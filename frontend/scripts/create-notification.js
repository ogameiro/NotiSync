// Função para validar o tamanho da mensagem
function validateMessageLength() {
    const smsCheckbox = document.querySelector('input[name="channels"][value="sms"]');
    const contentTextarea = document.getElementById('content');
    const contentError = document.getElementById('content-error') || (() => {
        const error = document.createElement('div');
        error.id = 'content-error';
        error.className = 'error-message';
        error.style.display = 'none';
        error.style.color = '#dc2626';
        error.style.marginTop = '0.5rem';
        contentTextarea.parentNode.appendChild(error);
        return error;
    })();

    if (smsCheckbox.checked && contentTextarea.value.length > 120) {
        contentError.textContent = 'A mensagem não pode ter mais de 120 caracteres quando o canal SMS está selecionado';
        contentError.style.display = 'block';
        return false;
    }

    contentError.style.display = 'none';
    return true;
}

// Função para validar os canais selecionados
function validateChannels() {
    const emailCheckbox = document.querySelector('input[name="channels"][value="email"]');
    const smsCheckbox = document.querySelector('input[name="channels"][value="sms"]');
    const recipientsTextarea = document.getElementById('recipients');
    const recipientsError = document.getElementById('recipients-error');

    // Verifica se pelo menos um canal está selecionado
    if (!emailCheckbox.checked && !smsCheckbox.checked) {
        recipientsError.textContent = 'Selecione pelo menos um canal de envio (Email ou SMS)';
        recipientsError.style.display = 'block';
        return false;
    }

    // Se houver destinatários, valida-os
    if (recipientsTextarea.value.trim()) {
        if (!validateRecipients()) {
            return false;
        }
    }

    // Valida o tamanho da mensagem se SMS estiver selecionado
    if (smsCheckbox.checked) {
        if (!validateMessageLength()) {
            return false;
        }
    }

    recipientsError.style.display = 'none';
    return true;
}

// Função para validar os destinatários
function validateRecipients() {
    const emailCheckbox = document.querySelector('input[name="channels"][value="email"]');
    const smsCheckbox = document.querySelector('input[name="channels"][value="sms"]');
    const recipientsTextarea = document.getElementById('recipients');
    const recipientsError = document.getElementById('recipients-error');

    const recipients = recipientsTextarea.value.split(',').map(r => r.trim()).filter(r => r);
    
    if (recipients.length === 0) {
        recipientsError.textContent = 'Digite pelo menos um destinatário';
        recipientsError.style.display = 'block';
        return false;
    }

    // Expressões regulares para validar email e telefone
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const phoneRegex = /^\+?[0-9\s-()]{10,}$/;

    const emails = recipients.filter(r => emailRegex.test(r));
    const phones = recipients.filter(r => phoneRegex.test(r));

    // Se ambos os canais estiverem selecionados
    if (emailCheckbox.checked && smsCheckbox.checked) {
        if (emails.length === 0) {
            recipientsError.textContent = 'É necessário incluir pelo menos um email quando o canal Email está selecionado';
            recipientsError.style.display = 'block';
            return false;
        }
        if (phones.length === 0) {
            recipientsError.textContent = 'É necessário incluir pelo menos um número de telefone quando o canal SMS está selecionado';
            recipientsError.style.display = 'block';
            return false;
        }
    }
    // Se apenas email estiver selecionado
    else if (emailCheckbox.checked) {
        if (emails.length === 0) {
            recipientsError.textContent = 'Digite pelo menos um email válido';
            recipientsError.style.display = 'block';
            return false;
        }
    }
    // Se apenas SMS estiver selecionado
    else if (smsCheckbox.checked) {
        if (phones.length === 0) {
            recipientsError.textContent = 'Digite pelo menos um número de telefone válido';
            recipientsError.style.display = 'block';
            return false;
        }
    }

    recipientsError.style.display = 'none';
    return true;
}

// Função para salvar a notificação
async function saveNotification() {
    if (!validateChannels() || !validateRecipients() || !validateMessageLength()) {
        return;
    }

    try {
        const form = document.getElementById('notification-form');
        const formData = new FormData(form);

        // Coleta os canais selecionados
        const channels = Array.from(document.querySelectorAll('input[name="channels"]:checked'))
            .map(checkbox => checkbox.value);

        // Coleta os destinatários
        const recipients = formData.get('recipients')
            .split(',')
            .map(r => r.trim())
            .filter(r => r);

        // Prepara os dados para envio no formato esperado pelo backend
        const notificationData = {
            tipo_id: parseInt(formData.get('type')), // Converte para número
            conteudo: formData.get('content'),
            canais: channels,
            destinatarios: recipients,
            prioridade: formData.get('priority') || 'Normal'
        };

        console.log('Dados da notificação:', notificationData);

        // Envia para a API usando a função fetchAPI
        const response = await fetchAPI('/notifications/', {
            method: 'POST',
            body: JSON.stringify(notificationData)
        });

        console.log('Notificação criada com sucesso:', response);
        showNotification('Notificação criada com sucesso!', 'success');
        setTimeout(() => {
            window.location.href = '/NotiSync/frontend/pages/notifications.html';
        }, 1000);

    } catch (error) {
        console.error('Erro ao criar notificação:', error);
        showNotification(error.message || 'Erro ao criar notificação', 'error');
    }
}

// Carregar tipos de notificação
async function carregarTiposNotificacao() {
    try {
        const response = await fetch('http://localhost:5050/dashboard/notificationtypes/', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'include'  // Importante para enviar os cookies
        });

        if (!response.ok) {
            if (response.status === 401) {
                // Token expirado ou inválido
                window.location.href = '/NotiSync/frontend/index.html';
                return;
            }
            throw new Error(`Erro ao carregar tipos de notificação: ${response.status}`);
        }

        const tipos = await response.json();
        const select = document.getElementById('type');
        if (!select) {
            console.error('Elemento select não encontrado');
            return;
        }

        select.innerHTML = '<option value="">Selecione um tipo</option>';
        
        tipos.forEach(tipo => {
            const option = document.createElement('option');
            option.value = tipo.type_id;
            option.textContent = tipo.name;
            select.appendChild(option);
        });
    } catch (error) {
        console.error('Erro:', error);
        alert('Erro ao carregar tipos de notificação. Por favor, tente novamente.');
    }
}

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
        
        // Carregar dados iniciais
        await Promise.all([
            carregarTiposNotificacao(),
        ]);
    } catch (error) {
        console.error('Erro ao verificar autenticação:', error);
        window.location.href = '/NotiSync/frontend/index.html';
    }
}); 