-- Primeiro, vamos ver todas as chaves estrangeiras da tabela
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME, 
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    REFERENCED_TABLE_SCHEMA = 'notisync'
    AND TABLE_NAME = 'notifications'
    AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Tentar remover a chave estrangeira usando o nome que aparece no resultado acima
-- (Substitua 'nome_da_constraint' pelo nome real que apareceu no resultado)
ALTER TABLE notifications DROP FOREIGN KEY nome_da_constraint;

-- Se não funcionar, podemos tentar uma abordagem mais radical:
-- 1. Criar uma tabela temporária
CREATE TABLE notifications_temp LIKE notifications;

-- 2. Copiar os dados, exceto a coluna sender_id
INSERT INTO notifications_temp 
SELECT 
    notification_id,
    type_id,
    content_override,
    priority,
    created_at,
    updated_at
FROM notifications;

-- 3. Dropar a tabela original
DROP TABLE notifications;

-- 4. Renomear a tabela temporária
RENAME TABLE notifications_temp TO notifications;

-- 5. Adicionar a coluna sender_id novamente
ALTER TABLE notifications 
ADD COLUMN sender_id INT NULL;

-- 6. Garantir que o usuário admin existe
INSERT IGNORE INTO users (name, email, password)
VALUES ('Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy');

-- 7. Atualizar sender_id para o ID do admin
UPDATE notifications n
SET n.sender_id = (SELECT id FROM users WHERE email = 'admin@notisync.com' LIMIT 1)
WHERE n.sender_id IS NULL;

-- 8. Tornar a coluna NOT NULL
ALTER TABLE notifications 
MODIFY COLUMN sender_id INT NOT NULL;

-- 9. Adicionar a nova chave estrangeira
ALTER TABLE notifications 
ADD CONSTRAINT fk_notification_sender 
FOREIGN KEY (sender_id) REFERENCES users(id); 