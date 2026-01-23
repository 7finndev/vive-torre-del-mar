import 'dart:async';
import 'dart:io'; 
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _emailSent = false; 
  bool _isAdminMode = false; // Lógica Admin (NUEVA)
  bool _isPasswordVisible = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        // El usuario ha entrado. Aquí podrías redirigir si GoRouter no lo hace solo.
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

  // --- LÓGICA DE ENVÍO (Mantenemos la corrección de URL) ---
  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return _showError("Por favor, escribe tu email");

    setState(() => _isLoading = true);
    try {
      // OJO: Asegúrate de que esto coincide con tu AndroidManifest.xml
      // En tu snippet pusiste 'vivetorredelmar', antes era 'torredelmar'.
      // He puesto la de tu último código:
      String redirectUrl = kIsWeb 
          ? 'https://vive_torre_del_mar.7finn.es' 
          : 'io.supabase.vivetorredelmar://login-callback';

      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectUrl,
      );

      if (mounted) setState(() { _isLoading = false; _emailSent = true; });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return _showError("Rellena todos los campos");

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Aquí no hace falta cambiar estado manual, el auth listener lo detectará
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object e) {
    if (mounted) setState(() => _isLoading = false);
    String msg = "Error de conexión o envío.";
    if (e.toString().contains("Invalid login")) msg = "Credenciales incorrectas.";
    // Gestión bonita de errores de red
    final err = e.toString().toLowerCase();
    if (err.contains("socketexception") || err.contains("network")) {
       msg = "⚠️ Sin conexión a internet.";
    } else if (err.contains("rate limit")) {
       msg = "⏳ Has pedido muchos enlaces. Espera un poco.";
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
    return Scaffold(
      appBar: AppBar(title: const Text("Acceso")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  // --- VISTA FORMULARIO (LA NUEVA CON ADMIN - QUE SÍ TE GUSTABA) ---
  Widget _buildFormView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_isAdminMode ? Icons.admin_panel_settings : Icons.mark_email_unread_outlined, 
             size: 80, color: _isAdminMode ? Colors.blueGrey : Colors.orange),
        const SizedBox(height: 20),
        
        Text(
          _isAdminMode ? "Acceso Administrativo" : "Bienvenido a la Ruta",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        
        Text(
          _isAdminMode 
            ? "Introduce tus credenciales de gestor."
            : "Olvídate de las contraseñas.\nIntroduce tu email para entrar al instante.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Tu correo electrónico",
            hintText: "ejemplo@correo.com",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 20),

        if (_isAdminMode) ...[
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: "Contraseña",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_isAdminMode ? _loginWithPassword : _sendMagicLink),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAdminMode ? Colors.blueGrey : Colors.blue[900], // Azul para usuario (tu antiguo), Gris para Admin
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
            child: _isLoading 
              ? const SizedBox(
                  height: 20, width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
                  _isAdminMode ? "ENTRAR COMO ADMIN" : "ENVIAR ENLACE MÁGICO ✨",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ),

        const SizedBox(height: 20),

        TextButton(
          onPressed: () {
            setState(() {
              _isAdminMode = !_isAdminMode;
              _emailSent = false;
            });
          },
          child: Text(
            _isAdminMode 
              ? "¿Eres usuario? Entrar con enlace mágico" 
              : "¿Eres administrador? Entrar con contraseña",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // --- VISTA ÉXITO (LA ANTIGUA - RESTAURADA EL RECUADRO AZUL) ---
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "¡Correo Enviado!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        
        // AQUÍ ESTÁ EL CONTENEDOR AZUL QUE TE GUSTABA
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200)
          ),
          child: Column(
            children: [
              const Text("Hemos enviado un enlace de acceso a:", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 5),
              Text(
                _emailController.text,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        const Text(
          "👉 Abre tu aplicación de correo en este móvil y pulsa el enlace para entrar.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () => setState(() => _emailSent = false),
          icon: const Icon(Icons.arrow_back),
          label: const Text("Usar otro correo / Reintentar"),
        ),
        const SizedBox(height: 10),
        const Text("¿No llega? Revisa la carpeta Spam.", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}