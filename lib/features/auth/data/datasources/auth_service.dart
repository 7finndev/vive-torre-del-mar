import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  // Login con email y contraseña
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Registrarse (SignUp) 
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // Stream para escuchar cambios de sesión (Login/Logout)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
