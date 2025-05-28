// Verificação de autenticação
window.addEventListener('DOMContentLoaded', async () => {
    try {
        const res = await fetch('http://localhost:5050/auth/status', {
            method: 'GET',
            credentials: 'include'
        });
        
        if (!res.ok) {
            window.location.href = '/NotiSync/frontend/index.html';
            return;
        }

        const data = await res.json();
        document.querySelector('.user-name').textContent = data.user;
        
        // Carregar dados do dashboard
        await loadDashboardData();
    } catch (error) {
        console.error('Erro ao verificar autenticação:', error);
        window.location.href = '/NotiSync/frontend/index.html';
    }
});

// Função para carregar dados do dashboard
async function loadDashboardData() {
    try {
        // Carregar estatísticas
        const statsRes = await fetch('http://localhost:5050/dashboard/resumo', {
            method: 'GET',
            credentials: 'include'
        });
        
        if (statsRes.ok) {
            const stats = await statsRes.json();
            updateStats(stats);
        }

        // Carregar atividades recentes
        const activityRes = await fetch('http://localhost:5050/dashboard/recentes', {
            method: 'GET',
            credentials: 'include'
        });
        
        if (activityRes.ok) {
            const activities = await activityRes.json();
            updateActivities(activities);
        }
    } catch (error) {
        console.error('Erro ao carregar dados do dashboard:', error);
        showError('Não foi possível carregar os dados do dashboard');
    }
}

// Atualizar estatísticas
function updateStats(stats) {
    // Atualizar números nas cards de estatísticas
    document.querySelector('.stat-card:nth-child(1) .stat-number').textContent = stats.total_enviadas.toLocaleString();
    document.querySelector('.stat-card:nth-child(2) .stat-number').textContent = stats.pendentes.toLocaleString();
    document.querySelector('.stat-card:nth-child(3) .stat-number').textContent = stats.erros.toLocaleString();
    document.querySelector('.stat-card:nth-child(4) .stat-number').textContent = `${stats.taxa_sucesso}%`;

    // Atualizar tendências (se disponíveis)
    if (stats.tendencia_total) {
        const changeElement = document.querySelector('.stat-card:nth-child(1) .stat-change');
        updateStatChange(changeElement, stats.tendencia_total);
    }
    if (stats.tendencia_pendentes) {
        const changeElement = document.querySelector('.stat-card:nth-child(2) .stat-change');
        updateStatChange(changeElement, stats.tendencia_pendentes);
    }
    if (stats.tendencia_erros) {
        const changeElement = document.querySelector('.stat-card:nth-child(3) .stat-change');
        updateStatChange(changeElement, stats.tendencia_erros);
    }
    if (stats.tendencia_taxa) {
        const changeElement = document.querySelector('.stat-card:nth-child(4) .stat-change');
        updateStatChange(changeElement, stats.tendencia_taxa);
    }
}

// Atualizar mudança nas estatísticas
function updateStatChange(element, change) {
    if (!element) return;
    
    const isPositive = change > 0;
    const isNegative = change < 0;
    
    element.textContent = `${isPositive ? '+' : ''}${change}% esta semana`;
    element.className = 'stat-change ' + (isPositive ? 'positive' : isNegative ? 'negative' : '');
}

// Atualizar lista de atividades
function updateActivities(activities) {
    const activityList = document.querySelector('.activity-list');
    if (!activityList) return;

    activityList.innerHTML = activities.map(activity => `
        <div class="activity-item">
            <div class="activity-icon ${getActivityIconClass(activity.estado)}">
                <i class="fas ${getActivityIcon(activity.estado)}"></i>
            </div>
            <div class="activity-details">
                <p class="activity-title">${activity.mensagem}</p>
                <p class="activity-meta">${activity.canais} • ${activity.tipo} • ${activity.data}</p>
            </div>
        </div>
    `).join('');
}

// Obter classe do ícone baseado no status
function getActivityIconClass(status) {
    switch (status.toLowerCase()) {
        case 'sucesso':
            return 'success';
        case 'pendente':
            return 'warning';
        case 'erro':
            return 'error';
        default:
            return '';
    }
}

// Obter ícone baseado no status
function getActivityIcon(status) {
    switch (status.toLowerCase()) {
        case 'sucesso':
            return 'fa-check';
        case 'pendente':
            return 'fa-clock';
        case 'erro':
            return 'fa-times';
        default:
            return 'fa-info-circle';
    }
}

// Mostrar mensagem de erro
function showError(message) {
    // Implementar sistema de notificações de erro
    console.error(message);
    // TODO: Adicionar sistema de notificações toast
}

// Event Listeners para ações rápidas
document.querySelectorAll('.action-button').forEach(button => {
    button.addEventListener('click', (e) => {
        const action = e.target.textContent.trim();
        switch (action) {
            case 'Nova Notificação':
                window.location.href = '/NotiSync/frontend/pages/create-notification.html';
                break;
            case 'Exportar Relatório':
                exportReport();
                break;
        }
    });
});

// Função para exportar relatório
async function exportReport() {
    try {
        const res = await fetch('http://localhost:5050/dashboard/export', {
            method: 'GET',
            credentials: 'include'
        });
        
        if (res.ok) {
            const blob = await res.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `relatorio-notisync-${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
        } else {
            showError('Não foi possível exportar o relatório');
        }
    } catch (error) {
        console.error('Erro ao exportar relatório:', error);
        showError('Erro ao exportar relatório');
    }
}

// Pesquisa
const searchInput = document.querySelector('.search-box input');
let searchTimeout;

searchInput.addEventListener('input', (e) => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        const query = e.target.value.trim();
        if (query.length >= 2) {
            searchNotifications(query);
        }
    }, 300);
});

async function searchNotifications(query) {
    try {
        const res = await fetch(`http://localhost:5050/notifications/search?q=${encodeURIComponent(query)}`, {
            method: 'GET',
            credentials: 'include'
        });
        
        if (res.ok) {
            const results = await res.json();
            // TODO: Implementar exibição dos resultados da pesquisa
            console.log('Resultados da pesquisa:', results);
        }
    } catch (error) {
        console.error('Erro na pesquisa:', error);
    }
} 