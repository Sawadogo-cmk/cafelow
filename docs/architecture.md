# Architecture du projet CaféFlow

## Vue d'ensemble

CaféFlow est une application **full-stack** avec :
- Un **frontend Flutter** (Android, iOS, Web) qui communique avec une API REST.
- Un **backend Node.js/Express** qui sert l'API et gère la logique métier.
- Une **base de données MySQL** pour le stockage persistant.

```
┌─────────────────┐     ┌─────────────────────┐     ┌──────────────┐
│   Flutter App   │────▶│  Node.js / Express  │────▶│    MySQL     │
│  (Mobile/Web)   │◀────│      (API REST)     │◀────│   Database   │
└─────────────────┘     └─────────────────────┘     └──────────────┘
         │                        │
         ▼                        ▼
   Sécurité JWT           Cloudinary (Images)
   flutter_secure_storage
```

---

## Détail du Frontend (Flutter)

**Structure des dossiers `lib/` :**

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── config.dart               # Configuration (URL de l'API)
├── screens/                  # Tous les écrans
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart      # Client
│   ├── admin_panel_screen.dart
│   ├── menu_management_screen.dart
│   ├── order_history_screen.dart
│   ├── receipt_screen.dart
│   └── shop_settings_screen.dart
├── services/                 # Services métier
│   ├── cart_service.dart     # Gestion du panier (Provider)
│   └── receipt_service.dart  # Génération des reçus
└── widgets/                  # Composants réutilisables (à créer)
```

**Gestion d'état :** `Provider` pour le panier (`CartService`).

**Stockage sécurisé :** `flutter_secure_storage` pour le token JWT.

---

## Détail du Backend (Node.js/Express)

**Structure des dossiers `backend/` :**

```
backend/
├── server.js                 # Point d'entrée
├── src/
│   ├── config/
│   │   └── db.js             # Configuration MySQL (pool de connexions)
│   ├── middlewares/
│   │   └── auth.js           # Middleware JWT (verifyToken)
│   ├── routes/
│   │   ├── authRoutes.js     # Login / Inscription
│   │   ├── menuRoutes.js     # Menu public
│   │   ├── orderRoutes.js    # Commandes client
│   │   └── adminRoutes.js    # Routes protégées (admin)
│   └── controllers/          # (Optionnel, si implémenté)
└── uploads/                  # Dossier d'images (fallback)
```

**Middelware d'authentification :** JWT stocké dans le header `Authorization: Bearer <token>`.

---

## Flux de données

1. **Authentification** :
   - L'utilisateur envoie `email/password` à `/api/auth/login`.
   - Le backend vérifie le hash bcrypt et renvoie un token JWT.
   - L'application stocke le token et le rôle.

2. **Menu** :
   - GET `/api/menu` (public).
   - CRUD via `/api/admin/menu` (protégé par JWT + rôle admin).

3. **Commandes** :
   - Client : POST `/api/orders` (avec le token).
   - Admin : GET `/api/admin/orders` et PUT pour changer le statut.

---

## Technologies clés

| Composant | Technologie | Rôle |
| :--- | :--- | :--- |
| **Frontend** | Flutter (Dart) | Interface utilisateur multiplateforme |
| **Backend** | Node.js / Express | API REST, logique métier |
| **Base de données** | MySQL | Stockage persistant |
| **Authentification** | JWT (jsonwebtoken) | Sessions sans état |
| **Hachage** | bcrypt | Sécurisation des mots de passe |
| **Images** | Cloudinary | Hébergement et optimisation des images |
| **Environnement** | dotenv | Variables de configuration |