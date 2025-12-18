import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// IMPORTS
import 'package:torre_del_mar_app/core/utils/image_picker_widget.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/establishment_repository.dart';

class EstablishmentFormScreen extends ConsumerStatefulWidget {
  final EstablishmentModel? establishmentToEdit;

  const EstablishmentFormScreen({super.key, this.establishmentToEdit});

  @override
  ConsumerState<EstablishmentFormScreen> createState() =>
      _EstablishmentFormScreenState();
}

class _EstablishmentFormScreenState
    extends ConsumerState<EstablishmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _webCtrl = TextEditingController();
  final _scheduleController = TextEditingController();
  final _imageController = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  // Estado de los switches
  bool _isPartner = true;
  bool _isActive = true;
  bool _useImageUpload = true; 

  @override
  void initState() {
    super.initState();
    // Si estamos editando, rellenamos los campos
    if (widget.establishmentToEdit != null) {
      final e = widget.establishmentToEdit!;
      _nameController.text = e.name;
      _addressController.text = e.address ?? '';
      _descController.text = e.description ?? '';
      _ownerController.text = e.ownerName ?? '';
      _phoneController.text = e.phone ?? '';
      _scheduleController.text = e.schedule ?? '';
      
      // CORRECCIÓN 1: Usar .text para asignar valores
      _webCtrl.text = e.website ?? '';
      _facebookCtrl.text = e.facebook ?? '';
      _instagramCtrl.text = e.instagram ?? '';
      _tiktokCtrl.text = e.socialTiktok ?? '';
      _imageController.text = e.coverImage ?? '';

      _isPartner = e.isPartner;
      _isActive = e.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.establishmentToEdit != null
              ? "Editar Socio"
              : "Alta de Nuevo Socio",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN 1: DATOS INTERNOS ---
              const Text(
                "Datos del Responsable (Interno)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: "Nombre del Propietario",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),

              // --- SECCIÓN 2: DATOS PÚBLICOS ---
              const Text(
                "Ficha del Establecimiento (Público)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre Comercial *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Dirección Completa",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // TELÉFONO (Solo, ya que web va abajo)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Teléfono Público",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),
              
              // --- SECCIÓN PRESENCIA DIGITAL ---
              const Text("Presencia Digital", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // 1. WEB
              TextFormField(
                controller: _webCtrl,
                decoration: const InputDecoration(
                  labelText: "Página Web", 
                  hintText: "https://tuhotel.com",
                  prefixIcon: Icon(Icons.language), 
                  border: OutlineInputBorder()
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),

              // 2. FACEBOOK E INSTAGRAM (En fila)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _facebookCtrl,
                      decoration: const InputDecoration(
                        labelText: "Facebook", 
                        prefixIcon: Icon(Icons.facebook), 
                        border: OutlineInputBorder()
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _instagramCtrl,
                      decoration: const InputDecoration(
                        labelText: "Instagram", 
                        prefixIcon: Icon(Icons.camera_alt), 
                        border: OutlineInputBorder()
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. TIKTOK
              TextFormField(
                controller: _tiktokCtrl,
                decoration: const InputDecoration(
                  labelText: "TikTok", 
                  prefixIcon: Icon(Icons.music_note), 
                  border: OutlineInputBorder()
                ),
              ),
              
              const SizedBox(height: 24),

              // --- HORARIO ---
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: "Horario Apertura",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  hintText: "Ej: L-D: 12:00 - 24:00",
                ),
              ),

              const SizedBox(height: 24),

              // --- SECCIÓN 3: IMAGEN (CON DOBLE OPCIÓN) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto de Portada / Fachada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // INTERRUPTOR
                  Row(
                    children: [
                      Text(
                        _useImageUpload ? "Subir Archivo" : "Enlace URL",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Switch(
                        value: _useImageUpload,
                        activeThumbColor: Colors.black, // Corregido activeThumbColor
                        onChanged: (val) {
                          setState(() {
                            _useImageUpload = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // LÓGICA DE VISUALIZACIÓN
              if (_useImageUpload)
                ImagePickerWidget(
                  bucketName: 'establishment',
                  initialUrl: _imageController.text.isNotEmpty
                      ? _imageController.text
                      : null,
                  onImageUploaded: (url) {
                    setState(() {
                      _imageController.text = url;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Imagen subida")),
                    );
                  },
                )
              else
                Column(
                  children: [
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: "Pegar URL de la imagen",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        hintText: "https://ejemplo.com/foto.jpg",
                      ),
                      onChanged: (val) =>
                          setState(() {}),
                    ),
                    if (_imageController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: Image.network(
                              _imageController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // --- SECCIÓN 4: ESTADO ---
              Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Es Socio de la ACET"),
                      subtitle: const Text("Aparece con distintivo de socio"),
                      value: _isPartner,
                      activeThumbColor: Colors.blue, // Corregido activeThumbColor
                      onChanged: (v) => setState(() => _isPartner = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("Local Activo"),
                      subtitle: const Text(
                        "Si se desactiva, no aparecerá en la app",
                      ),
                      value: _isActive,
                      activeThumbColor: Colors.green, // Corregido activeThumbColor
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_isLoading ? "GUARDANDO..." : "GUARDAR DATOS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final establishment = EstablishmentModel(
        id: widget.establishmentToEdit?.id ?? 0,
        name: _nameController.text,
        address: _addressController.text,
        description: _descController.text,

        ownerName: _ownerController.text,
        phone: _phoneController.text,

        website: _webCtrl.text.isNotEmpty ? _webCtrl.text : null,
        facebook: _facebookCtrl.text.isNotEmpty ? _facebookCtrl.text : null,
        instagram: _instagramCtrl.text.isNotEmpty ? _instagramCtrl.text : null,
        socialTiktok: _tiktokCtrl.text.isNotEmpty ? _tiktokCtrl.text : null,

        schedule: _scheduleController.text,

        coverImage: _imageController.text.isNotEmpty
            ? _imageController.text
            : null,

        isPartner: _isPartner,
        isActive: _isActive,

        // Generar UUID si es nuevo
        qrUuid: widget.establishmentToEdit?.qrUuid ?? const Uuid().v4(),

        latitude: widget.establishmentToEdit?.latitude,
        longitude: widget.establishmentToEdit?.longitude,
      );

      final repo = ref.read(establishmentRepositoryProvider);

      if (widget.establishmentToEdit == null) {
        await repo.createEstablishment(establishment);
      } else {
        await repo.updateEstablishment(establishment);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}