# Salesforce Backup and Rollback System

## Overview

This project now includes a comprehensive **backup and rollback system** for Salesforce deployments. The system automatically backs up metadata before deployment and creates rollback packages that can restore the org to its previous state.

## Quick Start

### 1. Setup (One-time)

```bash
cd scripts/backup
./setup.sh
```

### 2. Create Backup Before Deployment

#### For sf-orgdevmode-builds deployments:
```bash
cd scripts/backup
./backup-metadata.sh <your-org-alias> [buildfile.json-path]
```

#### For standard deployments (single package.xml):
```bash
cd scripts/backup
./backup-metadata.sh <your-org-alias> <package.xml-path>
```

**Examples:**
```bash
# Default (uses manifest/buildfile.json)
./backup-metadata.sh myProdOrg

# With buildfile.json
./backup-metadata.sh myProdOrg manifest/buildfile.json

# With package.xml
./backup-metadata.sh myProdOrg manifest/package.xml
./backup-metadata.sh myProdOrg manifest/package-1.xml
```

### 3. Deploy Your Changes

```bash
# Using sf-orgdevmode-builds
sf deploy orgdevmode -b manifest/buildfile.json -u <your-org-alias>

# OR using standard CLI
sf project deploy start --manifest manifest/package.xml -u <your-org-alias>
```

### 4. Rollback (if needed)

```bash
cd backups/backup_YYYYMMDD_HHMMSS/rollback
./deploy-rollback.sh
```

## What It Does

The backup system supports **two deployment modes**:

### Mode 1: sf-orgdevmode-builds
Works with buildfile.json that contains multiple manifest files

### Mode 2: Standard
Works with a single package.xml file

**The system:**

1. ✅ **Auto-detects mode** based on file extension (.json or .xml)
2. ✅ **Reads your manifest(s)** to identify what metadata will be deployed
3. ✅ **Retrieves existing metadata** from the target org
4. ✅ **Creates a recovery manifest** to restore the old metadata
5. ✅ **Generates destructive changes** to remove new metadata that wasn't in the org
6. ✅ **Creates rollback configuration** (buildfile.json or standard CLI commands)
7. ✅ **Compresses the backup** into a `.tar.gz` archive

## Key Features

- **🔄 Dual Mode Support**: Works with both sf-orgdevmode-builds AND standard package.xml
- **🤖 Auto-Detection**: Automatically detects deployment mode from file extension
- **📦 Multi-Manifest Support**: Combines multiple package.xml files from buildfile.json
- **🗜️ Compressed Backups**: Saves disk space with automatic compression
- **📋 Detailed Logging**: Complete audit trail of backup and rollback operations
- **🔧 Parameterizable**: Works with any buildfile.json or package.xml in your project
- **⚡ CI/CD Ready**: Easy integration with GitHub Actions, GitLab CI, Jenkins, etc.
- **🎯 Smart Rollback**: Generates appropriate rollback for each mode

## File Structure

```
scripts/backup/
├── backup-metadata.sh              # Main backup script
├── deploy-rollback.sh              # Standalone rollback deployment
├── setup.sh                        # One-time setup script
├── parse-buildfile.js              # Buildfile parser
├── combine-manifests.js            # Manifest combiner
├── generate-recovery-manifest.js   # Recovery manifest generator
├── generate-destructive-changes.js # Destructive changes generator
├── generate-rollback-buildfile.js  # Rollback buildfile generator
├── package.json                    # Node.js dependencies
├── README.md                       # Detailed documentation
└── USAGE_EXAMPLE.md               # Practical examples

backups/                            # Created by backup system
└── backup_YYYYMMDD_HHMMSS/
    ├── backup.log                  # Backup process log
    ├── combined-manifest.xml       # Combined deployment manifest
    ├── metadata/                   # Retrieved metadata
    ├── rollback/
    │   ├── buildfile.json          # Rollback buildfile
    │   ├── recovery-package.xml    # Recovery manifest
    │   ├── destructive/
    │   │   ├── package.xml
    │   │   └── destructiveChanges.xml
    │   └── deploy-rollback.sh      # Rollback script
    └── backup_YYYYMMDD_HHMMSS.tar.gz
```

## Rollback Process

The generated rollback buildfile follows sf-orgdevmode-builds standards:

```json
{
  "builds": [
    {
      "type": "metadata",
      "manifestFile": "destructive/package.xml",
      "testLevel": "NoTestRun",
      "postDestructiveChanges": "destructive/destructiveChanges.xml",
      "timeout": "180",
      "ignoreWarnings": true,
      "disableTracking": true
    },
    {
      "type": "metadata",
      "manifestFile": "recovery-package.xml",
      "testLevel": "NoTestRun",
      "timeout": "180",
      "ignoreWarnings": true,
      "disableTracking": true
    }
  ]
}
```

**Rollback Steps:**
1. **Remove new metadata** using destructive changes
2. **Restore old metadata** using recovery manifest

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Create Backup
  run: |
    cd scripts/backup
    ./backup-metadata.sh ${{ secrets.PROD_ORG_ALIAS }}

- name: Deploy Changes
  run: |
    sf deploy orgdevmode -b manifest/buildfile.json -u ${{ secrets.PROD_ORG_ALIAS }}

- name: Rollback on Failure
  if: failure()
  run: |
    BACKUP_DIR=$(ls -td backups/backup_* | head -1)
    cd scripts/backup
    ./deploy-rollback.sh ../../${BACKUP_DIR}/rollback ${{ secrets.PROD_ORG_ALIAS }}
```

## Documentation

- **[scripts/backup/README.md](scripts/backup/README.md)** - Complete technical documentation
- **[scripts/backup/USAGE_EXAMPLE.md](scripts/backup/USAGE_EXAMPLE.md)** - Practical examples and scenarios

## Prerequisites

- Salesforce CLI (`sf`)
- Node.js and npm
- `sf-orgdevmode-builds` plugin (installed automatically by setup script)

## Best Practices

1. ✅ **Always create a backup before production deployments**
2. ✅ **Test the rollback process in a sandbox first**
3. ✅ **Keep backups for at least 30 days**
4. ✅ **Archive backups to external storage**
5. ✅ **Review backup logs before proceeding with deployment**

## Troubleshooting

Common issues and solutions are documented in:
- [scripts/backup/README.md](scripts/backup/README.md#troubleshooting)
- [scripts/backup/USAGE_EXAMPLE.md](scripts/backup/USAGE_EXAMPLE.md#troubleshooting)

## Support

For issues with:
- **This backup system**: Check logs in `backups/backup_*/backup.log`
- **sf-orgdevmode-builds**: See [GitHub](https://github.com/tiagonnascimento/sf-orgdevmode-builds)
- **Salesforce CLI**: See [Salesforce Documentation](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

---

**Created**: October 10, 2025  
**Version**: 1.0.0  
**Compatible with**: sf-orgdevmode-builds plugin

