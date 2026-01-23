# 🍷 Vive Torre del Mar

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green?style=for-the-badge&logo=supabase)
![Riverpod](https://img.shields.io/badge/State-Riverpod_2.0-purple?style=for-the-badge)

Una solución integral multiplataforma (Móvil + Web/Desktop) para la gestión y participación digital en el evento gastronómico "Ruta de la Tapa" de Torre del Mar así como otros eventos.
El proyecto se ha diseñado con propósito multi eventos, para gestionar distintos eventos ("Ruta de la Tapa", "Ruta del Coctel", "Ruta Gastronómica", "Sorteos", etc).

El proyecto digitaliza la experiencia tradicional del "Pasaporte de Tapas", permitiendo votaciones en tiempo real, validación de visitas mediante QR geolocalizado y un panel administrativo robusto.

---

## 📱 Funcionalidades

### 👤 Aplicación de Usuario (Móvil)
Diseñada para los asistentes al evento.
* **Pasaporte Digital:** Sellado virtual de visitas.
* **Escáner QR Inteligente:** Valida la visita cruzando el código UUID del local con la ubicación GPS del usuario (Geo-fencing).
* **Votaciones:** Valoración de tapas (0-5 estrellas) sincronizadas en tiempo real.
* **Mapa Interactivo:** Visualización de establecimientos participantes con marcadores personalizados.
* **Modo Offline:** Sincronización automática de votos cuando se recupera la conexión.

### 🛠️ Panel de Administración (Web / Desktop)
Herramienta de gestión para la ACET (Asociación de Comerciantes).
* **Dashboard:** Métricas clave en tiempo real.
* **Gestión de Socios:** CRUD completo de establecimientos con logos e información de contacto interna.
* **Generador de QR:** Creación automática y descarga de carteles QR únicos para cada establecimiento.
* **Gestión de Productos:** Asignación de tapas/cócteles a cada local.
* **Seguridad:** Acceso restringido basado en roles (Row Level Security).

---

## 🏗️ Arquitectura Técnica

El proyecto sigue una **Clean Architecture** basada en "Features" (Funcionalidades), asegurando que el código sea escalable, testeable y fácil de mantener.

### Estructura de Carpetas
```text
lib/
├── core/            # Utilidades compartidas, Router, Tema, Constantes
├── features/        # Módulos funcionales
│   ├── auth/        # Login y Gestión de Perfil
│   ├── admin/       # Lógica del Panel Administrativo
│   ├── home/        # Listados, Detalle de Tapas, Mapa
│   ├── scan/        # Lógica de Cámara, QR y Geolocalización
│   └── hub/         # Shell de navegación principal
└── main.dart        # Punto de entrada

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


4. Ejecutar la App:
* **Móvil:** `flutter run` (Seleccionar emulador/dispositivo).
* **Admin:** `flutter run -d chrome` o `flutter run -d macos/windows`.



---

## 🔮 Futuro del Proyecto

El sistema está diseñado de forma **desacoplada**. Actualmente utiliza Supabase para una iteración rápida.

---

**Desarrollado con ❤️ para Torre del Mar.**


## 📱 Demo de la Aplicación

Haz clic en la imagen para ver el recorrido completo de la App "Vive Torre del Mar":

[![Ver Video Demo](https://img.youtube.com/vi/TU_ID_AQUI/maxresdefault.jpg)](https://youtu.be/ejg0LpLGWFc)

> **Duración:** 4 min | **Incluye:** Flujo de usuario, Votaciones y Panel de Administración.
