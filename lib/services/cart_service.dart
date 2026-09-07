import 'package:flutter/material.dart';

// Modèle d'un article dans le panier
class CartItem {
  final int id;
  final String name;
  final int price; // Prix en FCFA
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

// Le service qui gère le panier (extends ChangeNotifier pour rafraîchir l'UI)
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Nombre total d'articles (ex: 2 Coca + 1 Riz = 3)
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  // Prix total en FCFA
  int get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  // Ajouter un plat
  void addItem(Map<String, dynamic> menuItem) {
    final existingIndex = _items.indexWhere(
      (item) => item.id == menuItem['id'],
    );
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: menuItem['id'],
          name: menuItem['name'],
          price: menuItem['price'],
        ),
      );
    }
    notifyListeners(); // Met à jour l'écran
  }

  // Supprimer complètement un article
  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Augmenter la quantité
  void incrementQuantity(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  // Diminuer la quantité (si 1, on supprime l'article)
  void decrementQuantity(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        removeItem(id);
      }
    }
  }

  // Vider le panier (après validation de commande)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
