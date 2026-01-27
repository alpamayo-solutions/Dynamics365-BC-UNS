# Releasing UNS Bridge Connector

This document describes how to create releases for the UNS Bridge Connector app.

## Prerequisites

- VS Code with AL Language extension
- GitHub CLI (`gh`) installed and authenticated
- Access to the GitHub repository

## Build Process

1. **Update version in `app.json`**

   Increment the version number following semantic versioning:

   ```json
   {
     "version": "X.Y.Z.0"
   }
   ```

   - **Major (X):** Breaking changes or major feature additions
   - **Minor (Y):** New features, backward compatible
   - **Patch (Z):** Bug fixes, backward compatible
   - **Build (0):** Always 0 for releases

2. **Build the app package**

   In VS Code:
   - Press `Cmd+Shift+B` (macOS) or `Ctrl+Shift+B` (Windows/Linux)
   - Select **AL: Package**

   This creates `alpamayo_UNS Bridge Connector_X.Y.Z.0.app` in the project root.

3. **Verify the build**

   Ensure the `.app` file exists and the version matches `app.json`.

## Creating a GitHub Release

1. **Create the release with the app file**

   ```bash
   gh release create vX.Y.Z \
     --title "UNS Bridge Connector vX.Y.Z" \
     --notes "Release notes here..." \
     "alpamayo_UNS Bridge Connector_X.Y.Z.0.app"
   ```

   Replace `X.Y.Z` with the actual version number.

2. **Example for v1.0.0**

   ```bash
   gh release create v1.0.0 \
     --title "UNS Bridge Connector v1.0.0" \
     --notes "Initial release of UNS Bridge Connector for Business Central 26.x

   ## Features
   - Observe shopfloor execution data in Business Central
   - Anchor execution facts to production orders and routing operations
   - Observer-only integration (no posting, no inventory changes)

   ## Requirements
   - Microsoft Dynamics 365 Business Central 26.0+
   - Cloud target deployment" \
     "alpamayo_UNS Bridge Connector_1.0.0.0.app"
   ```

## Version Convention

- **Git tag:** `vX.Y.Z` (e.g., `v1.0.0`)
- **App version:** `X.Y.Z.0` (e.g., `1.0.0.0`)

The git tag should match the first three components of the app.json version.

## Post-Release

After creating a release:

1. Verify the release appears at: https://github.com/alpamayo-solutions/Dynamics365-BC-UNS-Workorders/releases
2. Test the download link works
3. Verify the website picks up the new release (may take a few minutes due to caching)

## Troubleshooting

**"command not found: gh"**
Install GitHub CLI: https://cli.github.com/

**Authentication errors**
Run `gh auth login` to authenticate with GitHub.

**File not found**
Ensure you're in the project root directory and the `.app` file exists.
