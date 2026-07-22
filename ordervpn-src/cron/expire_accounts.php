<?php
// Cron: jalankan setiap jam via crontab
// 0 * * * * php /var/www/html/cron/expire_accounts.php
require_once __DIR__.'/../includes/config.php';
require_once __DIR__.'/../includes/vpn_manager.php';
$count = VPNManager::processExpiredAccounts();
echo date('Y-m-d H:i:s')." — Expired {$count} accounts\n";
