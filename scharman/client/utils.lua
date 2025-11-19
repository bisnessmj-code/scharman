-- ════════════════════════════════════════════════════════════════════════════════
-- 🔧 FONCTIONS UTILITAIRES CLIENT
-- ════════════════════════════════════════════════════════════════════════════════

-- Log avec préfixe
function LogClient(type, message)
    if not Config.Debug and type == "DEBUG" then return end
    
    local prefix = Config.LogPrefix
    local color = "^7"
    
    if type == "INFO" then
        color = "^2"
    elseif type == "WARN" then
        color = "^3"
    elseif type == "ERROR" then
        color = "^1"
    elseif type == "DEBUG" then
        color = "^5"
    end
    
    print(prefix .. " " .. color .. "[" .. type .. "]^7 " .. message)
end

-- Notification simple
function NotifyClient(message, type)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, false)
    
    LogClient("INFO", "Notification envoyée: " .. message)
end

-- Help text en bas d'écran
function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Obtenir les coordonnées du joueur
function GetPlayerCoords()
    local ped = PlayerPedId()
    return GetEntityCoords(ped)
end

-- Calculer la distance entre deux coordonnées
function GetDistance(coords1, coords2)
    return #(vector3(coords1.x, coords1.y, coords1.z) - vector3(coords2.x, coords2.y, coords2.z))
end

-- Téléporter le joueur
function TeleportPlayer(coords)
    local ped = PlayerPedId()
    
    -- Désactiver les contrôles pendant le téléportation
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Téléportation
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w or 0.0)
    
    -- Attendre que le joueur soit chargé
    Wait(500)
    DoScreenFadeIn(500)
    
    LogClient("DEBUG", string.format("Joueur téléporté à %.2f, %.2f, %.2f", coords.x, coords.y, coords.z))
end

-- Freeze le joueur
function FreezePlayer(toggle)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, toggle)
    
    LogClient("DEBUG", "Joueur freeze: " .. tostring(toggle))
end

-- Créer un PED
function CreatePedAtCoords(model, coords, heading, scenario)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(100)
    end
    
    local ped = CreatePed(4, GetHashKey(model), coords.x, coords.y, coords.z, heading, false, true)
    
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    
    if scenario then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end
    
    LogClient("DEBUG", "PED créé: " .. model .. " à " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
    
    return ped
end

-- Créer un blip
function CreateBlipAtCoords(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    
    LogClient("DEBUG", "Blip créé: " .. label)
    
    return blip
end

-- Supprimer un blip
function RemoveBlipSafe(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
        LogClient("DEBUG", "Blip supprimé")
    end
end

-- Créer un véhicule
function CreateVehicleAtCoords(model, coords, heading)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(100)
    end
    
    local vehicle = CreateVehicle(GetHashKey(model), coords.x, coords.y, coords.z, heading, true, false)
    
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, "OFF")
    
    LogClient("DEBUG", "Véhicule créé: " .. model .. " à " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
    
    return vehicle
end

-- Placer le joueur dans un véhicule
function PutPlayerInVehicle(vehicle, seat)
    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, seat)
    
    LogClient("DEBUG", "Joueur placé dans le véhicule, siège: " .. seat)
end

-- Désactiver le tir depuis le véhicule
function DisableVehicleShooting(vehicle)
    SetPedCanBeShotInVehicle(PlayerPedId(), false)
    
    Citizen.CreateThread(function()
        while DoesEntityExist(vehicle) and IsPedInVehicle(PlayerPedId(), vehicle, false) do
            DisableControlAction(0, 24, true) -- Attack (tir)
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 140, true) -- Light melee
            DisableControlAction(0, 141, true) -- Heavy melee
            DisableControlAction(0, 142, true) -- Melee block
            DisableControlAction(0, 257, true) -- Attack 2
            Wait(0)
        end
    end)
    
    LogClient("DEBUG", "Tir désactivé pour le véhicule")
end

-- Donner une arme au joueur
function GiveWeaponToPlayer(weaponName, ammo, components)
    local ped = PlayerPedId()
    
    -- Retirer toutes les armes si configuré
    if Config.Weapons.RemoveAllWeapons then
        RemoveAllPedWeapons(ped, true)
    end
    
    -- Donner l'arme
    GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, true)
    
    -- Ajouter les composants
    if components then
        for _, component in ipairs(components) do
            GiveWeaponComponentToPed(ped, GetHashKey(weaponName), GetHashKey(component))
        end
    end
    
    -- Sélectionner l'arme
    SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
    
    LogClient("DEBUG", "Arme donnée: " .. weaponName .. " avec " .. ammo .. " munitions")
end

-- Supprimer toutes les armes
function RemoveAllWeapons()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    
    LogClient("DEBUG", "Toutes les armes supprimées")
end

-- Dessiner un marker 3D
function DrawMarker3D(type, pos, dir, rot, scale, color, bobUpAndDown, faceCamera, rotate)
    DrawMarker(
        type, 
        pos.x, pos.y, pos.z,
        dir.x, dir.y, dir.z,
        rot.x, rot.y, rot.z,
        scale.x, scale.y, scale.z,
        color.r, color.g, color.b, color.a,
        bobUpAndDown or false,
        faceCamera or false,
        2,
        rotate or false,
        nil,
        nil,
        false
    )
end

-- Dessiner du texte 3D
function DrawText3D(coords, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistance(coords, {x = px, y = py, z = pz})
    
    scale = (scale or 1) / dist * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Vérifier si un joueur est dans un véhicule
function IsPlayerInVehicle()
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

-- Obtenir le véhicule du joueur
function GetPlayerVehicle()
    local ped = PlayerPedId()
    return GetVehiclePedIsIn(ped, false)
end

-- Obtenir le siège du joueur dans le véhicule
function GetPlayerSeatInVehicle()
    local ped = PlayerPedId()
    local vehicle = GetPlayerVehicle()
    
    if vehicle == 0 then return -1 end
    
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            return i
        end
    end
    
    return -1
end

-- Freeze un véhicule
function FreezeVehicle(vehicle, toggle)
    FreezeEntityPosition(vehicle, toggle)
    SetVehicleEngineOn(vehicle, not toggle, true, true)
    
    LogClient("DEBUG", "Véhicule freeze: " .. tostring(toggle))
end

-- Supprimer un véhicule proprement
function DeleteVehicleSafe(vehicle)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        LogClient("DEBUG", "Véhicule supprimé")
    end
end

-- Formatter le temps en minutes:secondes
function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

-- Afficher un compte à rebours à l'écran
function ShowCountdown(seconds, callback)
    Citizen.CreateThread(function()
        local remaining = seconds
        
        while remaining > 0 do
            SetTextFont(4)
            SetTextProportional(0)
            SetTextScale(1.5, 1.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(true)
            AddTextComponentString(tostring(remaining))
            DrawText(0.5, 0.4)
            
            PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
            
            remaining = remaining - 1
            Wait(1000)
        end
        
        -- Son et texte final "GO!"
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        
        for i = 1, 10 do
            SetTextFont(4)
            SetTextProportional(0)
            SetTextScale(2.0, 2.0)
            SetTextColour(0, 255, 0, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(true)
            AddTextComponentString("GO!")
            DrawText(0.5, 0.4)
            Wait(100)
        end
        
        if callback then
            callback()
        end
    end)
end

-- Afficher un timer à l'écran
function ShowTimer(duration, onUpdate, onComplete)
    Citizen.CreateThread(function()
        local remaining = duration
        
        while remaining > 0 do
            SetTextFont(4)
            SetTextProportional(0)
            SetTextScale(0.8, 0.8)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(true)
            AddTextComponentString("Temps restant: " .. FormatTime(remaining))
            DrawText(0.5, 0.05)
            
            if onUpdate then
                onUpdate(remaining)
            end
            
            remaining = remaining - 1
            Wait(1000)
        end
        
        if onComplete then
            onComplete()
        end
    end)
end

LogClient("INFO", "Utilitaires client chargés")
