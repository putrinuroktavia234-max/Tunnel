<?php
require_once __DIR__.'/../includes/config.php';
$session = requireLogin();
header('Content-Type: application/json');

$userId = $session['user_id'];

if (empty($_FILES['avatar']['tmp_name'])) {
    echo json_encode(['success'=>false,'message'=>'Pilih file gambar']);
    exit;
}

$allowed = ['jpg','jpeg','png','gif','webp'];
$ext = strtolower(pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION));
if (!in_array($ext, $allowed)) {
    echo json_encode(['success'=>false,'message'=>'Format harus jpg/jpeg/png/gif/webp']);
    exit;
}

$uploadDir = __DIR__.'/../uploads/avatars/';
if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);

$fname = 'avatar_'.$userId.'_'.time().'.'.$ext;
$dest = $uploadDir.$fname;

if (!move_uploaded_file($_FILES['avatar']['tmp_name'], $dest)) {
    echo json_encode(['success'=>false,'message'=>'Gagal upload file']);
    exit;
}

$db = getDB();
$db->prepare("UPDATE users SET avatar=? WHERE id=?")->execute(['/uploads/avatars/'.$fname, $userId]);

echo json_encode(['success'=>true,'message'=>'Foto profil berhasil diupdate','avatar'=>'/uploads/avatars/'.$fname]);
