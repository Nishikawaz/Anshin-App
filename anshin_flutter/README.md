# Anshin Flutter

App de finanzas personales de Anshin construida con Flutter.

## Requisitos

- Flutter SDK instalado (`flutter --version`)
- Android Studio + Android SDK
- dispositivo físico (USB) o emulador Android
- cuenta Firebase configurada para Google Sign-In (Android)

## Configuración

1. Instalar dependencias:
   - `flutter pub get`
2. Crear/descargar `google-services.json` de Firebase.
3. Copiar archivo a:
   - `android/app/google-services.json`
4. (Opcional) instalar hooks de git:
   - PowerShell: `./hooks/setup-hooks.ps1`
   - Bash: `./hooks/setup-hooks.sh`

## Ejecutar

- `flutter run`

Si hay varios dispositivos:

- `flutter devices`
- `flutter run -d <device_id>`

## Build de release (Android)

- `flutter build apk --release`

## Documentación útil

- `GOOGLE_SIGNIN_SETUP.md`: pasos de Firebase y SHA
- `PROJECT.md`: alcance funcional actual
- `docs/`: changelog, release notes y checklist de arquitectura
