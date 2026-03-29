# Anshin Project

Last updated: 2026-03-29

## Vision
Anshin is a calm finance assistant for Paraguay users, focused on everyday
money control with low friction and clear feedback.

## Product Scope (Current)
- Google Sign-In
- Onboarding with salary + plan templates
- Budget by categories (Fijos, Variables, Ahorro)
- Capture flows:
  - OCR ticket scan
  - voice expense capture
  - bank notification capture (Android)
- Movement management:
  - add manual
  - edit
  - delete
- Persistence:
  - budget plan
  - movements
- UI:
  - light mode and dark mode
  - modernized green visual system

## Out of Scope (For Now)
- Multi-currency support
- Full backend sync and multi-device account sync
- Advanced analytics dashboards

## Tech Stack
- Flutter (Material 3)
- Dart
- Main packages:
  - `google_sign_in`
  - `google_mlkit_text_recognition`
  - `speech_to_text`
  - `shared_preferences`
  - `flutter_local_notifications`
  - `notification_listener_service`

## Repo Structure
- `lib/main.dart`: current main app flow and state
- `test/widget_test.dart`: basic smoke test
- `hooks/`: git hooks for local quality gates
- `docs/`: release notes and architecture checklists
- `AGENTS.md`: engineering guardrails
- `PROJECT.md`: product and project source of truth

## Runtime Configuration
- Android package id: `com.anshin.android`
- Firebase Google Services file in:
  - `android/app/google-services.json`

## Local Development
1. Install dependencies
```bash
flutter pub get
```
2. Analyze
```bash
flutter analyze --no-pub
```
3. Test
```bash
flutter test --no-pub
```
4. Run on device
```bash
flutter run -d <device_id> --no-resident --no-pub
```

## Git Hooks
Hooks are included in `hooks/` and can be installed with:

```bash
sh hooks/setup-hooks.sh
```

Windows PowerShell alternative:

```powershell
powershell -ExecutionPolicy Bypass -File hooks/setup-hooks.ps1
```

Included hooks:
- `pre-commit`: format + analyze + simple safety checks
- `pre-push`: analyze + tests
- `commit-msg`: conventional commit validation

## Release Docs
- `docs/CHANGELOG.md`
- `docs/RELEASE_NOTES_v1.0.0.md`
- `docs/RELEASE_NOTES_v1.0.1.md`
- `docs/RELEASE_NOTES_v1.0.1_TEMPLATE.md`
- `docs/RELEASE_NOTES_v1.1.0_TEMPLATE.md`
- `docs/RELEASE_SCOPE_v1.0.1.md`
- `docs/ARCHITECTURE_CHECKLIST_v1.0.md`
- `docs/TEAM_RELEASE_CHECKLIST_v1.0.md`
- `docs/VERSIONING.md`

## Definition of Done
- Feature behavior matches product request.
- Light and dark mode both readable.
- Amount inputs use readable thousand separators.
- Local persistence verified for affected data.
- `flutter analyze --no-pub` passes.
- `flutter test --no-pub` passes.

## Next Milestones
- Better OCR confidence and visual review flow for uncertain totals
- Movement list filters and search
- Monthly report cards with actionable recommendations
- Optional cloud sync layer
