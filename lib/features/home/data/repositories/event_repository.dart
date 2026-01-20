import 'dart:typed_data'; // <--- IMPORTANTE: Para Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/event_model.dart';

part 'event_repository.g.dart';

class EventRepository {
  final SupabaseClient _client;

  EventRepository(this._client);

  // ==========================================================
  // 📸 NUEVO MÉTODO: SUBIR IMAGEN DE EVENTO
  // ==========================================================
  Future<String> uploadEventImage(String fileName, Uint8List fileBytes) async {
    try {
      final path = 'events/$fileName'; // Ej: events/cartel_2025.jpg

      // 1. Subir archivo
      await _client.storage.from('events').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Obtener URL PÚBLICA (Recuerda poner el bucket 'events' como Público en Supabase)
      return _client.storage.from('events').getPublicUrl(path);
    } catch (e) {
      print("⚠️ Error subiendo imagen evento: $e");
      throw Exception("Error subiendo imagen: $e");
    }
  }

  // ==========================================================
  // 📖 MÉTODOS DE LECTURA Y ESCRITURA
  // ==========================================================

  // --- READ: Obtener todos ---
  Future<List<EventModel>> getAllEvents() async {
    final response = await _client
        .from('events')
        .select()
        .order('start_date', ascending: false);

    return response.map((json) {
      try {
        return EventModel.fromJson(json);
      } catch (e) {
        print("💀 ERROR PARSEANDO EVENTO ID ${json['id']}: $e");
        rethrow;
      }
    }).toList();
  }

  // Obtener activo
  Future<EventModel?> getActiveEvent() async {
    final response = await _client
        .from('events')
        .select()
        .eq('status', 'active')
        .maybeSingle();

    return response != null ? EventModel.fromJson(response) : null;
  }

  // --- CREATE ---
  Future<void> createEvent(EventModel event) async {
    final data = event.toJson();
    data.remove('id'); 
    await _client.from('events').insert(data);
  }

  // --- UPDATE ---
  Future<void> updateEvent(EventModel event) async {
    final data = event.toJson();
    data.remove('id'); // No actualizamos ID
    await _client.from('events').update(data).eq('id', event.id);
  }

  // --- DELETE ---
  Future<void> deleteEvent(int id) async {
    await _client.from('events').delete().eq('id', id);
  }
}

@riverpod
EventRepository eventRepository(EventRepositoryRef ref) {
  return EventRepository(Supabase.instance.client);
}

@riverpod
Future<List<EventModel>> adminEventsList(AdminEventsListRef ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getAllEvents();
}