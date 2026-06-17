# Neon Switch — Versioning Policy

Neon Switch uses the version stored at:

```text
project.godot → application/config/version
```

The HUD reads this value directly and displays it in the top-left corner of every build.

## Development Format

During foundation and pre-release development, use:

```text
0.1.0-dev.N
```

`N` is the development build number.

Examples:

```text
0.1.0-dev.2
0.1.0-dev.3
0.1.0-dev.4
```

## Required Rule

Every pull request that changes the playable game must increment the development build number before merge.

A playable-game change includes modifications to:

- `scripts/**`
- `scenes/**`
- `project.godot`
- The application icon or runtime assets

Documentation-only and test-only pull requests do not require a version bump unless they accompany a game change.

## Update Procedure

1. Read the current value in `project.godot`.
2. Increment the final development number by one.
3. Update the expected version in `tests/baseline_smoke_test.gd`.
4. Run the Godot baseline workflow.
5. Confirm the HUD test passes.
6. Mention the new version in the pull request summary and milestone report.

Do not hard-code the version in `hud.gd`. The HUD must continue reading the canonical value from `ProjectSettings`.

## Automated Guard

`.github/workflows/version-guard.yml` compares the pull-request branch against its base branch. When runtime game files change, the workflow fails if the value in `project.godot` has not changed.

The guard does not choose the version number; it simply prevents a playable update from quietly reusing the previous build identity.

## Release Versions

When the project reaches public release readiness, development versions will transition to semantic release versions:

```text
1.0.0
1.0.1
1.1.0
```

Until then, increment `0.1.0-dev.N` for every playable update.
