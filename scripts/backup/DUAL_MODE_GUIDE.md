# Dual Mode Support Guide

The Salesforce Backup and Rollback System supports **two deployment modes**, making it versatile for different project setups.

## Mode Detection

The system automatically detects which mode to use based on the file extension:

- **`.json`** → `orgdevmode` mode (sf-orgdevmode-builds)
- **`.xml`** → `standard` mode (single package.xml)

## Mode 1: sf-orgdevmode-builds (buildfile.json)

### When to Use
- You're using the [sf-orgdevmode-builds](https://github.com/tiagonnascimento/sf-orgdevmode-builds) plugin
- You have multiple package.xml files to deploy in sequence
- You need complex deployment workflows (metadata + datapacks + apex scripts)
- You want to manage deployment dependencies

### How It Works

1. **Backup Phase:**
   ```bash
   ./backup-metadata.sh myProdOrg manifest/buildfile.json
   ```
   - Parses buildfile.json
   - Extracts all manifest files from builds
   - Combines them into a single manifest
   - Retrieves metadata from org

2. **Rollback Generation:**
   - Creates `buildfile.json` with sf-orgdevmode-builds format
   - Two-step rollback process:
     1. Destructive changes (remove new metadata)
     2. Recovery deployment (restore old metadata)

3. **Rollback Execution:**
   ```bash
   cd backups/backup_*/rollback
   ./deploy-rollback.sh myProdOrg
   ```
   - Uses `sf builds deploy` command
   - Follows sf-orgdevmode-builds standards

### Example buildfile.json Input

```json
{
  "builds": [
    {
      "type": "metadata",
      "manifestFile": "manifest/package-1.xml",
      "testLevel": "RunLocalTests"
    },
    {
      "type": "metadata",
      "manifestFile": "manifest/package-2.xml",
      "testLevel": "RunLocalTests"
    }
  ]
}
```

### Generated Rollback buildfile.json

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

---

## Mode 2: Standard (package.xml)

### When to Use
- You're using standard Salesforce CLI commands
- You have a single package.xml file
- You don't need the sf-orgdevmode-builds plugin
- You want a simpler deployment process

### How It Works

1. **Backup Phase:**
   ```bash
   ./backup-metadata.sh myProdOrg manifest/package.xml
   ```
   - Uses package.xml directly
   - No parsing needed
   - Retrieves metadata from org

2. **Rollback Generation:**
   - Creates `buildfile.json` documenting CLI commands
   - Two-step rollback process (same as orgdevmode):
     1. Destructive changes
     2. Recovery deployment

3. **Rollback Execution:**
   ```bash
   cd backups/backup_*/rollback
   ./deploy-rollback.sh myProdOrg
   ```
   - Uses standard `sf project deploy start` commands
   - Executes each step sequentially

### Example package.xml Input

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>MyApexClass</members>
        <members>MyOtherClass</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>MyTrigger</members>
        <name>ApexTrigger</name>
    </types>
    <version>61.0</version>
</Package>
```

### Generated Rollback buildfile.json

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

---

## Comparison

| Feature | orgdevmode Mode | standard Mode |
|---------|----------------|---------------|
| **Input File** | buildfile.json | package.xml |
| **Plugin Required** | sf-orgdevmode-builds | None |
| **Multi-Package Support** | ✅ Yes | ❌ No (single package) |
| **Rollback Command** | `sf builds deploy` | `sf project deploy start` |
| **Rollback Format** | buildfile.json (builds array) | buildfile.json (steps array) |
| **Use Case** | Complex deployments | Simple deployments |
| **Setup Complexity** | Medium | Low |

---

## Choosing the Right Mode

### Use **orgdevmode** mode if:
- ✅ You already use sf-orgdevmode-builds
- ✅ You have multiple package.xml files
- ✅ You need to deploy in a specific order
- ✅ You want to combine metadata, datapacks, and scripts

### Use **standard** mode if:
- ✅ You have a single package.xml
- ✅ You want to keep it simple
- ✅ You don't want additional plugins
- ✅ You're new to Salesforce deployments

---

## Switching Between Modes

You can use different modes for different deployments:

```bash
# Monday: Deploy using orgdevmode
./backup-metadata.sh myOrg manifest/buildfile.json
sf builds deploy -b manifest/buildfile.json -u myOrg

# Tuesday: Deploy using standard
./backup-metadata.sh myOrg manifest/hotfix-package.xml
sf project deploy start --manifest manifest/hotfix-package.xml -u myOrg
```

Each backup is independent and mode-specific.

---

## Mixed Projects

If your project has both buildfile.json and package.xml files:

1. **Use buildfile.json for comprehensive deployments:**
   ```bash
   ./backup-metadata.sh myOrg manifest/buildfile.json
   ```

2. **Use package.xml for quick hotfixes:**
   ```bash
   ./backup-metadata.sh myOrg manifest/hotfix.xml
   ```

---

## CI/CD Integration

### GitHub Actions - Dual Mode Example

```yaml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      deployment_type:
        description: 'Deployment type'
        required: true
        type: choice
        options:
          - full-deployment
          - hotfix

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup
        run: |
          cd scripts/backup
          ./setup.sh
      
      - name: Backup (Full Deployment)
        if: inputs.deployment_type == 'full-deployment'
        run: |
          cd scripts/backup
          ./backup-metadata.sh myProdOrg manifest/buildfile.json
      
      - name: Backup (Hotfix)
        if: inputs.deployment_type == 'hotfix'
        run: |
          cd scripts/backup
          ./backup-metadata.sh myProdOrg manifest/hotfix.xml
      
      - name: Deploy (Full)
        if: inputs.deployment_type == 'full-deployment'
        run: |
          sf builds deploy -b manifest/buildfile.json -u myProdOrg
      
      - name: Deploy (Hotfix)
        if: inputs.deployment_type == 'hotfix'
        run: |
          sf project deploy start --manifest manifest/hotfix.xml -u myProdOrg
```

---

## Best Practices

1. **📁 Organize Your Manifests**
   ```
   manifest/
   ├── buildfile.json          # Full deployment
   ├── package-full.xml        # Complete package
   ├── package-critical.xml    # Critical changes only
   └── hotfix/
       └── package.xml         # Emergency fixes
   ```

2. **🏷️ Name Your Backups**
   ```bash
   # The system uses timestamps, but you can add notes in backup.log
   echo "DEPLOYMENT: Critical hotfix for bug #123" >> backups/backup_*/backup.log
   ```

3. **🔄 Test Both Modes**
   - Test rollback for orgdevmode in sandbox
   - Test rollback for standard mode in sandbox
   - Document which mode to use when

4. **📝 Document Your Strategy**
   ```markdown
   # Deployment Strategy
   
   ## Full Releases (Monthly)
   - Use: manifest/buildfile.json
   - Mode: orgdevmode
   - Tests: RunLocalTests
   
   ## Hotfixes (As needed)
   - Use: manifest/hotfix.xml
   - Mode: standard
   - Tests: RunSpecifiedTests
   ```

---

## Troubleshooting

### Issue: "Manifest source must be a .json or .xml file"

**Cause:** The file extension is not recognized.

**Solution:** Ensure your file ends with `.json` or `.xml`

```bash
# Wrong
./backup-metadata.sh myOrg manifest/buildfile.txt

# Right
./backup-metadata.sh myOrg manifest/buildfile.json
./backup-metadata.sh myOrg manifest/package.xml
```

### Issue: Rollback uses wrong command

**Cause:** The backup was created in a different mode.

**Solution:** Check the `backup.log` for the deployment mode:

```bash
cat backups/backup_*/backup.log | grep "Deployment Mode"
```

### Issue: Plugin not found in standard mode

**Cause:** The deploy script is trying to use sf-orgdevmode-builds in standard mode.

**Solution:** This shouldn't happen (the script auto-detects), but if it does:

```bash
# Manually run the rollback
cd backups/backup_*/rollback
sf project deploy start --manifest recovery-package.xml -u myOrg
```

---

## FAQ

**Q: Can I convert a buildfile.json backup to standard mode?**  
A: No, but you can create a new backup using the package.xml directly.

**Q: Which mode is faster?**  
A: Both are equally fast for the backup. Rollback speed depends on metadata size, not mode.

**Q: Can I use orgdevmode buildfile with standard CLI?**  
A: No, you need the sf-orgdevmode-builds plugin for buildfile.json rollbacks.

**Q: What if I'm not sure which mode to use?**  
A: Start with standard mode (package.xml) - it's simpler. Upgrade to orgdevmode when you need multi-package deployments.

---

For more information:
- [README.md](README.md) - Full documentation
- [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) - Practical examples
- [sf-orgdevmode-builds](https://github.com/tiagonnascimento/sf-orgdevmode-builds) - Plugin documentation

