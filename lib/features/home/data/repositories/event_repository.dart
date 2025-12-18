import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/event_model.dart';

part 'event_repository.g.dart';

class EventRepository {
  final SupabaseClient _client;

  EventRepository(this._client);

  // --- READ: Obtener todos (Admin Dashboard) ---
  Future<List<EventModel>> getAllEvents() async {
    final response = await _client
        .from('events')
        .select()
        .order('start_date', ascending: false); // Los más nuevos primero

    //return response.map((json) => EventModel.fromJson(json)).toList();

    return response.map((json) {
      try {
        return EventModel.fromJson(json);
      } catch (e) {
        // ESTO TE DIRÁ QUÉ FILA Y QUÉ ERROR EXACTO ES
        print("💀 ERROR PARSEANDO EVENTO ID ${json['id']}:");
        print("Datos recibidos: $json");
        print("Error: $e");
        rethrow; // Vuelve a lanzar el error para que la app se pare
      }
    }).toList();
  }

  // Actualización
  Future<EventModel?> getActiveEvent() async {
    final response = await _client
        .from('events')
        .select()
        .eq('status', 'active') // Usamos el string 'active'
        .maybeSingle();

    return response != null ? EventModel.fromJson(response) : null;
  }

  // --- CREATE ---
  Future<void> createEvent(EventModel event) async {
    final data = event.toJson();
    data.remove('id'); // Dejamos que Supabase genere el ID
    await _client.from('events').insert(data);
  }

  // --- UPDATE ---
  Future<void> updateEvent(EventModel event) async {
    await _client.from('events').update(event.toJson()).eq('id', event.id);
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

// Este provider nos da la lista actualizada de eventos siempre que lo pidamos
@riverpod
Future<List<EventModel>> adminEventsList(AdminEventsListRef ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getAllEvents();
}
