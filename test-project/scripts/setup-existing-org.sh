#!/bin/bash

###############################################################################
# Setup Test with EXISTING Org (Sandbox/Developer Edition)
# 
# Use this script if you DON'T have a DevHub or prefer to use an existing org
# instead of creating a scratch org.
#
# Usage: ./scripts/setup-existing-org.sh [org-alias]
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG_ALIAS="${1:-}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  SF Backup Plugin - Existing Org Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

if ! command -v sf &> /dev/null; then
    echo -e "${RED}✗ Salesforce CLI not found${NC}"
    echo "Please install: npm install -g @salesforce/cli"
    exit 1
fi
echo -e "${GREEN}✓ Salesforce CLI installed${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js installed${NC}"
echo ""

# Select or authenticate org
echo -e "${YELLOW}[2/5] Setting up target org...${NC}"

if [ -z "$ORG_ALIAS" ]; then
    echo -e "${BLUE}Available orgs:${NC}"
    sf org list
    echo ""
    read -p "Enter org alias to use (or press Enter to authenticate new org): " ORG_ALIAS
    
    if [ -z "$ORG_ALIAS" ]; then
        echo ""
        echo -e "${YELLOW}Authenticating new org...${NC}"
        read -p "Enter alias for new org: " ORG_ALIAS
        
        if [ -z "$ORG_ALIAS" ]; then
            ORG_ALIAS="backup-test"
            echo "Using default alias: backup-test"
        fi
        
        echo ""
        echo -e "${YELLOW}Opening browser for authentication...${NC}"
        sf org login web --alias "$ORG_ALIAS" --set-default
    fi
fi

# Verify org exists
if ! sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
    echo -e "${RED}✗ Org '$ORG_ALIAS' not found or not authenticated${NC}"
    echo ""
    echo "Available orgs:"
    sf org list
    exit 1
fi

echo -e "${GREEN}✓ Using org: $ORG_ALIAS${NC}"
echo ""

# Show org info
echo -e "${YELLOW}[3/5] Verifying org access...${NC}"
sf org display --target-org "$ORG_ALIAS"
echo ""

# Confirm deployment
echo -e "${YELLOW}[4/5] Ready to deploy test metadata...${NC}"
echo ""
echo -e "${BLUE}This will deploy:${NC}"
echo "  • 3 Apex classes (AccountService, ContactService, AccountServiceTest)"
echo "  • 1 Custom object (Project__c) with 5 fields"
echo "  • 1 Lightning Web Component (accountList)"
echo ""
read -p "Continue with deployment? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Deploy metadata
echo ""
echo -e "${YELLOW}Deploying metadata...${NC}"
echo "This may take a minute..."
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org "$ORG_ALIAS" \
    --wait 10

echo -e "${GREEN}✓ Metadata deployed successfully${NC}"
echo ""

# Verify deployment
echo -e "${YELLOW}[5/5] Verifying deployment...${NC}"

# Simple verification: try to retrieve one of the deployed classes
VERIFY_DIR=".verify-deploy"
mkdir -p "$VERIFY_DIR"

echo "Checking deployed metadata..."
if sf project retrieve start \
    --metadata "ApexClass:AccountService" \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir "$VERIFY_DIR" \
    --wait 5 &> /dev/null; then
    echo -e "${GREEN}✓ Apex classes deployed${NC}"
    rm -rf "$VERIFY_DIR"
else
    echo -e "${YELLOW}⚠ Unable to verify Apex classes (may require additional permissions)${NC}"
    rm -rf "$VERIFY_DIR"
fi

# Verify custom object
if sf project retrieve start \
    --metadata "CustomObject:Project__c" \
    --target-org "$ORG_ALIAS" \
    --target-metadata-dir "$VERIFY_DIR" \
    --wait 5 &> /dev/null; then
    echo -e "${GREEN}✓ Custom objects deployed${NC}"
    rm -rf "$VERIFY_DIR"
else
    echo -e "${YELLOW}⚠ Unable to verify custom objects (may require additional permissions)${NC}"
    rm -rf "$VERIFY_DIR"
fi

echo -e "${GREEN}✓ Deployment verification complete${NC}"
echo ""

# Display success message
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Org Details:${NC}"
sf org display --target-org "$ORG_ALIAS" --verbose
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo -e "1. Open the org:"
echo -e "   ${YELLOW}sf org open --target-org $ORG_ALIAS${NC}"
echo ""
echo -e "2. Create your first backup:"
echo -e "   ${YELLOW}sf backup create --target-org $ORG_ALIAS --manifest manifest/package.xml${NC}"
echo ""
echo -e "3. List backups:"
echo -e "   ${YELLOW}sf backup list${NC}"
echo ""
echo -e "4. Make changes and test rollback:"
echo -e "   ${YELLOW}# ... make changes to files ...${NC}"
echo -e "   ${YELLOW}sf project deploy start --manifest manifest/package.xml --target-org $ORG_ALIAS${NC}"
echo -e "   ${YELLOW}sf backup rollback --target-org $ORG_ALIAS --backup-dir backups/backup_[TIMESTAMP]${NC}"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "- Quick Start: ${YELLOW}cat QUICK_START.md${NC}"
echo -e "- Full Guide:  ${YELLOW}cat README.md${NC}"
echo -e "- Test Cases:  ${YELLOW}cat test-scenarios/TEST_INSTRUCTIONS.md${NC}"
echo ""
echo -e "${GREEN}Happy testing! 🚀${NC}"

