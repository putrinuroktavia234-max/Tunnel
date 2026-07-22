<?php
// OrderVPN — Cron: delete / suspend expired accounts
require_once __DIR__ . '/../includes/config.php';

try {
    $db = getDB();
    $st = $db->prepare("UPDATE vpn_accounts SET status='expired' WHERE status='active' AND expiry_date < NOW()");
    $st->execute();
    $count = $st->rowCount();
    echo "[OK] Suspended {$count} expired accounts\n";
} catch (Exception $e) {
    echo "[ERR] " . $e->getMessage() . "\n";
    exit(1);
}
