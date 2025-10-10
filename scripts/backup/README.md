# Salesforce Metadata Backup and Rollback System

This system provides comprehensive backup and rollback capabilities for Salesforce deployments, following the [sf-orgdevmode-builds](https://github.com/tiagonnascimento/sf-orgdevmode-builds) plugin standards.

## ⚠️ Critical Warning: Read Before Using

> **Salesforce rollbacks are NOT like traditional code rollbacks.** This system creates **compensatory rollback packages**, not true reversions.
>
> - ❌ **Does NOT guarantee 100% effective rollback**
> - ❌ Cannot restore data from deleted fields
> - ❌ Cannot remove newly created metadata automatically
> - ❌ Cannot fully reverse permission and sharing changes
> - ❌ Industries/Communications Cloud significantly increases complexity
>
> **📖 REQUIRED READING:** [ROLLBACK_LIMITATIONS.md](../../ROLLBACK_LIMITATIONS.md) - Understand what this tool CAN and CANNOT do.
>
> **Best Practice:** Use roll-forward strategies and invest in pipeline quality rather than relying on automatic rollbacks.

## Overview

The backup and rollback system consists of several scripts that work together to:

1. **Backup existing metadata** from the target org before deployment
2. **Create recovery manifests** for restoring the original state
3. **Generate destructive packages** to remove new metadata that wasn't in the org before
4. **Create a rollback buildfile** following sf-orgdevmode-builds standards
5. **Deploy the rollback** to restore the org to its previous state

## Prerequisites

- Salesforce CLI (`sf`) installed
- Node.js and npm installed
- Access to target Salesforce org
- `sf-orgdevmode-builds` plugin (will be installed automatically if not present)
- `xml2js` npm package (install with: `npm install xml2js`)

## Directory Structure

```
scripts/backup/
├── backup-metadata.sh              # Main orchestration script
├── parse-buildfile.js              # Extract manifest files from buildfile.json
├── combine-manifests.js            # Combine multiple manifests into one
├── generate-recovery-manifest.js   # Generate manifest from retrieved metadata
├── generate-destructive-changes.js # Create destructive changes for new metadata
├── generate-rollback-buildfile.js  # Create rollback buildfile.json
├── deploy-rollback.sh              # Standalone rollback deployment script
└── README.md                       # This file

backups/
└── backup_YYYYMMDD_HHMMSS/
    ├── backup.log                  # Backup process log
    ├── combined-manifest.xml       # Combined deployment manifest
    ├── metadata/                   # Retrieved metadata from org
    ├── rollback/
    │   ├── buildfile.json          # Rollback buildfile
    │   ├── recovery-package.xml    # Manifest for restoring old metadata
    │   ├── destructive/
    │   │   ├── package.xml         # Empty package for destructive changes
    │   │   └── destructiveChanges.xml  # Metadata to delete
    │   └── deploy-rollback.sh      # Rollback deployment script
    └── backup_YYYYMMDD_HHMMSS.tar.gz   # Compressed backup archive
```

## Usage

### Creating a Backup

The backup system supports two deployment modes:

#### Mode 1: sf-orgdevmode-builds (with buildfile.json)

```bash
cd scripts/backup
./backup-metadata.sh <target-org> [buildfile-path]
```

**Example:**
```bash
./backup-metadata.sh myProdOrg
./backup-metadata.sh myProdOrg manifest/buildfile.json
```

#### Mode 2: Standard (with package.xml)

```bash
cd scripts/backup
./backup-metadata.sh <target-org> <package-xml-path>
```

**Example:**
```bash
./backup-metadata.sh myProdOrg manifest/package.xml
./backup-metadata.sh myProdOrg manifest/package-1.xml
```

**Arguments:**
- `target-org`: Salesforce org alias or username (required)
- `manifest-source`: Path to buildfile.json OR package.xml (optional, default: `manifest/buildfile.json`)

The script automatically detects the mode based on the file extension (.json or .xml).

This will:
1. Parse your buildfile.json to extract manifest files
2. Combine all manifests into a single package.xml
3. Retrieve existing metadata from the target org
4. Generate a recovery manifest for the retrieved metadata
5. Create destructive changes for metadata that doesn't exist in the org
6. Generate a rollback buildfile.json
7. Create a compressed backup archive

### Deploying a Rollback

If you need to rollback a deployment, use the rollback deployment script:

```bash
cd backups/backup_YYYYMMDD_HHMMSS/rollback
./deploy-rollback.sh
```

Or use the standalone script:

```bash
cd scripts/backup
./deploy-rollback.sh <rollback-directory> <target-org>
```

**Example:**
```bash
./deploy-rollback.sh ../../backups/backup_20250110_143022/rollback myProdOrg
```

The rollback process will:
1. Deploy destructive changes to remove new metadata
2. Deploy the old metadata to restore the previous state

## Rollback Configuration Structure

### For sf-orgdevmode-builds Mode

The generated `buildfile.json` follows sf-orgdevmode-builds standards:

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

### For Standard Mode

The generated `buildfile.json` documents the CLI commands:

```json
{
  "mode": "standard",
  "description": "Rollback using standard Salesforce CLI commands",
  "steps": [
    {
      "name": "Remove new metadata",
      "command": "sf project deploy start",
      "options": {
        "manifest": "destructive/package.xml",
        "post-destructive-changes": "destructive/destructiveChanges.xml",
        "ignore-warnings": true,
        "wait": 60
      }
    },
    {
      "name": "Restore old metadata",
      "command": "sf project deploy start",
      "options": {
        "manifest": "recovery-package.xml",
        "ignore-warnings": true,
        "wait": 60
      }
    }
  ]
}
```

### Build Steps

1. **Destructive Changes Build**: Removes metadata that was deployed but didn't exist before
   - Uses an empty `package.xml` with `postDestructiveChanges`
   - Deletes new metadata first to avoid conflicts

2. **Recovery Build**: Deploys the old metadata to restore previous state
   - Uses the generated recovery manifest
   - Restores all metadata that existed before the deployment

## Important Notes

### Test Level

The rollback builds use `testLevel: "NoTestRun"` by default to speed up the rollback process. If you need to run tests during rollback, you can modify the generated buildfile.json.

### Metadata Not Retrieved

Some metadata types cannot be retrieved from the org:
- Settings objects (unless specified in the manifest)
- Some platform cache configurations
- Certain system-generated metadata

These limitations are inherent to the Salesforce Metadata API.

### Metadata Dependencies

The rollback process may fail if there are dependency issues. In such cases:
1. Review the deployment errors
2. Manually adjust the recovery manifest if needed
3. Re-run the rollback

### Backup Storage

Backups are stored in the `backups/` directory and compressed into `.tar.gz` archives. Make sure to:
- Archive old backups to a secure location
- Clean up old backups periodically to save disk space
- Store backups in a version control system or backup service

## Troubleshooting

### "No metadata found" warning

This can occur if:
- The manifest files don't exist in the org
- The metadata retrieval failed
- The manifest is empty

Check the backup log for details.

### "sf-orgdevmode-builds not found"

Install the plugin manually:
```bash
sf plugins install sf-orgdevmode-builds
```

### Rollback fails with dependency errors

Some metadata has dependencies that must be deployed in a specific order. You may need to:
1. Manually adjust the recovery manifest
2. Split the rollback into multiple builds
3. Remove problematic metadata from the destructive changes

### XML parsing errors

Ensure the `xml2js` package is installed:
```bash
cd scripts/backup
npm install xml2js
```

## Best Practices

1. **Always create a backup before production deployments**
2. **Test the rollback process in a sandbox first**
3. **Keep backups for at least 30 days**
4. **Document any manual changes needed for rollback**
5. **Verify the backup was successful before proceeding with deployment**
6. **Run the backup during a maintenance window if possible**

## Integration with CI/CD

You can integrate the backup system into your CI/CD pipeline:

```yaml
# Example GitLab CI/CD
backup_production:
  stage: pre-deploy
  script:
    - cd scripts/backup
    - ./backup-metadata.sh $PROD_ORG_ALIAS
  artifacts:
    paths:
      - backups/
    expire_in: 30 days
```

## Support

For issues with:
- **This backup system**: Check the logs in `backups/backup_*/backup.log`
- **sf-orgdevmode-builds plugin**: See [GitHub repository](https://github.com/tiagonnascimento/sf-orgdevmode-builds)
- **Salesforce CLI**: See [Salesforce CLI documentation](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## License

This backup system is provided as-is for use with your Salesforce projects.

