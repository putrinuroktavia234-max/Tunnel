<?php
require_once __DIR__.'/../includes/config.php';
require_once __DIR__.'/../includes/vpn_manager.php';
$session = requireLogin();
header('Content-Type: application/json');

$userId   = $session['user_id'];
$serverId = (int)($_POST['server_id'] ?? 0);
$tipe     = strtolower(sanitize($_POST['tipe'] ?? ''));
$username = preg_replace('/[^a-zA-Z0-9_\-]/', '', $_POST['username'] ?? '');
$days     = (int)($_POST['days'] ?? 0);
$isTrial  = isset($_POST['is_trial']) && $_POST['is_trial'] == 1;
$promoCode = strtoupper(sanitize($_POST['promo_code']??''));

if (!$serverId || !$tipe || !$username || $days < 1) {
    echo json_encode(['success'=>false,'message'=>'Parameter tidak lengkap']); exit;
}
if (!in_array($tipe, ['ssh','vmess','vless','trojan'])) {
    echo json_encode(['success'=>false,'message'=>'Tipe tidak valid']); exit;
}

$db = getDB();

// Ambil server
$st = $db->prepare("SELECT * FROM servers WHERE id=? AND status='ready'");
$st->execute([$serverId]); $server = $st->fetch();
if (!$server) { echo json_encode(['success'=>false,'message'=>'Server tidak tersedia']); exit; }

// Hitung harga
$hargaHari  = (float)$server['harga_hari'];
$hargaBulan = (float)$server['harga_bulan'];
$harga = $days >= 30
    ? ($hargaBulan * floor($days/30)) + ($hargaHari * ($days%30))
    : $hargaHari * $days;

// Promo check
$diskon = 0; $promoData = null;
if ($promoCode && !$isTrial) {
    $st = $db->prepare("SELECT * FROM promo_codes WHERE code=? AND status='active'");
    $st->execute([$promoCode]); $promoData = $st->fetch();
    if ($promoData) {
        if ($promoData['expires_at'] && $promoData['expires_at'] < date('Y-m-d')) $promoData = null;
        elseif ($promoData['max_uses'] > 0 && (int)$promoData['used_count'] >= (int)$promoData['max_uses']) $promoData = null;
        elseif ($promoData['min_price'] > 0 && $harga < (int)$promoData['min_price']) $promoData = null;
    }
    if ($promoData) {
        if ($promoData['discount_type'] === 'percent') $diskon = (int)($harga * (int)$promoData['discount_value'] / 100);
        else $diskon = (int)$promoData['discount_value'];
        if ($diskon > $harga) $diskon = $harga;
        $harga -= $diskon;
    }
}

// Trial check
if ($isTrial) {
    $used = $db->prepare("SELECT COUNT(*) FROM vpn_accounts WHERE user_id=? AND is_trial=1 AND DATE(created_at)=CURDATE()");
    $used->execute([$userId]);
    if ((int)$used->fetchColumn() > 0) {
        echo json_encode(['success'=>false,'message'=>'Kamu sudah ambil trial hari ini. Coba lagi besok.']); exit;
    }
    $harga = 0; $days = 1; $isTrial = true;
} else {
    // Cek saldo
    $u = $db->prepare("SELECT saldo FROM users WHERE id=?");
    $u->execute([$userId]); $user = $u->fetch();
    if ((float)$user['saldo'] < $harga) {
        echo json_encode(['success'=>false,'message'=>'Saldo tidak cukup! Saldo kamu: '.formatRupiah($user['saldo'])]); exit;
    }
}

// Buat akun di server
$result = VPNManager::createAccount($server, $tipe, $username, $days,
    (int)($server['quota_limit'] ?? 100), (int)($server['ip_limit'] ?? 2));

if (!$result['success']) {
    echo json_encode($result); exit;
}

$db->beginTransaction();
try {
    // Kurangi saldo (jika bukan trial)
    if (!$isTrial && $harga > 0) {
        $db->prepare("UPDATE users SET saldo=saldo-? WHERE id=?")->execute([$harga, $userId]);
    }

    // Hitung masa aktif
    $expiry = $isTrial
        ? date('Y-m-d H:i:s', strtotime('+1 hour'))
        : date('Y-m-d H:i:s', strtotime("+{$days} days"));

    // Simpan akun
    $ins = $db->prepare("INSERT INTO vpn_accounts 
        (user_id,server_id,tipe,username,uuid,password_vpn,link_config,link_tls,link_nontls,link_grpc,masa_aktif,days_ordered,is_trial,harga_total,status)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,'active')");
    $ins->execute([
        $userId, $serverId, $tipe, $username,
        $result['uuid'] ?? null,
        $result['password'] ?? $result['uuid'] ?? null,
        $result['link_config'] ?? $result['link_tls'] ?? null,
        $result['link_tls'] ?? null,
        $result['link_nontls'] ?? null,
        $result['link_grpc'] ?? null,
        $expiry, $days, $isTrial ? 1 : 0, $harga
    ]);

    // Catat transaksi
    $ketOrder = "Order {$tipe} - {$username} ({$days} hari)";
    if ($promoData) $ketOrder .= " [Promo: {$promoData['code']}]";
    if (!$isTrial) {
        $db->prepare("INSERT INTO transactions (user_id,type,amount,keterangan,status) VALUES (?,?,?,?,'success')")
           ->execute([$userId, 'order', $harga, $ketOrder]);
    } else {
        $db->prepare("INSERT INTO transactions (user_id,type,amount,keterangan,status) VALUES (?,?,0,?,'success')")
           ->execute([$userId, 'trial', "Trial {$tipe} - {$username} (1 jam)"]);
    }

    // Increment promo usage
    if ($promoData) {
        $db->prepare("UPDATE promo_codes SET used_count=used_count+1 WHERE id=?")->execute([$promoData['id']]);
    }

    $db->commit();

    // Tambah info ke response
    $result['expired'] = $isTrial
        ? date('d M Y, H:i', strtotime('+1 hour')).' (1 Jam Trial)'
        : date('d M Y', strtotime("+{$days} days"));
    $result['harga']   = formatRupiah($harga);
    $result['is_trial']= $isTrial;
    if ($diskon > 0) {
        $result['diskon'] = formatRupiah($diskon);
        $result['promo_code'] = $promoCode;
    }

    // Notif Telegram
    $notifMsg = $isTrial
        ? "[POWER] <b>Trial Baru</b>\nUser: {$username}\nTipe: {$tipe}\nServer: {$server['nama_server']}"
        : "[CART] <b>Order Baru</b>\nUser: {$username}\nTipe: {$tipe}\nServer: {$server['nama_server']}\nDurasi: {$days} hari\nTotal: ".formatRupiah($harga);
    sendTelegramNotif($notifMsg);

    echo json_encode($result);

} catch (Exception $e) {
    $db->rollback();
    // Rollback akun di server jika DB error
    VPNManager::deleteAccount($server, $tipe, $username);
    echo json_encode(['success'=>false,'message'=>'DB error: '.$e->getMessage()]);
}
