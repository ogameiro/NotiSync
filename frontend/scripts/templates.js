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
function showNewTemplateModal() {
    const modal = document.getElementById('template-modal');
    modal.classList.add('show');
    document.getElementById('template-form').reset();
    document.getElementById('template-form').dataset.mode = 'create';
    modal.querySelector('.modal-header h3').textContent = 'Novo Template';
}

function closeTemplateModal() {
    const modal = document.getElementById('template-modal');
    modal.classList.remove('show');
}

// Fechar modal ao clicar fora
document.addEventListener('click', function(event) {
    const modal = document.getElementById('template-modal');
    if (event.target === modal) {
        closeTemplateModal();
    }
});

// Gerenciamento de Templates
async function editTemplate(templateId) {
    try {
        const template = await fetchAPI(`/templates/${templateId}`);
        
        // Preencher o formulário com os dados
        document.getElementById('template-name').value = template.nome;
        document.getElementById('template-description').value = template.descricao;
        document.getElementById('template-type').value = template.tipo;
        document.getElementById('template-category').value = template.categoria;
        document.getElementById('template-content').value = template.conteudo;
        document.getElementById('template-active').checked = template.ativo;

        // Configurar o formulário para edição
        const form = document.getElementById('template-form');
        form.dataset.mode = 'edit';
        form.dataset.id = templateId;

        // Mostrar o modal
        const modal = document.getElementById('template-modal');
        modal.classList.add('show');
        modal.querySelector('.modal-header h3').textContent = 'Editar Template';
    } catch (error) {
        console.error('Erro ao carregar template:', error);
        showNotification('Erro ao carregar template', 'error');
    }
}

async function deleteTemplate(templateId) {
    if (!confirm('Tem certeza que deseja excluir este template?')) return;

    try {
        await fetchAPI(`/templates/${templateId}`, { method: 'DELETE' });
        showNotification('Template excluído com sucesso', 'success');
        carregarTemplates();
    } catch (error) {
        console.error('Erro ao excluir template:', error);
        showNotification('Erro ao excluir template', 'error');
    }
}

async function duplicateTemplate(templateId) {
    try {
        await fetchAPI(`/templates/${templateId}/duplicate`, { method: 'POST' });
        showNotification('Template duplicado com sucesso', 'success');
        carregarTemplates();
    } catch (error) {
        console.error('Erro ao duplicar template:', error);
        showNotification('Erro ao duplicar template', 'error');
    }
}

// Carregar templates
async function carregarTemplates(page = 1, filtros = {}) {
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

        // Carregar dados dos templates
        const data = await fetchAPI(`/templates/?${new URLSearchParams({
            page,
            per_page: 10,
            ...filtros
        })}`);
        const grid = document.querySelector('.templates-grid');
        if (!grid) return;

        grid.innerHTML = data.templates.map(template => `
            <div class="template-card">
                <div class="template-header">
                    <h3>${template.nome}</h3>
                    <div class="template-actions">
                        <button class="btn-action btn-edit" onclick="editTemplate(${template.id})" title="Editar">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-action btn-duplicar" onclick="duplicateTemplate(${template.id})" title="Duplicar">
                            <i class="fas fa-copy"></i>
                        </button>
                        <button class="btn-action btn-excluir" onclick="deleteTemplate(${template.id})" title="Excluir">
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
                        <i class="fas fa-chart-bar"></i> ${template.uso || 0} usos
                    </span>
                </div>
            </div>
        `).join('');

        // Atualizar paginação
        atualizarPaginacao(data.pagina, data.total_paginas);
    } catch (error) {
        console.error('Erro ao carregar templates:', error);
        showNotification('Erro ao carregar templates', 'error');
    }
}

// Inserção de Variáveis
function insertTemplateVariable(variable) {
    const contentTextarea = document.getElementById('template-content');
    const start = contentTextarea.selectionStart;
    const end = contentTextarea.selectionEnd;
    const text = contentTextarea.value;
    
    contentTextarea.value = text.substring(0, start) + variable + text.substring(end);
    contentTextarea.focus();
    contentTextarea.selectionStart = contentTextarea.selectionEnd = start + variable.length;
}

// Filtros
function applyFilters() {
    const filtros = {
        categoria: document.getElementById('category-filter').value,
        tipo: document.getElementById('type-filter').value,
        status: document.getElementById('status-filter').value,
        search: document.querySelector('.search-box input').value
    };

    carregarTemplates(1, filtros);
}

// Formulário de Template
document.getElementById('template-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    if (!validateTemplateForm()) return;

    const formData = new FormData(this);
    const dados = Object.fromEntries(formData.entries());
    dados.ativo = formData.get('ativo') === 'on';

    try {
        if (this.dataset.mode === 'edit') {
            await fetchAPI(`/templates/${this.dataset.id}`, {
                method: 'PUT',
                body: JSON.stringify(dados)
            });
            showNotification('Template atualizado com sucesso', 'success');
        } else {
            await fetchAPI('/templates/', {
                method: 'POST',
                body: JSON.stringify(dados)
            });
            showNotification('Template criado com sucesso', 'success');
        }
        
        closeTemplateModal();
        carregarTemplates();
    } catch (error) {
        console.error('Erro ao salvar template:', error);
        showNotification('Erro ao salvar template', 'error');
    }
});

// Validação do formulário
function validateTemplateForm() {
    const form = document.getElementById('template-form');
    const nome = form.querySelector('#template-name').value.trim();
    const tipo = form.querySelector('#template-type').value;
    const conteudo = form.querySelector('#template-content').value.trim();

    if (!nome) {
        showNotification('O nome do template é obrigatório', 'error');
        return false;
    }

    if (!tipo) {
        showNotification('O tipo do template é obrigatório', 'error');
        return false;
    }

    if (!conteudo) {
        showNotification('O conteúdo do template é obrigatório', 'error');
        return false;
    }

    return true;
}

// Sistema de Notificações
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <i class="fas ${getNotificationIcon(type)}"></i>
        <span>${message}</span>
    `;

    document.body.appendChild(notification);

    // Anima a entrada
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);

    // Remove após 3 segundos
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

function getNotificationIcon(type) {
    switch(type) {
        case 'success':
            return 'fa-check-circle';
        case 'error':
            return 'fa-exclamation-circle';
        case 'warning':
            return 'fa-exclamation-triangle';
        default:
            return 'fa-info-circle';
    }
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
            carregarTemplates();
        }
    }).catch(error => {
        console.error('Erro ao verificar autenticação:', error);
        window.location.href = '/NotiSync/frontend/index.html';
    });

    // Event listeners para filtros
    const filters = ['category-filter', 'type-filter', 'status-filter'];
    filters.forEach(filterId => {
        const filter = document.getElementById(filterId);
        if (filter) {
            filter.addEventListener('change', applyFilters);
        }
    });

    // Event listener para pesquisa
    const searchInput = document.querySelector('.search-box input');
    if (searchInput) {
        searchInput.addEventListener('input', applyFilters);
    }
}); 