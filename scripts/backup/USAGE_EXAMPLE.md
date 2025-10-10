# Usage Examples

This document provides practical examples of using the Salesforce Backup and Rollback System.

## Quick Start

### 1. Initial Setup

```bash
cd scripts/backup
./setup.sh
```

This will:
- Check for required dependencies (Node.js, npm, Salesforce CLI)
- Install npm packages (xml2js)
- Install sf-orgdevmode-builds plugin if needed
- Create the backups directory

### 2. Create Your First Backup

Before deploying to production:

```bash
# Authenticate with your org (if not already done)
sf org login web --alias myProdOrg

# Create backup (choose your mode)
cd scripts/backup

# Option A: Using buildfile.json (sf-orgdevmode-builds mode)
./backup-metadata.sh myProdOrg

# Option B: Using package.xml (standard mode)
./backup-metadata.sh myProdOrg manifest/package.xml
```

**Output:**
```
═══════════════════════════════════════════════════════════
  Salesforce Metadata Backup System
═══════════════════════════════════════════════════════════
Target Org: myProdOrg
Buildfile: manifest/buildfile.json
Backup Directory: /path/to/backups/backup_20250110_143022
Timestamp: 20250110_143022

[1/6] Parsing buildfile.json...
Found manifest files:
  - manifest/package-omni.xml
  - manifest/package-1.xml
  - manifest/package-2.xml

[2/6] Extracting metadata types from manifests...
Combined manifest created: /path/to/backups/backup_20250110_143022/combined-manifest.xml

[3/6] Retrieving metadata from target org...
This may take several minutes depending on the amount of metadata...
...

[4/6] Generating recovery manifest...
Recovery manifest created: /path/to/backups/backup_20250110_143022/rollback/recovery-package.xml

[5/6] Generating destructive changes for new metadata...
Destructive changes created: /path/to/backups/backup_20250110_143022/rollback/destructive/destructiveChanges.xml

[6/6] Generating rollback buildfile...
Rollback buildfile created: /path/to/backups/backup_20250110_143022/rollback/buildfile.json

═══════════════════════════════════════════════════════════
  Backup Completed Successfully!
═══════════════════════════════════════════════════════════

Backup Archive: /path/to/backups/backup_20250110_143022.tar.gz
...
```

### 3. Deploy Your Changes

```bash
# Option A: Deploy using sf-orgdevmode-builds
sf builds deploy -b manifest/buildfile.json -u myProdOrg

# Option B: Deploy using standard CLI
sf project deploy start --manifest manifest/package.xml -u myProdOrg
```

### 4. Rollback (if needed)

If something goes wrong and you need to rollback:

```bash
cd backups/backup_20250110_143022/rollback
./deploy-rollback.sh
```

Or use the standalone script:

```bash
cd scripts/backup
./deploy-rollback.sh ../../backups/backup_20250110_143022/rollback myProdOrg
```

## Advanced Examples

### Using Custom Manifest Locations

```bash
# Custom buildfile location
./backup-metadata.sh myProdOrg custom/path/to/buildfile.json

# Custom package.xml location
./backup-metadata.sh myProdOrg custom/path/to/package.xml

# Specific package from multi-package project
./backup-metadata.sh myProdOrg manifest/package-critical.xml
```

### Automating Backups in CI/CD

#### GitHub Actions Example

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  backup-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli
      
      - name: Authenticate with Production
        run: |
          echo ${{ secrets.PROD_AUTH_URL }} > auth.txt
          sf org login sfdx-url --sfdx-url-file auth.txt --alias myProdOrg
      
      - name: Setup Backup System
        run: |
          cd scripts/backup
          ./setup.sh
      
      - name: Create Backup
        run: |
          cd scripts/backup
          ./backup-metadata.sh myProdOrg
      
      - name: Upload Backup as Artifact
        uses: actions/upload-artifact@v2
        with:
          name: backup-${{ github.sha }}
          path: backups/backup_*
          retention-days: 30
      
      - name: Deploy Changes
        run: |
          sf builds deploy -b manifest/buildfile.json -u myProdOrg
      
      - name: Rollback on Failure
        if: failure()
        run: |
          BACKUP_DIR=$(ls -td backups/backup_* | head -1)
          cd scripts/backup
          ./deploy-rollback.sh ../../${BACKUP_DIR}/rollback myProdOrg
```

#### GitLab CI Example

```yaml
stages:
  - backup
  - deploy
  - rollback

variables:
  BACKUP_DIR: ""

backup_production:
  stage: backup
  script:
    - cd scripts/backup
    - ./setup.sh
    - ./backup-metadata.sh $PROD_ORG_ALIAS
    - echo "BACKUP_DIR=$(ls -td ../../backups/backup_* | head -1)" > backup_dir.env
  artifacts:
    paths:
      - backups/
    reports:
      dotenv: scripts/backup/backup_dir.env
    expire_in: 30 days

deploy_production:
  stage: deploy
  dependencies:
    - backup_production
  script:
    - sf builds deploy -b manifest/buildfile.json -u $PROD_ORG_ALIAS
  only:
    - main

rollback_production:
  stage: rollback
  dependencies:
    - backup_production
  script:
    - cd scripts/backup
    - ./deploy-rollback.sh ${BACKUP_DIR}/rollback $PROD_ORG_ALIAS
  when: on_failure
  only:
    - main
```

### Scheduled Backups

Create a cron job for regular backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/project/scripts/backup && ./backup-metadata.sh myProdOrg >> /path/to/logs/backup.log 2>&1
```

### Manual Verification Before Rollback

```bash
# 1. Extract and review the backup
cd backups
tar -xzf backup_20250110_143022.tar.gz
cd backup_20250110_143022

# 2. Review the backup log
cat backup.log

# 3. Check the recovery manifest
cat rollback/recovery-package.xml

# 4. Check destructive changes
cat rollback/destructive/destructiveChanges.xml

# 5. Review rollback buildfile
cat rollback/buildfile.json

# 6. If everything looks good, deploy
cd rollback
./deploy-rollback.sh
```

## Common Scenarios

### Scenario 1: Deploying New Apex Classes

**Before deployment:**
```bash
./backup-metadata.sh myProdOrg
```

**What gets backed up:**
- Existing Apex classes (if any with the same names)
- Related triggers
- Test classes

**What gets created for rollback:**
- Recovery manifest with old versions
- Destructive changes to delete new classes

### Scenario 2: Updating Profiles and Permission Sets

**Before deployment:**
```bash
./backup-metadata.sh myProdOrg
```

**What gets backed up:**
- Current profile configurations
- Current permission set configurations
- Related object and field permissions

**What gets created for rollback:**
- Recovery manifest with old permissions
- Empty destructive changes (profiles/permissions are updated, not deleted)

### Scenario 3: Multiple Package Deployment

Your `buildfile.json`:
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

**Before deployment:**
```bash
./backup-metadata.sh myProdOrg
```

**What happens:**
- Both package-1.xml and package-2.xml are combined
- All metadata from both packages is retrieved
- A single rollback is created for both packages

### Scenario 4: Failed Deployment Recovery

**Your deployment failed midway:**
```bash
sf builds deploy -b manifest/buildfile.json -u myProdOrg
# ERROR: Deployment failed at package 2/3
```

**Rollback options:**

Option 1: Full rollback
```bash
cd scripts/backup
./deploy-rollback.sh ../../backups/backup_20250110_143022/rollback myProdOrg
```

Option 2: Partial rollback (if you know what failed)
```bash
# Edit the rollback buildfile to only rollback specific builds
cd backups/backup_20250110_143022/rollback
vi buildfile.json  # Remove builds that succeeded

# Deploy modified rollback
./deploy-rollback.sh
```

## Troubleshooting

### Issue: "No metadata found"

**Cause:** The manifest files reference metadata that doesn't exist in the org yet.

**Solution:** This is normal for new metadata. The backup will create destructive changes to remove it during rollback.

### Issue: Rollback fails with dependency errors

**Example error:**
```
Cannot delete ApexClass:MyClass because it's referenced by Flow:MyFlow
```

**Solution:**
```bash
# 1. Edit the rollback buildfile to split into multiple steps
cd backups/backup_20250110_143022/rollback
vi buildfile.json

# 2. Add a build to delete dependent metadata first
{
  "builds": [
    {
      "type": "metadata",
      "manifestFile": "destructive-flows.xml",
      "postDestructiveChanges": "destructive/destructiveChanges-flows.xml",
      ...
    },
    {
      "type": "metadata",
      "manifestFile": "destructive/package.xml",
      "postDestructiveChanges": "destructive/destructiveChanges.xml",
      ...
    },
    ...
  ]
}

# 3. Create separate destructive manifests
# (manually split destructiveChanges.xml into multiple files)

# 4. Deploy rollback
./deploy-rollback.sh
```

### Issue: Backup takes too long

**Solution:** Break your deployment into smaller packages with separate buildfiles, and create backups for each.

```bash
# Backup for package 1
./backup-metadata.sh myProdOrg manifest/buildfile-package1.json

# Deploy package 1
sf builds deploy -b manifest/buildfile-package1.json -u myProdOrg

# Backup for package 2
./backup-metadata.sh myProdOrg manifest/buildfile-package2.json

# Deploy package 2
sf builds deploy -b manifest/buildfile-package2.json -u myProdOrg
```

## Best Practices

1. **Always backup before production deployments**
2. **Keep backups for at least 30 days**
3. **Test rollback in sandbox first**
4. **Document any manual steps required for rollback**
5. **Archive backups to external storage**
6. **Review the backup log before deploying**
7. **Verify backup was successful before proceeding**

## Next Steps

- Read the [README.md](README.md) for detailed documentation
- Set up automated backups in your CI/CD pipeline
- Create a runbook for rollback procedures
- Train your team on the rollback process

