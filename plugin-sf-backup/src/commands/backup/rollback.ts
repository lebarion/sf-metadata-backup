import { SfCommand, Flags } from '@salesforce/sf-plugins-core';
import { Messages } from '@salesforce/core';
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import chalk from 'chalk';

Messages.importMessagesDirectoryFromMetaUrl(import.meta.url);
const messages = Messages.loadMessages('sf-metadata-backup', 'backup.rollback');

export type BackupRollbackResult = {
  success: boolean;
  backupDir: string;
  mode: string;
  stepsExecuted: number;
};

export default class BackupRollback extends SfCommand<BackupRollbackResult> {
  public static readonly summary = messages.getMessage('summary');
  public static readonly description = messages.getMessage('description');
  public static readonly examples = messages.getMessages('examples');

  public static readonly flags = {
    'target-org': Flags.requiredOrg({
      summary: messages.getMessage('flags.target-org.summary'),
      char: 'o',
      required: true,
    }),
    'backup-dir': Flags.directory({
      summary: messages.getMessage('flags.backup-dir.summary'),
      char: 'd',
      required: true,
      exists: true,
    }),
    'no-confirm': Flags.boolean({
      summary: messages.getMessage('flags.no-confirm.summary'),
      default: false,
    }),
  };

  public async run(): Promise<BackupRollbackResult> {
    const { flags } = await this.parse(BackupRollback);

    // Determine if it's a rollback directory or backup directory
    let rollbackDir = flags['backup-dir'];
    if (path.basename(rollbackDir) !== 'rollback') {
      rollbackDir = path.join(rollbackDir, 'rollback');
    }

    if (!fs.existsSync(rollbackDir)) {
      throw new Error(`Rollback directory not found: ${rollbackDir}`);
    }

    const buildfilePath = path.join(rollbackDir, 'buildfile.json');
    if (!fs.existsSync(buildfilePath)) {
      throw new Error(`Buildfile not found in rollback directory: ${buildfilePath}`);
    }

    // Read buildfile to determine mode
    const buildfile = JSON.parse(fs.readFileSync(buildfilePath, 'utf8'));
    const mode = buildfile.mode || 'orgdevmode';

    this.log(chalk.blue('═══════════════════════════════════════════════════════════'));
    this.log(chalk.blue('  Salesforce Rollback Deployment'));
    this.log(chalk.blue('═══════════════════════════════════════════════════════════'));
    this.log(chalk.green('Rollback Directory:'), rollbackDir);
    this.log(chalk.green('Target Org:'), flags['target-org'].getUsername());
    this.log(chalk.green('Mode:'), mode);
    this.log('');

    // Confirm rollback
    if (!flags['no-confirm']) {
      const confirmed = await this.confirm({
        message: chalk.yellow('Are you sure you want to proceed with the rollback?'),
      });

      if (!confirmed) {
        this.log(chalk.yellow('Rollback cancelled'));
        return {
          success: false,
          backupDir: flags['backup-dir'],
          mode,
          stepsExecuted: 0,
        };
      }
    }

    let stepsExecuted = 0;

    try {
      if (mode === 'orgdevmode') {
        // Deploy using sf-orgdevmode-builds
        this.spinner.start(chalk.yellow('Deploying rollback using sf-orgdevmode-builds...'));

        execSync(`sf builds deploy -b "${buildfilePath}" -u "${flags['target-org'].getUsername()}"`, {
          cwd: rollbackDir,
          stdio: 'inherit',
        });

        this.spinner.stop(chalk.green('✓'));
        stepsExecuted = buildfile.builds?.length || 0;
      } else {
        // Deploy using standard CLI commands
        const steps = buildfile.steps || [];
        const orgUsername = flags['target-org'].getUsername()!;

        for (let i = 0; i < steps.length; i++) {
          const step = steps[i];
          this.spinner.start(chalk.yellow(`[${i + 1}/${steps.length}] ${step.name}...`));

          if (step.name === 'Remove new metadata') {
            const destructiveChanges = path.join(rollbackDir, step.options['post-destructive-changes']);
            const manifest = path.join(rollbackDir, step.options.manifest);

            if (fs.existsSync(destructiveChanges) && fs.readFileSync(destructiveChanges, 'utf8').includes('<members>')) {
              execSync(
                `sf project deploy start --manifest "${manifest}" --post-destructive-changes "${destructiveChanges}" --target-org "${orgUsername}" --ignore-warnings --wait 60`,
                { stdio: 'inherit' }
              );
            } else {
              this.spinner.stop(chalk.yellow('⊘ (skipped - no metadata to remove)'));
              continue;
            }
          } else if (step.name === 'Restore old metadata') {
            const manifest = path.join(rollbackDir, step.options.manifest);

            if (fs.existsSync(manifest) && fs.readFileSync(manifest, 'utf8').includes('<members>')) {
              execSync(`sf project deploy start --manifest "${manifest}" --target-org "${orgUsername}" --ignore-warnings --wait 60`, {
                stdio: 'inherit',
              });
            } else {
              this.spinner.stop(chalk.yellow('⊘ (skipped - no metadata to restore)'));
              continue;
            }
          }

          this.spinner.stop(chalk.green('✓'));
          stepsExecuted++;
        }
      }

      this.log('');
      this.log(chalk.green('═══════════════════════════════════════════════════════════'));
      this.log(chalk.green('  Rollback Completed Successfully!'));
      this.log(chalk.green('═══════════════════════════════════════════════════════════'));
      this.log('');
      this.log(chalk.yellow('Important:'));
      this.log('1. Verify the rollback was successful in the target org');
      this.log('2. Check for any errors or warnings in the deployment output');
      this.log('3. Test critical functionality to ensure the org is working correctly');
      this.log('');

      return {
        success: true,
        backupDir: flags['backup-dir'],
        mode,
        stepsExecuted,
      };
    } catch (error) {
      this.spinner.stop(chalk.red('✗'));
      throw error;
    }
  }
}

