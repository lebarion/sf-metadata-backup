#!/usr/bin/env node

/**
 * Generate destructive changes for metadata that doesn't exist in the org
 * (metadata that will be deployed but wasn't in the org before)
 * 
 * Usage: node generate-destructive-changes.js <deployment-manifest> <recovery-manifest> <output-file>
 */

const fs = require('fs');
const xml2js = require('xml2js');

async function generateDestructiveChanges(deploymentManifest, recoveryManifest, outputFile) {
    try {
        const parser = new xml2js.Parser();
        const builder = new xml2js.Builder({
            xmldec: { version: '1.0', encoding: 'UTF-8' }
        });
        
        // Parse deployment manifest (what will be deployed)
        console.error('Parsing deployment manifest...');
        const deploymentXml = fs.readFileSync(deploymentManifest, 'utf8');
        const deploymentPkg = await parser.parseStringPromise(deploymentXml);
        
        // Parse recovery manifest (what exists in org)
        console.error('Parsing recovery manifest...');
        let recoveryPkg = null;
        
        if (fs.existsSync(recoveryManifest)) {
            const recoveryXml = fs.readFileSync(recoveryManifest, 'utf8');
            recoveryPkg = await parser.parseStringPromise(recoveryXml);
        } else {
            console.error('Warning: Recovery manifest not found, all deployment metadata will be marked for deletion');
        }
        
        // Build map of existing metadata
        const existingMetadata = new Map();
        
        if (recoveryPkg && recoveryPkg.Package && recoveryPkg.Package.types) {
            recoveryPkg.Package.types.forEach(type => {
                const typeName = type.name[0];
                const members = new Set(type.members || []);
                existingMetadata.set(typeName, members);
            });
        }
        
        // Find new metadata (in deployment but not in org)
        const newMetadata = new Map();
        
        if (deploymentPkg.Package && deploymentPkg.Package.types) {
            deploymentPkg.Package.types.forEach(type => {
                const typeName = type.name[0];
                const deploymentMembers = type.members || [];
                const existingMembers = existingMetadata.get(typeName) || new Set();
                
                const newMembers = deploymentMembers.filter(member => {
                    return !existingMembers.has(member);
                });
                
                if (newMembers.length > 0) {
                    newMetadata.set(typeName, newMembers);
                }
            });
        }
        
        // Build destructive changes manifest
        const destructivePackage = {
            Package: {
                $: {
                    xmlns: 'http://soap.sforce.com/2006/04/metadata'
                },
                types: [],
                version: ['61.0']
            }
        };
        
        // Convert map to array of types
        for (const [typeName, members] of newMetadata.entries()) {
            destructivePackage.Package.types.push({
                members: members.sort(),
                name: [typeName]
            });
        }
        
        // Sort types by name
        destructivePackage.Package.types.sort((a, b) => {
            return a.name[0].localeCompare(b.name[0]);
        });
        
        // Write destructive changes
        const xml = builder.buildObject(destructivePackage);
        fs.writeFileSync(outputFile, xml);
        
        console.error(`Destructive changes created with ${destructivePackage.Package.types.length} metadata types`);
        
        // Log summary
        let totalMembers = 0;
        destructivePackage.Package.types.forEach(type => {
            totalMembers += type.members.length;
            console.error(`  ${type.name[0]}: ${type.members.length} members`);
        });
        console.error(`Total members to delete: ${totalMembers}`);
        
        if (totalMembers === 0) {
            console.error('Note: No new metadata detected - all deployment metadata exists in org');
        }
        
    } catch (error) {
        console.error(`Error generating destructive changes: ${error.message}`);
        console.error(error.stack);
        process.exit(1);
    }
}

// Main execution
if (process.argv.length < 5) {
    console.error('Usage: node generate-destructive-changes.js <deployment-manifest> <recovery-manifest> <output-file>');
    process.exit(1);
}

const deploymentManifest = process.argv[2];
const recoveryManifest = process.argv[3];
const outputFile = process.argv[4];

if (!fs.existsSync(deploymentManifest)) {
    console.error(`Error: Deployment manifest not found: ${deploymentManifest}`);
    process.exit(1);
}

generateDestructiveChanges(deploymentManifest, recoveryManifest, outputFile);

