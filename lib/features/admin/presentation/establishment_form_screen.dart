import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/establishment_repository.dart';
// IMPORTAMOS EL NUEVO HELPER
import 'package:torre_del_mar_app/core/utils/geocoding_helper.dart';

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
  bool _isGeocoding = false; // Para el spinner del botón GPS

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

  // NUEVOS CONTROLADORES GPS
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final MapController _mapController = MapController(); // <--- NUEVO
  
  bool _isPartner = true;
  bool _isActive = true;
  bool _useImageUpload = true;

  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.establishmentToEdit != null) {
      final e = widget.establishmentToEdit!;
      _nameController.text = e.name;
      _addressController.text = e.address ?? '';
      _descController.text = e.description ?? '';
      _ownerController.text = e.ownerName ?? '';
      _phoneController.text = e.phone ?? '';
      _scheduleController.text = e.schedule ?? '';
      _webCtrl.text = e.website ?? '';
      _facebookCtrl.text = e.facebook ?? '';
      _instagramCtrl.text = e.instagram ?? '';
      _tiktokCtrl.text = e.socialTiktok ?? '';
      _imageController.text = e.coverImage ?? '';
      _isPartner = e.isPartner;
      _isActive = e.isActive;

      // CARGAR GPS SI EXISTE
      if (e.latitude != null) _latController.text = e.latitude.toString();
      if (e.longitude != null) _lngController.text = e.longitude.toString();
    }
  }

  // FUNCIÓN PARA BUSCAR GPS AUTOMÁTICO
  Future<void> _findCoordinates() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escribe una dirección primero")));
      return;
    }

    setState(() => _isGeocoding = true);

    final coords = await GeocodingHelper.getCoordinatesFromAddress(_addressController.text);

    if (mounted) {
      setState(() => _isGeocoding = false);
      
      if (coords != null) {
        final lat = coords[0];
        final lng = coords[1];

        _latController.text = lat.toString();
        _lngController.text = lng.toString();
        
        // 🚀 MOVEMOS EL MAPA AL NUEVO PUNTO
        _mapController.move(LatLng(lat, lng), 17.0);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📍 ¡Ubicación encontrada!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ No encontrada. Intenta simplificar la dirección.")));
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.establishmentToEdit != null ? "Editar Socio" : "Nuevo Socio",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre Comercial *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),

              // --- SECCIÓN DIRECCIÓN Y GPS ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: "Dirección",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 58, // Altura para igualar al input
                      child: ElevatedButton(
                        onPressed: _isGeocoding ? null : _findCoordinates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade900,
                          padding: EdgeInsets.zero,
                        ),
                        child: _isGeocoding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_outlined),
                                  Text(
                                    "Buscar GPS",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // COORDENADAS MANUALES
              // ... (Después del botón buscar GPS y las casillas de texto lat/long) ...

              const SizedBox(height: 10),
              // COORDENADAS MANUALES
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Latitud", hintText: "36.7...", isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _lngController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Longitud", hintText: "-4.1...", isDense: true, border: OutlineInputBorder()))),
                ],
              ),
              
              const SizedBox(height: 10),

              // ========================================================
              // 🗺️ MAPA INTERACTIVO (OPENSTREETMAP)
              // ========================================================
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Centro inicial: Torre del Mar (o la latitud guardada)
                      initialCenter: _latController.text.isNotEmpty 
                          ? LatLng(double.parse(_latController.text), double.parse(_lngController.text))
                          : const LatLng(36.741, -4.093), 
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        // AL TOCAR EL MAPA, ACTUALIZAMOS LAS CASILLAS
                        setState(() {
                          _latController.text = point.latitude.toStringAsFixed(6);
                          _lngController.text = point.longitude.toStringAsFixed(6);
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.torredelmar.admin',
                      ),
                      // MARCADOR QUE SIGUE AL CLIC
                      MarkerLayer(
                        markers: [
                          if (_latController.text.isNotEmpty && _lngController.text.isNotEmpty)
                            Marker(
                              point: LatLng(
                                double.tryParse(_latController.text) ?? 36.74, 
                                double.tryParse(_lngController.text) ?? -4.09
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text("👆 Toca en el mapa para ajustar la posición exacta", style: TextStyle(fontSize: 12, color: Colors.grey)),
              // ========================================================

              // -----------------------------
              const SizedBox(height: 15),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: "Nombre Propietario",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto de Portada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _useImageUpload,
                    onChanged: (v) => setState(() => _useImageUpload = v),
                  ),
                ],
              ),

              if (_useImageUpload)
                Column(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      // LÓGICA MEJORADA DE IMAGEN
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (_imageController.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _imageController.text,
                                      fit: BoxFit.cover,
                                      // ESTO EVITA QUE LA APP PETE SI LA IMAGEN FALLA
                                      errorBuilder: (context, error, stackTrace) {
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(height: 5),
                                            const Text(
                                              "No se puede cargar la imagen externa",
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            TextButton(
                                              onPressed: () {},
                                              child: const Text(
                                                "(Sube una nueva)",
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  )),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Seleccionar Imagen"),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: "URL Manual",
                    border: OutlineInputBorder(),
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
      final repo = ref.read(establishmentRepositoryProvider);
      String? finalImageUrl = _imageController.text.isNotEmpty
          ? _imageController.text
          : null;

      if (_useImageUpload && _selectedImageBytes != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        finalImageUrl = await repo.uploadEstablishmentImage(
          fileName,
          _selectedImageBytes!,
        );
      }

      // CONVERSIÓN DE COORDENADAS
      // Reemplazamos coma por punto por si el teclado está en español
      double? lat;
      double? lng;
      if (_latController.text.isNotEmpty) {
        lat = double.tryParse(_latController.text.replaceAll(',', '.'));
      }
      if (_lngController.text.isNotEmpty) {
        lng = double.tryParse(_lngController.text.replaceAll(',', '.'));
      }

      final establishment = EstablishmentModel(
        id: widget.establishmentToEdit?.id ?? 0,
        name: _nameController.text,
        address: _addressController.text,
        description: _descController.text,
        ownerName: _ownerController.text,
        phone: _phoneController.text,
        website: _webCtrl.text,
        schedule: _scheduleController.text,
        coverImage: finalImageUrl,
        isPartner: _isPartner,
        isActive: _isActive,
        qrUuid: widget.establishmentToEdit?.qrUuid ?? const Uuid().v4(),
        // AQUI METEMOS LAS COORDENADAS NUEVAS
        latitude: lat,
        longitude: lng,
        // -----------------------------------
      );

      if (widget.establishmentToEdit == null) {
        await repo.createEstablishment(establishment);
      } else {
        await repo.updateEstablishment(establishment);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Guardado correctamente")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
