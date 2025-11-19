-- ════════════════════════════════════════════════════════════════════════════════
-- 🔧 FONCTIONS UTILITAIRES SERVEUR
-- ════════════════════════════════════════════════════════════════════════════════

-- Log avec préfixe
function LogServer(type, message)
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
    
    print(prefix .. " " .. color .. "[" .. type .. "] [SERVER]^7 " .. message)
end

-- Obtenir l'identifiant d'un joueur
function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    local identifier = nil
    
    for _, id in pairs(identifiers) do
        if string.match(id, Config.Database.IdentifierType) then
            identifier = id
            break
        end
    end
    
    if not identifier then
        LogServer("WARN", "Impossible de trouver l'identifiant pour le joueur " .. source)
    end
    
    return identifier
end

-- Obtenir le nom d'un joueur
function GetPlayerName(source)
    return GetPlayerName(source) or "Joueur Inconnu"
end

-- Générer un ID unique
function GenerateUniqueId()
    return string.format("%d-%d", os.time(), math.random(1000, 9999))
end

-- Vérifier si un joueur est connecté
function IsPlayerConnected(source)
    return GetPlayerPing(source) > 0
end

-- Obtenir tous les joueurs d'une liste de sources
function GetPlayersFromSources(sources)
    local players = {}
    
    for _, source in ipairs(sources) do
        if IsPlayerConnected(source) then
            table.insert(players, {
                source = source,
                name = GetPlayerName(source),
                identifier = GetPlayerIdentifier(source)
            })
        end
    end
    
    return players
end

-- Envoyer une notification à un joueur
function NotifyPlayer(source, message, type)
    TriggerClientEvent('scharman:client:lobbyNotification', source, message)
    LogServer("DEBUG", string.format("Notification envoyée à %d: %s", source, message))
end

-- Envoyer une notification à plusieurs joueurs
function NotifyPlayers(sources, message, type)
    for _, source in ipairs(sources) do
        NotifyPlayer(source, message, type)
    end
end

-- Obtenir un routing bucket disponible
local usedBuckets = {}

function GetAvailableBucket()
    local bucket = Config.Advanced.StartingBucket
    
    while usedBuckets[bucket] do
        bucket = bucket + 1
        
        if bucket > Config.Advanced.StartingBucket + Config.Advanced.MaxLobbies then
            LogServer("ERROR", "Nombre maximum de lobbys atteint!")
            return nil
        end
    end
    
    usedBuckets[bucket] = true
    LogServer("DEBUG", "Bucket " .. bucket .. " réservé")
    
    return bucket
end

-- Libérer un routing bucket
function ReleaseBucket(bucket)
    usedBuckets[bucket] = nil
    LogServer("DEBUG", "Bucket " .. bucket .. " libéré")
end

-- Définir le routing bucket d'un joueur
function SetPlayerBucket(source, bucket)
    SetPlayerRoutingBucket(source, bucket)
    LogServer("DEBUG", string.format("Joueur %d placé dans le bucket %d", source, bucket))
end

-- Obtenir le routing bucket d'un joueur
function GetPlayerBucket(source)
    return GetPlayerRoutingBucket(source)
end

-- Téléporter un joueur (côté serveur, pour sync)
function TeleportPlayerServer(source, coords)
    local ped = GetPlayerPed(source)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    
    if coords.w then
        SetEntityHeading(ped, coords.w)
    end
    
    LogServer("DEBUG", string.format("Joueur %d téléporté à %.2f, %.2f, %.2f", source, coords.x, coords.y, coords.z))
end

-- Obtenir les coordonnées d'un joueur
function GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    return {x = coords.x, y = coords.y, z = coords.z}
end

-- Calculer la distance entre deux coordonnées
function GetDistance(coords1, coords2)
    return math.sqrt(
        math.pow(coords2.x - coords1.x, 2) +
        math.pow(coords2.y - coords1.y, 2) +
        math.pow(coords2.z - coords1.z, 2)
    )
end

-- Copier une table (deep copy)
function DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[DeepCopy(key)] = DeepCopy(value)
        end
        setmetatable(copy, DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Mélanger un tableau (shuffle)
function ShuffleTable(tbl)
    local shuffled = DeepCopy(tbl)
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

-- Compter les éléments d'une table
function CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Vérifier si une table contient une valeur
function TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Retirer un élément d'un tableau par valeur
function RemoveFromTable(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

-- Obtenir une clé par valeur dans une table
function GetKeyByValue(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return k
        end
    end
    return nil
end

-- Formatter un timestamp en date
function FormatTimestamp(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- Obtenir la date du jour (format: YYYY-MM-DD)
function GetToday()
    return os.date("%Y-%m-%d")
end

-- Calculer le winrate
function CalculateWinrate(wins, losses)
    local total = wins + losses
    if total == 0 then
        return 0
    end
    return math.floor((wins / total) * 100)
end

-- Formatter le temps de jeu (secondes -> HH:MM:SS)
function FormatPlaytime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Enregistrer un événement dans les logs
function LogEvent(eventType, playerId, details)
    local timestamp = os.time()
    local playerName = playerId and GetPlayerName(playerId) or "Système"
    
    LogServer("INFO", string.format(
        "[%s] %s - Joueur: %s (%s) - Détails: %s",
        FormatTimestamp(timestamp),
        eventType,
        playerName,
        playerId or "N/A",
        details or "N/A"
    ))
end

-- Valider les données d'un joueur
function ValidatePlayerData(source)
    if not source then
        LogServer("ERROR", "Source invalide")
        return false
    end
    
    if not IsPlayerConnected(source) then
        LogServer("ERROR", "Joueur " .. source .. " non connecté")
        return false
    end
    
    local identifier = GetPlayerIdentifier(source)
    if not identifier then
        LogServer("ERROR", "Impossible d'obtenir l'identifiant du joueur " .. source)
        return false
    end
    
    return true
end

-- Créer un timer côté serveur
function CreateTimer(duration, callback)
    Citizen.CreateThread(function()
        local remaining = duration
        
        while remaining > 0 do
            Wait(1000)
            remaining = remaining - 1
        end
        
        if callback then
            callback()
        end
    end)
end

-- Déboguer une table (afficher son contenu)
function DebugTable(tbl, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(indentStr .. tostring(key) .. " = {")
            DebugTable(value, indent + 1)
            print(indentStr .. "}")
        else
            print(indentStr .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

LogServer("INFO", "Utilitaires serveur chargés")
