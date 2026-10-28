# Spécification de Conception : Gestion des Groupes & SideBar avec Animations

Date: 2026-10-20
Statut: Approuvé par l'utilisateur

## 1. Objectifs & Vue d'ensemble

L'application **Gestion Cours de Soutien** nécessite l'ajout d'une gestion complète des **Groupes** d'élèves, d'une **SideBar de navigation (Drawer)** moderne et animée, d'un écran dédié à l'**Historique des Paiements**, ainsi que des animations dynamiques et fluides pour la **Landing Page** et la **SideBar**.

### Besoins validés :
1. **Gestion des Groupes** :
   - Création, modification et suppression de groupes (Nom, Niveau scolaire, Tarif standard par élève, Description).
   - Affectation / désaffectation facile d'un ou plusieurs élèves à un groupe.
   - Planification d'une séance collective pour tout le groupe en 1 clic.
   - Pointage des présences et encaissement collectif avec bouton magique *"Tout encaisser en 1 clic (Total : X DA)"* ou élève par élève.
2. **SideBar (Drawer de navigation latérale)** :
   - Accessible via icône hamburger ou geste de glissement (swipe).
   - Header professeur stylisé avec avatar, nom, matières et statistiques rapides.
   - Navigation animée vers :
     - 🏠 Tableau de bord
     - 👥 Groupes (Nouvel écran)
     - 📜 Historique des Paiements (Nouvel écran)
     - 🎓 Élèves
     - 💰 Finances & Impayés
     - 📝 Cahier de Notes
     - ⚙️ Paramètres & Tarifs
     - 🌙 / ☀️ Bascule Mode Sombre / Clair
3. **Historique des Paiements** :
   - Flux chronologique de tous les paiements réalisés avec filtres (par mois, par élève, par groupe).
   - Cartes KPI récapitulatives (Total encaissé ce mois, total annuel, nombre de séances réglées).
   - Accès et consultation des archives des clôtures mensuelles.
4. **Animations UX Premium** :
   - **Landing Page** : animations d'entrée échelonnées (staggered fade & slide), flottement subtil du badge / logo, micro-interactions sur les boutons.
   - **SideBar** : apparition fluide du tiroir, effet d'échelle subtil sur les icônes actives, feedback tactile élégant lors de la sélection des onglets.

---

## 2. Modèle de Données & Backend

### 2.1 Table PostgreSQL `groupes`
```sql
CREATE TABLE IF NOT EXISTS groupes (
    id_groupe UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL,
    niveau VARCHAR(50),
    tarif_par_eleve INTEGER NOT NULL DEFAULT 1000,
    description TEXT,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 2.2 Table de liaison `groupe_eleves`
```sql
CREATE TABLE IF NOT EXISTS groupe_eleves (
    id_groupe UUID REFERENCES groupes(id_groupe) ON DELETE CASCADE,
    id_eleve UUID REFERENCES eleves(id_eleve) ON DELETE CASCADE,
    date_inscription TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_groupe, id_eleve)
);
```

### 2.3 Évolution de la table `seances`
Ajout de la colonne :
- `id_groupe UUID REFERENCES groupes(id_groupe) ON DELETE SET NULL`
- `id_seance_groupe UUID` (permet de regrouper les enregistrements élèves d'une même séance collective).

### 2.4 Endpoints API REST (Express.js)
- `GET /api/groupes` : Liste des groupes avec nombre d'élèves et dernier cours.
- `GET /api/groupes/:id` : Détails d'un groupe avec la liste de ses élèves membres.
- `POST /api/groupes` : Créer un groupe (avec liste d'élèves initiale optionnelle).
- `PUT /api/groupes/:id` : Mettre à jour nom, niveau, tarif, et élèves associés.
- `DELETE /api/groupes/:id` : Supprimer un groupe.
- `POST /api/groupes/:id/seance` : Créer une séance collective pour les élèves du groupe (génère les séances individuelles liées).
- `POST /api/groupes/:id/encaisser` : Encaisser toutes les séances impayées d'une date donnée pour le groupe (ou un sous-ensemble d'élèves pointés).
- `GET /api/paiements/historique` : Liste chronologique paginée/filtrable de toutes les séances payées (`statut_paiement = 'Payé'`).

---

## 3. Architecture Mobile (Flutter)

### 3.1 Nouveaux Modèles
- `Groupe` (`mobile_app/lib/models/groupe.dart`) : `id`, `nom`, `niveau`, `tarifParEleve`, `description`, `elevesIds`, `nombreEleves`.
- `PaiementHistorique` (`mobile_app/lib/models/paiement_historique.dart`) : informations de séance payée avec nom groupe/élève, date, montant, mode.

### 3.2 Nouveaux Widgets & Écrans
- `AppDrawer` (`mobile_app/lib/widgets/app_drawer.dart`) : Le menu latéral animé avec header prof, items stylisés, badges dynamiques.
- `GroupesScreen` ou `GroupesTab` (`mobile_app/lib/screens/groupes_screen.dart`) : Écran de gestion des groupes, fiche groupe, séance de groupe et encaissement express.
- `NouveauGroupeDialog` (`mobile_app/lib/widgets/nouveau_groupe_dialog.dart`) : Modal de création / édition avec sélection multi-élèves.
- `SeanceGroupeDialog` (`mobile_app/lib/widgets/seance_groupe_dialog.dart`) : Modal de pointage et encaissement en 1 clic pour un groupe.
- `HistoriquePaiementsScreen` (`mobile_app/lib/screens/historique_paiements_screen.dart`) : Journal chronologique des encaissements + onglet archives clôtures.

### 3.3 Amélioration des Animations
- Refonte dynamique de `LandingScreen` (`mobile_app/lib/screens/landing_screen.dart`) avec `AnimationController`, `FadeTransition`, `SlideTransition` et `ScaleTransition`.
- Animation d'ouverture et d'apparition des éléments dans `AppDrawer`.
