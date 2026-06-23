import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  final storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadShopInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/shop'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final info = data['data'];
          _addressController.text = info['address'] ?? '';
          _phoneController.text = info['phone'] ?? '';
          _hoursController.text = info['opening_hours'] ?? '';
          _latController.text = info['lat']?.toString() ?? '';
          _lngController.text = info['lng']?.toString() ?? '';
          setState(() {
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
        _errorMessage = 'Impossible de charger les informations.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveShopInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous reconnecter')),
        );
        setState(() => _isSaving = false);
        return;
      }

      final body = {
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'opening_hours': _hoursController.text.trim(),
        'lat': double.parse(_latController.text.trim()),
        'lng': double.parse(_lngController.text.trim()),
      };

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/shop'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations mises à jour !'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isSaving = false);
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Erreur lors de la mise à jour';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Suppression de l'AppBar personnalisée
      appBar: null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Adresse
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Adresse complète',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Horaires
                    TextFormField(
                      controller: _hoursController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Horaires d\'ouverture',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Latitude
                    TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.pin_drop),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.trim().isEmpty) return 'Requis';
                        if (double.tryParse(value) == null) {
                          return 'Nombre valide requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Longitude
                    TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.pin_drop),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.trim().isEmpty) return 'Requis';
                        if (double.tryParse(value) == null) {
                          return 'Nombre valide requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bouton sauvegarder
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveShopInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Sauvegarder',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
