import 'dart:async';
import 'package:flutter/material.dart';
// Mantener si usas dotenv
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/widgets/web_container.dart'; // Usamos WebContainer
import 'package:torre_del_mar_app/main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Variables para Magic Link (Conservadas por si acaso, pero sin uso visual actual)
  // bool _emailSent = false; 

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        // LÓGICA DE REDIRECCIÓN INTELIGENTE
        // Si veníamos forzados a admin, vamos al admin. Si no, al home.
        final uri = GoRouterState.of(context).uri;
        if (uri.queryParameters['admin'] == 'true') {
          context.go('/admin');
        } else {
          context.go('/');
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  // --- LÓGICA DE LOGIN CON CONTRASEÑA (ACTIVA) ---
  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      return _showError("Rellena todos los campos");
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // El listener de authState se encargará de redirigir
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _handleError(e);
    }
  }

  // --- LÓGICA MAGIC LINK (OCULTA / RESERVADA PARA FUTURO) ---
  /* Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return _showError("Por favor, escribe tu email");

    setState(() => _isLoading = true);
    try {
      String redirectUrl = kIsWeb 
          ? (dotenv.env['MAGIC_LINK_URL_WEB'] ?? 'https://vivetorredelmar.7finn.es')
          : (dotenv.env['MAGIC_LINK_URL_ANDROID'] ?? 'es.sietefinn.appvivetorredelmar://login-callback');

      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectUrl,
      );

      if (mounted) setState(() { _isLoading = false; _emailSent = true; });
    } catch (e) {
      _handleError(e);
    }
  }
  */

  void _handleError(Object e) {
    if (mounted) setState(() => _isLoading = false);
    String msg = "Error de conexión.";
    if (e.toString().contains("Invalid login")) msg = "Email o contraseña incorrectos.";
    
    // Gestión de errores de red
    final err = e.toString().toLowerCase();
    if (err.contains("socketexception") || err.contains("network")) {
       msg = "⚠️ Sin conexión a internet.";
    }
    _showError(msg);
  }

  void _showError(String msg) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebContainer(
      backgroundColor: Colors.grey[100],
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Iniciar Sesión"),
          centerTitle: true,
          // 🔥 AQUÍ ESTÁ LA FLECHITA QUE PEDÍAS
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: "Volver",
            onPressed: () {
              // Si puede volver atrás (pop), vuelve. Si no, va al Home ('/')
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  // --- VISTA FORMULARIO ---
  Widget _buildFormView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ICONO GENÉRICO
        const Icon(Icons.lock_person_outlined, size: 80, color: Colors.blueGrey),
        const SizedBox(height: 20),
        
        const Text(
          "Bienvenido",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        
        const Text(
          "Introduce tus credenciales para continuar.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        
        // CAMPO EMAIL
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Correo electrónico",
            hintText: "usuario@ejemplo.com",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),

        // CAMPO PASSWORD
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: "Contraseña",
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          onSubmitted: (_) => _loginWithPassword(),
        ),
        const SizedBox(height: 30),

        // BOTÓN ÚNICO DE ENTRADA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _loginWithPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading 
              ? const SizedBox(
                  height: 20, width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text(
                  "ENTRAR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ),

        const SizedBox(height: 20),

        // LINK DE OLVIDO CONTRASEÑA
        TextButton(
          onPressed: () {
            _showError("Contacta con administración si has olvidado tu clave.");
          },
          child: Text(
            "¿Olvidaste tu contraseña?",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // ENLACE AL REGISTRO
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("¿No tienes cuenta?"),
            TextButton(
              onPressed: () {
                // Navegamos a la pantalla de registro
                // Asegúrate de tener esta ruta '/register' en tu router.dart
                context.push('/register'); 
              },
              child: const Text(
                "Regístrate aquí",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.explore_outlined, color: Colors.grey),
          label: const Text(
            "Seguir como invitado",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ],
    );
  }
}