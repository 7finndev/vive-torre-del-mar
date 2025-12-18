import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart'; // NECESARIO
import 'package:go_router/go_router.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  // Recibo el ID del evento (puede ser nulo)
  final int? eventId;
  const ProfileScreen({super.key, this.eventId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  File? _selectedImage;
  bool _isLoading = false;
  bool _isEditing = false; // Para habilitar/deshabilitar edición

  @override
  void initState() {
    super.initState();
    // Inicializamos con datos vacíos, luego en el build se rellenan
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

  // Función para elegir foto
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 600, // Optimizamos tamaño
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isEditing = true; // Si cambia foto, activamos modo guardado
      });
    }
  }

  // Función para guardar
  Future<void> _saveProfile(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).updateProfile(
        userId: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: Colors.green),
        );
        setState(() => _isEditing = false); // Volvemos a modo lectura
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
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mi Perfil")),
        body: const Center(child: Text("No hay sesión activa")),
      );
    }

    // Rellenar datos iniciales si no se está editando
    if (!_isEditing && _nameController.text.isEmpty) {
      final meta = user.userMetadata;
      _emailController.text = user.email ?? '';
      _nameController.text = meta?['full_name'] ?? meta?['name'] ?? '';
      _phoneController.text = meta?['phone'] ?? '';
    }

    final String avatarUrl = user.userMetadata?['avatar_url'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.blue),
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
              // 1. AVATAR CON CÁMARA
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null) as ImageProvider?,
                        child: (_selectedImage == null && avatarUrl.isEmpty)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. CAMPOS DE TEXTO
              _buildTextField(
                label: "Nombre Completo",
                controller: _nameController,
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: "Teléfono",
                controller: _phoneController,
                icon: Icons.phone_outlined,
                enabled: _isEditing,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: "Correo Electrónico",
                controller: _emailController,
                icon: Icons.email_outlined,
                enabled: false, // El email no se suele cambiar así como así
                isReadOnly: true,
              ),

              const SizedBox(height: 30),

              // --- SECCIÓN PASAPORTE (SOLO SI HAY EVENTO) ---
              if (widget.eventId != null && !_isEditing) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[50], 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "GESTIÓN DE PASAPORTE",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 15),
                      
                      // BOTÓN SINCRONIZAR (CON FUNCIONALIDAD REAL)
                      OutlinedButton.icon(
                        onPressed: () async {
                          // 1. Feedback visual inmediato
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Sincronizando votos con la nube... ☁️")),
                          );
                          
                          try {
                            // 2. LLAMADA REAL A TU SERVICIO DE SINCRONIZACIÓN
                            // Usamos el eventId que recibimos en el perfil
                            await ref.read(syncServiceProvider).syncPendingVotes(
                              targetEventId: widget.eventId!,
                            );
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("¡Sincronización completada! ✅"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.sync, color: Colors.orange),
                        label: const Text("Sincronizar Votos", style: TextStyle(color: Colors.orange)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange.shade300),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Botón Vincular Físico
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push('/scan_physical_passport');
                        },
                        icon: const Icon(Icons.qr_code, color: Colors.brown),
                        label: const Text("Vincular Pasaporte Físico", style: TextStyle(color: Colors.brown)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.brown.shade300),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // MENOS ESPACIO AQUÍ (Para pegarlo al QR)
                const SizedBox(height: 30),
              ],
              
              // -----------------------------------------------------
              // 3. TARJETA DE IDENTIFICACIÓN (QR)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Text(
                      "TU QR",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue, 
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: QrImageView(
                        data: user.id, // El ID único de Supabase
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Muestra este código a la organización para identificarte o recoger premios.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // 4. BOTÓN CERRAR SESIÓN CON SEGURIDAD
              if (!_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    // AQUÍ EMPIEZA LA LÓGICA SEGURA
                    onPressed: () async {
                      final repo = ref.read(passportRepositoryProvider);
                      final authRepo = ref.read(authRepositoryProvider);

                      // A. ¿HAY DATOS PENDIENTES EN EL MÓVIL?
                      if (repo.hasPendingData) {
                        // Mostramos alerta
                        final bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("⚠️ Datos sin guardar"),
                            content: const Text(
                              "Tienes votos en el pasaporte que aún no se han subido a la nube.\n\n"
                              "Si cierras sesión ahora, se borrarán del móvil y los perderás.\n\n"
                              "¿Estás seguro de que quieres salir?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false), // Cancelar
                                child: const Text("CANCELAR"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), // Aceptar borrado
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text("PERDER DATOS Y SALIR"),
                              ),
                            ],
                          ),
                        );

                        // Si el usuario cancela o toca fuera, NO hacemos nada.
                        if (confirmDelete != true) return;
                      }

                      // B. SI NO HAY PENDIENTES O EL USUARIO ACEPTÓ BORRARLOS:
                      
                      // 1. Limpiamos la base de datos local (para que no los vea el siguiente usuario)
                      await repo.clearLocalData();
                      
                      // 2. Cerramos sesión en Supabase
                      await authRepo.signOut();
                      
                      // 3. Salimos de la pantalla de perfil
                      if (context.mounted) context.pop(); 
                    },
                    // FIN DE LA LÓGICA
                    
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    bool isReadOnly = false,
    TextInputType inputType = TextInputType.text,
  }) {
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}