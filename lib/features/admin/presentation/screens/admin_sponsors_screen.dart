import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // <--- NUEVO
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';
import 'package:torre_del_mar_app/features/home/data/models/sponsor_model.dart';

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

  // --- SUBIR IMAGEN (Lógica nueva) ---
  Future<String?> _uploadLogo() async {
    final ImagePicker picker = ImagePicker();
    // 1. Abrir Galería
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return null; // Usuario canceló

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subiendo imagen... ☁️"), duration: Duration(seconds: 1)),
        );
      }

      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'sponsors/$fileName'; // Carpeta sponsors dentro del bucket logos

      // 2. Subir a Supabase Storage (Bucket 'logos')
      await Supabase.instance.client.storage
          .from('logos')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      // 3. Obtener URL Pública
      final imageUrl = Supabase.instance.client.storage
          .from('logos')
          .getPublicUrl(filePath);

      return imageUrl;

    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error subiendo: $e")));
      }
      return null;
    }
  }

  Future<void> _deleteSponsor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Borrar patrocinador?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('sponsors').delete().eq('id', id);
      ref.invalidate(sponsorsListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eliminado correctamente")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSponsorForm({SponsorModel? sponsor}) {
    final isEditing = sponsor != null;
    
    final nameCtrl = TextEditingController(text: isEditing ? sponsor.name : "");
    final logoCtrl = TextEditingController(text: isEditing ? sponsor.logoUrl : "");
    final urlCtrl = TextEditingController(text: isEditing ? sponsor.websiteUrl : "");
    final priorityCtrl = TextEditingController(text: isEditing ? sponsor.priority.toString() : "0");

    // Variable local para actualizar la UI del BottomSheet al subir imagen
    // Usamos StatefulBuilder para poder hacer setState SOLO dentro del modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20, 
              left: 20, 
              right: 20, 
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? "Editar Patrocinador" : "Nuevo Patrocinador",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: 12),
                
                // --- CAMPO DE IMAGEN CON BOTÓN DE SUBIDA ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: logoCtrl,
                        decoration: const InputDecoration(
                          labelText: "URL Logo", 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          isDense: true,
                        ),
                        onChanged: (_) => setModalState((){}), // Refrescar vista previa al escribir manual
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () async {
                        final url = await _uploadLogo();
                        if (url != null) {
                          logoCtrl.text = url;
                          setModalState((){}); // Refrescar para ver la imagen cargada
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      tooltip: "Subir desde Galería",
                    ),
                  ],
                ),
                // VISTA PREVIA
                if (logoCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Image.network(
                        logoCtrl.text, 
                        fit: BoxFit.contain,
                        errorBuilder: (_,__,___) => const Center(child: Text("URL no válida o rota", style: TextStyle(color: Colors.red, fontSize: 10))),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: "Web Oficial", border: OutlineInputBorder(), prefixIcon: Icon(Icons.language)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priorityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Prioridad", border: OutlineInputBorder(), prefixIcon: Icon(Icons.sort)),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || logoCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre y Logo obligatorios")));
                      return;
                    }
                    Navigator.pop(ctx);
                    
                    final data = {
                      'name': nameCtrl.text,
                      'logo_url': logoCtrl.text,
                      'website_url': urlCtrl.text.isEmpty ? null : urlCtrl.text,
                      'priority': int.tryParse(priorityCtrl.text) ?? 0,
                      'is_active': true,
                    };

                    try {
                      if (isEditing) {
                        await Supabase.instance.client.from('sponsors').update(data).eq('id', sponsor.id);
                      } else {
                        await Supabase.instance.client.from('sponsors').insert(data);
                      }
                      ref.invalidate(sponsorsListProvider);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? "Actualizado" : "Creado")));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: Text(isEditing ? "GUARDAR CAMBIOS" : "CREAR PATROCINADOR"),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sponsorsAsync = ref.watch(sponsorsListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Gestionar Sponsors"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: () => _showSponsorForm(), backgroundColor: Colors.indigo, child: const Icon(Icons.add, color: Colors.white)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar patrocinador...", prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: sponsorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
              data: (sponsors) {
                final filteredList = sponsors.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();
                if (filteredList.isEmpty) return const Center(child: Text("No encontrado"));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sponsor = filteredList[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _showSponsorForm(sponsor: sponsor),
                        leading: Container(
                          width: 50, height: 50, padding: const EdgeInsets.all(4),
                          child: Image.network(sponsor.logoUrl, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                        ),
                        title: Text(sponsor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Prioridad: ${sponsor.priority}"),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteSponsor(sponsor.id)),
                      ),
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