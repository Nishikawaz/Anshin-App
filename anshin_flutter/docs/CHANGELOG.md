# Changelog

All notable changes to this project will be documented in this file.

Format is based on Keep a Changelog and this project uses Semantic Versioning.

## [Unreleased]
### Added
- v1.0.1 release scope and draft notes:
  - `docs/RELEASE_NOTES_v1.0.1.md`
  - `docs/RELEASE_SCOPE_v1.0.1.md`

### Changed
- Amount input formatting and template workflows prepared for patch stabilization.

### Fixed
- OCR parsing heuristics and persistence flows prepared for patch QA.

## [1.0.0] - 2026-03-29
### Added
- Google Sign-In and onboarding flow.
- Salary and budget template setup (equilibrado, ahorro, supervivencia, custom).
- Budget template switcher from Budget screen.
- Movement capture by manual input, OCR, voice, and bank notifications.
- Movement edit and delete actions.
- Light/dark theme support.
- Local persistence for budget plan and movements.
- Project guardrails and release documentation:
  - `AGENTS.md`
  - `PROJECT.md`
  - release docs and checklists
  - git hooks (`pre-commit`, `pre-push`, `commit-msg`)

### Changed
- PYG established as the only currency.
- Amount entry formatting improved with thousands separators.
- OCR amount parsing improved to prioritize receipt totals.
- “¿Puedo comprar esto?” input alignment and readability improved.

### Fixed
- Dark mode readability issues in key screens.
- Salary/template reset issue after logout/login.
- Demo auto-seeded movements removed at startup.

## Planned Next Releases
### [1.0.1] - Patch (planned)
- OCR parsing robustness improvements for difficult tickets.
- Minor UX polish and bug fixes from production feedback.
- Stability hardening for voice capture fallback paths.

### [1.1.0] - Minor (planned)
- Movement filters/search and quality-of-life list improvements.
- Clear review flow for uncertain OCR captures.
- Better monthly summary and progress insights.
