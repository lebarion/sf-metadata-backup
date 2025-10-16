# Test Scenarios - Detailed Instructions

This directory contains modified and new files to test various backup/rollback scenarios.

## 📁 Directory Structure

```
test-scenarios/
├── modified-files/          # Updated versions of existing files
│   ├── AccountService_v2.cls
│   ├── accountList_v2.js
│   └── accountList_v2.html
├── new-files/              # Completely new metadata
│   ├── OpportunityService.cls
│   ├── OpportunityService.cls-meta.xml
│   └── Project__c.Priority__c.field-meta.xml
└── TEST_INSTRUCTIONS.md    # This file
```

---

## 🧪 Test Case 1: Modifying Existing Apex Class

**Goal:** Test backup/rollback when an Apex class is modified

### Setup

1. Deploy original version:
   ```bash
   cd test-project
   sf project deploy start --manifest manifest/phase1-classes.xml -o backup-test
   ```

2. Create backup:
   ```bash
   sf backup create --target-org backup-test --manifest manifest/phase1-classes.xml
   ```

### Test Execution

3. Copy modified version:
   ```bash
   cp test-scenarios/modified-files/AccountService_v2.cls force-app/main/default/classes/AccountService.cls
   ```

4. Deploy modified version:
   ```bash
   sf project deploy start --manifest manifest/phase1-classes.xml -o backup-test
   ```

5. Verify changes in org:
   - Open Developer Console
   - Check AccountService.cls has new methods:
     - `getAccountsByIndustry()`
     - `deleteAccount()`
   - Verify enhanced query in `getAllAccounts()`

### Rollback Test

6. Execute rollback:
   ```bash
   BACKUP_DIR=$(ls -td backups/backup_* | head -1)
   sf backup rollback --target-org backup-test --backup-dir $BACKUP_DIR
   ```

7. Verify rollback:
   - Open Developer Console
   - Confirm new methods are REMOVED
   - Confirm original implementation is restored
   - No compilation errors

### Cleanup

8. Restore original file:
   ```bash
   git checkout force-app/main/default/classes/AccountService.cls
   ```

---

## 🧪 Test Case 2: Modifying Lightning Web Component

**Goal:** Test backup/rollback when LWC is modified

### Setup

1. Deploy original version:
   ```bash
   sf project deploy start --manifest manifest/phase3-components.xml -o backup-test
   ```

2. Create backup:
   ```bash
   sf backup create --target-org backup-test --manifest manifest/phase3-components.xml
   ```

### Test Execution

3. Copy modified versions:
   ```bash
   cp test-scenarios/modified-files/accountList_v2.js force-app/main/default/lwc/accountList/accountList.js
   cp test-scenarios/modified-files/accountList_v2.html force-app/main/default/lwc/accountList/accountList.html
   ```

4. Deploy modified version:
   ```bash
   sf project deploy start --manifest manifest/phase3-components.xml -o backup-test
   ```

5. Verify changes in org:
   - Navigate to App Builder
   - Add accountList component to a page
   - Verify new columns (Type, Annual Revenue)
   - Verify row selection works
   - Check enhanced error display

### Rollback Test

6. Execute rollback:
   ```bash
   BACKUP_DIR=$(ls -td backups/backup_* | head -1)
   sf backup rollback --target-org backup-test --backup-dir $BACKUP_DIR
   ```

7. Verify rollback:
   - Refresh the Lightning page
   - Confirm only original 3 columns shown
   - Confirm row selection is disabled
   - Original error display restored

### Cleanup

8. Restore original files:
   ```bash
   git checkout force-app/main/default/lwc/accountList/
   ```

---

## 🧪 Test Case 3: Adding New Apex Class

**Goal:** Test backup/rollback when NEW metadata is added

### Setup

1. Deploy original metadata:
   ```bash
   sf project deploy start --manifest manifest/package.xml -o backup-test
   ```

2. Create backup:
   ```bash
   sf backup create --target-org backup-test --manifest manifest/package.xml
   ```

### Test Execution

3. Copy new class:
   ```bash
   cp test-scenarios/new-files/OpportunityService.cls force-app/main/default/classes/
   cp test-scenarios/new-files/OpportunityService.cls-meta.xml force-app/main/default/classes/
   ```

4. Update manifest to include new class:
   ```bash
   # Add to manifest/package.xml under ApexClass:
   # <members>OpportunityService</members>
   ```

5. Deploy with new class:
   ```bash
   sf project deploy start --manifest manifest/package.xml -o backup-test
   ```

6. Verify in org:
   - Developer Console → File → Open → OpportunityService
   - Class should exist

### Rollback Test

7. Execute rollback:
   ```bash
   BACKUP_DIR=$(ls -td backups/backup_* | head -1)
   sf backup rollback --target-org backup-test --backup-dir $BACKUP_DIR
   ```

8. **⚠️ EXPECTED LIMITATION:**
   - OpportunityService class will likely STILL EXIST in org
   - This is a known limitation: new metadata is NOT removed by rollback
   - The destructiveChanges.xml is generated, but:
     - Salesforce doesn't allow deleting metadata with dependencies
     - Some metadata types cannot be deleted via API

9. Verify destructive changes were attempted:
   ```bash
   cat $BACKUP_DIR/rollback/destructive/destructiveChanges.xml
   # Should show OpportunityService in <members>
   ```

### Cleanup

10. Manually delete from org or:
    ```bash
    rm force-app/main/default/classes/OpportunityService.cls*
    # Restore original manifest
    git checkout manifest/package.xml
    ```

---

## 🧪 Test Case 4: Adding New Custom Field

**Goal:** Test backup/rollback when a custom field is added

### Setup

1. Deploy original object:
   ```bash
   sf project deploy start --manifest manifest/phase2-objects.xml -o backup-test
   ```

2. Create backup:
   ```bash
   sf backup create --target-org backup-test --manifest manifest/phase2-objects.xml
   ```

### Test Execution

3. Copy new field:
   ```bash
   cp test-scenarios/new-files/Project__c.Priority__c.field-meta.xml \
      force-app/main/default/objects/Project__c/fields/
   ```

4. Update manifest/phase2-objects.xml:
   ```xml
   <!-- Add under Project__c members -->
   <members>Project__c.Priority__c</members>
   ```

5. Deploy with new field:
   ```bash
   sf project deploy start --manifest manifest/phase2-objects.xml -o backup-test
   ```

6. Verify in org:
   - Setup → Object Manager → Project
   - Fields & Relationships → Priority__c should exist

### Rollback Test

7. Execute rollback:
   ```bash
   BACKUP_DIR=$(ls -td backups/backup_* | head -1)
   sf backup rollback --target-org backup-test --backup-dir $BACKUP_DIR
   ```

8. **⚠️ EXPECTED LIMITATION:**
   - Priority__c field will STILL EXIST in org
   - Cannot delete custom fields that are:
     - Referenced in layouts
     - Referenced in code
     - Contain data
   - This is a core Salesforce limitation, not plugin limitation

9. Check destructive changes:
   ```bash
   cat $BACKUP_DIR/rollback/destructive/destructiveChanges.xml
   # Should show Project__c.Priority__c
   ```

### Cleanup

10. Manually delete field from org:
    - Setup → Object Manager → Project → Fields → Priority__c → Delete

---

## 🧪 Test Case 5: Complete Multi-Phase Scenario

**Goal:** Test full deployment lifecycle with buildfile.json

### Prerequisites

```bash
sf plugins install sf-orgdevmode-builds
```

### Setup

1. Deploy Phase 1 (Classes):
   ```bash
   sf project deploy start --manifest manifest/phase1-classes.xml -o backup-test
   ```

2. Deploy Phase 2 (Objects):
   ```bash
   sf project deploy start --manifest manifest/phase2-objects.xml -o backup-test
   ```

3. Deploy Phase 3 (Components):
   ```bash
   sf project deploy start --manifest manifest/phase3-components.xml -o backup-test
   ```

4. Create comprehensive backup:
   ```bash
   sf backup create --target-org backup-test --manifest manifest/buildfile.json
   ```

### Test Execution

5. Make changes to multiple files:
   ```bash
   # Modify Apex
   cp test-scenarios/modified-files/AccountService_v2.cls force-app/main/default/classes/AccountService.cls
   
   # Modify LWC
   cp test-scenarios/modified-files/accountList_v2.js force-app/main/default/lwc/accountList/accountList.js
   cp test-scenarios/modified-files/accountList_v2.html force-app/main/default/lwc/accountList/accountList.html
   
   # Add new class
   cp test-scenarios/new-files/OpportunityService.cls* force-app/main/default/classes/
   
   # Add new field
   cp test-scenarios/new-files/Project__c.Priority__c.field-meta.xml \
      force-app/main/default/objects/Project__c/fields/
   ```

6. Update manifests to include new metadata

7. Deploy all changes using buildfile:
   ```bash
   sf builds deploy -b manifest/buildfile.json -u backup-test
   ```

### Rollback Test

8. Execute comprehensive rollback:
   ```bash
   BACKUP_DIR=$(ls -td backups/backup_* | head -1)
   sf backup rollback --target-org backup-test --backup-dir $BACKUP_DIR
   ```

9. Verify rollback:
   - ✅ AccountService restored to v1
   - ✅ accountList restored to original
   - ⚠️ OpportunityService still exists (expected limitation)
   - ⚠️ Priority__c field still exists (expected limitation)

10. Review logs:
    ```bash
    cat $BACKUP_DIR/backup.log
    cat $BACKUP_DIR/rollback/buildfile.json
    ```

---

## 📊 Results Tracking

Use this template to track your test results:

### Test Case: [Number and Name]

**Date/Time:** [timestamp]

**Org Info:**
- Type: [Scratch/Sandbox/Developer]
- Alias: backup-test
- Username: [username]

**Backup Details:**
- Backup Dir: backups/backup_[timestamp]
- Mode: [standard/orgdevmode]
- Compressed: [Yes/No]
- Size: [X MB]

**Changes Made:**
- [List of modifications]

**Rollback Results:**
| Metadata Type | Expected Behavior | Actual Result | Status |
|---------------|-------------------|---------------|--------|
| Modified Apex | Restored to v1    | ✅ Restored    | PASS   |
| New Apex      | Remains in org    | ✅ Remains     | PASS*  |
| Modified LWC  | Restored to v1    | ✅ Restored    | PASS   |
| New Field     | Remains in org    | ✅ Remains     | PASS*  |

*Expected limitation as documented

**Issues/Notes:**
- [Any unexpected behavior]
- [Performance observations]
- [Recommendations]

---

## 🎯 Testing Best Practices

1. **Always test in scratch orgs or sandboxes**
2. **Document every step and result**
3. **Understand expected limitations before testing**
4. **Keep backup directories organized**
5. **Clean up test metadata after testing**
6. **Test both success and failure scenarios**

---

## 📚 Reference Documentation

- [Main README](../README.md)
- [Plugin README](../../plugin-sf-backup/README.md)
- [Rollback Limitations](../../ROLLBACK_LIMITATIONS.md)

---

## ❓ Need Help?

If tests fail unexpectedly:

1. Check backup.log for detailed information
2. Verify manifest files are correct
3. Confirm all prerequisites are installed
4. Review Salesforce deployment logs in target org
5. Check for API version compatibility

For known issues, see [ROLLBACK_LIMITATIONS.md](../../ROLLBACK_LIMITATIONS.md)

