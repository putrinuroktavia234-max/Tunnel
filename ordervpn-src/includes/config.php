<?php
$envFile = __DIR__.'/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#') continue;
        $parts = explode('=', $line, 2);
        if (count($parts) === 2) {
            $_ENV[trim($parts[0])] = trim($parts[1]);
        }
    }
}

define('DB_HOST', $_ENV['DB_HOST'] ?? 'localhost');
define('DB_USER', $_ENV['DB_USER'] ?? 'ordervpn');
define('DB_PASS', $_ENV['DB_PASS'] ?? '');
define('DB_NAME', $_ENV['DB_NAME'] ?? 'ordervpn_db');
define('DB_PORT', (int)($_ENV['DB_PORT'] ?? 3306));

define('APP_VERSION', '2.0.0');
define('VPN_API_BRIDGE', '/usr/local/bin/vpn-api');
define('TUNNEL_SCRIPT', '/root/tunnel.sh');
define('SSH_KEY_PATH', '/root/.ssh/id_rsa');

session_start();

function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=".DB_HOST.";port=".DB_PORT.";dbname=".DB_NAME.";charset=utf8mb4";
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            die(json_encode(['success'=>false,'message'=>'DB error: '.$e->getMessage()]));
        }
    }
    return $pdo;
}

function getSetting($key, $default='') {
    static $cache = [];
    if (isset($cache[$key])) return $cache[$key];
    try {
        $db = getDB();
        $s = $db->prepare("SELECT setting_value FROM app_settings WHERE setting_key=?");
        $s->execute([$key]);
        $r = $s->fetchColumn();
        $cache[$key] = $r !== false ? $r : $default;
        return $cache[$key];
    } catch(Exception $e) { return $default; }
}

function sanitize($input) {
    if (is_array($input)) return array_map('sanitize', $input);
    return strip_tags(trim($input));
}

function esc($str) {
    return htmlspecialchars($str, ENT_QUOTES, 'UTF-8');
}

function formatRupiah($amount) {
    return 'Rp '.number_format((float)$amount, 0, ',', '.');
}

function generateUUID() {
    $data = random_bytes(16);
    $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

function sendTelegramNotif($message) {
    $token = getSetting('tg_bot_token');
    $chatId = getSetting('tg_chat_id');
    if (empty($token) || empty($chatId)) return;
    $url = "https://api.telegram.org/bot{$token}/sendMessage";
    $ch = curl_init();
    curl_setopt_array($ch,[CURLOPT_URL=>$url,CURLOPT_POST=>true,
        CURLOPT_POSTFIELDS=>http_build_query(['chat_id'=>$chatId,'text'=>$message,'parse_mode'=>'HTML']),
        CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>5]);
    curl_exec($ch); curl_close($ch);
}

function sendEmail($to, $subject, $htmlBody) {
    $smtpHost = $_ENV['SMTP_HOST'] ?? getSetting('smtp_host','smtp.gmail.com');
    $smtpPort = (int)($_ENV['SMTP_PORT'] ?? getSetting('smtp_port',587));
    $smtpUser = $_ENV['SMTP_USER'] ?: getSetting('smtp_user');
    $smtpPass = $_ENV['SMTP_PASS'] ?: getSetting('smtp_pass');
    $smtpFrom = $_ENV['SMTP_FROM'] ?: getSetting('smtp_from') ?: $smtpUser;
    $appName  = getSetting('app_name','OrderVPN');

    if (empty($smtpUser) || empty($smtpPass)) return false;

    $cmd = sprintf(
        'curl --url "smtp://%s:%d" --ssl-reqd --mail-from "%s" --mail-rcpt "%s" --user "%s:%s" -T - 2>/dev/null',
        escapeshellarg($smtpHost), $smtpPort,
        escapeshellarg($smtpFrom), escapeshellarg($to),
        escapeshellarg($smtpUser), escapeshellarg($smtpPass)
    );
    $msg  = "From: {$appName} <{$smtpFrom}>\r\n";
    $msg .= "To: {$to}\r\n";
    $msg .= "Subject: {$subject}\r\n";
    $msg .= "MIME-Version: 1.0\r\n";
    $msg .= "Content-Type: text/html; charset=UTF-8\r\n\r\n";
    $msg .= $htmlBody;

    $desc = [0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']];
    $proc = proc_open($cmd, $desc, $pipes);
    if (is_resource($proc)) {
        fwrite($pipes[0], $msg);
        fclose($pipes[0]);
        fclose($pipes[1]);
        fclose($pipes[2]);
        $code = proc_close($proc);
        return $code === 0;
    }
    return false;
}

function csrf_token() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrf_field() {
    return '<input type="hidden" name="csrf_token" value="'.csrf_token().'">';
}

function verify_csrf() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') return true;
    $token = $_POST['csrf_token'] ?? '';
    if (empty($token) || !hash_equals($_SESSION['csrf_token']??'', $token)) {
        http_response_code(403);
        die(json_encode(['success'=>false,'message'=>'CSRF token invalid']));
    }
    return true;
}

function check_rate_limit($key, $maxAttempts=5, $window=300) {
    $db = getDB();
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $since = date('Y-m-d H:i:s', time() - $window);
    $st = $db->prepare("SELECT COUNT(*) FROM login_attempts WHERE ip_address=? AND action=? AND success=0 AND attempted_at>?");
    $st->execute([$ip, $key, $since]);
    $attempts = (int)$st->fetchColumn();
    return $attempts < $maxAttempts;
}

function log_login_attempt($action, $success, $username=null) {
    $db = getDB();
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $st = $db->prepare("INSERT INTO login_attempts (ip_address, username, action, success) VALUES (?,?,?,?)");
    $st->execute([$ip, $username, $action, $success ? 1 : 0]);
}

function cleanup_rate_limits() {
    $db = getDB();
    $cutoff = date('Y-m-d H:i:s', time() - 3600);
    $db->prepare("DELETE FROM login_attempts WHERE attempted_at < ?")->execute([$cutoff]);
}

function requireLogin() {
    if (session_status()===PHP_SESSION_NONE) session_start();
    if (!isset($_SESSION['user_id'])) {
        if (strpos($_SERVER['REQUEST_URI']??'','/api/')!==false) {
            header('Content-Type: application/json');
            echo json_encode(['success'=>false,'message'=>'Unauthorized']); exit;
        }
        header('Location: /'); exit;
    }
    try {
        $db = getDB();
        $s = $db->prepare("SELECT saldo,is_verified FROM users WHERE id=?");
        $s->execute([$_SESSION['user_id']]);
        $u = $s->fetch();
        if ($u) $_SESSION['saldo'] = $u['saldo'];
    } catch(Exception $e){}
    return $_SESSION;
}

function requireAdmin() {
    $s = requireLogin();
    if (($s['role']??'') !== 'admin') {
        header('Location: /dashboard.php'); exit;
    }
    return $s;
}
