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
    
    -- Initialiser la base de données
    InitializeDatabase()
    
    -- Attendre un peu
    Wait(1000)
    
    LogServer("INFO", "Serveur Scharman initialisé avec succès !")
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
    
    LogServer("INFO", string.format("Joueur %d veut rejoindre un lobby", source))
    
    -- Valider le joueur
    if not ValidatePlayerData(source) then
        return
    end
    
    -- Vérifier que le joueur n'est pas déjà dans un lobby
    if ServerData.PlayerLobbies[source] then
        LogServer("WARN", string.format("Joueur %d est déjà dans un lobby", source))
        NotifyPlayer(source, Config.Messages.AlreadyInGame, "error")
        return
    end
    
    -- Trouver ou créer un lobby
    local lobbyId = FindOrCreateLobby()
    
    if not lobbyId then
        LogServer("ERROR", "Impossible de trouver ou créer un lobby")
        NotifyPlayer(source, "Erreur lors de la recherche d'un lobby", "error")
        return
    end
    
    -- Ajouter le joueur au lobby
    AddPlayerToLobby(source, lobbyId)
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
        GetGlobalStats(function(globalStats)
            -- Envoyer les stats au client
            TriggerClientEvent('scharman:client:receiveStats', source, playerStats, globalStats)
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
        if IsPlayerConnected(source) then
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
        
        for lobbyId, lobby in pairs(ServerData.Lobbies) do
            print(string.format("Lobby %s:", lobbyId))
            print(string.format("  Joueurs: %d/%d", #lobby.players, Config.Game.PlayersPerLobby))
            print(string.format("  Bucket: %d", lobby.bucket))
            print(string.format("  En jeu: %s", tostring(lobby.inGame)))
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
    
    LogServer("DEBUG", "Commandes admin activées: /scharman_lobbies, /scharman_force_start")
end

LogServer("INFO", "Main serveur chargé")
