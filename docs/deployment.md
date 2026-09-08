# Guide de déploiement de CaféFlow

Ce guide explique comment déployer CaféFlow sur Render (Backend) et Netlify (Web).

---

## 1️⃣ Déployer le Backend sur Render

Render est la plateforme d'hébergement du backend Node.js.

### Étapes

1. Allez sur [Render.com](https://render.com) et connectez-vous.
2. Cliquez sur **"New +"** → **"Web Service"**.
3. Connectez votre dépôt GitHub `Sawadogo-cmk/cafelow`.
4. Configurez le service :
   - **Name** : `cafelow-api`
   - **Environment** : `Node`
   - **Build Command** : `npm install`
   - **Start Command** : `npm start`
   - **Root Directory** : `backend/`

5. Ajoutez les **variables d'environnement** (dans la section "Environment") :
   ```env
   PORT=3000
   DB_HOST=ton_host_mysql
   DB_USER=ton_user
   DB_PASSWORD=ton_password
   DB_NAME=cafeflow
   JWT_SECRET=ton_secret
   CLOUDINARY_CLOUD_NAME=ton_cloud_name
   CLOUDINARY_API_KEY=ton_api_key
   CLOUDINARY_API_SECRET=ton_api_secret
   ```

6. Cliquez sur **"Create Web Service"**.

Votre backend sera disponible à : `https://cafelow-api.onrender.com`

---

## 2️⃣ Déployer la version Web sur Netlify

Netlify héberge la version Web statique de Flutter.

### Étapes (via glisser-déposer)

1. **Générer le build Web** :
   ```bash
   flutter build web --release
   ```

2. Allez sur [Netlify.com](https://netlify.com) et connectez-vous.
3. **Glissez-déposez** le dossier `build/web` dans la zone prévue.
4. Netlify détecte automatiquement le site statique.
5. Cliquez sur **"Deploy"**.

Lien obtenu : `https://votre-nom.netlify.app` (personnalisable dans les paramètres).

---

## 3️⃣ Déployer la version Android (APK) sur GitHub Releases

1. **Générer les APK** :
   ```bash
   flutter build apk --split-per-abi
   ```

2. Les fichiers se trouvent dans `build/app/outputs/flutter-apk/`.

3. Allez sur GitHub → votre dépôt → **Releases**.
4. **Create a new release** → attachez les 3 fichiers `.apk`.
5. Publiez la release.

Les utilisateurs pourront télécharger les APK depuis cette page.

---

## 4️⃣ Mettre à jour le lien de l'API dans le frontend

Modifiez `lib/config.dart` :

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://votre-backend.onrender.com/api';
  static const String imageBaseUrl = 'https://votre-backend.onrender.com';
}
```

Puis regénérez la version Web et les APK.

---

## 🔄 Mise à jour automatique (CI/CD)

Pour automatiser les déploiements :

- **Netlify** : Connectez votre dépôt → à chaque push sur `master`, Netlify rebuild automatiquement.
- **Render** : Connecté à GitHub → à chaque push, Render redéploie le backend.

---

## ✅ Vérification finale

- Backend : `https://cafelow-api.onrender.com/api/test-db` doit répondre `OK`.
- Web : `https://cafeflow1.netlify.app` doit charger l'application.
- APK : Les liens de téléchargement dans les Releases doivent fonctionner.