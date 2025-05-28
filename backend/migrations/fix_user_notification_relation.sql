-- Verificar a estrutura atual da tabela users
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'notisync' 
AND TABLE_NAME = 'users';

-- Verificar se a tabela users existe
SET @dbname = 'notisync';
SET @tablename = 'users';

SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
    ),
    'SELECT "Table users exists"',
    'CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        active BOOLEAN DEFAULT TRUE
    )'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar se a coluna sender_id existe na tabela notifications
SET @tablename = 'notifications';
SET @columnname = 'sender_id';

SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
        AND COLUMN_NAME = @columnname
    ),
    'SELECT "Column sender_id exists"',
    'ALTER TABLE notifications ADD COLUMN sender_id INT NOT NULL'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar e adicionar a chave estrangeira
SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
        AND COLUMN_NAME = @columnname
        AND REFERENCED_TABLE_NAME = 'users'
    ),
    'SELECT "Foreign key already exists"',
    'ALTER TABLE notifications ADD CONSTRAINT fk_notification_sender FOREIGN KEY (sender_id) REFERENCES users(id)'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Inserir usuário padrão se não existir
INSERT IGNORE INTO users (name, email, password)
VALUES ('Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy'); 