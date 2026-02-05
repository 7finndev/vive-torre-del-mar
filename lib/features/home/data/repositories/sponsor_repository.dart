import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:torre_del_mar_app/features/home/data/models/sponsor_model.dart';
import 'package:torre_del_mar_app/core/local_storage/local_db_service.dart';

part 'sponsor_repository.g.dart';

class SponsorRepository {
  final SupabaseClient _client;
  final LocalDbService _localDb;

  SponsorRepository(this._client, this._localDb);

  // --- SUBIDA DE IMAGEN (OPTIMIZADA) ---
  Future<String> uploadSponsorLogo(String fileName, Uint8List imageBytes) async {
    try {
      final path = 'logos/$fileName'; 

      await _client.storage.from('logos').uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _client.storage.from('logos').getPublicUrl(path);
    } catch (e) {
      throw Exception("Error subiendo logo: $e");
    }
  }

  // --- BORRAR IMAGEN ---
  Future<void> deleteSponsorLogo(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      await _client.storage.from('logos').remove([fileName]);
    } catch (e) {
      print("⚠️ Error borrando logo antiguo: $e");
    }
  }

  // --- CRUD BÁSICO ---
  Future<List<SponsorModel>> getActiveSponsors() async {
    // Aquí podrías meter lógica de caché igual que en Eventos, 
    // pero de momento replicamos lo básico.
    final response = await _client
        .from('sponsors')
        .select()
        .eq('is_active', true)
        .order('priority', ascending: false);
    
    return (response as List).map((e) => SponsorModel.fromJson(e)).toList();
  }
  
  // Usado por Admin (trae activos e inactivos)
  Future<List<SponsorModel>> getAllSponsors() async {
    final response = await _client
        .from('sponsors')
        .select()
        .order('priority', ascending: false);
    
    return (response as List).map((e) => SponsorModel.fromJson(e)).toList();
  }

  Future<void> createSponsor(Map<String, dynamic> data) async {
    await _client.from('sponsors').insert(data);
  }

  Future<void> updateSponsor(int id, Map<String, dynamic> data) async {
    await _client.from('sponsors').update(data).eq('id', id);
  }

  Future<void> deleteSponsor(int id) async {
    await _client.from('sponsors').delete().eq('id', id);
  }
}

@riverpod
SponsorRepository sponsorRepository(SponsorRepositoryRef ref) {
  final db = ref.watch(localDbServiceProvider);
  return SponsorRepository(Supabase.instance.client, db);
}