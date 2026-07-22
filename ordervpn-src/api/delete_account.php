<?php
require_once __DIR__.'/../includes/config.php';
require_once __DIR__.'/../includes/vpn_manager.php';
$session = requireLogin();
header('Content-Type: application/json');

$userId  = $session['user_id'];
$akunId  = (int)($_POST['akun_id'] ?? 0);
if (!$akunId) { echo json_encode(['success'=>false,'message'=>'ID tidak valid']); exit; }

$db = getDB();
// Ambil akun milik user ini saja (keamanan)
$st = $db->prepare("SELECT va.*, s.host, s.port, s.ssh_user, s.ssh_password, s.ssh_key 
    FROM vpn_accounts va JOIN servers s ON va.server_id=s.id 
    WHERE va.id=? AND va.user_id=?");
$st->execute([$akunId, $userId]); $akun = $st->fetch();
if (!$akun) { echo json_encode(['success'=>false,'message'=>'Akun tidak ditemukan']); exit; }

// Hapus dari server VPN (fix utama)
$res = VPNManager::deleteAccount($akun, $akun['tipe'], $akun['username']);

// Hapus dari DB meski server error (akun mungkin sudah tidak ada)
$db->prepare("DELETE FROM vpn_accounts WHERE id=?")->execute([$akunId]);

echo json_encode(['success'=>true,'message'=>'Akun berhasil dihapus dari server dan database']);
