// Archivo: lib/core/utils/image_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart'; // <--- NUEVO IMPORT

class ImagePickerWidget extends StatefulWidget {
  final String? initialUrl;
  final String bucketName;
  final Function(String newUrl) onImageUploaded;

  const ImagePickerWidget({
    super.key,
    this.initialUrl,
    required this.bucketName,
    required this.onImageUploaded,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _imageFile;
  bool _isUploading = false;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.initialUrl;
  }

  // Si la URL externa cambia (ej: pegamos una URL en el modo texto), actualizamos
  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != oldWidget.initialUrl) {
      setState(() {
        _previewUrl = widget.initialUrl;
      });
    }
  }

Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    // Bajamos un poco la calidad para que suba rápido (opcional)
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _isUploading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // --- CORRECCIÓN PARA WEB ---
      // Usamos .name en vez de .path para sacar la extensión correctamente
      final fileExt = picked.name.split('.').last; 
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName; // O 'productos/$fileName' si quieres carpetas

      // Intentamos obtener el mimeType. 
      // XFile en web a veces ya lo trae. Si no, lo buscamos por el nombre.
      String mimeType = picked.mimeType ?? lookupMimeType(picked.name) ?? 'image/$fileExt';
      // ---------------------------

      // 2. Subida a Supabase
      // NOTA: En Web, File(picked.path) a veces da problemas al subir directamente.
      // Es más seguro leer los bytes si estamos en web, o dejar que supabase_flutter lo maneje.
      // Para un código universal simple:
      final bytes = await picked.readAsBytes(); // Esto funciona en Web y Móvil

      await supabase.storage.from(widget.bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType, 
        ),
      );

      // 3. Obtener URL Pública
      final publicUrl = supabase.storage.from(widget.bucketName).getPublicUrl(filePath);

      setState(() {
        _previewUrl = publicUrl;
        _isUploading = false;
      });

      widget.onImageUploaded(publicUrl);

    } catch (e) {
      print("Error subiendo: $e"); // Log para ti
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUpload,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              // Si tenemos imagen local, la mostramos. Si no, la URL de red.
              image: _imageFile != null
                  ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                  : (_previewUrl != null && _previewUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(_previewUrl!), 
                          fit: BoxFit.cover,
                          onError: (e,s) => const Icon(Icons.broken_image), // Evita crash si la URL es mala
                        )
                      : null,
            ),
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : (_imageFile == null && (_previewUrl == null || _previewUrl!.isEmpty))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blueGrey[300]),
                          const SizedBox(height: 8),
                          Text("Toca para subir imagen", style: TextStyle(color: Colors.blueGrey[400])),
                        ],
                      )
                    : null,
          ),
        ),
        if (_previewUrl != null || _imageFile != null)
          TextButton.icon(
            onPressed: _pickAndUpload, 
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("Cambiar imagen")
          ),
      ],
    );
  }
}