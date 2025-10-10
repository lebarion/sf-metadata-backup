# Setup Scripts for Plugin

The SF CLI plugin depends on utility scripts from the main project. You need to copy these scripts into the plugin directory before building.

## Required Scripts

The following scripts need to be copied from `scripts/backup/` to `plugin-sf-backup/scripts/`:

1. `parse-buildfile.js` - Parses buildfile.json to extract manifest files
2. `combine-manifests.js` - Combines multiple package.xml files into one
3. `generate-recovery-manifest.js` - Generates recovery manifest from retrieved metadata
4. `generate-destructive-changes.js` - Creates destructive changes for new metadata
5. `generate-rollback-buildfile.js` - Generates rollback buildfile.json

## Automated Setup

Run this command from the project root to copy all required scripts:

```bash
# Create scripts directory in plugin
mkdir -p plugin-sf-backup/scripts

# Copy all utility scripts
cp scripts/backup/parse-buildfile.js plugin-sf-backup/scripts/
cp scripts/backup/combine-manifests.js plugin-sf-backup/scripts/
cp scripts/backup/generate-recovery-manifest.js plugin-sf-backup/scripts/
cp scripts/backup/generate-destructive-changes.js plugin-sf-backup/scripts/
cp scripts/backup/generate-rollback-buildfile.js plugin-sf-backup/scripts/

echo "✓ Scripts copied successfully!"
```

Or use this one-liner:

```bash
mkdir -p plugin-sf-backup/scripts && \
cp scripts/backup/{parse-buildfile,combine-manifests,generate-recovery-manifest,generate-destructive-changes,generate-rollback-buildfile}.js plugin-sf-backup/scripts/ && \
echo "✓ Scripts copied successfully!"
```

## Manual Setup

If you prefer to copy manually:

1. **Create the scripts directory:**
   ```bash
   cd plugin-sf-backup
   mkdir -p scripts
   ```

2. **Copy each script:**
   ```bash
   cp ../scripts/backup/parse-buildfile.js scripts/
   cp ../scripts/backup/combine-manifests.js scripts/
   cp ../scripts/backup/generate-recovery-manifest.js scripts/
   cp ../scripts/backup/generate-destructive-changes.js scripts/
   cp ../scripts/backup/generate-rollback-buildfile.js scripts/
   ```

3. **Verify the scripts:**
   ```bash
   ls -la scripts/
   ```

   You should see:
   ```
   parse-buildfile.js
   combine-manifests.js
   generate-recovery-manifest.js
   generate-destructive-changes.js
   generate-rollback-buildfile.js
   ```

## After Copying Scripts

### 1. Install Dependencies

The scripts require `xml2js`:

```bash
cd plugin-sf-backup
npm install
```

### 2. Build the Plugin

```bash
npm run build
```

### 3. Link for Development

```bash
sf plugins link
```

### 4. Test the Plugin

```bash
sf backup --help
sf backup create --help
```

## Verification

To verify scripts are correctly placed and working:

```bash
# Test parse-buildfile.js
node scripts/parse-buildfile.js ../manifest/buildfile.json

# Test combine-manifests.js (requires output from parse-buildfile)
# This is tested indirectly by the plugin

# All scripts are tested when you run:
sf backup create --target-org myOrg
```

## Script Locations in Plugin

After copying, the plugin directory structure should be:

```
plugin-sf-backup/
├── src/
│   └── commands/
│       └── backup/
│           ├── create.ts    (references scripts)
│           ├── rollback.ts  (references scripts)
│           └── list.ts
├── scripts/                 ← Scripts directory
│   ├── parse-buildfile.js
│   ├── combine-manifests.js
│   ├── generate-recovery-manifest.js
│   ├── generate-destructive-changes.js
│   └── generate-rollback-buildfile.js
├── messages/
├── package.json
└── tsconfig.json
```

## How Commands Use Scripts

The TypeScript commands reference scripts using relative paths:

```typescript
const scriptDir = path.join(__dirname, '../../../scripts');
const script = path.join(scriptDir, 'parse-buildfile.js');
execSync(`node "${script}" "${manifestSource}"`, { encoding: 'utf8' });
```

After building with `npm run build`, the compiled JavaScript in `lib/` will correctly reference `scripts/`.

## Troubleshooting

### Issue: "Cannot find module 'xml2js'"

**Solution:**
```bash
cd plugin-sf-backup
npm install
```

### Issue: "ENOENT: no such file or directory, open 'scripts/parse-buildfile.js'"

**Solution:**
```bash
# Verify scripts directory exists
ls -la plugin-sf-backup/scripts/

# If empty, copy scripts again
cp scripts/backup/*.js plugin-sf-backup/scripts/
```

### Issue: Scripts run but commands fail

**Solution:**
```bash
# Rebuild the plugin
cd plugin-sf-backup
npm run clean
npm run build
sf plugins link
```

## Updating Scripts

If you modify any of the utility scripts in `scripts/backup/`, remember to copy them to the plugin again:

```bash
# Copy updated scripts
cp scripts/backup/*.js plugin-sf-backup/scripts/

# Rebuild
cd plugin-sf-backup
npm run build
```

## For Distribution

When publishing the plugin to NPM, ensure `package.json` includes scripts in the files array:

```json
{
  "files": [
    "/lib",
    "/messages",
    "/scripts",      ← Important!
    "/oclif.manifest.json"
  ]
}
```

This ensures the scripts are included in the NPM package.

---

**Setup complete!** Your plugin is now ready to use with all required scripts in place.

