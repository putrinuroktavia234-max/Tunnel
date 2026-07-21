<?php
// ============================================================
// OrderVPN — Main Config
// ============================================================

require_once __DIR__ . '/functions.php';

// Load .env
loadEnv();

// Default timezone
date_default_timezone_set('Asia/Jakarta');

// Session security
if (session_status() === PHP_SESSION_NONE) {
    session_start([
        'cookie_httponly' => true,
        'cookie_secure' => isset($_SERVER['HTTPS']),
        'cookie_samesite' => 'Strict',
    ]);
}
