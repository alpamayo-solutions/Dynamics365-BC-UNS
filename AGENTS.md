# AGENTS.md

## Project Context

This repository contains the Business Central AL extension for the PREKIT UNS bridge.

The extension:
- ingests shopfloor execution and disruption events
- creates and closes work log entries
- exposes read/write API pages used by the bridge
- applies audited execution corrections

The extension does not replace ERP production posting or costing logic. It is an integration layer anchored in Business Central.

## Versioning

The extension version is defined in [app.json](/Users/alpamayo/projects/d365_uns_app/app.json) under the `version` field.

Current rule:
- version bumps are manual
- do not assume CI or GitHub will bump the AL app version automatically
- if a change should produce a new deployable `.app` artifact, bump `app.json` before merging to `main`

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

Edit the `version` field in [app.json](/Users/alpamayo/projects/d365_uns_app/app.json).

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
- if yes, ensure `app.json` was bumped on the branch being merged
- do not rely on re-running an older merged commit if the version was not updated

If a merged PR was missing the bump, create a follow-up PR that only updates `app.json` and merge that before expecting the next build artifact to be usable as a new version.

## Key Constraints

- no direct ERP posting logic beyond the defined integration behavior
- keep auditability for execution corrections
- prefer deterministic BC-side handling over bridge-side business rules
- preserve upgrade-safe AL patterns

## Testing

Minimum expectation after functional changes:
- ensure the app version is correct for the release intent
- run or observe the AL build pipeline
- run related AL tests when available
- verify any new API page or correction path end-to-end when possible
