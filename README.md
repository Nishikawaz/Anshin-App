# Anshin App

Aplicación de finanzas personales enfocada en Paraguay (PYG), con diseño moderno, onboarding financiero y funcionalidades inteligentes para registrar gastos.

## Proyecto actual

La implementación activa del producto está en Flutter:

- `anshin_flutter/` app principal multiplataforma
- inicio de sesión con Google (Firebase Auth)
- OCR para tickets y carga de movimientos
- persistencia local de configuración, plantilla y movimientos
- modo claro / oscuro

## Estructura del repositorio

- `anshin_flutter/`: código de la app Flutter
- `anshin_flutter/docs/`: notas de versión, checklist de arquitectura y versionado
- `anshin_flutter/hooks/`: hooks de git para calidad (pre-commit / pre-push)

## Instalación rápida

1. Clona el repositorio.
2. Entra al proyecto Flutter:
   - `cd anshin_flutter`
3. Instala dependencias:
   - `flutter pub get`
4. Configura Firebase Android:
   - coloca `google-services.json` en `anshin_flutter/android/app/google-services.json`
5. Ejecuta en emulador o dispositivo:
   - `flutter run`

## Ejecución en Android Studio

1. Abre la carpeta `anshin_flutter` en Android Studio.
2. Espera el sync inicial.
3. Selecciona un emulador o teléfono por USB.
4. Ejecuta la configuración `main.dart` o `app`.

## Documentación adicional

- Guía de Google Sign-In: `anshin_flutter/GOOGLE_SIGNIN_SETUP.md`
- Resumen del proyecto: `anshin_flutter/PROJECT.md`
- Notas de versión: `anshin_flutter/docs/`
