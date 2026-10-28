# Plan d'Implémentation : Gestion des Groupes & SideBar avec Animations

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter la gestion complète des Groupes d'élèves (avec planification et encaissement collectif en 1 clic), une SideBar (Drawer) animée, un écran d'Historique des paiements, et des animations modernes pour la Landing Page et la SideBar.

**Architecture:** 
1. Backend PostgreSQL : ajout des tables `groupes` et `groupe_eleves`, colonnes `id_groupe` et `id_seance_groupe` dans `seances`, et nouveaux endpoints REST dans `server.js`.
2. Mobile Flutter : modèles `Groupe` et `PaiementHistorique`, `AppDrawer` animé intégré au `Scaffold` principal, écran `GroupesScreen` avec dialogue de pointage/encaissement groupé, et écran `HistoriquePaiementsScreen`.
3. Animations riches : micro-interactions, transitions fluides staggered sur la Landing Page et le Drawer.

**Tech Stack:** Flutter 3.x, Dart, Node.js (Express), PostgreSQL (pg), Material 3.

**Spec:** `docs/superpowers/specs/2026-10-20-groupes-sidebar-design.md`

## Global Constraints
- Respecter le thème visuel existant (Bleu marine `#061449`, Indigo `#1E2A5E`, Teal `#006A61`, Mint `#86F2E4`, Ambre `#FFB95F`).
- Préserver 100% de la compatibilité avec les requêtes existantes du tableau de bord, des finances, des fiches élèves et de la clôture mensuelle.
- `flutter analyze` doit rester strictement à 0 erreur.
- La compilation de l'APK doit réussir et être installée sur l'appareil connecté.

---

### Task 1: Backend Database Migration & Groupes Endpoints
**Files:**
- Modify: `backend/schema.sql`
- Modify: `backend/server.js`

**Interfaces:**
- Produces: 
  - `GET /api/groupes` -> `List<Groupe>`
  - `POST /api/groupes` -> `{ id_groupe, nom, niveau, tarif_par_eleve, description, eleves_ids }`
  - `PUT /api/groupes/:id` -> `{ success: true, groupe }`
  - `DELETE /api/groupes/:id` -> `{ success: true }`

- [x] **Step 1: Mettre à jour `backend/schema.sql`**
Ajouter la création de `groupes`, `groupe_eleves`, et les colonnes `id_groupe` et `id_seance_groupe` dans `seances`.

- [x] **Step 2: Exécuter la migration SQL automatique au démarrage dans `backend/server.js`**
Ajouter dans `initDatabase()` de `server.js` les requêtes `CREATE TABLE IF NOT EXISTS groupes...` et `ALTER TABLE seances ADD COLUMN IF NOT EXISTS id_groupe UUID REFERENCES groupes(id_groupe) ON DELETE SET NULL;`.

- [x] **Step 3: Implémenter les routes REST CRUD pour les groupes dans `server.js`**
Ajouter `GET /api/groupes`, `GET /api/groupes/:id`, `POST /api/groupes`, `PUT /api/groupes/:id`, `DELETE /api/groupes/:id`.

- [x] **Step 4: Tester les endpoints avec curl/fetch**
Vérifier la création et récupération d'un groupe via requête HTTP.

---

### Task 2: Backend Planification et Encaissement Groupé & Historique Paiements
**Files:**
- Modify: `backend/server.js`

**Interfaces:**
- Produces:
  - `POST /api/groupes/:id/seance` -> `{ message, count, seances }`
  - `POST /api/groupes/:id/encaisser` -> `{ message, countEncaisses, montantTotal }`
  - `GET /api/paiements/historique` -> `{ totalMontant, count, paiements }`

- [x] **Step 1: Ajouter l'endpoint de séance collective `POST /api/groupes/:id/seance`**
Génère pour chaque élève sélectionné une entrée `seances` avec `id_groupe`, date, heure, montant (tarif du groupe ou personnalisé).

- [x] **Step 2: Ajouter l'endpoint d'encaissement en 1 clic `POST /api/groupes/:id/encaisser`**
Met à jour en `Payé` toutes les séances impayées de ce groupe pour la date spécifiée (ou les IDs d'élèves fournis).

- [x] **Step 3: Ajouter l'endpoint `GET /api/paiements/historique`**
Retourne la liste ordonnée des séances réglées avec pagination, filtre de mois et recherche.

---

### Task 3: Mobile Models & ApiService Integration
**Files:**
- Create: `mobile_app/lib/models/groupe.dart`
- Create: `mobile_app/lib/models/paiement_historique.dart`
- Modify: `mobile_app/lib/services/api_service.dart`

**Interfaces:**
- Consumes: Endpoints backend `/api/groupes`, `/api/paiements/historique`
- Produces:
  - `ApiService.getGroupes()` -> `Future<List<Groupe>>`
  - `ApiService.createGroupe(...)` -> `Future<Groupe>`
  - `ApiService.updateGroupe(...)` -> `Future<Groupe>`
  - `ApiService.deleteGroupe(id)` -> `Future<bool>`
  - `ApiService.creerSeanceGroupe(...)` -> `Future<bool>`
  - `ApiService.encaisserGroupe(...)` -> `Future<Map<String, dynamic>>`
  - `ApiService.getHistoriquePaiements(...)` -> `Future<HistoriquePaiementsResponse>`

- [x] **Step 1: Créer `mobile_app/lib/models/groupe.dart`**
- [x] **Step 2: Créer `mobile_app/lib/models/paiement_historique.dart`**
- [x] **Step 3: Ajouter les méthodes correspondantes dans `mobile_app/lib/services/api_service.dart`**

---

### Task 4: Animated SideBar (Drawer) Widget
**Files:**
- Create: `mobile_app/lib/widgets/app_drawer.dart`
- Modify: `mobile_app/lib/main.dart`

**Interfaces:**
- Produces: `AppDrawer` widget avec callbacks de navigation `onSelectDestination(int index)`.

- [x] **Step 1: Créer le widget `AppDrawer`**
Drawer moderne avec :
- Header professeur animé (avatar gradient, nom du prof, compteur d'élèves/groupes).
- Liste des éléments de navigation avec icônes stylisées, hover/selection animation, et badges (ex: nombre de séances impayées).
- Switch de thème sombre/clair directement dans le tiroir.
- [x] **Step 2: Intégrer le Drawer dans `_MainNavigationScreenState` de `main.dart`**
Ajouter `drawer: AppDrawer(...)` dans le `Scaffold` et bouton hamburger menant à l'ouverture du tiroir.

---

### Task 5: Écran Groupes & Dialogs (Création & Encaissement en 1 clic)
**Files:**
- Create: `mobile_app/lib/screens/groupes_screen.dart`
- Create: `mobile_app/lib/widgets/nouveau_groupe_dialog.dart`
- Create: `mobile_app/lib/widgets/seance_groupe_dialog.dart`
- Modify: `mobile_app/lib/main.dart`

**Interfaces:**
- Produces:
  - Interface complète des Groupes accessible depuis la SideBar et l'IndexedStack.
  - Modal de création/édition d'un groupe avec sélection d'élèves.
  - Modal de pointage de présence et bouton magique « Tout encaisser en 1 clic ».

- [x] **Step 1: Créer `nouveau_groupe_dialog.dart`**
Saisie du nom, niveau scolaire, tarif par élève, et liste cochable des élèves inscrits.
- [x] **Step 2: Créer `seance_groupe_dialog.dart`**
Permet de planifier une séance pour le groupe, ou d'ouvrir une séance du jour pour pointer qui est présent et cliquer sur « Tout encaisser en 1 clic ».
- [x] **Step 3: Créer `groupes_screen.dart`**
Vue en cartes des groupes, avec effectifs, statut des paiements du groupe, et boutons d'action rapide.

---

### Task 6: Écran Historique des Paiements & Archives
**Files:**
- Create: `mobile_app/lib/screens/historique_paiements_screen.dart`
- Modify: `mobile_app/lib/main.dart`

**Interfaces:**
- Produces:
  - Écran complet avec journal des paiements, KPI, filtre par mois/élève, et consultation des clôtures mensuelles archivées.

- [x] **Step 1: Créer `historique_paiements_screen.dart`**
Affichage du flux d'encaissements, totaux encaissés, et onglet des clôtures mensuelles archivées.
- [x] **Step 2: Relier la SideBar à l'écran Historique des Paiements**

---

### Task 7: Animations Premium sur la Landing Page et la SideBar
**Files:**
- Modify: `mobile_app/lib/screens/landing_screen.dart`
- Modify: `mobile_app/lib/widgets/app_drawer.dart`

**Interfaces:**
- Animations d'entrée, pulsations douces, transitions fluides.

- [x] **Step 1: Animer la `LandingScreen`**
Ajout de `SingleTickerProviderStateMixin`, `AnimationController`, effet d'apparition échelonnée (hero badge, titre, cartes de fonctionnalités, bouton démarrer).
- [x] **Step 2: Animer les items du `AppDrawer`**
Transitions fluides avec délais progressifs sur les items du menu latéral.

---

### Task 8: Validation Complète & Build APK
**Files:**
- Run: `flutter analyze`
- Run: `flutter build apk --debug`
- Install: `adb -s R8YY71A5CXT install -r build/app/outputs/flutter-apk/app-debug.apk`

- [x] **Step 1: Vérifier `flutter analyze` sans erreur ni avertissement critique**
- [x] **Step 2: Compiler le nouvel APK et le copier à la racine**
- [x] **Step 3: Installer et tester sur le smartphone connecté**
