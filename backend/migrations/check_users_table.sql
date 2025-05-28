-- Verificar se a tabela users existe e criar se não existir
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE
);

-- Verificar se a coluna sender_id existe na tabela notifications
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS sender_id INT;

-- Adicionar a chave estrangeira se não existir
ALTER TABLE notifications 
DROP FOREIGN KEY IF EXISTS fk_notification_sender;

ALTER TABLE notifications 
ADD CONSTRAINT fk_notification_sender 
FOREIGN KEY (sender_id) REFERENCES users(id);

-- Inserir usuário padrão se não existir
INSERT IGNORE INTO users (name, email, password)
VALUES ('Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy'); 