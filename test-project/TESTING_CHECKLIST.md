# SF Backup Plugin - Testing Checklist

Use this checklist to track your testing progress for the sf-metadata-backup plugin.

## 📋 Prerequisites Setup

- [ ] Salesforce CLI installed and updated (`sf --version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] DevHub authorized (`sf org list` shows DevHub)
- [ ] Plugin built and linked
  ```bash
  cd plugin-sf-backup
  npm install
  npm run build
  sf plugins link
  ```
- [ ] Plugin visible in plugin list (`sf plugins | grep backup`)

---

## 🚀 Initial Setup Tests

### Test Environment Setup

- [ ] Navigate to test-project directory
- [ ] Run automated setup: `./scripts/setup-test-org.sh`
- [ ] Verify scratch org created: `sf org list`
- [ ] Open org successfully: `sf org open --target-org backup-test`
- [ ] Verify metadata deployed:
  - [ ] AccountService class visible in org
  - [ ] ContactService class visible in org
  - [ ] Project__c object visible in org
  - [ ] accountList LWC visible in org

### Manual Setup Alternative

- [ ] Create scratch org: `sf org create scratch --definition-file config/project-scratch-def.json --alias backup-test`
- [ ] Deploy metadata: `sf project deploy start --manifest manifest/package.xml`
- [ ] Verify deployment successful

---

## 🧪 Core Functionality Tests

### Test 1: Basic Backup Creation

**Standard Mode (package.xml)**

- [ ] Create backup: `sf backup create --target-org backup-test --manifest manifest/package.xml`
- [ ] Command completes without errors
- [ ] Backup directory created with timestamp
- [ ] Backup contains:
  - [ ] `backup.log` file
  - [ ] `combined-manifest.xml`
  - [ ] `metadata/` directory with retrieved files
  - [ ] `rollback/` directory
  - [ ] `rollback/buildfile.json`
  - [ ] `rollback/recovery-package.xml`
  - [ ] `rollback/destructive/` directory
  - [ ] `.tar.gz` archive created

**OrgDevMode (buildfile.json)**

- [ ] Install orgdevmode plugin: `sf plugins install sf-orgdevmode-builds`
- [ ] Create backup: `sf backup create --target-org backup-test --manifest manifest/buildfile.json`
- [ ] Command completes without errors
- [ ] Backup directory created
- [ ] Combined manifest includes all 3 phases
- [ ] Rollback buildfile has correct structure

### Test 2: List Backups

- [ ] Run: `sf backup list`
- [ ] Shows created backup(s)
- [ ] Displays timestamp correctly
- [ ] Shows deployment mode (standard/orgdevmode)
- [ ] Shows compressed status
- [ ] Shows size information

### Test 3: Uncompressed Backup

- [ ] Create backup with: `sf backup create --target-org backup-test --manifest manifest/package.xml --no-compress`
- [ ] Backup directory created
- [ ] No `.tar.gz` file created
- [ ] All backup files present

---

## 🔄 Rollback Functionality Tests

### Test 4: Rollback Modified Apex Class

- [ ] Create backup of AccountService
- [ ] Modify AccountService.cls (add a method)
- [ ] Deploy changes
- [ ] Verify changes in org (new method exists)
- [ ] Execute rollback: `sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]`
- [ ] Rollback completes without errors
- [ ] Retrieve class from org
- [ ] Verify original version restored (new method removed)

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 5: Rollback Modified LWC

- [ ] Create backup of accountList component
- [ ] Modify accountList.js (add columns)
- [ ] Deploy changes
- [ ] Verify changes in org (new columns visible)
- [ ] Execute rollback
- [ ] Verify original version restored (new columns removed)

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 6: New Metadata Addition (Expected Limitation)

- [ ] Create backup
- [ ] Add NEW class (OpportunityService.cls from test-scenarios/new-files/)
- [ ] Deploy new class
- [ ] Verify new class exists in org
- [ ] Execute rollback
- [ ] **Expected:** New class STILL exists in org (limitation)
- [ ] Verify destructiveChanges.xml includes the new class
- [ ] Document this expected behavior

**Result:** ✅ Pass (limitation documented) / ❌ Fail  
**Notes:** _________________________________

### Test 7: New Custom Field Addition (Expected Limitation)

- [ ] Create backup
- [ ] Add NEW field (Priority__c from test-scenarios/new-files/)
- [ ] Deploy new field
- [ ] Verify new field exists in org
- [ ] Execute rollback
- [ ] **Expected:** New field STILL exists in org (limitation)
- [ ] Verify destructiveChanges.xml includes the new field
- [ ] Document this expected behavior

**Result:** ✅ Pass (limitation documented) / ❌ Fail  
**Notes:** _________________________________

---

## 🔧 Advanced Testing

### Test 8: Multi-Phase OrgDevMode Deployment

- [ ] Create backup: `sf backup create --target-org backup-test --manifest manifest/buildfile.json`
- [ ] Verify buildfile.json includes all 3 phases
- [ ] Modify files from multiple phases
- [ ] Deploy using: `sf builds deploy -b manifest/buildfile.json -u backup-test`
- [ ] Execute rollback
- [ ] Verify all phases rolled back correctly

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 9: Automated Full Test Cycle

- [ ] Run: `./scripts/run-full-test.sh backup-test standard`
- [ ] Script completes without errors
- [ ] All 8 steps execute successfully
- [ ] Final verification passes
- [ ] Test summary shows all green checks

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 10: Custom Backup Directory

- [ ] Create backup with custom dir: `sf backup create --target-org backup-test --manifest manifest/package.xml --backup-dir custom-backups`
- [ ] Backup created in custom-backups/
- [ ] List custom backups: `sf backup list --backup-dir custom-backups`
- [ ] Rollback from custom directory works

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 11: No-Confirm Rollback Flag

- [ ] Create backup
- [ ] Execute rollback with: `sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP] --no-confirm`
- [ ] No confirmation prompt appears
- [ ] Rollback executes immediately

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

---

## 📊 Error Handling Tests

### Test 12: Invalid Manifest Path

- [ ] Run: `sf backup create --target-org backup-test --manifest invalid/path.xml`
- [ ] Error message displayed
- [ ] No backup directory created
- [ ] Error is clear and helpful

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 13: Invalid Org Alias

- [ ] Run: `sf backup create --target-org nonexistent-org --manifest manifest/package.xml`
- [ ] Error message displayed
- [ ] Error indicates org not found

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 14: Rollback Non-Existent Backup

- [ ] Run: `sf backup rollback --target-org backup-test --backup-dir backups/nonexistent`
- [ ] Error message displayed
- [ ] Error indicates backup not found

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

---

## 🎯 Real-World Scenarios

### Test 15: Hotfix Simulation

- [ ] Deploy to "production" (test org)
- [ ] Create pre-deployment backup
- [ ] Deploy hotfix changes
- [ ] Hotfix causes issue
- [ ] Rollback successfully
- [ ] Verify production state restored

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

### Test 16: CI/CD Simulation

- [ ] Create backup (automated step)
- [ ] Store backup directory variable
- [ ] Deploy changes (automated step)
- [ ] Simulate failure condition
- [ ] Auto-rollback using stored directory
- [ ] Verify rollback successful

**Result:** ✅ Pass / ❌ Fail  
**Notes:** _________________________________

---

## 🔍 Validation Checks

### Backup File Integrity

For each backup created, verify:

- [ ] `backup.log` contains complete log
- [ ] `combined-manifest.xml` is valid XML
- [ ] `combined-manifest.xml` includes all expected metadata
- [ ] `metadata/` contains retrieved files
- [ ] `rollback/buildfile.json` is valid JSON
- [ ] `rollback/recovery-package.xml` is valid XML
- [ ] `rollback/destructive/package.xml` is valid XML
- [ ] `rollback/destructive/destructiveChanges.xml` is valid XML
- [ ] Archive file is not corrupted (if compressed)

### Rollback Package Validation

- [ ] Recovery manifest includes only existing metadata
- [ ] Destructive changes includes only new metadata
- [ ] Buildfile has correct mode setting
- [ ] Manifest references are correct paths
- [ ] API version is consistent

---

## 📝 Documentation Review

- [ ] README.md is clear and comprehensive
- [ ] QUICK_START.md provides fast onboarding
- [ ] TEST_INSTRUCTIONS.md has detailed steps
- [ ] ROLLBACK_LIMITATIONS.md explains limitations
- [ ] Examples in docs are accurate
- [ ] Code comments are helpful

---

## 🧹 Cleanup

- [ ] Run: `./scripts/cleanup-test.sh`
- [ ] Backup directories removed
- [ ] Test artifacts removed
- [ ] Original files restored
- [ ] Optionally delete test org: `./scripts/cleanup-test.sh --delete-org backup-test`

---

## 📊 Test Summary

### Overall Results

| Category | Tests Passed | Tests Failed | Total |
|----------|--------------|--------------|-------|
| Prerequisites | __ | __ | 9 |
| Core Functionality | __ | __ | 3 |
| Rollback Tests | __ | __ | 4 |
| Advanced Tests | __ | __ | 4 |
| Error Handling | __ | __ | 3 |
| Real-World Scenarios | __ | __ | 2 |
| Validation | __ | __ | 2 |
| **TOTAL** | **__** | **__** | **27** |

### Known Limitations Verified

- [ ] New Apex classes not removed by rollback (documented)
- [ ] New custom fields not removed by rollback (documented)
- [ ] Profile changes persist (documented)
- [ ] Picklist additions persist (documented)

### Issues Found

Document any unexpected issues:

1. _________________________________
2. _________________________________
3. _________________________________

### Performance Notes

- Average backup creation time: _______ seconds
- Average rollback time: _______ seconds
- Backup size (compressed): _______ MB
- Backup size (uncompressed): _______ MB

---

## ✅ Sign-Off

**Tester Name:** _________________________________

**Date:** _________________________________

**Environment:**
- SF CLI Version: _________________________________
- Plugin Version: _________________________________
- Node.js Version: _________________________________
- OS: _________________________________

**Overall Assessment:**
- [ ] Ready for production use
- [ ] Needs minor fixes
- [ ] Needs major fixes
- [ ] Not ready for production

**Additional Comments:**

_____________________________________
_____________________________________
_____________________________________
_____________________________________

---

## 🚀 Next Steps

After completing this checklist:

1. [ ] Review all failed tests
2. [ ] Document all issues in GitHub issues
3. [ ] Update documentation based on findings
4. [ ] Test in different org types (sandbox, dev edition)
5. [ ] Perform load testing with larger metadata sets
6. [ ] Validate CI/CD integration
7. [ ] Get peer review of test results

---

**For questions or issues, refer to:**
- [Main README](README.md)
- [Plugin README](../plugin-sf-backup/README.md)
- [Rollback Limitations](../ROLLBACK_LIMITATIONS.md)

