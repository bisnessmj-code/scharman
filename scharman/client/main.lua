-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 MAIN CLIENT - Point d'entrée et variables globales
-- ════════════════════════════════════════════════════════════════════════════════

-- Variables globales du client
ClientData = {
    -- État du joueur
    InWaitingRoom = false,
    InLobby = false,
    InGame = false,
    
    -- Données du lobby
    CurrentLobby = nil,
    CurrentTeam = nil,
    IsReady = false,
    
    -- Données de la partie en cours
    CurrentRound = 0,
    MyRole = nil, -- "chased" ou "chaser"
    GameVehicle = nil,
    CombatZoneBlip = nil,
    
    -- UI
    MainUIOpen = false,
    LobbyUIOpen = false,
}

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION
-- ════════════════════════════════════════════════════════════════════════════════

Citizen.CreateThread(function()
    LogClient("INFO", "════════════════════════════════════════════════════════")
    LogClient("INFO", "  Scharman - Course-poursuite 2v2")
    LogClient("INFO", "  Version 1.0.0")
    LogClient("INFO", "════════════════════════════════════════════════════════")
    
    -- Attendre que le joueur soit complètement chargé
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    LogClient("INFO", "Joueur chargé, initialisation du script...")
    
    -- Initialiser les composants
    InitializePed()
    
    LogClient("INFO", "Script Scharman initialisé avec succès !")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 📨 GESTION DES EVENTS GLOBAUX
-- ════════════════════════════════════════════════════════════════════════════════

-- Event : Rejoindre la salle d'attente
RegisterNetEvent('scharman:client:joinWaitingRoom', function(lobbyId, bucketId)
    LogClient("INFO", string.format("Rejoindre la salle d'attente - Lobby ID: %s, Bucket: %d", lobbyId, bucketId))
    
    -- Fermer l'UI principale
    CloseMainUI()
    
    -- Mettre à jour l'état
    ClientData.InWaitingRoom = true
    ClientData.InLobby = true
    ClientData.CurrentLobby = lobbyId
    
    -- Téléporter le joueur
    TeleportPlayer(Config.WaitingRoom.Coords)
    
    -- Notification
    NotifyClient(Config.Messages.JoinedWaitingRoom, "success")
    
    -- Activer l'interface du lobby
    Wait(1000)
    EnableLobbyUI()
end)

-- Event : Quitter la salle d'attente
RegisterNetEvent('scharman:client:leaveWaitingRoom', function()
    LogClient("INFO", "Quitter la salle d'attente")
    
    -- Mettre à jour l'état
    ClientData.InWaitingRoom = false
    ClientData.InLobby = false
    ClientData.CurrentLobby = nil
    ClientData.CurrentTeam = nil
    ClientData.IsReady = false
    
    -- Fermer l'interface du lobby
    CloseLobbyUI()
    
    -- Téléporter le joueur au PED
    TeleportPlayer(Config.Ped.Coords)
    
    -- Notification
    NotifyClient(Config.Messages.LeftWaitingRoom, "info")
end)

-- Event : Changer d'équipe
RegisterNetEvent('scharman:client:teamChanged', function(team)
    LogClient("INFO", "Changement d'équipe: " .. team)
    
    ClientData.CurrentTeam = team
    
    local teamName = Config.Teams[team].Name
    NotifyClient(string.format(Config.Messages.TeamChanged, teamName), "info")
end)

-- Event : Changer l'état de prêt
RegisterNetEvent('scharman:client:readyStatusChanged', function(isReady)
    LogClient("INFO", "Changement de statut prêt: " .. tostring(isReady))
    
    ClientData.IsReady = isReady
    
    local status = isReady and "~g~Prêt~s~" or "~r~Non prêt~s~"
    NotifyClient(string.format(Config.Messages.ReadyStatusChanged, status), "info")
end)

-- Event : Notification du lobby
RegisterNetEvent('scharman:client:lobbyNotification', function(message)
    NotifyClient(message, "info")
end)

-- Event : Démarrer la partie
RegisterNetEvent('scharman:client:startGame', function(gameData)
    LogClient("INFO", "Démarrage de la partie")
    LogClient("DEBUG", "Données de la partie: " .. json.encode(gameData))
    
    -- Mettre à jour l'état
    ClientData.InGame = true
    ClientData.InLobby = false
    ClientData.MyRole = gameData.role
    ClientData.CurrentRound = 1
    
    -- Fermer l'UI du lobby
    CloseLobbyUI()
    
    -- Désactiver l'UI du lobby
    DisableLobbyUI()
    
    -- Notification
    NotifyClient(Config.Messages.GameStarting, "success")
    
    -- Démarrer le jeu
    StartGame(gameData)
end)

-- Event : Terminer la partie
RegisterNetEvent('scharman:client:endGame', function(winnerTeam)
    LogClient("INFO", "Fin de la partie - Gagnant: " .. winnerTeam)
    
    -- Mettre à jour l'état
    ClientData.InGame = false
    ClientData.InLobby = false
    ClientData.InWaitingRoom = false
    ClientData.CurrentLobby = nil
    ClientData.CurrentTeam = nil
    ClientData.IsReady = false
    ClientData.CurrentRound = 0
    ClientData.MyRole = nil
    
    -- Nettoyer le véhicule si existant
    if ClientData.GameVehicle and DoesEntityExist(ClientData.GameVehicle) then
        DeleteVehicleSafe(ClientData.GameVehicle)
        ClientData.GameVehicle = nil
    end
    
    -- Nettoyer le blip de la zone de combat
    if ClientData.CombatZoneBlip then
        RemoveBlipSafe(ClientData.CombatZoneBlip)
        ClientData.CombatZoneBlip = nil
    end
    
    -- Notification
    local teamName = Config.Teams[winnerTeam].Name
    NotifyClient(string.format(Config.Messages.GameWon, teamName), "success")
    
    -- Téléporter au PED
    Wait(3000)
    TeleportPlayer(Config.Ped.Coords)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔄 BOUCLE PRINCIPALE
-- ════════════════════════════════════════════════════════════════════════════════

-- Thread pour les mises à jour régulières
Citizen.CreateThread(function()
    while true do
        local sleep = Config.Advanced.UpdateRate or 500
        
        -- Vérifier si le joueur est dans une partie et gérer les restrictions
        if ClientData.InGame then
            -- Logique gérée dans game.lua
            sleep = 0
        elseif ClientData.InWaitingRoom then
            -- Logique gérée dans lobby.lua
            sleep = 100
        end
        
        Wait(sleep)
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🛑 GESTION DE LA DÉCONNEXION
-- ════════════════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    LogClient("WARN", "Arrêt du script - Nettoyage...")
    
    -- Nettoyer le PED
    CleanupPed()
    
    -- Nettoyer les UIs
    CloseMainUI()
    CloseLobbyUI()
    
    -- Nettoyer le véhicule si existant
    if ClientData.GameVehicle and DoesEntityExist(ClientData.GameVehicle) then
        DeleteVehicleSafe(ClientData.GameVehicle)
    end
    
    -- Nettoyer les blips
    if ClientData.CombatZoneBlip then
        RemoveBlipSafe(ClientData.CombatZoneBlip)
    end
    
    LogClient("INFO", "Nettoyage terminé")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 COMMANDES DÉVELOPPEUR (DEBUG)
-- ════════════════════════════════════════════════════════════════════════════════

if Config.Debug then
    -- Commande pour afficher l'état actuel
    RegisterCommand('scharman_debug', function()
        print("════════════════════════════════════════════════════════")
        print("DEBUG - État du client Scharman")
        print("════════════════════════════════════════════════════════")
        print("InWaitingRoom: " .. tostring(ClientData.InWaitingRoom))
        print("InLobby: " .. tostring(ClientData.InLobby))
        print("InGame: " .. tostring(ClientData.InGame))
        print("CurrentLobby: " .. tostring(ClientData.CurrentLobby))
        print("CurrentTeam: " .. tostring(ClientData.CurrentTeam))
        print("IsReady: " .. tostring(ClientData.IsReady))
        print("CurrentRound: " .. tostring(ClientData.CurrentRound))
        print("MyRole: " .. tostring(ClientData.MyRole))
        print("════════════════════════════════════════════════════════")
    end, false)
    
    -- Commande pour forcer la sortie d'un lobby
    RegisterCommand('scharman_leave', function()
        if ClientData.InLobby then
            TriggerServerEvent('scharman:server:leaveLobby')
            LogClient("DEBUG", "Commande leave exécutée")
        else
            LogClient("WARN", "Vous n'êtes pas dans un lobby")
        end
    end, false)
    
    -- Commande pour téléporter au PED
    RegisterCommand('scharman_tp_ped', function()
        TeleportPlayer(Config.Ped.Coords)
        LogClient("DEBUG", "Téléporté au PED")
    end, false)
    
    LogClient("DEBUG", "Commandes de debug activées: /scharman_debug, /scharman_leave, /scharman_tp_ped")
end

LogClient("INFO", "Main client chargé")
