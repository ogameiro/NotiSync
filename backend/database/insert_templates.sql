-- Script para inserir templates de exemplo na base de dados

USE notisync;

-- Inserir templates de exemplo (usando INSERT IGNORE para evitar duplicados)

INSERT IGNORE INTO `templates` (`template_id`, `name`, `description`, `type_id`, `category`, `content`, `is_active`, `created_by`, `created_at`, `updated_at`, `usage_count`) VALUES
(1, 'Email de Boas Vindas', 'Template de email para novos usuários', 2, 'Boas Vindas', '<p>Olá, {{nome_usuario}}!</p><p>Bem-vindo(a) ao nosso serviço. Estamos felizes em tê-lo(a) conosco.</p><p>Para começar, clique aqui: {{link_ativacao}}</p><p>Atenciosamente,<br>Equipe NotiSync</p>', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0),
(2, 'Alerta de Sistema - Erro Crítico', 'Template para alertar sobre erros críticos no sistema', 1, 'Sistema', 'Alerta Crítico: Foi detectado um erro no sistema {{nome_sistema}}. Código do erro: {{codigo_erro}}. Consulte os logs para mais detalhes.', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0),
(3, 'SMS de Promoção', 'Template de SMS para promoções de marketing', 2, 'Marketing', 'Nova promoção para você! Use o código {{codigo_promocao}} para {{desconto}} no site.', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0),
(4, 'Notificação de Segurança - Login Suspeito', 'Template de email/push para login suspeito', 3, 'Segurança', '<p>Olá,</p><p>Detectamos um login suspeito na sua conta NotiSync a partir de um novo dispositivo/localização.</p><p>Data/Hora: {{data_hora}}<br>Dispositivo/Localização: {{dispositivo_localizacao}}</p><p>Se não foi você, altere sua senha imediatamente.</p><p>Se foi você, pode ignorar este aviso.</p><p>Atenciosamente,<br>Equipe de Segurança NotiSync</p>', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);

-- Nota: Os IDs dos tipos de notificação (type_id) e o created_by (user_id) devem existir na base de dados.
-- Assumimos que user_id = 1 existe para o usuário admin.
-- Assumimos que type_id 1 (Sistema) e 2 (Geral) existem.
-- Você pode ajustar os type_id e created_by conforme necessário na sua base de dados. 