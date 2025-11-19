-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 LOGIQUE DE JEU CÔTÉ SERVEUR
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 DÉMARRER UNE PARTIE
-- ════════════════════════════════════════════════════════════════════════════════

function StartGame(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("ERROR", "Lobby introuvable: " .. lobbyId)
        return
    end
    
    LogServer("INFO", "═══════════════════════════════════════════════════════")
    LogServer("INFO", "  DÉMARRAGE DE LA PARTIE - Lobby: " .. lobbyId)
    LogServer("INFO", "═══════════════════════════════════════════════════════")
    
    -- Marquer le lobby comme en jeu
    lobby.inGame = true
    
    -- Initialiser les données de la partie
    local gameData = {
        lobbyId = lobbyId,
        startTime = os.time(),
        currentRound = 1,
        scores = {
            Blue = 0,
            Red = 0
        },
        rounds = {},
        players = {},
        totalKills = 0
    }
    
    -- Initialiser les stats des joueurs
    for _, playerData in ipairs(lobby.players) do
        gameData.players[playerData.source] = {
            kills = 0,
            deaths = 0
        }
    end
    
    -- Sauvegarder les données de la partie
    ServerData.ActiveGames[lobbyId] = gameData
    
    -- Déterminer quelle équipe commence en tant que "suivie"
    local firstChasedTeam = math.random(2) == 1 and "Blue" or "Red"
    local firstChaserTeam = firstChasedTeam == "Blue" and "Red" or "Blue"
    
    LogServer("INFO", string.format("Premier round - Équipe suivie: %s | Équipe chasseuse: %s", 
        firstChasedTeam, firstChaserTeam))
    
    gameData.currentChasedTeam = firstChasedTeam
    gameData.currentChaserTeam = firstChaserTeam
    
    -- Notifier tous les joueurs
    NotifyLobbyPlayers(lobbyId, Config.Messages.GameStarting, "success")
    
    -- Démarrer le premier round
    Citizen.SetTimeout(2000, function()
        StartRound(lobbyId, 1)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏁 DÉMARRER UN ROUND
-- ════════════════════════════════════════════════════════════════════════════════

function StartRound(lobbyId, roundNumber)
    local lobby = ServerData.Lobbies[lobbyId]
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not lobby or not gameData then
        LogServer("ERROR", "Données introuvables pour le lobby: " .. lobbyId)
        return
    end
    
    LogServer("INFO", "─────────────────────────────────────────────────────")
    LogServer("INFO", string.format("  ROUND %d - Lobby: %s", roundNumber, lobbyId))
    LogServer("INFO", "─────────────────────────────────────────────────────")
    
    gameData.currentRound = roundNumber
    
    -- Données du round
    local roundData = {
        number = roundNumber,
        startTime = os.time(),
        chasedTeam = gameData.currentChasedTeam,
        chaserTeam = gameData.currentChaserTeam,
        combatZone = nil,
        winner = nil
    }
    
    table.insert(gameData.rounds, roundData)
    
    -- Spawn des véhicules et placement des joueurs
    SpawnVehiclesForRound(lobbyId, roundNumber)
    
    -- Attendre que tous les véhicules soient spawn
    Citizen.SetTimeout(2000, function()
        -- Lancer le compte à rebours
        StartCountdown(lobbyId)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚗 SPAWN DES VÉHICULES
-- ════════════════════════════════════════════════════════════════════════════════

function SpawnVehiclesForRound(lobbyId, roundNumber)
    local lobby = ServerData.Lobbies[lobbyId]
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not lobby or not gameData then
        return
    end
    
    LogServer("INFO", "Spawn des véhicules pour le round " .. roundNumber)
    
    local chasedTeam = gameData.currentChasedTeam
    local chaserTeam = gameData.currentChaserTeam
    
    -- Spawn véhicule équipe suivie (devant)
    local chasedPlayers = lobby.teams[chasedTeam]
    local chasedCoords = Config.VehicleSpawns.Chased.Coords
    
    for i, source in ipairs(chasedPlayers) do
        local seat = (i == 1) and -1 or 0 -- Premier = conducteur, second = passager
        
        TriggerClientEvent('scharman:client:spawnVehicle', source, {
            model = Config.Vehicles.Model,
            coords = chasedCoords,
            seat = seat,
            color = chasedTeam,
            role = "chased"
        })
        
        -- Notifier le joueur de son rôle
        TriggerClientEvent('scharman:client:startGame', source, {
            role = "chased",
            team = chasedTeam,
            round = roundNumber
        })
        
        LogServer("DEBUG", string.format("Joueur %d spawn dans le véhicule suivie (siège %d)", source, seat))
    end
    
    -- Spawn véhicule équipe chasseuse (derrière)
    local chaserPlayers = lobby.teams[chaserTeam]
    local chaserCoords = Config.VehicleSpawns.Chaser.Coords
    
    for i, source in ipairs(chaserPlayers) do
        local seat = (i == 1) and -1 or 0
        
        TriggerClientEvent('scharman:client:spawnVehicle', source, {
            model = Config.Vehicles.Model,
            coords = chaserCoords,
            seat = seat,
            color = chaserTeam,
            role = "chaser"
        })
        
        TriggerClientEvent('scharman:client:startGame', source, {
            role = "chaser",
            team = chaserTeam,
            round = roundNumber
        })
        
        LogServer("DEBUG", string.format("Joueur %d spawn dans le véhicule chasseuse (siège %d)", source, seat))
    end
    
    LogServer("INFO", "Tous les véhicules ont été spawn")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ⏱️ COMPTE À REBOURS
-- ════════════════════════════════════════════════════════════════════════════════

function StartCountdown(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        return
    end
    
    local countdown = Config.Game.CountdownBeforeStart
    
    LogServer("INFO", "Démarrage du compte à rebours: " .. countdown .. " secondes")
    
    -- Envoyer le countdown à tous les joueurs
    for _, playerData in ipairs(lobby.players) do
        TriggerClientEvent('scharman:client:startCountdown', playerData.source, countdown)
    end
    
    -- Attendre la fin du countdown
    Citizen.SetTimeout((countdown + 1) * 1000, function()
        OnCountdownFinished(lobbyId)
    end)
end

function OnCountdownFinished(lobbyId)
    LogServer("INFO", "Compte à rebours terminé - Démarrage du round")
    
    -- Démarrer le timer pour l'équipe suivie
    StartFindPositionTimer(lobbyId)
end

-- Event : Compte à rebours terminé côté client
RegisterNetEvent('scharman:server:countdownFinished', function()
    local source = source
    LogServer("DEBUG", string.format("Joueur %d prêt après le countdown", source))
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- ⏲️ TIMER POUR TROUVER LA POSITION
-- ════════════════════════════════════════════════════════════════════════════════

function StartFindPositionTimer(lobbyId)
    local lobby = ServerData.Lobbies[lobbyId]
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not lobby or not gameData then
        return
    end
    
    local duration = Config.Game.TimeToFindPosition
    
    LogServer("INFO", "Démarrage du timer de recherche: " .. duration .. " secondes")
    
    -- Envoyer le timer à tous les joueurs
    for _, playerData in ipairs(lobby.players) do
        TriggerClientEvent('scharman:client:startFindTimer', playerData.source, duration)
    end
    
    -- Sauvegarder le timer
    gameData.findTimer = {
        startTime = os.time(),
        duration = duration,
        expired = false
    }
    
    -- Attendre la fin du timer
    Citizen.SetTimeout(duration * 1000, function()
        OnFindTimerExpired(lobbyId)
    end)
end

function OnFindTimerExpired(lobbyId)
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not gameData then
        return
    end
    
    -- Vérifier si le conducteur est sorti
    if gameData.driverExited then
        LogServer("DEBUG", "Timer expiré mais le conducteur était déjà sorti")
        return
    end
    
    gameData.findTimer.expired = true
    
    LogServer("WARN", "Timer expiré! L'équipe suivie n'a pas trouvé de position")
    
    -- L'équipe chasseuse gagne le round
    local chaserTeam = gameData.currentChaserTeam
    EndRound(lobbyId, chaserTeam, "timeout")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚗 CONDUCTEUR SORTI DU VÉHICULE
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:driverExited', function(position)
    local source = source
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if not lobbyId then
        LogServer("WARN", "Joueur " .. source .. " n'est pas dans un lobby")
        return
    end
    
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not gameData then
        return
    end
    
    -- Vérifier que le timer n'a pas expiré
    if gameData.findTimer and gameData.findTimer.expired then
        LogServer("WARN", "Timer déjà expiré, sortie du conducteur ignorée")
        return
    end
    
    -- Vérifier que c'est le conducteur de l'équipe suivie
    local playerData = GetPlayerDataInLobby(source, lobbyId)
    
    if not playerData or playerData.team ~= gameData.currentChasedTeam then
        LogServer("WARN", "Ce n'est pas un conducteur de l'équipe suivie")
        return
    end
    
    LogServer("INFO", "Le conducteur est sorti du véhicule à la position: " .. json.encode(position))
    
    -- Marquer comme sorti
    gameData.driverExited = true
    
    -- Arrêter le timer
    TriggerClientEvent('scharman:client:stopFindTimer', -1)
    
    -- Créer la zone de combat
    CreateCombatZone(lobbyId, position)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 📍 CRÉATION DE LA ZONE DE COMBAT
-- ════════════════════════════════════════════════════════════════════════════════

function CreateCombatZone(lobbyId, position)
    local lobby = ServerData.Lobbies[lobbyId]
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not lobby or not gameData then
        return
    end
    
    LogServer("INFO", "Création de la zone de combat")
    
    -- Sauvegarder la position
    local currentRound = gameData.rounds[#gameData.rounds]
    currentRound.combatZone = position
    
    -- Notifier tous les joueurs
    for _, playerData in ipairs(lobby.players) do
        TriggerClientEvent('scharman:client:createCombatZone', playerData.source, position)
    end
    
    local teamName = Config.Teams[gameData.currentChasedTeam].Name
    NotifyLobbyPlayers(lobbyId, string.format(Config.Messages.PositionValidated, teamName), "success")
    
    LogServer("INFO", "Zone de combat créée")
    
    -- À partir de maintenant, le round se termine quand une équipe est éliminée
    -- ou après un certain temps (optionnel)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏆 FIN D'UN ROUND
-- ════════════════════════════════════════════════════════════════════════════════

function EndRound(lobbyId, winnerTeam, reason)
    local lobby = ServerData.Lobbies[lobbyId]
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not lobby or not gameData then
        return
    end
    
    LogServer("INFO", "═══════════════════════════════════════════════════════")
    LogServer("INFO", string.format("  FIN DU ROUND %d - Gagnant: %s (%s)", 
        gameData.currentRound, winnerTeam, reason or "unknown"))
    LogServer("INFO", "═══════════════════════════════════════════════════════")
    
    -- Mettre à jour le score
    gameData.scores[winnerTeam] = gameData.scores[winnerTeam] + 1
    
    -- Sauvegarder le round
    local currentRound = gameData.rounds[#gameData.rounds]
    currentRound.winner = winnerTeam
    currentRound.endTime = os.time()
    currentRound.reason = reason
    
    -- Notifier tous les joueurs
    for _, playerData in ipairs(lobby.players) do
        TriggerClientEvent('scharman:client:roundEnd', playerData.source, winnerTeam, gameData.currentRound)
    end
    
    local teamName = Config.Teams[winnerTeam].Name
    NotifyLobbyPlayers(lobbyId, string.format(Config.Messages.RoundWon, teamName), "success")
    
    -- Vérifier si la partie est terminée
    local maxRoundsToWin = math.ceil(Config.Game.MaxRounds / 2)
    
    if gameData.scores[winnerTeam] >= maxRoundsToWin then
        -- Fin de la partie
        Citizen.SetTimeout(3000, function()
            EndGame(lobbyId, winnerTeam)
        end)
    else
        -- Nouveau round
        Citizen.SetTimeout(Config.Game.RespawnDelay * 1000, function()
            PrepareNextRound(lobbyId)
        end)
    end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔄 PRÉPARER LE ROUND SUIVANT
-- ════════════════════════════════════════════════════════════════════════════════

function PrepareNextRound(lobbyId)
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not gameData then
        return
    end
    
    LogServer("INFO", "Préparation du round suivant")
    
    -- Inverser les rôles
    local newChasedTeam = gameData.currentChaserTeam
    local newChaserTeam = gameData.currentChasedTeam
    
    gameData.currentChasedTeam = newChasedTeam
    gameData.currentChaserTeam = newChaserTeam
    
    -- Réinitialiser les données du round
    gameData.driverExited = false
    gameData.findTimer = nil
    
    LogServer("INFO", string.format("Rôles inversés - Suivis: %s | Chasseurs: %s", 
        newChasedTeam, newChaserTeam))
    
    -- Notifier les joueurs
    local lobby = ServerData.Lobbies[lobbyId]
    for _, playerData in ipairs(lobby.players) do
        local newRole = (playerData.team == newChasedTeam) and "chased" or "chaser"
        TriggerClientEvent('scharman:client:newRound', playerData.source, gameData.currentRound + 1, newRole)
    end
    
    -- Démarrer le nouveau round
    Citizen.SetTimeout(2000, function()
        StartRound(lobbyId, gameData.currentRound + 1)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏁 FIN DE LA PARTIE
-- ════════════════════════════════════════════════════════════════════════════════

function EndGame(lobbyId, winnerTeam)
    local lobby = ServerData.Lobbies[lobbyId]
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not lobby or not gameData then
        return
    end
    
    LogServer("INFO", "═══════════════════════════════════════════════════════")
    LogServer("INFO", string.format("  FIN DE LA PARTIE - Gagnant: %s", winnerTeam))
    LogServer("INFO", string.format("  Score final - Blue: %d | Red: %d", 
        gameData.scores.Blue, gameData.scores.Red))
    LogServer("INFO", "═══════════════════════════════════════════════════════")
    
    -- Calculer la durée
    gameData.duration = os.time() - gameData.startTime
    
    -- Enregistrer les stats
    local loserTeam = winnerTeam == "Blue" and "Red" or "Blue"
    gameData[winnerTeam] = {roundsWon = gameData.scores[winnerTeam]}
    gameData[loserTeam] = {roundsWon = gameData.scores[loserTeam]}
    
    RecordMatchEnd(lobbyId, winnerTeam, gameData)
    
    -- Notifier tous les joueurs
    for _, playerData in ipairs(lobby.players) do
        TriggerClientEvent('scharman:client:endGame', playerData.source, winnerTeam)
    end
    
    -- Nettoyer les données
    ServerData.ActiveGames[lobbyId] = nil
    
    -- Réinitialiser le lobby
    lobby.inGame = false
    
    -- Vider le lobby
    local playersToRemove = {}
    for _, playerData in ipairs(lobby.players) do
        table.insert(playersToRemove, playerData.source)
    end
    
    for _, source in ipairs(playersToRemove) do
        HandlePlayerLeaveLobby(source, lobbyId)
    end
    
    LogServer("INFO", "Partie terminée et lobby nettoyé")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 💀 GESTION DES MORTS (OPTIONNEL - POUR STATISTIQUES)
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:server:playerKilled', function(killerId, victimId)
    local source = source
    local lobbyId = ServerData.PlayerLobbies[source]
    
    if not lobbyId then
        return
    end
    
    local gameData = ServerData.ActiveGames[lobbyId]
    
    if not gameData then
        return
    end
    
    LogServer("INFO", string.format("Joueur %d tué par %d", victimId, killerId))
    
    -- Mettre à jour les stats
    if gameData.players[killerId] then
        gameData.players[killerId].kills = gameData.players[killerId].kills + 1
        gameData.totalKills = gameData.totalKills + 1
    end
    
    if gameData.players[victimId] then
        gameData.players[victimId].deaths = gameData.players[victimId].deaths + 1
    end
end)

LogServer("INFO", "Module Game chargé")
