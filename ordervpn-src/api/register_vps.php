<?php
require_once __DIR__.'/../includes/config.php';

header('Content-Type: application/json');

$secret = getSetting('vpn_join_secret', '');
if (empty($secret)) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Join secret not configured. Generate one from admin panel.']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON']);
    exit;
}

if (!isset($input['secret']) || $input['secret'] !== $secret) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Invalid secret']);
    exit;
}

$action = $input['action'] ?? '';

if ($action === 'register') {
    $host = sanitize($input['host'] ?? '');
    $code = sanitize($input['code_server'] ?? '');
    $nama = sanitize($input['name'] ?? '');
    $lokasi = sanitize($input['lokasi'] ?? 'Unknown');
    $flag = sanitize($input['flag'] ?? '🌐');
    $domain = sanitize($input['domain'] ?? '');
    $pubkey = $input['pubkey'] ?? '';

    if (empty($host) || empty($code) || empty($pubkey)) {
        echo json_encode(['success' => false, 'message' => 'host, code_server, and pubkey required']);
        exit;
    }

    $db = getDB();

    // Check if code already exists
    $chk = $db->prepare("SELECT id FROM servers WHERE code_server=?");
    $chk->execute([$code]);
    if ($chk->fetch()) {
        // Update existing
        $db->prepare("UPDATE servers SET host=?, name=?, lokasi=?, flag=?, domain=?, status='ready' WHERE code_server=?")
           ->execute([$host, $nama, $lokasi, $flag, $domain, $code]);
    } else {
        // Insert new
        $db->prepare("INSERT INTO servers (name,code_server,lokasi,flag,harga_hari,harga_bulan,host,port,ssh_user,domain,status)
            VALUES (?,?,?,?,300,9000,?,22,'root',?,'ready')")
           ->execute([$nama, $code, $lokasi, $flag, $host, $domain]);
    }

    // Save SSH public key
    $keyFile = "/root/.ssh/vps_{$code}.pub";
    file_put_contents($keyFile, $pubkey);
    chmod($keyFile, 0600);

    // Add to authorized_keys
    $authFile = "/root/.ssh/authorized_keys";
    $existing = file_exists($authFile) ? file_get_contents($authFile) : '';
    if (strpos($existing, $pubkey) === false) {
        file_put_contents($authFile, $existing . "\n" . $pubkey . "\n", LOCK_EX);
    }

    // Add own public key to the new VPS's authorized keys (for master to SSH back)
    $masterKey = file_get_contents("/root/.ssh/id_rsa.pub");
    $masterKey = trim($masterKey ?? '');

    echo json_encode([
        'success' => true,
        'message' => "VPS '$nama' ($code) registered successfully",
        'master_pubkey' => $masterKey,
        'master_ip' => $_SERVER['SERVER_ADDR'] ?? gethostbyname(gethostname()),
        'master_port' => 22,
    ]);
    exit;
}

if ($action === 'heartbeat') {
    $code = sanitize($input['code_server'] ?? '');
    $cpu = $input['cpu'] ?? null;
    $ram = $input['ram'] ?? null;
    $disk = $input['disk'] ?? null;
    $uptime = $input['uptime'] ?? null;

    if (empty($code)) {
        echo json_encode(['success' => false, 'message' => 'code_server required']);
        exit;
    }

    $db = getDB();
    $db->prepare("UPDATE servers SET last_heartbeat=NOW(), cpu=?, ram=?, disk=? WHERE code_server=?")
       ->execute([$cpu, $ram, $disk, $code]);

    echo json_encode(['success' => true]);
    exit;
}

echo json_encode(['success' => false, 'message' => 'Unknown action']);
