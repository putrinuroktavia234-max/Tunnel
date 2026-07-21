<?php
// ============================================================
// OrderVPN — User Dashboard
// Multi-page SPA via ?page=X. Midnight Console theme.
// Backend actions: change_password, topup_request, renew_account,
//                  delete_vpn_account, place_order, delete_account.
// Sesuai: menu 1-8 (Account Mgmt) + 21 (OrderVPN) + 23 (Traffic).
// Sesuai: ssh/vmess/vless/trojan/zivpn ordering via servers table
//         + manual topup via Dana/GoPay/QRIS + saldo flow.
// ============================================================
require_once __DIR__.'/includes/config.php';
if (session_status() === PHP_SESSION_NONE) session_start();
$ctx      = requireLogin();
$db       = getDB();
$uid      = (int)$ctx['user_id'];
$appName  = getSetting('app_name', 'OrderVPN');
$page     = $_GET['page'] ?? 'home';
$valid    = ['home','akun','traffic','servers','orders','topup','settings'];
if (!in_array($page, $valid, true)) $page = 'home';

$me_q = $db->prepare("SELECT * FROM users WHERE id=? LIMIT 1");
$me_q->execute([$uid]);
$me = $me_q->fetch();

$isAdmin = (($me['role'] ?? '') === 'admin');
$saldo   = (int)($me['saldo'] ?? 0);

// Handle POST actions for ALL pages
$flash = ['ok' => '', 'err' => ''];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // ----- CHANGE PASSWORD -----
    if ($action === 'change_password') {
        $cur = $_POST['current_password'] ?? '';
        $np  = $_POST['new_password'] ?? '';
        $cp  = $_POST['confirm_password'] ?? '';
        if (!password_verify($cur, $me['password'])) {
            $flash['err'] = 'Password saat ini salah.';
        } elseif (strlen($np) < 6) {
            $flash['err'] = 'Password baru minimal 6 karakter.';
        } elseif ($np !== $cp) {
            $flash['err'] = 'Konfirmasi tidak cocok.';
        } else {
            $hash = password_hash($np, PASSWORD_BCRYPT);
            $db->prepare("UPDATE users SET password=? WHERE id=?")->execute([$hash, $uid]);
            $flash['ok'] = 'Password berhasil diubah.';
        }
    }

    // ----- DELETE ACCOUNT (user self-delete) -----
    if ($action === 'delete_account') {
        $confirm = sanitize($_POST['confirm_username'] ?? '');
        if ($confirm !== $me['username']) {
            $flash['err'] = 'Username konfirmasi tidak cocok.';
        } else {
            try {
                $db->beginTransaction();
                $db->prepare("DELETE FROM vpn_accounts    WHERE user_id=?")->execute([$uid]);
                $db->prepare("DELETE FROM topup_requests  WHERE user_id=?")->execute([$uid]);
                $db->prepare("DELETE FROM transactions    WHERE user_id=?")->execute([$uid]);
                $db->prepare("DELETE FROM users           WHERE id=?")->execute([$uid]);
                $db->commit();
            } catch (Exception $ex) { $db->rollBack(); $flash['err'] = 'Gagal menghapus akun: '.$ex->getMessage(); }
            if (!$flash['err']) { session_destroy(); header('Location: index.php?deleted=1'); exit; }
        }
    }

    // ----- TOPUP REQUEST -----
    if ($action === 'topup_request') {
        $amount = (int)($_POST['amount'] ?? 0);
        $method = sanitize($_POST['method'] ?? '');
        $proof  = '';
        if (!empty($_FILES['proof']) && (int)$_FILES['proof']['error'] === 0) {
            $ext = strtolower(pathinfo($_FILES['proof']['name'] ?? '', PATHINFO_EXTENSION));
            if (in_array($ext, ['jpg','jpeg','png','webp'], true)) {
                if ($_FILES['proof']['size'] > 5 * 1024 * 1024) {
                    $flash['err'] = 'Ukuran file bukti maksimal 5MB.';
                } else {
                    $fname  = 'topup_'.date('Ymd').'_'.$uid.'_'.bin2hex(random_bytes(4)).'.'.$ext;
                    $dest   = __DIR__.'/uploads/bukti/'.$fname;
                    if (!is_dir(dirname($dest))) { @mkdir(dirname($dest), 0755, true); }
                    if (move_uploaded_file($_FILES['proof']['tmp_name'], $dest)) {
                        @chmod($dest, 0644);
                        $proof = 'uploads/bukti/'.$fname;
                    } else { $flash['err'] = 'Gagal upload file bukti.'; }
                }
            } else { $flash['err'] = 'Bukti harus JPG / PNG / WebP.'; }
        }
        if (!$flash['err']) {
            if ($amount < 5000)               $flash['err'] = 'Minimum topup Rp 5.000.';
            elseif ($amount > 10000000)       $flash['err'] = 'Maksimum topup Rp 10.000.000.';
            elseif (!in_array($method, ['dana','gopay','shopeepay','ovo','qris','bank_transfer'], true))
                                            $flash['err'] = 'Metode pembayaran tidak valid.';
            elseif ($proof === '')            $flash['err'] = 'Upload bukti transfer dulu.';
        }
        if (!$flash['err']) {
            $db->prepare("INSERT INTO topup_requests (user_id, amount, method, proof_image, status, created_at) VALUES (?,?,?,?, 'pending', NOW())")
               ->execute([$uid, $amount, $method, $proof]);
            $flash['ok'] = 'Permintaan topup Rp '.number_format($amount).' dikirim. Tunggu konfirmasi admin.';
            $page = 'topup';
        }
    }

    // ----- DELETE VPN ACCOUNT -----
    if ($action === 'delete_vpn_account') {
        $acc_id = (int)($_POST['account_id'] ?? 0);
        $db->prepare("DELETE FROM vpn_accounts WHERE id=? AND user_id=?")->execute([$acc_id, $uid]);
        $flash['ok'] = 'Akun VPN dihapus.';
        $page = 'akun';
    }

    // ----- RENEW VPN ACCOUNT -----
    if ($action === 'renew_account') {
        $acc_id = (int)($_POST['account_id'] ?? 0);
        $days   = (int)($_POST['days'] ?? 30);
        $aq     = $db->prepare("SELECT * FROM vpn_accounts WHERE id=? AND user_id=? LIMIT 1");
        $aq->execute([$acc_id, $uid]);
        $acc    = $aq->fetch();
        if (!$acc)                                          $flash['err'] = 'Akun tidak ditemukan.';
        elseif ($days < 1 || $days > 365)                  $flash['err'] = 'Durasi harus 1-365 hari.';
        else {
            $sq = $db->prepare("SELECT * FROM servers WHERE id=? LIMIT 1");
            $sq->execute([$acc['server_id']]);
            $srv = $sq->fetch();
            $price = (int)round(($srv['monthly_price'] ?? 10000) * ($days / 30));
            if ($saldo < $price) $flash['err'] = 'Saldo tidak cukup. Diperlukan Rp '.number_format($price);
            else {
                try {
                    $db->beginTransaction();
                    $newExpiry = date('Y-m-d H:i:s', strtotime(($acc['expiry_date'] ?? date('Y-m-d H:i:s'))." +{$days} days"));
                    if (strtotime($newExpiry) < time()) $newExpiry = date('Y-m-d H:i:s', strtotime("+{$days} days"));
                    $db->prepare("UPDATE vpn_accounts SET expiry_date=?, status='active' WHERE id=?")->execute([$newExpiry, $acc_id]);
                    $db->prepare("UPDATE users SET saldo = saldo - ? WHERE id=?")->execute([$price, $uid]);
                    $db->prepare("INSERT INTO transactions (user_id, server_id, account_id, type, amount, status, created_at) VALUES (?,?,?,?,?, 'success', NOW())")
                       ->execute([$uid, $acc['server_id'], $acc_id, 'renew', $price]);
                    $db->commit();
                    $saldo -= $price;
                    $flash['ok'] = "Akun #{$acc_id} diperpanjang {$days} hari. Saldo berkurang Rp ".number_format($price).'.';
                } catch (Exception $ex) { $db->rollBack(); $flash['err'] = 'Transaksi gagal: '.$ex->getMessage(); }
            }
        }
        $page = 'akun';
    }

    // ----- PLACE ORDER (create_account) -----
    if ($action === 'place_order') {
        $server_id = (int)($_POST['server_id'] ?? 0);
        $protocol  = sanitize($_POST['protocol'] ?? '');
        $days      = (int)($_POST['days'] ?? 30);
        $promo     = sanitize($_POST['promo_code'] ?? '');

        $sq = $db->prepare("SELECT * FROM servers WHERE id=? AND status='ready' LIMIT 1");
        $sq->execute([$server_id]);
        $srv = $sq->fetch();

        if (!$srv)                                                            $flash['err'] = 'Server tidak tersedia.';
        elseif (!in_array($protocol, ['ssh','vmess','vless','trojan','zivpn-udp','udp-custom'], true))
                                                                              $flash['err'] = 'Protokol tidak valid.';
        elseif ($days < 1 || $days > 365)                                     $flash['err'] = 'Durasi 1-365 hari.';
        else {
            $price = (int)round(($srv['monthly_price'] ?? 10000) * ($days / 30));
            // Apply promo if any
            $discount = 0;
            if ($promo !== '') {
                $pq = $db->prepare("SELECT * FROM promo_codes WHERE code=? AND (max_uses IS NULL OR used_count < max_uses) AND (expires IS NULL OR expires > NOW()) LIMIT 1");
                $pq->execute([$promo]);
                $promoRow = $pq->fetch();
                if ($promoRow) { $discount = (int)($price * ((float)($promoRow['discount'] ?? 0) / 100)); }
            }
            $finalPrice = $price - $discount;
            if ($saldo < $finalPrice) $flash['err'] = 'Saldo tidak cukup. Diperlukan Rp '.number_format($finalPrice);
            else {
                try {
                    $db->beginTransaction();
                    $username = strtolower($me['username']).'-'.substr(bin2hex(random_bytes(2)), 0, 4);
                    $password = bin2hex(random_bytes(6));
                    $ip_limit = 2;
                    $expiry   = date('Y-m-d H:i:s', strtotime("+{$days} days"));
                    $db->prepare("INSERT INTO vpn_accounts (user_id, server_id, username, password, protocol, ip_limit, expiry_date, status, created_at) VALUES (?,?,?,?,?,?,?, 'active', NOW())")
                       ->execute([$uid, $server_id, $username, $password, $protocol, $ip_limit, $expiry, $ip_limit, $expiry]);
                    $acc_id = (int)$db->lastInsertId();
                    $db->prepare("UPDATE users SET saldo = saldo - ? WHERE id=?")->execute([$finalPrice, $uid]);
                    $db->prepare("INSERT INTO transactions (user_id, server_id, account_id, type, amount, status, created_at) VALUES (?,?,?,?,?, 'success', NOW())")
                       ->execute([$uid, $server_id, $acc_id, 'order', $finalPrice]);
                    if ($promoRow ?? false) {
                        $db->prepare("UPDATE promo_codes SET used_count = used_count + 1 WHERE id=?")->execute([$promoRow['id']]);
                    }
                    $db->commit();
                    $saldo -= $finalPrice;
                    $flash['ok'] = "Order berhasil. Akun #{$acc_id} ({$protocol}) di {$srv['name']} aktif sampai ".date('d M Y', strtotime($expiry)).'. Username: '.htmlspecialchars($username);
                } catch (Exception $ex) { $db->rollBack(); $flash['err'] = 'Order gagal: '.$ex->getMessage(); }
            }
        }
        $page = 'orders';
    }
}

// ====== DATA FETCHES PER PAGE ======
$counts = [
    'akun_active'   => 0,
    'akun_total'    => 0,
    'orders'        => 0,
    'topup_pending' => 0,
];
if ($db) {
    try {
        $counts['akun_active']   = (int)$db->query("SELECT COUNT(*) FROM vpn_accounts WHERE user_id={$uid} AND status='active' AND expiry_date > NOW()")->fetchColumn();
        $counts['akun_total']    = (int)$db->query("SELECT COUNT(*) FROM vpn_accounts WHERE user_id={$uid}")->fetchColumn();
        $counts['orders']        = (int)$db->query("SELECT COUNT(*) FROM transactions WHERE user_id={$uid}")->fetchColumn();
        $counts['topup_pending'] = (int)$db->query("SELECT COUNT(*) FROM topup_requests WHERE user_id={$uid} AND status='pending'")->fetchColumn();
    } catch (Exception $ex) { /* tables may not exist yet — silently skip */ }
}

$pages = [
    'home'     => '[ 01 // Overview ]',
    'akun'     => '[ 02 // Account Mgmt ]',
    'traffic'  => '[ 03 // Traffic Monitor ]',
    'servers'  => '[ 04 // Browse Servers ]',
    'orders'   => '[ 05 // Order History ]',
    'topup'    => '[ 06 // Topup Saldo ]',
    'settings' => '[ 07 // Settings ]',
];
$titles = [
    'home'     => 'Dashboard Overview',
    'akun'     => 'Akun VPN Saya',
    'traffic'  => 'Traffic Monitor',
    'servers'  => 'Browse Server',
    'orders'   => 'Riwayat Order',
    'topup'    => 'Topup Saldo',
    'settings' => 'Pengaturan Akun',
];
$pageTitle = $titles[$page];
$pageEyebrow = $pages[$page];
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($pageTitle) ?> · <?= htmlspecialchars($appName) ?></title>
<link rel="stylesheet" href="assets/ordervpn.css?v=3.12.1">
<style>
/* ============================================================
   DASHBOARD-SPECIFIC (extends shared tokens from ordervpn.css)
   ============================================================ */
.dash-layout { display:grid; grid-template-columns:240px 1fr; min-height:calc(100vh - 60px); }
.dash-side   { background:var(--bg-elev); border-right:1px solid var(--border); padding:20px 0; position:sticky; top:60px; height:calc(100vh - 60px); overflow-y:auto; }
.dash-side-user { padding:0 22px 18px; margin-bottom:6px; }
.dash-side-user .who   { font-family:var(--font-display); font-size:14px; font-weight:700; color:var(--text); letter-spacing:-0.01em; }
.dash-side-user .email { font-family:var(--font-display); font-size:10px; color:var(--muted); margin-top:4px; word-break:break-all; }
.dash-side-user .saldo { display:flex; flex-direction:column; gap:4px; margin-top:14px; padding:10px 12px; background:var(--bg); border:1px solid var(--border); }
.dash-side-user .saldo-label { font-family:var(--font-display); font-size:9px; color:var(--muted); letter-spacing:0.28em; text-transform:uppercase; }
.dash-side-user .saldo-amt   { font-family:var(--font-display); font-size:17px; font-weight:700; color:var(--yellow); letter-spacing:-0.01em; }
.dash-side-nav { display:flex; flex-direction:column; gap:1px; padding:0 10px; margin-top:8px; }
.dash-nav-btn { display:flex; align-items:center; gap:10px; padding:9px 12px; border:none; border-left:2px solid transparent; background:transparent; color:var(--text-dim); font-family:var(--font-display); font-size:11px; font-weight:700; letter-spacing:0.18em; text-transform:uppercase; cursor:pointer; text-align:left; text-decoration:none; transition:background var(--transition), color var(--transition), border-color var(--transition); }
.dash-nav-btn:hover { background:rgba(0,255,170,0.05); color:var(--text); }
.dash-nav-btn.active { background:rgba(0,255,170,0.1); color:var(--cyan); border-left-color:var(--cyan); padding-left:10px; }
.dash-nav-btn .icn { font-family:var(--font-display); font-size:13px; min-width:14px; color:var(--cyan); }
.dash-nav-btn .badge-count { margin-left:auto; background:rgba(255,198,0,0.15); color:var(--yellow); font-size:9px; padding:2px 6px; }
.dash-main { padding:32px 40px; max-width:1240px; }
.dash-eyebrow { font-family:var(--font-display); font-size:11px; color:var(--cyan); letter-spacing:0.3em; text-transform:uppercase; margin-bottom:10px; }
.dash-h1 { font-family:var(--font-display); font-size:1.7rem; font-weight:700; letter-spacing:-0.025em; line-height:1.15; margin-bottom:6px; }
.dash-sub { color:var(--muted); margin-bottom:28px; font-size:0.92rem; }
.flash { padding:14px 16px; border-left:3px solid; font-family:var(--font-display); font-size:12px; margin-bottom:24px; letter-spacing:0.05em; animation:fadeSlide 0.25s ease-out; }
.flash-ok  { border-color:var(--success); background:rgba(63,185,80,0.08); color:#7be899; }
.flash-err { border-color:var(--danger);  background:rgba(248,81,73,0.08); color:#ff8a82; }
@keyframes fadeSlide { from{opacity:0;transform:translateY(-6px)} to{opacity:1;transform:translateY(0)} }

/* Stat grid */
.stat-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:1px; background:var(--border); border:1px solid var(--border); margin-bottom:32px; }
.stat-box { background:var(--bg); padding:20px 22px; }
.stat-box .label { font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.28em; text-transform:uppercase; }
.stat-box .val   { font-family:var(--font-display); font-size:1.7rem; font-weight:700; letter-spacing:-0.02em; margin-top:6px; }
.stat-box .val.cyan   { color:var(--cyan); }
.stat-box .val.yellow { color:var(--yellow); }
.stat-box .subtitle   { font-size:0.78rem; color:var(--muted); margin-top:4px; }

/* Quick action cards */
.qa-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:14px; margin-bottom:32px; }
.qa-card { display:block; padding:22px 20px; border:1px solid var(--border); background:var(--bg-elev); transition:border-color var(--transition), background var(--transition); text-decoration:none; }
.qa-card:hover { border-color:var(--cyan); background:rgba(0,255,170,0.04); }
.qa-card h3 { font-family:var(--font-display); font-size:13px; margin-bottom:6px; color:var(--text); letter-spacing:-0.01em; }
.qa-card p  { font-size:0.84rem; color:var(--muted); line-height:1.5; }
.qa-card .arr { color:var(--cyan); font-family:var(--font-display); font-size:11px; margin-top:12px; display:block; letter-spacing:0.15em; }

/* Section card */
.section-card { background:var(--bg-elev); border:1px solid var(--border); margin-bottom:22px; }
.section-card .head { padding:14px 18px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
.section-card .head h3 { font-family:var(--font-display); font-size:11px; color:var(--cyan); letter-spacing:0.25em; text-transform:uppercase; }
.section-card .body { padding:18px; }

/* Tables */
.table-wrap { background:var(--bg-elev); border:1px solid var(--border); overflow-x:auto; margin-bottom:22px; }
table.data { width:100%; border-collapse:collapse; font-size:0.88rem; }
table.data th { text-align:left; padding:11px 14px; font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.22em; text-transform:uppercase; border-bottom:1px solid var(--border); white-space:nowrap; }
table.data td { padding:13px 14px; border-bottom:1px solid var(--border-dim); color:var(--text-dim); vertical-align:middle; }
table.data tr:last-child td { border-bottom:none; }
table.data tr:hover td { background:rgba(0,255,170,0.03); }
table.data td.mono { font-family:var(--font-display); font-size:11px; color:var(--text); letter-spacing:0; }
table.data td .row-actions { display:flex; gap:6px; }

/* Pills */
.pill { display:inline-block; padding:3px 9px; font-family:var(--font-display); font-size:9px; font-weight:700; letter-spacing:0.2em; text-transform:uppercase; }
.pill-active   { background:rgba(63,185,80,0.15) ; color:var(--success); }
.pill-expired  { background:rgba(248,81,73,0.12) ; color:var(--danger);  }
.pill-pending  { background:rgba(255,198,0,0.15) ; color:var(--yellow);  }
.pill-online   { background:rgba(16,185,129,0.12); color:var(--success); }
.pill-offline  { background:rgba(100,116,139,0.12); color:var(--muted);   }
.pill-protocol { background:rgba(99,102,241,0.15) ; color:var(--accent); }

/* Connection details card */
.conn-card { background:var(--bg); border:1px solid var(--border); padding:14px; font-family:var(--font-display); font-size:11px; color:var(--text-dim); white-space:pre-wrap; word-break:break-all; line-height:1.65; max-height:280px; overflow:auto; }
.conn-card .kv { display:flex; gap:8px; padding:2px 0; border-bottom:1px dashed var(--border-dim); }
.conn-card .kv:last-child { border-bottom:none; }
.conn-card .kv .k { color:var(--cyan); min-width:90px; flex-shrink:0; }

/* Forms */
.form-group { margin-bottom:14px; }
.form-group label { display:block; font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.2em; text-transform:uppercase; margin-bottom:6px; }
.form-group input[type=text], .form-group input[type=email], .form-group input[type=password], .form-group input[type=number], .form-group input[type=file], .form-group select, .form-group textarea {
  width:100%; padding:10px 12px; background:var(--bg); border:1px solid var(--border); color:var(--text); font-family:var(--font-body); font-size:0.92rem;
}
.form-group input:focus, .form-group select:focus, .form-group textarea:focus { outline:none; border-color:var(--cyan); box-shadow:0 0 0 3px rgba(0,255,170,0.12); }
.form-row { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
@media(max-width:600px){ .form-row { grid-template-columns:1fr; } }

/* Topup amount buttons */
.amt-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:8px; margin-bottom:14px; }
.amt-btn { padding:14px 4px; background:var(--bg); border:1px solid var(--border); font-family:var(--font-display); font-size:10px; font-weight:700; color:var(--text-dim); cursor:pointer; transition:all var(--transition); letter-spacing:0.15em; }
.amt-btn:hover, .amt-btn.active { border-color:var(--cyan); color:var(--cyan); background:rgba(0,255,170,0.05); }
.amt-btn .num { display:block; font-size:14px; color:var(--yellow); margin-bottom:4px; letter-spacing:-0.01em; }

/* Payment method tiles */
.pmt-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:10px; margin-bottom:14px; }
.pmt-tile { padding:14px 12px; border:1px solid var(--border); cursor:pointer; transition:all var(--transition); background:var(--bg); }
.pmt-tile:hover, .pmt-tile.active { border-color:var(--cyan); background:rgba(0,255,170,0.05); }
.pmt-tile .name { font-family:var(--font-display); font-size:11px; font-weight:700; color:var(--text); letter-spacing:0.05em; }
.pmt-tile .num  { font-family:var(--font-display); font-size:10px; color:var(--muted); margin-top:4px; }
.pmt-tile .num.qris { color:var(--yellow); font-style:italic; }

/* Buttons (reuse shared .btn classes) */
.btn-danger { background:transparent; color:var(--danger); border-color:var(--danger); }
.btn-danger:hover { background:var(--danger); color:var(--bg); }
.btn-sm  { padding:6px 12px; font-size:10px; }
.btn-xs  { padding:4px 8px;  font-size:9px; }

/* Account list (akun) — card per record */
.acc-card { display:grid; grid-template-columns:auto 1fr auto; gap:18px; align-items:center; padding:14px; border:1px solid var(--border); background:var(--bg); margin-bottom:8px; }
.acc-card:hover { border-color:var(--cyan); }
.acc-card .acc-protocol { font-family:var(--font-display); font-size:10px; font-weight:700; padding:7px 9px; background:rgba(0,255,170,0.1); color:var(--cyan); letter-spacing:0.15em; }
.acc-card .acc-info .acc-name { font-family:var(--font-display); font-size:13px; font-weight:700; color:var(--text); margin-bottom:3px; }
.acc-card .acc-info .acc-meta { font-family:var(--font-display); font-size:10px; color:var(--muted); }
.acc-card .acc-actions { display:flex; gap:6px; }

/* Severity/danger zone */
.danger-zone { border:1px solid rgba(248,81,73,0.4); background:rgba(248,81,73,0.03); padding:18px; margin-top:24px; }
.danger-zone h4 { font-family:var(--font-display); font-size:11px; color:var(--danger); letter-spacing:0.25em; text-transform:uppercase; margin-bottom:8px; }
.danger-zone p  { font-size:0.85rem; color:var(--muted); margin-bottom:12px; line-height:1.5; }

/* Responsive */
@media(max-width: 980px) {
  .dash-layout { grid-template-columns:1fr; }
  .dash-side { position:static; height:auto; padding:14px 0; }
  .dash-main { padding:20px 18px; }
}
@media(max-width: 600px) {
  .stat-grid { grid-template-columns:1fr 1fr; }
  .amt-grid { grid-template-columns:repeat(2,1fr); }
  .acc-card { grid-template-columns:1fr; }
  .acc-card .acc-actions { justify-content:flex-start; }
}
</style>
</head>
<body>

<!-- ============================================================
     TOP NAV (shared style with landing)
     ============================================================ -->
<nav class="nav">
  <div class="nav-brand">
    <span class="prompt">&gt;_</span><span class="name"><?= htmlspecialchars($appName) ?></span>
    <span class="ver">v3.12.1 · DASHBOARD</span>
  </div>
  <div class="nav-actions">
    <span style="font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.2em; margin-right:10px; display:none;" class="role-badge">[ <?= htmlspecialchars(strtoupper($me['role'] ?? 'user')) ?> ]</span>
    <?php if ($isAdmin): ?>
      <a href="admin/" class="btn btn-sm" style="color:var(--yellow); border-color:var(--yellow);">[ Admin ]</a>
    <?php endif; ?>
    <a href="index.php?logout=1" class="btn btn-sm">[ Logout ]</a>
  </div>
</nav>

<div class="dash-layout">

  <!-- ============================================================
       SIDEBAR
       ============================================================ -->
  <aside class="dash-side">
    <div class="dash-side-user">
      <div class="who"><?= htmlspecialchars($me['username']) ?></div>
      <div class="email"><?= htmlspecialchars($me['email']) ?></div>
      <div class="saldo">
        <span class="saldo-label">[ Saldo ]</span>
        <span class="saldo-amt">Rp <?= number_format($saldo, 0, ',', '.') ?></span>
      </div>
    </div>
    <nav class="dash-side-nav">
      <a class="dash-nav-btn <?= $page==='home'?'active':'' ?>" href="?page=home"><span class="icn">::</span> Home</a>
      <a class="dash-nav-btn <?= $page==='akun'?'active':'' ?>" href="?page=akun"><span class="icn">[]</span> Akun VPN<?php if($counts['akun_active']>0): ?> <span class="badge-count"><?= $counts['akun_active'] ?></span><?php endif; ?></a>
      <a class="dash-nav-btn <?= $page==='traffic'?'active':'' ?>" href="?page=traffic"><span class="icn">~~</span> Traffic</a>
      <a class="dash-nav-btn <?= $page==='servers'?'active':'' ?>" href="?page=servers"><span class="icn">&gt;&gt;</span> Servers</a>
      <a class="dash-nav-btn <?= $page==='orders'?'active':'' ?>" href="?page=orders"><span class="icn">##</span> Orders<?php if($counts['orders']>0): ?> <span class="badge-count"><?= $counts['orders'] ?></span><?php endif; ?></a>
      <a class="dash-nav-btn <?= $page==='topup'?'active':'' ?>" href="?page=topup"><span class="icn">++</span> Topup<?php if($counts['topup_pending']>0): ?> <span class="badge-count" style="background:rgba(255,198,0,0.25);"><?= $counts['topup_pending'] ?></span><?php endif; ?></a>
      <a class="dash-nav-btn <?= $page==='settings'?'active':'' ?>" href="?page=settings"><span class="icn">~~</span> Settings</a>
    </nav>
    <div style="padding:20px 22px; margin-top:24px; border-top:1px dashed var(--border-dim);">
      <div style="font-family:var(--font-display); font-size:9px; color:var(--muted); letter-spacing:0.22em; text-transform:uppercase; margin-bottom:6px;">[ Build ]</div>
      <div style="font-family:var(--font-display); font-size:10px; color:var(--cyan);">v3.12.1 &middot; Youzin Crabz</div>
    </div>
  </aside>

  <!-- ============================================================
       MAIN
       ============================================================ -->
  <main class="dash-main">
    <div class="dash-eyebrow"><?= $pageEyebrow ?></div>
    <h1 class="dash-h1"><?= htmlspecialchars($pageTitle) ?>.</h1>

    <?php if ($flash['ok']): ?>
      <div class="flash flash-ok">[ OK ]&nbsp;&nbsp;<?= htmlspecialchars($flash['ok']) ?></div>
    <?php endif; ?>
    <?php if ($flash['err']): ?>
      <div class="flash flash-err">[ ERR ]&nbsp;<?= htmlspecialchars($flash['err']) ?></div>
    <?php endif; ?>

    <?php
    // ============================================================
    // [01] HOME — Overview stats + quick actions
    // ============================================================
    if ($page === 'home'):
      $recentOrders = [];
      if ($db) {
        try { $recentOrders = $db->query("SELECT t.*, s.name AS server_name FROM transactions t LEFT JOIN servers s ON s.id=t.server_id WHERE t.user_id={$uid} ORDER BY t.created_at DESC LIMIT 5")->fetchAll(); }
        catch (Exception $ex) {}
      }
      $expiringSoon = 0;
      if ($db) {
        try { $expiringSoon = (int)$db->query("SELECT COUNT(*) FROM vpn_accounts WHERE user_id={$uid} AND status='active' AND expiry_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)")->fetchColumn(); } catch (Exception $ex) {}
      }
    ?>
      <p class="dash-sub">Selamat datang kembali, <strong><?= htmlspecialchars($me['username']) ?></strong>. Panel kontrol akun tunnel kamu.</p>

      <div class="stat-grid">
        <div class="stat-box">
          <div class="label">[ Saldo ]</div>
          <div class="val yellow">Rp <?= number_format($saldo, 0, ',', '.') ?></div>
          <div class="subtitle">Saldo wallet aktif</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Akun Aktif ]</div>
          <div class="val cyan"><?= $counts['akun_active'] ?> <span style="font-size:11px; color:var(--muted); font-weight:400;">/ <?= $counts['akun_total'] ?></span></div>
          <div class="subtitle"><?= $expiringSoon ?> akan expire dalam 7 hari</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Orders ]</div>
          <div class="val"><?= $counts['orders'] ?></div>
          <div class="subtitle">Transaksi sukses</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Topup Pending ]</div>
          <div class="val"><?= $counts['topup_pending'] ?></div>
          <div class="subtitle">Menunggu approval admin</div>
        </div>
      </div>

      <h2 style="font-family:var(--font-display); font-size:11px; color:var(--cyan); letter-spacing:0.25em; text-transform:uppercase; margin-bottom:14px;">[ Quick Actions ]</h2>
      <div class="qa-grid">
        <a class="qa-card" href="?page=servers">
          <h3>Browse Servers</h3>
          <p>Lihat semua server yang tersedia dan pilih region untuk order.</p>
          <span class="arr">[ DEPLOY ] &rarr;</span>
        </a>
        <a class="qa-card" href="?page=topup">
          <h3>Topup Saldo</h3>
          <p>Tambah saldo wallet via Dana, GoPay, QRIS, atau bank transfer.</p>
          <span class="arr">[ TOPUP ] &rarr;</span>
        </a>
        <a class="qa-card" href="?page=akun">
          <h3>Akun VPN Saya</h3>
          <p>Lihat, renew, atau hapus akun tunnel aktif.</p>
          <span class="arr">[ MANAGE ] &rarr;</span>
        </a>
        <a class="qa-card" href="?page=traffic">
          <h3>Traffic Monitor</h3>
          <p>Monitor penggunaan bandwidth per akun dan per server.</p>
          <span class="arr">[ MONITOR ] &rarr;</span>
        </a>
      </div>

      <?php if (!empty($recentOrders)): ?>
      <div class="section-card">
        <div class="head"><h3>[ Recent Transactions ]</h3><a href="?page=orders" style="font-family:var(--font-display); font-size:10px; color:var(--cyan); text-decoration:none; letter-spacing:0.15em;">[ ALL &rarr; ]</a></div>
        <div class="body" style="padding:0;">
          <table class="data">
            <thead><tr>
              <th>ID</th><th>Type</th><th>Server</th><th>Amount</th><th>Status</th><th>Date</th>
            </tr></thead>
            <tbody>
            <?php foreach ($recentOrders as $o): ?>
              <tr>
                <td class="mono">#<?= (int)$o['id'] ?></td>
                <td><span class="pill <?= $o['type']==='order'?'pill-active':($o['type']==='topup'?'pill-online':'') ?>"><?= htmlspecialchars($o['type']) ?></span></td>
                <td><?= htmlspecialchars($o['server_name'] ?? '-') ?></td>
                <td class="mono">Rp <?= number_format((int)$o['amount'], 0, ',', '.') ?></td>
                <td><span class="pill <?= $o['status']==='success'?'pill-active':($o['status']==='pending'?'pill-pending':'pill-expired') ?>"><?= htmlspecialchars($o['status']) ?></span></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($o['created_at'] ?? '-') ?></td>
              </tr>
            <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      </div>
      <?php endif; ?>

    <?php
    // ============================================================
    // [02] AKUN — VPN account list with renew/delete + connection info
    // ============================================================
    elseif ($page === 'akun'):
      $accounts = [];
      if ($db) {
        try {
          $aq = $db->prepare("SELECT a.*, s.name AS server_name, s.region AS server_region, s.host AS server_host FROM vpn_accounts a LEFT JOIN servers s ON s.id=a.server_id WHERE a.user_id=? ORDER BY a.created_at DESC");
          $aq->execute([$uid]);
          $accounts = $aq->fetchAll();
        } catch (Exception $ex) {}
      }
    ?>
      <p class="dash-sub">Daftar lengkap akun tunnel kamu. Klik [+] untuk melihat detail koneksi, atau [RENEW] untuk perpanjang.</p>

      <?php if (empty($accounts)): ?>
        <div class="section-card"><div class="body" style="padding:48px; text-align:center; color:var(--muted); font-family:var(--font-display); font-size:12px; letter-spacing:0.15em;">
          [ BELUM ADA AKUN ]<br><br>
          <a href="?page=servers" class="btn btn-yellow" style="display:inline-block; width:auto; padding:12px 32px;">[ ORDER AKUN PERTAMA ]</a>
        </div></div>
      <?php else: ?>
        <?php foreach ($accounts as $a):
          $expired  = strtotime($a['expiry_date'] ?? '') < time();
          $daysLeft = max(0, (int)((strtotime($a['expiry_date'] ?? '') - time()) / 86400));
        ?>
          <div class="acc-card">
            <div class="acc-protocol"><?= htmlspecialchars(strtoupper($a['protocol'] ?? '?')) ?></div>
            <div class="acc-info">
              <div class="acc-name">#<?= (int)$a['id'] ?> &middot; <?= htmlspecialchars($a['username']) ?> <span style="color:var(--muted); font-weight:400;">&middot; <?= htmlspecialchars($a['server_region'] ?? $a['server_name'] ?? '-') ?></span></div>
              <div class="acc-meta">
                IP Limit: <?= (int)$a['ip_limit'] ?> &middot;
                <?php if ($expired): ?>
                  <span class="pill pill-expired">EXPIRED</span>
                <?php elseif ($daysLeft <= 7): ?>
                  Expires <?= $daysLeft ?> hari
                <?php else: ?>
                  Expires <?= date('d M Y', strtotime($a['expiry_date'])) ?>(<?= $daysLeft ?> hari)
                <?php endif; ?>
              </div>
            </div>
            <div class="acc-actions">
              <button type="button" class="btn btn-sm" onclick="toggleConn(<?= (int)$a['id'] ?>)">[+]</button>
              <form method="POST" style="display:inline;" onsubmit="return confirm('Hapus akun #<?= (int)$a['id'] ?>? Tindakan ini tidak dapat dibatalkan.');">
                <input type="hidden" name="action" value="delete_vpn_account">
                <input type="hidden" name="account_id" value="<?= (int)$a['id'] ?>">
                <?= csrfField() ?>
                <button type="submit" class="btn btn-sm btn-danger">[ DEL ]</button>
              </form>
              <form method="POST" style="display:inline;" onsubmit="return confirm('Perpanjang akun ini 30 hari dari saldo?');">
                <input type="hidden" name="action" value="renew_account">
                <input type="hidden" name="account_id" value="<?= (int)$a['id'] ?>">
                <input type="hidden" name="days" value="30">
                <?= csrfField() ?>
                <button type="submit" class="btn btn-sm">[ RENEW ]</button>
              </form>
            </div>
          </div>
          <div id="conn-<?= (int)$a['id'] ?>" style="display:none; margin-bottom:14px;">
            <div class="conn-card">
              <div class="kv"><span class="k">SERVER</span><span><?= htmlspecialchars($a['server_host'] ?? $a['server_name'] ?? '-') ?></span></div>
              <div class="kv"><span class="k">PROTOCOL</span><span><?= htmlspecialchars($a['protocol'] ?? '-') ?></span></div>
              <div class="kv"><span class="k">USERNAME</span><span><?= htmlspecialchars($a['username'] ?? '-') ?></span></div>
              <div class="kv"><span class="k">PASSWORD</span><span><?= htmlspecialchars($a['password'] ?? '-') ?></span></div>
              <div class="kv"><span class="k">IP_LIMIT</span><span><?= (int)$a['ip_limit'] ?></span></div>
              <div class="kv"><span class="k">EXPIRES</span><span><?= htmlspecialchars($a['expiry_date'] ?? '-') ?></span></div>
            </div>
          </div>
        <?php endforeach; ?>
      <?php endif; ?>

    <?php
    // ============================================================
    // [03] TRAFFIC — usage breakdown
    // ============================================================
    elseif ($page === 'traffic'):
      $traffic = [];
      if ($db) {
        try {
          $tq = $db->query("SELECT s.name, s.region, COUNT(a.id) AS accounts, SUM(a.bytes_in) AS bytes_in, SUM(a.bytes_out) AS bytes_out FROM servers s LEFT JOIN vpn_accounts a ON a.server_id=s.id WHERE a.user_id={$uid} GROUP BY s.id ORDER BY bytes_in DESC");
          $traffic = $tq->fetchAll();
        } catch (Exception $ex) {}
      }
      $totalIn  = array_sum(array_column($traffic, 'bytes_in'));
      $totalOut = array_sum(array_column($traffic, 'bytes_out'));
      $fmtBytes = function($b) {
        if ($b <= 0) return '0 B';
        $units = ['B','KB','MB','GB','TB'];
        $i = (int)floor(log($b, 1024));
        return round($b / pow(1024, $i), 2).' '.$units[min($i, 4)];
      };
      $maxBytes = max(1, (int)max(array_column($traffic, 'bytes_in') ?: [1]));
    ?>
      <p class="dash-sub">Akumulasi bandwidth masuk/keluar per server. Data diperbarui oleh vpn-keepalive service.</p>

      <?php if (empty($traffic)): ?>
        <div class="section-card"><div class="body" style="padding:48px; text-align:center; color:var(--muted); font-family:var(--font-display); font-size:11px; letter-spacing:0.2em;">
          [ BELUM ADA DATA TRAFFIC ]<br><br>
          Traffic akan tercatat setelah akun VPN kamu aktif dan ada koneksi masuk/keluar.
        </div></div>
      <?php else: ?>
        <div class="stat-grid">
          <div class="stat-box">
            <div class="label">[ Total IN ]</div>
            <div class="val cyan"><?= $fmtBytes($totalIn) ?></div>
            <div class="subtitle">Bandwidth masuk</div>
          </div>
          <div class="stat-box">
            <div class="label">[ Total OUT ]</div>
            <div class="val"><?= $fmtBytes($totalOut) ?></div>
            <div class="subtitle">Bandwidth keluar</div>
          </div>
          <div class="stat-box">
            <div class="label">[ Server Aktif ]</div>
            <div class="val yellow"><?= count($traffic) ?></div>
            <div class="subtitle">Server yang kamu pakai</div>
          </div>
        </div>

        <div class="section-card">
          <div class="head"><h3>[ Per-Server Breakdown ]</h3></div>
          <div class="body" style="padding:0;">
            <table class="data">
              <thead><tr>
                <th>Server</th><th>Region</th><th>Accounts</th><th>IN</th><th>OUT</th><th>%</th>
              </tr></thead>
              <tbody>
              <?php foreach ($traffic as $t): ?>
                <?php $pct = min(100, round(((int)($t['bytes_in'] ?? 0) / $maxBytes) * 100)); ?>
                <tr>
                  <td><?= htmlspecialchars($t['name'] ?? '-') ?></td>
                  <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['region'] ?? '-') ?></td>
                  <td class="mono"><?= (int)($t['accounts'] ?? 0) ?></td>
                  <td class="mono"><?= $fmtBytes((int)($t['bytes_in'] ?? 0)) ?></td>
                  <td class="mono"><?= $fmtBytes((int)($t['bytes_out'] ?? 0)) ?></td>
                  <td>
                    <div style="height:8px; background:var(--bg); border:1px solid var(--border); position:relative; overflow:hidden;">
                      <div style="position:absolute; left:0; top:0; bottom:0; width:<?= $pct ?>%; background:var(--cyan); transition:width 0.6s ease;"></div>
                    </div>
                    <span style="font-family:var(--font-display); font-size:10px; color:var(--muted);"><?= $pct ?>%</span>
                  </td>
                </tr>
              <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>
      <?php endif; ?>

    <?php
    // ============================================================
    // [04] SERVERS — browse all available servers + order form
    // ============================================================
    elseif ($page === 'servers'):
      $servers = [];
      if ($db) {
        try { $servers = $db->query("SELECT * FROM servers WHERE status='ready' ORDER BY monthly_price ASC")->fetchAll(); } catch (Exception $ex) {}
      }
      $order_server = (int)($_GET['server'] ?? 0);
    ?>
      <p class="dash-sub">Pilih server, protokol, dan durasi. Pembayaran dipotong otomatis dari saldo wallet.</p>

      <?php if (empty($servers)): ?>
        <div class="section-card"><div class="body" style="padding:48px; text-align:center; color:var(--muted);">Belum ada server yang tersedia. Hubungi admin.</div></div>
      <?php else: ?>
        <?php foreach ($servers as $s): ?>
          <div class="section-card">
            <div class="head">
              <h3>[ <?= htmlspecialchars($s['region'] ?? '?') ?> &middot; <?= htmlspecialchars($s['name']) ?> ]</h3>
              <span style="font-family:var(--font-display); font-size:14px; font-weight:700; color:var(--yellow);">Rp <?= number_format((int)$s['monthly_price'], 0, ',', '.') ?> <span style="font-size:10px; color:var(--muted); font-weight:400;">/bulan</span></span>
            </div>
            <div class="body">
              <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:8px; margin-bottom:14px; font-family:var(--font-display); font-size:10px; color:var(--muted);">
                <div>HOST  &middot; <?= htmlspecialchars($s['host'] ?? '-') ?></div>
                <div>LOAD  &middot; <?= htmlspecialchars((string)($s['load_pct'] ?? 'N/A')) ?></div>
                <div>LIMIT &middot; <?= (int)($s['max_accounts'] ?? 100) ?> akun</div>
                <div>STATUS &middot; <span class="pill pill-online">READY</span></div>
              </div>

              <form method="POST" style="background:var(--bg); border:1px dashed var(--border); padding:14px;">
                <input type="hidden" name="action" value="place_order">
                <?= csrfField() ?>
                <input type="hidden" name="server_id" value="<?= (int)$s['id'] ?>">
                <div class="form-row">
                  <div class="form-group">
                    <label>Protokol</label>
                    <select name="protocol" required>
                      <option value="ssh">SSH / OpenSSH</option>
                      <option value="vmess">VMess (WS + gRPC)</option>
                      <option value="vless">VLess (WS + gRPC)</option>
                      <option value="trojan">Trojan (WS + gRPC)</option>
                      <option value="udp-custom">UDP Custom</option>
                      <option value="zivpn-udp">ZIVPN UDP</option>
                    </select>
                  </div>
                  <div class="form-group">
                    <label>Durasi (hari)</label>
                    <input type="number" name="days" value="30" min="1" max="365" required>
                  </div>
                </div>
                <div class="form-row">
                  <div class="form-group">
                    <label>Promo Code (opsional)</label>
                    <input type="text" name="promo_code" placeholder="PROMO2025" maxlength="32">
                  </div>
                  <div class="form-group" style="display:flex; align-items:flex-end;">
                    <button type="submit" class="btn btn-yellow" data-confirm="Konfirmasi buat order akun baru di server pilihanmu?" style="width:100%;">[ DEPLOY SEKARANG ]</button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        <?php endforeach; ?>
      <?php endif; ?>

    <?php
    // ============================================================
    // [05] ORDERS — full transaction history
    // ============================================================
    elseif ($page === 'orders'):
      $txs = [];
      if ($db) {
        try {
          $tq = $db->prepare("SELECT t.*, s.name AS server_name FROM transactions t LEFT JOIN servers s ON s.id=t.server_id WHERE t.user_id=? ORDER BY t.created_at DESC LIMIT 100");
          $tq->execute([$uid]);
          $txs = $tq->fetchAll();
        } catch (Exception $ex) {}
      }
      $totalSpent = array_sum(array_column(array_filter($txs, fn($t) => ($t['type'] ?? '') === 'order'), 'amount'));
    ?>
      <p class="dash-sub">Seluruh transaksi order & renewal yang kamu lakukan. Total pembelanjaan: <strong style="color:var(--yellow);">Rp <?= number_format((int)$totalSpent, 0, ',', '.') ?></strong>.</p>

      <?php if (empty($txs)): ?>
        <div class="section-card"><div class="body" style="padding:48px; text-align:center; color:var(--muted);">Belum ada transaksi. <a href="?page=servers" style="color:var(--cyan);">Order sekarang</a>.</div></div>
      <?php else: ?>
        <div class="table-wrap">
          <table class="data">
            <thead><tr>
              <th>ID</th><th>Tanggal</th><th>Type</th><th>Server</th><th>Method</th><th>Amount</th><th>Status</th>
            </tr></thead>
            <tbody>
            <?php foreach ($txs as $t): ?>
              <tr>
                <td class="mono">#<?= (int)$t['id'] ?></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['created_at'] ?? '-') ?></td>
                <td><span class="pill <?= $t['type']==='order'?'pill-protocol':($t['type']==='renew'?'pill-online':($t['type']==='topup'?'pill-active':'')) ?>"><?= htmlspecialchars($t['type']) ?></span></td>
                <td><?= htmlspecialchars($t['server_name'] ?? '-') ?></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['method'] ?? ($t['type']==='order' || $t['type']==='renew' ? 'saldo' : '-')) ?></td>
                <td class="mono">Rp <?= number_format((int)$t['amount'], 0, ',', '.') ?></td>
                <td><span class="pill <?= $t['status']==='success'?'pill-active':($t['status']==='pending'?'pill-pending':'pill-expired') ?>"><?= htmlspecialchars($t['status']) ?></span></td>
              </tr>
            <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      <?php endif; ?>

    <?php
    // ============================================================
    // [06] TOPUP — request saldo topup via manual payment
    // ============================================================
    elseif ($page === 'topup'):
      $pending = [];
      if ($db) {
        try {
          $pq = $db->prepare("SELECT * FROM topup_requests WHERE user_id=? ORDER BY created_at DESC LIMIT 10");
          $pq->execute([$uid]);
          $pending = $pq->fetchAll();
        } catch (Exception $ex) {}
      }
      $dana  = getSetting('dana_number', '');
      $gopay = getSetting('gopay_number', '');
      $ovo   = getSetting('ovo_number', '');
      $qris  = getSetting('qris_image', '');
    ?>
      <p class="dash-sub">Tambah saldo wallet. Pilih nominal, transfer ke salah satu metode, lalu upload bukti di sini. Admin akan approve manual.</p>

      <div class="section-card">
        <div class="head"><h3>[ Nominal ]</h3></div>
        <div class="body">
          <div class="amt-grid">
            <button type="button" class="amt-btn" data-amt="10000" onclick="setAmt(this)"><span class="num">10K</span>Percobaan</button>
            <button type="button" class="amt-btn" data-amt="25000" onclick="setAmt(this)"><span class="num">25K</span>1 Bulan</button>
            <button type="button" class="amt-btn active" data-amt="50000" onclick="setAmt(this)"><span class="num">50K</span>2 Bulan</button>
            <button type="button" class="amt-btn" data-amt="100000" onclick="setAmt(this)"><span class="num">100K</span>4 Bulan</button>
          </div>
          <form method="POST" enctype="multipart/form-data">
            <input type="hidden" name="action" value="topup_request">
            <?= csrfField() ?>
            <div class="form-row">
              <div class="form-group">
                <label>Nominal (Rp)</label>
                <input type="number" name="amount" id="amtField" value="50000" min="5000" max="10000000" required>
              </div>
              <div class="form-group">
                <label>Metode Pembayaran</label>
                <select name="method" id="methodField" required>
                  <option value="dana">DANA</option>
                  <option value="gopay">GoPay</option>
                  <option value="ovo">OVO</option>
                  <option value="shopeepay">ShopeePay</option>
                  <option value="qris">QRIS</option>
                  <option value="bank_transfer">Bank Transfer</option>
                </select>
              </div>
            </div>

            <h4 style="font-family:var(--font-display); font-size:10px; color:var(--cyan); letter-spacing:0.22em; text-transform:uppercase; margin:18px 0 10px;">[ Nomor Tujuan ]</h4>
            <div class="pmt-grid">
              <?php if ($dana):  ?><div class="pmt-tile" data-method="dana" onclick="selectMethod(this)"><div class="name">DANA</div><div class="num"><?= htmlspecialchars($dana) ?></div></div><?php endif; ?>
              <?php if ($gopay): ?><div class="pmt-tile" data-method="gopay" onclick="selectMethod(this)"><div class="name">GoPay</div><div class="num"><?= htmlspecialchars($gopay) ?></div></div><?php endif; ?>
              <?php if ($ovo):   ?><div class="pmt-tile" data-method="ovo" onclick="selectMethod(this)"><div class="name">OVO</div><div class="num"><?= htmlspecialchars($ovo) ?></div></div><?php endif; ?>
              <?php if ($qris):  ?><div class="pmt-tile" data-method="qris" onclick="selectMethod(this)"><div class="name">QRIS</div><div class="num qris">[ SCAN QR ]</div></div><?php endif; ?>
              <div class="pmt-tile" data-method="bank_transfer" onclick="selectMethod(this)"><div class="name">BANK</div><div class="num">[ Hubungi Admin ]</div></div>
            </div>

            <div class="form-group">
              <label>Bukti Transfer (JPG/PNG/WebP, max 5MB)</label>
              <input type="file" name="proof" accept="image/jpeg,image/png,image/webp" required>
            </div>

            <button type="submit" class="btn btn-yellow" style="width:100%; padding:14px; font-size:13px;" onclick="return confirm('Konfirmasi submit permintaan topup?')">[ SUBMIT TOPUP REQUEST ]</button>
          </form>
        </div>
      </div>

      <?php if (!empty($pending)): ?>
      <div class="section-card">
        <div class="head"><h3>[ Topup History ]</h3></div>
        <div class="body" style="padding:0;">
          <table class="data">
            <thead><tr><th>ID</th><th>Tanggal</th><th>Amount</th><th>Method</th><th>Status</th><th>Bukti</th></tr></thead>
            <tbody>
            <?php foreach ($pending as $p): ?>
              <tr>
                <td class="mono">#<?= (int)$p['id'] ?></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($p['created_at'] ?? '-') ?></td>
                <td class="mono">Rp <?= number_format((int)$p['amount'], 0, ',', '.') ?></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($p['method']) ?></td>
                <td><span class="pill <?= $p['status']==='approved'?'pill-active':($p['status']==='pending'?'pill-pending':'pill-expired') ?>"><?= htmlspecialchars($p['status']) ?></span></td>
                <td><?php if (!empty($p['proof_image'])): ?><a href="<?= htmlspecialchars($p['proof_image']) ?>" target="_blank" style="color:var(--cyan); font-family:var(--font-display); font-size:10px; letter-spacing:0.15em;">[ VIEW IMG ]</a><?php endif; ?></td>
              </tr>
            <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      </div>
      <?php endif; ?>

      <script>
        function setAmt(btn) {
          document.querySelectorAll('.amt-btn').forEach(function(b){ b.classList.remove('active'); });
          btn.classList.add('active');
          document.getElementById('amtField').value = btn.dataset.amt;
        }
        function selectMethod(tile) {
          document.querySelectorAll('.pmt-tile').forEach(function(t){ t.classList.remove('active'); });
          tile.classList.add('active');
          document.getElementById('methodField').value = tile.dataset.method;
        }
        // Pre-select first available payment method
        document.addEventListener('DOMContentLoaded', function() {
          var first = document.querySelector('.pmt-tile');
          if (first) selectMethod(first);
        });
      </script>

    <?php
    // ============================================================
    // [07] SETTINGS — profile + password + danger zone
    // ============================================================
    elseif ($page === 'settings'):
    ?>
      <p class="dash-sub">Profil akun, keamanan, dan koneksi Telegram bot.</p>

      <div class="section-card">
        <div class="head"><h3>[ Profil ]</h3></div>
        <div class="body">
          <div class="form-row">
            <div class="form-group">
              <label>Username</label>
              <input type="text" value="<?= htmlspecialchars($me['username']) ?>" readonly style="opacity:0.6; cursor:not-allowed;">
            </div>
            <div class="form-group">
              <label>Email</label>
              <input type="email" value="<?= htmlspecialchars($me['email']) ?>" readonly style="opacity:0.6; cursor:not-allowed;">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Role</label>
              <input type="text" value="<?= htmlspecialchars(strtoupper($me['role'] ?? 'user')) ?>" readonly style="opacity:0.6; cursor:not-allowed;">
            </div>
            <div class="form-group">
              <label>Saldo</label>
              <input type="text" value="Rp <?= number_format($saldo, 0, ',', '.') ?>" readonly style="opacity:0.6; cursor:not-allowed;">
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>IP Terakhir (login)</label>
              <input type="text" value="<?= htmlspecialchars($me['ip_address'] ?? '-') ?>" readonly style="opacity:0.6; cursor:not-allowed;">
            </div>
            <div class="form-group">
              <label>Tanggal Daftar</label>
              <input type="text" value="<?= htmlspecialchars($me['created_at'] ?? '-') ?>" readonly style="opacity:0.6; cursor:not-allowed;">
            </div>
          </div>
        </div>
      </div>

      <div class="section-card">
        <div class="head"><h3>[ Ganti Password ]</h3></div>
        <div class="body">
          <form method="POST">
            <input type="hidden" name="action" value="change_password">
            <?= csrfField() ?>
            <div class="form-group">
              <label>Password Saat Ini</label>
              <input type="password" name="current_password" required autocomplete="current-password">
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Password Baru</label>
                <input type="password" name="new_password" required minlength="6" autocomplete="new-password">
              </div>
              <div class="form-group">
                <label>Konfirmasi</label>
                <input type="password" name="confirm_password" required minlength="6" autocomplete="new-password">
              </div>
            </div>
            <button type="submit" class="btn btn-primary">[ UPDATE PASSWORD ]</button>
          </form>
        </div>
      </div>

      <div class="danger-zone">
        <h4>[ Danger Zone ]</h4>
        <p>Menghapus akun akan menghapus semua data terkait: akun VPN, transaksi, dan topup request. Tindakan ini tidak dapat dibatalkan.</p>
        <form method="POST" onsubmit="return confirm('PERMANENT. Ketik username konfirmasi untuk lanjut.');">
          <input type="hidden" name="action" value="delete_account">
          <?= csrfField() ?>
          <div class="form-row">
            <div class="form-group">
              <label>Ketik username untuk konfirmasi: <strong><?= htmlspecialchars($me['username']) ?></strong></label>
              <input type="text" name="confirm_username" placeholder="<?= htmlspecialchars($me['username']) ?>" required>
            </div>
            <div class="form-group" style="display:flex; align-items:flex-end;">
              <button type="submit" class="btn btn-danger" style="background:var(--danger); color:var(--bg); border-color:var(--danger); width:100%;">[ DELETE AKUN PERMANENT ]</button>
            </div>
          </div>
        </form>
      </div>

    <?php endif; ?>

  </main>
</div>

<script>
// Toggle account connection details card
function toggleConn(id) {
  var el = document.getElementById('conn-' + id);
  if (el) el.style.display = (el.style.display === 'none' || !el.style.display) ? 'block' : 'none';
}
// Logout confirmation for nav link
// Universal data-confirm handler — safe from server-data interpolation
document.querySelectorAll('[data-confirm]').forEach(function(el){
  el.addEventListener('click', function(e){
    if (!confirm(el.dataset.confirm)) e.preventDefault();
  });
});

// Logout confirmation for nav link
// Universal data-confirm handler — safe from server-data interpolation
document.querySelectorAll('[data-confirm]').forEach(function(el){
  el.addEventListener('click', function(e){
    if (!confirm(el.dataset.confirm)) e.preventDefault();
  });
});

// Logout confirmation for nav link
document.querySelector('a[href="index.php?logout=1"]')?.addEventListener('click', function(e) {
  if (!confirm('Logout dari sesi dashboard?')) e.preventDefault();
});
</script>
</body>
</html>
