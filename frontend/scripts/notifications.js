// Funções de utilidade
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

// Função de Logout Unificada
async function logout() {
    try {
        const response = await fetch('http://localhost:5050/auth/logout', {
            method: 'POST',
            credentials: 'include'
        });

        if (response.ok) {
            showNotification('Sessão encerrada com sucesso', 'success');
            setTimeout(() => {
                window.location.href = '/NotiSync/frontend/index.html';
            }, 1000);
        } else {
            throw new Error('Erro ao encerrar sessão');
        }
    } catch (error) {
        console.error('Erro ao fazer logout:', error);
        showNotification('Erro ao encerrar sessão', 'error');
    }
}

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

// Funções de Notificação
async function listarNotificacoes(page = 1, filtros = {}) {
    const params = new URLSearchParams({
        page,
        per_page: 10,
        ...filtros
    });
    return await fetchAPI(`/notifications/?${params}`);
}

async function obterNotificacao(id) {
    return await fetchAPI(`/notifications/${id}`);
}

async function criarNotificacao(dados) {
    return await fetchAPI('/notifications/', {
        method: 'POST',
        body: JSON.stringify(dados)
    });
}

async function reenviarNotificacao(id) {
    return await fetchAPI(`/notifications/${id}/reenviar`, {
        method: 'POST'
    });
}

async function excluirNotificacao(id) {
    return await fetchAPI(`/notifications/${id}`, {
        method: 'DELETE'
    });
}

async function exportarHistorico(formato = 'csv') {
    const response = await fetchAPI(`/notifications/exportar?formato=${formato}`);
    // TODO: Implementar download do arquivo
    return response;
}

// Funções de Template
async function listarTemplates(page = 1, filtros = {}) {
    const params = new URLSearchParams({
        page,
        per_page: 10,
        ...filtros
    });
    return await fetchAPI(`/templates/?${params}`);
}

async function obterTemplate(id) {
    return await fetchAPI(`/templates/${id}`);
}

async function criarTemplate(dados) {
    return await fetchAPI('/templates/', {
        method: 'POST',
        body: JSON.stringify(dados)
    });
}

async function atualizarTemplate(id, dados) {
    return await fetchAPI(`/templates/${id}`, {
        method: 'PUT',
        body: JSON.stringify(dados)
    });
}

async function excluirTemplate(id) {
    return await fetchAPI(`/templates/${id}`, {
        method: 'DELETE'
    });
}

async function duplicarTemplate(id) {
    return await fetchAPI(`/templates/${id}/duplicar`, {
        method: 'POST'
    });
}

// Funções de carregamento de dados
async function carregarNotificacoes(page = 1, filtros = {}) {
    try {
        const data = await listarNotificacoes(page, filtros);
        const tbody = document.querySelector('#tabelaNotificacoes tbody');
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
        console.error('Erro ao carregar notificações:', error);
        showNotification('Erro ao carregar notificações', 'error');
    }
}

async function carregarTemplates(page = 1, filtros = {}) {
    try {
        const data = await listarTemplates(page, filtros);
        const grid = document.querySelector('.templates-grid');
        if (!grid) return;

        grid.innerHTML = data.templates.map(template => `
            <div class="template-card">
                <div class="template-header">
                    <h3>${template.nome}</h3>
                    <div class="template-actions">
                        <button class="btn-action btn-edit" data-id="${template.id}" title="Editar">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-action btn-duplicar" data-id="${template.id}" title="Duplicar">
                            <i class="fas fa-copy"></i>
                        </button>
                        <button class="btn-action btn-excluir" data-id="${template.id}" title="Excluir">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="template-info">
                    <span class="template-type ${template.tipo.toLowerCase()}">${template.tipo}</span>
                    <span class="template-category ${template.categoria.toLowerCase()}">${template.categoria}</span>
                </div>
                <p class="template-description">${template.descricao || 'Sem descrição'}</p>
                <div class="template-footer">
                    <span class="template-status ${template.ativo ? 'ativo' : 'inativo'}">
                        ${template.ativo ? 'Ativo' : 'Inativo'}
                    </span>
                    <span class="template-usage">
                        <i class="fas fa-chart-bar"></i> ${template.uso} usos
                    </span>
                </div>
            </div>
        `).join('');

        // Atualizar paginação
        atualizarPaginacao(data.pagina, data.total_paginas);
    } catch (error) {
        console.error('Erro ao carregar templates:', error);
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

// Funções de modal
async function showNotificationDetails(id) {
    const modal = document.getElementById('notificationDetailsModal');
    if (!modal) return;

    try {
        const notif = await obterNotificacao(id);
        modal.querySelector('.modal-title').textContent = 'Detalhes da Notificação';
        modal.querySelector('.modal-body').innerHTML = `
            <div class="details-section">
                <h3>Informações Básicas</h3>
                <p><strong>Título:</strong> ${notif.mensagem}</p>
                <p><strong>Tipo:</strong> ${notif.tipo}</p>
                <p><strong>Categoria:</strong> ${notif.categoria}</p>
                <p><strong>Estado:</strong> ${notif.estado}</p>
                <p><strong>Data:</strong> ${notif.data}</p>
            </div>
            ${notif.erro ? `
                <div class="details-section">
                    <h3>Erro</h3>
                    <p class="error-message">${notif.erro}</p>
                </div>
            ` : ''}
            <div class="details-section">
                <h3>Informações Adicionais</h3>
                <p><strong>Prioridade:</strong> ${notif.prioridade}</p>
                <p><strong>Tentativas:</strong> ${notif.tentativas}</p>
                ${notif.template_id ? `<p><strong>Template:</strong> #${notif.template_id}</p>` : ''}
            </div>
        `;
        modal.classList.add('show');
    } catch (error) {
        console.error('Erro ao carregar detalhes:', error);
        showNotification('Erro ao carregar detalhes da notificação', 'error');
    }
}

function closeNotificationDetails() {
    const modal = document.getElementById('notificationDetailsModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// Funções de paginação
function atualizarPaginacao(paginaAtual, totalPaginas) {
    const paginacao = document.querySelector('.pagination');
    if (!paginacao) return;

    let html = '';
    
    // Botão anterior
    html += `
        <button class="btn-page" ${paginaAtual === 1 ? 'disabled' : ''} 
                onclick="carregarNotificacoes(${paginaAtual - 1})">
            <i class="fas fa-chevron-left"></i>
        </button>
    `;

    // Páginas
    for (let i = 1; i <= totalPaginas; i++) {
        if (i === 1 || i === totalPaginas || (i >= paginaAtual - 2 && i <= paginaAtual + 2)) {
            html += `
                <button class="btn-page ${i === paginaAtual ? 'active' : ''}"
                        onclick="carregarNotificacoes(${i})">
                    ${i}
                </button>
            `;
        } else if (i === paginaAtual - 3 || i === paginaAtual + 3) {
            html += '<span class="pagination-ellipsis">...</span>';
        }
    }

    // Botão próximo
    html += `
        <button class="btn-page" ${paginaAtual === totalPaginas ? 'disabled' : ''}
                onclick="carregarNotificacoes(${paginaAtual + 1})">
            <i class="fas fa-chevron-right"></i>
        </button>
    `;

    paginacao.innerHTML = html;
}

// Inicialização
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
            carregarNotificacoes();
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
            filter.addEventListener('change', () => carregarNotificacoes(1));
        }
    });

    // Event listener para pesquisa
    const searchInput = document.querySelector('.search-box input');
    if (searchInput) {
        searchInput.addEventListener('input', () => carregarNotificacoes(1));
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