#!/bin/bash

################################################################################
# SF CLI Plugin Setup Script
# 
# This script sets up the sf-metadata-backup plugin by:
# 1. Copying utility scripts from scripts/backup/ to plugin-sf-backup/scripts/
# 2. Installing dependencies
# 3. Building the plugin
# 4. Linking the plugin to SF CLI
#
# Usage: ./setup-plugin.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  SF CLI Plugin Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if we're in the right directory
if [ ! -d "scripts/backup" ]; then
    echo -e "${RED}Error: scripts/backup directory not found${NC}"
    echo "Please run this script from the project root"
    exit 1
fi

if [ ! -d "plugin-sf-backup" ]; then
    echo -e "${RED}Error: plugin-sf-backup directory not found${NC}"
    echo "Please ensure the plugin directory exists"
    exit 1
fi

# Step 1: Create scripts directory in plugin
echo -e "${YELLOW}[1/5] Creating scripts directory in plugin...${NC}"
mkdir -p plugin-sf-backup/scripts
echo -e "${GREEN}✓ Scripts directory created${NC}"
echo ""

# Step 2: Copy utility scripts
echo -e "${YELLOW}[2/5] Copying utility scripts...${NC}"
cp scripts/backup/parse-buildfile.js plugin-sf-backup/scripts/
echo "  ✓ parse-buildfile.js"
cp scripts/backup/combine-manifests.js plugin-sf-backup/scripts/
echo "  ✓ combine-manifests.js"
cp scripts/backup/generate-recovery-manifest.js plugin-sf-backup/scripts/
echo "  ✓ generate-recovery-manifest.js"
cp scripts/backup/generate-destructive-changes.js plugin-sf-backup/scripts/
echo "  ✓ generate-destructive-changes.js"
cp scripts/backup/generate-rollback-buildfile.js plugin-sf-backup/scripts/
echo "  ✓ generate-rollback-buildfile.js"
echo -e "${GREEN}✓ All scripts copied${NC}"
echo ""

# Step 3: Install dependencies
echo -e "${YELLOW}[3/5] Installing dependencies...${NC}"
cd plugin-sf-backup
npm install
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 4: Build the plugin
echo -e "${YELLOW}[4/5] Building plugin...${NC}"
npm run build
echo -e "${GREEN}✓ Plugin built successfully${NC}"
echo ""

# Step 5: Link plugin to SF CLI
echo -e "${YELLOW}[5/5] Linking plugin to SF CLI...${NC}"
sf plugins link
echo -e "${GREEN}✓ Plugin linked${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Plugin is now available:${NC}"
echo "  sf backup --help"
echo "  sf backup create --help"
echo "  sf backup rollback --help"
echo "  sf backup list --help"
echo ""
echo -e "${YELLOW}Test the plugin:${NC}"
echo "  sf backup create --target-org myDevOrg"
echo "  sf backup list"
echo ""
echo -e "${YELLOW}To unlink:${NC}"
echo "  sf plugins unlink sf-metadata-backup"
echo ""

