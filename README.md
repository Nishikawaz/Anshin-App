# Anshin — 安心

> *Alivio financiero para Paraguay.*

Anshin (安心, *alivio* en japonés) es una app de finanzas personales construida para usuarios paraguayos. Lee automáticamente notificaciones de bancos locales, registra gastos por voz, foto de ticket o manualmente, y te da claridad sobre tu dinero — sin fricción.

---

## Características

- **Captura automática** — Lee notificaciones de Itaú, Ueno y Continental sin que hagas nada
- **OCR de tickets** — Fotografía un comprobante y la app extrae el monto
- **Entrada por voz** — Dicta un gasto en español paraguayo
- **Presupuesto por plantillas** — Equilibrado, ahorro, supervivencia o personalizado
- **Modo claro / oscuro** — UI moderna con Material 3
- **Persistencia local** — Sin cuenta ni nube requerida para empezar

---

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Framework | Flutter (Dart) |
| UI | Material 3 |
| Auth | Firebase Auth (Google Sign-In) |
| OCR | ML Kit Text Recognition |
| Voz | speech\_to\_text |
| Notificaciones | notification\_listener\_service |
| Persistencia | shared\_preferences |

---

## Requisitos

| Herramienta | Versión mínima |
|-------------|----------------|
| Flutter SDK | 3.x |
| Android SDK | API 26 (Android 8) |
| Android Studio | Hedgehog 2023.1+ |
| Dart | 3.x |

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-org/anshin-app.git
cd anshin-app/anshin_flutter

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase
#    Descargar google-services.json desde Firebase Console → Proyecto Anshin
#    Colocarlo en: android/app/google-services.json

# 4. Instalar git hooks (opcional pero recomendado)
sh hooks/setup-hooks.sh          # Bash / macOS / Linux
# .\hooks\setup-hooks.ps1        # Windows PowerShell

# 5. Ejecutar
flutter run
```

Si tenés varios dispositivos conectados:

```bash
flutter devices
flutter run -d <device_id>
```

---

## Build de release

```bash
# APK firmado para Android
flutter build apk --release

# App Bundle para Play Store
flutter build appbundle --release
```

---

## Estructura del proyecto

```
anshin_flutter/
├── lib/
│   └── main.dart          # Flujo principal y estado de la app
├── android/
│   └── app/
│       └── google-services.json   # ← colocar aquí (no commitear)
├── hooks/                 # Git hooks: pre-commit, pre-push, commit-msg
├── docs/                  # Changelogs, release notes, checklists
├── AGENTS.md              # Guardrails de ingeniería
└── PROJECT.md             # Fuente de verdad del producto
```

---

## Bancos soportados

| Banco | Formato detectado |
|-------|-------------------|
| Itaú PY | "Compra aprobada por G. XX.XXX en COMERCIO" |
| Ueno | "Pagaste G XX.XXX a COMERCIO" |
| Continental | "Débito G. XX.XXX - COMERCIO" |

Para agregar un banco: ver [docs/README.md](docs/README.md#bancos-soportados).

---

## Desarrollo

```bash
# Análisis estático
flutter analyze --no-pub

# Tests
flutter test --no-pub

# Formatear código
dart format lib/
```

### Git hooks incluidos

| Hook | Qué hace |
|------|----------|
| `pre-commit` | Format + analyze + chequeos de seguridad |
| `pre-push` | Analyze + tests completos |
| `commit-msg` | Valida formato Conventional Commits |

---

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [PROJECT.md](anshin_flutter/PROJECT.md) | Visión, alcance y stack del producto |
| [GOOGLE_SIGNIN_SETUP.md](anshin_flutter/GOOGLE_SIGNIN_SETUP.md) | Configurar Firebase y SHA |
| [docs/CHANGELOG.md](anshin_flutter/docs/CHANGELOG.md) | Historial de cambios |
| [docs/VERSIONING.md](anshin_flutter/docs/VERSIONING.md) | Política de versionado |
| [docs/README.md](docs/README.md) | Arquitectura detallada |

---

## Versión actual

**v1.0.0** — lanzamiento inicial (2026-03-29)

- Onboarding con salario y plantillas de presupuesto
- Captura manual, OCR, voz y notificaciones bancarias
- Edición y eliminación de movimientos
- Persistencia local completa
- Tema claro y oscuro

Próximas versiones: [CHANGELOG](anshin_flutter/docs/CHANGELOG.md)

---

## Versionado

`MAJOR.MINOR.PATCH` — Semantic Versioning

- `MAJOR`: cambios de arquitectura o base de datos incompatibles
- `MINOR`: features nuevas
- `PATCH`: bugfixes y mejoras menores
