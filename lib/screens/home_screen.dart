import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import 'dashboard_screen.dart';
import 'menu_management_screen.dart';
import 'order_history_screen.dart';
import 'location_screen.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _menuItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  String? _selectedCategory;

  static const String apiUrl = '${AppConfig.apiBaseUrl}/menu';
  final storage = const FlutterSecureStorage();
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkAuthAndRole();
    _fetchMenu();
    _searchController.addListener(_filterMenu);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndRole() async {
    final token = await storage.read(key: 'token');
    final role = await storage.read(key: 'role');
    if (token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = (role == 'admin');
        });
      }
    }
  }

  Future<void> _fetchMenu() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = data['data'] as List;
          final categoriesSet = <String>{};
          for (var item in items) {
            final cat = item['category_name'] ?? 'Autre';
            categoriesSet.add(cat);
          }
          if (mounted) {
            setState(() {
              _menuItems = items;
              _filteredItems = items;
              _categories = categoriesSet.toList()..sort();
              _isLoading = false;
              _selectedCategory = null;
            });
            _animationController.forward(from: 0.0);
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Erreur de chargement du menu';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur serveur (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger le menu. Vérifie ton réseau.';
          _isLoading = false;
        });
      }
    }
  }

  void _filterMenu() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _menuItems.where((item) {
        if (_selectedCategory != null) {
          final cat = item['category_name'] ?? 'Autre';
          if (cat != _selectedCategory) return false;
        }
        final name = item['name'].toLowerCase();
        final category = item['category_name']?.toLowerCase() ?? '';
        return name.contains(query) || category.contains(query);
      }).toList();
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterMenu();
    _animationController.forward(from: 0.0);
  }

  Future<void> _logout() async {
    context.read<CartService>().clearCart();
    await storage.deleteAll();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  String formatPrice(int price) => '$price FCFA';

  Map<String, List<dynamic>> _groupItemsByCategory(List<dynamic> items) {
    final map = <String, List<dynamic>>{};
    for (var item in items) {
      final cat = item['category_name'] ?? 'Autre';
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final bool isFilteredByCategory = _selectedCategory != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'CaféFlow',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationScreen()),
              );
            },
            tooltip: 'Nous trouver',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historique des commandes',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuManagementScreen(),
                  ),
                );
              },
              tooltip: 'Gérer le menu',
            ),
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
              tooltip: 'Dashboard admin',
            ),
          ],
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
                tooltip: 'Voir mon panier',
              ),
              if (cart.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cart.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un plat...',
                prefixIcon: const Icon(Icons.search, color: Colors.brown),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (!_isLoading && _categories.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(null, 'Tous'),
                  const SizedBox(width: 8),
                  ..._categories.map((cat) => _buildCategoryChip(cat, cat)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : _filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun plat ne correspond à votre recherche',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : FadeTransition(
                    opacity: _animationController,
                    child: isFilteredByCategory
                        ? _buildFlatList(_filteredItems)
                        : _buildGroupedList(_filteredItems),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.brown[800]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.brown[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFlatList(List<dynamic> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildGroupedList(List<dynamic> items) {
    final grouped = _groupItemsByCategory(items);
    final categoryKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: categoryKeys.length,
      itemBuilder: (context, index) {
        final category = categoryKeys[index];
        final categoryItems = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Column(
              children: categoryItems
                  .map((item) => _buildMenuItemCard(item))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  // ----- Carte d'un plat (avec image agrandie) -----
  Widget _buildMenuItemCard(dynamic item) {
    final category = item['category_name'] ?? '';
    final imageUrl = item['image_url'];
    final Color categoryColor = _getCategoryColor(category);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 IMAGE AGRANDIE : 90 x 120
                Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                          ),
                        )
                      : const Icon(Icons.fastfood, color: Colors.brown),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatPrice(item['price']),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.brown[50],
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                size: 20,
                              ),
                              color: Colors.brown,
                              onPressed: () {
                                context.read<CartService>().addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${item['name']} ajouté au panier !',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 SHIMMER MIS À JOUR : 90 x 120
                Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 14,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            height: 20,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'plat':
        return Colors.orange;
      case 'boisson':
        return Colors.blue;
      case 'dessert':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
