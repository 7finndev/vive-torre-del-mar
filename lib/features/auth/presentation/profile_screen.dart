import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <--- AÑADIR
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart'; // <--- AÑADIR

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controladores para el formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // Para alternar entre Login y Registro
  // Variables de estado para los datos del perfil
  String? _fullName;
  String? _phone;
  bool _isEditing = false;

  // Controladores para editar
  final _nameEditController = TextEditingController();
  final _phoneEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // CAMBIO CLAVE: Usamos .maybeSingle() en lugar de .single()
        // Esto devuelve 'null' si no encuentra el perfil, en vez de dar error.
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          setState(() {
            _fullName = data['full_name'];
            _phone = data['phone'];
            _nameEditController.text = _fullName ?? '';
            _phoneEditController.text = _phone ?? '';
          });
        } else {
          print("⚠️ El usuario no tiene perfil creado en la tabla pública.");
          // Opcional: Podríamos crearlo aquí automáticamente si quisiéramos
        }
      } catch (e) {
        print("Error cargando perfil: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({
          'full_name': _nameEditController.text,
          'phone': _phoneEditController.text,
        })
        .eq('id', user.id);

    await _loadProfile(); // Recargar
    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil actualizado ✅"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al usuario actual
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          // A. SI HAY USUARIO -> MOSTRAR PERFIL
          if (user != null) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // TARJETA DE SOCIO DIGITAL
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.email ?? "Usuario",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Participante Oficial",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const Divider(height: 40),

                          // CÓDIGO QR DEL USUARIO (Su ID)
                          QrImageView(
                            data:
                                user.id, // El contenido es su UUID de Supabase
                            version: QrVersions.auto,
                            size: 180.0,
                            foregroundColor: Colors.black87,
                          ),

                          const SizedBox(height: 20),

                          // SECCIÓN DE DATOS PERSONALES
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(
                                _isEditing ? Icons.save : Icons.edit,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                if (_isEditing) {
                                  _saveProfile();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                            ),
                          ),

                          _isEditing
                              ? Column(
                                  children: [
                                    TextField(
                                      controller: _nameEditController,
                                      decoration: const InputDecoration(
                                        labelText: "Nombre Completo",
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _phoneEditController,
                                      decoration: const InputDecoration(
                                        labelText: "Teléfono",
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(
                                      _fullName ?? "Sin nombre",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _phone ?? "Sin teléfono",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                          Text(
                            "Muestra este código para canjear premios",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // BOTONES DE ACCIÓN
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final count = await ref
                              .read(syncServiceProvider)
                              .syncPendingVotes();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Sincronizado: $count nuevos sellos subidos",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("Sincronizar Pasaporte"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón Vincular Físico (Placeholder)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Próximamente: Escanear Pasaporte Físico",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.link),
                        label: const Text("Vincular Pasaporte Físico"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    // BOTÓN CERRAR SESIÓN (CON LIMPIEZA)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          // 1. Cerrar sesión en la Nube (Supabase)
                          await ref.read(authRepositoryProvider).signOut();

                          // 2. BORRAR DATOS LOCALES (Hive)
                          // Importante: Borramos tanto los pendientes como los sincronizados
                          // para que el próximo usuario empiece limpio.
                          await Hive.box(
                            LocalDbService.syncedStampsBoxName,
                          ).clear();
                          await Hive.box(
                            LocalDbService.pendingVotesBoxName,
                          ).clear();

                          // 3. Notificar al usuario
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Sesión cerrada. Datos locales borrados.",
                                ),
                                backgroundColor: Colors.grey,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Cerrar Sesión"),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }

          // B. SI NO HAY USUARIO -> FORMULARIO DE LOGIN
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode ? "Iniciar Sesión" : "Crear Cuenta",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ... (El resto de tus TextFields y Botones sigue igual) ...
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: "Contraseña",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),

                    if (_isLoading) const CircularProgressIndicator(),

                    if (!_isLoading)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(_isLoginMode ? "Entrar" : "Registrarse"),
                        ),
                      ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode
                            ? "¿No tienes cuenta? Regístrate"
                            : "¿Ya tienes cuenta? Inicia Sesión",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authRepositoryProvider);

      if (_isLoginMode) {
        // --- MODO LOGIN ---
        await auth.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        await _loadProfile();
        // Si la línea de arriba no dio error, estamos dentro. Sincronizamos ya.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sesión iniciada. Recuperando tus sellos... ⏳"),
            ),
          );
          // Disparamos la sincronización (bajada y subida)
          await ref.read(syncServiceProvider).syncPendingVotes();
        }
        // Si no da error, Riverpod detectará el cambio de usuario y redibujará la pantalla sola.
      } else {
        // --- MODO REGISTRO ---
        await auth.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Cuenta creada! Iniciando sesión..."),
              backgroundColor: Colors.green,
            ),
          );

          // TRUCO: Intentamos iniciar sesión automáticamente tras el registro
          // (Supabase a veces lo hace solo, pero esto lo asegura si no hay confirmación de email)
          try {
            await auth.signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
          } catch (_) {
            // Si falla el autologin (ej: requiere confirmar email), cambiamos a modo login
            setState(() {
              _isLoginMode = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Mensaje de error amigable
        String message = "Error desconocido";
        if (e.toString().contains("Invalid login")) {
          message = "Email o contraseña incorrectos.";
        }
        if (e.toString().contains("already registered")) {
          message = "Este email ya está registrado.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
