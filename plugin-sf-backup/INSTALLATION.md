# Installation Guide: sf-metadata-backup

This guide covers multiple ways to install and use the sf-metadata-backup plugin.

## Table of Contents

1. [NPM Installation (Recommended)](#npm-installation-recommended)
2. [Local Development Installation](#local-development-installation)
3. [Git Installation](#git-installation)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

---

## NPM Installation (Recommended)

### Prerequisites

- Salesforce CLI (sf) installed
- Node.js 18.0.0 or higher

### Install from NPM

```bash
sf plugins install sf-metadata-backup
```

### Verify Installation

```bash
sf plugins

# Should show:
sf-metadata-backup 1.0.0
```

### Test Commands

```bash
sf backup --help
sf backup create --help
sf backup rollback --help
sf backup list --help
```

---

## Local Development Installation

For development or if you want to install from the source code:

### 1. Clone or Navigate to Plugin Directory

```bash
cd plugin-sf-backup
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Build the Plugin

```bash
npm run build
```

### 4. Link the Plugin Locally

```bash
sf plugins link
```

This creates a symlink so the SF CLI can use your local version.

### 5. Verify

```bash
sf plugins

# Should show:
sf-metadata-backup 1.0.0 (link) /path/to/plugin-sf-backup
```

### Development Mode

For active development:

```bash
# Watch for changes and rebuild
npm run build -- --watch
```

In another terminal:

```bash
# Test your changes
sf backup create --target-org myOrg
```

---

## Git Installation

Install directly from a Git repository:

```bash
sf plugins install https://github.com/yourusername/sf-metadata-backup
```

Or from a specific branch:

```bash
sf plugins install https://github.com/yourusername/sf-metadata-backup#develop
```

---

## Copy Scripts to Plugin

If you're building from the project, you need to copy the utility scripts:

### 1. Create Scripts Directory in Plugin

```bash
cd plugin-sf-backup
mkdir -p scripts
```

### 2. Copy Utility Scripts

```bash
# From the project root
cp scripts/backup/parse-buildfile.js plugin-sf-backup/scripts/
cp scripts/backup/combine-manifests.js plugin-sf-backup/scripts/
cp scripts/backup/generate-recovery-manifest.js plugin-sf-backup/scripts/
cp scripts/backup/generate-destructive-changes.js plugin-sf-backup/scripts/
cp scripts/backup/generate-rollback-buildfile.js plugin-sf-backup/scripts/
```

### 3. Update package.json Files

Add to `package.json` files array:

```json
{
  "files": [
    "/lib",
    "/messages",
    "/scripts",
    "/oclif.manifest.json"
  ]
}
```

---

## Verification

### Check Plugin Installation

```bash
sf plugins
```

Expected output:
```
sf-metadata-backup 1.0.0
```

### Check Commands Available

```bash
sf backup --help
```

Expected output:
```
USAGE
  $ sf backup COMMAND

COMMANDS
  backup create    Create a backup of Salesforce metadata before deployment
  backup list      List all available backups
  backup rollback  Rollback a deployment using a previously created backup
```

### Run Test Backup

```bash
# Create a test backup
sf backup create --target-org myDevOrg --manifest manifest/package.xml

# List backups
sf backup list

# Should show your new backup
```

---

## Updating the Plugin

### Update from NPM

```bash
sf plugins update
```

Or update specific plugin:

```bash
sf plugins install sf-metadata-backup@latest
```

### Update Local Development Version

```bash
cd plugin-sf-backup
git pull origin main
npm install
npm run build
```

---

## Uninstalling

### Remove Plugin

```bash
sf plugins uninstall sf-metadata-backup
```

### Unlink Local Development Plugin

```bash
cd plugin-sf-backup
sf plugins unlink
```

---

## Troubleshooting

### Issue: "Plugin not found"

**Cause:** Plugin not installed or not in plugin path

**Solution:**
```bash
# Reinstall
sf plugins install sf-metadata-backup

# Or check plugin directory
sf plugins --core
```

### Issue: "Command not found"

**Cause:** Plugin installed but commands not registered

**Solution:**
```bash
# Clear plugin cache
sf plugins uninstall sf-metadata-backup
sf plugins install sf-metadata-backup

# Rebuild local plugin
cd plugin-sf-backup
npm run clean
npm run build
sf plugins link
```

### Issue: "Module not found" errors

**Cause:** Dependencies not installed

**Solution:**
```bash
cd plugin-sf-backup
npm install
npm run build
```

### Issue: TypeScript compilation errors

**Cause:** TypeScript or dependencies out of date

**Solution:**
```bash
cd plugin-sf-backup
npm install --save-dev typescript@latest
npm install
npm run build
```

### Issue: Scripts not found

**Cause:** Utility scripts not copied to plugin directory

**Solution:**
```bash
cd plugin-sf-backup
mkdir -p scripts
cp ../scripts/backup/*.js scripts/
npm run build
```

---

## Advanced Configuration

### Custom Plugin Directory

Set a custom plugins directory:

```bash
export SF_PLUGINS_DIR=/path/to/custom/plugins
sf plugins install sf-metadata-backup
```

### Using with Multiple SF CLI Versions

If you have multiple SF CLI versions:

```bash
# Install for specific version
/path/to/sf/bin/sf plugins install sf-metadata-backup
```

---

## Environment Variables

The plugin respects these environment variables:

- `SF_PLUGINS_DIR`: Custom plugins directory
- `NODE_ENV`: Set to 'development' for debug output
- `DEBUG`: Set to 'sf-metadata-backup:*' for verbose logging

Example:

```bash
export DEBUG=sf-metadata-backup:*
sf backup create --target-org myOrg
```

---

## Next Steps

After installation:

1. **Read the README**: Check `README.md` for usage examples
2. **Try It Out**: Create a test backup in a sandbox
3. **Test Rollback**: Verify rollback works in sandbox
4. **Document**: Document your backup/rollback procedures
5. **CI/CD**: Integrate into your deployment pipeline

---

## Getting Help

- **Plugin Help**: `sf backup --help`
- **Command Help**: `sf backup create --help`
- **Issues**: Report issues on GitHub
- **Documentation**: See `README.md` for complete docs

---

## Publishing (For Maintainers)

### Prepare for Publishing

```bash
cd plugin-sf-backup
npm version patch  # or minor, or major
npm run prepack
```

### Publish to NPM

```bash
npm publish
```

### Create GitHub Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

**Installation complete!** Start using the plugin with:

```bash
sf backup create --target-org myOrg
```

