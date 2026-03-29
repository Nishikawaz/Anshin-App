# Google Sign-In Setup (Android)

Este proyecto ya quedó preparado para iniciar sesión con Google.

## 1) Datos de esta app

- `applicationId`: `com.anshin.android`
- `SHA-1 (debug)`: `72:57:A2:FB:67:06:05:64:AE:9A:04:ED:15:75:39:12:8C:5D:58:FB`

## 2) Crear credenciales en Google/Firebase

Puedes hacerlo con Firebase o Google Cloud, pero necesitas:

1. Un cliente OAuth de **Android** con:
   - package: `com.anshin.android`
   - SHA-1: `72:57:A2:FB:67:06:05:64:AE:9A:04:ED:15:75:39:12:8C:5D:58:FB`
2. Un cliente OAuth de tipo **Web** (este ID se usa como `serverClientId`).

## 3) Pegar el Web Client ID en local.properties

Editar: `android/local.properties`

Agregar esta línea:

```properties
google.serverClientId=TU_WEB_CLIENT_ID.apps.googleusercontent.com
```

Ejemplo:

```properties
google.serverClientId=1234567890-abcxyzdefghijklmno.apps.googleusercontent.com
```

Con eso ya no hace falta pasar `--dart-define` para Android.

## 4) Ejecutar

```bash
flutter clean
flutter pub get
flutter run -d <android_device_id>
```

## 5) Opcional: google-services.json

Si usas Firebase, también puedes colocar `google-services.json` en:

`android/app/google-services.json`

Importante: tu `google-services.json` debe incluir un `oauth_client` de tipo web.
Si está vacío, activa Google Sign-In en Firebase Authentication y vuelve a descargarlo.
