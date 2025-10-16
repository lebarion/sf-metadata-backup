#!/usr/bin/env node

/**
 * Generate rollback buildfile.json following sf-orgdevmode-builds standards
 * 
 * The rollback process consists of two steps:
 * 1. Deploy destructive changes (remove new metadata)
 * 2. Deploy old metadata (restore previous state)
 * 
 * Supports two modes:
 * - orgdevmode: Creates buildfile.json for sf-orgdevmode-builds plugin
 * - standard: Creates buildfile.json documenting standard CLI commands
 * 
 * Usage: node generate-rollback-buildfile.js <recovery-manifest> <destructive-changes> <output-file> [mode]
 */

const fs = require('fs');
const path = require('path');

function generateRollbackBuildfile(recoveryManifest, destructiveChanges, outputFile, mode = 'orgdevmode') {
    try {
        console.error(`Generating rollback buildfile (${mode} mode)...`);
        
        // Determine relative paths from rollback directory (where buildfile.json is located)
        const rollbackDir = path.dirname(outputFile);
        const recoveryManifestRel = path.relative(rollbackDir, recoveryManifest);
        const destructiveDir = path.dirname(destructiveChanges);
        const destructiveDirRel = path.relative(rollbackDir, destructiveDir);
        
        // Check if files exist
        const hasRecoveryManifest = fs.existsSync(recoveryManifest);
        const hasDestructiveChanges = fs.existsSync(destructiveChanges);
        
        // Build rollback configuration based on mode
        let rollbackBuildfile;
        
        if (mode === 'orgdevmode') {
            // sf-orgdevmode-builds mode
            rollbackBuildfile = {
                builds: []
            };
            
            // Step 1: Deploy recovery metadata FIRST (restore old state)
            if (hasRecoveryManifest) {
                const recoveryXml = fs.readFileSync(recoveryManifest, 'utf8');
                
                // Check if recovery manifest has any metadata
                if (recoveryXml.includes('<members>')) {
                    console.error('Adding recovery metadata deployment step...');
                    rollbackBuildfile.builds.push({
                        type: 'metadata',
                        manifestFile: recoveryManifestRel,
                        testLevel: 'NoTestRun',
                        timeout: '180',
                        ignoreWarnings: true,
                        disableTracking: true
                    });
                } else {
                    console.error('No recovery metadata found (org had no existing metadata)');
                }
            }
            
            // Step 2: Deploy destructive changes SECOND (remove new metadata)
            if (hasDestructiveChanges) {
                const destructiveXml = fs.readFileSync(destructiveChanges, 'utf8');
                
                // Check if destructive changes has any metadata
                if (destructiveXml.includes('<members>')) {
                    console.error('Adding destructive changes step...');
                    rollbackBuildfile.builds.push({
                        type: 'metadata',
                        manifestFile: `${destructiveDirRel}/package.xml`,
                        testLevel: 'NoTestRun',
                        postDestructiveChanges: `${destructiveDirRel}/destructiveChanges.xml`,
                        timeout: '180',
                        ignoreWarnings: true,
                        disableTracking: true
                    });
                } else {
                    console.error('No destructive changes needed (no new metadata detected)');
                }
            }
            
            // If no builds were added, create a minimal buildfile
            if (rollbackBuildfile.builds.length === 0) {
                console.error('Warning: No rollback steps needed - creating empty buildfile');
                rollbackBuildfile.builds.push({
                    type: 'metadata',
                    manifestFile: `${destructiveDirRel}/package.xml`,
                    testLevel: 'NoTestRun',
                    timeout: '180',
                    ignoreWarnings: true,
                    disableTracking: true
                });
            }
        } else {
            // Standard mode - document CLI commands in buildfile
            rollbackBuildfile = {
                mode: 'standard',
                description: 'Rollback using standard Salesforce CLI commands',
                steps: []
            };
            
            // Step 1: Deploy recovery metadata FIRST (restore old state)
            if (hasRecoveryManifest) {
                const recoveryXml = fs.readFileSync(recoveryManifest, 'utf8');
                
                if (recoveryXml.includes('<members>')) {
                    console.error('Adding recovery metadata deployment step...');
                    rollbackBuildfile.steps.push({
                        name: 'Restore old metadata',
                        command: 'sf project deploy start',
                        options: {
                            manifest: recoveryManifestRel,
                            'ignore-warnings': true,
                            wait: 60
                        }
                    });
                } else {
                    console.error('No recovery metadata found (org had no existing metadata)');
                }
            }
            
            // Step 2: Deploy destructive changes SECOND (remove new metadata)
            if (hasDestructiveChanges) {
                const destructiveXml = fs.readFileSync(destructiveChanges, 'utf8');
                
                if (destructiveXml.includes('<members>')) {
                    console.error('Adding destructive changes step...');
                    rollbackBuildfile.steps.push({
                        name: 'Remove new metadata',
                        command: 'sf project deploy start',
                        options: {
                            manifest: `${destructiveDirRel}/package.xml`,
                            'post-destructive-changes': `${destructiveDirRel}/destructiveChanges.xml`,
                            'ignore-warnings': true,
                            wait: 60
                        }
                    });
                } else {
                    console.error('No destructive changes needed (no new metadata detected)');
                }
            }
            
            if (rollbackBuildfile.steps.length === 0) {
                console.error('Warning: No rollback steps needed');
                rollbackBuildfile.steps.push({
                    name: 'No rollback needed',
                    command: 'echo',
                    options: {
                        message: 'No metadata changes detected'
                    }
                });
            }
        }
        
        // Write rollback buildfile
        fs.writeFileSync(outputFile, JSON.stringify(rollbackBuildfile, null, 2));
        
        if (mode === 'orgdevmode') {
            console.error(`Rollback buildfile created with ${rollbackBuildfile.builds.length} build step(s)`);
            console.error('');
            console.error('Rollback sequence:');
            rollbackBuildfile.builds.forEach((build, index) => {
                console.error(`  ${index + 1}. ${build.type} deployment`);
                console.error(`     - Manifest: ${build.manifestFile}`);
                if (build.postDestructiveChanges) {
                    console.error(`     - Destructive changes: ${build.postDestructiveChanges}`);
                }
                if (build.preDestructiveChanges) {
                    console.error(`     - Pre-destructive changes: ${build.preDestructiveChanges}`);
                }
            });
        } else {
            console.error(`Rollback buildfile created with ${rollbackBuildfile.steps.length} step(s)`);
            console.error('');
            console.error('Rollback sequence:');
            rollbackBuildfile.steps.forEach((step, index) => {
                console.error(`  ${index + 1}. ${step.name}`);
                console.error(`     - Command: ${step.command}`);
            });
        }
        
    } catch (error) {
        console.error(`Error generating rollback buildfile: ${error.message}`);
        console.error(error.stack);
        process.exit(1);
    }
}

// Main execution
if (process.argv.length < 5) {
    console.error('Usage: node generate-rollback-buildfile.js <recovery-manifest> <destructive-changes> <output-file> [mode]');
    console.error('  mode: "orgdevmode" (default) or "standard"');
    process.exit(1);
}

const recoveryManifest = process.argv[2];
const destructiveChanges = process.argv[3];
const outputFile = process.argv[4];
const mode = process.argv[5] || 'orgdevmode';

if (mode !== 'orgdevmode' && mode !== 'standard') {
    console.error('Error: mode must be "orgdevmode" or "standard"');
    process.exit(1);
}

generateRollbackBuildfile(recoveryManifest, destructiveChanges, outputFile, mode);

