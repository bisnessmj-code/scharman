# 🎮 Scharman - Course-poursuite 2v2 pour FiveM

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-green.svg)
![Lua](https://img.shields.io/badge/Lua-5.4-yellow.svg)

> **Script FiveM hautement configurable et optimisé pour des parties de course-poursuite 2v2 en instance**

---

## 📋 Table des Matières

- [Présentation](#-présentation)
- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Architecture](#-architecture)
- [Utilisation](#-utilisation)
- [Système de Jeu](#-système-de-jeu)
- [Base de Données](#️-base-de-données)
- [Logs & Debug](#-logs--debug)
- [Performance](#-performance)
- [FAQ](#-faq)
- [Support](#-support)

---

## 🎯 Présentation

**Scharman** est un mini-jeu de course-poursuite 2v2 pour FiveM, développé avec une architecture modulaire, des performances optimisées et un système de configuration ultra-complet. Les joueurs s'affrontent en équipes dans des manches alternées où l'une des équipes fuit et l'autre poursuit.

### Concept du Jeu

1. **Phase de Fuite** : L'équipe "suivie" doit trouver une position stratégique dans un temps limité
2. **Phase de Combat** : L'équipe "chasseuse" doit retrouver et éliminer l'équipe adverse dans la zone établie
3. **Alternance** : Les rôles s'inversent à chaque manche
4. **Victoire** : Première équipe à gagner 2 manches sur 3 (Best of 3)

---

## ✨ Fonctionnalités

### 🎮 Gameplay

- ✅ **Système de lobby 2v2** avec gestion automatique du matchmaking
- ✅ **Routing buckets** pour isoler chaque partie
- ✅ **Alternance des rôles** chasseur/chassé à chaque manche
- ✅ **Timer pour la phase de fuite** (configurable)
- ✅ **Zone de combat dynamique** avec markers visuels et blips
- ✅ **Compte à rebours** avant chaque manche
- ✅ **Système de respawn** automatique entre les manches
- ✅ **Restrictions véhicule** (pas de tir en voiture, sortie contrôlée)

### 🎨 Interface NUI

- ✅ **Interface principale** avec statistiques personnelles et globales
- ✅ **Interface de lobby** pour choisir son équipe et se mettre prêt
- ✅ **Design moderne** et responsive
- ✅ **Animations fluides** et transitions

### 📊 Statistiques

- ✅ **Stats personnelles** : parties jouées, manches gagnées/perdues, kills, morts, temps de jeu, winrate
- ✅ **Stats globales quotidiennes** : parties totales, manches, kills, joueurs uniques
- ✅ **Persistance en base de données** MySQL/oxmysql
- ✅ **Calcul automatique du winrate et K/D**

### 🔧 Configuration

- ✅ **Fichier config.lua ultra-complet** : positions, véhicules, armes, timers, couleurs, etc.
- ✅ **Aucun hardcode** dans le code principal
- ✅ **Modification sans redémarrage** (certains paramètres)

### 📝 Logs & Debug

- ✅ **Système de logs détaillés** à chaque étape critique
- ✅ **Mode debug activable** dans la configuration
- ✅ **Logs préfixés et colorés** pour une lecture facile
- ✅ **Commandes de debug** pour les développeurs

### ⚡ Performance

- ✅ **Architecture optimisée** sans boucles inutiles
- ✅ **Events plutôt que threads constants**
- ✅ **Nettoyage automatique** des entités et buckets
- ✅ **Taux de rafraîchissement configurable**

---

## 📦 Prérequis

- **Serveur FiveM** (dernière version recommandée)
- **oxmysql** : Ressource pour la gestion de la base de données MySQL
- **MySQL/MariaDB** : Base de données pour la persistance des stats

---

## 🚀 Installation

### 1. Téléchargement

Placez le dossier `scharman` dans votre répertoire `resources` de votre serveur FiveM.

```
📂 resources/
  └── 📂 [local]/
      └── 📂 scharman/
```

### 2. Configuration du server.cfg

Ajoutez ces lignes dans votre `server.cfg` :

```cfg
# Assurez-vous que oxmysql est démarré AVANT scharman
ensure oxmysql

# Démarrer le script Scharman
ensure scharman
```

### 3. Base de Données

Le script créera automatiquement les tables nécessaires au premier démarrage si `Config.Database.AutoCreateTable` est activé (par défaut).

Sinon, vous pouvez exécuter manuellement ce SQL :

```sql
CREATE TABLE IF NOT EXISTS scharman_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(100) NOT NULL UNIQUE,
    player_name VARCHAR(255) DEFAULT 'Inconnu',
    matches_played INT DEFAULT 0,
    rounds_won INT DEFAULT 0,
    rounds_lost INT DEFAULT 0,
    kills INT DEFAULT 0,
    deaths INT DEFAULT 0,
    playtime INT DEFAULT 0,
    first_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_identifier (identifier),
    INDEX idx_rounds_won (rounds_won),
    INDEX idx_kills (kills)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS scharman_daily_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stat_date DATE NOT NULL UNIQUE,
    total_matches INT DEFAULT 0,
    total_rounds INT DEFAULT 0,
    total_kills INT DEFAULT 0,
    unique_players INT DEFAULT 0,
    INDEX idx_stat_date (stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4. Vérification

Redémarrez votre serveur et vérifiez les logs. Vous devriez voir :

```
[SCHARMAN] [INFO] ════════════════════════════════════════════════════════
[SCHARMAN] [INFO]   Scharman - Course-poursuite 2v2
[SCHARMAN] [INFO]   Version 1.0.0
[SCHARMAN] [INFO] ════════════════════════════════════════════════════════
```

---

## ⚙️ Configuration

Ouvrez le fichier `config.lua` pour personnaliser le script.

### 🎯 Configuration Essentielle

```lua
-- Activer/désactiver les logs détaillés
Config.Debug = true

-- Position du PED d'interaction
Config.Ped.Coords = vector4(-270.0, -957.0, 31.2, 206.0)

-- Position de la salle d'attente
Config.WaitingRoom.Coords = vector4(752.89, -1799.57, 29.55, 0.0)

-- Timers du jeu
Config.Game.CountdownBeforeStart = 5      -- Compte à rebours
Config.Game.TimeToFindPosition = 60       -- Temps pour trouver position
Config.Game.MaxRounds = 3                 -- Best of 3

-- Véhicules
Config.Vehicles.Model = "sultan2"         -- Modèle de véhicule

-- Armes
Config.Weapons.Default.Name = "WEAPON_HEAVYSNIPER"
Config.Weapons.Default.Ammo = 50
```

### 📍 Positions de Spawn

Les positions de spawn des véhicules doivent être modifiées selon votre map :

```lua
Config.VehicleSpawns = {
    Chased = {
        Coords = vector4(200.0, -1000.0, 29.0, 90.0),
    },
    Chaser = {
        Coords = vector4(180.0, -1000.0, 29.0, 90.0),
    }
}
```

### 🎨 Personnalisation Visuelle

```lua
-- Couleurs des équipes
Config.Teams.Blue.ColorCode = "#0064FF"
Config.Teams.Red.ColorCode = "#FF0000"

-- Thème de l'interface
Config.UI.Theme.Primary = "#0064FF"
Config.UI.Theme.Secondary = "#FF0000"
```

---

## 🏗️ Architecture

```
scharman/
├── fxmanifest.lua          # Manifest du script
├── config.lua              # Configuration complète
│
├── client/                 # Scripts côté client
│   ├── main.lua           # Point d'entrée client
│   ├── utils.lua          # Fonctions utilitaires
│   ├── ped.lua            # Gestion du PED d'interaction
│   ├── ui.lua             # Gestion de l'interface principale
│   ├── lobby.lua          # Gestion du lobby
│   └── game.lua           # Logique de jeu en partie
│
├── server/                # Scripts côté serveur
│   ├── main.lua          # Point d'entrée serveur
│   ├── utils.lua         # Fonctions utilitaires
│   ├── stats.lua         # Gestion des stats et BDD
│   ├── matchmaking.lua   # Gestion des lobbys
│   └── game.lua          # Logique de jeu serveur
│
└── html/                 # Interface NUI
    ├── index.html       # Structure HTML
    ├── style.css        # Styles CSS
    └── script.js        # Logique JavaScript
```

---

## 🎮 Utilisation

### Pour les Joueurs

1. **Se rendre au PED** indiqué sur la carte (blip configuré)
2. **Appuyer sur E** près du PED pour ouvrir l'interface
3. **Consulter ses stats** dans l'onglet "Mes Stats"
4. **Rejoindre une partie** via l'onglet "Rejoindre"
5. **Choisir son équipe** (Bleue ou Rouge) dans le lobby
6. **Se mettre prêt** une fois l'équipe choisie
7. **Attendre** que 4 joueurs soient prêts
8. **Jouer !** 🎮

### Commandes (Debug)

Si le mode debug est activé :

```
/scharman_debug         # Afficher l'état actuel du client
/scharman_leave         # Forcer la sortie du lobby
/scharman_tp_ped        # Téléporter au PED
/scharman_lobbies       # [ADMIN] Voir tous les lobbys actifs
/scharman_force_start   # Forcer le démarrage d'une partie
```

---

## 🎲 Système de Jeu

### Déroulement d'une Partie

#### 1️⃣ Lobby (Salle d'Attente)

- Les joueurs rejoignent un lobby (max 4 joueurs)
- Chacun choisit son équipe (Bleue ou Rouge, 2 par équipe)
- Une fois 4 joueurs prêts, la partie démarre

#### 2️⃣ Spawn et Compte à Rebours

- Les 2 équipes spawn dans leurs véhicules
- Équipe "suivie" devant, équipe "chasseuse" derrière
- Compte à rebours de 5 secondes (véhicules freeze)

#### 3️⃣ Phase de Fuite

- L'équipe suivie a 60 secondes pour trouver une position
- Le **conducteur** doit descendre du véhicule pour valider
- Si le temps expire : l'équipe chasseuse gagne la manche

#### 4️⃣ Phase de Combat

- Une zone de combat apparaît autour de la position validée
- GPS créé pour l'équipe chasseuse
- Les joueurs reçoivent leurs armes en sortant du véhicule
- Combat jusqu'à élimination d'une équipe

#### 5️⃣ Fin de Manche

- Équipe gagnante annoncée
- Respawn automatique
- **Inversion des rôles** pour la manche suivante

#### 6️⃣ Fin de Partie

- Première équipe à gagner 2 manches remporte la partie
- Stats enregistrées en base de données
- Retour au PED principal

### Restrictions Importantes

- ❌ **Pas de tir depuis le véhicule** (drive-by désactivé)
- ❌ **L'équipe chasseuse ne peut pas sortir** avant que la zone soit créée
- ❌ **Seul le conducteur de l'équipe suivie** peut valider la position
- ✅ **Chaque équipe est dans un routing bucket isolé**

---

## 🗄️ Base de Données

### Table `scharman_stats`

Stocke les statistiques personnelles de chaque joueur.

| Colonne | Type | Description |
|---------|------|-------------|
| `identifier` | VARCHAR(100) | Identifiant unique du joueur |
| `player_name` | VARCHAR(255) | Nom du joueur |
| `matches_played` | INT | Nombre de parties jouées |
| `rounds_won` | INT | Nombre de manches gagnées |
| `rounds_lost` | INT | Nombre de manches perdues |
| `kills` | INT | Nombre de kills |
| `deaths` | INT | Nombre de morts |
| `playtime` | INT | Temps de jeu en secondes |
| `first_played` | TIMESTAMP | Première connexion |
| `last_played` | TIMESTAMP | Dernière connexion |

### Table `scharman_daily_stats`

Stocke les statistiques globales quotidiennes.

| Colonne | Type | Description |
|---------|------|-------------|
| `stat_date` | DATE | Date du jour |
| `total_matches` | INT | Parties totales du jour |
| `total_rounds` | INT | Manches totales du jour |
| `total_kills` | INT | Kills totaux du jour |
| `unique_players` | INT | Joueurs uniques du jour |

---

## 📝 Logs & Debug

### Activation du Mode Debug

Dans `config.lua` :

```lua
Config.Debug = true
```

### Types de Logs

- `[INFO]` : Informations générales (vert)
- `[WARN]` : Avertissements (orange)
- `[ERROR]` : Erreurs critiques (rouge)
- `[DEBUG]` : Debug détaillé (violet, seulement si Config.Debug = true)

### Exemples de Logs

```
[SCHARMAN] [INFO] Joueur 1 ajouté au lobby abc123 (total: 2/4)
[SCHARMAN] [DEBUG] Bucket 1000 réservé
[SCHARMAN] [INFO] ═══════════════════════════════════════════════════════
[SCHARMAN] [INFO]   DÉMARRAGE DE LA PARTIE - Lobby: abc123
[SCHARMAN] [INFO] ═══════════════════════════════════════════════════════
```

---

## ⚡ Performance

### Optimisations Implémentées

1. **Threads Optimisés**
   - Pas de boucles infinies inutiles
   - Taux de rafraîchissement adaptatif (500ms par défaut)
   - Threads stoppés quand non nécessaires

2. **Events au Lieu de Loops**
   - Système événementiel plutôt que vérifications constantes
   - Callbacks efficaces

3. **Nettoyage Automatique**
   - Suppression des véhicules après chaque manche
   - Libération des routing buckets
   - Invalidation du cache des stats

4. **Routing Buckets**
   - Isolation des parties pour éviter les interférences
   - Libération automatique après la partie

### Recommandations

- **Joueurs maximum** : 50 lobbys simultanés (200 joueurs)
- **RAM** : ~20MB par lobby actif
- **Charge CPU** : Minimale grâce aux optimisations

---

## ❓ FAQ

### Q: Le PED n'apparaît pas
**R:** Vérifiez que les coordonnées dans `Config.Ped.Coords` sont correctes pour votre map.

### Q: Les joueurs ne peuvent pas rejoindre de lobby
**R:** Vérifiez qu'oxmysql est démarré et que la connexion MySQL fonctionne.

### Q: Les véhicules spawn au mauvais endroit
**R:** Modifiez les coordonnées dans `Config.VehicleSpawns` selon votre map.

### Q: Les stats ne se sauvegardent pas
**R:** Vérifiez que la base de données est accessible et que les tables sont créées.

### Q: Comment changer le nombre de manches ?
**R:** Modifiez `Config.Game.MaxRounds` dans config.lua (3 = Best of 3, 5 = Best of 5, etc.)

### Q: Puis-je utiliser un autre véhicule ?
**R:** Oui, changez `Config.Vehicles.Model` avec n'importe quel spawn code de véhicule GTA V.

### Q: Comment désactiver les logs ?
**R:** Mettez `Config.Debug = false` dans config.lua.

---

## 💡 Bonnes Pratiques 2025

Ce script respecte les bonnes pratiques FiveM modernes :

- ✅ **Lua 5.4** pour de meilleures performances
- ✅ **Architecture modulaire** pour la maintenabilité
- ✅ **Configuration externalisée** sans hardcode
- ✅ **Routing buckets** pour l'isolation
- ✅ **Events optimisés** plutôt que loops
- ✅ **Logs structurés** pour le debug
- ✅ **Code commenté** et lisible
- ✅ **Nettoyage automatique** des ressources
- ✅ **Interface NUI moderne** et responsive
- ✅ **Système de stats persistant**

---

## 🤝 Support

Pour toute question, problème ou suggestion :

1. **Vérifiez les logs** serveur et client
2. **Consultez la FAQ** ci-dessus
3. **Activez le mode debug** pour plus d'informations
4. **Contactez le support** avec les logs pertinents

---

## 📜 Licence

Ce script est fourni tel quel pour un usage personnel ou commercial. Vous êtes libre de le modifier selon vos besoins.

---

## 🎉 Crédits

Développé avec ❤️ pour la communauté FiveM

**Version** : 1.0.0  
**Date** : 2025  
**Auteur** : Scharman Development

---

**Bon jeu ! 🎮**
#   s c h a r m a n  
 