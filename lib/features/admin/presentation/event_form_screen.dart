import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torre_del_mar_app/core/utils/image_picker_widget.dart';
import 'package:torre_del_mar_app/features/home/data/models/event_model.dart';
import 'package:torre_del_mar_app/features/home/data/repositories/event_repository.dart';

const Map<String, String> _statusMap = {
  'upcoming': '🔜 Próximamente',
  'active': '🟢 Activo',
  'archived': '🔴 Finalizado',
};

class EventFormScreen extends ConsumerStatefulWidget {
  final EventModel? eventToEdit;
  const EventFormScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _themeColorController = TextEditingController(text: '#FF5733');
  final _navColorController = TextEditingController(text: '#FFFFFF');
  final _bgColorController = TextEditingController(text: '#F5F5F5');
  final _textColorController = TextEditingController(text: '#000000');
  final _fontFamilyController = TextEditingController(text: 'Roboto');
  
  // --- CONTROLADORES DE IMAGEN ---
  final _logoUrlController = TextEditingController(); 
  final _bgImageUrlController = TextEditingController(); // <--- NUEVO: Para el fondo

  final _priceController = TextEditingController(text: '0.0');

  String _selectedType = 'gastronomic';
  String _selectedStatus = 'upcoming';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _nameController.text = e.name;
      _themeColorController.text = e.themeColorHex;
      _priceController.text = e.basePrice?.toString() ?? '0.0';
      
      // CARGAMOS AMBAS IMÁGENES
      _logoUrlController.text = e.logoUrl ?? '';
      _bgImageUrlController.text = e.bgImageUrl ?? ''; // <--- CARGAMOS FONDO

      // Normalización de Estado
      String incomingStatus = e.status.toLowerCase().trim();
      if (_statusMap.containsKey(incomingStatus)) {
        _selectedStatus = incomingStatus;
      } else {
        if (incomingStatus.contains('prox')) {
          _selectedStatus = 'upcoming';
        } else if (incomingStatus == 'activo') _selectedStatus = 'active';
        else _selectedStatus = 'archived';
      }

      // Normalización de Tipo
      String incomingType = e.type;
      if (incomingType == 'drink') incomingType = 'drinks';
      if (incomingType == 'tapas') incomingType = 'gastronomic';
      const validTypes = ['gastronomic', 'drinks', 'shopping', 'menu'];
      _selectedType = validTypes.contains(incomingType) ? incomingType : 'gastronomic';

      _startDate = e.startDate;
      _endDate = e.endDate;
    }
  }

  String _generateSlug(String name) {
    return name.toLowerCase().trim().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit != null ? 'Personalizar Evento' : 'Nuevo Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // SECCIÓN 1: DATOS PRINCIPALES
              const Text('Información General', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Evento', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'gastronomic', child: Text('🥘 Tapas')),
                        DropdownMenuItem(value: 'menu', child: Text('🍽️ Menú Gastronómico')),
                        DropdownMenuItem(value: 'drinks', child: Text('🍹 Cócteles')),
                        DropdownMenuItem(value: 'shopping', child: Text('🛍️ Tiendas')),
                      ],
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusMap.containsKey(_selectedStatus) ? _selectedStatus : null,
                      decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                      items: _statusMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (val) { if (val != null) setState(() => _selectedStatus = val); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ==========================================
              // SECCIÓN IMÁGENES (CORREGIDA)
              // ==========================================
              const Text('Imágenes del Evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              
              // 1. SELECTOR DE LOGOTIPO
              const Text('Logotipo (Icono pequeño)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ImagePickerWidget(
                bucketName: 'events',
                initialUrl: _logoUrlController.text.isNotEmpty ? _logoUrlController.text : null,
                onImageUploaded: (url) {
                  setState(() => _logoUrlController.text = url);
                },
              ),
              if (_logoUrlController.text.isNotEmpty)
                 Padding(
                   padding: const EdgeInsets.only(top: 5, bottom: 20),
                   child: Text("✅ Logo cargado: ...${_logoUrlController.text.substring(_logoUrlController.text.length - 15)}", style: const TextStyle(fontSize: 10, color: Colors.green)),
                 ),

              const SizedBox(height: 20),

              // 2. SELECTOR DE FONDO (CARTEL) - ¡NUEVO!
              const Text('Imagen de Fondo / Cartel (Grande)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ImagePickerWidget(
                bucketName: 'events',
                initialUrl: _bgImageUrlController.text.isNotEmpty ? _bgImageUrlController.text : null,
                onImageUploaded: (url) {
                  setState(() => _bgImageUrlController.text = url); // Guardamos en el controller del fondo
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Fondo subido correctamente')));
                },
              ),
              // Preview del fondo
              if (_bgImageUrlController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    height: 150, // Más grande para ver bien el fondo
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(_bgImageUrlController.text),
                        fit: BoxFit.cover, // Para ver cómo queda de fondo
                      ),
                    ),
                  ),
                ),
              // ==========================================

              const SizedBox(height: 32),

              // SECCIÓN DISEÑO
              const Text('Diseño y Branding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _ColorInput(label: 'Color Principal (Tema)', controller: _themeColorController),
              const SizedBox(height: 10),
              _ColorInput(label: 'Color Fondo App', controller: _bgColorController),
              const SizedBox(height: 10),
              _ColorInput(label: 'Color Barra Navegación', controller: _navColorController),
              const SizedBox(height: 10),
              _ColorInput(label: 'Color de Texto', controller: _textColorController),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fontFamilyController,
                decoration: const InputDecoration(labelText: 'Tipografía', border: OutlineInputBorder(), prefixIcon: Icon(Icons.text_fields)),
              ),

              const SizedBox(height: 32),

              // SECCIÓN FECHAS
              const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Inicio: ${_formatDate(_startDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),
              ListTile(
                title: Text('Fin: ${_formatDate(_endDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(false),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isLoading ? 'Guardando...' : 'GUARDAR EVENTO'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper de Color
  Widget _ColorInput({required String label, required TextEditingController controller}) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _hexToColor(controller.text), border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
            onChanged: (val) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String code) {
    try {
      if (code.isEmpty) return Colors.transparent;
      String clean = code.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (e) { return Colors.white; }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final generatedSlug = _generateSlug(_nameController.text);
      final price = double.tryParse(_priceController.text) ?? 0.0;

      final newEvent = EventModel(
        id: widget.eventToEdit?.id ?? 0,
        name: _nameController.text,
        slug: generatedSlug,
        themeColorHex: _themeColorController.text,
        bgColorHex: _bgColorController.text,
        navColorHex: _navColorController.text,
        textColorHex: _textColorController.text,
        fontFamily: _fontFamilyController.text,
        type: _selectedType,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        basePrice: price,

        // --- CORRECCIÓN FINAL ---
        // Ahora guardamos CADA imagen en su sitio correcto
        logoUrl: _logoUrlController.text.isNotEmpty ? _logoUrlController.text : null,
        bgImageUrl: _bgImageUrlController.text.isNotEmpty ? _bgImageUrlController.text : null,
      );

      final repo = ref.read(eventRepositoryProvider);

      if (widget.eventToEdit == null) {
        await repo.createEvent(newEvent);
      } else {
        await repo.updateEvent(newEvent);
      }

      if (mounted) {
        ref.refresh(adminEventsListProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}