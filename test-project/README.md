# SF Backup Plugin - Test Project

This is a comprehensive test project for the `sf-metadata-backup` CLI plugin. It includes sample Salesforce metadata to test backup and rollback capabilities in various scenarios.

## 📋 Project Structure

```
test-project/
├── force-app/main/default/          # Main source directory
│   ├── classes/                     # Apex classes
│   │   ├── AccountService.cls
│   │   ├── ContactService.cls
│   │   └── AccountServiceTest.cls
│   ├── objects/                     # Custom objects
│   │   └── Project__c/
│   │       ├── Project__c.object-meta.xml
│   │       └── fields/
│   │           ├── Status__c.field-meta.xml
│   │           ├── Start_Date__c.field-meta.xml
│   │           ├── End_Date__c.field-meta.xml
│   │           ├── Budget__c.field-meta.xml
│   │           └── Description__c.field-meta.xml
│   └── lwc/                         # Lightning Web Components
│       └── accountList/
├── manifest/                        # Deployment manifests
│   ├── package.xml                  # Standard single manifest
│   ├── buildfile.json              # OrgDevMode buildfile
│   ├── phase1-classes.xml          # Multi-phase deployment
│   ├── phase2-objects.xml
│   └── phase3-components.xml
├── test-scenarios/                  # Modified versions for testing
│   ├── modified-files/             # Updated metadata for changes
│   └── new-files/                  # New metadata for additions
└── config/                         # Project configuration
    └── project-scratch-def.json
```

## 🚀 Quick Start

### Prerequisites

1. **Salesforce CLI** installed (`sf` command available)
2. **sf-metadata-backup plugin** installed:
   ```bash
   cd plugin-sf-backup
   npm install
   npm run build
   sf plugins link
   ```
3. **Access to a Salesforce org** (scratch org, sandbox, or developer edition)

### Setup Test Environment

1. **Navigate to test project:**
   ```bash
   cd test-project
   ```

2. **Option A: Create a Scratch Org**
   ```bash
   sf org create scratch --definition-file config/project-scratch-def.json --alias backup-test --set-default --duration-days 7
   ```

3. **Option B: Use Existing Org**
   ```bash
   sf org login web --alias backup-test --set-default
   ```

4. **Deploy initial metadata:**
   ```bash
   # Standard mode
   sf project deploy start --manifest manifest/package.xml

   # Or using OrgDevMode (requires sf-orgdevmode-builds plugin)
   sf plugins install sf-orgdevmode-builds
   sf builds deploy -b manifest/buildfile.json -u backup-test
   ```

## 🧪 Test Scenarios

### Scenario 1: Standard Mode - Simple Backup & Rollback

**Test Goal:** Verify basic backup and rollback functionality with a single package.xml

**Steps:**

1. **Create initial backup:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/package.xml
   ```

2. **Verify backup created:**
   ```bash
   sf backup list
   ```

3. **Make changes to the org** (modify a class, add a field, etc.)

4. **Deploy changes:**
   ```bash
   sf project deploy start --manifest manifest/package.xml
   ```

5. **Test rollback:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

6. **Verify rollback:** Check that changes were reverted in the org

**Expected Results:**
- ✅ Backup creates compressed archive
- ✅ Rollback restores original metadata
- ✅ No errors during backup or rollback process

---

### Scenario 2: OrgDevMode - Multi-Phase Deployment

**Test Goal:** Test backup/rollback with buildfile.json and multiple manifests

**Prerequisites:**
```bash
sf plugins install sf-orgdevmode-builds
```

**Steps:**

1. **Create backup using buildfile:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/buildfile.json
   ```

2. **Verify combined manifest generated:**
   ```bash
   cat backups/backup_[TIMESTAMP]/combined-manifest.xml
   ```

3. **Inspect rollback buildfile:**
   ```bash
   cat backups/backup_[TIMESTAMP]/rollback/buildfile.json
   ```

4. **Make changes and deploy:**
   ```bash
   sf builds deploy -b manifest/buildfile.json -u backup-test
   ```

5. **Rollback using generated buildfile:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

**Expected Results:**
- ✅ All three phase manifests are combined
- ✅ Rollback buildfile references correct manifests
- ✅ Multi-phase rollback executes in correct order

---

### Scenario 3: Testing Metadata Changes

**Test Goal:** Test backup/rollback with various types of metadata changes

#### 3a. Modified Apex Class

1. **Create backup:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/phase1-classes.xml
   ```

2. **Modify AccountService.cls** (add a new method):
   ```apex
   /**
    * Get accounts by industry
    */
   public static List<Account> getAccountsByIndustry(String industry) {
       return [SELECT Id, Name, Industry FROM Account WHERE Industry = :industry];
   }
   ```

3. **Deploy changes:**
   ```bash
   sf project deploy start --manifest manifest/phase1-classes.xml
   ```

4. **Rollback to original:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

5. **Verify:** New method should be removed

#### 3b. Add New Custom Field

1. **Create backup:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/phase2-objects.xml
   ```

2. **Add new field** to `Project__c`:
   ```bash
   # Create Priority__c.field-meta.xml in force-app/main/default/objects/Project__c/fields/
   ```

3. **Update manifest** to include new field

4. **Deploy:**
   ```bash
   sf project deploy start --manifest manifest/phase2-objects.xml
   ```

5. **Rollback:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

**⚠️ Expected Limitation:** New field will NOT be removed by rollback (see ROLLBACK_LIMITATIONS.md)

#### 3c. Modify Lightning Web Component

1. **Create backup:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/phase3-components.xml
   ```

2. **Modify accountList.js** (add a new column)

3. **Deploy changes:**
   ```bash
   sf project deploy start --manifest manifest/phase3-components.xml
   ```

4. **Rollback:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

5. **Verify:** Component should revert to original

---

### Scenario 4: Testing Destructive Changes

**Test Goal:** Verify that rollback properly handles metadata that was removed

1. **Create backup with all metadata:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/package.xml
   ```

2. **Remove ContactService.cls from org** (don't delete file, just undeploy)

3. **Rollback:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

4. **Verify:** ContactService.cls should be restored

---

### Scenario 5: Uncompressed Backup

**Test Goal:** Test backup without compression

**Steps:**

1. **Create uncompressed backup:**
   ```bash
   sf backup create --target-org backup-test --manifest manifest/package.xml --no-compress
   ```

2. **Verify no .tar.gz created:**
   ```bash
   ls -la backups/backup_[TIMESTAMP]/
   ```

3. **Rollback should still work:**
   ```bash
   sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]
   ```

---

### Scenario 6: CI/CD Simulation

**Test Goal:** Simulate automated backup and rollback in CI/CD pipeline

**Steps:**

1. **Automated backup before deployment:**
   ```bash
   # This would be in your CI/CD script
   sf backup create --target-org backup-test --manifest manifest/buildfile.json
   
   # Store the backup directory
   BACKUP_DIR=$(ls -td backups/backup_* | head -1)
   echo "BACKUP_DIR=$BACKUP_DIR" >> $GITHUB_ENV
   ```

2. **Deploy changes:**
   ```bash
   sf builds deploy -b manifest/buildfile.json -u backup-test
   ```

3. **On deployment failure, automatic rollback:**
   ```bash
   if [ $? -ne 0 ]; then
     echo "Deployment failed, rolling back..."
     sf backup rollback --target-org backup-test --backup-dir $BACKUP_DIR --no-confirm
   fi
   ```

---

## 📊 Validation Checklist

After each test scenario, verify:

- [ ] Backup directory created with timestamp
- [ ] `backup.log` contains complete operation log
- [ ] `combined-manifest.xml` has all metadata types
- [ ] `metadata/` directory contains retrieved metadata
- [ ] `rollback/buildfile.json` is properly formatted
- [ ] `rollback/recovery-package.xml` references existing metadata
- [ ] `rollback/destructive/destructiveChanges.xml` has new metadata
- [ ] `.tar.gz` archive created (unless --no-compress)
- [ ] Rollback command executes without errors
- [ ] Org metadata state matches expected after rollback

---

## 🔍 Troubleshooting

### Issue: "Manifest not found"
**Solution:** Verify you're in the `test-project` directory and manifest files exist

### Issue: "Org not authenticated"
**Solution:** 
```bash
sf org login web --alias backup-test
```

### Issue: "sf-orgdevmode-builds plugin not found"
**Solution:**
```bash
sf plugins install sf-orgdevmode-builds
```

### Issue: Rollback fails with dependency errors
**Solution:** 
- Check deployment order in buildfile.json
- Some metadata types have dependencies (e.g., Apex classes before LWC)
- Try rolling back in reverse order of original deployment

---

## 📝 Test Results Template

Use this template to document your test results:

```markdown
## Test Run: [Date/Time]

### Environment
- Org Type: [Scratch/Sandbox/Developer]
- SF CLI Version: [version]
- Plugin Version: [version]

### Scenario: [Scenario Name]

**Steps Executed:**
1. [step]
2. [step]

**Results:**
- Backup created: ✅/❌
- Rollback executed: ✅/❌
- Metadata restored: ✅/❌

**Issues Found:**
- [issue description]

**Notes:**
- [additional observations]
```

---

## 🎯 Advanced Testing

### Test Custom Backup Directory

```bash
sf backup create --target-org backup-test --manifest manifest/package.xml --backup-dir custom-backups
```

### Test Multiple Backups

```bash
# Create multiple backups
sf backup create --target-org backup-test --manifest manifest/phase1-classes.xml
sf backup create --target-org backup-test --manifest manifest/phase2-objects.xml
sf backup create --target-org backup-test --manifest manifest/phase3-components.xml

# List all backups
sf backup list

# Rollback specific backup
sf backup rollback --target-org backup-test --backup-dir backups/backup_[SPECIFIC_TIMESTAMP]
```

### Test with Different Org Types

- **Scratch Org:** Fast, isolated testing
- **Sandbox:** Production-like environment
- **Developer Edition:** Long-term testing

---

## 🛡️ Safety Considerations

**⚠️ IMPORTANT:** Always test in a non-production environment first!

1. **Never test directly in production**
2. **Review rollback packages before deploying**
3. **Understand rollback limitations** (see ROLLBACK_LIMITATIONS.md)
4. **Keep manual recovery procedures ready**
5. **Monitor deployments closely**

---

## 📚 Additional Resources

- [Plugin README](../plugin-sf-backup/README.md)
- [Rollback Limitations](../ROLLBACK_LIMITATIONS.md)
- [Salesforce CLI Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [OrgDevMode Builds Plugin](https://github.com/tiagonnascimento/sf-orgdevmode-builds)

---

## 🤝 Contributing Test Scenarios

Found a useful test scenario? Please add it to this README via pull request!

Include:
- Clear test goal
- Step-by-step instructions
- Expected results
- Known limitations or edge cases

---

## 📄 License

This test project is part of the sf-metadata-backup plugin and follows the same MIT license.

