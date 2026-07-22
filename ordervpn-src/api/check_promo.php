<?php
require_once __DIR__.'/../includes/config.php';
$session = requireLogin();
header('Content-Type: application/json');

$code = strtoupper(sanitize($_POST['code']??''));
if (!$code) {
    echo json_encode(['success'=>false,'message'=>'Masukkan kode promo']); exit;
}

$db = getDB();
$st = $db->prepare("SELECT * FROM promo_codes WHERE code=? AND status='active'");
$st->execute([$code]);
$p = $st->fetch();

if (!$p) {
    echo json_encode(['success'=>false,'message'=>'Kode promo tidak ditemukan']); exit;
}

if ($p['expires_at'] && $p['expires_at'] < date('Y-m-d')) {
    echo json_encode(['success'=>false,'message'=>'Kode promo sudah kadaluarsa']); exit;
}

if ($p['max_uses'] > 0 && (int)$p['used_count'] >= (int)$p['max_uses']) {
    echo json_encode(['success'=>false,'message'=>'Kuota pemakaian kode promo sudah habis']); exit;
}

$label = $p['discount_type']==='percent'
    ? 'Diskon '.$p['discount_value'].'%'
    : 'Diskon '.formatRupiah($p['discount_value']);

echo json_encode([
    'success'=>true,
    'data'=>[
        'code'=>$p['code'],
        'type'=>$p['discount_type'],
        'val'=>(int)$p['discount_value'],
        'min_price'=>(int)$p['min_price'],
        'label'=>$label
    ]
]);
