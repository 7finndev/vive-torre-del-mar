#!/bin/bash
set -e

# Generamos un número de compilación basado en fecha corta (Ej: 2602021030 -> AñoMesDiaHoraMinuto)
# Usamos solo números para que no de problemas como build number
BUILD_NUMBER=$(date +%y%m%d%H%M)
FULL_VERSION=$(date +%Y%m%d_%H%M%S)

echo "🚀 [1/4] Limpiando proyecto..."
flutter clean
flutter pub get

echo "⚙️ [2/4] Generando código..."
dart run build_runner build --delete-conflicting-outputs

echo "🛠️ [3/4] Compilando Web (Versión automática: $BUILD_NUMBER)..."

# --- CAMBIO AQUÍ ---
# Añadimos --build-number=$BUILD_NUMBER
# Esto sobrescribe el "+2" del pubspec.yaml por la fecha actual solo para esta compilación

###Comento la siguiente linea para probar otra cosa en el navegador:
###flutter build web --release --pwa-strategy=none --build-number=$BUILD_NUMBER
###Y la siguiente linea es para probar si se realiza instalación desde navegador :
flutter build web --build-number=$BUILD_NUMBER

# Comprobación
if [ ! -f "build/web/index.html" ]; then
    echo "❌ ERROR: Falló la compilación."
    exit 1
fi

echo "🪄 [4/4] Aplicando sello de caché ($FULL_VERSION)..."
cd build/web

# Cache Busting (usamos la versión larga con segundos para asegurar unicidad en caché)
sed -i "s/flutter_bootstrap.js/flutter_bootstrap.js?v=$FULL_VERSION/g" index.html
sed -i "s/force_reload_PLACEHOLDER/force_reload_$FULL_VERSION/g" index.html

echo "✅ ¡COMPLETADO! Versión interna: $BUILD_NUMBER"
