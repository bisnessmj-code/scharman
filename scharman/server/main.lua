-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 MAIN SERVER - Point d'entrée et variables globales
-- ════════════════════════════════════════════════════════════════════════════════

-- Variables globales du serveur
ServerData = {
    -- Lobbys actifs
    Lobbies = {},
    
    -- Joueurs dans les lobbys (source -> lobbyId)
    PlayerLobbies = {},
    
    -- Parties en cours
    ActiveGames = {},
    
    -- Stats en cache
    StatsCache = {}
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ════════════════════════════════════════════════════════════════════════════════

Citizen.CreateThread(function()
    LogServer("INFO", "════════════════════════════════════════════════════════")
    LogServer("INFO", "  Scharman - Course-poursuite 2v2 [SERVEUR]")
    LogServer("INFO", "  Version 1.0.0")
    LogServer("INFO", "════════════════════════════════════════════════════════")
    
    -- Vérifier que MySQL est disponible
    if not MySQL then
        LogServer("ERROR", "❌ MySQL/oxmysql n'est pas disponible!")
        LogServer("ERROR", "❌ Assurez-vous que oxmysql est démarré AVANT scharman")
        return
    end
    
    LogServer("INFO", "✅ MySQL/oxmysql détecté")
    
    -- Initialiser la base de données
    InitializeDatabase()
    
    -- Attendre un peu
    Wait(1000)
    
    LogServer("INFO", "✅ Serveur Scharman initialisé avec succès !")
    LogServer("INFO", "════════════════════════════════════════════════════════")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 📊 GESTION DES CONNEXIONS/DÉCONNEXIONS
-- ════════════════════════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source
    LogServer("INFO", string.format("Joueur %d déconnecté: %s", source, reason))
    
    -- Vérifier si le joueur était dans un lobby
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if lobbyId then
        LogServer("INFO", string.format("Joueur %d était dans le lobby %s", source, lobbyId))
        HandlePlayerLeaveLobby(source, lobbyId)
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 EVENTS PRINCIPAUX
-- ════════════════════════════════════════════════════════════════════════════════

-- Event : Rejoindre un lobby
RegisterNetEvent('scharman:server:joinLobby', function()
    local source = source
    
    LogServer("INFO", "════════════════════════════════════════════════════════")
    LogServer("INFO", string.format("📥 Joueur %d (%s) veut rejoindre un lobby", source, GetPlayerName(source)))
    LogServer("INFO", "════════════════════════════════════════════════════════")
    
    -- Valider le joueur
    LogServer("DEBUG", "Étape 1: Validation du joueur...")
    if not ValidatePlayerData(source) then
        LogServer("ERROR", "❌ Validation du joueur échouée")
        NotifyPlayer(source, "Erreur: Impossible de valider votre identité", "error")
        return
    end
    LogServer("INFO", "✅ Joueur validé")
    
    -- Vérifier que le joueur n'est pas déjà dans un lobby
    LogServer("DEBUG", "Étape 2: Vérification du statut du lobby...")
    if ServerData.PlayerLobbies[source] then
        LogServer("WARN", string.format("❌ Joueur %d est déjà dans un lobby", source))
        NotifyPlayer(source, Config.Messages.AlreadyInGame, "error")
        return
    end
    LogServer("INFO", "✅ Joueur pas encore dans un lobby")
    
    -- Trouver ou créer un lobby
    LogServer("DEBUG", "Étape 3: Recherche ou création d'un lobby...")
    local lobbyId = FindOrCreateLobby()
    
    if not lobbyId then
        LogServer("ERROR", "❌ Impossible de trouver ou créer un lobby")
        NotifyPlayer(source, "Erreur: Aucun lobby disponible. Réessayez dans quelques instants.", "error")
        return
    end
    LogServer("INFO", "✅ Lobby trouvé/créé: " .. lobbyId)
    
    -- Ajouter le joueur au lobby
    LogServer("DEBUG", "Étape 4: Ajout du joueur au lobby...")
    AddPlayerToLobby(source, lobbyId)
    LogServer("INFO", "✅ Joueur ajouté au lobby avec succès!")
    LogServer("INFO", "════════════════════════════════════════════════════════")
end)

-- Event : Quitter un lobby
RegisterNetEvent('scharman:server:leaveLobby', function()
    local source = source
    
    LogServer("INFO", string.format("Joueur %d veut quitter le lobby", source))
    
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if not lobbyId then
        LogServer("WARN", string.format("Joueur %d n'est pas dans un lobby", source))
        return
    end
    
    HandlePlayerLeaveLobby(source, lobbyId)
end)

-- Event : Changer d'équipe
RegisterNetEvent('scharman:server:changeTeam', function(team)
    local source = source
    
    LogServer("INFO", string.format("Joueur %d veut changer d'équipe: %s", source, team))
    
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if not lobbyId then
        LogServer("WARN", string.format("Joueur %d n'est pas dans un lobby", source))
        return
    end
    
    ChangePlayerTeam(source, lobbyId, team)
end)

-- Event : Changer l'état de prêt
RegisterNetEvent('scharman:server:toggleReady', function(isReady)
    local source = source
    
    LogServer("INFO", string.format("Joueur %d change son état: %s", source, tostring(isReady)))
    
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if not lobbyId then
        LogServer("WARN", string.format("Joueur %d n'est pas dans un lobby", source))
        return
    end
    
    TogglePlayerReady(source, lobbyId, isReady)
end)

-- Event : Demander les données du lobby
RegisterNetEvent('scharman:server:requestLobbyData', function()
    local source = source
    
    LogServer("DEBUG", string.format("Joueur %d demande les données du lobby", source))
    
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if not lobbyId then
        LogServer("WARN", string.format("Joueur %d n'est pas dans un lobby", source))
        return
    end
    
    SendLobbyDataToPlayer(source, lobbyId)
end)

-- Event : Demander les statistiques
RegisterNetEvent('scharman:server:requestStats', function()
    local source = source
    
    LogServer("DEBUG", string.format("Joueur %d demande ses statistiques", source))
    
    -- Obtenir les stats
    GetPlayerStats(source, function(playerStats)
        if not playerStats then
            LogServer("ERROR", "Impossible de récupérer les stats du joueur " .. source)
            -- Envoyer des stats vides
            playerStats = {
                matches_played = 0,
                rounds_won = 0,
                rounds_lost = 0,
                kills = 0,
                deaths = 0,
                winrate = 0,
                playtime_formatted = "00:00:00"
            }
        end
        
        GetGlobalStats(function(globalStats)
            if not globalStats then
                globalStats = {
                    total_matches = 0,
                    total_rounds = 0,
                    total_kills = 0,
                    unique_players = 0
                }
            end
            
            -- Envoyer les stats au client
            TriggerClientEvent('scharman:client:receiveStats', source, playerStats, globalStats)
            LogServer("DEBUG", "Stats envoyées au joueur " .. source)
        end)
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔄 BOUCLE PRINCIPALE (VÉRIFICATION DES LOBBYS)
-- ════════════════════════════════════════════════════════════════════════════════

Citizen.CreateThread(function()
    while true do
        Wait(5000) -- Vérifier toutes les 5 secondes
        
        -- Nettoyer les lobbys vides
        CleanupEmptyLobbies()
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ════════════════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    LogServer("WARN", "Arrêt du script - Nettoyage...")
    
    -- Libérer tous les buckets
    for lobbyId, lobby in pairs(ServerData.Lobbies) do
        if lobby.bucket then
            ReleaseBucket(lobby.bucket)
        end
    end
    
    -- Téléporter tous les joueurs au PED
    for source, _ in pairs(ServerData.PlayerLobbies) do
        if GetPlayerPing(source) > 0 then
            TriggerClientEvent('scharman:client:leaveWaitingRoom', source)
        end
    end
    
    LogServer("INFO", "Nettoyage terminé")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 COMMANDES ADMIN (DEBUG)
-- ════════════════════════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('scharman_lobbies', function(source)
        print("════════════════════════════════════════════════════════")
        print("DEBUG - Lobbys actifs")
        print("════════════════════════════════════════════════════════")
        
        local lobbyCount = 0
        for lobbyId, lobby in pairs(ServerData.Lobbies) do
            lobbyCount = lobbyCount + 1
            print(string.format("Lobby %s:", lobbyId))
            print(string.format("  Joueurs: %d/%d", #lobby.players, Config.Game.PlayersPerLobby))
            print(string.format("  Bucket: %d", lobby.bucket))
            print(string.format("  En jeu: %s", tostring(lobby.inGame)))
            print("  Joueurs:")
            for _, p in ipairs(lobby.players) do
                print(string.format("    - %s (ID: %d, Team: %s, Ready: %s)", 
                    p.name, p.source, tostring(p.team), tostring(p.isReady)))
            end
        end
        
        if lobbyCount == 0 then
            print("  Aucun lobby actif")
        end
        
        print("════════════════════════════════════════════════════════")
    end, true)
    
    RegisterCommand('scharman_force_start', function(source)
        local lobbyId = ServerData.PlayerLobbies[source]
        
        if lobbyId then
            LogServer("DEBUG", "Forçage du démarrage de la partie pour le lobby " .. lobbyId)
            StartGame(lobbyId)
        else
            print("Vous n'êtes pas dans un lobby")
        end
    end, false)
    
    RegisterCommand('scharman_test_db', function(source)
        LogServer("INFO", "Test de la connexion MySQL...")
        
        MySQL.Async.fetchAll('SELECT 1', {}, function(result)
            if result then
                LogServer("INFO", "✅ Connexion MySQL OK")
                print("✅ La connexion à MySQL fonctionne correctement")
            else
                LogServer("ERROR", "❌ Connexion MySQL échouée")
                print("❌ La connexion à MySQL a échoué")
            end
        end)
    end, true)
    
    LogServer("DEBUG", "Commandes admin activées: /scharman_lobbies, /scharman_force_start, /scharman_test_db")
end

LogServer("INFO", "Main serveur chargé")
