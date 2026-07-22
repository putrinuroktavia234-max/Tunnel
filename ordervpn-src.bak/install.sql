-- OrderVPN Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS `ordervpn_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ordervpn_db`;

-- Settings
CREATE TABLE IF NOT EXISTS `settings` (
  `key` VARCHAR(100) NOT NULL PRIMARY KEY,
  `value` TEXT DEFAULT NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Users
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('user','admin') DEFAULT 'user',
  `saldo` BIGINT DEFAULT 0,
  `is_verified` TINYINT(1) DEFAULT 0,
  `otp_code` VARCHAR(20) DEFAULT NULL,
  `otp_expires` DATETIME DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Servers
CREATE TABLE IF NOT EXISTS `servers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `host` VARCHAR(255) DEFAULT NULL,
  `monthly_price` INT DEFAULT 10000,
  `status` ENUM('ready','maintenance','offline') DEFAULT 'ready',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- VPN Accounts
CREATE TABLE IF NOT EXISTS `vpn_accounts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `server_id` INT NOT NULL,
  `username` VARCHAR(100) NOT NULL,
  `password` VARCHAR(255) DEFAULT NULL,
  `protocol` VARCHAR(20) DEFAULT 'ssh',
  `ip_limit` INT DEFAULT 2,
  `expiry_date` DATETIME DEFAULT NULL,
  `status` ENUM('active','expired','suspended') DEFAULT 'active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`server_id`) REFERENCES `servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Transactions
CREATE TABLE IF NOT EXISTS `transactions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `server_id` INT DEFAULT NULL,
  `account_id` INT DEFAULT NULL,
  `type` VARCHAR(50) DEFAULT NULL,
  `amount` INT DEFAULT 0,
  `status` ENUM('pending','success','failed','cancelled') DEFAULT 'pending',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Topup Requests
CREATE TABLE IF NOT EXISTS `topup_requests` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `amount` INT NOT NULL,
  `method` VARCHAR(50) DEFAULT NULL,
  `proof_image` VARCHAR(255) DEFAULT NULL,
  `status` ENUM('pending','approved','rejected') DEFAULT 'pending',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Promo Codes
CREATE TABLE IF NOT EXISTS `promo_codes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `discount_type` ENUM('percent','nominal') NOT NULL DEFAULT 'percent',
  `discount_value` DECIMAL(10,0) NOT NULL DEFAULT 0,
  `max_uses` INT NOT NULL DEFAULT 0,
  `used_count` INT NOT NULL DEFAULT 0,
  `min_price` DECIMAL(10,0) NOT NULL DEFAULT 0,
  `expires_at` DATE DEFAULT NULL,
  `status` ENUM('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default settings
INSERT INTO `settings` (`key`, `value`) VALUES
('app_name', 'OrderVPN'),
('contact_tg', '@ordervpn_admin'),
('contact_wa', '081234567890')
ON DUPLICATE KEY UPDATE `value`=`value`;

-- Insert default servers
INSERT INTO `servers` (`name`, `host`, `monthly_price`, `status`) VALUES
('Singapore Premium', 'sg.example.com', 10000, 'ready'),
('Indonesia Local', 'id.example.com', 12500, 'ready'),
('Global Multi', 'global.example.com', 15000, 'ready')
ON DUPLICATE KEY UPDATE `name`=`name`;
