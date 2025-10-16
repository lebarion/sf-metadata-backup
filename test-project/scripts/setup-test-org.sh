#!/bin/bash

###############################################################################
# Setup Test Org for SF Backup Plugin Testing
# 
# This script automates the setup of a test environment for the sf-metadata-backup
# plugin. It creates a scratch org, deploys sample metadata, and prepares for
# backup/rollback testing.
#
# Usage: ./scripts/setup-test-org.sh [org-alias]
# Default org alias: backup-test
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG_ALIAS="${1:-backup-test}"
SCRATCH_DEF="config/project-scratch-def.json"
DURATION=7

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  SF Backup Plugin - Test Org Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

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

# Check if DevHub is authorized
DEVHUB_CHECK=$(sf org list --json | grep -c '"isDevHub": *true' || echo "0")
if [ "$DEVHUB_CHECK" -eq "0" ]; then
    echo -e "${RED}✗ No DevHub authorized${NC}"
    echo "Please authorize a DevHub: sf org login web --set-default-dev-hub"
    echo ""
    echo "Or use an existing sandbox/developer org instead:"
    echo "  Run: $0 [existing-org-alias]"
    echo ""
    echo "Current orgs:"
    sf org list
    exit 1
else
    echo -e "${GREEN}✓ DevHub authorized${NC}"
    
    # Check if default DevHub is set
    DEFAULT_DEVHUB=$(sf config get target-dev-hub --json 2>/dev/null | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$DEFAULT_DEVHUB" ]; then
        echo -e "${YELLOW}⚠ No default DevHub set${NC}"
        # Try to set the first DevHub as default
        FIRST_DEVHUB=$(sf org list --json | grep -A5 '"isDevHub": *true' | grep '"username"' | head -1 | cut -d'"' -f4)
        if [ -n "$FIRST_DEVHUB" ]; then
            echo -e "${YELLOW}Setting $FIRST_DEVHUB as default DevHub...${NC}"
            sf config set target-dev-hub="$FIRST_DEVHUB"
            echo -e "${GREEN}✓ Default DevHub configured${NC}"
        fi
    else
        echo -e "${GREEN}✓ Default DevHub: $DEFAULT_DEVHUB${NC}"
    fi
fi
echo ""

# Check if org already exists
echo -e "${YELLOW}[2/6] Checking for existing test org...${NC}"
if sf org list --json | grep -q "\"alias\":\"$ORG_ALIAS\""; then
    echo -e "${YELLOW}Org '$ORG_ALIAS' already exists${NC}"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting existing org...${NC}"
        sf org delete scratch --target-org "$ORG_ALIAS" --no-prompt || true
    else
        echo -e "${YELLOW}Using existing org${NC}"
        SKIP_CREATE=true
    fi
fi

# Create scratch org
if [ "$SKIP_CREATE" != true ]; then
    echo -e "${YELLOW}[3/6] Creating scratch org...${NC}"
    
    # Try to create scratch org
    if ! sf org create scratch \
        --definition-file "$SCRATCH_DEF" \
        --alias "$ORG_ALIAS" \
        --set-default \
        --duration-days "$DURATION" 2>&1 | tee /tmp/scratch_create.log; then
        
        # Check if it's a limit error
        if grep -q "LIMIT_EXCEEDED\|active scratch org limit" /tmp/scratch_create.log; then
            echo ""
            echo -e "${RED}✗ Scratch org limit exceeded${NC}"
            echo ""
            echo -e "${YELLOW}Your DevHub has reached the active scratch org limit.${NC}"
            echo ""
            echo -e "${BLUE}Options:${NC}"
            echo "  1. Delete old scratch orgs: ./scripts/cleanup-scratch-orgs.sh"
            echo "  2. Use existing org: ./scripts/setup-existing-org.sh [org-alias]"
            echo ""
            echo "Current scratch orgs:"
            sf org list | grep -A100 "Scratch" || echo "None"
            rm -f /tmp/scratch_create.log
            exit 1
        else
            # Other error
            rm -f /tmp/scratch_create.log
            exit 1
        fi
    fi
    
    rm -f /tmp/scratch_create.log
    echo -e "${GREEN}✓ Scratch org created: $ORG_ALIAS${NC}"
else
    echo -e "${YELLOW}[3/6] Skipping org creation${NC}"
fi
echo ""

# Deploy metadata
echo -e "${YELLOW}[4/6] Deploying sample metadata...${NC}"
echo "This may take a minute..."
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org "$ORG_ALIAS" \
    --wait 10

echo -e "${GREEN}✓ Metadata deployed successfully${NC}"
echo ""

# Verify deployment
echo -e "${YELLOW}[5/6] Verifying deployment...${NC}"

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
    echo -e "${YELLOW}⚠ Unable to verify Apex classes (may still be deployed)${NC}"
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
    echo -e "${YELLOW}⚠ Unable to verify custom objects (may still be deployed)${NC}"
    rm -rf "$VERIFY_DIR"
fi

echo -e "${GREEN}✓ Deployment verification complete${NC}"
echo ""

# Display org info
echo -e "${YELLOW}[6/6] Test org ready!${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Org Details:${NC}"
sf org display --target-org "$ORG_ALIAS"
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
echo -e "   ${YELLOW}sf project deploy start --manifest manifest/package.xml${NC}"
echo -e "   ${YELLOW}sf backup rollback --target-org $ORG_ALIAS --backup-dir backups/backup_[TIMESTAMP]${NC}"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "- Quick Start: ${YELLOW}cat QUICK_START.md${NC}"
echo -e "- Full Guide:  ${YELLOW}cat README.md${NC}"
echo -e "- Test Cases:  ${YELLOW}cat test-scenarios/TEST_INSTRUCTIONS.md${NC}"
echo ""
echo -e "${GREEN}Happy testing! 🚀${NC}"

