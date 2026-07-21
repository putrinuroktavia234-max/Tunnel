<?php
require_once __DIR__.'/../includes/config.php';
$session = requireLogin();
header('Content-Type: application/json');

$userId = $session['user_id'];
$db = getDB();

$s = $db->prepare("SELECT avatar FROM users WHERE id=?");
$s->execute([$userId]);
$avatar = $s->fetchColumn();

if ($avatar) {
    $file = __DIR__.'/../'.ltrim($avatar, '/');
    if (file_exists($file)) unlink($file);
}

$db->prepare("UPDATE users SET avatar=NULL WHERE id=?")->execute([$userId]);
echo json_encode(['success'=>true,'message'=>'Foto profil dihapus']);
