-- Primeiro, vamos ver a estrutura atual
SHOW CREATE TABLE notifications;

-- Tentar remover a chave estrangeira específica que vimos no phpMyAdmin
ALTER TABLE notifications DROP FOREIGN KEY IF EXISTS notifications_ibfk_3;

-- Tentar remover outras chaves estrangeiras comuns para garantir
ALTER TABLE notifications DROP FOREIGN KEY IF EXISTS notifications_ibfk_1;
ALTER TABLE notifications DROP FOREIGN KEY IF EXISTS notifications_ibfk_2;
ALTER TABLE notifications DROP FOREIGN KEY IF EXISTS fk_notification_sender;
ALTER TABLE notifications DROP FOREIGN KEY IF EXISTS fk_sender;

-- Remover a coluna sender_id
ALTER TABLE notifications DROP COLUMN IF EXISTS sender_id;

-- Adicionar a coluna novamente
ALTER TABLE notifications ADD COLUMN sender_id INT NULL;

-- Garantir que o usuário admin existe
INSERT IGNORE INTO users (name, email, password)
VALUES ('Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy');

-- Atualizar sender_id para o ID do admin
UPDATE notifications n
SET n.sender_id = (SELECT id FROM users WHERE email = 'admin@notisync.com' LIMIT 1)
WHERE n.sender_id IS NULL;

-- Tornar a coluna NOT NULL
ALTER TABLE notifications MODIFY COLUMN sender_id INT NOT NULL;

-- Adicionar a nova chave estrangeira referenciando users(id)
ALTER TABLE notifications 
ADD CONSTRAINT fk_notification_sender 
FOREIGN KEY (sender_id) REFERENCES users(id); 