<?php
if (session_status() === PHP_SESSION_NONE) session_start();

function getDB() {
    static $db = null;
    if ($db === null) {
        try {
            $host = getenv('DB_HOST') ?: 'localhost';
            $name = getenv('DB_NAME') ?: 'ordervpn_db';
            $user = getenv('DB_USER') ?: 'root';
            $pass = getenv('DB_PASS') ?: '';
            $db = new PDO("mysql:host=$host;dbname=$name;charset=utf8mb4", $user, $pass);
            $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (Exception $e) {
            return null;
        }
    }
    return $db;
}

function getSetting($key, $default = '') {
    $db = getDB();
    if (!$db) return $default;
    try {
        $st = $db->prepare("SELECT value FROM settings WHERE `key` = ?");
        $st->execute([$key]);
        $row = $st->fetch();
        return $row ? $row['value'] : $default;
    } catch (Exception $e) {
        return $default;
    }
}

function sanitize($input) {
    return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
}

function requireLogin() {
    if (!isset($_SESSION['user_id'])) {
        header('Location: index.php');
        exit;
    }
    return $_SESSION;
}

function requireAdmin() {
    if (!isset($_SESSION['user_id']) || ($_SESSION['role'] ?? '') !== 'admin') {
        header('Location: index.php');
        exit;
    }
    return $_SESSION;
}

function csrfToken() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrfField() {
    return '<input type="hidden" name="csrf_token" value="'.csrfToken().'">';
}
