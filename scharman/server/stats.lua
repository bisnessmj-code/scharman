-- ════════════════════════════════════════════════════════════════════════════════
-- 📊 GESTION DES STATISTIQUES ET BASE DE DONNÉES
-- ════════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALISATION DE LA BASE DE DONNÉES
-- ════════════════════════════════════════════════════════════════════════════════

function InitializeDatabase()
    LogServer("INFO", "Initialisation de la base de données...")
    
    if not Config.Database.AutoCreateTable then
        LogServer("INFO", "Création automatique de la table désactivée")
        return
    end
    
    -- Créer la table si elle n'existe pas
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.Database.TableName .. [[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) NOT NULL UNIQUE,
            player_name VARCHAR(255) DEFAULT 'Inconnu',
            
            -- Stats principales
            matches_played INT DEFAULT 0,
            rounds_won INT DEFAULT 0,
            rounds_lost INT DEFAULT 0,
            kills INT DEFAULT 0,
            deaths INT DEFAULT 0,
            playtime INT DEFAULT 0,
            
            -- Timestamps
            first_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            
            INDEX idx_identifier (identifier),
            INDEX idx_rounds_won (rounds_won),
            INDEX idx_kills (kills)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            LogServer("INFO", "Table " .. Config.Database.TableName .. " créée/vérifiée avec succès")
        else
            LogServer("ERROR", "Erreur lors de la création de la table")
        end
    end)
    
    -- Créer la table pour les stats globales quotidiennes
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS scharman_daily_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            stat_date DATE NOT NULL UNIQUE,
            total_matches INT DEFAULT 0,
            total_rounds INT DEFAULT 0,
            total_kills INT DEFAULT 0,
            unique_players INT DEFAULT 0,
            
            INDEX idx_stat_date (stat_date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            LogServer("INFO", "Table scharman_daily_stats créée/vérifiée avec succès")
        else
            LogServer("ERROR", "Erreur lors de la création de la table des stats quotidiennes")
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 📈 GESTION DES STATS JOUEUR
-- ════════════════════════════════════════════════════════════════════════════════

function GetPlayerStats(source, callback)
    local identifier = GetPlayerIdentifier(source)
    
    if not identifier then
        LogServer("ERROR", "Impossible d'obtenir l'identifiant du joueur " .. source)
        callback(nil)
        return
    end
    
    LogServer("DEBUG", "Récupération des stats pour " .. identifier)
    
    -- Vérifier le cache
    if ServerData.StatsCache[identifier] then
        LogServer("DEBUG", "Stats trouvées dans le cache")
        callback(ServerData.StatsCache[identifier])
        return
    end
    
    -- Récupérer depuis la BDD
    MySQL.Async.fetchAll('SELECT * FROM ' .. Config.Database.TableName .. ' WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            -- Stats existantes
            local stats = result[1]
            
            -- Calculer le winrate
            if Config.Stats.CalculateWinrate then
                stats.winrate = CalculateWinrate(stats.rounds_won, stats.rounds_lost)
            end
            
            -- Formater le temps de jeu
            stats.playtime_formatted = FormatPlaytime(stats.playtime)
            
            -- Mettre en cache
            ServerData.StatsCache[identifier] = stats
            
            LogServer("DEBUG", "Stats récupérées depuis la BDD")
            callback(stats)
        else
            -- Créer de nouvelles stats
            CreatePlayerStats(source, identifier, callback)
        end
    end)
end

function CreatePlayerStats(source, identifier, callback)
    local playerName = GetPlayerName(source)
    
    LogServer("INFO", "Création de nouvelles stats pour " .. identifier)
    
    MySQL.Async.execute('INSERT INTO ' .. Config.Database.TableName .. ' (identifier, player_name) VALUES (@identifier, @player_name)', {
        ['@identifier'] = identifier,
        ['@player_name'] = playerName
    }, function(rowsChanged)
        if rowsChanged > 0 then
            LogServer("INFO", "Stats créées avec succès")
            
            -- Récupérer les stats créées
            GetPlayerStats(source, callback)
        else
            LogServer("ERROR", "Erreur lors de la création des stats")
            callback(nil)
        end
    end)
end

function UpdatePlayerStats(source, statsToUpdate, callback)
    local identifier = GetPlayerIdentifier(source)
    
    if not identifier then
        LogServer("ERROR", "Impossible d'obtenir l'identifiant du joueur " .. source)
        if callback then callback(false) end
        return
    end
    
    LogServer("DEBUG", "Mise à jour des stats pour " .. identifier)
    LogServer("DEBUG", "Stats à mettre à jour: " .. json.encode(statsToUpdate))
    
    -- Construire la requête de mise à jour
    local setClause = {}
    local params = {['@identifier'] = identifier}
    
    for stat, value in pairs(statsToUpdate) do
        if TableContains(Config.Stats.TrackedStats, stat) then
            table.insert(setClause, stat .. " = " .. stat .. " + @" .. stat)
            params['@' .. stat] = value
        end
    end
    
    if #setClause == 0 then
        LogServer("WARN", "Aucune stat valide à mettre à jour")
        if callback then callback(false) end
        return
    end
    
    local query = 'UPDATE ' .. Config.Database.TableName .. ' SET ' .. table.concat(setClause, ', ') .. ' WHERE identifier = @identifier'
    
    MySQL.Async.execute(query, params, function(rowsChanged)
        if rowsChanged > 0 then
            LogServer("INFO", "Stats mises à jour avec succès")
            
            -- Invalider le cache
            ServerData.StatsCache[identifier] = nil
            
            if callback then callback(true) end
        else
            LogServer("ERROR", "Erreur lors de la mise à jour des stats")
            if callback then callback(false) end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🌍 GESTION DES STATS GLOBALES
-- ════════════════════════════════════════════════════════════════════════════════

function GetGlobalStats(callback)
    if not Config.Stats.DailyGlobalStats then
        callback({})
        return
    end
    
    LogServer("DEBUG", "Récupération des stats globales")
    
    -- Stats du jour
    local today = GetToday()
    
    MySQL.Async.fetchAll('SELECT * FROM scharman_daily_stats WHERE stat_date = @date', {
        ['@date'] = today
    }, function(result)
        if result[1] then
            LogServer("DEBUG", "Stats globales récupérées")
            callback(result[1])
        else
            -- Créer l'entrée du jour
            CreateDailyStats(today, callback)
        end
    end)
    
    -- Top joueurs (top 10)
    MySQL.Async.fetchAll('SELECT player_name, rounds_won, kills, deaths FROM ' .. Config.Database.TableName .. ' ORDER BY rounds_won DESC LIMIT 10', {}, function(topPlayers)
        LogServer("DEBUG", "Top joueurs récupérés: " .. #topPlayers)
    end)
end

function CreateDailyStats(date, callback)
    LogServer("INFO", "Création des stats quotidiennes pour " .. date)
    
    MySQL.Async.execute('INSERT INTO scharman_daily_stats (stat_date) VALUES (@date)', {
        ['@date'] = date
    }, function(rowsChanged)
        if rowsChanged > 0 then
            LogServer("INFO", "Stats quotidiennes créées")
            GetGlobalStats(callback)
        else
            LogServer("ERROR", "Erreur lors de la création des stats quotidiennes")
            callback({})
        end
    end)
end

function UpdateDailyStats(statsToUpdate)
    local today = GetToday()
    
    LogServer("DEBUG", "Mise à jour des stats quotidiennes")
    
    local setClause = {}
    local params = {['@date'] = today}
    
    for stat, value in pairs(statsToUpdate) do
        table.insert(setClause, stat .. " = " .. stat .. " + @" .. stat)
        params['@' .. stat] = value
    end
    
    if #setClause == 0 then
        return
    end
    
    local query = 'UPDATE scharman_daily_stats SET ' .. table.concat(setClause, ', ') .. ' WHERE stat_date = @date'
    
    MySQL.Async.execute(query, params, function(rowsChanged)
        if rowsChanged > 0 then
            LogServer("DEBUG", "Stats quotidiennes mises à jour")
        else
            LogServer("ERROR", "Erreur lors de la mise à jour des stats quotidiennes")
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🏆 GESTION DES STATS DE FIN DE PARTIE
-- ════════════════════════════════════════════════════════════════════════════════

function RecordMatchEnd(lobbyId, winnerTeam, gameStats)
    LogServer("INFO", "Enregistrement des stats de fin de partie - Lobby: " .. lobbyId)
    LogServer("DEBUG", "Stats de la partie: " .. json.encode(gameStats))
    
    local lobby = ServerData.Lobbies[lobbyId]
    
    if not lobby then
        LogServer("ERROR", "Lobby introuvable: " .. lobbyId)
        return
    end
    
    -- Mettre à jour les stats de chaque joueur
    for _, playerData in ipairs(lobby.players) do
        local source = playerData.source
        local team = playerData.team
        
        if IsPlayerConnected(source) then
            local statsUpdate = {
                matches_played = 1
            }
            
            -- Calculer les rounds gagnés/perdus
            if team == winnerTeam then
                statsUpdate.rounds_won = gameStats[team].roundsWon or 0
                statsUpdate.rounds_lost = gameStats[team == "Blue" and "Red" or "Blue"].roundsWon or 0
            else
                statsUpdate.rounds_lost = gameStats[team].roundsWon or 0
                statsUpdate.rounds_won = gameStats[team == "Blue" and "Red" or "Blue"].roundsWon or 0
            end
            
            -- Kills et morts
            statsUpdate.kills = gameStats.players[source].kills or 0
            statsUpdate.deaths = gameStats.players[source].deaths or 0
            
            -- Temps de jeu (approximatif)
            statsUpdate.playtime = gameStats.duration or 0
            
            -- Mettre à jour les stats
            UpdatePlayerStats(source, statsUpdate, function(success)
                if success then
                    NotifyPlayer(source, Config.Messages.StatsUpdated, "success")
                end
            end)
        end
    end
    
    -- Mettre à jour les stats quotidiennes
    UpdateDailyStats({
        total_matches = 1,
        total_rounds = (gameStats.Blue.roundsWon or 0) + (gameStats.Red.roundsWon or 0),
        total_kills = gameStats.totalKills or 0,
        unique_players = #lobby.players
    })
end

-- ════════════════════════════════════════════════════════════════════════════════
-- 🔧 FONCTIONS UTILITAIRES
-- ════════════════════════════════════════════════════════════════════════════════

function ClearStatsCache(identifier)
    ServerData.StatsCache[identifier] = nil
    LogServer("DEBUG", "Cache des stats nettoyé pour " .. identifier)
end

function GetTopPlayers(limit, callback)
    limit = limit or 10
    
    MySQL.Async.fetchAll('SELECT player_name, rounds_won, kills, deaths FROM ' .. Config.Database.TableName .. ' ORDER BY rounds_won DESC LIMIT @limit', {
        ['@limit'] = limit
    }, function(result)
        callback(result)
    end)
end

LogServer("INFO", "Module Stats chargé")
