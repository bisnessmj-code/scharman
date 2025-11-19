fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Scharman Development'
description 'Mini-jeu de course-poursuite 2v2 en instance - Scharman'
version '1.0.0'

-- Configuration partagée
shared_scripts {
    'config.lua'
}

-- Scripts client
client_scripts {
    'client/utils.lua',
    'client/main.lua',
    'client/ped.lua',
    'client/ui.lua',
    'client/lobby.lua',
    'client/game.lua'
}

-- Scripts serveur
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Dépendance oxmysql
    'server/utils.lua',
    'server/main.lua',
    'server/stats.lua',
    'server/matchmaking.lua',
    'server/game.lua'
}

-- Interface NUI
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*.png',
    'html/assets/*.jpg'
}

-- Dépendances
dependencies {
    'oxmysql' -- Requis pour la gestion des stats
}
