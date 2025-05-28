// Funções de API
async function fetchAPI(endpoint, options = {}) {
    try {
        const response = await fetch(`http://localhost:5050${endpoint}`, {
            ...options,
            credentials: 'include',
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Erro na requisição');
        }

        return await response.json();
    } catch (error) {
        showNotification(error.message, 'error');
        throw error;
    }
}

// Gerenciamento do Modal
async function showNotificationDetails(notificationId) {
    const modal = document.getElementById('notificationDetailsModal');
    if (!modal) return;
    
    try {
        const notification = await fetchAPI(`/notifications/${notificationId}`);
        
        modal.querySelector('.modal-title').textContent = 'Detalhes da Notificação';
        modal.querySelector('.modal-body').innerHTML = `
            <div class="details-section">
                <h3>Informações Básicas</h3>
                <p><strong>Título:</strong> ${notification.mensagem}</p>
                <p><strong>Tipo:</strong> ${notification.tipo}</p>
                <p><strong>Categoria:</strong> ${notification.categoria}</p>
                <p><strong>Estado:</strong> ${notification.estado}</p>
                <p><strong>Data:</strong> ${notification.data}</p>
            </div>
            ${notification.erro ? `
                <div class="details-section">
                    <h3>Erro</h3>
                    <p class="error-message">${notification.erro}</p>
                </div>
            ` : ''}
            <div class="details-section">
                <h3>Informações Adicionais</h3>
                <p><strong>Prioridade:</strong> ${notification.prioridade}</p>
                <p><strong>Tentativas:</strong> ${notification.tentativas}</p>
                ${notification.template_id ? `<p><strong>Template:</strong> #${notification.template_id}</p>` : ''}
            </div>
        `;
        
        modal.classList.add('show');
    } catch (error) {
        console.error('Erro ao carregar detalhes:', error);
        showNotification('Erro ao carregar detalhes da notificação', 'error');
    }
}

// Carregar histórico
async function carregarHistorico(page = 1, filtros = {}) {
    try {
        // Verificar autenticação antes de carregar dados
        const authRes = await fetch('http://localhost:5050/auth/status', {
            method: 'GET',
            credentials: 'include'
        });
        
        if (!authRes.ok) {
            window.location.href = '/NotiSync/frontend/index.html';
            return;
        }

        const authData = await authRes.json();
        document.querySelector('.user-name').textContent = authData.user;

        // Carregar dados do histórico
        const params = new URLSearchParams({
            page,
            per_page: 10,
            ...filtros
        });
        
        const data = await fetchAPI(`/notifications/?${params}`);
        const tbody = document.querySelector('.history-table tbody');
        if (!tbody) return;

        tbody.innerHTML = data.notificacoes.map(notif => `
            <tr>
                <td>
                    <input type="checkbox" class="row-select" onchange="updateSelectAll()">
                </td>
                <td>${notif.data}</td>
                <td>${notif.mensagem}</td>
                <td>
                    <span class="notification-type ${notif.tipo.toLowerCase()}">
                        <i class="fas ${getNotificationTypeIcon(notif.tipo)}"></i>
                        ${notif.tipo}
                    </span>
                </td>
                <td>${notif.destinatario || '---'}</td>
                <td>
                    <span class="status-badge ${notif.estado.toLowerCase()}">
                        <i class="fas ${getStatusIcon(notif.estado)}"></i>
                        ${notif.estado}
                    </span>
                </td>
                <td>
                    <div class="table-actions">
                        <button class="icon-button" onclick="showNotificationDetails(${notif.id})" title="Ver Detalhes">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="icon-button" onclick="reenviarNotificacao(${notif.id})" title="Reenviar">
                            <i class="fas fa-paper-plane"></i>
                        </button>
                        <button class="icon-button" onclick="excluirNotificacao(${notif.id})" title="Excluir">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');

        // Atualizar paginação
        atualizarPaginacao(data.pagina, data.total_paginas);
    } catch (error) {
        console.error('Erro ao carregar histórico:', error);
        showNotification('Erro ao carregar histórico', 'error');
    }
}

// Funções auxiliares
function getNotificationTypeIcon(tipo) {
    const icons = {
        'Alerta': 'fa-exclamation-triangle',
        'Aviso': 'fa-bell',
        'Informação': 'fa-info-circle',
        'Sucesso': 'fa-check-circle',
        'Erro': 'fa-times-circle'
    };
    return icons[tipo] || 'fa-bell';
}

function getStatusIcon(status) {
    const icons = {
        'Pendente': 'fa-clock',
        'Enviado': 'fa-check',
        'Erro': 'fa-times',
        'Cancelado': 'fa-ban'
    };
    return icons[status] || 'fa-question';
}

function updateSelectAll() {
    const checkboxes = document.querySelectorAll('.row-select');
    const selectAllCheckbox = document.querySelector('#select-all');
    
    if (!selectAllCheckbox) return;
    
    const allChecked = Array.from(checkboxes).every(cb => cb.checked);
    const someChecked = Array.from(checkboxes).some(cb => cb.checked);
    
    selectAllCheckbox.checked = allChecked;
    selectAllCheckbox.indeterminate = someChecked && !allChecked;
    
    // Atualizar botões de ação em massa
    const bulkActions = document.querySelector('.bulk-actions');
    if (bulkActions) {
        bulkActions.style.display = someChecked ? 'flex' : 'none';
    }
}

// Funções de ação
async function reenviarNotificacao(id) {
    if (!confirm('Deseja reenviar esta notificação?')) return;
    
    try {
        await fetchAPI(`/notifications/${id}/reenviar`, { method: 'POST' });
        showNotification('Notificação agendada para reenvio', 'success');
        await carregarHistorico();
    } catch (error) {
        console.error('Erro ao reenviar:', error);
    }
}

async function excluirNotificacao(id) {
    if (!confirm('Tem certeza que deseja excluir esta notificação?')) return;
    
    try {
        await fetchAPI(`/notifications/${id}`, { method: 'DELETE' });
        showNotification('Notificação excluída com sucesso', 'success');
        await carregarHistorico();
    } catch (error) {
        console.error('Erro ao excluir:', error);
    }
}

// Funções de UI
function closeNotificationDetails() {
    const modal = document.getElementById('notificationDetailsModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

function atualizarPaginacao(paginaAtual, totalPaginas) {
    const paginacao = document.querySelector('.pagination');
    if (!paginacao) return;

    const prevButton = paginacao.querySelector('.pagination-button:first-child');
    const nextButton = paginacao.querySelector('.pagination-button:last-child');
    const pageNumbers = paginacao.querySelector('.page-numbers');

    prevButton.disabled = paginaAtual === 1;
    nextButton.disabled = paginaAtual === totalPaginas;

    // Atualizar números das páginas
    let html = '';
    for (let i = 1; i <= totalPaginas; i++) {
        if (i === 1 || i === totalPaginas || (i >= paginaAtual - 2 && i <= paginaAtual + 2)) {
            html += `<button class="page-number ${i === paginaAtual ? 'active' : ''}" onclick="carregarHistorico(${i})">${i}</button>`;
        } else if (i === paginaAtual - 3 || i === paginaAtual + 3) {
            html += '<span class="page-ellipsis">...</span>';
        }
    }
    pageNumbers.innerHTML = html;
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    // Verificar autenticação
    fetch('http://localhost:5050/auth/status', {
        method: 'GET',
        credentials: 'include'
    }).then(res => {
        if (!res.ok) {
            window.location.href = '/NotiSync/frontend/index.html';
            return;
        }
        return res.json();
    }).then(data => {
        if (data) {
            document.querySelector('.user-name').textContent = data.user;
            carregarHistorico();
        }
    }).catch(error => {
        console.error('Erro ao verificar autenticação:', error);
        window.location.href = '/NotiSync/frontend/index.html';
    });

    // Event listener para selecionar todos
    const selectAllCheckbox = document.querySelector('#select-all');
    if (selectAllCheckbox) {
        selectAllCheckbox.addEventListener('change', (e) => {
            const checkboxes = document.querySelectorAll('.row-select');
            checkboxes.forEach(cb => cb.checked = e.target.checked);
            updateSelectAll();
        });
    }

    // Event listeners para filtros
    const filters = ['status-filter', 'type-filter', 'date-filter'];
    filters.forEach(filterId => {
        const filter = document.getElementById(filterId);
        if (filter) {
            filter.addEventListener('change', () => carregarHistorico(1));
        }
    });

    // Event listener para pesquisa
    const searchInput = document.querySelector('.search-box input');
    if (searchInput) {
        searchInput.addEventListener('input', () => carregarHistorico(1));
    }

    // Fechar modal ao clicar fora
    const modal = document.getElementById('notificationDetailsModal');
    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeNotificationDetails();
            }
        });
    }
});

// Gerenciamento de Filtros
function applyFilters() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const statusFilter = document.getElementById('statusFilter').value;
    const typeFilter = document.getElementById('typeFilter').value;
    const dateRange = document.getElementById('dateRange').value;

    const rows = document.querySelectorAll('.history-table tbody tr');
    
    rows.forEach(row => {
        const title = row.querySelector('td:nth-child(3)').textContent.toLowerCase();
        const type = row.querySelector('td:nth-child(4)').textContent.toLowerCase();
        const status = row.querySelector('td:nth-child(6)').textContent.toLowerCase();
        const date = row.querySelector('td:nth-child(2)').textContent;

        const matchesSearch = title.includes(searchTerm);
        const matchesStatus = statusFilter === 'all' || status === statusFilter.toLowerCase();
        const matchesType = typeFilter === 'all' || type === typeFilter.toLowerCase();
        const matchesDate = dateRange === 'all' || isDateInRange(date, dateRange);

        row.style.display = matchesSearch && matchesStatus && matchesType && matchesDate ? '' : 'none';
    });

    updatePagination();
}

function isDateInRange(date, range) {
    const notificationDate = new Date(date);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const lastWeek = new Date(today);
    lastWeek.setDate(lastWeek.getDate() - 7);
    const lastMonth = new Date(today);
    lastMonth.setMonth(lastMonth.getMonth() - 1);

    switch (range) {
        case 'today':
            return notificationDate.toDateString() === today.toDateString();
        case 'yesterday':
            return notificationDate.toDateString() === yesterday.toDateString();
        case 'last7days':
            return notificationDate >= lastWeek;
        case 'last30days':
            return notificationDate >= lastMonth;
        default:
            return true;
    }
}

// Gerenciamento de Paginação
let currentPage = 1;
const itemsPerPage = 10;

function updatePagination() {
    const visibleRows = Array.from(document.querySelectorAll('.history-table tbody tr'))
        .filter(row => row.style.display !== 'none');
    
    const totalPages = Math.ceil(visibleRows.length / itemsPerPage);
    const paginationContainer = document.querySelector('.pagination');
    const pageNumbers = document.querySelector('.page-numbers');
    
    // Atualizar botões de navegação
    document.getElementById('prevPage').disabled = currentPage === 1;
    document.getElementById('nextPage').disabled = currentPage === totalPages;

    // Atualizar números das páginas
    pageNumbers.innerHTML = '';
    
    if (totalPages <= 7) {
        // Mostrar todas as páginas
        for (let i = 1; i <= totalPages; i++) {
            addPageNumber(i, pageNumbers);
        }
    } else {
        // Mostrar páginas com elipses
        if (currentPage <= 3) {
            for (let i = 1; i <= 4; i++) {
                addPageNumber(i, pageNumbers);
            }
            addEllipsis(pageNumbers);
            for (let i = totalPages - 1; i <= totalPages; i++) {
                addPageNumber(i, pageNumbers);
            }
        } else if (currentPage >= totalPages - 2) {
            for (let i = 1; i <= 2; i++) {
                addPageNumber(i, pageNumbers);
            }
            addEllipsis(pageNumbers);
            for (let i = totalPages - 3; i <= totalPages; i++) {
                addPageNumber(i, pageNumbers);
            }
        } else {
            for (let i = 1; i <= 2; i++) {
                addPageNumber(i, pageNumbers);
            }
            addEllipsis(pageNumbers);
            for (let i = currentPage - 1; i <= currentPage + 1; i++) {
                addPageNumber(i, pageNumbers);
            }
            addEllipsis(pageNumbers);
            for (let i = totalPages - 1; i <= totalPages; i++) {
                addPageNumber(i, pageNumbers);
            }
        }
    }

    // Atualizar visibilidade das linhas
    visibleRows.forEach((row, index) => {
        const pageStart = (currentPage - 1) * itemsPerPage;
        const pageEnd = pageStart + itemsPerPage;
        row.style.display = index >= pageStart && index < pageEnd ? '' : 'none';
    });
}

function addPageNumber(pageNum, container) {
    const pageButton = document.createElement('button');
    pageButton.className = `page-number ${pageNum === currentPage ? 'active' : ''}`;
    pageButton.textContent = pageNum;
    pageButton.onclick = () => goToPage(pageNum);
    container.appendChild(pageButton);
}

function addEllipsis(container) {
    const ellipsis = document.createElement('span');
    ellipsis.className = 'page-ellipsis';
    ellipsis.textContent = '...';
    container.appendChild(ellipsis);
}

function goToPage(page) {
    currentPage = page;
    updatePagination();
}

function goToPreviousPage() {
    if (currentPage > 1) {
        currentPage--;
        updatePagination();
    }
}

function goToNextPage() {
    const visibleRows = Array.from(document.querySelectorAll('.history-table tbody tr'))
        .filter(row => row.style.display !== 'none');
    const totalPages = Math.ceil(visibleRows.length / itemsPerPage);
    
    if (currentPage < totalPages) {
        currentPage++;
        updatePagination();
    }
}

// Exportação
function exportHistory() {
    const format = document.getElementById('exportFormat').value;
    // Simular exportação
    showNotification(`Histórico exportado em formato ${format.toUpperCase()}!`, 'success');
}

// Limpar Histórico
function clearHistory() {
    if (confirm('Tem certeza que deseja limpar todo o histórico? Esta ação não pode ser desfeita.')) {
        // Simular limpeza
        const tbody = document.querySelector('.history-table tbody');
        tbody.innerHTML = '';
        showNotification('Histórico limpo com sucesso!', 'success');
        updatePagination();
    }
}

// Sistema de Notificações
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <span class="notification-icon">
                ${type === 'success' ? '✓' : type === 'error' ? '✕' : type === 'warning' ? '!' : 'i'}
            </span>
            <span class="notification-message">${message}</span>
        </div>
        <button class="notification-close" onclick="this.parentElement.remove()">×</button>
    `;

    document.body.appendChild(notification);

    // Remover automaticamente após 5 segundos
    setTimeout(() => {
        notification.remove();
    }, 5000);
} 