import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// 1. Proveedor del Repositorio
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(Supabase.instance.client);
}

// 2. Proveedor del Usuario Actual (Stream)
// Este provider nos dirá en tiempo real si hay usuario o no
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges.map((event) => event.session?.user);
}