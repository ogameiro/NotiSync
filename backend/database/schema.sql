-- 1. Criação da Base de Dados
CREATE DATABASE IF NOT EXISTS `notisync`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `notisync`;

-- 2. Tabelas Fundamentais

CREATE TABLE `users` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE `notificationtypes` (
  `type_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL
) ENGINE=InnoDB;

CREATE TABLE `channels` (
  `channel_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL
) ENGINE=InnoDB;

CREATE TABLE `notificationstatus` (
  `status_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 3. Tabelas Dependentes de Users

CREATE TABLE `templates` (
  `template_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `type_id` INT NOT NULL,
  `category` VARCHAR(50) NULL,
  `content` TEXT NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_by` INT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `usage_count` INT NOT NULL DEFAULT 0,
  FOREIGN KEY (`created_by`)
    REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT,
  FOREIGN KEY (`type_id`)
    REFERENCES `notificationtypes`(`type_id`)
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `refreshtokens` (
  `token_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `jwt` VARCHAR(512) NOT NULL,
  `issued_at` DATETIME NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `revoked` BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (`user_id`)
    REFERENCES `users`(`user_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Notificações e Agendamentos

CREATE TABLE `notifications` (
  `notification_id` INT AUTO_INCREMENT PRIMARY KEY,
  `type_id` INT NOT NULL,
  `template_id` INT NULL,
  `sender_id` INT NOT NULL,
  `content_override` TEXT NULL,
  `priority` ENUM('baixa', 'normal', 'alta') NOT NULL DEFAULT 'normal',
  `category` VARCHAR(50) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`type_id`)
    REFERENCES `notificationtypes`(`type_id`)
    ON DELETE RESTRICT,
  FOREIGN KEY (`template_id`)
    REFERENCES `templates`(`template_id`)
    ON DELETE SET NULL,
  FOREIGN KEY (`sender_id`)
    REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE `notificationschedules` (
  `schedule_id` INT AUTO_INCREMENT PRIMARY KEY,
  `notification_id` INT NOT NULL,
  `send_at` DATETIME NOT NULL,
  `recurrence_rule` VARCHAR(255) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`notification_id`)
    REFERENCES `notifications`(`notification_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Configurações de Canal

CREATE TABLE `channelconfigs` (
  `config_id` INT AUTO_INCREMENT PRIMARY KEY,
  `channel_id` INT NOT NULL,
  `key` VARCHAR(255) NOT NULL,
  `value` TEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`channel_id`)
    REFERENCES `channels`(`channel_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Registo de Envios

CREATE TABLE `notificationlogs` (
  `log_id` INT AUTO_INCREMENT PRIMARY KEY,
  `notification_id` INT NOT NULL,
  `channel_id` INT NOT NULL,
  `recipient_id` INT NOT NULL,
  `status_id` INT NOT NULL,
  `error_message` TEXT NULL,
  `attempted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `attempts` INT NOT NULL DEFAULT 0,
  `last_attempt` TIMESTAMP NULL,
  FOREIGN KEY (`notification_id`)
    REFERENCES `notifications`(`notification_id`)
    ON DELETE CASCADE,
  FOREIGN KEY (`channel_id`)
    REFERENCES `channels`(`channel_id`)
    ON DELETE RESTRICT,
  FOREIGN KEY (`recipient_id`)
    REFERENCES `users`(`user_id`)
    ON DELETE RESTRICT,
  FOREIGN KEY (`status_id`)
    REFERENCES `notificationstatus`(`status_id`)
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 7. Dados Iniciais

INSERT INTO `notificationtypes` (`name`, `description`) VALUES
('Email', 'Notificações enviadas por email'),
('SMS', 'Notificações enviadas por SMS'),
('Push', 'Notificações push para aplicações móveis');

INSERT INTO `channels` (`name`, `description`) VALUES
('Email SMTP', 'Canal de email via SMTP'),
('SMS Gateway', 'Canal de SMS via gateway'),
('Firebase Cloud Messaging', 'Canal de push notifications via FCM');

INSERT INTO `notificationstatus` (`name`) VALUES
('Pendente'),
('Enviado'),
('Erro'),
('Cancelado');
