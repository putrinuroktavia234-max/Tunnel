<?php
require_once __DIR__.'/../includes/config.php';
$session = requireLogin();
header('Content-Type: application/json');

$code = strtoupper(sanitize($_POST['code']??''));
if (!$code) {
    echo json_encode(['success'=>false,'message'=>'Masukkan kode promo']); exit;
}

$db = getDB();
$serverId = (int)($_POST['server_id'] ?? 0);
$days = (int)($_POST['days'] ?? 0);
$price = 0;
if ($serverId > 0 && $days > 0) {
    $server = $db->prepare("SELECT harga_hari, harga_bulan FROM servers WHERE id=? AND status='ready'");
    $server->execute([$serverId]);
    $server = $server->fetch();
    if ($server) {
        $price = $days >= 30
            ? ((float)$server['harga_bulan'] * floor($days / 30)) + ((float)$server['harga_hari'] * ($days % 30))
            : (float)$server['harga_hari'] * $days;
    }
}
$st = $db->prepare("SELECT p.*, EXISTS(
    SELECT 1 FROM promo_redemptions pr WHERE pr.promo_id=p.id AND pr.user_id=?
) AS already_used FROM promo_codes p WHERE p.code=? AND p.status='active'");
$st->execute([$session['user_id'], $code]);
$p = $st->fetch();

if (!$p) {
    echo json_encode(['success'=>false,'message'=>'Kode promo tidak ditemukan']); exit;
}

if ($p['expires_at'] && date('Y-m-d', strtotime($p['expires_at'])) < date('Y-m-d')) {
    echo json_encode(['success'=>false,'message'=>'Kode promo sudah kadaluarsa']); exit;
}

if ($p['max_uses'] > 0 && (int)$p['used_count'] >= (int)$p['max_uses']) {
    echo json_encode(['success'=>false,'message'=>'Kuota pemakaian kode promo sudah habis']); exit;
}

if ($p['min_price'] > 0 && $price > 0 && $price < (float)$p['min_price']) {
    echo json_encode(['success'=>false,'message'=>'Minimal pembelian untuk promo ini adalah '.formatRupiah($p['min_price'])]); exit;
}

if ((int)$p['already_used'] === 1) {
    echo json_encode(['success'=>false,'message'=>'Kode promo ini sudah pernah kamu gunakan']); exit;
}

if ($p['discount_type']==='free_account') {
    $label = 'GRATIS '.(int)$p['free_days'].' Hari!';
} elseif ($p['discount_type']==='percent') {
    $label = 'Diskon '.$p['discount_value'].'%';
} else {
    $label = 'Diskon '.formatRupiah($p['discount_value']);
}

echo json_encode([
    'success'=>true,
    'data'=>[
        'code'=>$p['code'],
        'type'=>$p['discount_type'],
        'val'=>(int)$p['discount_value'],
        'free_days'=>(int)($p['free_days']??0),
        'min_price'=>(int)$p['min_price'],
        'label'=>$label
    ]
]);
