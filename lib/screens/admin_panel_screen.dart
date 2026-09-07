import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import 'shop_settings_screen.dart';

// ============================================================
// ADMIN PANEL PRINCIPAL (avec BottomNavigationBar amélioré)
// ============================================================
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;
  final storage = const FlutterSecureStorage();

  static const List<Widget> _tabs = [
    DashboardTab(),
    MenuManagementTab(),
    ClientsTab(),
    ProfileTab(),
    ShopSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.coffee, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Administration',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ],
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await storage.deleteAll();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.brown[800],
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Boutique'),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ONGLET 1 : DASHBOARD
// ============================================================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalOrders = 0;
  int _totalRevenue = 0;
  int _pendingOrders = 0;

  static String get _apiUrl => '${AppConfig.apiBaseUrl}/admin/orders';
  static String _statusUrl(int orderId) =>
      '${AppConfig.apiBaseUrl}/admin/orders/$orderId/status';

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token manquant. Veuillez vous reconnecter.';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final orders = (data['data'] as List).map((order) {
            final parsedOrder = Map<String, dynamic>.from(order);
            try {
              final total = order['total'];
              parsedOrder['total'] = (total is String)
                  ? double.parse(total).toInt()
                  : (total as num).toInt();
            } catch (e) {
              parsedOrder['total'] = 0;
            }
            return parsedOrder;
          }).toList();

          if (mounted) {
            setState(() {
              _orders = orders;
              _totalOrders = orders.length;
              _totalRevenue = orders.fold(
                0,
                (sum, order) => sum + (order['total'] as int),
              );
              _pendingOrders = orders
                  .where((o) => o['status'] == 'en_attente')
                  .length;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = data['error'] ?? 'Erreur de chargement';
              _isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 401) {
        await storage.deleteAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expirée, reconnectez-vous')),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de contacter le serveur.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.put(
        Uri.parse(_statusUrl(orderId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );
      if (response.statusCode == 200) {
        _fetchOrders();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Statut #$orderId mis à jour')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'en_attente':
        color = Colors.orange;
        break;
      case 'en_preparation':
        color = Colors.blue;
        break;
      case 'termine':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.brown[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune commande pour le moment',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total commandes',
                  value: '$_totalOrders',
                  icon: Icons.receipt_long,
                  color: Colors.blue[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Chiffre d\'affaires',
                  value: '$_totalRevenue FCFA',
                  icon: Icons.attach_money,
                  color: Colors.green[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'En attente',
                  value: '$_pendingOrders',
                  icon: Icons.pending,
                  color: Colors.orange[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Terminées',
                  value: '${_totalOrders - _pendingOrders}',
                  icon: Icons.check_circle,
                  color: Colors.green[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Dernières commandes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length > 5 ? 5 : _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.brown[100],
                    child: Text(
                      '#${order['id']}',
                      style: TextStyle(
                        color: Colors.brown[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          order['customer_name'] ?? 'Anonyme',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      _buildStatusChip(order['status'] ?? 'en_attente'),
                    ],
                  ),
                  subtitle: Text(
                    '${_formatDate(DateTime.parse(order['created_at']))} • ${order['total']} FCFA',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (newStatus) =>
                        _updateStatus(order['id'], newStatus),
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'en_attente',
                        child: Text('En attente'),
                      ),
                      const PopupMenuItem(
                        value: 'en_preparation',
                        child: Text('En préparation'),
                      ),
                      const PopupMenuItem(
                        value: 'termine',
                        child: Text('Terminé'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONGLET 2 : GESTION DU MENU (CORRIGÉ)
// ============================================================
class MenuManagementTab extends StatefulWidget {
  const MenuManagementTab({super.key});

  @override
  State<MenuManagementTab> createState() => _MenuManagementTabState();
}

class _MenuManagementTabState extends State<MenuManagementTab> {
  List<dynamic> _menuItems = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  static String get _baseUrl => AppConfig.apiBaseUrl;
  final String _getMenuUrl = '$_baseUrl/menu';
  final String _adminMenuUrl = '$_baseUrl/admin/menu';
  final String _categoriesUrl = '$_baseUrl/admin/categories';
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final menuResponse = await http.get(
        Uri.parse(_getMenuUrl),
        headers: headers,
      );
      final categoriesResponse = await http.get(
        Uri.parse(_categoriesUrl),
        headers: headers,
      );

      if (menuResponse.statusCode == 200) {
        final menuData = jsonDecode(menuResponse.body);
        if (menuData['success'] == true) {
          if (mounted) {
            setState(() {
              _menuItems = menuData['data'] ?? [];
            });
          }
        }
      }
      if (categoriesResponse.statusCode == 200) {
        final catData = jsonDecode(categoriesResponse.body);
        if (catData['success'] == true) {
          if (mounted) {
            setState(() {
              _categories = catData['data'] ?? [];
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des données.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ----- FORMULAIRE D'AJOUT / MODIFICATION -----
  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    if (!mounted) return;
    final isEditing = item != null;
    final nameController = TextEditingController(
      text: isEditing ? item['name'] : '',
    );
    final descriptionController = TextEditingController(
      text: isEditing ? item['description'] ?? '' : '',
    );
    final priceController = TextEditingController(
      text: isEditing ? item['price'].toString() : '',
    );
    int? selectedCategoryId = isEditing
        ? item['category_id']
        : (_categories.isNotEmpty ? _categories[0]['id'] : null);
    File? selectedImage;
    String? existingImageUrl = isEditing ? item['image_url'] : null;

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
      }
    }

    Future<void> addCategory() async {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Nouvelle catégorie'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                try {
                  final token = await storage.read(key: 'token');
                  final response = await http.post(
                    Uri.parse(_categoriesUrl),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'name': name}),
                  );
                  final data = jsonDecode(response.body);
                  if (data['success'] == true) {
                    _fetchData();
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catégorie ajoutée !')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : ${data['error']}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur réseau')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      );
      if (result == true) {
        if (mounted) setState(() {});
      }
    }

    Future<void> deleteCategory(int catId) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Supprimer la catégorie ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          final token = await storage.read(key: 'token');
          final response = await http.delete(
            Uri.parse('$_categoriesUrl/$catId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            _fetchData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catégorie supprimée !')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur : ${data['error']}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
        }
      }
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEditing ? 'Modifier le plat' : 'Ajouter un plat',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du plat',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix (FCFA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat['id'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat['name']),
                                  if (_categories.length > 1) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          deleteCategory(cat['id']),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategoryId = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.brown,
                        ),
                        onPressed: addCategory,
                        tooltip: 'Ajouter une catégorie',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (existingImageUrl != null &&
                                  existingImageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  existingImageUrl!, // 👈 UTILISATION DIRECTE
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.photo_library,
                              color: Colors.brown,
                            ),
                            onPressed: pickImage,
                            tooltip: 'Choisir une image',
                          ),
                          if (selectedImage != null ||
                              (existingImageUrl != null &&
                                  existingImageUrl!.isNotEmpty))
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  selectedImage = null;
                                  existingImageUrl = null;
                                });
                              },
                              tooltip: 'Supprimer l\'image',
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = int.tryParse(priceController.text.trim());
                  if (name.isEmpty ||
                      price == null ||
                      selectedCategoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Remplissez tous les champs'),
                      ),
                    );
                    return;
                  }

                  final token = await storage.read(key: 'token');
                  final request = http.MultipartRequest(
                    isEditing ? 'PUT' : 'POST',
                    Uri.parse(
                      isEditing
                          ? '$_adminMenuUrl/${item['id']}'
                          : _adminMenuUrl,
                    ),
                  );
                  request.headers['Authorization'] = 'Bearer $token';
                  request.fields['name'] = name;
                  request.fields['category_id'] = selectedCategoryId.toString();
                  request.fields['price'] = price.toString();
                  request.fields['description'] = descriptionController.text
                      .trim();

                  if (selectedImage != null) {
                    request.files.add(
                      await http.MultipartFile.fromPath(
                        'image',
                        selectedImage!.path,
                      ),
                    );
                  }

                  try {
                    final streamedResponse = await request.send();
                    final response = await http.Response.fromStream(
                      streamedResponse,
                    );
                    final data = jsonDecode(response.body);
                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      if (data['success'] == true) {
                        Navigator.pop(context, true);
                        _fetchData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(data['message'] ?? 'Succès !'),
                            backgroundColor: Colors.green[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : ${data['error']}')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erreur serveur')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur réseau')),
                    );
                  }
                },
                child: Text(isEditing ? 'Modifier' : 'Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(int id, String name) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final token = await storage.read(key: 'token');
        final response = await http.delete(
          Uri.parse('$_adminMenuUrl/$id'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _fetchData();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Plat supprimé !')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
      }
    }
  }

  String formatPrice(int price) => '$price FCFA';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.brown[300]),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: _menuItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun plat dans le menu',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                // 👇 CORRECTION : utilisation directe de l'URL Cloudinary
                final imageUrl = item['image_url'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.brown[100],
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.brown,
                              ),
                            ),
                    ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${item['category_name'] ?? 'Catégorie'} - ${formatPrice(item['price'])}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showItemDialog(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteItem(item['id'], item['name']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

// ============================================================
// ONGLET 3 : LISTE DES CLIENTS
// ============================================================
class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key});

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  List<dynamic> _clients = [];
  bool _isLoading = true;
  String _errorMessage = '';

  static String get _apiUrl => '${AppConfig.apiBaseUrl}/admin/clients';
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Token manquant. Veuillez vous reconnecter.';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _clients = data['data'] ?? [];
              _isLoading = false;
            });
          }
          return;
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = data['error'] ?? 'Erreur de chargement';
              _isLoading = false;
            });
          }
          return;
        }
      } else if (response.statusCode == 401) {
        await storage.deleteAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expirée, reconnectez-vous')),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
        return;
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur ${response.statusCode} : ${response.body}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Impossible de contacter le serveur. Vérifie que le backend tourne.';
          _isLoading = false;
        });
      }
      print('Exception dans _fetchClients: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.brown[300]),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchClients,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_clients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun client inscrit.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.brown[100],
              child: Text(
                client['name']?[0]?.toUpperCase() ?? '?',
                style: TextStyle(
                  color: Colors.brown[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              client['name'] ?? 'Sans nom',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              client['email'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Text(
              _formatDate(DateTime.parse(client['created_at'])),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ONGLET 4 : PROFIL ADMIN
// ============================================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  bool _isEditing = false;
  String _errorMessage = '';
  String _successMessage = '';
  Map<String, dynamic> _profile = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final storage = const FlutterSecureStorage();
  static String get _apiUrl => '${AppConfig.apiBaseUrl}/admin/profile';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
        return;
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _profile = data['data'];
            _nameController.text = _profile['name'] ?? '';
            _emailController.text = _profile['email'] ?? '';
            _phoneController.text = _profile['phone'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Erreur de chargement';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        await storage.deleteAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expirée, reconnectez-vous')),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de contacter le serveur.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _successMessage = data['message'] ?? 'Profil mis à jour !';
          _isEditing = false;
          _isLoading = false;
        });
        await storage.write(
          key: 'user_name',
          value: _nameController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (response.statusCode == 401) {
        await storage.deleteAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expirée, reconnectez-vous')),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Erreur lors de la mise à jour';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de contacter le serveur.';
        _isLoading = false;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      _errorMessage = '';
      _successMessage = '';
      if (_isEditing) {
        _nameController.text = _profile['name'] ?? '';
        _emailController.text = _profile['email'] ?? '';
        _phoneController.text = _profile['phone'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.brown[300]),
                  const SizedBox(height: 16),
                  Text(_errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mon Profil',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez vos informations personnelles',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.brown[100],
                            child: Text(
                              _profile['name']?.isNotEmpty == true
                                  ? _profile['name'][0].toUpperCase()
                                  : 'A',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_successMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _successMessage,
                                      style: TextStyle(
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (!_isEditing)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleEdit,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Modifier'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isEditing) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _updateProfile,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Enregistrer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _toggleEdit,
                                    icon: const Icon(Icons.close),
                                    label: const Text('Annuler'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// ONGLET 5 : GESTION DE LA BOUTIQUE
// ============================================================
class ShopSettingsTab extends StatelessWidget {
  const ShopSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShopSettingsScreen();
  }
}
