import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart'; // Importamos tu modelo existente

part 'product_repository.g.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  // 1. Subir Imagen al Storage
  Future<String> uploadProductImage(String fileName, Uint8List fileBytes) async {
    final path = 'products/$fileName';
    
    // Asegúrate de tener un bucket llamado 'products' en Supabase Storage
    await _client.storage.from('products').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Obtener URL pública
    return _client.storage.from('products').getPublicUrl(path);
  }

  // 2. Crear Producto en Base de Datos
  Future<void> createProduct(ProductModel product) async {
    // 1.-Convertimos el modelo a Mapa JSON
    final productMap = product.toJson();

    // 2.-Importante: Eliminamos el 'id' del mapa.
    // Como en Dart el Id es obligatorio, le pasamos '0' temporalmente,
    // pero a Supabase no debemos enviarle 'id': 0, debemos enviar 'null' o nada
    // para que la base de datos genere el siguiente número (auto increment).
    productMap.remove('id');

    // 3.-Insertamos
    await _client.from('event_products').insert(productMap);
  }

  // 3. Obtener Productos por Evento (Lectura)
  Future<List<ProductModel>> getProductsByEvent(int eventId) async {
    try {
      final response = await _client
          .from('event_products')
          .select()
          .eq('event_id', eventId) // FILTRO CLAVE
          .order('name', ascending: true); // Orden alfabético

      // Mapeamos la lista de JSON a objetos ProductModel
      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      // Es buena práctica lanzar una excepción limpia o loguear
      throw Exception('Error cargando productos: $e');
    }
  }

  // 4. Borrar Producto
  Future<void> deleteProduct(int productId) async {
    await _client.from('event_products').delete().eq('id', productId);
  }

  // 5. Actualizar Producto Existente
  Future<void> updateProduct(ProductModel product) async {
    // Convertimos el objeto a Mapa JSON
    final map = product.toJson();
    
    // IMPORTANTE: Quitamos el ID del mapa de datos a enviar.
    // No queremos modificar el ID (clave primaria), solo usarlo para saber QUÉ fila actualizar.
    map.remove('id');

    // Ejecutamos el Update en Supabase
    await _client
        .from('event_products') // Asegúrate de que tu tabla se llama así
        .update(map)
        .eq('id', product.id); // Cláusula WHERE id = product.id
  }

  // --- AÑADE ESTO DENTRO DE ProductRepository ---
  
  // Función para obtener TODOS los productos (sin filtrar por evento)
  // Útil para el panel de administración
  Future<List<ProductModel>> getAllProducts() async {
    final response = await _client
        .from('event_products')
        .select(); // Sin filtros, tráelo todo

    return response.map((json) => ProductModel.fromJson(json)).toList();
  }
}

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository(Supabase.instance.client);
}