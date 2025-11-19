-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 SYSTÈME DE MATCHMAKING ET LOBBYS
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔍 TROUVER OU CRÉER UN LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function FindOrCreateLobby()
    LogServer("INFO", "Recherche d'un lobby disponible...")
    
    -- Chercher un lobby non complet et non en jeu
    for lobbyId, lobby in pairs(ServerData.Lobbies) do
        if #lobby.players < Config.Game.PlayersPerLobby and not lobby.inGame then
            LogServer("INFO", "Lobby disponible trouvé: " .. lobbyId)
            return lobbyId
        end
    end
    
    -- Aucun lobby trouvé, en créer un nouveau
    LogServer("INFO", "Aucun lobby disponible, création d'un nouveau...")
    return CreateNewLobby()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ➕ CRÉER UN NOUVEAU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function CreateNewLobby()
    local lobbyId = GenerateUniqueId()
    local bucket = GetAvailableBucket()
    
    if not bucket then
        LogServer("ERROR", "Impossible d'obtenir un bucket disponible")
        return nil
    end
    
    LogServer("INFO", "Création du lobby " .. lobbyId .. " avec le bucket " .. bucket)
    
    ServerData.Lobbies[lobbyId] = {
        id = lobbyId,
        players = {},
        bucket = bucket,
        inGame = false,
        createdAt = os.time(),
        teams = {
            Blue = {},
            Red = {}
        }
    }
    
    LogServer("INFO", "Lobby " .. lobbyId .. " créé avec succès")
    
    return lobbyId
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 👤 AJOUTER UN JOUEUR AU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function AddPlayerToLobby(source, lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("ERROR", "Lobby introuvable: " .. lobbyId)
        return
    end
    
    -- Vérifier que le lobby n'est pas complet
    if #lobby.players >= Config.Game.PlayersPerLobby then
        LogServer("WARN", "Lobby complet: " .. lobbyId)
        NotifyPlayer(source, Config.Messages.LobbyFull, "error")
        return
    end
    
    local identifier = GetPlayerIdentifier(source)
    local playerName = GetPlayerName(source)
    
    LogServer("INFO", string.format("Ajout du joueur %d (%s) au lobby %s", source, playerName, lobbyId))
    
    -- Créer les données du joueur
    local playerData = {
        source = source,
        identifier = identifier,
        name = playerName,
        team = nil, -- Sera défini par le joueur
        isReady = false
    }
    
    -- Ajouter aux joueurs du lobby
    table.insert(lobby.players, playerData)
    
    -- Enregistrer l'association
    ServerData.PlayerLobbies[source] = lobbyId
    
    -- Placer le joueur dans le routing bucket
    SetPlayerBucket(source, lobby.bucket)
    
    -- Téléporter le joueur dans la salle d'attente
    TriggerClientEvent('scharman:client:joinWaitingRoom', source, lobbyId, lobby.bucket)
    
    -- Notifier tous les joueurs du lobby
    local message = string.format("%s a rejoint le lobby (%d/%d)", playerName, #lobby.players, Config.Game.PlayersPerLobby)
    NotifyLobbyPlayers(lobbyId, message, "info")
    
    -- Broadcast les données du lobby
    BroadcastLobbyData(lobbyId)
    
    LogServer("INFO", string.format("Joueur %d ajouté au lobby %s (total: %d/%d)", 
        source, lobbyId, #lobby.players, Config.Game.PlayersPerLobby))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 👋 RETIRER UN JOUEUR DU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function HandlePlayerLeaveLobby(source, lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("WARN", "Lobby introuvable: " .. lobbyId)
        return
    end
    
    local playerName = GetPlayerName(source)
    
    LogServer("INFO", string.format("Retrait du joueur %d (%s) du lobby %s", source, playerName, lobbyId))
    
    -- Retirer le joueur du lobby
    for i, playerData in ipairs(lobby.players) do
        if playerData.source == source then
            -- Retirer de l'équipe si assigné
            if playerData.team then
                RemoveFromTable(lobby.teams[playerData.team], source)
            end
            
            -- Retirer de la liste
            table.remove(lobby.players, i)
            break
        end
    end
    
    -- Retirer l'association
    ServerData.PlayerLobbies[source] = nil
    
    -- Remettre le joueur dans le bucket 0
    SetPlayerBucket(source, 0)
    
    -- Téléporter le joueur
    if IsPlayerConnected(source) then
        TriggerClientEvent('scharman:client:leaveWaitingRoom', source)
    end
    
    -- Notifier les autres joueurs
    if #lobby.players > 0 then
        local message = string.format("%s a quitté le lobby (%d/%d)", playerName, #lobby.players, Config.Game.PlayersPerLobby)
        NotifyLobbyPlayers(lobbyId, message, "warn")
        
        -- Broadcast les données mises à jour
        BroadcastLobbyData(lobbyId)
    else
        -- Lobby vide, le supprimer
        DeleteLobby(lobbyId)
    end
    
    LogServer("INFO", string.format("Joueur %d retiré du lobby %s", source, lobbyId))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎨 GESTION DES ÉQUIPES
-- ════════════════════════════════════════════════════════════════════════════════

function ChangePlayerTeam(source, lobbyId, newTeam)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("ERROR", "Lobby introuvable: " .. lobbyId)
        return
    end
    
    if lobby.inGame then
        LogServer("WARN", "Impossible de changer d'équipe pendant une partie")
        NotifyPlayer(source, "Impossible de changer d'équipe pendant une partie", "error")
        return
    end
    
    LogServer("INFO", string.format("Changement d'équipe pour le joueur %d: %s", source, newTeam))
    
    -- Trouver le joueur
    local playerData = GetPlayerDataInLobby(source, lobbyId)
    
    if not playerData then
        LogServer("ERROR", "Joueur introuvable dans le lobby")
        return
    end
    
    -- Vérifier que l'équipe n'est pas complète
    if #lobby.teams[newTeam] >= Config.Game.PlayersPerTeam then
        LogServer("WARN", "Équipe complète: " .. newTeam)
        NotifyPlayer(source, "Cette équipe est complète", "error")
        return
    end
    
    -- Retirer de l'ancienne équipe si nécessaire
    if playerData.team then
        RemoveFromTable(lobby.teams[playerData.team], source)
        LogServer("DEBUG", string.format("Joueur retiré de l'équipe %s", playerData.team))
    end
    
    -- Ajouter à la nouvelle équipe
    playerData.team = newTeam
    table.insert(lobby.teams[newTeam], source)
    
    -- Marquer comme non prêt
    playerData.isReady = false
    
    -- Notifier le client
    TriggerClientEvent('scharman:client:teamChanged', source, newTeam)
    TriggerClientEvent('scharman:client:readyStatusChanged', source, false)
    
    -- Broadcast les données du lobby
    BroadcastLobbyData(lobbyId)
    
    LogServer("INFO", string.format("Joueur %d changé vers l'équipe %s", source, newTeam))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ✅ GESTION DU STATUT PRÊT
-- ════════════════════════════════════════════════════════════════════════════════

function TogglePlayerReady(source, lobbyId, isReady)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("ERROR", "Lobby introuvable: " .. lobbyId)
        return
    end
    
    if lobby.inGame then
        LogServer("WARN", "Impossible de changer l'état pendant une partie")
        return
    end
    
    LogServer("INFO", string.format("Changement d'état prêt pour le joueur %d: %s", source, tostring(isReady)))
    
    -- Trouver le joueur
    local playerData = GetPlayerDataInLobby(source, lobbyId)
    
    if not playerData then
        LogServer("ERROR", "Joueur introuvable dans le lobby")
        return
    end
    
    -- Vérifier que le joueur a une équipe
    if not playerData.team then
        LogServer("WARN", "Le joueur doit choisir une équipe avant de se mettre prêt")
        NotifyPlayer(source, "Vous devez d'abord choisir une équipe", "error")
        return
    end
    
    -- Mettre à jour l'état
    playerData.isReady = isReady
    
    -- Notifier le client
    TriggerClientEvent('scharman:client:readyStatusChanged', source, isReady)
    
    -- Broadcast les données du lobby
    BroadcastLobbyData(lobbyId)
    
    -- Vérifier si tous les joueurs sont prêts
    CheckIfReadyToStart(lobbyId)
    
    LogServer("INFO", string.format("État prêt du joueur %d mis à jour: %s", source, tostring(isReady)))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 VÉRIFIER SI PRÊT À DÉMARRER
-- ════════════════════════════════════════════════════════════════════════════════

function CheckIfReadyToStart(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    -- Vérifier qu'il y a 4 joueurs
    if #lobby.players < Config.Game.PlayersPerLobby then
        local message = string.format(Config.Messages.WaitingForPlayers, #lobby.players)
        NotifyLobbyPlayers(lobbyId, message, "info")
        return
    end
    
    -- Vérifier que tous les joueurs ont une équipe
    for _, playerData in ipairs(lobby.players) do
        if not playerData.team then
            return
        end
    end
    
    -- Vérifier que les équipes sont équilibrées (2v2)
    if #lobby.teams.Blue ~= Config.Game.PlayersPerTeam or #lobby.teams.Red ~= Config.Game.PlayersPerTeam then
        return
    end
    
    -- Vérifier que tous les joueurs sont prêts
    for _, playerData in ipairs(lobby.players) do
        if not playerData.isReady then
            return
        end
    end
    
    LogServer("INFO", "Tous les joueurs sont prêts! Démarrage de la partie pour le lobby " .. lobbyId)
    
    -- Notifier tous les joueurs
    NotifyLobbyPlayers(lobbyId, Config.Messages.AllPlayersReady, "success")
    
    -- Attendre 3 secondes avant de démarrer
    Citizen.SetTimeout(3000, function()
        StartGame(lobbyId)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 📡 COMMUNICATION AVEC LES CLIENTS
-- ════════════════════════════════════════════════════════════════════════════════

function BroadcastLobbyData(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    -- Préparer les données à envoyer
    local lobbyData = {
        id = lobbyId,
        playerCount = #lobby.players,
        maxPlayers = Config.Game.PlayersPerLobby,
        players = {},
        teams = {
            Blue = {},
            Red = {}
        }
    }
    
    -- Ajouter les infos des joueurs
    for _, playerData in ipairs(lobby.players) do
        table.insert(lobbyData.players, {
            source = playerData.source,
            name = playerData.name,
            team = playerData.team,
            isReady = playerData.isReady
        })
        
        if playerData.team then
            table.insert(lobbyData.teams[playerData.team], {
                source = playerData.source,
                name = playerData.name,
                isReady = playerData.isReady
            })
        end
    end
    
    -- Envoyer aux joueurs du lobby
    for _, playerData in ipairs(lobby.players) do
        if IsPlayerConnected(playerData.source) then
            TriggerClientEvent('scharman:client:receiveLobbyData', playerData.source, lobbyData)
        end
    end
    
    LogServer("DEBUG", "Données du lobby " .. lobbyId .. " broadcastées")
end

function SendLobbyDataToPlayer(source, lobbyId)
    -- Juste re-broadcast pour ce joueur
    BroadcastLobbyData(lobbyId)
end

function NotifyLobbyPlayers(lobbyId, message, type)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    for _, playerData in ipairs(lobby.players) do
        if IsPlayerConnected(playerData.source) then
            NotifyPlayer(playerData.source, message, type)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE
-- ════════════════════════════════════════════════════════════════════════════════

function DeleteLobby(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    LogServer("INFO", "Suppression du lobby " .. lobbyId)
    
    -- Libérer le bucket
    if lobby.bucket then
        ReleaseBucket(lobby.bucket)
    end
    
    -- Supprimer le lobby
    ServerData.Lobbies[lobbyId] = nil
    
    LogServer("INFO", "Lobby " .. lobbyId .. " supprimé")
end

function CleanupEmptyLobbies()
    for lobbyId, lobby in pairs(ServerData.Lobbies) do
        if #lobby.players == 0 and not lobby.inGame then
            LogServer("DEBUG", "Nettoyage du lobby vide: " .. lobbyId)
            DeleteLobby(lobbyId)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔧 FONCTIONS UTILITAIRES
-- ════════════════════════════════════════════════════════════════════════════════

function GetPlayerDataInLobby(source, lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return nil
    end
    
    for _, playerData in ipairs(lobby.players) do
        if playerData.source == source then
            return playerData
        end
    end
    
    return nil
end

function GetLobbyByPlayer(source)
    local lobbyId = ServerData.PlayerLobbies[source]
    return ServerData.Lobbies[lobbyId]
end

LogServer("INFO", "Module Matchmaking chargé")
