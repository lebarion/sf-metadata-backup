import { SfCommand, Flags } from '@salesforce/sf-plugins-core';
import { Messages } from '@salesforce/core';
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import chalk from 'chalk';

Messages.importMessagesDirectoryFromMetaUrl(import.meta.url);
const messages = Messages.loadMessages('sf-metadata-backup', 'backup.create');

export type BackupCreateResult = {
  success: boolean;
  backupDir: string;
  backupArchive: string;
  mode: string;
  timestamp: string;
  manifestSource: string;
};

export default class BackupCreate extends SfCommand<BackupCreateResult> {
  public static readonly summary = messages.getMessage('summary');
  public static readonly description = messages.getMessage('description');
  public static readonly examples = messages.getMessages('examples');

  public static readonly flags = {
    'target-org': Flags.requiredOrg({
      summary: messages.getMessage('flags.target-org.summary'),
      char: 'o',
      required: true,
    }),
    manifest: Flags.file({
      summary: messages.getMessage('flags.manifest.summary'),
      char: 'm',
      default: 'manifest/buildfile.json',
      exists: true,
    }),
    'backup-dir': Flags.directory({
      summary: messages.getMessage('flags.backup-dir.summary'),
      default: 'backups',
    }),
    'no-compress': Flags.boolean({
      summary: messages.getMessage('flags.no-compress.summary'),
      default: false,
    }),
  };

  public async run(): Promise<BackupCreateResult> {
    const { flags } = await this.parse(BackupCreate);

    this.log(chalk.blue('═══════════════════════════════════════════════════════════'));
    this.log(chalk.blue('  Salesforce Metadata Backup System'));
    this.log(chalk.blue('═══════════════════════════════════════════════════════════'));

    // Determine mode from file extension
    const manifestSource = flags.manifest;
    const mode = path.extname(manifestSource) === '.json' ? 'orgdevmode' : 'standard';

    this.log(chalk.green('Target Org:'), flags['target-org'].getUsername());
    this.log(chalk.green('Deployment Mode:'), mode);
    this.log(chalk.green('Manifest Source:'), manifestSource);

    // Create timestamp and backup directory
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
    const backupDir = path.join(flags['backup-dir'], `backup_${timestamp}`);
    const rollbackDir = path.join(backupDir, 'rollback');
    const metadataDir = path.join(backupDir, 'metadata');

    // Create directories
    fs.mkdirSync(backupDir, { recursive: true });
    fs.mkdirSync(rollbackDir, { recursive: true });
    fs.mkdirSync(metadataDir, { recursive: true });

    this.log(chalk.green('Backup Directory:'), backupDir);
    this.log('');

    try {
      // Step 1: Parse or copy manifest
      this.spinner.start(chalk.yellow('[1/6] Processing manifest...'));
      const combinedManifest = await this.processManifest(manifestSource, backupDir, mode);
      this.spinner.stop(chalk.green('✓'));

      // Step 2: Retrieve metadata from org
      this.spinner.start(chalk.yellow('[2/6] Retrieving metadata from target org...'));
      await this.retrieveMetadata(combinedManifest, metadataDir, flags['target-org'].getUsername()!);
      this.spinner.stop(chalk.green('✓'));

      // Step 3: Generate recovery manifest
      this.spinner.start(chalk.yellow('[3/6] Generating recovery manifest...'));
      const recoveryManifest = path.join(rollbackDir, 'recovery-package.xml');
      await this.generateRecoveryManifest(metadataDir, recoveryManifest);
      this.spinner.stop(chalk.green('✓'));

      // Step 4: Generate destructive changes
      this.spinner.start(chalk.yellow('[4/6] Generating destructive changes...'));
      const destructiveDir = path.join(rollbackDir, 'destructive');
      await this.generateDestructiveChanges(combinedManifest, recoveryManifest, destructiveDir);
      this.spinner.stop(chalk.green('✓'));

      // Step 5: Generate rollback buildfile
      this.spinner.start(chalk.yellow('[5/6] Generating rollback configuration...'));
      const rollbackBuildfile = path.join(rollbackDir, 'buildfile.json');
      await this.generateRollbackBuildfile(recoveryManifest, destructiveDir, rollbackBuildfile, mode);
      this.spinner.stop(chalk.green('✓'));

      // Step 6: Compress backup (if enabled)
      let backupArchive = '';
      if (!flags['no-compress']) {
        this.spinner.start(chalk.yellow('[6/6] Compressing backup...'));
        backupArchive = await this.compressBackup(backupDir);
        this.spinner.stop(chalk.green('✓'));
      }

      this.log('');
      this.log(chalk.green('═══════════════════════════════════════════════════════════'));
      this.log(chalk.green('  Backup Completed Successfully!'));
      this.log(chalk.green('═══════════════════════════════════════════════════════════'));
      this.log('');
      this.log(chalk.green('Backup Directory:'), backupDir);
      if (backupArchive) {
        this.log(chalk.green('Backup Archive:'), backupArchive);
      }
      this.log(chalk.green('Deployment Mode:'), mode);
      this.log('');
      this.log(chalk.yellow('To deploy rollback:'));
      this.log(`  sf backup rollback --backup-dir "${backupDir}" --target-org ${flags['target-org'].getUsername()}`);
      this.log('');

      return {
        success: true,
        backupDir,
        backupArchive,
        mode,
        timestamp,
        manifestSource,
      };
    } catch (error) {
      this.spinner.stop(chalk.red('✗'));
      throw error;
    }
  }

  private async processManifest(manifestSource: string, backupDir: string, mode: string): Promise<string> {
    const combinedManifest = path.join(backupDir, 'combined-manifest.xml');

    if (mode === 'orgdevmode') {
      // Parse buildfile.json and combine manifests
      const scriptDir = path.join(__dirname, '../../../scripts');
      const parseScript = path.join(scriptDir, 'parse-buildfile.js');
      const combineScript = path.join(scriptDir, 'combine-manifests.js');

      const manifestFiles = execSync(`node "${parseScript}" "${manifestSource}"`, {
        encoding: 'utf8',
      }).trim();

      execSync(
        `node "${combineScript}" "${manifestFiles.replace(/\n/g, ' ')}" "${combinedManifest}" "${process.cwd()}"`,
        { encoding: 'utf8' }
      );
    } else {
      // Copy package.xml directly
      fs.copyFileSync(manifestSource, combinedManifest);
    }

    return combinedManifest;
  }

  private async retrieveMetadata(manifest: string, targetDir: string, orgUsername: string): Promise<void> {
    try {
      execSync(
        `sf project retrieve start --manifest "${manifest}" --target-org "${orgUsername}" --target-metadata-dir "${targetDir}" --wait 60 --ignore-conflicts`,
        { stdio: 'pipe' }
      );
    } catch (error) {
      // Ignore errors for non-existent metadata
      this.warn('Some metadata may not exist in target org');
    }
  }

  private async generateRecoveryManifest(metadataDir: string, outputFile: string): Promise<void> {
    const scriptDir = path.join(__dirname, '../../../scripts');
    const script = path.join(scriptDir, 'generate-recovery-manifest.js');
    execSync(`node "${script}" "${metadataDir}" "${outputFile}"`, { stdio: 'pipe' });
  }

  private async generateDestructiveChanges(
    deploymentManifest: string,
    recoveryManifest: string,
    destructiveDir: string
  ): Promise<void> {
    fs.mkdirSync(destructiveDir, { recursive: true });

    const scriptDir = path.join(__dirname, '../../../scripts');
    const script = path.join(scriptDir, 'generate-destructive-changes.js');
    const destructiveChanges = path.join(destructiveDir, 'destructiveChanges.xml');

    execSync(`node "${script}" "${deploymentManifest}" "${recoveryManifest}" "${destructiveChanges}"`, {
      stdio: 'pipe',
    });

    // Create empty package.xml
    const emptyPackage = `<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>61.0</version>
</Package>`;
    fs.writeFileSync(path.join(destructiveDir, 'package.xml'), emptyPackage);
  }

  private async generateRollbackBuildfile(
    recoveryManifest: string,
    destructiveDir: string,
    outputFile: string,
    mode: string
  ): Promise<void> {
    const scriptDir = path.join(__dirname, '../../../scripts');
    const script = path.join(scriptDir, 'generate-rollback-buildfile.js');
    const destructiveChanges = path.join(destructiveDir, 'destructiveChanges.xml');

    execSync(`node "${script}" "${recoveryManifest}" "${destructiveChanges}" "${outputFile}" "${mode}"`, {
      stdio: 'pipe',
    });
  }

  private async compressBackup(backupDir: string): Promise<string> {
    const backupArchive = `${backupDir}.tar.gz`;
    const backupName = path.basename(backupDir);
    const backupsDir = path.dirname(backupDir);

    execSync(`tar -czf "${backupArchive}" -C "${backupsDir}" "${backupName}"`, { stdio: 'pipe' });

    return backupArchive;
  }
}

