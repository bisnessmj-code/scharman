-- ════════════════════════════════════════════════════════════════════════════════
-- 🎮 LOGIQUE DE JEU CÔTÉ CLIENT
-- ════════════════════════════════════════════════════════════════════════════════

local currentGameData = nil
local vehicleFrozen = false
local canExitVehicle = false
local combatZoneMarker = nil
local timerActive = false

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 DÉMARRAGE DU JEU
-- ════════════════════════════════════════════════════════════════════════════════

function StartGame(gameData)
    LogClient("INFO", "Démarrage du jeu")
    LogClient("DEBUG", "Données du jeu: " .. json.encode(gameData))
    
    currentGameData = gameData
    
    -- Attendre un peu pour que tous les joueurs soient prêts
    Wait(1000)
    
    -- Démarrer la manche
    StartRound()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏁 DÉMARRAGE D'UNE MANCHE
-- ════════════════════════════════════════════════════════════════════════════════

function StartRound()
    LogClient("INFO", "Démarrage de la manche " .. ClientData.CurrentRound)
    
    -- Nettoyer les éléments précédents
    CleanupRound()
    
    -- Attendre la synchronisation
    Wait(500)
end

-- Event : Spawn du véhicule
RegisterNetEvent('scharman:client:spawnVehicle', function(vehicleData)
    LogClient("INFO", "Spawn du véhicule")
    LogClient("DEBUG", "Données véhicule: " .. json.encode(vehicleData))
    
    -- Créer le véhicule
    local coords = vehicleData.coords
    local vehicle = CreateVehicleAtCoords(vehicleData.model, coords, coords.w)
    
    -- Sauvegarder la référence
    ClientData.GameVehicle = vehicle
    
    -- Appliquer les modifications
    ApplyVehicleMods(vehicle, vehicleData.color)
    
    -- Placer le joueur dans le véhicule
    local seat = vehicleData.seat -- -1 = conducteur, 0 = passager
    PutPlayerInVehicle(vehicle, seat)
    
    -- Désactiver le tir si configuré
    if Config.Vehicles.DisableShooting then
        DisableVehicleShooting(vehicle)
    end
    
    LogClient("INFO", "Joueur placé dans le véhicule au siège: " .. seat)
end)

-- Event : Compte à rebours
RegisterNetEvent('scharman:client:startCountdown', function(seconds)
    LogClient("INFO", "Démarrage du compte à rebours: " .. seconds .. " secondes")
    
    -- Freeze le véhicule
    if ClientData.GameVehicle then
        FreezeVehicle(ClientData.GameVehicle, true)
        vehicleFrozen = true
    end
    
    -- Afficher le compte à rebours
    ShowCountdown(seconds, function()
        LogClient("INFO", "Compte à rebours terminé - GO!")
        
        -- Défreeze le véhicule
        if ClientData.GameVehicle then
            FreezeVehicle(ClientData.GameVehicle, false)
            vehicleFrozen = false
        end
        
        -- Notifier le serveur que le joueur est prêt
        TriggerServerEvent('scharman:server:countdownFinished')
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- ⏱️ TIMER POUR L'ÉQUIPE SUIVIE
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:startFindTimer', function(duration)
    LogClient("INFO", "Démarrage du timer de recherche: " .. duration .. " secondes")
    
    timerActive = true
    
    -- Activer la possibilité de sortir du véhicule pour le conducteur
    if ClientData.MyRole == "chased" and GetPlayerSeatInVehicle() == -1 then
        canExitVehicle = true
        LogClient("DEBUG", "Le conducteur peut maintenant sortir du véhicule")
    end
    
    -- Afficher le timer
    ShowTimer(duration, function(remaining)
        -- Callback pendant le timer
        if remaining % 10 == 0 then
            LogClient("DEBUG", "Temps restant: " .. remaining .. " secondes")
        end
    end, function()
        -- Callback à la fin du timer
        LogClient("WARN", "Temps écoulé!")
        timerActive = false
        canExitVehicle = false
    end)
end)

RegisterNetEvent('scharman:client:stopFindTimer', function()
    LogClient("INFO", "Arrêt du timer de recherche")
    timerActive = false
    canExitVehicle = false
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 📍 ZONE DE COMBAT
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:createCombatZone', function(position)
    LogClient("INFO", "Création de la zone de combat")
    LogClient("DEBUG", "Position: " .. json.encode(position))
    
    -- Créer le blip
    ClientData.CombatZoneBlip = CreateBlipAtCoords(
        position,
        Config.Game.CombatZone.Blip.Sprite,
        Config.Game.CombatZone.Blip.Color,
        Config.Game.CombatZone.Blip.Scale,
        Config.Game.CombatZone.Blip.Label
    )
    
    -- Sauvegarder la position pour le marker
    combatZoneMarker = position
    
    -- Lancer le thread du marker
    StartCombatZoneMarkerThread()
    
    -- Si le joueur est chasseur, créer un waypoint
    if ClientData.MyRole == "chaser" then
        SetNewWaypoint(position.x, position.y)
        LogClient("INFO", "GPS créé vers la zone de combat")
    end
    
    -- Donner l'arme au joueur s'il est sorti du véhicule
    if not IsPlayerInVehicle() then
        GiveWeaponToPlayer(
            Config.Weapons.Default.Name,
            Config.Weapons.Default.Ammo,
            Config.Weapons.Default.Components
        )
    end
end)

-- Thread pour afficher le marker de la zone
function StartCombatZoneMarkerThread()
    Citizen.CreateThread(function()
        while combatZoneMarker and ClientData.InGame do
            Wait(0)
            
            local pos = combatZoneMarker
            local radius = Config.Game.CombatZone.Radius
            local height = Config.Game.CombatZone.Height
            local color = Config.Game.CombatZone.Marker.Color
            
            -- Dessiner un cylindre vertical
            DrawMarker(
                1, -- Type: Cylindre vertical
                pos.x, pos.y, pos.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                radius * 2, radius * 2, height,
                color.r, color.g, color.b, color.a,
                false, false, 2, false, nil, nil, false
            )
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔫 GESTION DES ARMES ET SORTIES DE VÉHICULE
-- ════════════════════════════════════════════════════════════════════════════════

-- Thread pour gérer les restrictions de sortie de véhicule
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if ClientData.InGame and ClientData.GameVehicle then
            local ped = PlayerPedId()
            local vehicle = ClientData.GameVehicle
            
            -- Si le joueur est dans le véhicule
            if IsPedInVehicle(ped, vehicle, false) then
                -- Empêcher la sortie si pas autorisé
                if not canExitVehicle and ClientData.MyRole == "chaser" then
                    DisableControlAction(0, 75, true) -- Exit Vehicle
                end
                
                -- Désactiver les armes dans le véhicule
                if Config.Advanced.DisableWeaponsInVehicle then
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 25, true) -- Aim
                end
            else
                -- Le joueur est sorti du véhicule
                if ClientData.MyRole == "chased" and GetPlayerSeatInVehicle() == -1 then
                    -- Le conducteur de l'équipe suivie est sorti
                    LogClient("INFO", "Le conducteur est sorti du véhicule")
                    
                    -- Notifier le serveur
                    local coords = GetEntityCoords(ped)
                    TriggerServerEvent('scharman:server:driverExited', {x = coords.x, y = coords.y, z = coords.z})
                    
                    -- Donner l'arme
                    GiveWeaponToPlayer(
                        Config.Weapons.Default.Name,
                        Config.Weapons.Default.Ammo,
                        Config.Weapons.Default.Components
                    )
                    
                    -- Ne vérifier qu'une seule fois
                    canExitVehicle = false
                end
                
                Wait(500) -- Réduire la charge quand hors véhicule
            end
        else
            Wait(500)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏆 FIN DE MANCHE
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:roundEnd', function(winnerTeam, roundNumber)
    LogClient("INFO", "Fin de la manche " .. roundNumber .. " - Gagnant: " .. winnerTeam)
    
    -- Notification
    local teamName = Config.Teams[winnerTeam].Name
    NotifyClient(string.format(Config.Messages.RoundWon, teamName), "success")
    
    -- Nettoyer la manche
    Wait(2000)
    CleanupRound()
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔄 NOUVELLE MANCHE
-- ════════════════════════════════════════════════════════════════════════════════

RegisterNetEvent('scharman:client:newRound', function(roundNumber, newRole)
    LogClient("INFO", "Nouvelle manche: " .. roundNumber .. " - Nouveau rôle: " .. newRole)
    
    -- Mettre à jour le rôle
    ClientData.MyRole = newRole
    ClientData.CurrentRound = roundNumber
    
    -- Réinitialiser les variables
    canExitVehicle = false
    vehicleFrozen = false
    timerActive = false
    
    -- Notification
    NotifyClient(string.format("Manche %d - Vous êtes %s", roundNumber, newRole == "chased" and "SUIVIS" or "CHASSEURS"), "info")
    
    -- Attendre les instructions du serveur
    LogClient("DEBUG", "En attente du spawn du véhicule...")
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE D'UNE MANCHE
-- ════════════════════════════════════════════════════════════════════════════════

function CleanupRound()
    LogClient("INFO", "Nettoyage de la manche")
    
    -- Supprimer le véhicule
    if ClientData.GameVehicle and DoesEntityExist(ClientData.GameVehicle) then
        DeleteVehicleSafe(ClientData.GameVehicle)
        ClientData.GameVehicle = nil
    end
    
    -- Supprimer le blip de la zone
    if ClientData.CombatZoneBlip then
        RemoveBlipSafe(ClientData.CombatZoneBlip)
        ClientData.CombatZoneBlip = nil
    end
    
    -- Supprimer le marker
    combatZoneMarker = nil
    
    -- Retirer les armes
    RemoveAllWeapons()
    
    -- Réinitialiser les variables
    canExitVehicle = false
    vehicleFrozen = false
    timerActive = false
    
    LogClient("DEBUG", "Nettoyage de la manche terminé")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🛠️ FONCTIONS UTILITAIRES
-- ════════════════════════════════════════════════════════════════════════════════

function ApplyVehicleMods(vehicle, colorTeam)
    -- Appliquer la couleur de l'équipe
    local colors = colorTeam == "Blue" and Config.Vehicles.TeamColors.Blue or Config.Vehicles.TeamColors.Red
    SetVehicleColours(vehicle, colors.Primary, colors.Secondary)
    
    -- Appliquer les modifications
    local mods = Config.Vehicles.Mods
    
    if mods.Engine >= 0 then
        SetVehicleMod(vehicle, 11, mods.Engine, false)
    end
    
    if mods.Brakes >= 0 then
        SetVehicleMod(vehicle, 12, mods.Brakes, false)
    end
    
    if mods.Transmission >= 0 then
        SetVehicleMod(vehicle, 13, mods.Transmission, false)
    end
    
    if mods.Turbo then
        ToggleVehicleMod(vehicle, 18, true)
    end
    
    if mods.Armor >= 0 then
        SetVehicleMod(vehicle, 16, mods.Armor, false)
    end
    
    LogClient("DEBUG", "Modifications du véhicule appliquées")
end

LogClient("INFO", "Module Game chargé")
