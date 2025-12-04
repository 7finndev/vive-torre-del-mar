import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/home/data/models/establishment_model.dart';

class AdminEstablishmentsScreen extends StatefulWidget {
  const AdminEstablishmentsScreen({super.key});

  @override
  State<AdminEstablishmentsScreen> createState() => _AdminEstablishmentsScreenState();
}

class _AdminEstablishmentsScreenState extends State<AdminEstablishmentsScreen> {
  List<EstablishmentModel> _establishments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('establishments')
          .select()
          .order('name'); // Orden alfabético
      
      final data = (response as List).map((e) => EstablishmentModel.fromJson(e)).toList();
      
      if (mounted) {
        setState(() {
          _establishments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error admin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestión de Socios (${_establishments.length})"),
        actions: [
          // BOTÓN REFRESCAR
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          const SizedBox(width: 20),
        ],
      ),
      
      // BOTÓN FLOTANTE PARA AÑADIR
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
           // Navegar al formulario (que ya creaste antes)
           // Esperamos resultado por si hay que recargar
           await context.push('/admin/socios/nuevo');
           _loadData(); 
        },
        label: const Text("NUEVO SOCIO"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columns: const [
                  DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Nombre Comercial", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Responsable", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Teléfono", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _establishments.map((bar) {
                  return DataRow(cells: [
                    DataCell(Text(bar.id.toString())),
                    DataCell(Text(bar.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(bar.ownerName ?? "-")),
                    DataCell(Text(bar.phone ?? "-")),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                             // TODO: Navegar a editar con los datos del bar
                             // context.push('/admin/socios/editar', extra: bar);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                             // TODO: Confirmar y borrar
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
    );
  }
}