# Anshin Flutter — Team Release Checklist v1.0

Fecha: 2026-03-29
Objetivo: checklist operativo para liberar versión estable.

## Pre-release
- Versionado definido (`pubspec.yaml`).
- Dependencias actualizadas y lockfile consistente.
- Hooks instalados localmente.
- Documentación actualizada:
  - `AGENTS.md`
  - `PROJECT.md`
  - `docs/RELEASE_NOTES_v1.0.0.md`

## QA funcional
- Login Google en dispositivo real.
- Onboarding completo (sueldo + plantilla).
- Persistencia validada tras cerrar/reabrir app.
- Cambio de plantilla desde Presupuesto.
- Captura OCR con ticket real.
- Captura por voz con frase simple y monto.
- Agregar/editar/borrar movimiento manual.
- Modo claro y oscuro revisado.

## QA técnico
- `flutter analyze --no-pub`.
- `flutter test --no-pub`.
- Build debug Android exitosa.
- App abre correctamente en dispositivo real.

## Publicación interna
- Tag de release creado.
- Release notes publicadas en el repo.
- Riesgos conocidos comunicados al equipo.

## Post-release
- Monitoreo de feedback temprano (OCR, voz, persistencia).
- Registro de incidencias en backlog.
- Definición de hotfix plan si hay regresiones.

