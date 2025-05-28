-- 1) Inserir (ou garantir) os tipos na tabela parent
INSERT INTO notificationtypes (type_id, name, description) VALUES
  (1, 'Sistema',           'Tipos de alerta do sistema'),
  (2, 'Geral',             'Tipos de aviso geral'),
  (3, 'Segurança',         'Tipos de alerta de segurança'),
  (4, 'Manutenção',        'Tipos de aviso de manutenção')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description);

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


SELECT 'Notificações',  COUNT(*) FROM notifications
UNION ALL
SELECT 'Logs',          COUNT(*) FROM notificationlogs;
