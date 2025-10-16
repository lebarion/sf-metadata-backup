# SF Backup Plugin Test Project - Complete Index

Quick reference guide to all test project resources.

## 🎯 Start Here

**New to this project?**
1. Read [QUICK_START.md](QUICK_START.md) (5 minutes)
2. Run `./scripts/setup-test-org.sh` (2 minutes)
3. Follow [QUICK_START.md](QUICK_START.md) examples (10 minutes)

**Ready for comprehensive testing?**
1. Read [README.md](README.md) for full details
2. Follow [test-scenarios/TEST_INSTRUCTIONS.md](test-scenarios/TEST_INSTRUCTIONS.md)
3. Track progress with [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)

---

## 📚 Documentation

### Getting Started
- **[QUICK_START.md](QUICK_START.md)** - 5-minute quick start guide
  - Super quick start commands
  - Prerequisites checklist
  - Simple test scenarios
  - Troubleshooting quick fixes

### Comprehensive Guides
- **[README.md](README.md)** - Complete test project documentation
  - Project structure overview
  - Detailed test scenarios (6 scenarios)
  - Validation checklist
  - Advanced testing guides
  - Best practices
  - Troubleshooting

### Test Instructions
- **[test-scenarios/TEST_INSTRUCTIONS.md](test-scenarios/TEST_INSTRUCTIONS.md)** - Detailed test case instructions
  - Test Case 1: Modifying Existing Apex Class
  - Test Case 2: Modifying Lightning Web Component
  - Test Case 3: Adding New Apex Class (with limitations)
  - Test Case 4: Adding New Custom Field (with limitations)
  - Test Case 5: Complete Multi-Phase Scenario
  - Results tracking template
  - Testing best practices

### Testing Checklist
- **[TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)** - Complete testing checklist
  - 27 distinct test cases
  - Prerequisites verification
  - Core functionality tests
  - Rollback tests
  - Advanced testing
  - Error handling tests
  - Real-world scenarios
  - Sign-off template

---

## 🛠️ Automation Scripts

All scripts are in the `scripts/` directory and are executable.

### Setup & Initialization
```bash
./scripts/setup-test-org.sh [org-alias]
```
- Creates scratch org
- Deploys initial metadata
- Verifies deployment
- Displays next steps

**Default org alias:** `backup-test`

### Full Test Cycle
```bash
./scripts/run-full-test.sh [org-alias] [mode]
```
- Runs complete end-to-end test
- Modes: `standard` or `orgdevmode`
- Tests backup, deploy, rollback cycle
- Verifies success automatically

**Example:**
```bash
./scripts/run-full-test.sh backup-test standard
./scripts/run-full-test.sh backup-test orgdevmode
```

### Cleanup
```bash
./scripts/cleanup-test.sh [--delete-org] [org-alias]
```
- Removes backup directories
- Cleans test artifacts
- Restores original files
- Optionally deletes test org

**Examples:**
```bash
./scripts/cleanup-test.sh                        # Clean artifacts only
./scripts/cleanup-test.sh --delete-org          # Clean and delete default org
./scripts/cleanup-test.sh --delete-org my-test  # Clean and delete specific org
```

---

## 📁 Project Structure

```
test-project/
│
├── 📖 Documentation
│   ├── INDEX.md                    # This file - complete navigation
│   ├── QUICK_START.md              # 5-minute getting started
│   ├── README.md                   # Comprehensive guide
│   └── TESTING_CHECKLIST.md        # Complete test tracking
│
├── ⚙️ Configuration
│   ├── sfdx-project.json           # Salesforce DX project config
│   ├── .forceignore                # Files to ignore
│   ├── .gitignore                  # Git ignore patterns
│   └── config/
│       └── project-scratch-def.json # Scratch org definition
│
├── 📦 Source Code (force-app/main/default/)
│   ├── classes/                    # Apex classes
│   │   ├── AccountService.cls          # Account service (v1)
│   │   ├── AccountServiceTest.cls      # Test class
│   │   └── ContactService.cls          # Contact service
│   │
│   ├── objects/                    # Custom objects
│   │   └── Project__c/
│   │       ├── Project__c.object-meta.xml
│   │       └── fields/
│   │           ├── Status__c.field-meta.xml
│   │           ├── Start_Date__c.field-meta.xml
│   │           ├── End_Date__c.field-meta.xml
│   │           ├── Budget__c.field-meta.xml
│   │           └── Description__c.field-meta.xml
│   │
│   └── lwc/                        # Lightning Web Components
│       └── accountList/
│           ├── accountList.js
│           ├── accountList.html
│           └── accountList.js-meta.xml
│
├── 📋 Manifests (manifest/)
│   ├── package.xml                 # Standard single manifest
│   ├── buildfile.json             # OrgDevMode buildfile
│   ├── phase1-classes.xml         # Phase 1: Apex classes
│   ├── phase2-objects.xml         # Phase 2: Custom objects
│   └── phase3-components.xml      # Phase 3: LWC and more
│
├── 🧪 Test Scenarios (test-scenarios/)
│   ├── TEST_INSTRUCTIONS.md       # Detailed test instructions
│   │
│   ├── modified-files/            # Modified versions for testing
│   │   ├── AccountService_v2.cls      # Enhanced AccountService
│   │   ├── accountList_v2.js          # Enhanced LWC JS
│   │   └── accountList_v2.html        # Enhanced LWC HTML
│   │
│   └── new-files/                 # New metadata for testing
│       ├── OpportunityService.cls      # New Apex class
│       ├── OpportunityService.cls-meta.xml
│       └── Project__c.Priority__c.field-meta.xml  # New field
│
└── 🔧 Scripts (scripts/)
    ├── setup-test-org.sh          # Automated setup
    ├── run-full-test.sh          # Full test cycle
    └── cleanup-test.sh           # Cleanup artifacts
```

---

## 🎓 Metadata Inventory

### Apex Classes (3)
1. **AccountService** - Service for Account operations
   - `getAllAccounts()` - Get all accounts
   - `getAccountById()` - Get account by ID
   - `createAccount()` - Create new account
   - `updateAccountIndustry()` - Update account industry

2. **ContactService** - Service for Contact operations
   - `getAllContacts()` - Get all contacts
   - `getContactsByAccount()` - Get contacts by account
   - `createContact()` - Create new contact

3. **AccountServiceTest** - Test class for AccountService
   - Full test coverage for AccountService

### Custom Objects (1)
1. **Project__c** - Project management object
   - **Fields (5):**
     - Status__c (Picklist: Planning, In Progress, Completed, On Hold)
     - Start_Date__c (Date)
     - End_Date__c (Date)
     - Budget__c (Currency)
     - Description__c (Long Text Area)

### Lightning Web Components (1)
1. **accountList** - Display accounts in data table
   - Shows Account Name, Industry, Phone
   - Wire service to AccountService.getAllAccounts()
   - Error handling

### Modified Versions (Test Scenarios)
1. **AccountService_v2.cls** - Enhanced version with:
   - `getAccountsByIndustry()` - NEW METHOD
   - `deleteAccount()` - NEW METHOD
   - Enhanced queries with more fields
   - Duplicate checking

2. **accountList_v2** - Enhanced version with:
   - 5 columns instead of 3
   - Row selection capability
   - Enhanced error display

### New Files (Test Scenarios)
1. **OpportunityService.cls** - Brand new Apex class
2. **Priority__c** - New custom field for Project__c

---

## 🚀 Common Commands Reference

### Setup
```bash
# Quick setup (recommended)
./scripts/setup-test-org.sh

# Manual setup
sf org create scratch --definition-file config/project-scratch-def.json --alias backup-test
sf project deploy start --manifest manifest/package.xml --target-org backup-test
```

### Backup Operations
```bash
# Create backup (standard)
sf backup create --target-org backup-test --manifest manifest/package.xml

# Create backup (orgdevmode)
sf backup create --target-org backup-test --manifest manifest/buildfile.json

# List backups
sf backup list

# List backups in custom directory
sf backup list --backup-dir custom-backups

# Create uncompressed backup
sf backup create --target-org backup-test --manifest manifest/package.xml --no-compress
```

### Rollback Operations
```bash
# Rollback with confirmation
sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP]

# Rollback without confirmation
sf backup rollback --target-org backup-test --backup-dir backups/backup_[TIMESTAMP] --no-confirm

# Get latest backup directory
BACKUP=$(ls -td backups/backup_* | head -1)
sf backup rollback --target-org backup-test --backup-dir $BACKUP
```

### Deployment
```bash
# Standard deployment
sf project deploy start --manifest manifest/package.xml --target-org backup-test

# OrgDevMode deployment
sf builds deploy -b manifest/buildfile.json -u backup-test

# Phase-specific deployment
sf project deploy start --manifest manifest/phase1-classes.xml
sf project deploy start --manifest manifest/phase2-objects.xml
sf project deploy start --manifest manifest/phase3-components.xml
```

### Testing & Validation
```bash
# Automated full test
./scripts/run-full-test.sh backup-test standard

# Open org
sf org open --target-org backup-test

# Check org details
sf org display --target-org backup-test

# List Apex classes
sf apex list --target-org backup-test

# List custom objects
sf sobject list --sobject custom --target-org backup-test
```

### Cleanup
```bash
# Clean artifacts only
./scripts/cleanup-test.sh

# Clean and delete org
./scripts/cleanup-test.sh --delete-org backup-test

# Manual cleanup
rm -rf backups/
git checkout force-app/
```

---

## 📊 Test Scenarios at a Glance

| Scenario | Type | Expected Result | Difficulty |
|----------|------|----------------|------------|
| Basic Backup | Core | Backup created successfully | ⭐ Easy |
| List Backups | Core | Shows all backups | ⭐ Easy |
| Modify Apex Class | Rollback | Changes reverted | ⭐ Easy |
| Modify LWC | Rollback | Changes reverted | ⭐⭐ Medium |
| Add New Apex | Limitation | Class remains (expected) | ⭐⭐ Medium |
| Add New Field | Limitation | Field remains (expected) | ⭐⭐ Medium |
| Multi-Phase Orgdevmode | Advanced | All phases work | ⭐⭐⭐ Hard |
| CI/CD Simulation | Advanced | Auto rollback works | ⭐⭐⭐ Hard |

---

## 🔗 Related Documentation

### Plugin Documentation
- [Plugin README](../plugin-sf-backup/README.md)
- [Plugin Quick Start](../plugin-sf-backup/QUICK_START.md)
- [Plugin Installation](../plugin-sf-backup/INSTALLATION.md)

### Important Concepts
- [Rollback Limitations](../ROLLBACK_LIMITATIONS.md)
- [Backup System Overview](../BACKUP_SYSTEM.md)
- [Enhancement Summary](../ENHANCEMENT_SUMMARY.md)

### Salesforce Resources
- [Salesforce CLI Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/)
- [Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/)
- [OrgDevMode Builds Plugin](https://github.com/tiagonnascimento/sf-orgdevmode-builds)

---

## 🎯 Testing Paths

### Path 1: Quick Validation (15 minutes)
1. Run `./scripts/setup-test-org.sh`
2. Run `./scripts/run-full-test.sh backup-test standard`
3. Verify all steps pass
4. Run `./scripts/cleanup-test.sh`

**Goal:** Confirm plugin works end-to-end

### Path 2: Standard Testing (1 hour)
1. Read [QUICK_START.md](QUICK_START.md)
2. Follow Scenarios A, B, and C
3. Try both standard and orgdevmode
4. Document results

**Goal:** Understand core functionality and limitations

### Path 3: Comprehensive Testing (2-3 hours)
1. Read [README.md](README.md)
2. Work through all 6 scenarios in README
3. Follow [test-scenarios/TEST_INSTRUCTIONS.md](test-scenarios/TEST_INSTRUCTIONS.md)
4. Complete [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)
5. Document all findings

**Goal:** Thorough validation of all features

### Path 4: Real-World Simulation (ongoing)
1. Use in actual development workflow
2. Test with production-like metadata
3. Integrate with CI/CD pipeline
4. Document edge cases found

**Goal:** Production readiness validation

---

## 💡 Pro Tips

### Efficiency Tips
- Use shell variables for backup dirs: `BACKUP=$(ls -td backups/backup_* | head -1)`
- Alias common commands in your `.bashrc` or `.zshrc`
- Keep multiple test orgs for parallel testing
- Use `--no-confirm` flag in automated scripts

### Debugging Tips
- Always check `backup.log` for detailed information
- Review `rollback/buildfile.json` to understand rollback plan
- Inspect `destructiveChanges.xml` to see what will be deleted
- Use `sf doctor` to diagnose Salesforce CLI issues

### Safety Tips
- **Never test in production** - always use scratch org or sandbox
- Keep backups of important metadata outside the plugin
- Review rollback packages manually before production rollback
- Test rollback in sandbox before production
- Understand limitations before relying on plugin

### Performance Tips
- Use `--no-compress` for faster backups during development
- Test with realistic metadata volumes
- Consider backup frequency vs storage constraints
- Archive old backups to external storage

---

## 🐛 Known Issues & Limitations

### Cannot Fully Rollback:
1. ❌ Deleting custom fields with data
2. ❌ Creating new custom fields
3. ❌ Profile permission changes
4. ❌ Sharing rules modifications
5. ❌ Picklist value additions in use
6. ❌ Translation changes
7. ❌ Complex dependencies

### Best Practices:
1. ✅ Test thoroughly in sandbox first
2. ✅ Roll forward rather than rollback when possible
3. ✅ Review generated rollback packages
4. ✅ Keep manual recovery procedures ready
5. ✅ Maintain multiple backup strategies

**Full details:** [../ROLLBACK_LIMITATIONS.md](../ROLLBACK_LIMITATIONS.md)

---

## ❓ FAQ

**Q: How long does it take to set up?**
A: 5 minutes with automated script, 10-15 minutes manually.

**Q: Do I need a DevHub?**
A: Yes, for scratch orgs. Alternatively, use a sandbox or developer edition.

**Q: Can I test without sf-orgdevmode-builds?**
A: Yes, use standard mode with package.xml.

**Q: What if a test fails?**
A: Check `backup.log`, verify prerequisites, review documentation.

**Q: Can I use this with my real metadata?**
A: Yes, but test thoroughly in non-production environment first.

**Q: How do I reset everything?**
A: Run `./scripts/cleanup-test.sh --delete-org` and start fresh.

---

## 📞 Getting Help

**Issue with setup?**
→ Check [QUICK_START.md](QUICK_START.md) troubleshooting section

**Test not working as expected?**
→ Review [test-scenarios/TEST_INSTRUCTIONS.md](test-scenarios/TEST_INSTRUCTIONS.md)

**Need to understand limitations?**
→ Read [../ROLLBACK_LIMITATIONS.md](../ROLLBACK_LIMITATIONS.md)

**Plugin issues?**
→ Check [../plugin-sf-backup/README.md](../plugin-sf-backup/README.md)

**General questions?**
→ Review this INDEX.md and linked documentation

---

## 🎉 You're Ready!

Pick your testing path above and get started. Good luck! 🚀

**Quick Start:**
```bash
cd test-project
./scripts/setup-test-org.sh
# Follow the displayed next steps
```

---

*Last Updated: October 2025*
*Plugin Version: 0.0.3*
*Test Project Version: 1.0*

