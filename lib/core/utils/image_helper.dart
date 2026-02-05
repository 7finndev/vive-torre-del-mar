/// *****************************************************************************
/// CÓDIGO PARA OPTIMIZAR LA CARGA DE IMAGENES A SUPABASE.
/// COMPRIME LA IMAGEN.
library;

import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen y la comprime devolviendo BYTES (Uint8List)
  static Future<Uint8List?> pickAndCompress({
    required ImageSource source,
    int quality = 70,       // Calidad por defecto
    int maxWidth = 1024,    // Ancho máximo
    int maxHeight = 1024,   // Alto máximo
  }) async {
    try {
      // 1. Seleccionar del sistema
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(), // Pre-escalado nativo del picker
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,         // Compresión nativa del picker
      );
      
      if (file == null) return null;

      // 2. Leer como bytes
      final Uint8List bytes = await file.readAsBytes();

      // 3. Compresión extra (Opcional pero recomendada para asegurar JPG)
      // Esto asegura que si suben un PNG pesado, se convierta a JPG ligero
      try {
        final Uint8List result = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: maxHeight,
          minWidth: maxWidth,
          quality: quality,
          format: CompressFormat.jpeg, 
        );

        // 🔥 LOGS RESTAURADOS:
        final originalSize = bytes.lengthInBytes / 1024;
        final compressedSize = result.lengthInBytes / 1024;
        final savings = 100 - ((compressedSize / originalSize) * 100);

        print("--------------------------------------------------");
        print("📸 Imagen original: ${originalSize.toStringAsFixed(2)} KB");
        print("📉 Imagen optimizada: ${compressedSize.toStringAsFixed(2)} KB");
        print("💰 Ahorro: ${savings.toStringAsFixed(1)}%");
        print("--------------------------------------------------");

        return result;
      } catch (e) {
        // En algunos casos raros (o web antigua), si falla la compresión, devolvemos original
        print("⚠️ Falló la compresión avanzada, usando original: $e");
        return bytes; 
      }
    } catch (e) {
      print("Error en ImageHelper: $e");
      return null;
    }
  }
}