START TRANSACTION;

-- 1) Apagar logs de notificação (têm FK para notifications)
DELETE FROM notificationlogs
WHERE log_id IN (1, 2, 3, 4);

-- 2) Apagar notificações de teste (têm FK para templates via type_id e parent)
DELETE FROM notifications
WHERE notification_id IN (1, 2, 3);

-- 3) Apagar templates de exemplo (têm FK para notificationtypes)
DELETE FROM templates
WHERE template_id IN (1, 2, 3, 4);

-- 4) (Opcional) Apagar tipos na tabela parent
DELETE FROM notificationtypes
WHERE type_id IN (1, 2, 3, 4);

COMMIT;

-- Verificar que não sobrou nada
SELECT 'Templates'     AS entidade, COUNT(*) FROM templates     WHERE template_id IN (1,2,3,4)
UNION ALL
SELECT 'Notificações', COUNT(*) FROM notifications  WHERE notification_id IN (1,2,3)
UNION ALL
SELECT 'Logs',         COUNT(*) FROM notificationlogs WHERE log_id IN (1,2,3,4)
UNION ALL
SELECT 'Tipos',        COUNT(*) FROM notificationtypes WHERE type_id IN (1,2,3,4);
