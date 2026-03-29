# Anshin Flutter — Release v1.0.0

Fecha: 2026-03-29
Estado: Candidate

## Resumen
Versión inicial funcional de Anshin enfocada en control de gastos en PYG,
onboarding de presupuesto por plantilla, y captura de movimientos por OCR/voz.

## Objetivo del release
- Entregar una app usable de punta a punta en Android.
- Mantener UX clara y calmada en modo claro y oscuro.
- Guardar datos clave del usuario localmente.

## Funcionalidades incluidas
- Login con Google.
- Onboarding con:
  - sueldo en PYG
  - plantillas de presupuesto (equilibrado, ahorro, supervivencia, custom)
  - formato de miles en montos.
- Dashboard con:
  - “¿Puedo comprar esto?” con evaluación rápida.
  - captura OCR.
  - captura por voz.
  - conexión a notificaciones bancarias (Android).
- Movimientos:
  - alta manual
  - edición
  - borrado
  - registro desde OCR/voz/banco.
- Persistencia local:
  - sueldo y plantilla activos
  - movimientos.
- Moneda única:
  - PYG en toda la app.
- Tema visual:
  - modo claro y modo oscuro.

## Cambios clave de UX
- Diseño visual modernizado, consistente con identidad verde de Anshin.
- Mejor legibilidad de textos en dark mode.
- Separadores de miles en entradas de monto.
- Cambio de plantilla disponible desde pantalla Presupuesto.

## Riesgos conocidos
- OCR de facturas puede fallar en tickets con baja calidad o formatos atípicos.
- Parsing por voz depende de calidad de micrófono/ruido del entorno.
- Persistencia actual es local al dispositivo (sin sync cloud).

## Criterios de aceptación (Go/No-Go)
- Login con Google funcional.
- Onboarding persiste sueldo y plantilla al reiniciar app.
- OCR y voz insertan movimiento editable/borrable.
- Lista de movimientos no carga datos demo.
- Modo claro/oscuro legible en pantallas principales.
- `flutter analyze --no-pub` en verde.
- `flutter test --no-pub` en verde.

## Smoke test recomendado
1. Instalar app en Android físico.
2. Iniciar sesión con Google.
3. Configurar sueldo y plantilla.
4. Cerrar sesión y volver a entrar.
5. Verificar que sueldo/plantilla se mantienen.
6. Crear movimiento manual.
7. Editar y borrar ese movimiento.
8. Probar OCR con ticket real.
9. Probar voz con frase “gaste 45.000 en supermercado”.
10. Cambiar entre modo claro/oscuro y revisar contraste.

## Rollback
Si una regresión bloquea uso básico:
- volver al commit/tag estable anterior
- publicar hotfix con scope mínimo.

