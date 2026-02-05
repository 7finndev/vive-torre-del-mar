# 03. Manual de Administración

## Acceso al Panel
El panel de administración es accesible solo para usuarios con rol `admin` en la tabla `profiles` de Supabase. Se accede desde el menú lateral de la app -> "Panel de Control".

## 1. Gestión de Establecimientos (Socios)

### Crear/Editar un Socio
1.  Navegar a **Establecimientos**.
2.  Pulsar `+` para crear o tocar un elemento para editar.
3.  **Ubicación:** Usar el buscador de direcciones o tocar en el mapa para ajustar la chincheta exacta.
4.  **Imágenes:** Se puede subir una imagen desde la galería (se comprimirá automáticamente) o pegar una URL externa.

### 🔐 Seguridad y PIN Camarero
En la ficha de cada establecimiento hay una sección llamada **"Seguridad (Anti-Trampas)"**.
* **¿Qué es?** Es un código de 4 dígitos de respaldo. Si al cliente le falla el escáner QR o el GPS, el camarero puede decirle este número para validar el voto manualmente.
* **Generación:** Puedes escribir uno manual (ej: "1234") o pulsar el icono del **Dado (🎲)** para generar uno aleatorio automáticamente.
* **Nota:** Este código es visible solo por el administrador. El personal del bar debe ser informado verbalmente.

## 2. Gestión de Eventos
* Permite definir la fecha de inicio y fin.
* Los usuarios verán el evento como "Próximamente" o "Finalizado" automáticamente según estas fechas.

## 3. Visualización de Métricas
El Dashboard principal muestra:
* Resumen: Métricas Clave con total de escaneos QR, usuarios únicos (híbrido: registrados + anónimos), productos, socios. También muestra datos por Evento.
* Tecnología: Desglose por plataforma (iOS vs Android vs Web) de utilización de los usuarios.
* Oferta: Porcentajes de la Oferta (Tapas, Bebidas, Tienda).

## 4. Guía de Recursos Gráficos (Imágenes)

Para asegurar el rendimiento de la App (velocidad de carga) y una estética correcta, se recomienda seguir estas especificaciones al subir imágenes desde el Panel de Administración.

| Tipo de Recurso | Dimensiones Recomendadas (px) | Formato Ideal | Peso Máx. Sugerido | Uso en la App |
| :--- | :--- | :--- | :--- | :--- |
| **Foto Portada Establecimiento** | **1200 x 800** (Aspecto 3:2) | JPG / WebP | 300 KB | Ficha de detalle y tarjetas grandes en Web. |
| **Foto de Tapa/Producto** | **800 x 800** (Cuadrada 1:1) | JPG / WebP | 150 KB | Listado de tapas y detalle de producto. |
| **Logo de Patrocinador** | **500 x 500** (Fondo transparente) | PNG | 100 KB | Carrusel de patrocinadores (Footer). |
| **Avatar de Usuario** | **300 x 300** (Cuadrada) | JPG | 50 KB | Perfil de usuario y menú lateral. |
| **Banner de Evento** | **1200 x 600** (Aspecto 2:1) | JPG / WebP | 300 KB | Cabecera de la ficha del evento. |
| **Icono de Categoría/Ranking** | **128 x 128** | PNG / SVG | 20 KB | Iconos pequeños en listas. |

> **Nota:** La aplicación incluye un compresor automático (`ImageHelper`). Aunque subas una imagen de 5MB, el sistema intentará reducirla, pero siempre es mejor subirla optimizada de origen para ahorrar datos y tiempo de subida.