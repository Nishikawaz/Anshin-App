# Release Scope — v1.0.1

Fecha: 2026-03-29
Owner: Equipo Anshin

## Objetivo
Cerrar regresiones de UX y estabilidad detectadas después de v1.0.0 sin cambiar
el alcance funcional mayor.

## Must Have
- OCR más confiable para detectar montos de facturas.
- Persistencia local de movimientos.
- Persistencia de sueldo y plantilla entre sesiones.
- Legibilidad dark mode sin texto oscuro sobre fondo oscuro.
- Separadores de miles consistentes en inputs de monto críticos.

## Should Have
- Mensajes más claros cuando OCR/voz no detectan monto confiable.
- Validación visual de plantilla activa tras relogin.

## Could Have
- Mejor heurística de comercio detectado por OCR.
- Métricas básicas de precisión de OCR para QA interno.

## No-Go Items
- Reintroducir multimoneda.
- Publicar sin validación manual de OCR/voz.
- Cambiar arquitectura grande en patch release.

## QA Matrix
- Android físico:
  - Login Google
  - Onboarding
  - OCR ticket
  - Voz
  - Editar/borrar
  - Persistencia
- Gates:
  - `flutter analyze --no-pub`
  - `flutter test --no-pub`

## Rollback
- Si falla OCR o persistencia de manera crítica:
  - volver a último tag estable
  - publicar hotfix mínimo.

