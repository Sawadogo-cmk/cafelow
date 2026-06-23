import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'toutes';

  final storage = const FlutterSecureStorage();
  static String get _apiUrl => '${AppConfig.apiBaseUrl}/admin/orders';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Token manquant. Veuillez vous reconnecter.';
          _isLoading = false;
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
            _filteredOrders = orders;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Erreur de chargement';
            _isLoading = false;
          });
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

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'toutes') {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((o) => o['status'] == filter).toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toutes les commandes'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
            tooltip: 'Rafraîchir',
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
                  Text(_errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchOrders,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filtres
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('Toutes', 'toutes'),
                      const SizedBox(width: 8),
                      _buildFilterChip('En attente', 'en_attente'),
                      const SizedBox(width: 8),
                      _buildFilterChip('En préparation', 'en_preparation'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Terminé', 'termine'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Liste
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune commande avec ce statut',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final orderId = order['id'];
                            final total = order['total'];
                            final status = order['status'] ?? 'en_attente';
                            final customer =
                                order['customer_name'] ?? 'Anonyme';
                            final createdAt = DateTime.parse(
                              order['created_at'],
                            );
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
                                    '#$orderId',
                                    style: const TextStyle(
                                      color: Colors.brown,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _applyFilter(value);
      },
      selectedColor: Colors.brown[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.brown[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.brown[700]! : Colors.grey[300]!,
        ),
      ),
    );
  }
}
