-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 SYSTÈME DE MATCHMAKING ET LOBBYS
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔍 TROUVER OU CRÉER UN LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function FindOrCreateLobby()
    LogServer("INFO", "🔍 Recherche d'un lobby disponible...")
    
    -- Chercher un lobby non complet et non en jeu
    local availableLobbies = 0
    for lobbyId, lobby in pairs(ServerData.Lobbies) do
        availableLobbies = availableLobbies + 1
        LogServer("DEBUG", string.format("  Lobby %s: %d/%d joueurs, en jeu: %s", 
            lobbyId, #lobby.players, Config.Game.PlayersPerLobby, tostring(lobby.inGame)))
        
        if #lobby.players < Config.Game.PlayersPerLobby and not lobby.inGame then
            LogServer("INFO", "✅ Lobby disponible trouvé: " .. lobbyId)
            return lobbyId
        end
    end
    
    LogServer("INFO", string.format("Aucun lobby disponible parmi les %d existants", availableLobbies))
    
    -- Aucun lobby trouvé, en créer un nouveau
    LogServer("INFO", "➕ Création d'un nouveau lobby...")
    return CreateNewLobby()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ➕ CRÉER UN NOUVEAU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function CreateNewLobby()
    local lobbyId = GenerateUniqueId()
    
    LogServer("DEBUG", "Génération de l'ID de lobby: " .. lobbyId)
    
    local bucket = GetAvailableBucket()
    
    if not bucket then
        LogServer("ERROR", "❌ Impossible d'obtenir un bucket disponible")
        LogServer("ERROR", "❌ Nombre maximum de lobbys atteint ou problème de bucket")
        return nil
    end
    
    LogServer("INFO", "✅ Bucket réservé: " .. bucket)
    LogServer("INFO", string.format("Création du lobby %s avec le bucket %d", lobbyId, bucket))
    
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
    
    LogServer("INFO", "✅ Lobby " .. lobbyId .. " créé avec succès")
    LogServer("DEBUG", "Données du lobby: " .. json.encode(ServerData.Lobbies[lobbyId]))
    
    return lobbyId
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 👤 AJOUTER UN JOUEUR AU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function AddPlayerToLobby(source, lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("ERROR", "❌ Lobby introuvable: " .. lobbyId)
        NotifyPlayer(source, "Erreur: Lobby introuvable", "error")
        return false
    end
    
    -- Vérifier que le lobby n'est pas complet
    if #lobby.players >= Config.Game.PlayersPerLobby then
        LogServer("WARN", "❌ Lobby complet: " .. lobbyId)
        NotifyPlayer(source, Config.Messages.LobbyFull, "error")
        return false
    end
    
    local identifier = GetPlayerIdentifier(source)
    local playerName = GetPlayerName(source)
    
    LogServer("INFO", string.format("➕ Ajout du joueur %d (%s) au lobby %s", source, playerName, lobbyId))
    LogServer("DEBUG", "Identifier: " .. tostring(identifier))
    
    -- Créer les données du joueur
    local playerData = {
        source = source,
        identifier = identifier,
        name = playerName,
        team = nil, -- Sera défini par le joueur
        isReady = false,
        joinedAt = os.time()
    }
    
    -- Ajouter aux joueurs du lobby
    table.insert(lobby.players, playerData)
    
    -- Enregistrer l'association
    ServerData.PlayerLobbies[source] = lobbyId
    
    LogServer("DEBUG", "Association joueur-lobby enregistrée")
    
    -- Placer le joueur dans le routing bucket
    LogServer("DEBUG", "Placement du joueur dans le bucket " .. lobby.bucket)
    SetPlayerBucket(source, lobby.bucket)
    
    -- Téléporter le joueur dans la salle d'attente
    LogServer("DEBUG", "Téléportation du joueur en salle d'attente")
    TriggerClientEvent('scharman:client:joinWaitingRoom', source, lobbyId, lobby.bucket)
    
    -- Notifier tous les joueurs du lobby
    local message = string.format("%s a rejoint le lobby (%d/%d)", playerName, #lobby.players, Config.Game.PlayersPerLobby)
    NotifyLobbyPlayers(lobbyId, message, "info")
    
    -- Attendre un peu avant d'envoyer les données du lobby
    Citizen.SetTimeout(1000, function()
        LogServer("DEBUG", "Envoi des données du lobby à tous les joueurs")
        BroadcastLobbyData(lobbyId)
    end)
    
    LogServer("INFO", string.format("✅ Joueur %d ajouté au lobby %s (total: %d/%d)", 
        source, lobbyId, #lobby.players, Config.Game.PlayersPerLobby))
    
    return true
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
    
    local playerName = GetPlayerName(source) or "Joueur Inconnu"
    
    LogServer("INFO", string.format("👋 Retrait du joueur %d (%s) du lobby %s", source, playerName, lobbyId))
    
    -- Retirer le joueur du lobby
    for i, playerData in ipairs(lobby.players) do
        if playerData.source == source then
            -- Retirer de l'équipe si assigné
            if playerData.team then
                RemoveFromTable(lobby.teams[playerData.team], source)
                LogServer("DEBUG", "Joueur retiré de l'équipe " .. playerData.team)
            end
            
            -- Retirer de la liste
            table.remove(lobby.players, i)
            LogServer("DEBUG", "Joueur retiré de la liste des joueurs")
            break
        end
    end
    
    -- Retirer l'association
    ServerData.PlayerLobbies[source] = nil
    
    -- Remettre le joueur dans le bucket 0
    SetPlayerBucket(source, 0)
    LogServer("DEBUG", "Joueur remis dans le bucket 0")
    
    -- Téléporter le joueur
    if GetPlayerPing(source) > 0 then
        TriggerClientEvent('scharman:client:leaveWaitingRoom', source)
        LogServer("DEBUG", "Event de sortie envoyé au client")
    end
    
    -- Notifier les autres joueurs
    if #lobby.players > 0 then
        local message = string.format("%s a quitté le lobby (%d/%d)", playerName, #lobby.players, Config.Game.PlayersPerLobby)
        NotifyLobbyPlayers(lobbyId, message, "warn")
        
        -- Broadcast les données mises à jour
        BroadcastLobbyData(lobbyId)
    else
        -- Lobby vide, le supprimer
        LogServer("INFO", "Lobby vide, suppression...")
        DeleteLobby(lobbyId)
    end
    
    LogServer("INFO", string.format("✅ Joueur %d retiré du lobby %s", source, lobbyId))
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
    
    LogServer("INFO", string.format("✅ Joueur %d changé vers l'équipe %s", source, newTeam))
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
    
    LogServer("INFO", string.format("✅ État prêt du joueur %d mis à jour: %s", source, tostring(isReady)))
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 VÉRIFIER SI PRÊT À DÉMARRER
-- ════════════════════════════════════════════════════════════════════════════════

function CheckIfReadyToStart(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    LogServer("DEBUG", "Vérification si prêt à démarrer...")
    
    -- Vérifier qu'il y a 4 joueurs
    if #lobby.players < Config.Game.PlayersPerLobby then
        local message = string.format(Config.Messages.WaitingForPlayers, #lobby.players)
        LogServer("DEBUG", message)
        return
    end
    
    -- Vérifier que tous les joueurs ont une équipe
    for _, playerData in ipairs(lobby.players) do
        if not playerData.team then
            LogServer("DEBUG", "Tous les joueurs n'ont pas encore choisi d'équipe")
            return
        end
    end
    
    -- Vérifier que les équipes sont équilibrées (2v2)
    if #lobby.teams.Blue ~= Config.Game.PlayersPerTeam or #lobby.teams.Red ~= Config.Game.PlayersPerTeam then
        LogServer("DEBUG", string.format("Équipes non équilibrées: Blue=%d, Red=%d", 
            #lobby.teams.Blue, #lobby.teams.Red))
        return
    end
    
    -- Vérifier que tous les joueurs sont prêts
    for _, playerData in ipairs(lobby.players) do
        if not playerData.isReady then
            LogServer("DEBUG", "Tous les joueurs ne sont pas encore prêts")
            return
        end
    end
    
    LogServer("INFO", "✅ Tous les joueurs sont prêts! Démarrage de la partie pour le lobby " .. lobbyId)
    
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
        LogServer("WARN", "Impossible de broadcaster: lobby introuvable " .. lobbyId)
        return
    end
    
    LogServer("DEBUG", "Broadcast des données du lobby " .. lobbyId)
    
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
    
    LogServer("DEBUG", "Données à envoyer: " .. json.encode(lobbyData))
    
    -- Envoyer aux joueurs du lobby
    local sentCount = 0
    for _, playerData in ipairs(lobby.players) do
        if GetPlayerPing(playerData.source) > 0 then
            TriggerClientEvent('scharman:client:receiveLobbyData', playerData.source, lobbyData)
            sentCount = sentCount + 1
        end
    end
    
    LogServer("DEBUG", string.format("Données du lobby envoyées à %d joueurs", sentCount))
end

function SendLobbyDataToPlayer(source, lobbyId)
    LogServer("DEBUG", "Envoi des données du lobby à un joueur spécifique")
    -- Juste re-broadcast pour ce joueur
    BroadcastLobbyData(lobbyId)
end

function NotifyLobbyPlayers(lobbyId, message, type)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    for _, playerData in ipairs(lobby.players) do
        if GetPlayerPing(playerData.source) > 0 then
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
    
    LogServer("INFO", "🗑️ Suppression du lobby " .. lobbyId)
    
    -- Libérer le bucket
    if lobby.bucket then
        ReleaseBucket(lobby.bucket)
    end
    
    -- Supprimer le lobby
    ServerData.Lobbies[lobbyId] = nil
    
    LogServer("INFO", "✅ Lobby " .. lobbyId .. " supprimé")
end

function CleanupEmptyLobbies()
    local cleaned = 0
    for lobbyId, lobby in pairs(ServerData.Lobbies) do
        if #lobby.players == 0 and not lobby.inGame then
            LogServer("DEBUG", "Nettoyage du lobby vide: " .. lobbyId)
            DeleteLobby(lobbyId)
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        LogServer("INFO", string.format("🧹 %d lobby(s) vide(s) nettoyé(s)", cleaned))
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
