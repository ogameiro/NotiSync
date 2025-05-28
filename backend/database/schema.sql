-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 28-Maio-2025 às 15:09
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
-- Estrutura da tabela `channelconfigs`
--

CREATE TABLE `channelconfigs` (
  `config_id` int(11) NOT NULL,
  `channel_id` int(11) NOT NULL,
  `key` varchar(255) NOT NULL,
  `value` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

--
-- Extraindo dados da tabela `notificationlogs`
--

INSERT INTO `notificationlogs` (`log_id`, `notification_id`, `channel_id`, `recipient_id`, `status_id`, `error_message`, `attempted_at`, `attempts`, `last_attempt`) VALUES
(5, 4, 1, 0, 2, NULL, '2025-05-27 23:54:02', 0, NULL),
(6, 5, 1, 0, 2, NULL, '2025-05-28 08:00:06', 0, NULL),
(9, 6, 1, 0, 2, NULL, '2025-05-28 08:00:09', 0, NULL),
(10, 7, 1, 0, 2, NULL, '2025-05-28 09:16:02', 0, NULL);

-- --------------------------------------------------------

--
-- Estrutura da tabela `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `type_id` int(11) NOT NULL,
  `template_id` int(11) DEFAULT NULL,
  `content_override` text DEFAULT NULL,
  `priority` enum('baixa','normal','alta') NOT NULL DEFAULT 'normal',
  `category` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sender_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Extraindo dados da tabela `notifications`
--

INSERT INTO `notifications` (`notification_id`, `type_id`, `template_id`, `content_override`, `priority`, `category`, `created_at`, `updated_at`, `sender_id`) VALUES
(4, 2, NULL, 'lknsknskn', '', NULL, '2025-05-27 23:54:01', '2025-05-28 00:54:01', 1),
(5, 3, NULL, 'Esta notificação é para informar que o sistema tá top!', '', NULL, '2025-05-28 08:00:05', '2025-05-28 09:00:05', 1),
(6, 3, NULL, 'Esta notificação é para informar que o sistema tá top!', '', NULL, '2025-05-28 08:00:08', '2025-05-28 09:00:08', 1),
(7, 1, NULL, 'sdsadadasd', '', NULL, '2025-05-28 09:16:01', '2025-05-28 10:16:01', 1);

-- --------------------------------------------------------

--
-- Estrutura da tabela `notificationschedules`
--

CREATE TABLE `notificationschedules` (
  `schedule_id` int(11) NOT NULL,
  `notification_id` int(11) NOT NULL,
  `send_at` datetime NOT NULL,
  `recurrence_rule` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
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

--
-- Extraindo dados da tabela `refreshtokens`
--

INSERT INTO `refreshtokens` (`token_id`, `user_id`, `jwt`, `issued_at`, `expires_at`, `revoked`) VALUES
(7, 1, '37813151ae9591241a85aa1d1f73a700ebe3c03eafe5a3701e4d03abea3242ce', '2025-05-27 15:16:25', '2025-06-03 15:16:25', 0),
(8, 1, '29cc4baba8a199d9736c8eafa46b8d46588ce8fbe6951f58b2a7e07c4bd01dbe', '2025-05-27 20:29:46', '2025-06-03 20:29:46', 0),
(9, 1, '0666339ebc6a91ce007031ba3b9bd25a046e264fb7ee0c51d2b83f3f9fec46eb', '2025-05-27 20:34:01', '2025-06-03 20:34:01', 0),
(10, 1, '52c9d2d0ea643f33de93c79020ec693c96d32efb3a0ac53a90ac1ae6016e0454', '2025-05-27 20:36:33', '2025-06-03 20:36:33', 0),
(11, 1, '2de3d53cdcda493476efe460c78ac1ff359f03ade0d75cfd049890b36ad47c00', '2025-05-27 20:39:43', '2025-06-03 20:39:43', 0),
(12, 1, 'd2a523645922a22b1965921b5992ac0dea1b9a0b83c833e69883a08dd9577fe4', '2025-05-28 01:07:15', '2025-06-04 01:07:15', 0),
(13, 1, '8ec2a666bd07713c8af10838a7a9e3fb3f6873386555129fdc44c7cd2fcf1420', '2025-05-28 01:10:31', '2025-06-04 01:10:31', 0),
(14, 1, '057213d022797dcfc9f4d6d6997b7b899feea6e325da90b5ce71b319f7a01d5b', '2025-05-28 01:14:59', '2025-06-04 01:14:59', 0),
(15, 1, '7f4944aa25114310a8f7df1ca5c1cdf9d161fd26cfed0641db8e5fe7f930efa5', '2025-05-28 01:18:10', '2025-06-04 01:18:10', 0),
(16, 1, '212a5c475d48c06213df60bc4e2ce8439e756774fdee30402c98887868efb4da', '2025-05-28 01:21:54', '2025-06-04 01:21:54', 0),
(17, 1, '8e43604a68897653653339f939c3e643906619f5d7dd6759f13b33def63a7ecc', '2025-05-28 01:25:00', '2025-06-04 01:25:00', 0),
(18, 1, 'e1dfdcc22af036fcfe402e2dfcc064bb17ba19a7819e49f0ca281d929566b6ad', '2025-05-28 01:45:46', '2025-06-04 01:45:46', 0),
(19, 1, '46cf904ceedb3d16f716fc46b1e4de79f4f666f1b04098f6b29aa6ef0791fa0e', '2025-05-28 01:47:40', '2025-06-04 01:47:40', 0),
(20, 1, '32192e049885100924fc1042ac8892e5672ad09698f52b2c161c719115de4fdd', '2025-05-28 01:51:29', '2025-06-04 01:51:29', 0),
(21, 1, 'ed5963dbf6ac8dd991bc5f16e8fdb944372f0f1da1b8bb52f1704c93c3b512e1', '2025-05-28 01:51:59', '2025-06-04 01:51:59', 0),
(22, 1, 'c0c9ed1d53ec9b080c9bb967cad1cc086f65b7c3f2dd302f08f2d00a7e6e206c', '2025-05-28 01:53:05', '2025-06-04 01:53:05', 0),
(23, 1, 'ae251823c986400ac6c87bd7674522d63ee7e1435b48c06afd3046f24337ff72', '2025-05-28 09:59:05', '2025-06-04 09:59:05', 0),
(24, 1, 'ad2be2288e4d2b5fa22ed6cef26b986c65e0d9fc0f8d027d8d7d40ae96ae9d37', '2025-05-28 11:06:47', '2025-06-04 11:06:47', 0),
(25, 1, '3e6941ff177029d5084af9d6c3d0a43c6bd32d766b03da060d529e2ede355f75', '2025-05-28 13:59:44', '2025-06-04 13:59:44', 0);

-- --------------------------------------------------------

--
-- Estrutura da tabela `templates`
--

CREATE TABLE `templates` (
  `template_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `type_id` int(11) NOT NULL,
  `category` varchar(50) DEFAULT NULL,
  `content` text NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `usage_count` int(11) NOT NULL DEFAULT 0
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
-- Extraindo dados da tabela `users`
--

INSERT INTO `users` (`user_id`, `name`, `email`, `password`, `created_at`, `updated_at`) VALUES
(1, 'Admin NotiSync', 'admin@notisync.pt', '$2y$10$C8kkd0trs.RHlHf6OiUQeuXD3IGSQSLTIqgAARM4k02CBNxhalDWW', '2025-05-10 14:54:00', '2025-05-27 14:12:44'),
(3, 'Administrador', 'admin@notisync.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBAQNQxwQZqKHy', '2025-05-28 00:39:55', '2025-05-28 00:39:55');

--
-- Índices para tabelas despejadas
--

--
-- Índices para tabela `channelconfigs`
--
ALTER TABLE `channelconfigs`
  ADD PRIMARY KEY (`config_id`),
  ADD KEY `channel_id` (`channel_id`);

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
  ADD KEY `recipient_id` (`recipient_id`),
  ADD KEY `status_id` (`status_id`);

--
-- Índices para tabela `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `type_id` (`type_id`),
  ADD KEY `template_id` (`template_id`);

--
-- Índices para tabela `notificationschedules`
--
ALTER TABLE `notificationschedules`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `notification_id` (`notification_id`);

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
-- Índices para tabela `templates`
--
ALTER TABLE `templates`
  ADD PRIMARY KEY (`template_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `type_id` (`type_id`);

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
-- AUTO_INCREMENT de tabela `channelconfigs`
--
ALTER TABLE `channelconfigs`
  MODIFY `config_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de tabela `channels`
--
ALTER TABLE `channels`
  MODIFY `channel_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de tabela `notificationlogs`
--
ALTER TABLE `notificationlogs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de tabela `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de tabela `notificationschedules`
--
ALTER TABLE `notificationschedules`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT;

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
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de tabela `templates`
--
ALTER TABLE `templates`
  MODIFY `template_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Restrições para despejos de tabelas
--

--
-- Limitadores para a tabela `channelconfigs`
--
ALTER TABLE `channelconfigs`
  ADD CONSTRAINT `channelconfigs_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channels` (`channel_id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `notificationlogs`
--
ALTER TABLE `notificationlogs`
  ADD CONSTRAINT `notificationlogs_ibfk_1` FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`notification_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notificationlogs_ibfk_2` FOREIGN KEY (`channel_id`) REFERENCES `channels` (`channel_id`),
  ADD CONSTRAINT `notificationlogs_ibfk_4` FOREIGN KEY (`status_id`) REFERENCES `notificationstatus` (`status_id`);

--
-- Limitadores para a tabela `notificationschedules`
--
ALTER TABLE `notificationschedules`
  ADD CONSTRAINT `notificationschedules_ibfk_1` FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`notification_id`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `templates`
--
ALTER TABLE `templates`
  ADD CONSTRAINT `templates_ibfk_2` FOREIGN KEY (`type_id`) REFERENCES `notificationtypes` (`type_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
