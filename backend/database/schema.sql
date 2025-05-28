-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 28-Maio-2025 às 21:08
-- Versão do servidor: 10.4.32-MariaDB
-- versão do PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `notisync`
--

-- --------------------------------------------------------

--
-- Estrutura da tabela `channels`
--

CREATE TABLE `channels` (
  `channel_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Extraindo dados da tabela `channels`
--

INSERT INTO `channels` (`channel_id`, `name`, `description`) VALUES
(1, 'Email', 'Canal de envio por email'),
(2, 'SMS', 'Canal de envio por SMS');

-- --------------------------------------------------------

--
-- Estrutura da tabela `notificationlogs`
--

CREATE TABLE `notificationlogs` (
  `log_id` int(11) NOT NULL,
  `notification_id` int(11) NOT NULL,
  `channel_id` int(11) NOT NULL,
  `recipient_id` int(11) NOT NULL,
  `status_id` int(11) NOT NULL,
  `error_message` text DEFAULT NULL,
  `attempted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `attempts` int(11) NOT NULL DEFAULT 0,
  `last_attempt` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `type_id` int(11) NOT NULL,
  `content_override` text DEFAULT NULL,
  `priority` enum('baixa','normal','alta') NOT NULL DEFAULT 'normal',
  `category` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sender_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `notificationstatus`
--

CREATE TABLE `notificationstatus` (
  `status_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Extraindo dados da tabela `notificationstatus`
--

INSERT INTO `notificationstatus` (`status_id`, `name`) VALUES
(1, 'Pendente'),
(2, 'Enviado'),
(3, 'Erro'),
(4, 'Cancelado');

-- --------------------------------------------------------

--
-- Estrutura da tabela `notificationtypes`
--

CREATE TABLE `notificationtypes` (
  `type_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Extraindo dados da tabela `notificationtypes`
--

INSERT INTO `notificationtypes` (`type_id`, `name`, `description`) VALUES
(1, 'Sistema', 'Tipos de alerta do sistema'),
(2, 'Geral', 'Tipos de aviso geral'),
(3, 'Segurança', 'Tipos de alerta de segurança'),
(4, 'Manutenção', 'Tipos de aviso de manutenção');

-- --------------------------------------------------------

--
-- Estrutura da tabela `refreshtokens`
--

CREATE TABLE `refreshtokens` (
  `token_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `jwt` varchar(512) NOT NULL,
  `issued_at` datetime NOT NULL,
  `expires_at` datetime NOT NULL,
  `revoked` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estrutura da tabela `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Índices para tabelas despejadas
--

--
-- Índices para tabela `channels`
--
ALTER TABLE `channels`
  ADD PRIMARY KEY (`channel_id`);

--
-- Índices para tabela `notificationlogs`
--
ALTER TABLE `notificationlogs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `notification_id` (`notification_id`),
  ADD KEY `channel_id` (`channel_id`),
  ADD KEY `status_id` (`status_id`);

--
-- Índices para tabela `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `sender_id` (`sender_id`);

--
-- Índices para tabela `notificationstatus`
--
ALTER TABLE `notificationstatus`
  ADD PRIMARY KEY (`status_id`);

--
-- Índices para tabela `notificationtypes`
--
ALTER TABLE `notificationtypes`
  ADD PRIMARY KEY (`type_id`);

--
-- Índices para tabela `refreshtokens`
--
ALTER TABLE `refreshtokens`
  ADD PRIMARY KEY (`token_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Índices para tabela `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT de tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `channels`
--
ALTER TABLE `channels`
  MODIFY `channel_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `notificationlogs`
--
ALTER TABLE `notificationlogs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `notificationstatus`
--
ALTER TABLE `notificationstatus`
  MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `notificationtypes`
--
ALTER TABLE `notificationtypes`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `refreshtokens`
--
ALTER TABLE `refreshtokens`
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restrições para despejos de tabelas
--

--
-- Limitadores para a tabela `notificationlogs`
--
ALTER TABLE `notificationlogs`
  ADD CONSTRAINT `notificationlogs_ibfk_1` FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`notification_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notificationlogs_ibfk_2` FOREIGN KEY (`channel_id`) REFERENCES `channels` (`channel_id`),
  ADD CONSTRAINT `notificationlogs_ibfk_3` FOREIGN KEY (`status_id`) REFERENCES `notificationstatus` (`status_id`);

--
-- Limitadores para a tabela `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`type_id`) REFERENCES `notificationtypes` (`type_id`),
  ADD CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`);

--
-- Limitadores para a tabela `refreshtokens`
--
ALTER TABLE `refreshtokens`
  ADD CONSTRAINT `refreshtokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
