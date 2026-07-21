-- OrderVPN Database Schema v2.0
-- by The Professor

CREATE DATABASE IF NOT EXISTS ordervpn_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ordervpn_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    saldo DECIMAL(15,2) DEFAULT 0.00,
    role ENUM('user','admin') DEFAULT 'user',
    is_verified TINYINT(1) DEFAULT 0,
    otp_code VARCHAR(10) DEFAULT NULL,
    otp_expires DATETIME DEFAULT NULL,
    ip_address VARCHAR(45),
    whatsapp VARCHAR(20) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_server VARCHAR(100) NOT NULL,
    code_server VARCHAR(20) UNIQUE NOT NULL,
    lokasi VARCHAR(100) NOT NULL,
    flag VARCHAR(10) DEFAULT '🇮🇩',
    harga_hari DECIMAL(10,2) NOT NULL,
    harga_bulan DECIMAL(10,2) NOT NULL,
    ip_limit INT DEFAULT 2,
    quota_limit INT DEFAULT 9999,
    status ENUM('ready','maintenance','offline') DEFAULT 'ready',
    host VARCHAR(255) NOT NULL,
    port INT DEFAULT 22,
    ssh_user VARCHAR(50) DEFAULT 'root',
    ssh_password VARCHAR(255) DEFAULT NULL,
    ssh_key VARCHAR(255) DEFAULT NULL,
    domain VARCHAR(255) DEFAULT NULL,
    xray_config_path VARCHAR(255) DEFAULT '/usr/local/etc/xray/config.json',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vpn_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    server_id INT NOT NULL,
    tipe ENUM('vmess','vless','trojan','ssh','trial') NOT NULL,
    username VARCHAR(100) NOT NULL,
    remarks VARCHAR(100),
    uuid VARCHAR(36),
    password_vpn VARCHAR(255),
    link_config TEXT,
    link_tls TEXT,
    link_nontls TEXT,
    link_grpc TEXT,
    masa_aktif DATETIME NOT NULL,
    days_ordered INT NOT NULL,
    is_trial TINYINT(1) DEFAULT 0,
    harga_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('active','expired','suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('topup','order','refund','trial') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    keterangan VARCHAR(255),
    status ENUM('pending','success','failed') DEFAULT 'success',
    ref_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS topup_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'manual',
    bukti_transfer VARCHAR(255),
    tripay_ref VARCHAR(100) DEFAULT NULL,
    tripay_channel VARCHAR(50) DEFAULT NULL,
    tripay_qr TEXT DEFAULT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_note VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS app_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS login_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    username VARCHAR(100) DEFAULT NULL,
    action VARCHAR(50) DEFAULT 'login',
    success TINYINT(1) DEFAULT 0,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ip_action (ip_address, action),
    INDEX idx_attempted_at (attempted_at)
) ENGINE=InnoDB;

-- Default settings
INSERT IGNORE INTO app_settings (setting_key, setting_value) VALUES
('app_name', 'OrderVPN'),
('app_logo', '[SIG]'),
('contact_wa', ''),
('contact_tg', ''),
('contact_ig', ''),
('bank_name', 'BCA'),
('bank_account', '1234567890'),
('bank_holder', 'Admin OrderVPN'),
('dana_number', ''),
('gopay_number', ''),
('shopee_number', ''),
('qris_image', ''),
('trial_duration_hours', '1'),
('trial_quota_gb', '1'),
('smtp_host', 'smtp.gmail.com'),
('smtp_port', '587'),
('smtp_user', ''),
('smtp_pass', ''),
('smtp_from', ''),
('tg_bot_token', ''),
('tg_chat_id', ''),
('tripay_api_key', ''),
('tripay_private_key', ''),
('tripay_merchant_code', ''),
('tripay_mode', 'sandbox');

INSERT IGNORE INTO users (username, email, password, saldo, role, is_verified) VALUES
('admin', 'admin@ordervpn.local', 'TO_BE_REPLACED_BY_INSTALL', 999999.00, 'admin', 1);
