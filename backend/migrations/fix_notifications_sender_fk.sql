-- Script para corrigir a coluna sender_id e chave estrangeira na tabela notifications

-- Mostrar a estrutura inicial das tabelas (opcional, para verificar)
-- SHOW CREATE TABLE users;
-- SHOW CREATE TABLE notifications;

USE notisync;

-- Encontrar e remover a chave estrangeira existente na coluna sender_id se ela existir
SELECT 
    CONSTRAINT_NAME
FROM
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
    TABLE_SCHEMA = 'notisync'
    AND TABLE_NAME = 'notifications'
    AND COLUMN_NAME = 'sender_id'
    AND REFERENCED_TABLE_NAME = 'users' INTO @constraint_name;

SET @drop_fk_sql = IF(
    @constraint_name IS NOT NULL,
    CONCAT('ALTER TABLE notifications DROP FOREIGN KEY ', @constraint_name),
    'SELECT \'No foreign key on sender_id found to drop.\''
);

PREPARE stmt FROM @drop_fk_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Tentar remover a coluna sender_id se ela existir
ALTER TABLE notifications DROP COLUMN IF EXISTS sender_id;

-- Adicionar a coluna sender_id como INT, permitindo NULL inicialmente
ALTER TABLE notifications ADD COLUMN sender_id INT NULL;

-- Garantir que o usuário admin existe (user_id como PK)
INSERT IGNORE INTO users (user_id, name, email, password)
VALUES (1, 'Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy');

-- Atualizar sender_id para o user_id do admin onde for NULL
UPDATE notifications n
SET n.sender_id = (SELECT user_id FROM users WHERE email = 'admin@notisync.com' LIMIT 1)
WHERE n.sender_id IS NULL;

-- Alterar a coluna sender_id para NOT NULL
ALTER TABLE notifications MODIFY COLUMN sender_id INT NOT NULL;

-- Adicionar a nova chave estrangeira referenciando users(user_id)
ALTER TABLE notifications 
ADD CONSTRAINT fk_notification_sender 
FOREIGN KEY (sender_id) REFERENCES users(user_id);

-- Mostrar a estrutura final (opcional, para verificar)
-- SHOW CREATE TABLE notifications; 