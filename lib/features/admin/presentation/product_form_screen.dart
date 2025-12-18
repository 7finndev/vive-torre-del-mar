import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart'; 
import 'package:torre_del_mar_app/core/utils/image_picker_widget.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/home/data/models/product_model.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/product_repository.dart';

// Lista constante de alérgenos comunes
const List<String> _commonAllergens = [
  'Gluten', 'Lácteos', 'Huevo', 'Frutos Secos', 'Marisco', 'Pescado', 'Soja',
  'Apio', 'Mostaza', 'Sulfitos', 'Altramuces', 'Moluscos', 'Otros',
];

final establishmentsListProvider =
    FutureProvider.autoDispose<List<EstablishmentModel>>((ref) async {
      return ref.read(establishmentRepositoryProvider).getAllEstablishments();
    });

class ProductFormScreen extends ConsumerStatefulWidget {
  final int initialEventId;
  final ProductModel? productToEdit;

  const ProductFormScreen({
    super.key,
    required this.initialEventId,
    this.productToEdit,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController(); 
  final _ingredientsController = TextEditingController();
  final _priceController = TextEditingController(text: '0.0');
  final _imageUrlController = TextEditingController();

  bool _useImageUpload = true;
  int? _selectedEstablishmentId;

  // Estado de los switches y alérgenos
  bool _isAvailable = true;
  bool _isWinner = false;
  List<String> _selectedAllergens = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _ingredientsController.text = p.ingredients ?? '';
      _priceController.text = p.price?.toString() ?? '0.0';
      _imageUrlController.text = p.imageUrl ?? '';
      _selectedEstablishmentId = p.establishmentId;

      _isAvailable = p.isAvailable;
      _isWinner = p.isWinner;
      _selectedAllergens = List.from(p.allergens ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final establishmentsAsync = ref.watch(establishmentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // 1. Selector de Establecimiento (AHORA CON BUSCADOR)
              establishmentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text('Error cargando locales'),
                data: (establishments) {
                  return DropdownSearch<EstablishmentModel>(
                    // --- CORRECCIÓN 1: 'items' ahora pide una función, no una lista ---
                    // Además, en la versión nueva hay que hacer el filtro manualmente aquí.
                    items: (filter, loadProps) {
                       // Si no escribe nada, devolvemos todos
                       if (filter.isEmpty) return establishments;
                       
                       // Si escribe, filtramos la lista por nombre
                       return establishments.where((element) => 
                           element.name.toLowerCase().contains(filter.toLowerCase())
                       ).toList();
                    },

                    // --- CORRECCIÓN 2: Comparador ---
                    // Ayuda a la librería a saber si dos objetos son el mismo (por ID)
                    compareFn: (item1, item2) => item1.id == item2.id,

                    // Qué texto mostrar en la lista
                    itemAsString: (EstablishmentModel u) => u.name,

                    // --- CORRECCIÓN 3: Cambio de nombre de parámetros de diseño ---
                    // Antes: dropdownDecoratorProps -> Ahora: decoratorProps
                    decoratorProps: const DropDownDecoratorProps(
                      // Antes: dropdownSearchDecoration -> Ahora: decoration
                      decoration: InputDecoration(
                        labelText: "Establecimiento / Local",
                        hintText: "Seleccione un local",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),

                    // Configuración del Popup (Buscador) - Esto se mantiene casi igual
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Escribe nombre del local...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                      menuProps: MenuProps(borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),

                    // Lógica al seleccionar
                    onChanged: (EstablishmentModel? data) {
                      if (data != null) {
                        setState(() => _selectedEstablishmentId = data.id);
                      }
                    },

                    // Valor inicial (Edición)
                    selectedItem: _selectedEstablishmentId != null
                        ? establishments.firstWhere(
                            (e) => e.id == _selectedEstablishmentId,
                            orElse: () => establishments.first)
                        : null,
                        
                    // Validación
                    validator: (item) {
                      if (_selectedEstablishmentId == null && item == null) return "Requerido";
                      return null;
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),

              // 2. Datos Básicos
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // PRECIO
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (€)',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 24),

              // --- SECCIÓN IMAGEN ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Foto del Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(
                        _useImageUpload ? "Subir Archivo" : "Enlace URL",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Switch(
                        value: _useImageUpload,
                        activeThumbColor: Colors.black,
                        onChanged: (val) => setState(() => _useImageUpload = val),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_useImageUpload)
                ImagePickerWidget(
                  bucketName: 'products',
                  initialUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
                  onImageUploaded: (url) {
                    setState(() => _imageUrlController.text = url);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Imagen lista")));
                  },
                )
              else
                Column(
                  children: [
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: "Pegar URL de la imagen",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        hintText: "https://...",
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    if (_imageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              
              const SizedBox(height: 16),

              // 3. Descripción e Ingredientes
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción Corta (Marketing)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredientes (Detallado)',
                  border: OutlineInputBorder(),
                  helperText: 'Lista separada por comas.',
                  prefixIcon: Icon(Icons.list),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // 4. ALÉRGENOS
              const Text('Alérgenos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _commonAllergens.map((allergen) {
                    final isSelected = _selectedAllergens.contains(allergen);
                    return FilterChip(
                      label: Text(allergen),
                      selected: isSelected,
                      selectedColor: Colors.orange.shade100,
                      checkmarkColor: Colors.orange,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedAllergens.add(allergen);
                          } else {
                            _selectedAllergens.remove(allergen);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 5. ESTADOS
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Disponible para el público'),
                      subtitle: Text(_isAvailable ? 'Visible en la app' : 'Oculto/Agotado'),
                      value: _isAvailable,
                      activeThumbColor: Colors.green,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('🏆 Marcar como Ganador'),
                      subtitle: const Text('Activa esto si ha ganado'),
                      value: _isWinner,
                      activeThumbColor: Colors.amber,
                      onChanged: (val) => setState(() => _isWinner = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // BOTÓN GUARDAR
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'GUARDAR PRODUCTO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _saveProduct,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validación manual del dropdown si falló la automática
    if (_selectedEstablishmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Falta seleccionar el establecimiento')));
      return;
    }

    if (_imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Debes subir una imagen o pegar una URL'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.tryParse(_priceController.text) ?? 0.0;

      final product = ProductModel(
        id: widget.productToEdit?.id ?? 0,
        eventId: widget.initialEventId,
        establishmentId: _selectedEstablishmentId!,
        name: _nameController.text,
        description: _descController.text,
        ingredients: _ingredientsController.text, // GUARDAMOS INGREDIENTES
        price: price,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        allergens: _selectedAllergens,
        isAvailable: _isAvailable,
        isWinner: _isWinner,
      );

      final repo = ref.read(productRepositoryProvider);
      if (widget.productToEdit == null) {
        await repo.createProduct(product);
      } else {
        await repo.updateProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Producto guardado correctamente"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}