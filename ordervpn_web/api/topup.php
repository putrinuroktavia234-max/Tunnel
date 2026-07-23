<?php
require_once __DIR__.'/../includes/config.php';
$session = requireLogin();
header('Content-Type: application/json');

$userId = $session['user_id'];
$amount = (float)($_POST['amount'] ?? 0);
$method = sanitize($_POST['payment_method'] ?? 'manual_transfer');

if ($amount < 5000) { echo json_encode(['success'=>false,'message'=>'Nominal minimal Rp 5.000']); exit; }
if ($amount > 1000000) { echo json_encode(['success'=>false,'message'=>'Nominal maksimal Rp 1.000.000']); exit; }

$db = getDB();
$buktiPath = null;

// Upload bukti
if (!empty($_FILES['bukti']['tmp_name'])) {
    // Validate MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $_FILES['bukti']['tmp_name']);
    finfo_close($finfo);
    $allowedMimes = ['image/jpeg','image/png','image/gif','image/webp','application/pdf'];
    if (!in_array($mime, $allowedMimes)) {
        echo json_encode(['success'=>false,'message'=>'Format file tidak didukung. Gunakan JPG/PNG/GIF/WebP/PDF']);
        exit;
    }
    // Max 5MB
    if ($_FILES['bukti']['size'] > 5 * 1024 * 1024) {
        echo json_encode(['success'=>false,'message'=>'Ukuran file maksimal 5MB']);
        exit;
    }
    $uploadDir = __DIR__.'/../uploads/bukti/';
    if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
    $ext = pathinfo($_FILES['bukti']['name'], PATHINFO_EXTENSION);
    $fname = 'bukti_'.time().'_'.$userId.'.'.$ext;
    if (move_uploaded_file($_FILES['bukti']['tmp_name'], $uploadDir.$fname)) {
        $buktiPath = '/uploads/bukti/'.$fname;
    }
}

$db->prepare("INSERT INTO topup_requests (user_id, amount, payment_method, bukti_transfer) VALUES (?,?,?,?)")
   ->execute([$userId, $amount, $method, $buktiPath]);

// Notif admin
$u = $db->prepare("SELECT username FROM users WHERE id=?"); $u->execute([$userId]); $uname=$u->fetchColumn();
sendTelegramNotif("[MONEY] <b>Topup Baru</b>\nUser: {$uname}\nNominal: ".formatRupiah($amount)."\nMetode: {$method}\nStatus: Menunggu konfirmasi admin");

echo json_encode(['success'=>true,'message'=>"Permintaan topup ".formatRupiah($amount)." berhasil dikirim! Tunggu konfirmasi admin."]);
