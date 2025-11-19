// ═══════════════════════════════════════════════════════════════════════════════
// 🎮 SCRIPT NUI - Gestion de l'interface
// ═══════════════════════════════════════════════════════════════════════════════

// État de l'interface
const UIState = {
    mainUIOpen: false,
    lobbyUIOpen: false,
    currentTeam: null,
    isReady: false
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 INITIALISATION
// ═══════════════════════════════════════════════════════════════════════════════

window.addEventListener('DOMContentLoaded', function() {
    console.log('🎮 Interface Scharman chargée');
    
    // Initialiser les tabs
    initializeTabs();
    
    // Écouter les messages depuis Lua
    window.addEventListener('message', handleNUIMessage);
    
    // Désactiver le clic droit
    document.addEventListener('contextmenu', (e) => e.preventDefault());
    
    // ESC pour fermer
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (UIState.lobbyUIOpen) {
                closeLobbyUI();
            } else if (UIState.mainUIOpen) {
                closeMainUI();
            }
        }
    });
});

// ═══════════════════════════════════════════════════════════════════════════════
// 📨 GESTION DES MESSAGES NUI
// ═══════════════════════════════════════════════════════════════════════════════

function handleNUIMessage(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'openMainUI':
            openMainUI(data.data);
            break;
            
        case 'closeMainUI':
            closeMainUI();
            break;
            
        case 'updateStats':
            updateStats(data.data.playerStats, data.data.globalStats);
            break;
            
        case 'openLobbyUI':
            openLobbyUI();
            break;
            
        case 'closeLobbyUI':
            closeLobbyUI();
            break;
            
        case 'updateLobbyData':
            updateLobbyData(data.data);
            break;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🎨 GESTION DES TABS
// ═══════════════════════════════════════════════════════════════════════════════

function initializeTabs() {
    const tabButtons = document.querySelectorAll('.tab-btn');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetTab = button.getAttribute('data-tab');
            switchTab(targetTab);
        });
    });
}

function switchTab(tabName) {
    // Désactiver tous les tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    // Activer le tab sélectionné
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    document.getElementById(`${tabName}Tab`).classList.add('active');
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🖥️ INTERFACE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════════

function openMainUI(data) {
    console.log('📂 Ouverture de l\'interface principale', data);
    
    const mainUI = document.getElementById('mainUI');
    mainUI.classList.remove('hidden');
    UIState.mainUIOpen = true;
    
    // Mettre à jour le titre si fourni
    if (data && data.title) {
        document.getElementById('uiTitle').textContent = data.title;
    }
}

function closeMainUI() {
    console.log('📁 Fermeture de l\'interface principale');
    
    const mainUI = document.getElementById('mainUI');
    mainUI.classList.add('hidden');
    UIState.mainUIOpen = false;
    
    // Notifier Lua
    sendNUICallback('closeUI');
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📊 GESTION DES STATS
// ═══════════════════════════════════════════════════════════════════════════════

function updateStats(playerStats, globalStats) {
    console.log('📊 Mise à jour des stats', playerStats, globalStats);
    
    if (playerStats) {
        // Stats personnelles
        document.getElementById('matchesPlayed').textContent = playerStats.matches_played || 0;
        document.getElementById('roundsWon').textContent = playerStats.rounds_won || 0;
        document.getElementById('roundsLost').textContent = playerStats.rounds_lost || 0;
        document.getElementById('winrate').textContent = (playerStats.winrate || 0) + '%';
        document.getElementById('kills').textContent = playerStats.kills || 0;
        document.getElementById('deaths').textContent = playerStats.deaths || 0;
        document.getElementById('playtime').textContent = playerStats.playtime_formatted || '00:00:00';
        
        // Calculer le K/D
        const kills = playerStats.kills || 0;
        const deaths = playerStats.deaths || 1;
        const kd = (kills / deaths).toFixed(2);
        document.getElementById('kd').textContent = kd;
    }
    
    if (globalStats) {
        // Stats globales
        document.getElementById('globalMatches').textContent = globalStats.total_matches || 0;
        document.getElementById('globalRounds').textContent = globalStats.total_rounds || 0;
        document.getElementById('globalKills').textContent = globalStats.total_kills || 0;
        document.getElementById('globalPlayers').textContent = globalStats.unique_players || 0;
    }
}

function refreshStats() {
    console.log('🔄 Rafraîchissement des stats demandé');
    sendNUICallback('refreshStats');
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🎮 REJOINDRE LA SALLE D'ATTENTE
// ═══════════════════════════════════════════════════════════════════════════════

function joinWaitingRoom() {
    console.log('🎯 Rejoindre la salle d\'attente');
    
    sendNUICallback('joinWaitingRoom', {}, (response) => {
        if (response.success) {
            console.log('✅ Demande de rejoindre acceptée');
        } else {
            console.error('❌ Erreur:', response.message);
            alert(response.message);
        }
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🏠 INTERFACE DU LOBBY
// ═══════════════════════════════════════════════════════════════════════════════

function openLobbyUI() {
    console.log('📂 Ouverture de l\'interface du lobby');
    
    const lobbyUI = document.getElementById('lobbyUI');
    lobbyUI.classList.remove('hidden');
    UIState.lobbyUIOpen = true;
}

function closeLobbyUI() {
    console.log('📁 Fermeture de l\'interface du lobby');
    
    const lobbyUI = document.getElementById('lobbyUI');
    lobbyUI.classList.add('hidden');
    UIState.lobbyUIOpen = false;
    
    // Notifier Lua
    sendNUICallback('closeLobbyUI');
}

// ═══════════════════════════════════════════════════════════════════════════════
// 👥 GESTION DU LOBBY
// ═══════════════════════════════════════════════════════════════════════════════

function updateLobbyData(data) {
    console.log('🔄 Mise à jour des données du lobby', data);
    
    const lobbyData = data.lobbyData;
    const teams = data.teams;
    const currentTeam = data.currentTeam;
    const isReady = data.isReady;
    
    // Mettre à jour l'état
    UIState.currentTeam = currentTeam;
    UIState.isReady = isReady;
    
    // Mettre à jour le compteur de joueurs
    document.getElementById('lobbyPlayerCount').textContent = lobbyData.playerCount || 0;
    
    // Mettre à jour les équipes
    updateTeamDisplay('Blue', lobbyData.teams.Blue);
    updateTeamDisplay('Red', lobbyData.teams.Red);
    
    // Mettre à jour le bouton Ready
    updateReadyButton(isReady);
    
    // Mettre à jour le message
    updateLobbyMessage(lobbyData, currentTeam, isReady);
}

function updateTeamDisplay(teamColor, teamPlayers) {
    const teamContainer = document.getElementById(teamColor.toLowerCase() + 'Players');
    const teamCount = document.getElementById(teamColor.toLowerCase() + 'TeamCount');
    
    // Mettre à jour le compteur
    teamCount.textContent = `${teamPlayers.length}/2`;
    
    // Vider le conteneur
    teamContainer.innerHTML = '';
    
    // Ajouter les joueurs
    for (let i = 0; i < 2; i++) {
        if (teamPlayers[i]) {
            const playerSlot = document.createElement('div');
            playerSlot.className = 'player-slot' + (teamPlayers[i].isReady ? ' ready' : '');
            playerSlot.textContent = teamPlayers[i].name;
            teamContainer.appendChild(playerSlot);
        } else {
            const emptySlot = document.createElement('div');
            emptySlot.className = 'empty-slot';
            emptySlot.textContent = 'Slot vide';
            teamContainer.appendChild(emptySlot);
        }
    }
}

function updateReadyButton(isReady) {
    const readyBtn = document.getElementById('readyBtn');
    
    if (isReady) {
        readyBtn.classList.add('active');
        readyBtn.textContent = '✓ Prêt';
    } else {
        readyBtn.classList.remove('active');
        readyBtn.textContent = '✓ Je suis Prêt';
    }
}

function updateLobbyMessage(lobbyData, currentTeam, isReady) {
    const messageEl = document.getElementById('lobbyMessage');
    let message = '';
    
    if (!currentTeam) {
        message = '⚠️ Choisissez votre équipe pour commencer!';
    } else if (!isReady) {
        message = '⏳ Cliquez sur "Je suis Prêt" quand vous êtes prêt!';
    } else if (lobbyData.playerCount < 4) {
        message = `⏳ En attente de joueurs... (${lobbyData.playerCount}/4)`;
    } else {
        message = '✅ Tous les joueurs sont présents! En attente que tout le monde soit prêt...';
    }
    
    messageEl.textContent = message;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🎯 ACTIONS DU LOBBY
// ═══════════════════════════════════════════════════════════════════════════════

function selectTeam(team) {
    console.log('🎨 Sélection de l\'équipe:', team);
    
    sendNUICallback('changeTeam', { team: team }, (response) => {
        if (response.success) {
            console.log('✅ Équipe changée avec succès');
            UIState.currentTeam = team;
        } else {
            console.error('❌ Erreur:', response.message);
            alert(response.message);
        }
    });
}

function toggleReady() {
    const newReadyState = !UIState.isReady;
    console.log('✅ Changement d\'état prêt:', newReadyState);
    
    sendNUICallback('toggleReady', { isReady: newReadyState }, (response) => {
        if (response.success) {
            console.log('✅ État prêt changé avec succès');
            UIState.isReady = newReadyState;
            updateReadyButton(newReadyState);
        } else {
            console.error('❌ Erreur:', response.message);
        }
    });
}

function leaveLobby() {
    console.log('👋 Quitter le lobby');
    
    if (confirm('Êtes-vous sûr de vouloir quitter le lobby?')) {
        sendNUICallback('leaveLobby', {}, (response) => {
            if (response.success) {
                console.log('✅ Lobby quitté avec succès');
                closeLobbyUI();
            }
        });
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔗 COMMUNICATION AVEC LUA
// ═══════════════════════════════════════════════════════════════════════════════

function sendNUICallback(action, data = {}, callback) {
    console.log('📤 Envoi callback NUI:', action, data);
    
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(responseData => {
        if (callback) {
            callback(responseData);
        }
    })
    .catch(error => {
        console.error('❌ Erreur callback NUI:', error);
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔧 FONCTIONS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════════════

function GetParentResourceName() {
    // Récupérer le nom de la ressource parente
    if (window.location.hostname === 'nui-game-internal') {
        return window.location.pathname.split('/')[1];
    }
    return 'scharman'; // Fallback pour les tests
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🧪 MODE DEBUG (Pour tester l'interface sans FiveM)
// ═══════════════════════════════════════════════════════════════════════════════

if (window.location.hostname !== 'nui-game-internal') {
    console.log('🧪 Mode DEBUG activé - Interface testable dans le navigateur');
    
    // Simuler l'ouverture de l'UI après 1 seconde
    setTimeout(() => {
        openMainUI({ title: 'Scharman - Course-poursuite 2v2 [DEBUG]' });
        
        // Simuler des stats
        updateStats({
            matches_played: 42,
            rounds_won: 85,
            rounds_lost: 41,
            winrate: 67,
            kills: 156,
            deaths: 89,
            playtime_formatted: '12:34:56'
        }, {
            total_matches: 1523,
            total_rounds: 4569,
            total_kills: 18234,
            unique_players: 387
        });
    }, 1000);
}

console.log('✅ Script NUI Scharman chargé avec succès!');
