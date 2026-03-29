# Versioning Guide

This project follows Semantic Versioning:
- `MAJOR.MINOR.PATCH`

## Rules
- PATCH (`x.y.Z`): bug fixes, no breaking behavior.
- MINOR (`x.Y.z`): new backward-compatible features.
- MAJOR (`X.y.z`): breaking changes.

## Release Update Steps
1. Update `pubspec.yaml` version.
2. Update `docs/CHANGELOG.md`.
3. Create/update release notes file in `docs/`.
4. Run:
   - `flutter analyze --no-pub`
   - `flutter test --no-pub`
5. Commit with conventional commit message.
6. Create tag:
```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

## Suggested Convention
- Stable release tags: `v1.0.0`, `v1.0.1`, `v1.1.0`
- Branch naming for release prep:
  - `release/v1.0.1`
  - `release/v1.1.0`

