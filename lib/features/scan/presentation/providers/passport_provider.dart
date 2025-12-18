import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/scan/data/models/passport_entry_model.dart';
// IMPORTANTE: Importar el auth provider
import 'package:torre_del_mar_app/features/auth/presentation/providers/auth_provider.dart';

part 'passport_provider.g.dart';

@riverpod
Future<List<PassportEntryModel>> passport(PassportRef ref, int eventId) async {
  // 1. VIGILANCIA: Hacemos que este provider dependa del usuario logueado.
  // Si el usuario cambia (login/logout), este provider se "autodestruye" y recarga.
  ref.watch(authStateProvider);

  final repository = ref.read(passportRepositoryProvider);
  
  // 2. Obtenemos los datos
  return repository.getPassportEntries(eventId);
}