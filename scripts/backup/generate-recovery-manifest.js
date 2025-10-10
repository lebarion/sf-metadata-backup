#!/usr/bin/env node

/**
 * Generate recovery manifest from retrieved metadata
 * 
 * Usage: node generate-recovery-manifest.js <metadata-dir> <output-file>
 */

const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

// Metadata type mappings (directory name to metadata type)
const METADATA_MAPPINGS = {
    'classes': 'ApexClass',
    'triggers': 'ApexTrigger',
    'pages': 'ApexPage',
    'components': 'ApexComponent',
    'aura': 'AuraDefinitionBundle',
    'lwc': 'LightningComponentBundle',
    'flows': 'Flow',
    'workflows': 'Workflow',
    'objects': 'CustomObject',
    'fields': 'CustomField',
    'layouts': 'Layout',
    'tabs': 'CustomTab',
    'applications': 'CustomApplication',
    'permissionsets': 'PermissionSet',
    'profiles': 'Profile',
    'roles': 'Role',
    'staticresources': 'StaticResource',
    'labels': 'CustomLabels',
    'queues': 'Queue',
    'quickActions': 'QuickAction',
    'reportTypes': 'ReportType',
    'reports': 'Report',
    'dashboards': 'Dashboard',
    'sharingRules': 'SharingRules',
    'customMetadata': 'CustomMetadata',
    'flexipages': 'FlexiPage',
    'assignmentRules': 'AssignmentRules',
    'duplicateRules': 'DuplicateRule',
    'matchingRules': 'MatchingRule',
    'globalValueSets': 'GlobalValueSet',
    'standardValueSets': 'StandardValueSet'
};

function scanMetadataDirectory(metadataDir) {
    const typesMap = new Map();
    
    if (!fs.existsSync(metadataDir)) {
        console.error(`Warning: Metadata directory not found: ${metadataDir}`);
        return typesMap;
    }
    
    console.error(`Scanning metadata directory: ${metadataDir}`);
    
    // Recursively scan directory
    function scanDir(dir, relativePath = '') {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        
        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            const relPath = path.join(relativePath, entry.name);
            
            if (entry.isDirectory()) {
                // Check if this is a known metadata type directory
                const metadataType = METADATA_MAPPINGS[entry.name];
                
                if (metadataType) {
                    console.error(`Found metadata type: ${metadataType} (${entry.name})`);
                    
                    if (!typesMap.has(metadataType)) {
                        typesMap.set(metadataType, new Set());
                    }
                    
                    // Scan for metadata members
                    scanMetadataType(fullPath, metadataType, typesMap.get(metadataType));
                } else {
                    // Continue scanning
                    scanDir(fullPath, relPath);
                }
            }
        }
    }
    
    function scanMetadataType(dir, metadataType, membersSet) {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        
        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            
            if (entry.isDirectory()) {
                // For bundled types (Aura, LWC)
                if (['AuraDefinitionBundle', 'LightningComponentBundle'].includes(metadataType)) {
                    membersSet.add(entry.name);
                } else {
                    // Recursively scan subdirectories
                    scanMetadataType(fullPath, metadataType, membersSet);
                }
            } else if (entry.isFile()) {
                // Extract member name from filename
                const memberName = extractMemberName(entry.name, metadataType);
                if (memberName) {
                    membersSet.add(memberName);
                }
            }
        }
    }
    
    function extractMemberName(filename, metadataType) {
        // Remove metadata extensions
        const extensions = [
            '.cls', '.trigger', '.page', '.component', '.xml',
            '.layout', '.flexipage', '.flow', '.workflow',
            '.object', '.field', '.tab', '.app', '.permissionset',
            '.profile', '.role', '.resource', '.labels', '.queue',
            '.quickAction', '.reportType', '.report', '.dashboard',
            '.sharingRules', '.md-meta.xml', '-meta.xml'
        ];
        
        let name = filename;
        
        // Special handling for meta files
        if (filename.endsWith('-meta.xml')) {
            name = filename.replace('-meta.xml', '');
        } else if (filename.endsWith('.xml')) {
            // For some types, .xml is the actual extension
            if (['Flow', 'Workflow', 'Layout'].includes(metadataType)) {
                name = filename.replace('.xml', '');
            } else {
                // For others, it's a meta file
                return null;
            }
        } else {
            // Remove known extensions
            for (const ext of extensions) {
                if (name.endsWith(ext)) {
                    name = name.replace(ext, '');
                    break;
                }
            }
        }
        
        return name || null;
    }
    
    scanDir(metadataDir);
    
    return typesMap;
}

async function generateRecoveryManifest(metadataDir, outputFile) {
    try {
        const builder = new xml2js.Builder({
            xmldec: { version: '1.0', encoding: 'UTF-8' }
        });
        
        const typesMap = scanMetadataDirectory(metadataDir);
        
        if (typesMap.size === 0) {
            console.error('Warning: No metadata found to create recovery manifest');
            console.error('Creating empty recovery manifest');
        }
        
        // Build recovery manifest
        const recoveryPackage = {
            Package: {
                $: {
                    xmlns: 'http://soap.sforce.com/2006/04/metadata'
                },
                types: [],
                version: ['61.0']
            }
        };
        
        // Convert map to array of types
        for (const [typeName, membersSet] of typesMap.entries()) {
            if (membersSet.size > 0) {
                const members = Array.from(membersSet).sort();
                recoveryPackage.Package.types.push({
                    members: members,
                    name: [typeName]
                });
            }
        }
        
        // Sort types by name
        recoveryPackage.Package.types.sort((a, b) => {
            return a.name[0].localeCompare(b.name[0]);
        });
        
        // Write recovery manifest
        const xml = builder.buildObject(recoveryPackage);
        fs.writeFileSync(outputFile, xml);
        
        console.error(`Recovery manifest created with ${recoveryPackage.Package.types.length} metadata types`);
        
        // Log summary
        let totalMembers = 0;
        recoveryPackage.Package.types.forEach(type => {
            totalMembers += type.members.length;
            console.error(`  ${type.name[0]}: ${type.members.length} members`);
        });
        console.error(`Total members: ${totalMembers}`);
        
    } catch (error) {
        console.error(`Error generating recovery manifest: ${error.message}`);
        process.exit(1);
    }
}

// Main execution
if (process.argv.length < 4) {
    console.error('Usage: node generate-recovery-manifest.js <metadata-dir> <output-file>');
    process.exit(1);
}

const metadataDir = process.argv[2];
const outputFile = process.argv[3];

generateRecoveryManifest(metadataDir, outputFile);

