# sf-metadata-backup

[![NPM](https://img.shields.io/npm/v/sf-metadata-backup.svg?label=sf-metadata-backup)](https://www.npmjs.com/package/sf-metadata-backup) [![Downloads/week](https://img.shields.io/npm/dw/sf-metadata-backup.svg)](https://npmjs.org/package/sf-metadata-backup) [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://raw.githubusercontent.com/yourusername/sf-metadata-backup/main/LICENSE.txt)

Salesforce CLI plugin for comprehensive metadata backup and rollback with dual-mode support.

## ⚠️ Important Notice

> **🚧 This plugin is currently under testing and active development.**
>
> ### Understanding Salesforce Rollback Limitations
>
> **Rollbacks in Salesforce are fundamentally different from traditional code deployments.** Unlike version control systems where you can simply revert to a previous commit, Salesforce operates on a "metadata happy soup" model where the target environment already contains metadata that must coexist with new deployments.
>
> #### What This Plugin Does
> This tool creates **compensatory rollback packages** - it generates new changes that attempt to counteract problematic deployments, rather than restoring the exact previous state. Think of it as "rolling forward with previous metadata" rather than a true rollback.
>
> #### Known Impossible Rollback Scenarios
>
> **This plugin CANNOT fully reverse:**
> - ❌ **Deleting custom fields with data** - The original field data cannot be restored
> - ❌ **Creating new custom fields** - Deploying the previous version won't remove the newly created field
> - ❌ **Profile permission changes** - Old profile versions won't reverse permission grants/revocations
> - ❌ **Sharing rules modifications** - Previous sharing rule versions don't undo new access patterns
> - ❌ **Picklist value additions** - Cannot remove picklist values that are in use
> - ❌ **Translation changes** - Language-specific metadata changes persist
> - ❌ **Industries/Communications Cloud** - These have significantly more complexity and corner cases
> - ❌ **Changes involving both metadata and datapacks** - Atomic deployments are impossible
>
> #### Recommended Approach: Roll Forward, Not Rollback
>
> Instead of relying on automatic rollbacks, we strongly recommend:
>
> 1. **Invest in Pipeline Quality**
>    - Implement nightly builds with automated regression tests
>    - Maintain comprehensive unit test coverage
>    - Use sandbox environments for thorough testing
>
> 2. **Adopt Roll-Forward Strategy**
>    - When issues occur, create new deployments that fix the problems
>    - Treat "rollback" as another forward deployment with previous metadata
>    - Document and track all changes, including compensatory deployments
>
> 3. **Use This Plugin As**
>    - A safety net for simple metadata reversions
>    - A tool to quickly generate recovery packages for review
>    - Part of a broader disaster recovery strategy (not the only strategy)
>
> #### Safety Guidelines
>
> - ⚠️ This plugin does **NOT guarantee 100% effective rollback** in all scenarios
> - ⚠️ Always test rollback procedures in a sandbox environment first
> - ⚠️ **Review generated rollback packages manually** before deploying to production
> - ⚠️ Have a manual rollback/recovery plan as a fallback
> - ⚠️ **Always maintain additional backups** through your org's native backup solutions
> - ⚠️ Use at your own risk in production environments
>
> #### Best Practices
>
> 1. ✅ Test thoroughly in sandbox environments before production use
> 2. ✅ Maintain multiple backup strategies (don't rely solely on this plugin)
> 3. ✅ Review generated rollback packages and understand what they will do
> 4. ✅ Monitor the deployment process closely
> 5. ✅ Document all rollback attempts and their outcomes
> 6. ✅ Consider the "blast radius" - what else might be affected?
> 7. ✅ When possible, fix forward rather than roll back
>
> 📖 **For a comprehensive understanding of rollback limitations, read [ROLLBACK_LIMITATIONS.md](../ROLLBACK_LIMITATIONS.md)**

## Features

- ✅ **Dual Mode Support**: Works with both `sf-orgdevmode-builds` (buildfile.json) and standard (package.xml) deployments
- 🔄 **Automatic Rollback Generation**: Creates deployment-ready rollback packages
- 📦 **Multi-Manifest Support**: Combines multiple package.xml files from buildfile.json
- 🗜️ **Compressed Backups**: Automatic compression with optional skip
- 📋 **Detailed Logging**: Complete audit trail of backup and rollback operations
- 🎯 **Smart Recovery**: Generates appropriate rollback for each deployment mode
- ⚡ **CLI Integration**: Seamless integration with Salesforce CLI

## Installation

```bash
sf plugins install sf-metadata-backup
```

## Commands

### `sf backup create`

Create a backup of Salesforce metadata before deployment.

**Usage:**

```bash
sf backup create --target-org <org-alias> [--manifest <path>] [--backup-dir <dir>] [--no-compress]
```

**Flags:**

- `-o, --target-org` (required): Salesforce org to backup metadata from
- `-m, --manifest`: Path to buildfile.json or package.xml (default: `manifest/buildfile.json`)
- `--backup-dir`: Directory to store backups (default: `backups`)
- `--no-compress`: Skip compression of backup into tar.gz archive

**Examples:**

```bash
# Backup using default buildfile.json (sf-orgdevmode-builds mode)
sf backup create --target-org myProdOrg

# Backup using custom buildfile.json
sf backup create --target-org myProdOrg --manifest manifest/custom-buildfile.json

# Backup using package.xml (standard mode)
sf backup create --target-org myProdOrg --manifest manifest/package.xml

# Backup without compression
sf backup create --target-org myProdOrg --manifest manifest/hotfix.xml --no-compress
```

**What It Does:**

1. Auto-detects deployment mode from file extension (.json = orgdevmode, .xml = standard)
2. Parses manifest(s) and retrieves existing metadata from target org
3. Generates recovery manifest for restoring old metadata
4. Creates destructive changes for removing new metadata
5. Generates rollback configuration (buildfile.json)
6. Compresses backup into .tar.gz archive (unless --no-compress)

---

### `sf backup rollback`

Rollback a deployment using a previously created backup.

**Usage:**

```bash
sf backup rollback --target-org <org-alias> --backup-dir <path> [--no-confirm]
```

**Flags:**

- `-o, --target-org` (required): Salesforce org to rollback deployment to
- `-d, --backup-dir` (required): Path to backup directory or rollback subdirectory
- `--no-confirm`: Skip confirmation prompt before rollback

**Examples:**

```bash
# Rollback with confirmation
sf backup rollback --target-org myProdOrg --backup-dir backups/backup_2025-01-10T14-30-22

# Rollback without confirmation
sf backup rollback --target-org myProdOrg --backup-dir backups/backup_2025-01-10T14-30-22 --no-confirm

# Rollback using rollback subdirectory
sf backup rollback --target-org myProdOrg --backup-dir backups/backup_2025-01-10T14-30-22/rollback
```

**What It Does:**

1. Auto-detects rollback mode from buildfile.json
2. For orgdevmode: Uses `sf builds deploy` with the plugin
3. For standard: Uses `sf project deploy start` commands
4. Removes new metadata using destructive changes
5. Restores old metadata from recovery manifest

---

### `sf backup list`

List all available backups.

**Usage:**

```bash
sf backup list [--backup-dir <dir>]
```

**Flags:**

- `--backup-dir`: Directory containing backups (default: `backups`)

**Examples:**

```bash
# List backups in default directory
sf backup list

# List backups in custom directory
sf backup list --backup-dir custom/backups
```

**Output:**

```
═══════════════════════════════════════════════════════════
  Available Backups
═══════════════════════════════════════════════════════════

Directory                    Timestamp              Mode        Size      Archive
backup_2025-01-10T14-30-22  2025-01-10T14-30-22   orgdevmode  12.45 MB  ✓
backup_2025-01-09T09-15-33  2025-01-09T09-15-33   standard    8.32 MB   ✓
backup_2025-01-08T16-45-11  2025-01-08T16-45-11   orgdevmode  15.67 MB  ✓

Total: 3 backup(s)
```

---

## Deployment Modes

### sf-orgdevmode-builds Mode

Uses buildfile.json with multiple manifest files.

**When to Use:**
- Multiple package.xml files with dependencies
- Complex multi-step deployments
- Using sf-orgdevmode-builds plugin

**Example:**
```bash
sf backup create --target-org myOrg --manifest manifest/buildfile.json
```

### Standard Mode

Uses a single package.xml file.

**When to Use:**
- Single package.xml deployments
- Hotfixes and quick changes
- No sf-orgdevmode-builds plugin needed

**Example:**
```bash
sf backup create --target-org myOrg --manifest manifest/package.xml
```

---

## Complete Workflow Example

### 1. Before Deployment - Create Backup

```bash
# For sf-orgdevmode-builds deployment
sf backup create --target-org myProdOrg

# For standard deployment
sf backup create --target-org myProdOrg --manifest manifest/package.xml
```

### 2. Deploy Your Changes

```bash
# Using sf-orgdevmode-builds
sf builds deploy -b manifest/buildfile.json -u myProdOrg

# Using standard CLI
sf project deploy start --manifest manifest/package.xml -u myProdOrg
```

### 3. If Something Goes Wrong - Rollback

```bash
# List available backups
sf backup list

# Rollback to previous state
sf backup rollback --target-org myProdOrg --backup-dir backups/backup_2025-01-10T14-30-22
```

---

## Backup Directory Structure

```
backups/
└── backup_2025-01-10T14-30-22/
    ├── backup.log                      # Complete backup log
    ├── combined-manifest.xml           # Combined deployment manifest
    ├── metadata/                       # Retrieved metadata
    │   └── [actual metadata files]
    ├── rollback/
    │   ├── buildfile.json             # Rollback configuration
    │   ├── recovery-package.xml        # Old metadata to restore
    │   └── destructive/
    │       ├── package.xml            # Empty package
    │       └── destructiveChanges.xml # New metadata to delete
    └── backup_2025-01-10T14-30-22.tar.gz  # Compressed archive
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy with Backup

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli
      
      - name: Install Backup Plugin
        run: sf plugins install sf-metadata-backup
      
      - name: Authenticate
        run: sf org login sfdx-url --sfdx-url-file auth.txt --alias prod
      
      - name: Create Backup
        run: sf backup create --target-org prod
      
      - name: Deploy
        run: sf builds deploy -b manifest/buildfile.json -u prod
      
      - name: Rollback on Failure
        if: failure()
        run: |
          BACKUP_DIR=$(ls -td backups/backup_* | head -1)
          sf backup rollback --target-org prod --backup-dir $BACKUP_DIR --no-confirm
```

### GitLab CI

```yaml
backup:
  script:
    - sf plugins install sf-metadata-backup
    - sf backup create --target-org $PROD_ORG
  artifacts:
    paths:
      - backups/
    expire_in: 30 days

deploy:
  dependencies:
    - backup
  script:
    - sf builds deploy -b manifest/buildfile.json -u $PROD_ORG
  when: on_success

rollback:
  dependencies:
    - backup
  script:
    - BACKUP_DIR=$(ls -td backups/backup_* | head -1)
    - sf backup rollback --target-org $PROD_ORG --backup-dir $BACKUP_DIR --no-confirm
  when: on_failure
```

---

## Best Practices

1. **Always backup before production deployments**
2. **Test rollback in sandbox first**
3. **Keep backups for at least 30 days**
4. **Use meaningful org aliases**
5. **Archive backups to external storage**
6. **Document rollback procedures**
7. **Verify backups completed successfully before deploying**

---

## Troubleshooting

### Issue: "Manifest source not found"

**Solution:** Check that the path to buildfile.json or package.xml is correct and the file exists.

### Issue: "sf-orgdevmode-builds plugin not found"

**Solution:** This error occurs when trying to rollback an orgdevmode backup without the plugin installed. Install it:

```bash
sf plugins install sf-orgdevmode-builds
```

### Issue: Rollback fails with dependency errors

**Solution:** Some metadata has dependencies. You may need to manually adjust the rollback order or split it into multiple steps.

---

## Requirements

- Salesforce CLI (sf) v2.0.0 or higher
- Node.js 18.0.0 or higher
- For orgdevmode rollbacks: sf-orgdevmode-builds plugin

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## License

MIT

---

## Support

For issues and feature requests, please visit:
- **Issues**: https://github.com/yourusername/sf-metadata-backup/issues
- **Documentation**: Full documentation available in the `/docs` folder

---

## Acknowledgments

Special thanks to:

- **[Tiago Nascimento](https://github.com/tiagonnascimento)** - For developing the [sf-orgdevmode-builds](https://github.com/tiagonnascimento/sf-orgdevmode-builds) plugin that inspired this work and for his valuable insights on Salesforce deployment strategies and rollback limitations.

- **Eric Gasparotto** - For challenging me to leverage AI tools in creating this solution, demonstrating how modern development practices can accelerate problem-solving and innovation.

This plugin stands on the shoulders of the Salesforce developer community's collective knowledge about the challenges and realities of metadata deployment and rollback.

---

## Changelog

### 0.0.3
- Added comprehensive rollback limitations documentation
- Enhanced warnings and best practices
- Improved safety guidelines

### 0.0.2
- Fixed orgdevmode command syntax (`sf builds deploy`)
- Updated all documentation and examples

### 0.0.1
- Initial release
- Dual mode support (orgdevmode and standard)
- Create, rollback, and list commands
- Automatic mode detection
- Compression support
- CI/CD ready

