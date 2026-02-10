# 🍷 Vive Torre del Mar

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green?style=for-the-badge&logo=supabase)
![Riverpod](https://img.shields.io/badge/State-Riverpod_2.0-purple?style=for-the-badge)
![Hive](https://img.shields.io/badge/Offline-Hive_NoSQL-orange?style=for-the-badge)

Una solución integral multiplataforma (Móvil + Web PWA) diseñada bajo una arquitectura **Offline-First** para la gestión y participación digital en eventos gastronómicos de la ACET, comenzando por la "Ruta de la Tapa" de Torre del Mar.

El proyecto digitaliza la experiencia tradicional del pasaporte físico, introduce mecanismos **anti-fraude** y permite la participación sin dependencia de internet continua.

---

## 📚 Documentación Completa

Para profundizar en el desarrollo, despliegue y uso, consulta la carpeta `/docs`:

* 📘 **[Documentación Técnica](docs/TECHNICAL_DOCUMENTATION.md):** Arquitectura, sincronización offline y estructura de código.
* 🚀 **[Guía de Despliegue](docs/02_Guia_Despliegue.md):** Configuración de entorno y subida a producción.
* 👨‍💼 **[Manual de Administración](docs/03_Manual_Administrador.md):** Gestión de eventos, pines de seguridad y recursos gráficos.
* 👁️ **[Visión y Alcance](docs/01_Vision_y_Alcance.md):** Objetivos del proyecto y actores.

---

## 📱 Funcionalidades Clave

### 👤 Aplicación de Usuario (Móvil & Web)
* **Offline-First Real:** Navegación, consulta de mapas y votaciones disponibles sin conexión a internet.
* **Sincronización Inteligente (`SyncService`):** Los votos realizados offline se guardan localmente y se suben a la nube automáticamente al recuperar la red.
* **Validación Anti-Fraude (Triple Capa):**
    1.  **Geo-fencing:** Validación GPS (<300m del local).
    2.  **QR Único:** UUID encriptado por establecimiento.
    3.  **PIN Camarero (Nuevo):** Código de respaldo de 4 dígitos para validación manual si falla la tecnología.
* **Pasaporte Digital:** Sellado virtual y control de progreso.
* **Noticias:** Feed integrado con `torredelmar.org` (con proxy CORS para Web).

### 🛠️ Panel de Administración (Web)
* **Gestión de Seguridad:** Visualización y regeneración de **PINs de Camarero** (manuales o aleatorios).
* **Analítica Híbrida:** Rastreo de usuarios registrados y dispositivos anónimos para métricas de conversión.
* **Gestión de Contenido:** CRUD de establecimientos, eventos y productos con compresión automática de imágenes.
* **Descargas:** Generación de cartelería QR lista para imprimir.

### ✨ Novedades Versión Actual (v1.1.2)

* **🔐 Recuperación de Contraseña:** Flujo completo vía Email con Deep Linking (Web y Móvil).
* **📸 Escáner para Administradores:** Herramienta interna para validar ganadores de sorteos mediante lectura de QR, con configuración de evento y umbral de votos.
* **🆔 Perfil 2.0:** Nueva interfaz responsiva (Escritorio/Móvil) con tarjeta de identidad digital y código QR ampliable para fácil lectura.
---

## 🏗️ Arquitectura Técnica

El proyecto sigue una arquitectura **Clean Architecture** modularizada por *Features*, utilizando **Riverpod** para la inyección de dependencias y gestión de estado.

### Estructura de Carpetas
```text
lib/
├── core/            # Motores: LocalDb (Hive), SyncService, Networking
├── features/        # Módulos de negocio
│   ├── auth/        # Autenticación
│   ├── admin/       # Panel de control y gestión de PINs
│   ├── home/        # Repositorios de datos y lógica offline
│   ├── scan/        # Lógica de Voto, GPS, Cámara y Sincronización
│   ├── hub/         # Noticias y Dashboard Usuario
│   └── map/         # Integración OpenStreetMap
└── main.dart        # Inicialización

```

### Tecnologías Clave

| Tecnología | Uso |
| --- | --- |
| **Flutter** | Framework UI para iOS, Android, Web y Desktop desde un solo código. |
| **Riverpod** | Gestión de estado reactiva y segura (Providers, AsyncValue). |
| **GoRouter** | Navegación declarativa avanzada (Rutas anidadas, Deep linking). |
| **Supabase** | Backend-as-a-Service (Auth, Database PostgreSQL, Storage, Realtime). |
| **Mobile Scanner** | Lectura nativa de códigos QR. |
| **Geolocator** | Verificación de latitud/longitud para evitar fraudes en votos. |
| **Hive** | Base de datos local para persistencia offline. |
| **Google Fonts** | Tipografías personalizadas (Ubuntu/Lato). |

---

## 🚀 Instalación y Despliegue

### Requisitos previos

* Flutter SDK instalado.
* Proyecto en Supabase configurado.
* Docker (Opcional, para pruebas de servidor web local).

### Configuración

1. Clonar el repositorio:
```bash
git clone [https://github.com/tu-usuario/torre-del-mar-app.git](https://github.com/tu-usuario/torre-del-mar-app.git)

```


2. Instalar dependencias:
```bash
flutter pub get

```


3. Configurar variables de entorno (crear archivo `.env` o configurar en `main.dart`):
```dart
const supabaseUrl = 'TU_URL_SUPABASE';
const supabaseKey = 'TU_KEY_SUPABASE';

```

4. Generación de Código (Importante): Al usar Riverpod Generator y Hive, es necesario ejecutar:
```Bash
    dart pub run build_runner build --delete-conflicting-outputs
```

5. Ejecutar la App:
* **Móvil:** `flutter run` (Seleccionar emulador/dispositivo).
* **Web:** `./build_web.sh (Script de producttión) o flutter run -d chrome` o `flutter run -d macos/windows`.


---

**Desarrollado con ❤️ para Torre del Mar.**


## 📱 Demo de la Aplicación

Haz clic en la imagen para ver el recorrido completo de la App "Vive Torre del Mar":

[![Ver Video Demo](https://img.youtube.com/vi/TU_ID_AQUI/maxresdefault.jpg)](https://youtu.be/ejg0LpLGWFc)

> **Duración:** 4 min | **Incluye:** Flujo de usuario, Votaciones y Panel de Administración.
