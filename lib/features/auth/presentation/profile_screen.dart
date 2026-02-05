import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/core/widgets/responsive_center.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';
// IMPORTANTE: Asegúrate de importar tu helper
import 'package:torre_del_mar_app/core/utils/image_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? eventId;
  const ProfileScreen({super.key, this.eventId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // CAMBIO: Usamos bytes en memoria en vez de File
  Uint8List? _selectedImageBytes;
  
  bool _isLoading = false;
  bool _isEditing = false; 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // CAMBIO: Usamos el ImageHelper para comprimir y obtener bytes
  Future<void> _pickImage() async {
    final bytes = await ImageHelper.pickAndCompress(
      source: ImageSource.gallery,
      maxWidth: 500, // Avatar no necesita ser gigante
      maxHeight: 500,
      quality: 70,   // Buena compresión
    );

    if (bytes != null) {
      setState(() {
        _selectedImageBytes = bytes;
        _isEditing = true; 
      });
    }
  }

  Future<void> _saveProfile(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // CAMBIO: Enviamos bytes al repositorio
      await ref.read(authRepositoryProvider).updateProfile(
            userId: userId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            imageBytes: _selectedImageBytes, 
          );

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: Colors.green),
        );
        setState(() {
          _isEditing = false; 
          _selectedImageBytes = null; // Limpiamos selección local para que cargue la URL nueva
        }); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. OBTENCIÓN DE DATOS
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final profileAsync = ref.watch(userProfileProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mi Perfil")),
        body: const Center(child: Text("No hay sesión activa")),
      );
    }

    String currentName = '';
    String currentPhone = '';
    String currentEmail = user.email ?? '';
    String? remoteAvatarUrl;

    // Prioridad 1: Datos de Supabase (Actualizados)
    if (profileAsync.value != null) {
      final data = profileAsync.value!;
      currentName = data['full_name'] ?? '';
      currentPhone = data['phone'] ?? '';
      remoteAvatarUrl = data['avatar_url'];
      
      if (remoteAvatarUrl != null && remoteAvatarUrl.isNotEmpty) {
        remoteAvatarUrl = "$remoteAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      }
    } 
    // Prioridad 2: Metadatos de sesión (Fallback)
    else {
      final meta = user.userMetadata;
      currentName = meta?['full_name'] ?? meta?['name'] ?? '';
      currentPhone = meta?['phone'] ?? '';
      remoteAvatarUrl = meta?['avatar_url'];
    }

    if (!_isEditing) {
      _nameController.text = currentName;
      _phoneController.text = currentPhone;
      _emailController.text = currentEmail;
    }

    // 2. PREPARACIÓN DE LA IMAGEN (Lógica Híbrida: Memoria vs Red)
    ImageProvider? imageProvider;
    
    if (_selectedImageBytes != null) {
      // A. Si hay foto nueva en memoria -> MemoryImage
      imageProvider = MemoryImage(_selectedImageBytes!);
    } else if (remoteAvatarUrl != null && remoteAvatarUrl.isNotEmpty) {
      // B. Si no, mostramos la de internet -> NetworkImage
      imageProvider = NetworkImage(remoteAvatarUrl);
    }

    return ResponsiveCenter(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          actions: [
            if (_isEditing)
              IconButton(
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.check, color: Colors.blue),
                onPressed: _isLoading ? null : () => _saveProfile(user.id),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () => setState(() => _isEditing = true),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1. AVATAR
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: CircleAvatar(
                          radius: 60, // Hacemos el avatar un poco más grande en perfil
                          backgroundColor: Colors.grey[200],
                          backgroundImage: imageProvider,
                          onBackgroundImageError: imageProvider != null 
                              ? (exception, stackTrace) { print("Error avatar perfil: $exception"); }
                              : null,
                          child: imageProvider == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 2. CAMPOS DE TEXTO
                _buildTextField(label: "Nombre Completo", controller: _nameController, icon: Icons.person_outline, enabled: _isEditing),
                const SizedBox(height: 15),
                _buildTextField(label: "Teléfono", controller: _phoneController, icon: Icons.phone_outlined, enabled: _isEditing, inputType: TextInputType.phone),
                const SizedBox(height: 15),
                _buildTextField(label: "Correo Electrónico", controller: _emailController, icon: Icons.email_outlined, enabled: false, isReadOnly: true),

                const SizedBox(height: 30),

                // --- SECCIÓN PASAPORTE ---
                if (widget.eventId != null && !_isEditing) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
                    child: Column(
                      children: [
                        const Text("GESTIÓN DE PASAPORTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1.2)),
                        const SizedBox(height: 15),
                        OutlinedButton.icon(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sincronizando votos con la nube... ☁️")));
                            try {
                              await ref.read(syncServiceProvider).syncPendingVotes(targetEventId: widget.eventId!);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Sincronización completada! ✅"), backgroundColor: Colors.green));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                            }
                          },
                          icon: const Icon(Icons.sync, color: Colors.orange),
                          label: const Text("Sincronizar Votos", style: TextStyle(color: Colors.orange)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.orange.shade300), backgroundColor: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/scan_physical_passport'),
                          icon: const Icon(Icons.qr_code, color: Colors.brown),
                          label: const Text("Vincular Pasaporte Físico", style: TextStyle(color: Colors.brown)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.brown.shade300), backgroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // 3. TARJETA QR
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
                  child: Column(
                    children: [
                      const Text("TU QR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: QrImageView(data: user.id, version: QrVersions.auto, size: 160.0, backgroundColor: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text("Muestra este código a la organización para identificarte o recoger premios.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. BOTÓN CERRAR SESIÓN
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final repo = ref.read(passportRepositoryProvider);
                        final authRepo = ref.read(authRepositoryProvider);

                        if (repo.hasPendingData) {
                          final bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("⚠️ Datos sin guardar"),
                              content: const Text("Tienes votos pendientes. Si sales, se perderán.\n¿Seguro que quieres salir?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
                                TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("SALIR")),
                              ],
                            ),
                          );
                          if (confirmDelete != true) return;
                        }
                        await repo.clearLocalData();
                        await authRepo.signOut();
                        if (context.mounted) context.pop();
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.red)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, bool enabled = true, bool isReadOnly = false, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: inputType,
      style: TextStyle(color: isReadOnly ? Colors.grey[600] : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: !enabled || isReadOnly,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }
}