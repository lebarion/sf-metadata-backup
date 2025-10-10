# Quick Start Guide

Get the sf-metadata-backup plugin up and running in 5 minutes!

## Prerequisites

- ✅ Salesforce CLI (sf) installed
- ✅ Node.js 18+ installed
- ✅ Access to a Salesforce org

## Installation

### Option 1: Automated Setup (Recommended)

From the project root:

```bash
./setup-plugin.sh
```

This will:
1. Copy utility scripts to plugin
2. Install dependencies
3. Build the plugin
4. Link it to SF CLI

### Option 2: Manual Setup

```bash
# 1. Copy scripts
mkdir -p plugin-sf-backup/scripts
cp scripts/backup/*.js plugin-sf-backup/scripts/

# 2. Install and build
cd plugin-sf-backup
npm install
npm run build

# 3. Link plugin
sf plugins link
```

## Verify Installation

```bash
sf plugins
# Should show: sf-metadata-backup 1.0.0

sf backup --help
# Should show available commands
```

## First Backup

### 1. Authenticate with Your Org

```bash
sf org login web --alias myDevOrg
```

### 2. Create Your First Backup

**For sf-orgdevmode-builds:**
```bash
sf backup create --target-org myDevOrg
```

**For standard package.xml:**
```bash
sf backup create --target-org myDevOrg --manifest manifest/package.xml
```

### 3. View Your Backups

```bash
sf backup list
```

Output:
```
═══════════════════════════════════════════════════════════
  Available Backups
═══════════════════════════════════════════════════════════

Directory                    Timestamp              Mode        Size      Archive
backup_2025-01-10T14-30-22  2025-01-10T14-30-22   orgdevmode  12.45 MB  ✓

Total: 1 backup(s)
```

## Test Rollback (Sandbox Only!)

⚠️ **Never test rollback in production first!**

```bash
# Deploy some changes first
sf project deploy start --manifest manifest/package.xml -u myDevOrg

# Then rollback
sf backup rollback --target-org myDevOrg --backup-dir backups/backup_2025-01-10T14-30-22
```

## Common Commands

### Create Backup

```bash
# With buildfile.json (orgdevmode)
sf backup create --target-org myOrg

# With package.xml (standard)
sf backup create --target-org myOrg --manifest manifest/package.xml

# Without compression
sf backup create --target-org myOrg --no-compress
```

### List Backups

```bash
sf backup list
```

### Rollback

```bash
sf backup rollback --target-org myOrg --backup-dir backups/backup_2025-01-10T14-30-22

# Skip confirmation
sf backup rollback --target-org myOrg --backup-dir backups/backup_* --no-confirm
```

## Workflow Example

```bash
# 1. Before deployment - create backup
sf backup create --target-org myProdOrg

# 2. Deploy your changes
sf builds deploy -b manifest/buildfile.json -u myProdOrg

# 3. If something goes wrong - rollback
sf backup list  # Find your backup
sf backup rollback --target-org myProdOrg --backup-dir backups/backup_2025-01-10T14-30-22
```

## Troubleshooting

### Command not found

```bash
# Relink the plugin
cd plugin-sf-backup
sf plugins link
```

### Scripts not found

```bash
# Copy scripts again
./setup-plugin.sh
```

### Build errors

```bash
cd plugin-sf-backup
npm run clean
npm install
npm run build
```

## Next Steps

1. **Read the README**: `plugin-sf-backup/README.md`
2. **Review Commands**: `sf backup --help`
3. **Test in Sandbox**: Always test rollback in sandbox first
4. **Integrate CI/CD**: See README for examples
5. **Document**: Document your backup/rollback procedures

## Getting Help

- **Command Help**: `sf backup create --help`
- **Full Documentation**: `plugin-sf-backup/README.md`
- **Installation Guide**: `plugin-sf-backup/INSTALLATION.md`
- **Script Setup**: `plugin-sf-backup/SETUP_SCRIPTS.md`

## Comparison: Scripts vs Plugin

### Using Shell Scripts

```bash
cd scripts/backup
./backup-metadata.sh myOrg
./deploy-rollback.sh backups/backup_*/rollback myOrg
```

### Using SF CLI Plugin

```bash
sf backup create --target-org myOrg
sf backup rollback --target-org myOrg --backup-dir backups/backup_*
```

**Both work!** The plugin provides better CLI integration and professional UX.

---

**You're ready!** Start creating backups with:

```bash
sf backup create --target-org myOrg
```

🚀

