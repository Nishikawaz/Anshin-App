# Anshin Agents Guide

Last updated: 2026-03-29

## Purpose
This document defines how we build and evolve Anshin in this Flutter repo.
It is intentionally practical and aligned with the current product direction.

## Product Direction
- Core promise: calm and clear personal finance for Paraguay users.
- Primary currency: PYG only.
- Voice and OCR are convenience inputs, not "magic".
- Every movement must remain editable and removable.

## Non-Negotiable Rules
- Keep PYG as the only currency in UX and business logic.
- Preserve a calm, non-alarmist tone in messages.
- Keep dark mode and light mode equally readable.
- Respect user data ownership:
  - local data should persist across app restarts and re-login
  - avoid storing sensitive raw logs
- New captures (OCR/voice/bank) must create real movements and allow edit/delete.

## Current Functional Contract
- Authentication:
  - login with Google
  - logout does not erase saved budget plan
- Onboarding:
  - salary in PYG
  - preset selection (equilibrado/ahorro/supervivencia/custom)
  - thousands separator while typing amounts
- Budget:
  - one active plan with percentages totaling 100
  - plan can be changed from Budget screen
- Movements:
  - manual, OCR, voice, and bank notifications
  - persisted locally
  - editable and deletable

## UI/UX Rules
- Typography:
  - keep current DM Sans / DM Serif pairing unless intentionally redesigned
- Visual language:
  - green-forward, calm, clean spacing
  - avoid noisy warning colors unless truly required
- Accessibility:
  - do not hardcode dark text on dark backgrounds
  - use theme colors for text and surfaces
- Inputs:
  - amount fields must use thousands separators for readability

## Code Rules
- Keep logic deterministic and easy to debug.
- Favor small pure helpers for parsing/formatting.
- Avoid introducing heavy dependencies without a clear need.
- If adding persistence keys, use stable names and document them.
- Keep network assumptions explicit; degrade gracefully if unavailable.

## Data Persistence Rules
- Budget plan persistence keys:
  - `anshin.salary_pyg`
  - `anshin.plan_name`
  - `anshin.plan_fixed`
  - `anshin.plan_variable`
  - `anshin.plan_savings`
- Movements persistence key:
  - `anshin.transactions`
- Backward compatibility:
  - parsing from storage must fail safely and never crash startup

## OCR/Voice Rules
- OCR should prioritize receipt totals over random numeric tokens.
- Voice should parse common spoken number patterns in Spanish.
- If amount is uncertain, show a clear message and avoid silent wrong inserts.
- Merchant guessing should avoid invoice boilerplate lines.

## Quality Gates
- Before merging meaningful code changes:
  - `flutter analyze --no-pub`
  - `flutter test --no-pub`
- Keep widget tests minimal but stable.
- If tests are flaky because of startup async, assert shell-level invariants.

## Delivery Checklist
- Feature works in both light and dark themes.
- Amount inputs have thousands separator behavior.
- Data survives app restart and auth re-entry.
- No regressions in edit/delete movement actions.
- Analyzer and tests pass.

## Roadmap Direction
- Short term:
  - improve OCR precision and review UX for ambiguous captures
  - movement filters and search
- Mid term:
  - modularize state into feature folders
  - optional cloud sync after local-first is stable

