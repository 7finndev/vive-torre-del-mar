import 'dart:io'; // Necesario para manejar el archivo de la foto
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  
  // Acceso directo al cliente para operaciones de Storage y Update
  final SupabaseClient _client = Supabase.instance.client;

  AuthRepository(this._authService);

  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email, password);
    } catch (e) {
      throw Exception('Error al registrarse: $e');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  User? get currentUser => _authService.currentUser;
  
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  // --- ACTUALIZAR PERFIL ---
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    File? imageFile,
  }) async {
    final updates = <String, dynamic>{};
    
    // 1. Preparamos los datos de texto
    if (name != null) {
      updates['full_name'] = name; 
      updates['name'] = name; // Guardamos en ambos por compatibilidad
    }
    if (phone != null) {
      updates['phone'] = phone;
    }

    // 2. Si hay imagen nueva, la subimos a Storage
    if (imageFile != null) {
      // Usamos siempre el nombre 'avatar' para sobreescribir la anterior y ahorrar espacio
      // Ojo: Hay que aseuúrarse de que el bucket 'avatars' exista en Supabase
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt'; 

      try {
        // Subimos la imagen (upsert: true permite sobreescribir)
        await _client.storage.from('avatars').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

        // Obtenemos la URL pública para guardarla en el perfil
        // NOTA: A veces Supabase tarda un segundo en refrescar la caché de la imagen pública
        final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);
        
        // Añadimos un timestamp al final para evitar problemas de caché en la app
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        updates['avatar_url'] = "$imageUrl?t=$timestamp";
        
      } catch (e) {
        throw 'Error subiendo imagen al servidor: $e';
      }
    }

    // 3. Actualizamos el usuario en Supabase Auth (Metadatos)
    if (updates.isNotEmpty) {
      final UserResponse res = await _client.auth.updateUser(
        UserAttributes(
          data: updates, 
        ),
      );
      
      if (res.user == null) {
        throw 'No se pudo actualizar el perfil en la base de datos';
      }
    }
  }
}