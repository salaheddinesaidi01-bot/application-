# Application Mobile Flutter + Backend Node.js (Prêt pour APK)

Ce projet contient l'architecture complète pour développer votre application mobile avec un backend Node.js et générer votre fichier APK Android.

---

## 📁 Structure du Projet

```text
├── backend/            # Serveur API Node.js (Express, CORS, dotenv)
│   ├── server.js       # Point d'entrée de l'API REST
│   ├── package.json    # Dépendances (express, cors, nodemon)
│   └── .env            # Variables d'environnement (PORT=3000)
│
└── mobile_app/         # Application Mobile Flutter
    ├── lib/main.dart   # Code source Flutter avec intégration HTTP
    ├── pubspec.yaml    # Dépendances Flutter (http, icons, etc.)
    └── android/        # Configuration native Android (Permissions Internet & Cleartext HTTP activées)
```

---

## 🚀 1. Lancer le Backend Node.js

Ouvrez un terminal dans le dossier `backend` :

```powershell
cd backend
npm run dev
```

> Le serveur écoute sur le port `3000` (`http://localhost:3000` et `http://0.0.0.0:3000`).

---

## 📱 2. Lancer l'Application Flutter en Développement

Ouvrez un second terminal dans le dossier `mobile_app` :

```powershell
cd mobile_app
flutter run
```

### 💡 Astuce de communication Réseau avec le Backend :
- **Sur Émulateur Android :** utilisez l'adresse `http://10.0.2.2:3000` (déjà préconfigurée par défaut dans l'application).
- **Sur Navigateur Web / Bureau Windows :** utilisez `http://localhost:3000`.
- **Sur Téléphone physique (en WiFi) :** utilisez l'adresse IP locale de votre PC (ex: `http://192.168.1.XX:3000`).

---

## 📦 3. Compiler l'Application en APK Android

Pour générer le fichier **APK** installable sur n'importe quel smartphone Android :

```powershell
cd mobile_app
flutter build apk
```

Une fois la compilation terminée, votre fichier APK sera disponible ici :
```text
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

### Option APK optimisé par architecture (plus léger) :
```powershell
flutter build apk --split-per-abi
```
Cela produit des APKs distincts plus légers (ex: `app-arm64-v8a-release.apk`) pour chaque type de processeur Android.
