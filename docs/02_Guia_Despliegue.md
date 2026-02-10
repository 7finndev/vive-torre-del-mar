# 02. Guía de Despliegue y Configuración

## 1. Requisitos Previos
* **Flutter SDK:** Versión 3.x (Canal Stable).
* **Docker:** Para levantar el servidor web local o contenedores de producción.
* **Supabase CLI:** (Opcional) Para gestión de base de datos.

## 2. Variables de Entorno (.env)
**IMPORTANTE:** Este archivo NUNCA debe subirse al repositorio. Debe crearse en la raíz del proyecto.

```env
# URL de tu proyecto Supabase
SUPABASE_URL=[https://tu-proyecto.supabase.co](https://tu-proyecto.supabase.co)

# Clave Pública (ANON KEY). 
# Si se regenera el JWT Secret, esta clave debe actualizarse aquí.
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6Ik...
```

## 3. Configuración de Servicios Externos

### A. Supabase Auth (Recuperación de Contraseña)
Para que el enlace de "Restablecer contraseña" funcione, debes configurar las **Redirect URLs** en tu panel de Supabase (*Authentication -> URL Configuration*):

* **Localhost:** `http://localhost:3000/update-password`
* **Producción Web:** `https://tu-dominio.com/update-password`
* **Móvil (Deep Link):** `es.sietefinn.appvivetorredelmar://login-callback/`

### B. Permisos de Cámara (Android/iOS)
El módulo de administración requiere acceso a la cámara.
* **Android:** Asegúrate de que `AndroidManifest.xml` incluye `<uses-permission android:name="android.permission.CAMERA" />`.
* **iOS:** El archivo `Info.plist` debe tener la clave `NSCameraUsageDescription`.

## 4. Comandos de Desarrollo
Generación de Código (Riverpod/Hive/Json)

Ejecutar cada vez que se modifique un Modelo o un Provider:
```Bash

flutter pub run build_runner build --delete-conflicting-outputs
```

Ejecución en Debug
```Bash

# Web
flutter run -d chrome --web-renderer html

# Móvil (Android)
flutter run -d <id_dispositivo>
```

## 5. Despliegue a Producción (Web)

Se utiliza el script automatizado ./build_web.sh que realiza:

    Limpieza de caché (flutter clean).

    Construcción optimizada (flutter build web --release).

    Web Renderer: html (para reducir tamaño de descarga) o canvaskit (para mejor rendimiento gráfico).

Comando:
```Bash

./build_web.sh
```

El resultado se generará en la carpeta build/web/, listo para subir a cualquier hosting estático o servidor Nginx.

---