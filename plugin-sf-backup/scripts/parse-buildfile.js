#!/usr/bin/env node

/**
 * Parse buildfile.json and extract manifest files
 * 
 * Usage: node parse-buildfile.js <buildfile-path>
 * Output: List of manifest file paths (one per line)
 */

const fs = require('fs');
const path = require('path');

function parseBuildfile(buildfilePath) {
    try {
        const buildfileContent = fs.readFileSync(buildfilePath, 'utf8');
        const buildfile = JSON.parse(buildfileContent);
        
        if (!buildfile.builds || !Array.isArray(buildfile.builds)) {
            console.error('Error: Invalid buildfile format - missing builds array');
            process.exit(1);
        }
        
        const manifestFiles = [];
        
        buildfile.builds.forEach((build, index) => {
            if (build.type === 'metadata' && build.manifestFile) {
                manifestFiles.push(build.manifestFile);
            }
        });
        
        if (manifestFiles.length === 0) {
            console.error('Error: No metadata builds with manifestFile found');
            process.exit(1);
        }
        
        // Output manifest files (one per line)
        manifestFiles.forEach(file => console.log(file));
        
    } catch (error) {
        console.error(`Error parsing buildfile: ${error.message}`);
        process.exit(1);
    }
}

// Main execution
if (process.argv.length < 3) {
    console.error('Usage: node parse-buildfile.js <buildfile-path>');
    process.exit(1);
}

const buildfilePath = process.argv[2];

if (!fs.existsSync(buildfilePath)) {
    console.error(`Error: Buildfile not found: ${buildfilePath}`);
    process.exit(1);
}

parseBuildfile(buildfilePath);

