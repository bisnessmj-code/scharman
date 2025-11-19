-- ════════════════════════════════════════════════════════════════════════════════
-- 👤 GESTION DU PED D'INTERACTION
-- ════════════════════════════════════════════════════════════════════════════════

local pedEntity = nil
local pedBlip = nil
local nearPed = false

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION DU PED
-- ════════════════════════════════════════════════════════════════════════════════

function InitializePed()
    LogClient("INFO", "Initialisation du PED d'interaction...")
    
    -- Créer le PED
    local coords = Config.Ped.Coords
    pedEntity = CreatePedAtCoords(
        Config.Ped.Model,
        coords,
        coords.w or 0.0,
        Config.Ped.Scenario
    )
    
    -- Rendre le PED invincible si configuré
    if Config.Ped.Invincible then
        SetEntityInvincible(pedEntity, true)
    end
    
    -- Freeze le PED si configuré
    if Config.Ped.Freeze then
        FreezeEntityPosition(pedEntity, true)
    end
    
    -- Créer le blip si activé
    if Config.Ped.Blip.Enable then
        pedBlip = CreateBlipAtCoords(
            coords,
            Config.Ped.Blip.Sprite,
            Config.Ped.Blip.Color,
            Config.Ped.Blip.Scale,
            Config.Ped.Blip.Label
        )
    end
    
    LogClient("INFO", "PED d'interaction créé avec succès")
    
    -- Lancer le thread d'interaction
    StartPedInteractionThread()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔄 THREAD D'INTERACTION
-- ════════════════════════════════════════════════════════════════════════════════

function StartPedInteractionThread()
    Citizen.CreateThread(function()
        LogClient("DEBUG", "Thread d'interaction PED démarré")
        
        while true do
            local sleep = 500
            
            -- Ne pas gérer l'interaction si le joueur est déjà dans un lobby ou en jeu
            if not ClientData.InLobby and not ClientData.InGame then
                local playerCoords = GetPlayerCoords()
                local pedCoords = GetEntityCoords(pedEntity)
                local distance = GetDistance(playerCoords, pedCoords)
                
                -- Joueur proche du PED
                if distance < Config.Ped.InteractionDistance then
                    sleep = 0
                    nearPed = true
                    
                    -- Afficher le help text
                    DisplayHelpText(Config.Ped.InteractionText)
                    
                    -- Vérifier la touche d'interaction
                    if IsControlJustPressed(0, Config.Ped.InteractionKey) then
                        LogClient("DEBUG", "Interaction avec le PED détectée")
                        OnPedInteraction()
                    end
                else
                    if nearPed then
                        nearPed = false
                        LogClient("DEBUG", "Joueur éloigné du PED")
                    end
                end
            else
                sleep = 1000 -- Réduire la charge quand le joueur est occupé
            end
            
            Wait(sleep)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🎯 GESTION DE L'INTERACTION
-- ════════════════════════════════════════════════════════════════════════════════

function OnPedInteraction()
    LogClient("INFO", "Ouverture de l'interface principale")
    
    -- Jouer un son d'interaction (optionnel)
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    
    -- Ouvrir l'UI principale
    OpenMainUI()
    
    -- Logger l'action
    LogClient("DEBUG", "Interface principale ouverte")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🧹 NETTOYAGE DU PED
-- ════════════════════════════════════════════════════════════════════════════════

function CleanupPed()
    LogClient("INFO", "Nettoyage du PED...")
    
    -- Supprimer le PED
    if pedEntity and DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
        pedEntity = nil
        LogClient("DEBUG", "PED supprimé")
    end
    
    -- Supprimer le blip
    if pedBlip then
        RemoveBlipSafe(pedBlip)
        pedBlip = nil
        LogClient("DEBUG", "Blip du PED supprimé")
    end
    
    LogClient("INFO", "Nettoyage du PED terminé")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 📊 GETTERS
-- ════════════════════════════════════════════════════════════════════════════════

function GetPedEntity()
    return pedEntity
end

function IsNearPed()
    return nearPed
end

LogClient("INFO", "Module PED chargé")
