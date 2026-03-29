# Anshin Flutter — Release v1.0.1

Fecha: 2026-03-29
Estado: Draft listo para ejecución

## Resumen
Patch release de estabilización enfocado en captura de gastos, consistencia visual
y persistencia local.

## Cambios incluidos
### Fixed
- OCR de facturas ajustado para priorizar montos de líneas tipo `TOTAL`/`IMPORTE`.
- Corrección de legibilidad de textos en modo oscuro en pantallas clave.
- Corrección visual en “¿Puedo comprar esto?” para mejorar alineación del ejemplo.
- Eliminación de movimientos demo que se autogeneraban al iniciar.
- Corrección de pérdida de sueldo/plantilla al cerrar sesión y volver a ingresar.

### Changed
- Entradas de monto con separadores de miles más consistentes.
- Cambio de plantilla disponible directamente desde pantalla Presupuesto.

### Added
- Persistencia local de movimientos (manual/OCR/voz/banco) con `SharedPreferences`.
- Base documental de release y arquitectura (`AGENTS.md`, `PROJECT.md`, docs v1.0).
- Hooks de calidad (`pre-commit`, `pre-push`, `commit-msg`) y scripts de instalación.

## Riesgos conocidos
- OCR aún depende de calidad de foto/impresión del ticket.
- Persistencia local no sincroniza entre dispositivos.

## QA ejecutado (actual)
- `flutter analyze --no-pub`: OK
- `flutter test --no-pub`: OK
- Smoke manual Android: OK (instala y abre en dispositivo físico)

## QA pendiente antes de publicar
- Validar OCR con 3 tickets reales de formatos distintos.
- Validar voz con 3 frases distintas con monto en español.
- Validar persistencia tras reinicio completo de app.

## Criterio de salida
- [ ] OCR aceptable en pruebas reales de ticket.
- [ ] Sin regresiones en editar/borrar movimientos.
- [ ] Persistencia validada en ciclo login/logout/reinicio.
- [ ] Changelog actualizado y tag generado.

