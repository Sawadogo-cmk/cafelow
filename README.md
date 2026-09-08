# ☕ CaféFlow - Application Flutter de gestion de café & commandes

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Node.js](https://img.shields.io/badge/Node.js-16+-green?logo=node.js)
![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql)
![License](https://img.shields.io/badge/license-MIT-green)

**CaféFlow** est une application **Flutter** complète de gestion de café et de commandes en ligne.  
Elle fonctionne sur **Android, iOS, et Web** à partir d’une seule base de code.

---

## 📲 Télécharger l'application

| Plateforme | Lien |
| :--- | :--- |
| **🌍 Version Web** | [https://cafeflow1.netlify.app/](https://cafeflow1.netlify.app/) |
| **📱 Android (ARM 64 bits)** | [Télécharger l'APK](https://github.com/Sawadogo-cmk/cafelow/releases/download/v1.0.0/app-arm64-v8a-release.apk) |
| **📱 Android (ARM 32 bits)** | [Télécharger l'APK](https://github.com/Sawadogo-cmk/cafelow/releases/download/v1.0.0/app-armeabi-v7a-release.apk) |
| **📱 Android (x86_64)** | [Télécharger l'APK](https://github.com/Sawadogo-cmk/cafelow/releases/download/v1.0.0/app-x86_64-release.apk) |
| **📦 Code source** | [GitHub](https://github.com/Sawadogo-cmk/cafelow) |

---

## 🔑 Identifiants de test

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
| <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/splash_screen.jpg" width="200"/> | <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/dashboard.jpg" width="200"/> | <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/administration.jpg" width="200"/> |

| Gestion du Menu (Admin) | Menu (Client) | Commandes |
| :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/menu_admin.jpg" width="200"/> | <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/menus.jpg" width="200"/> | <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/commandes.jpg" width="200"/> |

| Gestion des Clients | Reçu généré | Localisation |
| :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/client.jpg" width="200"/> | <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/recu_generer.jpg" width="200"/> | <img src="https://raw.githubusercontent.com/Sawadogo-cmk/cafelow/master/screenshots/localisation.jpg" width="200"/> |

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

## 📚 Documentation

- [Guide d'installation](docs/installation.md) - Installer le projet en local
- [API Endpoints](docs/api.md) - Documentation des routes backend
- [Structure de la base de données](docs/database.md) - Schéma MySQL
- [Déploiement](docs/deployment.md) - Déployer sur Render / Netlify
- [Architecture](docs/architecture.md) - Vue d'ensemble du projet

---

## 🤝 Contribuer

Les contributions sont les bienvenues ! Pour contribuer :

1. Forkez le projet
2. Créez votre branche (`git checkout -b feature/amazing-feature`)
3. Commitez vos changements (`git commit -m 'Add amazing feature'`)
4. Poussez sur la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

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
