# 01. Visión y Alcance - Vive Torre del Mar

## 1. Resumen Ejecutivo
El proyecto tiene como objetivo la transformación digital de la "Ruta de la Tapa" y otros eventos comerciales organizados por la **ACET** (Asociación de Comerciantes y Empresarios de Torre del Mar). Se busca sustituir el pasaporte físico de papel por una solución móvil moderna, ecológica y resistente a fraudes.

## 2. Actores del Sistema
* **Usuario Final (Visitante/Local):** Participa en el evento, visita bares, escanea QRs para "visar" su pasaporte digital y vota sus tapas favoritas.
* **Establecimiento (Socio):** Ofrece el producto. Necesita validar que el cliente está físicamente allí.
* **Administrador (ACET):** Gestiona el alta/baja de locales, monitoriza la participación en tiempo real y extrae datos para premios.

## 3. Requisitos Funcionales Clave
* **Votación Digital:** Sistema de 0 a 5 estrellas.
* **Geolocalización:** Mapa interactivo para encontrar locales participantes.
* **Pasaporte Virtual:** Visualización del progreso (sellos conseguidos).
* **Validación de Presencia:** Mecanismos para asegurar que el usuario está en el bar (QR + GPS + PIN).
* **Noticias:** Feed de actualidad conectado a `torredelmar.org`.

## 4. Requisitos No Funcionales
* **Disponibilidad Offline:** La app debe permitir votar y consultar el mapa sin conexión a internet (crítico para zonas con mala cobertura o saturación de red).
* **Sincronización Diferida:** Los datos guardados offline se suben automáticamente al recuperar conexión.
* **Privacidad:** Uso de identificadores anónimos para analítica sin violar RGPD.