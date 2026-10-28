-- ==============================================================================
-- BASE DE DONNÉES : GESTION DE SÉANCES DE COURS DE SOUTIEN ("BIENVENUE MME TRARI")
-- SGBD : PostgreSQL (Compatible version 13+)
-- ==============================================================================

-- Activer l'extension pgcrypto pour gen_random_uuid() si nécessaire (inclus par défaut en PG13+)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. TABLE CONFIGURATION
CREATE TABLE IF NOT EXISTS config (
    cle VARCHAR(50) PRIMARY KEY,
    valeur TEXT NOT NULL
);

-- Données de configuration initiales
INSERT INTO config (cle, valeur) VALUES
    ('PrixNormale', '1000'),
    ('PrixPrivee', '2000'),
    ('EmailDestinataire', 'salaheddinesaidi01@gmail.com')
ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur;

-- 2. TABLE ÉLÈVES
CREATE TABLE IF NOT EXISTS eleves (
    id_eleve UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL,
    niveau VARCHAR(50),
    telephone VARCHAR(20),
    telephone_parent VARCHAR(50),
    email VARCHAR(100),
    statut VARCHAR(20) NOT NULL DEFAULT 'Actif', -- 'Actif' ou 'Inactif'
    date_ajout TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index pour la recherche et le filtre sur les élèves
CREATE INDEX IF NOT EXISTS idx_eleves_nom ON eleves (LOWER(nom));
CREATE INDEX IF NOT EXISTS idx_eleves_statut ON eleves (statut);

-- 3. TABLE SÉANCES
CREATE TABLE IF NOT EXISTS seances (
    id_seance UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_eleve UUID REFERENCES eleves(id_eleve) ON DELETE SET NULL,
    nom_eleve VARCHAR(100) NOT NULL, -- Préservé même en cas de suppression de l'élève
    date_seance DATE NOT NULL,
    heure VARCHAR(10),               -- Format HH:mm (optionnel pour les séances planifiées)
    type_seance VARCHAR(20) NOT NULL, -- 'Normale' ou 'Privée'
    montant INTEGER NOT NULL,        -- Montant en DA (ex: 500, 1000, 2000)
    statut_seance VARCHAR(20) NOT NULL DEFAULT 'Réalisée', -- 'Réalisée', 'Planifiée', 'Annulée'
    statut_paiement VARCHAR(20) NOT NULL DEFAULT 'Impayé', -- 'Payé', 'Impayé'
    mode_paiement VARCHAR(50),       -- 'Espèces', etc.
    date_paiement TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    cloturee BOOLEAN NOT NULL DEFAULT FALSE,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index d'optimisation pour les requêtes de reporting et de dashboard
CREATE INDEX IF NOT EXISTS idx_seances_id_eleve ON seances (id_eleve);
CREATE INDEX IF NOT EXISTS idx_seances_date_seance ON seances (date_seance);
CREATE INDEX IF NOT EXISTS idx_seances_statut_paiement ON seances (statut_paiement);
CREATE INDEX IF NOT EXISTS idx_seances_statut_seance ON seances (statut_seance);
CREATE INDEX IF NOT EXISTS idx_seances_cloturee ON seances (cloturee);
CREATE INDEX IF NOT EXISTS idx_seances_dashboard ON seances (statut_paiement, cloturee, statut_seance);

-- 4. TABLE CLÔTURES MENSUELLES (ARCHIVES HISTORIQUE)
CREATE TABLE IF NOT EXISTS clotures_mensuelles (
    id_cloture UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_cloture TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    mois_nom VARCHAR(50) NOT NULL,
    annee INTEGER NOT NULL,
    mois INTEGER NOT NULL,
    ca_total INTEGER NOT NULL,
    total_seances INTEGER NOT NULL,
    total_eleves INTEGER NOT NULL,
    recap_eleves JSONB,
    seances_details JSONB
);

CREATE INDEX IF NOT EXISTS idx_clotures_date ON clotures_mensuelles (date_cloture DESC);

-- 5. TABLE GROUPES
CREATE TABLE IF NOT EXISTS groupes (
    id_groupe UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(100) NOT NULL,
    niveau VARCHAR(50),
    tarif_par_eleve INTEGER NOT NULL DEFAULT 1000,
    description TEXT,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_groupes_nom ON groupes (LOWER(nom));

-- 6. TABLE LIAISON GROUPE - ÉLÈVES
CREATE TABLE IF NOT EXISTS groupe_eleves (
    id_groupe UUID REFERENCES groupes(id_groupe) ON DELETE CASCADE,
    id_eleve UUID REFERENCES eleves(id_eleve) ON DELETE CASCADE,
    date_inscription TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_groupe, id_eleve)
);

CREATE INDEX IF NOT EXISTS idx_groupe_eleves_eleve ON groupe_eleves (id_eleve);

-- Migration colonnes pour les séances de groupe
ALTER TABLE seances ADD COLUMN IF NOT EXISTS id_groupe UUID REFERENCES groupes(id_groupe) ON DELETE SET NULL;
ALTER TABLE seances ADD COLUMN IF NOT EXISTS id_seance_groupe UUID;
CREATE INDEX IF NOT EXISTS idx_seances_id_groupe ON seances (id_groupe);
CREATE INDEX IF NOT EXISTS idx_seances_id_seance_groupe ON seances (id_seance_groupe);
