/*
 * Copyright (c) 2023, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';
import * as path from 'node:path';
import * as fs from 'node:fs';
import { SfCommand, Flags } from '@salesforce/sf-plugins-core';
import { Messages } from '@salesforce/core';
import chalk from 'chalk';

// ES modules equivalent of __dirname
// eslint-disable-next-line no-underscore-dangle
const __filename = fileURLToPath(import.meta.url);
// eslint-disable-next-line no-underscore-dangle
const __dirname = path.dirname(__filename);

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
      const combinedManifest = BackupCreate.processManifest(manifestSource, backupDir, mode);
      this.spinner.stop(chalk.green('✓'));

      // Step 2: Retrieve metadata from org
      this.spinner.start(chalk.yellow('[2/6] Retrieving metadata from target org...'));
      this.retrieveMetadata(combinedManifest, metadataDir, flags['target-org'].getUsername()!);
      this.spinner.stop(chalk.green('✓'));

      // Step 3: Generate recovery manifest
      this.spinner.start(chalk.yellow('[3/6] Generating recovery manifest...'));
      const recoveryManifest = path.join(rollbackDir, 'recovery-package.xml');
      BackupCreate.generateRecoveryManifest(metadataDir, recoveryManifest);
      this.spinner.stop(chalk.green('✓'));

      // Step 4: Generate destructive changes
      this.spinner.start(chalk.yellow('[4/6] Generating destructive changes...'));
      const destructiveDir = path.join(rollbackDir, 'destructive');
      BackupCreate.generateDestructiveChanges(combinedManifest, recoveryManifest, destructiveDir);
      this.spinner.stop(chalk.green('✓'));

      // Step 5: Generate rollback buildfile
      this.spinner.start(chalk.yellow('[5/6] Generating rollback configuration...'));
      const rollbackBuildfile = path.join(rollbackDir, 'buildfile.json');
      BackupCreate.generateRollbackBuildfile(recoveryManifest, destructiveDir, rollbackBuildfile, mode);
      this.spinner.stop(chalk.green('✓'));

      // Step 6: Compress backup (if enabled)
      let backupArchive = '';
      if (!flags['no-compress']) {
        this.spinner.start(chalk.yellow('[6/6] Compressing backup...'));
        backupArchive = BackupCreate.compressBackup(backupDir);
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
      this.log(`  sf backup rollback --backup-dir "${backupDir}" --target-org ${flags['target-org'].getUsername() ?? 'YOUR_ORG'}`);
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

  // eslint-disable-next-line @typescript-eslint/member-ordering
  private static processManifest(manifestSource: string, backupDir: string, mode: string): string {
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

  // eslint-disable-next-line @typescript-eslint/member-ordering
  private retrieveMetadata(manifest: string, targetDir: string, orgUsername: string): void {
    try {
      // Retrieve creates a ZIP file in the target directory
      // Note: --ignore-conflicts cannot be used with --target-metadata-dir
      execSync(
        `sf project retrieve start --manifest "${manifest}" --target-org "${orgUsername}" --target-metadata-dir "${targetDir}" --wait 60`,
        { stdio: 'pipe' }
      );
      
      // Extract the unpackaged.zip file
      const zipFile = path.join(targetDir, 'unpackaged.zip');
      this.log(chalk.gray(`  Checking for ZIP file: ${zipFile}`));
      
      if (fs.existsSync(zipFile)) {
        this.log(chalk.gray(`  ZIP file found, extracting...`));
        // Extract to the same directory
        execSync(`unzip -o -q "${zipFile}" -d "${targetDir}"`, { stdio: 'pipe' });
        
        // Remove the zip file after extraction
        fs.unlinkSync(zipFile);
        
        // Move extracted files from unpackaged/ subdirectory to root using mv command
        const unpackagedDir = path.join(targetDir, 'unpackaged');
        if (fs.existsSync(unpackagedDir)) {
          this.log(chalk.gray(`  Moving files from unpackaged/ to metadata/`));
          // Use shell command to move all contents recursively
          execSync(`mv "${unpackagedDir}"/* "${targetDir}/" 2>/dev/null || true`, { stdio: 'pipe' });
          
          // Remove empty unpackaged directory
          execSync(`rm -rf "${unpackagedDir}"`, { stdio: 'pipe' });
          
          // Verify files were moved
          const files = fs.readdirSync(targetDir);
          this.log(chalk.gray(`  Metadata directory now has ${files.length} items`));
        } else {
          this.warn('Unpackaged directory not found after extraction');
        }
      } else {
        this.warn(`ZIP file not found: ${zipFile}`);
      }
    } catch (error) {
      // Ignore errors for non-existent metadata
      this.warn('Some metadata may not exist in target org');
      if (error instanceof Error) {
        this.log(chalk.gray(`  Error details: ${error.message}`));
      }
    }
  }

  // eslint-disable-next-line @typescript-eslint/member-ordering
  private static generateRecoveryManifest(metadataDir: string, outputFile: string): void {
    const scriptDir = path.join(__dirname, '../../../scripts');
    const script = path.join(scriptDir, 'generate-recovery-manifest.js');
    execSync(`node "${script}" "${metadataDir}" "${outputFile}"`, { stdio: 'pipe' });
  }

  // eslint-disable-next-line @typescript-eslint/member-ordering
  private static generateDestructiveChanges(
    deploymentManifest: string,
    recoveryManifest: string,
    destructiveDir: string
  ): void {
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

  // eslint-disable-next-line @typescript-eslint/member-ordering
  private static generateRollbackBuildfile(
    recoveryManifest: string,
    destructiveDir: string,
    outputFile: string,
    mode: string
  ): void {
    const scriptDir = path.join(__dirname, '../../../scripts');
    const script = path.join(scriptDir, 'generate-rollback-buildfile.js');
    const destructiveChanges = path.join(destructiveDir, 'destructiveChanges.xml');

    execSync(`node "${script}" "${recoveryManifest}" "${destructiveChanges}" "${outputFile}" "${mode}"`, {
      stdio: 'pipe',
    });
  }

  // eslint-disable-next-line @typescript-eslint/member-ordering
  private static compressBackup(backupDir: string): string {
    const backupArchive = `${backupDir}.tar.gz`;
    const backupName = path.basename(backupDir);
    const backupsDir = path.dirname(backupDir);

    execSync(`tar -czf "${backupArchive}" -C "${backupsDir}" "${backupName}"`, { stdio: 'pipe' });

    return backupArchive;
  }
}

