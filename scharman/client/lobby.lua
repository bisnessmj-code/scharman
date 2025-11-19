-- ════════════════════════════════════════════════════════════════════════════════
-- 🏠 GESTION DU LOBBY / SALLE D'ATTENTE
-- ════════════════════════════════════════════════════════════════════════════════

local lobbyUIEnabled = false

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 ACTIVATION DE L'UI DU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function EnableLobbyUI()
    LogClient("INFO", "Activation de l'UI du lobby")
    lobbyUIEnabled = true
    
    -- Lancer le thread d'affichage du texte d'aide
    StartLobbyHelpTextThread()
end

function DisableLobbyUI()
    LogClient("INFO", "Désactivation de l'UI du lobby")
    lobbyUIEnabled = false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔄 THREAD D'AFFICHAGE DU TEXTE D'AIDE
-- ════════════════════════════════════════════════════════════════════════════════

function StartLobbyHelpTextThread()
    Citizen.CreateThread(function()
        while lobbyUIEnabled and ClientData.InWaitingRoom do
            Wait(0)
            
            -- Afficher le texte d'aide
            DisplayHelpText(Config.WaitingRoom.LobbyMenuText)
            
            -- Vérifier la touche pour ouvrir le menu
            if IsControlJustPressed(0, Config.WaitingRoom.LobbyMenuKey) then
                if ClientData.LobbyUIOpen then
                    CloseLobbyUI()
                else
                    OpenLobbyUI()
                end
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 OUVERTURE DE L'UI DU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function OpenLobbyUI()
    if ClientData.LobbyUIOpen then
        LogClient("WARN", "L'UI du lobby est déjà ouverte")
        return
    end
    
    if not ClientData.InWaitingRoom then
        LogClient("WARN", "Le joueur n'est pas dans la salle d'attente")
        return
    end
    
    LogClient("INFO", "Ouverture de l'UI du lobby")
    
    -- Activer le focus NUI
    SetNuiFocus(true, true)
    
    -- Marquer comme ouvert
    ClientData.LobbyUIOpen = true
    
    -- Demander les données du lobby au serveur
    TriggerServerEvent('scharman:server:requestLobbyData')
    
    LogClient("DEBUG", "UI du lobby ouverte")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚪 FERMETURE DE L'UI DU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

function CloseLobbyUI()
    if not ClientData.LobbyUIOpen then
        return
    end
    
    LogClient("INFO", "Fermeture de l'UI du lobby")
    
    -- Désactiver le focus NUI
    SetNuiFocus(false, false)
    
    -- Marquer comme fermé
    ClientData.LobbyUIOpen = false
    
    -- Envoyer un message à l'UI pour la fermer
    SendNUIMessage({
        action = "closeLobbyUI"
    })
    
    LogClient("DEBUG", "UI du lobby fermée")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 📊 RÉCEPTION DES DONNÉES DU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:receiveLobbyData', function(lobbyData)
    LogClient("DEBUG", "Réception des données du lobby")
    LogClient("DEBUG", "Données: " .. json.encode(lobbyData))
    
    -- Envoyer les données à l'UI
    SendNUIMessage({
        action = "updateLobbyData",
        data = {
            lobbyData = lobbyData,
            teams = Config.Teams,
            currentTeam = ClientData.CurrentTeam,
            isReady = ClientData.IsReady
        }
    })
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 📨 CALLBACKS NUI DU LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

-- Callback : Fermer l'UI du lobby
RegisterNUICallback('closeLobbyUI', function(data, cb)
    LogClient("DEBUG", "Callback NUI: closeLobbyUI")
    CloseLobbyUI()
    cb('ok')
end)

-- Callback : Changer d'équipe
RegisterNUICallback('changeTeam', function(data, cb)
    local team = data.team
    LogClient("INFO", "Callback NUI: changeTeam - " .. team)
    
    -- Vérifier que l'équipe est valide
    if team ~= "Blue" and team ~= "Red" then
        LogClient("ERROR", "Équipe invalide: " .. team)
        cb({success = false, message = "Équipe invalide"})
        return
    end
    
    -- Envoyer la demande au serveur
    TriggerServerEvent('scharman:server:changeTeam', team)
    
    cb({success = true})
end)

-- Callback : Changer l'état de prêt
RegisterNUICallback('toggleReady', function(data, cb)
    local isReady = data.isReady
    LogClient("INFO", "Callback NUI: toggleReady - " .. tostring(isReady))
    
    -- Envoyer la demande au serveur
    TriggerServerEvent('scharman:server:toggleReady', isReady)
    
    cb({success = true})
end)

-- Callback : Quitter le lobby
RegisterNUICallback('leaveLobby', function(data, cb)
    LogClient("INFO", "Callback NUI: leaveLobby")
    
    -- Envoyer la demande au serveur
    TriggerServerEvent('scharman:server:leaveLobby')
    
    -- Fermer l'UI
    CloseLobbyUI()
    
    cb({success = true})
end)

-- Callback : Rafraîchir les données du lobby
RegisterNUICallback('refreshLobbyData', function(data, cb)
    LogClient("DEBUG", "Callback NUI: refreshLobbyData")
    
    -- Demander les données mises à jour
    TriggerServerEvent('scharman:server:requestLobbyData')
    
    cb('ok')
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- ⌨️ GESTION DES TOUCHES POUR LE LOBBY
-- ════════════════════════════════════════════════════════════════════════════════

-- Thread pour gérer la fermeture avec ESC
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if ClientData.LobbyUIOpen then
            -- Désactiver les contrôles quand l'UI est ouverte
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            -- Fermer avec ESC (clé 322)
            if IsControlJustPressed(0, 322) then
                CloseLobbyUI()
            end
        else
            Wait(500)
        end
    end
end)

LogClient("INFO", "Module Lobby chargé")
