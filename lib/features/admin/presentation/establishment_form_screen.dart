import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EstablishmentFormScreen extends StatefulWidget {
  const EstablishmentFormScreen({super.key});

  @override
  State<EstablishmentFormScreen> createState() => _EstablishmentFormScreenState();
}

class _EstablishmentFormScreenState extends State<EstablishmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isPartner = true;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await Supabase.instance.client.from('establishments').insert({
        'name': _nameCtrl.text,
        'address': _addressCtrl.text,
        'owner_name': _ownerCtrl.text,
        'phone': _phoneCtrl.text, // Teléfono público
        'is_partner': _isPartner,
        'is_active': true,
        // Faltaría añadir el resto de campos del formulario PDF...
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Socio creado correctamente")));
        _nameCtrl.clear(); // Limpiar para el siguiente
        // No borramos todo para facilitar altas masivas
      }
    } catch (e) {
      // --- AÑADIR ESTO PARA VER EL ERROR EN LOS LOGS ---
      print("❌ ERROR CRÍTICO AL GUARDAR:");
      print(e.toString());
      
      if (e is PostgrestException) {
        print("📌 Código SQL: ${e.code}");
        print("📌 Detalle: ${e.details}");
        print("📌 Pista (Hint): ${e.hint}");
        print("📌 Mensaje: ${e.message}");
      }
      // -------------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"), // Convertir a string para asegurar que se ve algo
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Que dure más tiempo
          )
        );
      }      
      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alta de Nuevo Socio (Establecimiento)")),
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), // Para que no se estire en monitor grande
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Datos del Responsable", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextFormField(controller: _ownerCtrl, decoration: const InputDecoration(labelText: "Nombre y Apellidos", border: OutlineInputBorder())),
                
                const SizedBox(height: 20),
                const Text("Datos del Establecimiento (Públicos)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Nombre Comercial", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: "Dirección Completa", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Teléfono Reservas", border: OutlineInputBorder())),
                
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Es Socio de la ACET"),
                  value: _isPartner,
                  onChanged: (v) => setState(() => _isPartner = v),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _save, 
                    icon: const Icon(Icons.save), 
                    label: const Text("GUARDAR SOCIO"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}