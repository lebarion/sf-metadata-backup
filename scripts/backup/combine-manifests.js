#!/usr/bin/env node

/**
 * Combine multiple manifest files into a single package.xml
 * 
 * Usage: node combine-manifests.js <manifest-files> <output-file> <project-root>
 */

const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

async function combineManifests(manifestFiles, outputFile, projectRoot) {
    try {
        const parser = new xml2js.Parser();
        const builder = new xml2js.Builder({
            xmldec: { version: '1.0', encoding: 'UTF-8' }
        });
        
        const typesMap = new Map();
        let version = '61.0';
        
        // Parse each manifest file
        const manifestPaths = manifestFiles.trim().split('\n');
        
        for (const manifestPath of manifestPaths) {
            const fullPath = path.join(projectRoot, manifestPath);
            
            if (!fs.existsSync(fullPath)) {
                console.error(`Warning: Manifest file not found: ${fullPath}`);
                continue;
            }
            
            console.error(`Processing: ${manifestPath}`);
            const xmlContent = fs.readFileSync(fullPath, 'utf8');
            const result = await parser.parseStringPromise(xmlContent);
            
            if (!result.Package) {
                console.error(`Warning: Invalid package.xml format in ${manifestPath}`);
                continue;
            }
            
            // Extract version
            if (result.Package.version && result.Package.version[0]) {
                version = result.Package.version[0];
            }
            
            // Extract types
            if (result.Package.types) {
                result.Package.types.forEach(type => {
                    const typeName = type.name[0];
                    
                    if (!typesMap.has(typeName)) {
                        typesMap.set(typeName, new Set());
                    }
                    
                    const membersSet = typesMap.get(typeName);
                    
                    if (type.members) {
                        type.members.forEach(member => {
                            membersSet.add(member);
                        });
                    }
                });
            }
        }
        
        // Build combined manifest
        const combinedPackage = {
            Package: {
                $: {
                    xmlns: 'http://soap.sforce.com/2006/04/metadata'
                },
                types: [],
                version: [version]
            }
        };
        
        // Convert map to array of types
        for (const [typeName, membersSet] of typesMap.entries()) {
            const members = Array.from(membersSet).sort();
            combinedPackage.Package.types.push({
                members: members,
                name: [typeName]
            });
        }
        
        // Sort types by name
        combinedPackage.Package.types.sort((a, b) => {
            return a.name[0].localeCompare(b.name[0]);
        });
        
        // Write combined manifest
        const xml = builder.buildObject(combinedPackage);
        fs.writeFileSync(outputFile, xml);
        
        console.error(`Combined manifest created with ${combinedPackage.Package.types.length} metadata types`);
        
    } catch (error) {
        console.error(`Error combining manifests: ${error.message}`);
        process.exit(1);
    }
}

// Main execution
if (process.argv.length < 5) {
    console.error('Usage: node combine-manifests.js <manifest-files> <output-file> <project-root>');
    process.exit(1);
}

const manifestFiles = process.argv[2];
const outputFile = process.argv[3];
const projectRoot = process.argv[4];

combineManifests(manifestFiles, outputFile, projectRoot);

