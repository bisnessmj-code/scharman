-- ════════════════════════════════════════════════════════════════════════════════
-- 🎨 GESTION DE L'INTERFACE NUI PRINCIPALE
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 OUVERTURE DE L'UI PRINCIPALE
-- ════════════════════════════════════════════════════════════════════════════════

function OpenMainUI()
    if ClientData.MainUIOpen then
        LogClient("WARN", "L'UI principale est déjà ouverte")
        return
    end
    
    LogClient("INFO", "Ouverture de l'UI principale")
    
    -- Activer le focus NUI
    SetNuiFocus(true, true)
    
    -- Marquer comme ouvert
    ClientData.MainUIOpen = true
    
    -- Demander les stats au serveur
    LogClient("DEBUG", "Demande des stats au serveur...")
    TriggerServerEvent('scharman:server:requestStats')
    
    -- Envoyer un message à l'UI pour l'ouvrir
    SendNUIMessage({
        action = "openMainUI",
        data = {
            title = Config.UI.Title,
            theme = Config.UI.Theme
        }
    })
    
    LogClient("DEBUG", "UI principale envoyée au NUI")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚪 FERMETURE DE L'UI PRINCIPALE
-- ════════════════════════════════════════════════════════════════════════════════

function CloseMainUI()
    if not ClientData.MainUIOpen then
        return
    end
    
    LogClient("INFO", "Fermeture de l'UI principale")
    
    -- Désactiver le focus NUI
    SetNuiFocus(false, false)
    
    -- Marquer comme fermé
    ClientData.MainUIOpen = false
    
    -- Envoyer un message à l'UI pour la fermer
    SendNUIMessage({
        action = "closeMainUI"
    })
    
    LogClient("DEBUG", "UI principale fermée")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 📊 RÉCEPTION DES STATS
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:receiveStats', function(playerStats, globalStats)
    LogClient("DEBUG", "Réception des statistiques")
    LogClient("DEBUG", "Stats personnelles: " .. json.encode(playerStats))
    LogClient("DEBUG", "Stats globales: " .. json.encode(globalStats))
    
    -- Envoyer les stats à l'UI
    SendNUIMessage({
        action = "updateStats",
        data = {
            playerStats = playerStats,
            globalStats = globalStats
        }
    })
    
    LogClient("INFO", "Stats envoyées à l'UI NUI")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 📨 CALLBACKS NUI
-- ════════════════════════════════════════════════════════════════════════════════

-- Callback : Fermer l'UI
RegisterNUICallback('closeUI', function(data, cb)
    LogClient("DEBUG", "Callback NUI: closeUI")
    CloseMainUI()
    cb('ok')
end)

-- Callback : Rejoindre la salle d'attente
RegisterNUICallback('joinWaitingRoom', function(data, cb)
    LogClient("INFO", "Callback NUI: joinWaitingRoom - Début de la requête")
    
    -- Vérifier que le joueur n'est pas déjà dans un lobby
    if ClientData.InLobby or ClientData.InGame then
        LogClient("WARN", "Le joueur est déjà dans un lobby ou en jeu")
        cb({success = false, message = Config.Messages.AlreadyInGame})
        return
    end
    
    LogClient("INFO", "Envoi de la demande au serveur...")
    
    -- Demander au serveur de rejoindre un lobby
    TriggerServerEvent('scharman:server:joinLobby')
    
    -- Répondre immédiatement au NUI que la demande est envoyée
    cb({success = true, message = "Demande envoyée au serveur"})
    
    LogClient("INFO", "Callback joinWaitingRoom terminé - En attente de la réponse du serveur")
end)

-- Callback : Rafraîchir les stats
RegisterNUICallback('refreshStats', function(data, cb)
    LogClient("DEBUG", "Callback NUI: refreshStats")
    
    -- Demander les stats mises à jour
    TriggerServerEvent('scharman:server:requestStats')
    
    cb('ok')
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- ⌨️ GESTION DES TOUCHES
-- ════════════════════════════════════════════════════════════════════════════════

-- Thread pour gérer la fermeture avec ESC
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if ClientData.MainUIOpen then
            -- Désactiver les contrôles quand l'UI est ouverte
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            -- Fermer avec ESC (clé 322)
            if IsControlJustPressed(0, 322) then
                CloseMainUI()
            end
        else
            Wait(500)
        end
    end
end)

LogClient("INFO", "Module UI principale chargé")
