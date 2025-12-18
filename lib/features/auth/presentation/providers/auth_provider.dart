import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// 1. Proveedor del Servicio
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService(Supabase.instance.client);
}

// 2. Proveedor del Repositorio
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepository(service);
}

// 3. Proveedor del Usuario Actual (Stream)
// Esto permitirá que la UI reaccione automáticamente si el usuario entra o sale
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges.map((event) => event.session?.user);
}