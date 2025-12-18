import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/product_repository.dart';

part 'product_form_controller.g.dart';

@riverpod
class ProductFormController extends _$ProductFormController {
  @override
  FutureOr<void> build() {}

  Future<bool> submitProduct({
    required int eventId,
    required int establishmentId,
    required String name,
    required String description,
    required double price,
    required List<String> allergens,
    required String fileName,
    required Uint8List imageBytes,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(productRepositoryProvider);

      // 1. Subir foto
      final imageUrl = await repo.uploadProductImage(fileName, imageBytes);

      // 2. Crear modelo (Usando tu ProductModel existente)
      final newProduct = ProductModel(
        id: 0, // Ponemos 0 para cumplir con requisitos de Dart. El repositorio lo borrará.
        eventId: eventId,
        establishmentId: establishmentId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        price: price,
        allergens: allergens,
        isWinner: false,
        isAvailable: true,
      );

      // 3. Guardar en BD
      await repo.createProduct(newProduct);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}