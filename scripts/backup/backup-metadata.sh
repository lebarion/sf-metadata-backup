#!/bin/bash

################################################################################
# Salesforce Metadata Backup Script
# 
# This script backs up metadata from a target org before deployment.
# It supports two modes:
#   1. sf-orgdevmode-builds mode: reads manifest files from buildfile.json
#   2. Standard mode: uses a single package.xml file
#
# Usage: ./backup-metadata.sh <target-org> [manifest-source]
#
# Arguments:
#   target-org: Salesforce org alias or username
#   manifest-source: Path to buildfile.json OR package.xml
#                    (default: manifest/buildfile.json)
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
TARGET_ORG="$1"
MANIFEST_SOURCE="${2:-manifest/buildfile.json}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${PROJECT_ROOT}/backups/backup_${TIMESTAMP}"
ROLLBACK_DIR="${BACKUP_DIR}/rollback"
METADATA_DIR="${BACKUP_DIR}/metadata"
DEPLOYMENT_MODE=""

# Validate arguments
if [ -z "$TARGET_ORG" ]; then
    echo -e "${RED}Error: Target org is required${NC}"
    echo "Usage: $0 <target-org> [manifest-source]"
    echo "  manifest-source: path to buildfile.json OR package.xml"
    exit 1
fi

# Validate manifest source exists and determine mode
if [ ! -f "${PROJECT_ROOT}/${MANIFEST_SOURCE}" ]; then
    echo -e "${RED}Error: Manifest source not found at ${MANIFEST_SOURCE}${NC}"
    exit 1
fi

# Determine deployment mode based on file extension
if [[ "$MANIFEST_SOURCE" == *.json ]]; then
    DEPLOYMENT_MODE="orgdevmode"
elif [[ "$MANIFEST_SOURCE" == *.xml ]]; then
    DEPLOYMENT_MODE="standard"
else
    echo -e "${RED}Error: Manifest source must be a .json (buildfile) or .xml (package) file${NC}"
    exit 1
fi

# Create backup directories
mkdir -p "$BACKUP_DIR"
mkdir -p "$ROLLBACK_DIR"
mkdir -p "$METADATA_DIR"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Salesforce Metadata Backup System${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Target Org:${NC} $TARGET_ORG"
echo -e "${GREEN}Deployment Mode:${NC} $DEPLOYMENT_MODE"
echo -e "${GREEN}Manifest Source:${NC} $MANIFEST_SOURCE"
echo -e "${GREEN}Backup Directory:${NC} $BACKUP_DIR"
echo -e "${GREEN}Timestamp:${NC} $TIMESTAMP"
echo ""

# Log file
LOG_FILE="${BACKUP_DIR}/backup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Parse manifest source based on mode
if [ "$DEPLOYMENT_MODE" == "orgdevmode" ]; then
    echo -e "${YELLOW}[1/6] Parsing buildfile.json...${NC}"
    MANIFEST_FILES=$(node "${SCRIPT_DIR}/parse-buildfile.js" "${PROJECT_ROOT}/${MANIFEST_SOURCE}")
    
    if [ -z "$MANIFEST_FILES" ]; then
        echo -e "${RED}Error: No manifest files found in buildfile${NC}"
        exit 1
    fi
    
    echo "Found manifest files:"
    echo "$MANIFEST_FILES" | while read -r manifest; do
        echo "  - $manifest"
    done
    echo ""
    
    # Extract metadata types and members from manifests
    echo -e "${YELLOW}[2/6] Extracting metadata types from manifests...${NC}"
    COMBINED_MANIFEST="${BACKUP_DIR}/combined-manifest.xml"
    node "${SCRIPT_DIR}/combine-manifests.js" "$MANIFEST_FILES" "$COMBINED_MANIFEST" "${PROJECT_ROOT}"
else
    echo -e "${YELLOW}[1/6] Using package.xml manifest...${NC}"
    echo "Manifest file: $MANIFEST_SOURCE"
    echo ""
    
    # Copy the package.xml to combined manifest
    echo -e "${YELLOW}[2/6] Preparing manifest...${NC}"
    COMBINED_MANIFEST="${BACKUP_DIR}/combined-manifest.xml"
    cp "${PROJECT_ROOT}/${MANIFEST_SOURCE}" "$COMBINED_MANIFEST"
fi

if [ ! -f "$COMBINED_MANIFEST" ]; then
    echo -e "${RED}Error: Failed to create combined manifest${NC}"
    exit 1
fi

echo "Combined manifest created: $COMBINED_MANIFEST"
echo ""

# Retrieve metadata from target org
echo -e "${YELLOW}[3/6] Retrieving metadata from target org...${NC}"
echo "This may take several minutes depending on the amount of metadata..."
sf project retrieve start \
    --manifest "$COMBINED_MANIFEST" \
    --target-org "$TARGET_ORG" \
    --target-metadata-dir "$METADATA_DIR" \
    --wait 60 \
    --ignore-conflicts || {
        echo -e "${YELLOW}Warning: Some metadata may not exist in target org${NC}"
    }
echo ""

# Generate recovery manifest
echo -e "${YELLOW}[4/6] Generating recovery manifest...${NC}"
RECOVERY_MANIFEST="${ROLLBACK_DIR}/recovery-package.xml"
node "${SCRIPT_DIR}/generate-recovery-manifest.js" "$METADATA_DIR" "$RECOVERY_MANIFEST"

if [ ! -f "$RECOVERY_MANIFEST" ]; then
    echo -e "${RED}Error: Failed to generate recovery manifest${NC}"
    exit 1
fi

echo "Recovery manifest created: $RECOVERY_MANIFEST"
echo ""

# Generate destructive changes for new metadata
echo -e "${YELLOW}[5/6] Generating destructive changes for new metadata...${NC}"
DESTRUCTIVE_DIR="${ROLLBACK_DIR}/destructive"
mkdir -p "$DESTRUCTIVE_DIR"

node "${SCRIPT_DIR}/generate-destructive-changes.js" \
    "$COMBINED_MANIFEST" \
    "$RECOVERY_MANIFEST" \
    "${DESTRUCTIVE_DIR}/destructiveChanges.xml"

# Create empty package.xml for destructive changes
cat > "${DESTRUCTIVE_DIR}/package.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>61.0</version>
</Package>
EOF

echo "Destructive changes created: ${DESTRUCTIVE_DIR}/destructiveChanges.xml"
echo ""

# Generate rollback buildfile.json
echo -e "${YELLOW}[6/6] Generating rollback configuration...${NC}"
ROLLBACK_BUILDFILE="${ROLLBACK_DIR}/buildfile.json"
node "${SCRIPT_DIR}/generate-rollback-buildfile.js" \
    "$RECOVERY_MANIFEST" \
    "${DESTRUCTIVE_DIR}/destructiveChanges.xml" \
    "$ROLLBACK_BUILDFILE" \
    "$DEPLOYMENT_MODE"

echo "Rollback configuration created: $ROLLBACK_BUILDFILE"
echo ""

# Create deployment script based on mode
if [ "$DEPLOYMENT_MODE" == "orgdevmode" ]; then
    cat > "${ROLLBACK_DIR}/deploy-rollback.sh" << 'DEPLOY_EOF'
#!/bin/bash

################################################################################
# Rollback Deployment Script (sf-orgdevmode-builds mode)
# 
# This script deploys the rollback using sf-orgdevmode-builds plugin
#
# Usage: ./deploy-rollback.sh <target-org>
################################################################################

set -e

TARGET_ORG="$1"

if [ -z "$TARGET_ORG" ]; then
    echo "Error: Target org is required"
    echo "Usage: $0 <target-org>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Deploying Rollback (sf-orgdevmode-builds mode)"
echo "═══════════════════════════════════════════════════════════"
echo "Target Org: $TARGET_ORG"
echo ""

# Deploy using sf-orgdevmode-builds
sf builds deploy -b "${SCRIPT_DIR}/buildfile.json" -u "$TARGET_ORG"

echo ""
echo "Rollback deployment completed!"

DEPLOY_EOF
else
    cat > "${ROLLBACK_DIR}/deploy-rollback.sh" << 'DEPLOY_EOF'
#!/bin/bash

################################################################################
# Rollback Deployment Script (Standard mode)
# 
# This script deploys the rollback using standard Salesforce CLI commands
#
# Usage: ./deploy-rollback.sh <target-org>
################################################################################

set -e

TARGET_ORG="$1"

if [ -z "$TARGET_ORG" ]; then
    echo "Error: Target org is required"
    echo "Usage: $0 <target-org>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Deploying Rollback (Standard mode)"
echo "═══════════════════════════════════════════════════════════"
echo "Target Org: $TARGET_ORG"
echo ""

# Step 1: Deploy destructive changes to remove new metadata
if [ -f "${SCRIPT_DIR}/destructive/destructiveChanges.xml" ] && grep -q "<members>" "${SCRIPT_DIR}/destructive/destructiveChanges.xml"; then
    echo "Step 1/2: Removing new metadata..."
    sf project deploy start \
        --manifest "${SCRIPT_DIR}/destructive/package.xml" \
        --post-destructive-changes "${SCRIPT_DIR}/destructive/destructiveChanges.xml" \
        --target-org "$TARGET_ORG" \
        --ignore-warnings \
        --wait 60
    echo "New metadata removed successfully"
    echo ""
else
    echo "Step 1/2: No new metadata to remove (skipped)"
    echo ""
fi

# Step 2: Deploy recovery metadata to restore old state
if [ -f "${SCRIPT_DIR}/recovery-package.xml" ] && grep -q "<members>" "${SCRIPT_DIR}/recovery-package.xml"; then
    echo "Step 2/2: Restoring old metadata..."
    sf project deploy start \
        --manifest "${SCRIPT_DIR}/recovery-package.xml" \
        --target-org "$TARGET_ORG" \
        --ignore-warnings \
        --wait 60
    echo "Old metadata restored successfully"
    echo ""
else
    echo "Step 2/2: No metadata to restore (skipped)"
    echo ""
fi

echo ""
echo "Rollback deployment completed!"

DEPLOY_EOF
fi

chmod +x "${ROLLBACK_DIR}/deploy-rollback.sh"

# Compress backup
echo -e "${YELLOW}Compressing backup...${NC}"
BACKUP_ARCHIVE="${BACKUP_DIR}.tar.gz"
tar -czf "$BACKUP_ARCHIVE" -C "${PROJECT_ROOT}/backups" "backup_${TIMESTAMP}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Backup Completed Successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Backup Archive:${NC} $BACKUP_ARCHIVE"
echo -e "${GREEN}Backup Directory:${NC} $BACKUP_DIR"
echo -e "${GREEN}Recovery Manifest:${NC} $RECOVERY_MANIFEST"
echo -e "${GREEN}Destructive Changes:${NC} ${DESTRUCTIVE_DIR}/destructiveChanges.xml"
echo -e "${GREEN}Rollback Buildfile:${NC} $ROLLBACK_BUILDFILE"
echo ""
echo -e "${YELLOW}Deployment Mode:${NC} $DEPLOYMENT_MODE"
if [ "$DEPLOYMENT_MODE" == "orgdevmode" ]; then
    echo -e "${YELLOW}To deploy rollback:${NC}"
    echo "  cd ${ROLLBACK_DIR}"
    echo "  ./deploy-rollback.sh $TARGET_ORG"
else
    echo -e "${YELLOW}To deploy rollback:${NC}"
    echo "  cd ${ROLLBACK_DIR}"
    echo "  ./deploy-rollback.sh $TARGET_ORG"
    echo ""
    echo -e "${YELLOW}Or manually:${NC}"
    echo "  sf project deploy start --manifest recovery-package.xml -u $TARGET_ORG"
fi
echo ""

