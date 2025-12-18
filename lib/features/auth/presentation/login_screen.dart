import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:torre_del_mar_app/features/scan/presentation/providers/sync_provider.dart';
import 'dart:io'; // Para Platform
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/main.dart'; // Para hacer la consulta del perfil

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false; //Por defecto, oculta

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acceso")),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    
                    obscureText: !_isPasswordVisible, 

                    decoration: InputDecoration( // CORRECCIÓN: Quitamos 'const' aquí
                      labelText: "Contraseña",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      
                      // 3. AÑADIDO: Botón del ojo
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible 
                              ? Icons.visibility 
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
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
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authRepositoryProvider);

      // --- LOGICA PARA SABER SI ESTAMOS EN PLATAFORMA ADMIN ---
      // Si es Web O es (Linux/Windows/Mac), aplicamos seguridad estricta.
      // Si es móvil, dejamos pasar a cualquiera.
      bool isAdminPlatform = kIsWeb || (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

      if (_isLoginMode) {
        // --- LOGIN ---
        await auth.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // ✅ AQUI INYECTAMOS LA SEGURIDAD (Justo tras el login exitoso)
        if (isAdminPlatform) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            // Consultamos el rol en la tabla profiles
            final profileData = await Supabase.instance.client
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .maybeSingle();
            
            final role = profileData?['role'] ?? 'user'; // Si no tiene rol, asumimos 'user'

            if (role != 'admin') {
              // ⛔ NO ES ADMIN: Lo echamos
              await auth.signOut();
              throw Exception("ACCESS_DENIED_ADMIN"); // Lanzamos error para saltar al catch
            }
          }
        }
        // ✅ FIN DE LA SEGURIDAD
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sesión iniciada correctamente")),
          );
          ref.read(syncServiceProvider).syncPendingVotes();
        }

      } else {
        // --- REGISTRO ---
        await auth.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Cuenta creada!"),
              backgroundColor: Colors.green,
            ),
          );
          
          // Intentar autologin tras registro
          try {
             await auth.signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
            
            // ✅ SEGURIDAD TAMBIÉN EN REGISTRO (Si alguien se registra desde el panel admin)
            if (isAdminPlatform) {
               // Como acaba de registrarse, su rol por defecto en BBDD es 'user'.
               // Así que lo bloqueamos directamente sin consultar.
               await auth.signOut();
               throw Exception("ACCESS_DENIED_NEW_USER");
            }

          } catch (e) {
             // Si el autologin falla o es denegado
             if (e.toString().contains("ACCESS_DENIED")) rethrow; // Pasamos el error al catch principal
             
             setState(() => _isLoginMode = true);
          }
        }
      }
} catch (e) {
      // Ya no comprobamos 'if (mounted)' para el mensaje global, 
      // porque la llave global siempre está montada.
      
      String message = "Error desconocido";
      
      // Mensajes personalizados
      if (e.toString().contains("Invalid login")) message = "Credenciales incorrectas.";
      if (e.toString().contains("already registered")) message = "Email ya registrado.";
      
      if (e.toString().contains("ACCESS_DENIED_ADMIN")) {
        message = "⛔ Acceso Denegado: No tienes permisos de Administrador.";
      }
      if (e.toString().contains("ACCESS_DENIED_NEW_USER")) {
        message = "Cuenta creada, pero no tienes permisos de Administrador.";
      }
      
      // USAMOS LA LLAVE GLOBAL
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4), // Le damos tiempo para leer
        ),
      );
      
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}