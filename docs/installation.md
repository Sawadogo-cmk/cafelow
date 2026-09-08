# Guide d'installation de CaféFlow

Ce guide vous aidera à installer et exécuter CaféFlow en local sur votre machine.

---

## Prérequis

Avant de commencer, assurez-vous d'avoir installé :

| Logiciel | Version minimale |
| :--- | :--- |
| **Flutter SDK** | 3.0+ |
| **Node.js** | 16+ |
| **MySQL** | 8.0+ (ou XAMPP/WAMP) |
| **Git** | Dernière version |
| **Android Studio / VS Code** | Pour exécuter Flutter |

---

## 1️⃣ Cloner le dépôt

```bash
git clone https://github.com/Sawadogo-cmk/cafelow.git
cd cafelow
```

---

## 2️⃣ Installer le Backend (Node.js)

```bash
# Aller dans le dossier backend
cd backend

# Installer les dépendances
npm install

# Créer le fichier .env
cp .env.example .env
# OU le créer manuellement
```

**Configuration de `.env`** :
```env
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=cafeflow
JWT_SECRET=monSuperSecret

# Cloudinary (optionnel, pour les images)
CLOUDINARY_CLOUD_NAME=ton_cloud_name
CLOUDINARY_API_KEY=ton_api_key
CLOUDINARY_API_SECRET=ton_api_secret
```

**Démarrer le serveur** :
```bash
npm start
# OU en mode développement (avec rechargement automatique)
npm run dev
```

Le backend sera disponible sur : `http://localhost:3000`

---

## 3️⃣ Installer le Frontend (Flutter)

```bash
# Revenir à la racine du projet
cd ..

# Installer les dépendances Flutter
flutter pub get

# Vérifier que tout est prêt
flutter doctor

# Lancer l'application (Android/iOS/Web)
flutter run
```

---

## 4️⃣ Base de données MySQL

1. **Démarrer MySQL** (via XAMPP/WAMP ou en ligne de commande)
2. **Créer la base de données** :
   ```sql
   CREATE DATABASE cafeflow;
   USE cafeflow;
   ```
3. **Importer les tables** : Le schéma est disponible dans [database.md](database.md).
4. **Ajouter un administrateur par défaut** (optionnel) :
   ```sql
   INSERT INTO users (email, password_hash, role, name, phone)
   VALUES (
       'admin@gmail.com',
       '$2b$10$...', -- Générer avec bcrypt
       'admin',
       'Admin CafeFlow',
       '87284619'
   );
   ```

---

## ✅ Vérification

- Le backend répond à : `http://localhost:3000/api/test-db`
- L'application Flutter démarre et se connecte au backend.

---

## 🚀 Problèmes courants

| Problème | Solution |
| :--- | :--- |
| **Erreur MySQL : Access denied** | Vérifiez le mot de passe dans `.env` |
| **Flutter ne trouve pas le backend** | Dans `lib/config.dart`, remplacez l'URL par `http://10.0.2.2:3000/api` pour l'émulateur |
| **Port 3000 déjà utilisé** | Changez `PORT` dans `.env` |