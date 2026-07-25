<?php
if (!isset($_SESSION['csrf_token'])) $_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// Hanya deklarasi jika belum ada (config.php sudah mendefinisikan versi DB-backed)
if (!function_exists('csrf_token')) {
    function csrf_token(): string { return $_SESSION['csrf_token'] ?? ''; }
}

if (!function_exists('csrf_valid')) {
    function csrf_valid(?string $token): bool {
        if (empty($_SESSION['csrf_token']) || empty($token)) return false;
        return hash_equals($_SESSION['csrf_token'], $token);
    }
}

if (!function_exists('check_rate_limit')) {
    function check_rate_limit(string $action, int $max = 5, int $win = 15): bool {
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        $key = 'rl_'.md5($ip.'_'.$action);
        $a = isset($_SESSION[$key]) ? array_filter($_SESSION[$key], fn($t) => $t > (time()-$win*60)) : [];
        if (count($a) >= $max) return false;
        $a[] = time(); $_SESSION[$key] = array_values($a); return true;
    }
}

if (!function_exists('reset_rate_limit')) {
    function reset_rate_limit(string $action): void {
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        unset($_SESSION['rl_'.md5($ip.'_'.$action)]);
    }
}
