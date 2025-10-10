#!/bin/bash

################################################################################
# Setup Script for Backup System
# 
# This script installs all required dependencies for the backup system
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Salesforce Backup System Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check Node.js
echo -e "${YELLOW}Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js first."
    exit 1
fi
echo "Node.js version: $(node --version)"
echo ""

# Check npm
echo -e "${YELLOW}Checking npm...${NC}"
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed. Please install npm first."
    exit 1
fi
echo "npm version: $(npm --version)"
echo ""

# Check Salesforce CLI
echo -e "${YELLOW}Checking Salesforce CLI...${NC}"
if ! command -v sf &> /dev/null; then
    echo "Error: Salesforce CLI (sf) is not installed."
    echo "Please install from: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi
echo "Salesforce CLI version: $(sf --version)"
echo ""

# Install npm dependencies
echo -e "${YELLOW}Installing npm dependencies...${NC}"
npm install
echo ""

# Check sf-orgdevmode-builds plugin
echo -e "${YELLOW}Checking sf-orgdevmode-builds plugin...${NC}"
if sf plugins | grep -q "sf-orgdevmode-builds"; then
    echo "sf-orgdevmode-builds plugin is already installed"
else
    echo "Installing sf-orgdevmode-builds plugin..."
    sf plugins install sf-orgdevmode-builds
fi
echo ""

# Create backups directory
echo -e "${YELLOW}Creating backups directory...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
mkdir -p "${PROJECT_ROOT}/backups"
echo "Backups directory: ${PROJECT_ROOT}/backups"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}You can now use the backup system:${NC}"
echo "  ./backup-metadata.sh <target-org> [buildfile-path]"
echo ""
echo -e "${YELLOW}For more information, see:${NC}"
echo "  cat README.md"
echo ""

