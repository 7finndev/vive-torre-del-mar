import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Este provider nos dirá si el usuario actual es 'admin', 'user' o null (sin loguear)
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  
  // 1. Si no hay usuario logueado, devolvemos null
  if (user == null) return null;

  // 2. Si hay usuario, consultamos su rol en la tabla 'profiles'
  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    
    return data['role'] as String?;
  } catch (e) {
    // Si falla o no tiene perfil, asumimos que es usuario normal para no romper nada
    return 'user';
  }
});