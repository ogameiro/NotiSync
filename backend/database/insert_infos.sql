-- 1) Inserir (ou garantir) os tipos na tabela parent
INSERT INTO notificationtypes (type_id, name, description) VALUES
  (1, 'Sistema',           'Tipos de alerta do sistema'),
  (2, 'Geral',             'Tipos de aviso geral'),
  (3, 'Segurança',         'Tipos de alerta de segurança'),
  (4, 'Manutenção',        'Tipos de aviso de manutenção')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description);

-- 2) Agora insira seus templates
INSERT INTO templates (
  template_id, name, description,
  type_id, category, content,
  is_active, created_at, updated_at,
  created_by, usage_count
) VALUES
  (1, 'Alerta de Sistema',     'Template para alertas do sistema',  1, 'Sistema',     'ALERTA: {{mensagem}}',             TRUE, NOW(), NOW(), 1, 0),
  (2, 'Aviso Geral',           'Template para avisos gerais',       2, 'Geral',       'AVISO: {{mensagem}}',              TRUE, NOW(), NOW(), 1, 0),
  (3, 'Alerta de Segurança',   'Template para alertas de segurança',3, 'Segurança',   'ALERTA DE SEGURANÇA: {{mensagem}}',TRUE, NOW(), NOW(), 1, 0),
  (4, 'Manutenção',            'Template para avisos de manutenção',4, 'Manutenção',  'MANUTENÇÃO: {{mensagem}}',         TRUE, NOW(), NOW(), 1, 0);

-- 3) (Opcional) Inserir notificações de teste
INSERT INTO notifications (
  notification_id, type_id, sender_id,
  content_override, created_at
) VALUES
  (1, 1, 1, 'Teste de integração do sistema', NOW()),
  (2, 2, 1, 'Aviso de teste para verificação', NOW()),
  (3, 3, 1, 'Alerta de segurança de teste',    NOW());

-- 4) (Opcional) Inserir logs de notificação
INSERT INTO notificationlogs (
  log_id, status_id, channel_id,
  notification_id, recipient_id,
  error_message, attempted_at
) VALUES
  (1, 2, 1, 1, 1, NULL,    NOW()),
  (2, 2, 2, 1, 1, NULL,    NOW()),
  (3, 3, 1, 2, 1, 'Erro de teste', NOW()),
  (4, 1, 2, 3, 1, NULL,    NOW());

-- 5) Verificar contagens
SELECT 'Templates'      AS entidade, COUNT(*) FROM templates
UNION ALL
SELECT 'Notificações',  COUNT(*) FROM notifications
UNION ALL
SELECT 'Logs',          COUNT(*) FROM notificationlogs;
