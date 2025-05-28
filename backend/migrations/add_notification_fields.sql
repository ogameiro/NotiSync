-- Verificar e adicionar colunas à tabela notifications
SET @dbname = 'notisync';
SET @tablename = 'notifications';
SET @columnname = 'template_id';
SET @columnname2 = 'priority';
SET @columnname3 = 'updated_at';

SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
        AND COLUMN_NAME = @columnname
    ),
    'SELECT "Column template_id already exists"',
    'ALTER TABLE notifications ADD COLUMN template_id INT NULL, ADD FOREIGN KEY (template_id) REFERENCES templates(template_id)'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
        AND COLUMN_NAME = @columnname2
    ),
    'SELECT "Column priority already exists"',
    'ALTER TABLE notifications ADD COLUMN priority VARCHAR(20) DEFAULT "Normal"'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
        AND COLUMN_NAME = @columnname3
    ),
    'SELECT "Column updated_at already exists"',
    'ALTER TABLE notifications ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Atualizar created_at para ter valor padrão se ainda não tiver
SET @query = IF(
    EXISTS(
        SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @dbname
        AND TABLE_NAME = @tablename
        AND COLUMN_NAME = 'created_at'
        AND COLUMN_DEFAULT IS NULL
    ),
    'ALTER TABLE notifications MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP',
    'SELECT "Column created_at already has default value"'
);
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt; 