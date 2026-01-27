# Releasing UNS Bridge Connector

This document describes how to create releases for the UNS Bridge Connector app.

## Automated Release Process (Recommended)

The repository uses GitHub Actions to automatically handle releases:

1. **Create a release on GitHub** with a version tag (e.g., `v1.1.0`)
2. The workflow automatically:
   - Extracts the version from the tag
   - Updates `app.json` with the new version
   - Commits the version bump to `main`
   - Builds the app in a BC container
   - Uploads the zip file to the release

### Creating a Release

#### Option 1: GitHub Web UI

1. Go to [Releases](https://github.com/alpamayo-solutions/Dynamics365-BC-UNS/releases)
2. Click **Draft a new release**
3. Create a new tag (e.g., `v1.1.0`)
4. Add a title and release notes
5. Click **Publish release**

The workflow will handle versioning and building automatically.

#### Option 2: GitHub CLI

```bash
gh release create v1.1.0 \
  --title "UNS Bridge Connector v1.1.0" \
  --notes "## Changes
- Feature X
- Bug fix Y

## Requirements
- Business Central 26.0+
- Cloud target"
```

### What Happens Automatically

1. **Version extraction:** `v1.1.0` → `1.1.0.0` in `app.json`
2. **Commit:** Version bump committed to `main`
3. **Build:** App compiled in BC 26 container with CodeCop and UICop
4. **Upload:** Zip file attached to the release

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build.yml` | Push to main, PRs | Validates builds compile successfully |
| `release.yml` | Release created | Bumps version, builds, uploads artifact |

## Version Convention

- **Git tag:** `vX.Y.Z` (e.g., `v1.0.0`, `v1.1.0`, `v2.0.0`)
- **App version:** `X.Y.Z.0` (automatically set from tag)

Semantic versioning:
- **Major (X):** Breaking changes
- **Minor (Y):** New features, backward compatible
- **Patch (Z):** Bug fixes

## Manual Build (Local Development)

For local testing without creating a release:

1. In VS Code, press `Cmd+Shift+B` / `Ctrl+Shift+B`
2. Select **AL: Package**
3. The `.app` file is created in the project root

## Post-Release Verification

1. Check the release at: https://github.com/alpamayo-solutions/Dynamics365-BC-UNS/releases
2. Verify the zip file is attached
3. Check that `app.json` on `main` has the updated version
4. Website should show new version (may take a few minutes)

## Troubleshooting

**Build failed in CI**
- Check the Actions tab for error details
- Common issues: syntax errors, missing dependencies, CodeCop violations

**Version not updated**
- Ensure the tag follows the `vX.Y.Z` format
- Check if the workflow had permission to push to `main`

**Release has no artifact**
- The build job may have failed after version update
- Check the release workflow run for errors
