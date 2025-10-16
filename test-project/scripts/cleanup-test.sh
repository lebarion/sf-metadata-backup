#!/bin/bash

###############################################################################
# Cleanup Test Environment
# 
# This script cleans up test artifacts and optionally deletes the test org
#
# Usage: 
#   ./scripts/cleanup-test.sh           # Clean artifacts only
#   ./scripts/cleanup-test.sh --delete-org [org-alias]  # Clean and delete org
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DELETE_ORG=false
ORG_ALIAS="backup-test"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --delete-org)
            DELETE_ORG=true
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                ORG_ALIAS="$2"
                shift
            fi
            shift
            ;;
        *)
            ORG_ALIAS="$1"
            shift
            ;;
    esac
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Test Environment Cleanup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Clean backup directories
echo -e "${YELLOW}Cleaning backup directories...${NC}"
if [ -d "backups" ]; then
    BACKUP_COUNT=$(find backups -maxdepth 1 -type d -name "backup_*" | wc -l)
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo "Found $BACKUP_COUNT backup(s)"
        rm -rf backups/backup_*
        echo -e "${GREEN}✓ Backups removed${NC}"
    else
        echo -e "${YELLOW}No backups found${NC}"
    fi
else
    echo -e "${YELLOW}No backup directory found${NC}"
fi

# Clean custom backup directories
if [ -d "custom-backups" ]; then
    echo "Removing custom-backups..."
    rm -rf custom-backups
    echo -e "${GREEN}✓ Custom backups removed${NC}"
fi

# Clean test artifacts
echo -e "${YELLOW}Cleaning test artifacts...${NC}"
rm -rf .test-retrieve
rm -rf .sf/orgs
rm -f force-app/main/default/classes/*.backup
echo -e "${GREEN}✓ Test artifacts removed${NC}"

# Restore any modified files from git
echo -e "${YELLOW}Restoring original files from git...${NC}"
git checkout force-app/ 2>/dev/null || echo -e "${YELLOW}No git changes to restore${NC}"
echo -e "${GREEN}✓ Files restored${NC}"

echo ""

# Delete org if requested
if [ "$DELETE_ORG" = true ]; then
    echo -e "${YELLOW}Checking for org: $ORG_ALIAS...${NC}"
    if sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
        echo -e "${RED}Deleting org: $ORG_ALIAS${NC}"
        read -p "Are you sure? This cannot be undone (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sf org delete scratch --target-org "$ORG_ALIAS" --no-prompt
            echo -e "${GREEN}✓ Org deleted${NC}"
        else
            echo -e "${YELLOW}Org deletion cancelled${NC}"
        fi
    else
        echo -e "${YELLOW}Org not found${NC}"
    fi
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Cleanup Complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$DELETE_ORG" = false ]; then
    echo -e "${YELLOW}Note: Test org '$ORG_ALIAS' was not deleted${NC}"
    echo -e "To delete the org, run:"
    echo -e "  ${BLUE}./scripts/cleanup-test.sh --delete-org $ORG_ALIAS${NC}"
    echo ""
fi

echo -e "${GREEN}✓ Ready for new tests!${NC}"

