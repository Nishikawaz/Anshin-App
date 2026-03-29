# Anshin Flutter — Architecture Checklist v1.0

Fecha: 2026-03-29
Uso: checklist de revisión técnica por PR y por release.

## 1. Dominio de producto
- PYG se mantiene como única moneda visible y de cálculo.
- Flujo principal sigue simple: login → onboarding → uso diario.
- Cambios no rompen edición/borrado de movimientos.

## 2. Estado y datos
- Estado crítico no se pierde al reiniciar app.
- Persistencia local maneja errores sin crashear.
- Claves de storage son estables y documentadas.
- No se guardan secretos en texto plano.

## 3. Entradas de movimientos
- Manual/OCR/voz/banco convergen al mismo modelo de movimiento.
- Monto siempre validado como entero PYG.
- OCR y voz tienen mensajes de error claros cuando no hay monto confiable.
- Todo movimiento creado puede editarse y borrarse.

## 4. UI y diseño
- Modo claro y oscuro revisados en:
  - Login
  - Onboarding
  - Dashboard
  - Movimientos
  - Presupuesto
  - Racha
- Contraste de texto correcto en fondos oscuros.
- Inputs de montos con separador de miles.

## 5. Calidad de código
- No introducir lógica grande sin función helper reutilizable.
- No acoplar parseo OCR/voz a widgets.
- Evitar literales duplicados para reglas de negocio.
- Mantener naming consistente en español funcional.

## 6. Observabilidad y errores
- Mensajes de integración deben ser entendibles por usuario final.
- Errores de OCR/voz no bloquean navegación.
- Errores de storage no deben romper startup.

## 7. Seguridad y privacidad
- No loggear datos sensibles (saldo, tokens, cuentas, credenciales).
- No exponer contenido completo de notificaciones bancarias en logs.
- Revisar permisos Android solicitados y su justificación.

## 8. Gates técnicos obligatorios
- `flutter analyze --no-pub` pasa.
- `flutter test --no-pub` pasa.
- Hook `pre-commit` instalado y ejecutando.
- Hook `pre-push` instalado y ejecutando.
- Commit message en formato convencional.

## 9. Definición de “listo para merge”
- Checklist completo sin bloqueantes.
- QA manual básico completado.
- Riesgos conocidos documentados en release notes.

