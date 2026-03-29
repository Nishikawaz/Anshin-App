# PROJECT.md — Anshin 安心
> Este archivo es la memoria del proyecto. Actualizarlo con cada decisión importante.
> Codex lo lee junto con AGENTS.md al abrir el proyecto.

---

## Qué es Anshin

App de finanzas personales para Android, orientada al mercado paraguayo.
Primera app en Paraguay en leer notificaciones bancarias locales automáticamente.

**Nombre:** Anshin (安心) — significa *alivio, paz mental, tranquilidad* en japonés.
**Tagline:** El orden es progreso.
**Filosofía:** Kaizen (mejora continua), Ma (espacio y respiración), Wabi (simplicidad).

---

## Estado actual del proyecto

| Ítem | Estado |
|------|--------|
| Identidad de marca | ✅ Definida |
| Arquitectura técnica | ✅ Definida |
| AGENTS.md + hooks + docs | ✅ Generados |
| Android best practices skill | ✅ Creado |
| MVP — funcionalidades core | 🔄 En desarrollo |
| Demo MVP | 📅 Pendiente (presentación próxima) |
| Play Store | ⏳ Post-MVP |

---

## Producto

### Modelo de negocio

| Tier | Precio | Features |
|------|--------|----------|
| Free | Gratis | Captura, dashboard, presupuesto base, educación, rachas |
| Premium | A definir (mensual/anual) | Reporting avanzado, proyecciones, múltiples perfiles, exportación |
| Premium por racha | Gratis (recompensa) | 7 días racha → 7d premium · 30 días → 15d · 90 días → 1 mes |

### Funcionalidades — prioridad y estado

#### Demo MVP (las 3 que funcionan sólido)
1. **Captura automática desde banco** — NotificationListenerService (Itaú, Ueno, Continental)
2. **Dashboard principal** — "Disponible hoy" como número central
3. **Presupuesto con alertas** — plantilla 60/30/10, alertas configurables

#### Beta en demo (se muestran controladas)
1. **OCR — carga por foto** — ML Kit, requiere confirmación del usuario
2. **STT — carga por voz** — idioma desde Remote Config, requiere confirmación
3. **Educación financiera** — tips contextuales por pantalla
4. **Sistema de rachas** — contador diario + freeze + recompensas
5. **Reporte semanal** — resumen automático cada domingo

#### V2 (se anuncia como "próximamente")
- Importación Excel / Google Sheets / CSV
- Metas de ahorro con visualización
- Detector de gastos recurrentes
- Múltiples perfiles

### Features propias — no negociables

- **"¿Puedo comprar esto?"** — el usuario ingresa un monto, la app responde si rompe o no su plan. Feature de viralidad.
- **Multi-moneda desde v1** — PYG, USD, BRL (crítico para Ciudad del Este y frontera)
- **Freeze de racha desde v1** — si no está, los usuarios se van con rencor al perder una racha larga
- **Max 1 notificación push por día** — el sistema de alertas rediseñado para no generar fatiga

### North Star Metric

> % de usuarios que registran al menos 1 transacción por semana durante 4 semanas consecutivas.

Objetivo: 40% de retención semanal en los primeros 90 días.

---

## Identidad visual

### Paleta

| Rol | Color | Hex |
|-----|-------|-----|
| Principal (headers, botones, logo) | Verde bosque | `#1A4A31` |
| Acción | Verde principal | `#2A7A4E` |
| Interactivo | Verde acción | `#3A9A63` |
| Suave (fondos de card) | Verde pálido | `#EEF8F2` |
| Fondo base | Blanco natural | `#FAFBFA` |
| Texto primario | Gris oscuro | `#3A4240` |
| Texto secundario | Gris medio | `#6B7573` |

### Tipografía

| Uso | Fuente | Peso |
|-----|--------|------|
| Titulares, onboarding, momentos emocionales | DM Serif Display | Regular / Italic |
| Navegación, labels, montos | DM Sans | 500 |
| Cuerpo, descripciones, educación | DM Sans | 400 |
| Categorías, etiquetas | DM Sans | 300 uppercase |

### Logo

El ícono combina:
- **Arco superior** → referencia al kanji 安 (techo = protección, refugio)
- **Línea de tendencia ascendente** → progreso financiero
- **Base horizontal** → orden, estabilidad

### Principios de diseño

1. **Ma** — espacio negativo como elemento de diseño
2. **Wabi** — solo lo esencial, sin decoración innecesaria
3. **Kaizen** — el usuario debe sentir que avanza cada vez que abre la app

### Voz y tono

- Accesible, sin tecnicismos
- Directo pero nunca alarmista
- "Gastaste el 75% esta semana. Todavía estás en control." ✅
- "¡ALERTA! ¡Superaste casi todo tu presupuesto!" ❌

---

## Arquitectura técnica

### Stack

| Capa | Tecnología |
|------|-----------|
| Lenguaje | Kotlin |
| UI | Jetpack Compose + Material3 |
| Arquitectura | Clean Architecture + MVVM |
| DI | Hilt |
| Base de datos | Room + SQLCipher (cifrado obligatorio) |
| Config remota | Firebase Remote Config |
| Auth | Firebase Auth |
| Analytics | Firebase Analytics |
| OCR | ML Kit Text Recognition (on-device) |
| STT | Android SpeechRecognizer + SpeechConfig desde RemoteConfig |
| Gráficos | MPAndroidChart o Vico |
| Pagos Premium | Google Play Billing |

### Reglas absolutas

```
DINERO     → Long (centavos)       NUNCA Double, Float
DOMINIO    → sin android.*         NUNCA importar SDK Android en domain/
AUDIO      → idioma desde config   NUNCA hardcodear "es-PY" en código
CATEGORÍAS → desde Room            NUNCA lista hardcodeada en código
OCR/Audio  → isConfirmed = false   NUNCA guardar sin confirmación del usuario
DB         → SQLCipher SIEMPRE     NUNCA Room sin cifrado en producción
LOGS       → sin datos financieros NUNCA Log.d con montos, cuentas o nombres
```

### Estructura de módulos

```
app/
├── data/          # Room, Firebase, parsers, SpeechRepo, OcrProcessor
├── domain/        # UseCases, interfaces de repositorios, modelos (sin android.*)
├── presentation/  # Composables, ViewModels, NavGraph, Theme
└── core/          # BankNotificationService, parsers/, security/, currency/
```

---

## Bancos soportados

| Banco | Formato de notificación | Parser |
|-------|------------------------|--------|
| Itaú PY | "Compra aprobada por G. XX.XXX en COMERCIO" | `ItauParser` |
| Ueno | "Pagaste G XX.XXX a COMERCIO" | `UenoParser` |
| Continental | "Débito G. XX.XXX - COMERCIO" | `ContinentalParser` |

Los parsers son actualizables sin release vía sistema de monitoreo con Firebase Analytics.

---

## Firebase Remote Config — claves activas

| Clave | Default | Descripción |
|-------|---------|-------------|
| `stt_language_code` | `"es-PY"` | Idioma STT |
| `stt_max_alternatives` | `3` | Alternativas de reconocimiento |
| `budget_alert_thresholds` | `[50,75,90,100]` | % de alerta por categoría |
| `streak_reward_days` | `{"7":"7d","30":"15d","90":"1m"}` | Hitos de racha |
| `education_content_version` | `1` | Versión de contenido educativo |
| `premium_trial_days` | `7` | Días de trial |
| `cc_alert_presets` | `[25,50,75,90]` | % para alerta de TC |
| `parser_failure_threshold` | `5` | Notificaciones sin parsear antes de alertar |

---

## Riesgos críticos conocidos

| Riesgo | Mitigación |
|--------|-----------|
| Onboarding del permiso de notificaciones (Android 13+) | Pantalla dedicada de 3 pasos con animación |
| Parsers bancarios que se rompen sin aviso | ParseFailureTracker + alerta a Firebase |
| Fatiga de notificaciones push | Máximo 1 notificación por día |
| Estado vacío en primer uso | Empty state como momento motivacional con onboarding de 3 preguntas |
| Multi-moneda (CDE, frontera) | PYG + USD + BRL desde v1 |

---

## Decisiones pendientes

- [ ] Precio del plan Premium (mensual / anual / freemium puro)
- [ ] Backend propio vs. Firebase solo (impacta en arquitectura long-term)
- [ ] Estrategia de contenido educativo: ¿equipo interno o curado?
- [ ] Política de privacidad y cumplimiento regulatorio PY
- [ ] Nombre de la empresa / entidad legal

---

## Archivos del proyecto generados

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `AGENTS.md` | `/` | Guía principal para Codex |
| `PROJECT.md` | `/` | Este archivo — memoria del proyecto |
| `hooks/pre-commit` | `/hooks/` | Bloquea errores de seguridad y tipado |
| `hooks/pre-push` | `/hooks/` | Tests + lint antes de pushear |
| `hooks/commit-msg` | `/hooks/` | Valida Conventional Commits |
| `hooks/setup-hooks.sh` | `/hooks/` | Instala todos los hooks |
| `docs/README.md` | `/docs/` | Documentación técnica completa |
| `docs/bank-parsers.md` | `/docs/` | Formatos y edge cases por banco |
| `docs/CHANGELOG.md` | `/docs/` | Historial de versiones |
| `.github/workflows/ci.yml` | `/.github/` | CI: lint, tests, security checks, build |
| `android-best-practices.skill` | — | Skill instalable para Claude |
