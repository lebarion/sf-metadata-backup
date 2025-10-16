/*
 * Copyright (c) 2023, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import * as path from 'node:path';
import * as fs from 'node:fs';
import { SfCommand, Flags } from '@salesforce/sf-plugins-core';
import { Messages } from '@salesforce/core';
import chalk from 'chalk';

Messages.importMessagesDirectoryFromMetaUrl(import.meta.url);
const messages = Messages.loadMessages('sf-metadata-backup', 'backup.list');

export type BackupInfo = {
  directory: string;
  timestamp: string;
  mode: string;
  size: string;
  hasArchive: boolean;
};

export type BackupListResult = {
  backups: BackupInfo[];
  count: number;
};

export default class BackupList extends SfCommand<BackupListResult> {
  public static readonly summary = messages.getMessage('summary');
  public static readonly description = messages.getMessage('description');
  public static readonly examples = messages.getMessages('examples');

  public static readonly flags = {
    'backup-dir': Flags.directory({
      summary: messages.getMessage('flags.backup-dir.summary'),
      default: 'backups',
    }),
  };

  private static formatSize(bytes: number): string {
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return `${size.toFixed(2)} ${units[unitIndex]}`;
  }

  public async run(): Promise<BackupListResult> {
    const { flags } = await this.parse(BackupList);

    if (!fs.existsSync(flags['backup-dir'])) {
      this.log(chalk.yellow('No backups directory found'));
      return { backups: [], count: 0 };
    }

    const entries = fs.readdirSync(flags['backup-dir']);
    const backups: BackupInfo[] = [];

    for (const entry of entries) {
      if (entry.startsWith('backup_')) {
        const backupPath = path.join(flags['backup-dir'], entry);
        const stat = fs.statSync(backupPath);

        if (stat.isDirectory()) {
          const buildfilePath = path.join(backupPath, 'rollback', 'buildfile.json');
          let mode = 'unknown';

          if (fs.existsSync(buildfilePath)) {
            try {
              const buildfile = JSON.parse(fs.readFileSync(buildfilePath, 'utf8')) as { mode?: string };
              mode = buildfile.mode ?? 'orgdevmode';
            } catch {
              mode = 'unknown';
            }
          }

          const archivePath = `${backupPath}.tar.gz`;
          const hasArchive = fs.existsSync(archivePath);

          backups.push({
            directory: entry,
            timestamp: entry.replace('backup_', ''),
            mode,
            size: BackupList.formatSize(this.getDirectorySize(backupPath)),
            hasArchive,
          });
        }
      }
    }

    // Sort by timestamp (newest first)
    backups.sort((a, b) => b.timestamp.localeCompare(a.timestamp));

    this.log(chalk.blue('═══════════════════════════════════════════════════════════'));
    this.log(chalk.blue('  Available Backups'));
    this.log(chalk.blue('═══════════════════════════════════════════════════════════'));
    this.log('');

    if (backups.length === 0) {
      this.log(chalk.yellow('No backups found'));
    } else {
      this.table(backups, {
        directory: {
          header: 'Directory',
          get: (row) => chalk.cyan(row.directory),
        },
        timestamp: {
          header: 'Timestamp',
        },
        mode: {
          header: 'Mode',
          get: (row) => (row.mode === 'orgdevmode' ? chalk.green(row.mode) : chalk.blue(row.mode)),
        },
        size: {
          header: 'Size',
        },
        hasArchive: {
          header: 'Archive',
          get: (row) => (row.hasArchive ? chalk.green('✓') : chalk.gray('✗')),
        },
      });

      this.log('');
      this.log(chalk.gray(`Total: ${backups.length} backup(s)`));
    }

    this.log('');

    return {
      backups,
      count: backups.length,
    };
  }

  private getDirectorySize(dirPath: string): number {
    let size = 0;

    const files = fs.readdirSync(dirPath);
    for (const file of files) {
      const filePath = path.join(dirPath, file);
      const stat = fs.statSync(filePath);

      if (stat.isDirectory()) {
        size += this.getDirectorySize(filePath);
      } else {
        size += stat.size;
      }
    }

    return size;
  }
}

