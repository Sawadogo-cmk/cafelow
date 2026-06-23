import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import 'all_orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalOrders = 0;
  int _totalRevenueCompleted = 0;
  int _pendingOrders = 0;

  static String get _apiUrl => '${AppConfig.apiBaseUrl}/admin/orders';
  static String _statusUrl(int orderId) =>
      '${AppConfig.apiBaseUrl}/admin/orders/$orderId/status';

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAdminAndFetch();
  }

  Future<void> _checkAdminAndFetch() async {
    final role = await storage.read(key: 'role');
    if (role != 'admin') {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    final token = await storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée, veuillez vous reconnecter.'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
      return;
    }
    await _fetchOrders(token);
  }

  Future<void> _fetchOrders(String token) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
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

          setState(() {
            _orders = orders;
            _totalOrders = orders.length;
            _totalRevenueCompleted = data['totalRevenueCompleted'] ?? 0;
            _pendingOrders = orders
                .where((o) => o['status'] == 'en_attente')
                .length;
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
          _errorMessage = 'Erreur serveur (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Impossible de contacter le serveur. Vérifie que le backend tourne sur ${AppConfig.apiBaseUrl}.';
        _isLoading = false;
      });
      print('Exception dans _fetchOrders: $e');
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
        _checkAdminAndFetch();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut de la commande #$orderId mis à jour')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la mise à jour (${response.statusCode})',
            ),
          ),
        );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAdminAndFetch,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkAdminAndFetch,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : _orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune commande pour le moment'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _checkAdminAndFetch,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total commandes',
                          value: '$_totalOrders',
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Chiffre d\'affaires (terminé)',
                          value: '$_totalRevenueCompleted FCFA',
                          icon: Icons.attach_money,
                          color: Colors.green,
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
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Terminées',
                          value: '${_totalOrders - _pendingOrders}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dernières commandes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _orders.length > 5 ? 5 : _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final orderId = order['id'];
                      final total = order['total'];
                      final status = order['status'] ?? 'en_attente';
                      final customer = order['customer_name'] ?? 'Anonyme';
                      final createdAt = DateTime.parse(order['created_at']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown[100],
                            child: Text(
                              '#$orderId',
                              style: const TextStyle(color: Colors.brown),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(customer)),
                              _buildStatusChip(status),
                            ],
                          ),
                          subtitle: Text(
                            '${_formatDate(createdAt)} • $total FCFA',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (newStatus) =>
                                _updateStatus(orderId, newStatus),
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
                  // Espace pour que le bouton ne colle pas à la fin
                  const SizedBox(height: 20),
                ],
              ),
            ),
      // 👇 BOUTON FIXE EN BAS DE L'ÉCRAN
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllOrdersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
            label: const Text(
              'Voir toutes les commande',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
