# Quick Start Guide - Testing SF Backup Plugin

Get up and running with the backup plugin test environment in 5 minutes!

## ⚡ Super Quick Start

```bash
# 1. Navigate to test project
cd test-project

# 2. Create a scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias backup-test --set-default --duration-days 7

# 3. Deploy initial metadata
sf project deploy start --manifest manifest/package.xml

# 4. Create your first backup
sf backup create --target-org backup-test --manifest manifest/package.xml

# 5. List backups
sf backup list

# 6. Test rollback (creates and deploys a rollback package)
sf backup rollback --target-org backup-test --backup-dir backups/backup_[USE_ACTUAL_TIMESTAMP_FROM_STEP_5]
```

## 🎯 What You Just Did

1. ✅ Created a Salesforce scratch org for testing
2. ✅ Deployed sample metadata (Apex classes, custom objects, LWC)
3. ✅ Created a backup of that metadata
4. ✅ Generated rollback packages (destructive changes + recovery manifest)
5. ✅ Tested the rollback process

## 📋 Pre-requisites Checklist

Before starting, ensure you have:

- [ ] Salesforce CLI installed (`sf --version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] Authenticated DevHub org for scratch orgs (`sf org list`)
- [ ] sf-metadata-backup plugin installed (see below)

### Install the Plugin

**From plugin directory:**
```bash
cd plugin-sf-backup
npm install
npm run build
sf plugins link
```

**Verify installation:**
```bash
sf plugins | grep backup
# Should show: sf-metadata-backup
```

## 🧪 Simple Test Scenarios

### Scenario A: Test with Package.xml (Standard Mode)

```bash
# Create backup
sf backup create --target-org backup-test --manifest manifest/package.xml

# Make a change to any file in force-app/
# For example, add a comment to AccountService.cls

# Deploy the change
sf project deploy start --manifest manifest/package.xml

# Rollback to original
BACKUP=$(ls -td backups/backup_* | head -1)
sf backup rollback --target-org backup-test --backup-dir $BACKUP
```

### Scenario B: Test with Buildfile.json (OrgDevMode)

```bash
# Install orgdevmode plugin if not already installed
sf plugins install sf-orgdevmode-builds

# Create backup with buildfile
sf backup create --target-org backup-test --manifest manifest/buildfile.json

# Make changes to multiple files

# Deploy using orgdevmode
sf builds deploy -b manifest/buildfile.json -u backup-test

# Rollback
BACKUP=$(ls -td backups/backup_* | head -1)
sf backup rollback --target-org backup-test --backup-dir $BACKUP
```

### Scenario C: Test Rollback Limitations

This tests what the plugin CAN'T fully rollback:

```bash
# 1. Create backup
sf backup create --target-org backup-test --manifest manifest/package.xml

# 2. Add NEW metadata
cp test-scenarios/new-files/OpportunityService.cls* force-app/main/default/classes/

# 3. Update manifest to include OpportunityService

# 4. Deploy new metadata
sf project deploy start --manifest manifest/package.xml

# 5. Attempt rollback
BACKUP=$(ls -td backups/backup_* | head -1)
sf backup rollback --target-org backup-test --backup-dir $BACKUP

# 6. Verify: OpportunityService will STILL exist in org
#    This is expected - see ROLLBACK_LIMITATIONS.md
```

## 📊 Verify Your Test

After each test, check:

```bash
# 1. Backup was created
ls -la backups/

# 2. Backup contains expected files
ls -la backups/backup_*/

# 3. Check backup structure
tree backups/backup_*/ -L 2

# 4. View backup log
cat backups/backup_*/backup.log

# 5. Inspect rollback configuration
cat backups/backup_*/rollback/buildfile.json

# 6. Check what would be deleted
cat backups/backup_*/rollback/destructive/destructiveChanges.xml

# 7. Check what would be restored
cat backups/backup_*/rollback/recovery-package.xml
```

## 🔍 Troubleshooting Quick Fixes

### "Command not found: sf"
```bash
# Install Salesforce CLI
npm install -g @salesforce/cli
```

### "No default org"
```bash
# Set default org
sf config set target-org=backup-test
```

### "Command backup not found"
```bash
# Link the plugin
cd plugin-sf-backup
sf plugins link
```

### "No DevHub authorized"
```bash
# Authorize a DevHub
sf org login web --set-default-dev-hub
```

### "Deployment failed: No test coverage"
```bash
# Add --test-level NoTestRun for testing
sf project deploy start --manifest manifest/package.xml --test-level NoTestRun
```

## 📚 What's Next?

1. **Read the full README:** [README.md](README.md)
2. **Try test scenarios:** [test-scenarios/TEST_INSTRUCTIONS.md](test-scenarios/TEST_INSTRUCTIONS.md)
3. **Understand limitations:** [../ROLLBACK_LIMITATIONS.md](../ROLLBACK_LIMITATIONS.md)
4. **Check plugin docs:** [../plugin-sf-backup/README.md](../plugin-sf-backup/README.md)

## 🎓 Understanding the Test Project

### What's Included

**Apex Classes:**
- `AccountService` - Service class for Account operations
- `ContactService` - Service class for Contact operations
- `AccountServiceTest` - Test coverage for AccountService

**Custom Objects:**
- `Project__c` - Custom object with 5 fields
  - Status__c (Picklist)
  - Start_Date__c (Date)
  - End_Date__c (Date)
  - Budget__c (Currency)
  - Description__c (Long Text Area)

**Lightning Web Components:**
- `accountList` - Displays accounts in a data table

**Manifests:**
- `package.xml` - Single manifest (standard mode)
- `buildfile.json` - Multi-phase deployment (orgdevmode)
- `phase1-classes.xml` - Apex classes only
- `phase2-objects.xml` - Custom objects only
- `phase3-components.xml` - LWC and additional classes

**Test Scenarios:**
- Modified versions of existing metadata
- New metadata to test additions
- Detailed test instructions

### Test Data Flow

```
1. Initial Deploy → Org State A
         ↓
2. Create Backup → Backup contains State A
         ↓
3. Deploy Changes → Org State B
         ↓
4. Rollback → Org back to State A (mostly)
```

## 🚀 Advanced Testing

Once comfortable with basics, try:

1. **CI/CD Simulation:** Test automated backup/rollback
2. **Multiple Backups:** Create several backups and roll back to specific ones
3. **Custom Backup Dir:** Use `--backup-dir custom-backups`
4. **Uncompressed Mode:** Use `--no-compress` flag
5. **Different Org Types:** Test with sandbox, developer edition

## ⚠️ Safety Reminders

- ✅ Always test in non-production orgs
- ✅ Review rollback packages before deploying
- ✅ Keep manual recovery procedures ready
- ✅ Understand what CAN'T be rolled back
- ✅ Document your testing process

## 📞 Getting Help

**Issues with the plugin?**
- Check [troubleshooting guide](README.md#troubleshooting)
- Review [known limitations](../ROLLBACK_LIMITATIONS.md)

**Issues with Salesforce CLI?**
- Run `sf doctor` for diagnostics
- Check [Salesforce CLI docs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/)

**Issues with metadata deployment?**
- Review deployment logs in target org
- Check dependencies between metadata
- Verify API version compatibility

## 🎉 Success Criteria

You'll know the plugin is working correctly when:

- ✅ Backups create without errors
- ✅ Backup directory has all expected files
- ✅ `sf backup list` shows your backups
- ✅ Rollback executes without errors
- ✅ Modified metadata is restored to original state
- ✅ New metadata attempts deletion (may remain due to limitations)

---

**Ready to dive deeper?** Check out the [full README](README.md) for comprehensive test scenarios!

