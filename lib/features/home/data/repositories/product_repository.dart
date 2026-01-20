import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart'; // Importamos tu modelo existente

part 'product_repository.g.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  // 1. Subir Imagen al Storage
  Future<String> uploadProductImage(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final bucketName = 'products';
      final path = '$bucketName/$fileName';

      await _client.storage
          .from('products')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Obtener URL pública
      return _client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      print("⚠️ Error subiendo tapa: $e");
      throw Exception("Error subiendo imagen de producto");
    }
  }

  // 2. Crear Producto (SOPORTE PARA MENÚS)
  Future<void> createProduct(ProductModel product) async {
    // A. Guardamos el PADRE (El Menú/Tapa)
    final productMap = product.toJson();
    productMap.remove('id'); // Dejamos que la DB genere el ID
    // IMPORTANTE: Asegúrate de que tu modelo 'toJson' NO incluya la lista 'items' 
    // o bórrala aquí para que no falle al insertar en la tabla 'event_products'
    productMap.remove('items'); 
    productMap.remove('product_items'); 

    // Insertamos y PEDIMOS QUE NOS DEVUELVA EL ID GENERADO
    final response = await _client
        .from('event_products')
        .insert(productMap)
        .select()
        .single();
    
    final newProductId = response['id'] as int;

    // B. Guardamos los HIJOS (Los Platos), si existen
    if (product.items.isNotEmpty) {
      final itemsToInsert = product.items.map((item) {
        final json = item.toJson();
        json['product_id'] = newProductId; // Vinculamos con el padre
        return json;
      }).toList();

      await _client.from('product_items').insert(itemsToInsert);
    }
  }

  // 3. Obtener Productos por Evento (Lectura CON ITEMS)
  Future<List<ProductModel>> getProductsByEvent(int eventId) async {
    try {
      final response = await _client
          .from('event_products')
          // CAMBIO CLAVE: Pedimos todas las columnas (*) Y TAMBIÉN la tabla product_items
          .select('*, product_items(*)')
          .eq('event_id', eventId)
          .order('name', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error cargando productos: $e');
    }
  }

  // 4. Borrar Producto
  Future<void> deleteProduct(int productId) async {
    await _client.from('event_products').delete().eq('id', productId);
  }

  // 5. Actualizar Producto (SOPORTE PARA MENÚS)
  Future<void> updateProduct(ProductModel product) async {
    // A. Actualizamos el PADRE
    final map = product.toJson();
    map.remove('id');
    map.remove('items'); // Limpiamos para no ensuciar la query
    map.remove('product_items');

    await _client
        .from('event_products')
        .update(map)
        .eq('id', product.id);

    // B. Actualizamos los HIJOS (Estrategia: Borrar todo y re-insertar)
    // Es lo más sencillo para evitar lógica compleja de comparar qué plato cambió.
    if (product.items.isNotEmpty) {
      // 1. Borramos los platos viejos de este producto
      await _client.from('product_items').delete().eq('product_id', product.id);
      
      // 2. Insertamos los nuevos (que vienen del formulario)
      final itemsToInsert = product.items.map((item) {
        final json = item.toJson();
        json['product_id'] = product.id; // Mantenemos el ID del padre existente
        return json;
      }).toList();

      await _client.from('product_items').insert(itemsToInsert);
    } else {
      // Si la lista viene vacía, nos aseguramos de borrar lo que hubiera (por si pasó de Menú a Tapa)
      await _client.from('product_items').delete().eq('product_id', product.id);
    }
  }

  // Función para obtener TODOS los productos (CON ITEMS)
  Future<List<ProductModel>> getAllProducts() async {
    final response = await _client
        .from('event_products')
        .select('*, product_items(*)'); // <--- AÑADIR TAMBIÉN AQUÍ

    return response.map((json) => ProductModel.fromJson(json)).toList();
  }
}

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository(Supabase.instance.client);
}
