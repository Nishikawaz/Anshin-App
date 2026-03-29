# AGENTS.md — Anshin Finance App

## Project overview

**Anshin** (安心 — relief, peace of mind) is an Android personal finance app for Paraguay.
First app in Paraguay to read local bank notifications automatically.
Design philosophy: **El orden es progreso.**

Stack: Kotlin · Jetpack Compose · Clean Architecture + MVVM · Room + SQLCipher · Firebase · Hilt

---

## Environment setup

```bash
# Build debug APK
./gradlew assembleDebug

# Run all unit tests
./gradlew testDebugUnitTest

# Run lint
./gradlew lintDebug

# Run a single test class
./gradlew testDebugUnitTest --tests "com.anshin.core.notification.ItauParserTest"

# Install on connected device
./gradlew installDebug
```

> `google-services.json` is required in `app/`. Decode from CI secret or ask a teammate.

---

## Absolute rules — never break these

```
MONEY      → Long (cents)          NEVER Double or Float
DOMAIN     → no android.*          NEVER import Android SDK in domain/
AUDIO      → language from config  NEVER hardcode "es-PY" in code
CATEGORIES → from Room DB          NEVER hardcoded list in source
OCR/Audio  → isConfirmed = false   NEVER save without user confirmation
DB         → SQLCipher ALWAYS      NEVER plain Room in production
LOGS       → no financial data     NEVER Log.d with amounts, accounts, names
```

---

## Repository structure

```
app/
├── data/
│   ├── local/
│   │   ├── db/            # AnshinDatabase, Converters
│   │   ├── dao/           # TransactionDao, BudgetDao, GoalDao, StreakDao
│   │   ├── entity/        # Room entities (Entity suffix)
│   │   └── speech/        # AndroidSpeechToTextRepository
│   ├── remote/
│   │   ├── config/        # SpeechConfig, RemoteConfigRepository
│   │   └── firebase/      # FirestoreRepository
│   └── repository/        # Concrete repository implementations
├── domain/
│   ├── model/             # Transaction, Budget, Goal, Streak (no Entity suffix)
│   ├── repository/        # Interfaces — NO android.* imports here
│   └── usecase/           # One file = one use case
│       ├── transaction/
│       ├── budget/
│       ├── speech/
│       ├── ocr/
│       └── streak/
├── presentation/
│   ├── ui/
│   │   ├── dashboard/
│   │   ├── transaction/
│   │   ├── budget/
│   │   ├── audio/
│   │   ├── ocr/
│   │   ├── onboarding/
│   │   ├── streak/
│   │   ├── education/
│   │   └── premium/
│   ├── viewmodel/
│   ├── navigation/        # AnshinNavGraph, Routes
│   └── theme/             # AnshinTheme, Color, Type, Shape
└── core/
    ├── notification/      # BankNotificationService, BankParser, parsers/
    ├── security/          # BiometricHelper, PassphraseManager
    ├── currency/          # CurrencyFormatter, MultiCurrencyConverter
    └── utils/
```

---

## Naming conventions

| Type | Convention | Example |
|------|-----------|---------|
| Room entity | `NounEntity` | `TransactionEntity` |
| Domain model | `Noun` | `Transaction` |
| DAO | `NounDao` | `TransactionDao` |
| ViewModel | `NounViewModel` | `DashboardViewModel` |
| UseCase | `VerbNounUseCase` | `RegisterTransactionUseCase` |
| Screen composable | `NounScreen` | `DashboardScreen` |
| Content composable | `NounContent` | `DashboardContent` |
| Repository impl | `NounRepositoryImpl` | `TransactionRepositoryImpl` |

---

## Money — always Long in cents

```kotlin
// Correct: ₲ 85.000 → amountCents = 85_000L
// Correct: USD 10.50 → amountCents = 1050L
// Format only in presentation layer:
fun Long.toPYG() = NumberFormat.getCurrencyInstance(Locale("es", "PY")).format(this)
```

---

## Data flow

```
Room/API → Repository → UseCase → ViewModel (StateFlow) → Composable
                                                        ↑
                                               collectAsStateWithLifecycle()
```

---

## Supported banks

| Bank | Package | Notification format |
|------|---------|-------------------|
| Itaú PY | `com.itau.py` | "Compra aprobada por G. XX.XXX en MERCHANT" |
| Ueno | `py.ueno.app` | "Pagaste G XX.XXX a MERCHANT" |
| Continental | `py.continental.banca` | "Débito G. XX.XXX - MERCHANT" |

Each bank = one parser file in `core/notification/parsers/`.
To add a new bank: implement `BankParser`, register in `BankNotificationService`, add tests.

---

## Firebase Remote Config keys

| Key | Default | Description |
|-----|---------|-------------|
| `stt_language_code` | `"es-PY"` | STT language — NEVER hardcode |
| `stt_max_alternatives` | `3` | Recognition alternatives |
| `budget_alert_thresholds` | `[50,75,90,100]` | Alert % per category |
| `streak_reward_days` | `{"7":"7d","30":"15d","90":"1m"}` | Streak rewards |
| `premium_trial_days` | `7` | Trial days for new users |
| `cc_alert_presets` | `[25,50,75,90]` | Credit card alert presets |
| `parser_failure_threshold` | `5` | Failed parses before alerting |

Always read Remote Config through `ConfigRepository`, never directly in ViewModels.

---

## Security checklist per feature

- [ ] Amount is `Long`? Not `Double`, not `String`
- [ ] Entity has `isConfirmed` if from OCR or audio?
- [ ] Any `Log.d/e` with user financial data? → remove
- [ ] Direct SharedPreferences? → use `EncryptedSharedPreferences`
- [ ] DB without `SupportFactory(passphrase)`? → add encryption

---

## Test naming

```kotlin
@Test fun `itau parser extracts 85000 from compra notification`()
@Test fun `speech extractor returns null when no number spoken`()
@Test fun `streak breaks after 24h without activity and no freeze`()
```

Coverage targets: `domain/usecase/` 90% · `parsers/` 95% · `repository/` 75% · `viewmodel/` 70%

---

## Commit format

```
feat(notification): add Continental bank parser
fix(speech): handle empty SpeechRecognizer result
test(parser): add Ueno parser unit tests
chore(deps): bump Room to 2.6.1
```

---

## Do NOT

- Use `Double`/`Float` for monetary amounts
- Hardcode language strings, category lists, or alert thresholds
- Save OCR/audio data without a `Review` confirmation step
- Import `android.*` inside `domain/`
- Use `fallbackToDestructiveMigration()` in Room
- Add logs containing user financial information
- Push directly to `main`
