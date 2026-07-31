<?php
require_once __DIR__.'/../includes/config.php';
$session = requireLogin();
header('Content-Type: application/json');

$userId = $session['user_id'];
$email  = sanitize($_POST['email'] ?? '');
$wa     = sanitize($_POST['whatsapp'] ?? '');
$pass   = $_POST['password'] ?? '';

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success'=>false,'message'=>'Format email tidak valid']); exit;
}

$db = getDB();
$roleStmt = $db->prepare('SELECT role FROM users WHERE id=?');
$roleStmt->execute([$userId]);
$currentRole = $roleStmt->fetchColumn();
if ($currentRole === 'admin' && !empty($pass)) {
    echo json_encode(['success'=>false,'message'=>'Password admin harus diganti melalui Menu 21 agar informasi password tetap sinkron']); exit;
}
// Cek duplikat email
$chk = $db->prepare("SELECT id FROM users WHERE email=? AND id!=?");
$chk->execute([$email, $userId]);
if ($chk->fetch()) { echo json_encode(['success'=>false,'message'=>'Email sudah digunakan']); exit; }

if (!empty($pass)) {
    if (strlen($pass) < 6) { echo json_encode(['success'=>false,'message'=>'Password min. 6 karakter']); exit; }
    $db->prepare("UPDATE users SET email=?, whatsapp=?, password=? WHERE id=?")
       ->execute([$email, $wa, password_hash($pass, PASSWORD_BCRYPT), $userId]);
} else {
    $db->prepare("UPDATE users SET email=?, whatsapp=? WHERE id=?")
       ->execute([$email, $wa, $userId]);
}
echo json_encode(['success'=>true,'message'=>'Profil berhasil diperbarui']);
