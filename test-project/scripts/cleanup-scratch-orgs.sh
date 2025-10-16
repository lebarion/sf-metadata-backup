#!/bin/bash

###############################################################################
# Cleanup Scratch Orgs
# 
# This script helps you manage and clean up scratch orgs to avoid hitting
# the DevHub limit (typically 3 active scratch orgs for Developer Edition)
#
# Usage: ./scripts/cleanup-scratch-orgs.sh [--all]
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DELETE_ALL=false

# Parse arguments
if [ "$1" = "--all" ]; then
    DELETE_ALL=true
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Scratch Org Cleanup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check for DevHub
if ! sf org list --json | grep -q '"isDevHub": *true'; then
    echo -e "${RED}✗ No DevHub found${NC}"
    echo "This script is for managing scratch orgs. You don't seem to have a DevHub."
    exit 1
fi

# List all scratch orgs
echo -e "${YELLOW}Current Scratch Orgs:${NC}"
echo ""
sf org list | grep -A100 "Scratch" || echo "No scratch orgs found"
echo ""

# Get scratch org count
SCRATCH_COUNT=$(sf org list --json | grep -c '"isScratch": *true' || echo "0")

if [ "$SCRATCH_COUNT" -eq "0" ]; then
    echo -e "${GREEN}✓ No scratch orgs to clean up${NC}"
    exit 0
fi

echo -e "${BLUE}Found $SCRATCH_COUNT active scratch org(s)${NC}"
echo ""

# Get scratch orgs
SCRATCH_ORGS=$(sf org list --json | grep -B10 '"isScratch": *true' | grep '"username"' | cut -d'"' -f4)

if [ "$DELETE_ALL" = true ]; then
    echo -e "${RED}⚠ WARNING: This will delete ALL scratch orgs!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}Deleting all scratch orgs...${NC}"
    
    for org in $SCRATCH_ORGS; do
        echo -e "${YELLOW}Deleting: $org${NC}"
        sf org delete scratch --target-org "$org" --no-prompt
    done
    
    echo ""
    echo -e "${GREEN}✓ All scratch orgs deleted${NC}"
    
else
    echo -e "${YELLOW}Select scratch orgs to delete:${NC}"
    echo ""
    
    # Create array of orgs
    ORG_ARRAY=()
    INDEX=1
    
    for org in $SCRATCH_ORGS; do
        # Get alias if exists
        ALIAS=$(sf org list --json | grep -B5 "\"username\": *\"$org\"" | grep '"alias"' | cut -d'"' -f4 || echo "")
        
        if [ -n "$ALIAS" ]; then
            echo "  $INDEX) $ALIAS ($org)"
        else
            echo "  $INDEX) $org"
        fi
        
        ORG_ARRAY+=("$org")
        INDEX=$((INDEX + 1))
    done
    
    echo ""
    echo "  A) Delete all"
    echo "  Q) Quit"
    echo ""
    read -p "Enter choice (number, A, or Q): " CHOICE
    
    case $CHOICE in
        [Qq])
            echo -e "${YELLOW}Cancelled${NC}"
            exit 0
            ;;
        [Aa])
            echo ""
            echo -e "${YELLOW}Deleting all scratch orgs...${NC}"
            for org in $SCRATCH_ORGS; do
                echo -e "${YELLOW}Deleting: $org${NC}"
                sf org delete scratch --target-org "$org" --no-prompt
            done
            echo ""
            echo -e "${GREEN}✓ All scratch orgs deleted${NC}"
            ;;
        [0-9]*)
            if [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#ORG_ARRAY[@]}" ]; then
                SELECTED_ORG="${ORG_ARRAY[$((CHOICE - 1))]}"
                echo ""
                echo -e "${YELLOW}Deleting: $SELECTED_ORG${NC}"
                sf org delete scratch --target-org "$SELECTED_ORG" --no-prompt
                echo ""
                echo -e "${GREEN}✓ Scratch org deleted${NC}"
            else
                echo -e "${RED}Invalid choice${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
fi

echo ""
echo -e "${BLUE}Remaining scratch orgs:${NC}"
sf org list | grep -A100 "Scratch" || echo -e "${GREEN}None${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Cleanup Complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

