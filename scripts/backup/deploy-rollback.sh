#!/bin/bash

################################################################################
# Standalone Rollback Deployment Script
# 
# This script deploys a rollback using the sf-orgdevmode-builds plugin
# It can be used independently of the backup process if you have a rollback
# directory structure already created.
#
# Usage: ./deploy-rollback.sh <rollback-directory> <target-org>
#
# Arguments:
#   rollback-directory: Path to the rollback directory containing buildfile.json
#   target-org: Salesforce org alias or username
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROLLBACK_DIR="$1"
TARGET_ORG="$2"

# Validate arguments
if [ -z "$ROLLBACK_DIR" ]; then
    echo -e "${RED}Error: Rollback directory is required${NC}"
    echo "Usage: $0 <rollback-directory> <target-org>"
    exit 1
fi

if [ -z "$TARGET_ORG" ]; then
    echo -e "${RED}Error: Target org is required${NC}"
    echo "Usage: $0 <rollback-directory> <target-org>"
    exit 1
fi

# Validate rollback directory
if [ ! -d "$ROLLBACK_DIR" ]; then
    echo -e "${RED}Error: Rollback directory not found: $ROLLBACK_DIR${NC}"
    exit 1
fi

# Validate buildfile exists
BUILDFILE="${ROLLBACK_DIR}/buildfile.json"
if [ ! -f "$BUILDFILE" ]; then
    echo -e "${RED}Error: buildfile.json not found in rollback directory${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Salesforce Rollback Deployment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Rollback Directory:${NC} $ROLLBACK_DIR"
echo -e "${GREEN}Target Org:${NC} $TARGET_ORG"
echo -e "${GREEN}Buildfile:${NC} $BUILDFILE"
echo ""

# Confirm deployment
read -p "$(echo -e ${YELLOW}Are you sure you want to proceed with the rollback? [y/N]: ${NC})" -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 0
fi

# Change to rollback directory for relative paths
cd "$ROLLBACK_DIR"

echo -e "${YELLOW}Starting rollback deployment...${NC}"
echo ""

# Check if sf-orgdevmode-builds plugin is installed
if ! sf plugins | grep -q "sf-orgdevmode-builds"; then
    echo -e "${YELLOW}Warning: sf-orgdevmode-builds plugin not found${NC}"
    echo "Installing sf-orgdevmode-builds plugin..."
    sf plugins install sf-orgdevmode-builds
    echo ""
fi

# Deploy using sf-orgdevmode-builds
echo -e "${YELLOW}Executing rollback builds...${NC}"
sf builds deploy -b "buildfile.json" -u "$TARGET_ORG"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Rollback Deployment Completed!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "1. Verify the rollback was successful in the target org"
echo "2. Check for any errors or warnings in the deployment output"
echo "3. Test critical functionality to ensure the org is working correctly"
echo ""

