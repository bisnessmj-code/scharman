Config = {}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 CONFIGURATION GÉNÉRALE
-- ════════════════════════════════════════════════════════════════════════════════

-- Système de debug/logs
Config.Debug = true -- Active les logs détaillés partout
Config.LogPrefix = "^3[SCHARMAN]^7" -- Préfixe des logs

-- Nom du script (pour les logs et l'UI)
Config.ScriptName = "Scharman"

-- ════════════════════════════════════════════════════════════════════════════════
-- 👤 CONFIGURATION DU PED D'INTERACTION
-- ════════════════════════════════════════════════════════════════════════════════

Config.Ped = {
    Model = "a_m_y_business_03", -- Modèle du PED
    Coords = vector4(-270.0, -957.0, 31.2, 206.0), -- Position (x, y, z, heading)
    Scenario = "WORLD_HUMAN_CLIPBOARD", -- Animation du PED
    Invincible = true, -- Invincibilité
    Freeze = true, -- Bloquer les déplacements
    
    -- Interaction
    InteractionDistance = 2.5, -- Distance d'interaction (mètres)
    InteractionKey = 38, -- Touche E (38 = E)
    InteractionText = "Appuyez sur ~INPUT_CONTEXT~ pour accéder à ~b~Scharman~s~",
    
    -- Blip sur la carte
    Blip = {
        Enable = true,
        Sprite = 315, -- Icône
        Color = 3, -- Couleur (3 = Bleu)
        Scale = 0.8,
        Label = "Scharman - Course-poursuite 2v2"
    }
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏠 CONFIGURATION DES SALLES D'ATTENTE
-- ════════════════════════════════════════════════════════════════════════════════

Config.WaitingRoom = {
    -- Position de la salle d'attente
    Coords = vector4(752.89, -1799.57, 29.55, 0.0), -- Sous-sol de Maze Bank Arena
    
    -- Touche pour ouvrir l'interface du lobby
    LobbyMenuKey = 288, -- F1 (288 = F1)
    LobbyMenuText = "Appuyez sur ~INPUT_FRONTEND_DOWN~ pour gérer votre équipe",
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 CONFIGURATION DU JEU (ROUNDS & GAMEPLAY)
-- ════════════════════════════════════════════════════════════════════════════════

Config.Game = {
    -- Format de la partie
    MaxRounds = 3, -- Best of 3 (premier à 2 manches)
    PlayersPerLobby = 4, -- 2v2 = 4 joueurs
    PlayersPerTeam = 2,
    
    -- Timers
    CountdownBeforeStart = 5, -- Compte à rebours avant départ (secondes)
    TimeToFindPosition = 60, -- Temps pour l'équipe suivie de trouver sa position (secondes)
    RespawnDelay = 3, -- Délai avant respawn pour la manche suivante (secondes)
    
    -- Zone de combat
    CombatZone = {
        Radius = 50.0, -- Rayon de la zone (mètres)
        Height = 100.0, -- Hauteur du cylindre (mètres)
        Color = {r = 255, g = 0, b = 0, a = 100}, -- Couleur RGBA de la zone
        
        -- Blip
        Blip = {
            Sprite = 1, -- Icône du blip
            Color = 1, -- Rouge
            Scale = 1.2,
            Label = "Zone de combat"
        },
        
        -- Marker
        Marker = {
            Type = 1, -- Type de marker (cylindre vertical)
            Color = {r = 255, g = 0, b = 0, a = 100}
        }
    }
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏁 POSITIONS DE SPAWN DES VÉHICULES
-- ════════════════════════════════════════════════════════════════════════════════

Config.VehicleSpawns = {
    -- Véhicule de l'équipe SUIVIE (devant)
    Chased = {
        Coords = vector4(200.0, -1000.0, 29.0, 90.0), -- Position de spawn
        Offset = vector3(0.0, 5.0, 0.0) -- Décalage relatif
    },
    
    -- Véhicule de l'équipe CHASSEUSE (derrière)
    Chaser = {
        Coords = vector4(180.0, -1000.0, 29.0, 90.0), -- Position de spawn
        Offset = vector3(0.0, -10.0, 0.0) -- Décalage relatif (derrière)
    }
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚗 CONFIGURATION DES VÉHICULES
-- ════════════════════════════════════════════════════════════════════════════════

Config.Vehicles = {
    -- Modèle de véhicule utilisé
    Model = "sultan2", -- Sultan RS Classic (sportive équilibrée)
    
    -- Couleurs des équipes
    TeamColors = {
        Blue = {
            Primary = 64, -- Bleu foncé
            Secondary = 64
        },
        Red = {
            Primary = 27, -- Rouge
            Secondary = 27
        }
    },
    
    -- Modifications du véhicule
    Mods = {
        Engine = 3, -- Niveau moteur (0-4, -1 = stock)
        Brakes = 2,
        Transmission = 2,
        Turbo = true,
        Armor = 3
    },
    
    -- Verrouillage
    Locked = false, -- Véhicule verrouillé ou non
    
    -- Restrictions
    DisableShooting = true -- Désactiver le tir depuis le véhicule (drive-by)
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔫 CONFIGURATION DES ARMES
-- ════════════════════════════════════════════════════════════════════════════════

Config.Weapons = {
    -- Arme donnée lors du combat
    Default = {
        Name = "WEAPON_HEAVYSNIPER", -- Fusil de précision lourd (CAL.50)
        Ammo = 50, -- Munitions
        Components = { -- Composants de l'arme
            "COMPONENT_AT_SCOPE_MAX" -- Lunette
        }
    },
    
    -- Retirer toutes les armes avant de donner celle du jeu
    RemoveAllWeapons = true
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 👥 CONFIGURATION DES ÉQUIPES
-- ════════════════════════════════════════════════════════════════════════════════

Config.Teams = {
    Blue = {
        Name = "Équipe Bleue",
        Color = "^4", -- Couleur du texte (^4 = bleu)
        ColorRGB = {r = 0, g = 100, b = 255}, -- RGB pour les blips/markers
        ColorCode = "#0064FF" -- HEX pour l'UI
    },
    Red = {
        Name = "Équipe Rouge",
        Color = "^1", -- Couleur du texte (^1 = rouge)
        ColorRGB = {r = 255, g = 0, b = 0}, -- RGB pour les blips/markers
        ColorCode = "#FF0000" -- HEX pour l'UI
    }
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 💾 CONFIGURATION DE LA BASE DE DONNÉES
-- ════════════════════════════════════════════════════════════════════════════════

Config.Database = {
    -- Type d'identifiant utilisé
    IdentifierType = "license", -- "license", "steam", "fivem", etc.
    
    -- Nom de la table
    TableName = "scharman_stats",
    
    -- Créer automatiquement la table si elle n'existe pas
    AutoCreateTable = true
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 📊 CONFIGURATION DES STATISTIQUES
-- ════════════════════════════════════════════════════════════════════════════════

Config.Stats = {
    -- Stats personnelles sauvegardées
    TrackedStats = {
        "matches_played", -- Parties jouées
        "rounds_won", -- Manches gagnées
        "rounds_lost", -- Manches perdues
        "kills", -- Kills
        "deaths", -- Morts
        "playtime" -- Temps de jeu (secondes)
    },
    
    -- Calculs automatiques
    CalculateWinrate = true, -- Calculer le winrate automatiquement
    
    -- Stats globales quotidiennes
    DailyGlobalStats = true -- Activer les stats globales quotidiennes
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎨 CONFIGURATION DE L'INTERFACE (NUI)
-- ════════════════════════════════════════════════════════════════════════════════

Config.UI = {
    -- Titre de l'interface
    Title = "Scharman - Course-poursuite 2v2",
    
    -- Thème de couleurs
    Theme = {
        Primary = "#0064FF", -- Bleu
        Secondary = "#FF0000", -- Rouge
        Success = "#00FF00", -- Vert
        Warning = "#FFA500", -- Orange
        Danger = "#FF0000", -- Rouge
        Dark = "#1a1a1a",
        Light = "#ffffff"
    },
    
    -- Onglets disponibles
    Tabs = {
        "stats", -- Stats personnelles
        "global", -- Stats globales
        "lobby" -- Rejoindre la salle d'attente
    }
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔧 CONFIGURATION AVANCÉE
-- ════════════════════════════════════════════════════════════════════════════════

Config.Advanced = {
    -- Routing buckets
    StartingBucket = 1000, -- Premier bucket disponible pour les lobbys
    MaxLobbies = 50, -- Nombre maximum de lobbys simultanés
    
    -- Nettoyage automatique
    CleanupVehicles = true, -- Supprimer les véhicules après chaque manche
    CleanupDelay = 2, -- Délai avant nettoyage (secondes)
    
    -- Restrictions gameplay
    DisableWeaponsInVehicle = true, -- Désactiver armes en véhicule
    DisableExitVehicleForChaser = true, -- Empêcher équipe chasseuse de sortir avant validation
    
    -- Performance
    ReduceThreadLoad = true, -- Optimiser les threads
    UpdateRate = 500 -- Taux de rafraîchissement des threads (ms)
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 📝 MESSAGES & NOTIFICATIONS
-- ════════════════════════════════════════════════════════════════════════════════

Config.Messages = {
    -- Lobby
    JoinedWaitingRoom = "Vous avez rejoint la ~b~salle d'attente~s~.",
    LeftWaitingRoom = "Vous avez quitté la salle d'attente.",
    TeamChanged = "Vous avez changé d'équipe : %s",
    ReadyStatusChanged = "Statut : %s",
    WaitingForPlayers = "En attente de joueurs... (%d/4)",
    AllPlayersReady = "Tous les joueurs sont prêts ! Lancement de la partie...",
    
    -- Jeu
    GameStarting = "La partie commence !",
    CountdownStart = "Départ dans %d secondes...",
    RoundStart = "Manche %d - GO !",
    TimeToFind = "Temps restant pour trouver une position : %d secondes",
    TimeExpired = "Temps écoulé ! L'équipe %s remporte la manche.",
    PositionValidated = "Position validée ! L'équipe %s doit vous retrouver.",
    RoundWon = "L'équipe %s remporte la manche !",
    GameWon = "L'équipe %s remporte la partie !",
    
    -- Erreurs
    LobbyFull = "Le lobby est complet.",
    NotEnoughPlayers = "Pas assez de joueurs.",
    AlreadyInGame = "Vous êtes déjà en partie.",
    
    -- Stats
    StatsUpdated = "Vos statistiques ont été mises à jour.",
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎵 SONS (Optionnel)
-- ════════════════════════════════════════════════════════════════════════════════

Config.Sounds = {
    Enable = false, -- Activer les sons
    Countdown = "5_SEC_WARNING", -- Son du compte à rebours
    RoundStart = "SELECT", -- Son de début de manche
    RoundEnd = "CHECKPOINT_PERFECT", -- Son de fin de manche
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🛡️ PERMISSIONS (Optionnel - pour restrictin d'accès)
-- ════════════════════════════════════════════════════════════════════════════════

Config.Permissions = {
    Enable = false, -- Activer le système de permissions
    Groups = {"admin", "moderator"}, -- Groupes autorisés (si framework compatible)
}
