<?php
require_once __DIR__.'/../includes/config.php';

$secret = $_GET['secret'] ?? '';
$valid = getSetting('vpn_join_secret', '');
if (empty($valid) || $secret !== $valid) {
    http_response_code(403);
    exit;
}

header('Content-Type: application/x-sh');
$bridge = file_get_contents('/usr/local/bin/vpn-api');
if ($bridge) {
    echo $bridge;
} else {
    http_response_code(404);
}
