import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/core/utils/image_picker_widget.dart'; // Asegúrate de tener este import

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(response);
          _filterList(_searchQuery); // Re-aplicar filtro si existía
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterList(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredUsers = _allUsers.where((user) {
        final email = (user['email'] ?? '').toString().toLowerCase();
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        return email.contains(_searchQuery) || name.contains(_searchQuery);
      }).toList();
    });
  }

  // --- LÓGICA DE ACTUALIZACIÓN DE ROL ---
  Future<void> _updateUserRole(String userId, String newRole, {String? newName, String? newAvatar}) async {
    try {
      final updates = {
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newName != null) updates['full_name'] = newName;
      if (newAvatar != null) updates['avatar_url'] = newAvatar;

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      await _loadAllUsers(); // 🔥 Recarga forzosa para confirmar que la DB cambió
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Usuario actualizado a: ${newRole.toUpperCase()}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Si falla (por ejemplo, por RLS), recargamos para deshacer el cambio visual falso
      await _loadAllUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar (Revisa permisos SQL): $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- DIÁLOGO DE EDICIÓN ---
  Future<void> _editUserDialog(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    String selectedRole = user['role'] ?? 'user';
    String currentAvatar = user['avatar_url'] ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Editar Usuario"),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AVATAR
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: ImagePickerWidget(
                      // 🔥 CORRECCIÓN: CAMBIADO DE 'logos' A 'avatars'
                      bucketName: 'avatars', 
                      initialUrl: currentAvatar,
                      height: 120,
                      onImageUploaded: (url) => setDialogState(() => currentAvatar = url),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: "Rol", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Usuario Estándar')),
                      DropdownMenuItem(value: 'manager', child: Text('Gestor')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateUserRole(user['id'], selectedRole, newName: nameCtrl.text, newAvatar: currentAvatar);
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  // --- BORRAR ---
  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Estás seguro?"),
        content: const Text("Se borrará el perfil de este usuario, pero sus votos se mantendrán para no alterar el concurso."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        //Comentamo esta linea por nueva estrategia
        //await Supabase.instance.client.from('profiles').delete().eq('id', id);
        // Nueva Estrategia (SOFT DELETE):
        await Supabase.instance.client.from('profiles').update({
          'is_active': false, //Lo marcamos como inactivo
          'deleted_at': DateTime.now().toIso8601String(), //Guardamos la fecha
        }).eq('id', id);
        await _loadAllUsers();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eliminado")));
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllUsers)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _filterList(""); }),
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
              onChanged: _filterList,
            ),
          ),
          // --- LISTA DE USUARIOS ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text("No se encontraron usuarios", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          
                          // DATOS
                          final String role = user['role'] ?? 'user';
                          final String name = user['full_name'] ?? 'Sin Nombre';
                          final String email = user['email'] ?? 'Sin Email';
                          
                          // AQUÍ RECUPERAMOS EL AVATAR DE LA BD
                          final String? avatarUrl = user['avatar_url']; 

                          // Lógica Visual de Roles
                          final bool isAdmin = role == 'admin';
                          final bool isManager = role == 'manager';
                          
                          // Comprobar si está activo (por defecto True si es null)
                          final bool isActive = user['is_active'] ?? true;

                          //Color color = isAdmin ? Colors.green : (isManager ? Colors.blue : Colors.grey);
                          //IconData icon = isAdmin ? Icons.admin_panel_settings : (isManager ? Icons.manage_accounts : Icons.person);

                          //Si esta inactivo, todo gris. Si no, colores normales.
                          Color color = !isActive
                            ? Colors.grey
                            : (isAdmin ? Colors.green : (isManager ? Colors.blue : Colors.grey));

                          IconData icon = !isActive
                            ? Icons.block //Icono de bloqueado
                            : (isAdmin ? Icons.admin_panel_settings : (isManager ? Icons.manage_accounts : Icons.person));
                          return Card(
                            elevation: isActive ? 2 : 0,
                            color: isActive ? Colors.white : Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isAdmin || isManager ? color : Colors.transparent, width: 1.5)
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () {
                                _editUserDialog(user);
                              },
                              // --- CORRECCIÓN: MOSTRAR AVATAR SI EXISTE ---
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: color.withOpacity(0.1),
                                // Si hay URL válida, la usamos como fondo
                                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                                    ? NetworkImage(avatarUrl) 
                                    : null,
                                // Si NO hay URL, mostramos el icono correspondiente
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Icon(icon, color: color)
                                    : null, // Si hay foto, no mostramos icono encima
                              ),
                              // ---------------------------------------------

                              title: Text(
                                name.isNotEmpty ? name : "Usuario", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? Colors.green.shade900 : Colors.black87)
                              ),
                              
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email, style: const TextStyle(fontSize: 12)),
                                  if(isAdmin || isManager)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                    )
                                ],
                              ),
                              
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                    onPressed: () => _editUserDialog(user),
                                    tooltip: "Editar / Avatar",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteUser(user['id']),
                                    tooltip: "Borrar",
                                  ),
                                  // Switch Rápido
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: isAdmin,
                                      activeThumbColor: Colors.green,
                                      onChanged: (val) {
                                        _updateUserRole(user['id'], val ? 'admin' : 'user');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}