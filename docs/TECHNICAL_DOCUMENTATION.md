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
```

### Compilación Web

Script optimizado ./build_web.sh:
```Bash

./build_web.sh
```

(Realiza limpieza, build con renderer html/canvaskit y versionado de caché).

## 8. Base de Datos (Supabase Schema)

Tablas Clave:

    establishments:

        id, name, coords...

        waiter_pin (text): Código de seguridad manual.

        qr_uuid (uuid): Código para el QR.

    votes: Registro de votaciones vinculadas a auth.users.

    analytics_devices: Registro de dispositivos para métricas anónimas.


# Anexo: Estructura del Código Fuente

El proyecto sigue una arquitectura modular (**Feature-First**). Cada funcionalidad principal tiene su propia carpeta en `features/`.

## 📂 Raíz (`lib/`)
* **`main.dart`**: Punto de entrada. Inicializa Supabase, Hive, Riverpod y arranca la app.

## 📂 Core (`lib/core/`)
*El motor transversal de la aplicación. Contiene lógica compartida por todas las features.*

* **`constants/`**:
    * `app_data.dart`: Textos fijos, opciones de configuración y claves estáticas.
* **`local_storage/`**:
    * `local_db_service.dart`: **CRÍTICO**. Gestiona Hive (base de datos local). Aquí se inicializan las "cajas" para guardar bares, votos y el UUID del dispositivo.
* **`network/`**:
    * `storage_service.dart`: Cliente para subir archivos a Supabase Storage (Buckets).
* **`router/`**:
    * `app_router.dart`: Configuración de **GoRouter**. Define todas las URLs y la navegación.
* **`utils/`**: Herramientas auxiliares.
    * `image_helper.dart`: Comprime imágenes antes de subirlas.
    * `geocoding_helper.dart`: Convierte direcciones de texto a coordenadas GPS (y viceversa).
    * `analytics_service.dart`: Registra eventos y dispositivos anónimos en Supabase.
* **`widgets/`**: Componentes visuales reutilizables.
    * `web_container.dart`: Limita el ancho en pantallas grandes (PC) para que la app no se "estire" demasiado.
    * `error_view.dart`: Pantalla estándar de "Algo salió mal".

## 📂 Features (`lib/features/`)
*Módulos de negocio.*

### 1. 🔐 Admin (`features/admin/`)
*Panel de control para gestores. Solo accesible con rol 'admin'.*
* **`presentation/`**: Pantallas (Screens).
    * `admin_dashboard_screen.dart`: Gráficas y resumen.
    * `admin_establishments_screen.dart`: Lista CRUD de bares.
    * `establishment_form_screen.dart`: Formulario de alta/edición (incluye mapa y PIN).
    * `admin_sponsors_screen.dart`: Gestión de patrocinadores.

### 2. 👤 Auth (`features/auth/`)
*Gestión de usuarios.*
* `auth_repository.dart`: Conecta con Supabase Auth (Login, Registro, Logout).
* `profile_screen.dart`: Pantalla de edición de usuario y avatar.

### 3. 🏠 Home (`features/home/`)
*Lógica principal pública (Bares, Tapas, Eventos).*
* **`data/models/`**: Definición de objetos (Establishment, Product, Event).
    * `establishment_model.dart`: Define la estructura del Bar (incluyendo `waiter_pin`).
* **`data/repositories/`**: Lógica de obtención de datos.
    * `establishment_repository.dart`: **CRÍTICO**. Decide si leer de Supabase (Online) o Hive (Offline).
* **`presentation/`**:
    * `home_screen.dart`: Pantalla principal con listados.
    * `establishment_detail_screen.dart`: Ficha del bar, botón de escáner y validación PIN.

### 4. 📰 Hub (`features/hub/`)
*Pantalla de bienvenida y noticias.*
* `news_service.dart`: Conecta con WordPress para bajar noticias (incluye parche CORS para Web).
* `hub_screen.dart`: Dashboard visual con carrusel de noticias y accesos directos.

### 5. 🗺️ Map (`features/map/`)
*Visualización geográfica.*
* `osm_service.dart`: Servicio de OpenStreetMap.
* `map_screen.dart`: Muestra los bares en el mapa interactivo.

### 6. 📸 Scan (`features/scan/`)
*El corazón de la interacción del usuario (Votos y Pasaporte).*
* **`data/repositories/`**:
    * `passport_repository.dart`: Gestiona los votos locales en Hive (`pending_votes`).
    * `sync_service.dart`: **CRÍTICO**. Se encarga de subir los votos pendientes cuando hay internet.
* **`presentation/`**:
    * `scan_qr_screen.dart`: Pantalla de cámara + Lógica de validación QR/GPS/PIN.
    * `passport_screen.dart`: Muestra los sellos conseguidos por el usuario.

## 📝 Notas sobre Archivos Generados (`.g.dart`)
Verás muchos archivos que terminan en `.g.dart` (ej: `establishment_model.g.dart`).
* **NO EDITAR MANUALMENTE.**
* Son generados automáticamente por `build_runner`.
* Contienen la lógica "aburrida" de convertir JSON a Objetos y adaptadores de Hive.
***