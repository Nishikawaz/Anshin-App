# Anshin — 安心
### App de finanzas personales para Paraguay

> **El orden es progreso.**

Anshin (安心, *alivio* en japonés) es la primera app de finanzas personales en Paraguay que lee automáticamente las notificaciones de los bancos locales — Itaú, Ueno y Continental — y registra los gastos sin fricción. Construida con filosofía japonesa: simplicidad, orden y mejora continua.

---

## Índice

- [Setup inicial](#setup-inicial)
- [Arquitectura](#arquitectura)
- [Módulos principales](#módulos-principales)
- [Bancos soportados](#bancos-soportados)
- [Firebase Remote Config](#firebase-remote-config)
- [Seguridad](#seguridad)
- [Testing](#testing)
- [Releases](#releases)

---

## Setup inicial

### Requisitos

| Herramienta | Versión mínima |
|------------|----------------|
| Android Studio | Hedgehog 2023.1 |
| JDK | 17 |
| Kotlin | 1.9.x |
| minSdk | 26 (Android 8) |
| targetSdk | 34 |
| Gradle | 8.2 |

### Primeros pasos

```bash
# 1. Clonar
git clone https://github.com/tu-org/anshin-android.git
cd anshin-android

# 2. Instalar git hooks
sh hooks/setup-hooks.sh

# 3. Agregar google-services.json
# Descargarlo desde Firebase Console → Proyecto Anshin
# Colocarlo en: app/google-services.json

# 4. Variables de entorno locales
cp local.properties.example local.properties
# Editar local.properties con tus valores

# 5. Buildear
./gradlew assembleDebug
```

### local.properties.example

```properties
sdk.dir=/path/to/Android/sdk
# DB passphrase para desarrollo (producción viene de Keystore)
ANSHIN_DB_DEV_PASSPHRASE=dev_only_change_in_prod
```

---

## Arquitectura

Clean Architecture + MVVM. Tres capas con dependencias en una sola dirección.

```
┌─────────────────────────────────────────┐
│           presentation/                  │
│   Composables · ViewModels · NavGraph   │
└──────────────────┬──────────────────────┘
                   │ depende de
┌──────────────────▼──────────────────────┐
│              domain/                     │
│   UseCases · Modelos · Interfaces Repo  │  ← sin android.*
└──────────────────┬──────────────────────┘
                   │ implementado por
┌──────────────────▼──────────────────────┐
│               data/                      │
│   Room · Firebase · SpeechRepo · OCR   │
└─────────────────────────────────────────┘
```

**Regla de oro:** `domain/` no importa `android.*`. Es Kotlin puro, testeable sin emulador.

---

## Módulos principales

### 1. Captura automática de gastos

La app escucha notificaciones bancarias mediante `BankNotificationService` (extiende `NotificationListenerService`). Cada banco tiene su propio parser en `core/notification/parsers/`.

```
Notificación llega → BankNotificationService
  → parsers.firstOrNull { canHandle() }
  → parse() → TransactionEntity(isConfirmed = true)
  → TransactionRepository.insert()
  → Flow actualiza Dashboard automáticamente
```

**Permiso requerido:** El usuario activa manualmente en Configuración → Accesibilidad. La pantalla `NotificationPermissionScreen` guía el proceso en 3 pasos.

### 2. Carga por voz (Speech-to-Text)

```
Usuario habla → SpeechToTextRepository
  → Flow<SpeechResult.Partial | Final | Error>
  → ExtractTransactionFromSpeechUseCase
  → AudioInputState.Review (isConfirmed = false)
  → Usuario confirma → TransactionRepository.insert()
```

El idioma se lee de `SpeechConfig` → Firebase Remote Config (`stt_language_code`). Nunca hardcodeado.

### 3. Carga por foto (OCR)

```
Foto del ticket → ReceiptOcrProcessor (ML Kit)
  → OcrResult(amount, merchant, isConfirmed = false)
  → OcrConfirmScreen — el usuario verifica
  → Usuario confirma → TransactionRepository.insert()
```

### 4. Presupuestos

Plantillas predefinidas configurables. Los umbrales de alerta (`budget_alert_thresholds`) vienen de Remote Config. La lógica vive en `CheckAlertThresholdUseCase`.

```
Plantilla 50/30/20: necesidades / deseos / ahorro
Plantilla 60/30/10: fijos / variables / ahorro     ← default Anshin
Plantilla personalizada: el usuario define %
```

### 5. Sistema de rachas

```
Usuario abre la app → UpdateStreakUseCase
  → Si < 24h desde última apertura: racha++
  → Si > 24h y tiene freeze: consume freeze
  → Si > 24h sin freeze: racha = 0
  → CheckStreakRewardUseCase → desbloquear Premium si aplica
```

Hitos y recompensas en Remote Config (`streak_reward_days`).

### 6. Educación financiera

Tips contextuales en cada pantalla. El contenido se actualiza sin release desde Remote Config (`education_content_version`). Estructura: `EducationTip(screen, content, source)`.

---

## Bancos soportados

| Banco | Parser | Formato detectado |
|-------|--------|-------------------|
| Itaú PY | `ItauParser` | "Compra aprobada por G. XX.XXX en COMERCIO" |
| Ueno | `UenoParser` | "Pagaste G XX.XXX a COMERCIO" |
| Continental | `ContinentalParser` | "Débito G. XX.XXX - COMERCIO" |

Para agregar un banco nuevo:
1. Crear `NuevoBancoParser : BankParser` en `core/notification/parsers/`
2. Agregar a la lista en `BankNotificationService`
3. Agregar tests en `NuevoBancoParserTest` con ejemplos reales de notificaciones
4. Actualizar esta tabla

---

## Firebase Remote Config

Todas las configuraciones que pueden cambiar sin un nuevo release:

| Clave | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `stt_language_code` | String | `"es-PY"` | Idioma del reconocimiento de voz |
| `stt_max_alternatives` | Long | `3` | Alternativas STT |
| `stt_interim_results` | Boolean | `true` | Resultados parciales en tiempo real |
| `budget_alert_thresholds` | JSON | `[50,75,90,100]` | % de alerta por categoría |
| `streak_reward_days` | JSON | `{"7":"7d","30":"15d","90":"1m"}` | Hitos de racha → recompensa |
| `education_content_version` | Long | `1` | Versión del contenido educativo |
| `premium_trial_days` | Long | `7` | Días de trial para nuevos usuarios |
| `cc_alert_presets` | JSON | `[25,50,75,90]` | % predefinidos para alerta de TC |

Inicialización en `Application.onCreate()`:
```kotlin
remoteConfig.setDefaultsAsync(R.xml.remote_config_defaults)
remoteConfig.fetchAndActivate()
```

---

## Seguridad

### Base de datos

Room + SQLCipher. El passphrase se genera en el primer arranque y se guarda en `EncryptedSharedPreferences`. En producción, reforzado con Android Keystore.

### Datos en tránsito

HTTPS obligatorio. Network Security Config bloquea cleartext. Firebase usa TLS 1.2+.

### Acceso a la app

Biometría en `onResume()` si el usuario lo habilitó. Fallback a PIN de 6 dígitos.

### Qué nunca debe aparecer en logs

`amount`, `balance`, `accountNumber`, `token`, `password`, `monto`, `saldo`. El hook `pre-commit` bloquea commits que contengan `Log.*` con estas palabras.

---

## Testing

```bash
# Unit tests (sin emulador)
./gradlew testDebugUnitTest

# Tests de instrumentación (emulador requerido)
./gradlew connectedDebugAndroidTest

# Lint
./gradlew lintDebug

# Reporte de cobertura
./gradlew testDebugUnitTestCoverage
# → app/build/reports/coverage/
```

### Cobertura mínima requerida

| Capa | Mínimo |
|------|--------|
| `domain/usecase/` | 90% |
| `core/notification/parsers/` | 95% |
| `data/repository/` | 75% |
| `presentation/viewmodel/` | 70% |

---

## Releases

### Ramas

```
main          → producción (protegida, solo PRs)
develop       → integración
feature/xxx   → features nuevas
fix/xxx       → bugfixes
release/x.x   → preparación de release
```

### Checklist pre-release

- [ ] Todos los tests pasan (`testDebugUnitTest`)
- [ ] Lint sin errores (`lintDebug`)
- [ ] `versionCode` incrementado en `build.gradle`
- [ ] `versionName` actualizado
- [ ] `CHANGELOG.md` actualizado
- [ ] Remote Config defaults actualizados en `remote_config_defaults.xml`
- [ ] ProGuard rules verificadas para nuevas clases
- [ ] APK firmado con keystore de producción
- [ ] Probado en Android 8 (minSdk) y Android 14 (targetSdk)

### Versionado

`MAJOR.MINOR.PATCH` — Semantic Versioning
- `MAJOR`: cambios de arquitectura o base de datos incompatibles
- `MINOR`: features nuevas
- `PATCH`: bugfixes y mejoras menores
