import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<dynamic> _menuItems = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';
  static const String baseUrl = 'http://localhost:3000/api';

  final String _getMenuUrl = '$baseUrl/menu';
  final String _adminMenuUrl = '$baseUrl/admin/menu';
  final String _categoriesUrl = '$baseUrl/admin/categories';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Vérification de sécurité pour éviter les setState après unmount
  bool get _mounted => mounted;

  Future<void> _fetchData() async {
    if (!_mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final menuResponse = await http.get(Uri.parse(_getMenuUrl));
      final categoriesResponse = await http.get(Uri.parse(_categoriesUrl));

      if (_mounted) {
        if (menuResponse.statusCode == 200) {
          final menuData = jsonDecode(menuResponse.body);
          if (menuData['success'] == true) {
            setState(() {
              _menuItems = menuData['data'];
            });
          }
        }
        if (categoriesResponse.statusCode == 200) {
          final catData = jsonDecode(categoriesResponse.body);
          if (catData['success'] == true) {
            setState(() {
              _categories = catData['data'];
            });
          }
        }
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des données.';
        });
      }
    } finally {
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ----- AJOUTER UNE CATÉGORIE -----
  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                final response = await http.post(
                  Uri.parse(_categoriesUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'name': name}),
                );
                final data = jsonDecode(response.body);
                if (data['success'] == true) {
                  Navigator.pop(context, true);
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
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _fetchData();
    }
  }

  // ----- SUPPRIMER UNE CATÉGORIE -----
  Future<void> _deleteCategory(int catId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
        final response = await http.delete(Uri.parse('$_categoriesUrl/$catId'));
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _fetchData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catégorie supprimée !')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : ${data['error']}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erreur réseau')));
      }
    }
  }

  // ----- FORMULAIRE D'AJOUT / MODIFICATION (retourne Future<bool>) -----
  Future<bool> _showItemDialog({Map<String, dynamic>? item}) async {
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

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // On utilise un StatefulBuilder pour l'état local du dialogue
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> _pickImage() async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                setDialogState(() {
                  selectedImage = File(pickedFile.path);
                });
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Modifier le plat' : 'Ajouter un plat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du plat',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix (FCFA)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat['id'],
                                child: Text(cat['name']),
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
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addCategory,
                          tooltip: 'Ajouter une catégorie',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: selectedImage != null
                              ? Image.file(
                                  selectedImage!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : (existingImageUrl != null &&
                                    existingImageUrl!.isNotEmpty)
                              ? Image.network(
                                  '$baseUrl$existingImageUrl',
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.photo_library),
                              onPressed: _pickImage,
                              tooltip: 'Choisir une image',
                            ),
                            if (selectedImage != null ||
                                (existingImageUrl != null &&
                                    existingImageUrl!.isNotEmpty))
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.red,
                                ),
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
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = int.tryParse(priceController.text.trim());
                    if (name.isEmpty ||
                        price == null ||
                        selectedCategoryId == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Remplissez tous les champs'),
                        ),
                      );
                      return;
                    }

                    // Préparer la requête
                    final request = http.MultipartRequest(
                      isEditing ? 'PUT' : 'POST',
                      Uri.parse(
                        isEditing
                            ? '$_adminMenuUrl/${item!['id']}'
                            : _adminMenuUrl,
                      ),
                    );
                    request.fields['name'] = name;
                    request.fields['category_id'] = selectedCategoryId
                        .toString();
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
                          // Fermer le dialogue avec succès
                          Navigator.pop(dialogContext, true);
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Erreur : ${data['error']}'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Erreur serveur')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Erreur réseau')),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Modifier' : 'Ajouter'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) => value ?? false); // si null, on renvoie false
  }

  // ----- SUPPRIMER UN PLAT -----
  Future<void> _deleteItem(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
        final response = await http.delete(Uri.parse('$_adminMenuUrl/$id'));
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _fetchData();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Menu'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : _menuItems.isEmpty
          ? const Center(child: Text('Aucun plat dans le menu'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final imageUrl = item['image_url'] != null
                    ? '$baseUrl${item['image_url']}'
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.fastfood),
                    title: Text(item['name']),
                    subtitle: Text(
                      '${item['category_name'] ?? 'Catégorie'} - ${formatPrice(item['price'])}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final result = await _showItemDialog(item: item);
                            if (result) {
                              await _fetchData();
                            }
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await _showItemDialog();
          if (result) {
            await _fetchData();
          }
        },
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
