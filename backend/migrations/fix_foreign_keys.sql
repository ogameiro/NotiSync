-- Primeiro, vamos verificar a estrutura atual das tabelas
SHOW CREATE TABLE users;
SHOW CREATE TABLE notifications;

-- Encontrar o nome da chave estrangeira existente
SELECT tc.CONSTRAINT_NAME
FROM information_schema.TABLE_CONSTRAINTS tc
JOIN information_schema.KEY_COLUMN_USAGE kcu 
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
WHERE tc.TABLE_SCHEMA = 'notisync'
AND tc.TABLE_NAME = 'notifications'
AND tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
AND kcu.COLUMN_NAME = 'sender_id';

-- Remover a chave estrangeira existente
ALTER TABLE notifications 
DROP FOREIGN KEY IF EXISTS fk_notification_sender;

-- Agora podemos remover a coluna
ALTER TABLE notifications 
DROP COLUMN IF EXISTS sender_id;

-- Adicionar a coluna sender_id novamente, mas permitindo NULL inicialmente
ALTER TABLE notifications 
ADD COLUMN sender_id INT NULL;

-- Atualizar sender_id para um valor válido (ID do usuário admin)
UPDATE notifications n
SET n.sender_id = (SELECT id FROM users WHERE email = 'admin@notisync.com' LIMIT 1)
WHERE n.sender_id IS NULL;

-- Agora que temos dados válidos, tornar a coluna NOT NULL
ALTER TABLE notifications 
MODIFY COLUMN sender_id INT NOT NULL;

-- Adicionar a nova chave estrangeira
ALTER TABLE notifications 
ADD CONSTRAINT fk_notification_sender 
FOREIGN KEY (sender_id) REFERENCES users(id);

-- Verificar se o usuário admin existe, se não, criar
INSERT IGNORE INTO users (name, email, password)
VALUES ('Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy'); 