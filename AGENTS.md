# AGENTS.md

## Project Context

This repository contains the Business Central AL extension for the PREKIT UNS bridge.

The extension is the Business Central side of the PREKIT shop floor Execution app (2.0+):
- exposes the order book (production orders, routing lines as steps, work and machine centers) through API pages
- accepts step finishes, person time, operator notes, step moves and the station fine plan
- posts output only when Shopfloor Execution Setup "Post Output" is on; otherwise it records and posts nothing

The contract with the Execution app's BC adapter is `docs/execution-app-contract.md`. Change both together.

Layout: `app/` is the extension, `test/` the test app, `dev/bridge` a dev CLI.

## Versioning

The extension version is defined in [app/app.json](app/app.json) under the `version` field.

Current rule:
- version bumps are manual
- do not assume CI or GitHub will bump the AL app version automatically
- if a change should produce a new deployable `.app` artifact, bump `app/app.json` before merging to `main`

### When To Bump

Bump the version for any change that affects the packaged extension, especially:
- new tables, pages, codeunits, enums, permission sets, or API endpoints
- changes to API contracts or integration behavior
- work log ingestion or correction logic changes
- fixes that should be deployable to customer environments

Do not skip the bump just because the code change is small. If the result should be installed as a new app build, it needs a new version.

### When A Bump Is Usually Not Needed

A version bump is usually not needed for:
- docs-only changes
- comments only
- changes confined to local dev tooling that do not affect the packaged app

If in doubt, prefer bumping.

### How To Bump

Edit the `version` field in [app/app.json](app/app.json).

Use Business Central's four-part version format:
- `major.minor.patch.build`

Expected increment strategy:
- `major`: breaking or intentionally significant release line changes
- `minor`: new functionality or meaningful extension capability additions
- `patch`: bug fixes and safe behavioral fixes
- `build`: only use if the team explicitly wants build-only increments; otherwise prefer changing `patch`

Examples:
- `1.0.0.0` -> `1.1.0.0` for new execution-correction capability
- `1.1.0.0` -> `1.1.1.0` for a deployable bug fix

## Merge Rule

Before merging to `main`:
- confirm whether the branch changes require a new deployable artifact
- if yes, ensure `app/app.json` was bumped on the branch being merged
- do not rely on re-running an older merged commit if the version was not updated

If a merged PR was missing the bump, create a follow-up PR that only updates `app/app.json` and merge that before expecting the next build artifact to be usable as a new version.

## Key Constraints

- no direct ERP posting logic beyond the defined integration behavior
- keep auditability for execution corrections
- prefer deterministic BC-side handling over bridge-side business rules
- preserve upgrade-safe AL patterns

## Testing

Minimum expectation after functional changes:
- ensure the app version is correct for the release intent
- run or observe the AL build pipeline
- compile locally with alc (see README) including CodeCop, UICop and PerTenantExtensionCop
- run the AL tests in a BC container (Windows) before pushing; CI repeats them
- keep the upgrade from the last released version working (CI installs it first)
- verify any new API page or correction path end-to-end when possible
