<?php
// ============================================================
// OrderVPN — Helper Functions
// ============================================================

function loadEnv(): void {
    $envFile = __DIR__ . '/../.env';
    if (!file_exists($envFile)) return;
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#') continue;
        if (strpos($line, '=') === false) continue;
        list($k, $v) = explode('=', $line, 2);
        $k = trim($k);
        $v = trim($v);
        if (!isset($_ENV[$k])) $_ENV[$k] = $v;
    }
}

function env(string $key, string $default = ''): string {
    return $_ENV[$key] ?? getenv($key) ?: $default;
}

function getDB(): PDO {
    static $db = null;
    if ($db !== null) return $db;

    loadEnv();
    $host = env('DB_HOST', 'localhost');
    $user = env('DB_USER', 'ordervpn');
    $pass = env('DB_PASS', '');
    $name = env('DB_NAME', 'ordervpn_db');

    try {
        $db = new PDO("mysql:host={$host};dbname={$name};charset=utf8mb4", $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    } catch (PDOException $e) {
        error_log('DB Connection failed: ' . $e->getMessage());
        throw new Exception('Database connection failed');
    }
    return $db;
}

function getSetting(string $key, string $default = ''): string {
    try {
        $db = getDB();
        $st = $db->prepare("SELECT value FROM settings WHERE `key`=?");
        $st->execute([$key]);
        $row = $st->fetch();
        return $row ? $row['value'] : $default;
    } catch (Exception $e) {
        return $default;
    }
}

function sanitize(string $str): string {
    return htmlspecialchars(trim($str), ENT_QUOTES, 'UTF-8');
}

function csrfField(): string {
    if (session_status() === PHP_SESSION_NONE) session_start();
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($_SESSION['csrf_token']) . '">';
}

function sendEmail(string $to, string $subject, string $body): bool {
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $from = env('SMTP_FROM', 'noreply@example.com');
    $headers .= "From: {$from}\r\n";
    return mail($to, $subject, $body, $headers);
}

function requireLogin(): array {
    if (session_status() === PHP_SESSION_NONE) session_start();
    if (empty($_SESSION['user_id'])) {
        header('Location: /ordervpn/index.php');
        exit;
    }
    return $_SESSION;
}
