import 'dart:typed_data'; // Para manejar los bytes de la imagen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart'; // Para generar nombres únicos

// IMPORTS PROPIOS
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/home/data/models/sponsor_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/sponsor_repository.dart';
import 'package:torre_del_mar_app/core/utils/image_helper.dart';

class AdminSponsorsScreen extends ConsumerStatefulWidget {
  const AdminSponsorsScreen({super.key});

  @override
  ConsumerState<AdminSponsorsScreen> createState() => _AdminSponsorsScreenState();
}

class _AdminSponsorsScreenState extends ConsumerState<AdminSponsorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================================================
  // 🗑️ BORRAR PATROCINADOR
  // ========================================================================
  Future<void> _deleteSponsor(SponsorModel sponsor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Borrar patrocinador?"),
        content: Text("Vas a eliminar a '${sponsor.name}'. También se borrará su logo del servidor."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Borrar"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(sponsorRepositoryProvider);

      // 1. Borrar imagen del Storage (Limpieza)
      await repo.deleteSponsorLogo(sponsor.logoUrl);

      // 2. Borrar registro de la Base de Datos
      await repo.deleteSponsor(sponsor.id);

      // 3. Refrescar lista
      ref.invalidate(sponsorsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Eliminado correctamente"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // ========================================================================
  // 📝 FORMULARIO (CREAR / EDITAR)
  // ========================================================================
  // --- FORMULARIO EN VENTANA (OPTIMIZADO CON COMPRESIÓN) ---
  void _showSponsorForm({SponsorModel? sponsor}) {
    final isEditing = sponsor != null;

    final nameCtrl = TextEditingController(text: isEditing ? sponsor.name : "");
    final urlCtrl = TextEditingController(text: isEditing ? sponsor.websiteUrl : "");
    final priorityCtrl = TextEditingController(text: isEditing ? sponsor.priority.toString() : "0");

    Uint8List? newLogoBytes;
    String currentUrl = isEditing ? sponsor.logoUrl : "";
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // 🔥 AQUÍ ESTÁ LA MAGIA DE LA COMPRESIÓN
            Future<void> pickImage() async {
              final bytes = await ImageHelper.pickAndCompress(
                source: ImageSource.gallery,
                maxWidth: 600, // Logos no necesitan ser gigantes
                maxHeight: 600, 
                quality: 85,   // Buena calidad pero comprimido
              );
              if (bytes != null) {
                setDialogState(() => newLogoBytes = bytes);
              }
            }

            Future<void> save() async {
              if (nameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre obligatorio")));
                return;
              }
              // Validar que hay imagen (nueva o vieja)
              if (newLogoBytes == null && currentUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta el logo")));
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                final repo = ref.read(sponsorRepositoryProvider);
                String finalUrl = currentUrl;

                // 1. SUBIDA DE IMAGEN (Si hay nueva)
                if (newLogoBytes != null) {
                  // Borrar la vieja si estamos editando para no dejar basura
                  if (isEditing && sponsor.logoUrl.isNotEmpty) {
                    await repo.deleteSponsorLogo(sponsor.logoUrl);
                  }
                  
                  // Nombre único para evitar caché del navegador
                  final fileName = 'logo_${const Uuid().v4()}.jpg';
                  finalUrl = await repo.uploadSponsorLogo(fileName, newLogoBytes!);
                }

                // 2. PREPARAR DATOS
                final data = {
                  'name': nameCtrl.text.trim(),
                  'logo_url': finalUrl,
                  'website_url': urlCtrl.text.isEmpty ? null : urlCtrl.text.trim(),
                  'priority': int.tryParse(priorityCtrl.text) ?? 0,
                  'is_active': true,
                };

                // 3. GUARDAR EN BD
                if (isEditing) {
                  await repo.updateSponsor(sponsor.id, data);
                } else {
                  await repo.createSponsor(data);
                }

                ref.invalidate(sponsorsListProvider);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? "Patrocinador actualizado ✅" : "Patrocinador creado ✅"),
                      backgroundColor: Colors.green,
                    )
                  );
                }

              } catch (e) {
                setDialogState(() => isLoading = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // CABECERA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? "Editar Patrocinador" : "Nuevo Patrocinador",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (!isLoading)
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const Divider(height: 20),

                      // CAMPO NOMBRE
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: "Nombre Empresa", border: OutlineInputBorder(), isDense: true),
                      ),
                      const SizedBox(height: 12),
                      
                      // CAMPO PRIORIDAD
                      TextField(
                        controller: priorityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Prioridad", 
                          helperText: "Mayor número sale antes",
                          border: OutlineInputBorder(), 
                          isDense: true
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ZONA DE IMAGEN (Con Wrap para móviles)
                      const Text("Logotipo:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            // Previsualización
                            Container(
                              width: 100, height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: newLogoBytes != null
                                    ? Image.memory(newLogoBytes!, fit: BoxFit.contain)
                                    : (currentUrl.isNotEmpty
                                        ? Image.network(currentUrl, fit: BoxFit.contain)
                                        : const Icon(Icons.image_not_supported, color: Colors.grey)),
                              ),
                            ),
                            
                            // Botón de Selección
                            ElevatedButton.icon(
                              onPressed: isLoading ? null : pickImage,
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text("Seleccionar Logo"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // CAMPO WEB
                      TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(
                          labelText: "Web Oficial (Opcional)", 
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(), 
                          isDense: true
                        ),
                      ),
                      const SizedBox(height: 24),

                      // BOTÓN GUARDAR
                      SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isLoading ? null : save,
                          child: Text(isLoading ? "GUARDANDO..." : "GUARDAR DATOS"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========================================================================
  // 🖥️ UI PRINCIPAL
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    // Escuchamos el proveedor (que ahora usa el Repositorio nuevo)
    final sponsorsAsync = ref.watch(sponsorsListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Gestión Patrocinadores"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSponsorForm(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuevo", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar empresa...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // LISTADO (GRID RESPONSIVE)
          Expanded(
            child: sponsorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text("Error cargando datos: $e")),
              data: (sponsors) {
                // Filtro local por buscador
                final filteredList = sponsors.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text("No hay patrocinadores"));
                }

                // LayoutBuilder para decidir columnas según ancho de pantalla
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Si es pantalla ancha (>900px), usamos más columnas
                    final isDesktop = constraints.maxWidth > 900;
                    final crossAxisCount = isDesktop ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Espacio abajo para el FAB
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 110, // Altura fija de tarjeta
                      ),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final sponsor = filteredList[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => _showSponsorForm(sponsor: sponsor),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // LOGO
                                  Container(
                                    width: 80, 
                                    height: 80,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.network(
                                      sponsor.logoUrl, 
                                      fit: BoxFit.contain,
                                      errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          sponsor.name, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "Prioridad: ${sponsor.priority}", 
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13)
                                        ),
                                        if (sponsor.websiteUrl != null && sponsor.websiteUrl!.isNotEmpty)
                                          Text(
                                            sponsor.websiteUrl!, 
                                            style: const TextStyle(color: Colors.blue, fontSize: 12),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),

                                  // BOTÓN BORRAR
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteSponsor(sponsor), // Pasamos el modelo entero
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}