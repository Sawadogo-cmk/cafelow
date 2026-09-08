# ☕ CaféFlow - Application Flutter de gestion de café & commandes

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![License](https://img.shields.io/badge/license-MIT-green)

**CaféFlow** est une application **Flutter** complète de gestion de café et de commandes en ligne.  
Elle fonctionne sur **Android, iOS, et Web** à partir d’une seule base de code.

---

## 🌐 Tester l'application

| Support | Lien |
| :--- | :--- |
| **🌍 Web** (recommandé) | [https://cafeflow1.netlify.app/](https://cafeflow1.netlify.app/) |
| **📱 Android (APK)** | Télécharger dans la section [Releases](https://github.com/Sawadogo-cmk/cafelow/releases) |
| **📱 iOS** | (À venir) |

### 🔑 Identifiants de test
| Rôle | Email | Mot de passe |
| :--- | :--- | :--- |
| **Administrateur** | `admin@gmail.com` | `admin123` |

---

## 📱 Fonctionnalités

### 👤 Côté client
- ✅ Navigation dans le menu par catégories
- ✅ Ajout de plats au panier
- ✅ Passation de commandes
- ✅ Historique des commandes
- ✅ Reçu personnalisé

### 🛠️ Côté administrateur
- ✅ Dashboard avec statistiques en temps réel (CA, commandes, etc.)
- ✅ Gestion complète du menu (CRUD avec images Cloudinary)
- ✅ Gestion des catégories
- ✅ Suivi des commandes (statuts : en attente, en préparation, terminé)
- ✅ Liste des clients inscrits
- ✅ Gestion du profil administrateur

---

## 🖼️ Aperçu de l'application

| Écran de démarrage | Dashboard Admin | Administration |
| :---: | :---: | :---: |
| ![Splash](screenshots/splash_screen.jpg) | ![Dashboard](screenshots/dashboard.jpg) | ![Administration](screenshots/administration.jpg) |

| Gestion du Menu (Admin) | Menu (Client) | Commandes |
| :---: | :---: | :---: |
| ![Menu Admin](screenshots/menu_admin.jpg) | ![Menus](screenshots/menus.jpg) | ![Commandes](screenshots/commandes.jpg) |

| Gestion des Clients | Reçu généré | Localisation |
| :---: | :---: | :---: |
| ![Client](screenshots/client.jpg) | ![Reçu](screenshots/recu_generer.jpg) | ![Localisation](screenshots/localisation.jpg) |

---

## 🏗️ Stack technique

| Couche | Technologie |
| :--- | :--- |
| **Frontend** | Flutter (Dart) – multiplateforme (Android, iOS, Web) |
| **Backend API** | Node.js / Express |
| **Base de données** | MySQL |
| **Hébergement Backend** | Render |
| **Hébergement Web** | Netlify |
| **Stockage d'images** | Cloudinary |
| **Authentification** | JWT (JSON Web Tokens) |
| **Stockage sécurisé** | flutter_secure_storage |

---

## 🚀 Installation en local (pour les développeurs)

### 1️⃣ Prérequis
- Flutter SDK (dernière version stable)
- Node.js (v16+)
- MySQL (XAMPP/WAMP ou serveur dédié)
- Git

### 2️⃣ Backend
```bash
cd backend
npm install

# Créer un fichier .env (voir .env.example)
cp .env.example .env

# Démarrer le serveur
npm start