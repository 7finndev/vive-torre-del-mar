# 📘 Documentación Técnica - Vive Torre del Mar

**Versión:** 1.1.0
**Fecha:** Febrero 2026
**Tecnología:** Flutter v3.x / Supabase / Riverpod / Hive

---

## 1. Visión General del Sistema

"Vive Torre del Mar" es una aplicación multiplataforma (Web PWA y Android Nativo) diseñada para gestionar eventos turísticos y gastronómicos (Ruta de la Tapa). Su arquitectura prioriza la **disponibilidad Offline** y la integridad de los datos.

### Principios de Diseño
1.  **Offline-First:** La app permite consultar locales y **votar** sin conexión a internet, sincronizando cuando se recupera la red.
2.  **Hybrid Analytics:** Rastreo de dispositivos anónimos y registrados para toma de decisiones estratégicas.
3.  **Anti-Cheat (Anti-Trampas):** Sistema de triple validación: Coordenadas GPS, UUID en QR y PIN de respaldo manual.

---

## 2. Stack Tecnológico

| Capa | Tecnología | Descripción |
| :--- | :--- | :--- |
| **Frontend** | Flutter | Dart 3.x. Renderizado Web (HTML/CanvasKit) y Android. |
| **Estado** | Riverpod | Inyección de dependencias reactiva y segura. |
| **Backend** | Supabase | PostgreSQL, Auth, Storage y Edge Functions. |
| **Base Local** | Hive | Base de datos NoSQL clave-valor de alta velocidad. |
| **Mapas** | Flutter Map | Renderizado de OpenStreetMap (gratuito). |
| **Navegación** | GoRouter | Gestión de rutas profundas y URLs web. |

---

## 3. Arquitectura del Proyecto

El proyecto sigue una arquitectura **Feature-First** (modular por funcionalidad).

### Estructura de Carpetas (`lib/`)

* **`core/`**: Utilidades transversales.
    * `local_storage/`: Gestión de Hive (`LocalDbService`). Persistencia de UUID de dispositivo.
    * `network/`: Clientes HTTP y manejo de conectividad.
    * `utils/`: Helpers críticos (`ImageHelper` para compresión, `GeocodingHelper`).
* **`features/`**: Módulos de negocio.
    * **`admin/`**: Panel de control protegido. Gestión de Establecimientos, Eventos y **PINs de seguridad**.
    * **`auth/`**: Login, Registro y Perfil de usuario.
    * **`home/`**: Lógica pública. Repositorios de datos (`EstablishmentRepository`) y visualización de tapas/productos.
    * **`hub/`**: Dashboard principal. Incluye `NewsService` con parche CORS para Web.
    * **`map/`**: Lógica de GPS y navegación.
    * **`scan/`**: **Módulo Crítico**. Lógica de escáner QR, validación de votos y `SyncService` (sincronización diferida).

---

## 4. Estrategia de Datos & Sincronización

### 4.1. Lectura (Cache-Fallback)
1.  Intento de lectura desde Supabase.
2.  **Éxito:** Se guardan datos en Hive (`establishmentsBox`, `productsBox`) y se muestran.
3.  **Fallo/Offline:** Se recuperan datos de Hive. El usuario siempre ve contenido.

### 4.2. Escritura (Store-and-Forward)
1.  El usuario emite un voto (QR o PIN).
2.  El voto se guarda en `pending_votes_box` (Hive).
3.  `SyncService` intenta subirlo inmediatamente.
4.  Si no hay red, queda pendiente. Al recuperar conexión o reabrir la app, se procesa la cola de subida.

---

## 5. Seguridad y Validación de Voto

El sistema admite dos métodos de validación en el establecimiento:

### A. Método Principal (QR + GPS)
* **QR:** Debe contener un UUID que coincida con el `qr_uuid` del establecimiento en BD.
* **GPS:** La ubicación del usuario debe estar a menos de **300 metros** de las coordenadas del local.

### B. Método de Respaldo (PIN Camarero)
* Si falla el GPS o la cámara, el usuario puede introducir un **PIN de 4 dígitos**.
* Este PIN se valida contra el campo `waiter_pin` de la tabla `establishments`.
* *Gestión:* El administrador puede ver/editar/generar este PIN desde el panel de control.

---

## 6. Especificidades Web (PWA)

### 6.1. CORS (Noticias)
Para leer el JSON de WordPress (`torredelmar.org`) desde el navegador, se utiliza un proxy intermedio (`allorigins.win`) en `NewsService.dart` para evitar el bloqueo CORS.

### 6.2. Imágenes Externas
Las imágenes de noticias pasan por el proxy `wsrv.nl` para optimización y cabeceras correctas.

---

## 7. Despliegue y Mantenimiento

### Generación de Código


Tras modificar Modelos o Providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs

### Compilación Web

Script optimizado ./build_web.sh:
Bash

./build_web.sh

(Realiza limpieza, build con renderer html/canvaskit y versionado de caché).

## 8. Base de Datos (Supabase Schema)

Tablas Clave:

    establishments:

        id, name, coords...

        waiter_pin (text): Código de seguridad manual.

        qr_uuid (uuid): Código para el QR.

    votes: Registro de votaciones vinculadas a auth.users.

    analytics_devices: Registro de dispositivos para métricas anónimas.

    ***