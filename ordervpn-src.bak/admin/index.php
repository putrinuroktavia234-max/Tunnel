<?php
// ============================================================
// OrderVPN — Admin Panel (single file, ?page=X SPA)
// Midnight Console theme. Hanya role=admin yang boleh akses.
// Actions: approve_topup, reject_topup, toggle_user, add_server,
//          toggle_server, delete_server, save_settings, add_promo,
//          delete_promo, force_delete_account.
// ============================================================
require_once __DIR__.'/../includes/config.php';
if (session_status() === PHP_SESSION_NONE) session_start();
$ctx   = requireAdmin(); // 403 jika bukan admin
$db    = getDB();
$aid   = (int)$ctx['user_id'];
$appName = getSetting('app_name', 'OrderVPN');

$page = $_GET['page'] ?? 'home';
$valid = ['home','topup_pending','users','servers','transactions','promos','settings'];
if (!in_array($page, $valid, true)) $page = 'home';

$flash = ['ok' => '', 'err' => ''];

// ====== ADMIN ACTION HANDLERS ======
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // ----- APPROVE TOPUP -----
    if ($action === 'approve_topup') {
        $tid  = (int)($_POST['topup_id'] ?? 0);
        $note = sanitize($_POST['admin_note'] ?? '');
        $tq   = $db->prepare("SELECT * FROM topup_requests WHERE id=? AND status='pending' LIMIT 1");
        $tq->execute([$tid]);
        $tr   = $tq->fetch();
        if (!$tr) { $flash['err'] = 'Topup request tidak ditemukan atau sudah diproses.'; }
        else {
            try {
                $db->beginTransaction();
                $db->prepare("UPDATE topup_requests SET status='approved', admin_note=?, processed_at=NOW() WHERE id=?")
                   ->execute([$note, $tid]);
                $db->prepare("UPDATE users SET saldo = saldo + ? WHERE id=?")
                   ->execute([(int)$tr['amount'], (int)$tr['user_id']]);
                $db->prepare("INSERT INTO transactions (user_id, type, amount, method, status, created_at) VALUES (?,?,?,?,?, NOW())")
                   ->execute([(int)$tr['user_id'], 'topup', (int)$tr['amount'], $tr['method'], 'success']);
                $db->commit();
                $flash['ok'] = 'Topup #' . $tid . ' approved. Saldo user +Rp ' . number_format((int)$tr['amount']) . '.';
            } catch (Exception $ex) { $db->rollBack(); $flash['err'] = 'Gagal approve: ' . $ex->getMessage(); }
        }
        $page = 'topup_pending';
    }

    // ----- REJECT TOPUP -----
    if ($action === 'reject_topup') {
        $tid  = (int)($_POST['topup_id'] ?? 0);
        $note = sanitize($_POST['admin_note'] ?? '');
        $db->prepare("UPDATE topup_requests SET status='rejected', admin_note=?, processed_at=NOW() WHERE id=? AND status='pending'")
           ->execute([$note, $tid]);
        $flash['ok'] = 'Topup #' . $tid . ' rejected.';
        $page = 'topup_pending';
    }

    // ----- TOGGLE USER (suspend/activate via is_verified flip + audit note) -----
    if ($action === 'toggle_user') {
        $uid  = (int)($_POST['user_id'] ?? 0);
        $mode = $_POST['mode'] ?? ''; // 'suspend' or 'activate'
        $note = sanitize($_POST['admin_note'] ?? '');
        $newVerified = ($mode === 'activate') ? 1 : 0;
        $db->prepare("UPDATE users SET is_verified=?, role=IF(?=1,role,'user') WHERE id=?")
           ->execute([$newVerified, $newVerified, $uid]);
        $flash['ok'] = 'User #' . $uid . ' di-' . ($mode === 'activate' ? 'activate' : 'suspend') . '.';
        $page = 'users';
    }

    // ----- FORCE DELETE USER -----
    if ($action === 'force_delete_user') {
        $uid  = (int)($_POST['user_id'] ?? 0);
        $confirm = sanitize($_POST['confirm_username'] ?? '');
        $uq = $db->prepare("SELECT username FROM users WHERE id=?");
        $uq->execute([$uid]);
        $u = $uq->fetch();
        if (!$u || $confirm !== $u['username']) {
            $flash['err'] = 'Username konfirmasi tidak cocok.';
        } else {
            try {
                $db->beginTransaction();
                $db->prepare("DELETE FROM vpn_accounts    WHERE user_id=?")->execute([$uid]);
                $db->prepare("DELETE FROM topup_requests  WHERE user_id=?")->execute([$uid]);
                $db->prepare("DELETE FROM transactions    WHERE user_id=?")->execute([$uid]);
                $db->prepare("DELETE FROM users           WHERE id=?")->execute([$uid]);
                $db->commit();
                $flash['ok'] = 'User #' . $uid . ' (' . htmlspecialchars($u['username']) . ') dihapus permanen.';
            } catch (Exception $ex) { $db->rollBack(); $flash['err'] = 'Gagal hapus: ' . $ex->getMessage(); }
        }
        $page = 'users';
    }

    // ----- ADD SERVER -----
    if ($action === 'add_server') {
        $name   = sanitize($_POST['name'] ?? '');
        $region = sanitize($_POST['region'] ?? '');
        $host   = sanitize($_POST['host'] ?? '');
        $price  = (int)($_POST['monthly_price'] ?? 10000);
        $maxAcc = (int)($_POST['max_accounts'] ?? 100);
        $status = 'ready';
        if ($name === '' || $region === '' || $host === '') {
            $flash['err'] = 'Nama, region, dan host wajib diisi.';
        } elseif ($price < 1000 || $price > 1000000) {
            $flash['err'] = 'Harga bulanan harus 1000-1000000.';
        } else {
            try {
                $db->prepare("INSERT INTO servers (name, region, host, monthly_price, max_accounts, status, created_at) VALUES (?,?,?,?,?,?, NOW())")
                   ->execute([$name, $region, $host, $price, $maxAcc, $status]);
                $flash['ok'] = 'Server ' . $name . ' ditambahkan.';
            } catch (Exception $ex) { $flash['err'] = 'Gagal tambah server: ' . $ex->getMessage(); }
        }
        $page = 'servers';
    }

    // ----- TOGGLE SERVER -----
    if ($action === 'toggle_server') {
        $sid = (int)($_POST['server_id'] ?? 0);
        $sq  = $db->prepare("SELECT status FROM servers WHERE id=?");
        $sq->execute([$sid]);
        $srv = $sq->fetch();
        if (!$srv) { $flash['err'] = 'Server tidak ditemukan.'; }
        else {
            $ns = ($srv['status'] === 'ready') ? 'disabled' : 'ready';
            $db->prepare("UPDATE servers SET status=? WHERE id=?")->execute([$ns, $sid]);
            $flash['ok'] = 'Server #' . $sid . ' di-toggle ke ' . $ns . '.';
        }
        $page = 'servers';
    }

    // ----- DELETE SERVER -----
    if ($action === 'delete_server') {
        $sid = (int)($_POST['server_id'] ?? 0);
        $cnt = (int)$db->query("SELECT COUNT(*) FROM vpn_accounts WHERE server_id={$sid}")->fetchColumn();
        if ($cnt > 0) {
            $flash['err'] = 'Tidak bisa hapus: server masih punya ' . $cnt . ' akun aktif. Disable dulu.';
        } else {
            $db->prepare("DELETE FROM servers WHERE id=?")->execute([$sid]);
            $flash['ok'] = 'Server #' . $sid . ' dihapus.';
        }
        $page = 'servers';
    }

    // ----- SAVE SETTINGS -----
    // NOTE: writes to `settings` table (NOT `app_settings`) because config.php's
    //       getSetting() reads from `settings` — landing/dashboard pull values
    //       through that helper. Mismatched table means settings never surface.
    if ($action === 'save_settings') {
        $keys = [
            'app_name','contact_wa','contact_tg','contact_ig',
            'dana_number','gopay_number','shopee_number','ovo_number',
            'bank_name','bank_account','bank_holder','qris_image',
            'announce_1','announce_2','announce_3',
        ];
        try {
            $db->beginTransaction();
            foreach ($keys as $k) {
                $v = sanitize($_POST[$k] ?? '');
                // Explicit SELECT → UPDATE-or-INSERT (safe without UNIQUE INDEX assumption)
                $sel = $db->prepare("SELECT `key` FROM settings WHERE `key`=? LIMIT 1");
                $sel->execute([$k]);
                if ($sel->fetch()) {
                    $db->prepare("UPDATE settings SET `value`=? WHERE `key`=?")->execute([$v, $k]);
                } else {
                    $db->prepare("INSERT INTO settings (`key`,`value`) VALUES (?,?)")->execute([$k, $v]);
                }
            }
            $db->commit();
            $flash['ok'] = 'Pengaturan disimpan. Pengumuman akan tampil di landing.';
        } catch (Exception $ex) { $db->rollBack(); $flash['err'] = 'Gagal simpan: ' . $ex->getMessage(); }
        $page = 'settings';
    }

    // ----- ADD PROMO -----
    if ($action === 'add_promo') {
        $code      = strtoupper(sanitize($_POST['code'] ?? ''));
        $discount  = (int)($_POST['discount'] ?? 0);
        $max_uses  = (int)($_POST['max_uses'] ?? 0);
        $expires   = $_POST['expires'] ?? null;
        if ($code === '' || $discount < 1 || $discount > 100) {
            $flash['err'] = 'Code wajib diisi, diskon 1-100%.';
        } else {
            try {
                $db->prepare("INSERT INTO promo_codes (code, discount, max_uses, used_count, expires, created_at) VALUES (?,?,?,0,?, NOW())")
                   ->execute([$code, $discount, $max_uses ?: null, $expires ?: null]);
                $flash['ok'] = 'Promo ' . $code . ' dibuat (diskon ' . $discount . '%).';
            } catch (Exception $ex) { $flash['err'] = 'Gagal: ' . $ex->getMessage(); }
        }
        $page = 'promos';
    }

    // ----- DELETE PROMO -----
    if ($action === 'delete_promo') {
        $pid = (int)($_POST['promo_id'] ?? 0);
        $db->prepare("DELETE FROM promo_codes WHERE id=?")->execute([$pid]);
        $flash['ok'] = 'Promo #' . $pid . ' dihapus.';
        $page = 'promos';
    }
}

// ====== COUNTS FOR SIDEBAR ======
$counts = [
    'pending_topup' => 0,
    'pending_users' => 0,
    'servers_ready' => 0,
    'servers_off'   => 0,
];
if ($db) {
    try {
        $counts['pending_topup'] = (int)$db->query("SELECT COUNT(*) FROM topup_requests WHERE status='pending'")->fetchColumn();
        $counts['pending_users'] = (int)$db->query("SELECT COUNT(*) FROM users WHERE is_verified=0")->fetchColumn();
        $counts['servers_ready'] = (int)$db->query("SELECT COUNT(*) FROM servers WHERE status='ready'")->fetchColumn();
        $counts['servers_off']   = (int)$db->query("SELECT COUNT(*) FROM servers WHERE status='disabled' OR status<>'ready'")->fetchColumn();
    } catch (Exception $ex) { /* tables may not exist yet */ }
}

$titles = [
    'home'           => 'Admin Overview',
    'topup_pending'  => 'Topup Approval',
    'users'          => 'Manajemen User',
    'servers'        => 'Manajemen Server',
    'transactions'   => 'Semua Transaksi',
    'promos'         => 'Promo Codes',
    'settings'       => 'App Settings',
];
$pageTitle = $titles[$page];

$pageEyebrow = "[ ADMIN // " . strtoupper($page) . " ]";
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($pageTitle) ?> · Admin · <?= htmlspecialchars($appName) ?></title>
<link rel="stylesheet" href="../assets/ordervpn.css?v=3.12.1">
<style>
/* ============================================================
   ADMIN-SPECIFIC (extends shared tokens from ordervpn.css)
   Yellow accent variants for admin-only actions
   ============================================================ */
:root {
  --admin-glow: rgba(255, 198, 0, 0.4);
  --admin-border: rgba(255, 198, 0, 0.25);
}
.admin-layout { display:grid; grid-template-columns:240px 1fr; min-height:calc(100vh - 60px); }
.admin-side   { background:var(--bg-elev); border-right:1px solid var(--admin-border); padding:20px 0; position:sticky; top:60px; height:calc(100vh - 60px); overflow-y:auto; }
.admin-side-user { padding:0 22px 16px; margin-bottom:8px; border-bottom:1px solid var(--admin-border); }
.admin-side-user .label { font-family:var(--font-display); font-size:9px; color:var(--yellow); letter-spacing:0.28em; text-transform:uppercase; margin-bottom:4px; }
.admin-side-user .who   { font-family:var(--font-display); font-size:14px; font-weight:700; color:var(--text); }
.admin-side-user .sub   { font-family:var(--font-display); font-size:10px; color:var(--muted); margin-top:3px; }
.admin-nav { display:flex; flex-direction:column; gap:1px; padding:0 10px; margin-top:14px; }
.admin-nav-btn { display:flex; align-items:center; gap:10px; padding:9px 12px; border:none; border-left:2px solid transparent; background:transparent; color:var(--text-dim); font-family:var(--font-display); font-size:11px; font-weight:700; letter-spacing:0.18em; text-transform:uppercase; cursor:pointer; text-align:left; text-decoration:none; transition:background var(--transition), color var(--transition), border-color var(--transition); }
.admin-nav-btn:hover { background:rgba(255,198,0,0.06); color:var(--text); }
.admin-nav-btn.active { background:rgba(255,198,0,0.1); color:var(--yellow); border-left-color:var(--yellow); padding-left:10px; }
.admin-nav-btn .icn { font-family:var(--font-display); font-size:13px; min-width:14px; color:var(--yellow); }
.admin-nav-btn .badge-count { margin-left:auto; background:rgba(255,198,0,0.2); color:var(--yellow); font-size:9px; padding:2px 6px; font-weight:700; }
.admin-nav-btn .badge-warn { margin-left:auto; background:rgba(239,68,68,0.18); color:var(--danger); font-size:9px; padding:2px 6px; }
.admin-main { padding:32px 40px; max-width:1280px; }
.admin-eyebrow { font-family:var(--font-display); font-size:11px; color:var(--yellow); letter-spacing:0.3em; text-transform:uppercase; margin-bottom:10px; }
.admin-h1 { font-family:var(--font-display); font-size:1.7rem; font-weight:700; letter-spacing:-0.025em; line-height:1.15; margin-bottom:6px; }
.admin-sub { color:var(--muted); margin-bottom:28px; font-size:0.92rem; }
.flash { padding:14px 16px; border-left:3px solid; font-family:var(--font-display); font-size:12px; margin-bottom:24px; letter-spacing:0.05em; }
.flash-ok  { border-color:var(--success); background:rgba(63,185,80,0.08); color:#7be899; }
.flash-err { border-color:var(--danger);  background:rgba(248,81,73,0.08); color:#ff8a82; }
@keyframes fadeSlide { from{opacity:0;transform:translateY(-6px)} to{opacity:1;transform:translateY(0)} }

/* Stat grid */
.stat-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:1px; background:var(--admin-border); border:1px solid var(--border); margin-bottom:32px; }
.stat-box { background:var(--bg); padding:20px 22px; }
.stat-box .label { font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.28em; text-transform:uppercase; }
.stat-box .val { font-family:var(--font-display); font-size:1.7rem; font-weight:700; letter-spacing:-0.02em; margin-top:6px; }
.stat-box .val.cyan   { color:var(--cyan); }
.stat-box .val.yellow { color:var(--yellow); }
.stat-box .val.danger { color:var(--danger); }
.stat-box .sub { font-size:0.78rem; color:var(--muted); margin-top:4px; }

/* Section card */
.section-card { background:var(--bg-elev); border:1px solid var(--border); margin-bottom:22px; }
.section-card .head { padding:14px 18px; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap; }
.section-card .head h3 { font-family:var(--font-display); font-size:11px; color:var(--cyan); letter-spacing:0.25em; text-transform:uppercase; }
.section-card .body { padding:18px; }
.section-card .body.tight { padding:0; }

/* Tables */
.table-wrap { background:var(--bg-elev); border:1px solid var(--border); overflow-x:auto; margin-bottom:22px; }
table.data { width:100%; border-collapse:collapse; font-size:0.88rem; }
table.data th { text-align:left; padding:11px 14px; font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.22em; text-transform:uppercase; border-bottom:1px solid var(--border); white-space:nowrap; }
table.data td { padding:13px 14px; border-bottom:1px solid var(--border-dim); color:var(--text-dim); vertical-align:middle; }
table.data tr:last-child td { border-bottom:none; }
table.data tr:hover td { background:rgba(255,198,0,0.03); }
table.data td.mono { font-family:var(--font-display); font-size:11px; color:var(--text); }
table.data td .row-actions { display:flex; gap:6px; flex-wrap:wrap; }
table.data td.actions-cell { white-space:nowrap; }

/* Pills */
.pill { display:inline-block; padding:3px 9px; font-family:var(--font-display); font-size:9px; font-weight:700; letter-spacing:0.2em; text-transform:uppercase; }
.pill-active   { background:rgba(63,185,80,0.15) ; color:var(--success); }
.pill-expired  { background:rgba(248,81,73,0.12) ; color:var(--danger);  }
.pill-pending  { background:rgba(255,198,0,0.15) ; color:var(--yellow);  }
.pill-disabled { background:rgba(100,116,139,0.15); color:var(--muted);   }
.pill-admin    { background:rgba(255,198,0,0.18) ; color:var(--yellow);  }
.pill-user     { background:rgba(99,102,241,0.18) ; color:#9aa6ff;        }

/* Forms */
.form-group { margin-bottom:14px; }
.form-group label { display:block; font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.2em; text-transform:uppercase; margin-bottom:6px; }
.form-group input[type=text], .form-group input[type=email], .form-group input[type=number], .form-group input[type=date], .form-group select, .form-group textarea {
  width:100%; padding:10px 12px; background:var(--bg); border:1px solid var(--border); color:var(--text); font-family:var(--font-body); font-size:0.92rem;
}
.form-group input:focus, .form-group select:focus, .form-group textarea:focus { outline:none; border-color:var(--yellow); box-shadow:0 0 0 3px rgba(255,198,0,0.12); }
.form-row { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.form-row.three { grid-template-columns:1fr 1fr 1fr; }
@media(max-width:700px){ .form-row, .form-row.three { grid-template-columns:1fr; } }

/* Buttons */
.btn-danger         { background:transparent; color:var(--danger); border-color:var(--danger); }
.btn-danger:hover   { background:var(--danger); color:var(--bg); }
.btn-warn           { background:transparent; color:var(--yellow); border-color:var(--yellow); }
.btn-warn:hover     { background:var(--yellow); color:var(--bg); }
.btn-success        { background:var(--success); color:var(--bg); border-color:var(--success); }
.btn-success:hover  { background:transparent; color:var(--success); }
.btn-sm             { padding:6px 12px; font-size:10px; }
.btn-xs             { padding:4px 8px;  font-size:9px; }

/* Approve/Reject inline forms */
.inline-action { display:grid; grid-template-columns:1fr auto auto; gap:6px; align-items:center; }
.inline-action input[type=text] { padding:6px 10px; font-size:11px; }

/* Modal preview (proof image) */
.proof-thumb { max-width:60px; max-height:60px; border:1px solid var(--border); cursor:pointer; transition:all var(--transition); }
.proof-thumb:hover { border-color:var(--yellow); transform:scale(1.05); }

/* Responsive */
@media(max-width: 980px) {
  .admin-layout { grid-template-columns:1fr; }
  .admin-side { position:static; height:auto; padding:14px 0; }
  .admin-main { padding:20px 18px; }
}
@media(max-width: 600px) {
  .stat-grid { grid-template-columns:1fr 1fr; }
  .inline-action { grid-template-columns:1fr; }
}
</style>
</head>
<body>

<nav class="nav">
  <div class="nav-brand">
    <span class="prompt">&gt;_</span><span class="name"><?= htmlspecialchars($appName) ?></span>
    <span class="ver" style="color:var(--yellow);">v3.12.1 · ADMIN</span>
  </div>
  <div class="nav-actions">
    <a href="../dashboard.php" class="btn btn-sm">[ Dashboard ]</a>
    <a href="../index.php?logout=1" class="btn btn-sm btn-warn">[ Logout ]</a>
  </div>
</nav>

<div class="admin-layout">

  <aside class="admin-side">
    <div class="admin-side-user">
      <div class="label">[ Admin ]</div>
      <div class="who"><?= htmlspecialchars($ctx['username'] ?? '-') ?></div>
      <div class="sub">Session ID #<?= (int)$aid ?></div>
    </div>
    <nav class="admin-nav">
      <a class="admin-nav-btn <?= $page==='home'?'active':'' ?>" href="?page=home"><span class="icn">::</span> Overview</a>
      <a class="admin-nav-btn <?= $page==='topup_pending'?'active':'' ?>" href="?page=topup_pending"><span class="icn">$$</span> Topup Approval<?php if($counts['pending_topup']>0): ?> <span class="badge-warn"><?= $counts['pending_topup'] ?></span><?php endif; ?></a>
      <a class="admin-nav-btn <?= $page==='users'?'active':'' ?>" href="?page=users"><span class="icn">##</span> Users<?php if($counts['pending_users']>0): ?> <span class="badge-count"><?= $counts['pending_users'] ?></span><?php endif; ?></a>
      <a class="admin-nav-btn <?= $page==='servers'?'active':'' ?>" href="?page=servers"><span class="icn">&gt;&gt;</span> Servers<?php if($counts['servers_off']>0): ?> <span class="badge-warn"><?= $counts['servers_off'] ?> OFF</span><?php endif; ?></a>
      <a class="admin-nav-btn <?= $page==='transactions'?'active':'' ?>" href="?page=transactions"><span class="icn">##</span> Transactions</a>
      <a class="admin-nav-btn <?= $page==='promos'?'active':'' ?>" href="?page=promos"><span class="icn">%%</span> Promo Codes</a>
      <a class="admin-nav-btn <?= $page==='settings'?'active':'' ?>" href="?page=settings"><span class="icn">~~</span> Settings</a>
    </nav>
    <div style="padding:18px 22px; margin-top:24px; border-top:1px dashed var(--admin-border);">
      <div style="font-family:var(--font-display); font-size:9px; color:var(--muted); letter-spacing:0.22em; text-transform:uppercase; margin-bottom:6px;">[ Server Status ]</div>
      <div style="font-family:var(--font-display); font-size:11px; color:var(--text); margin-bottom:3px;">READY <span style="color:var(--success); font-weight:700;"><?= $counts['servers_ready'] ?></span></div>
      <div style="font-family:var(--font-display); font-size:11px; color:var(--text);">OFF    <span style="color:var(--danger); font-weight:700;"><?= $counts['servers_off'] ?></span></div>
    </div>
  </aside>

  <main class="admin-main">
    <div class="admin-eyebrow"><?= $pageEyebrow ?></div>
    <h1 class="admin-h1"><?= htmlspecialchars($pageTitle) ?>.</h1>

    <?php if ($flash['ok']): ?>
      <div class="flash flash-ok">[ OK ]&nbsp;<?= htmlspecialchars($flash['ok']) ?></div>
    <?php endif; ?>
    <?php if ($flash['err']): ?>
      <div class="flash flash-err">[ ERR ] <?= htmlspecialchars($flash['err']) ?></div>
    <?php endif; ?>

    <?php
    // ============================================================
    // [01] HOME — Admin overview
    // ============================================================
    if ($page === 'home'):
      $totUsers = 0; $totAccs = 0; $totRev = 0; $topupDone = 0; $topupAmt = 0;
      if ($db) {
        try {
          $totUsers   = (int)$db->query("SELECT COUNT(*) FROM users")->fetchColumn();
          $totAccs    = (int)$db->query("SELECT COUNT(*) FROM vpn_accounts")->fetchColumn();
          $totRev     = (int)$db->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success'")->fetchColumn();
          $topupDone  = (int)$db->query("SELECT COUNT(*) FROM topup_requests WHERE status='approved'")->fetchColumn();
          $topupAmt   = (int)$db->query("SELECT COALESCE(SUM(amount),0) FROM topup_requests WHERE status='approved'")->fetchColumn();
        } catch (Exception $ex) {}
      }
    ?>
      <p class="admin-sub">Ringkasan sistem. Gunakan sidebar untuk approval topup, manajemen user, dan settings.</p>

      <div class="stat-grid">
        <div class="stat-box">
          <div class="label">[ Total Users ]</div>
          <div class="val cyan"><?= number_format($totUsers) ?></div>
          <div class="sub"><?= $counts['pending_users'] ?> belum verified</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Total Akun VPN ]</div>
          <div class="val"><?= number_format($totAccs) ?></div>
          <div class="sub">Aktif + expired</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Total Revenue ]</div>
          <div class="val yellow">Rp <?= number_format($totRev, 0, ',', '.') ?></div>
          <div class="sub">Topup + order sukses</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Pending Topup ]</div>
          <div class="val <?= $counts['pending_topup']>0?'danger':'' ?>"><?= $counts['pending_topup'] ?></div>
          <div class="sub">Menunggu approval</div>
        </div>
      </div>

      <div class="stat-grid">
        <div class="stat-box">
          <div class="label">[ Servers READY ]</div>
          <div class="val cyan"><?= $counts['servers_ready'] ?></div>
          <div class="sub">Aktif untuk order</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Servers OFF ]</div>
          <div class="val <?= $counts['servers_off']>0?'danger':'' ?>"><?= $counts['servers_off'] ?></div>
          <div class="sub">Disabled / maintenance</div>
        </div>
        <div class="stat-box">
          <div class="label">[ Topup Approved ]</div>
          <div class="val yellow"><?= number_format($topupDone) ?></div>
          <div class="sub">Rp <?= number_format($topupAmt, 0, ',', '.') ?></div>
        </div>
        <div class="stat-box">
          <div class="label">[ Pending Verify ]</div>
          <div class="val"><?= $counts['pending_users'] ?></div>
          <div class="sub">User baru belum OTP</div>
        </div>
      </div>

      <h2 style="font-family:var(--font-display); font-size:11px; color:var(--cyan); letter-spacing:0.25em; text-transform:uppercase; margin-bottom:14px;">[ Aksi Cepat ]</h2>
      <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:14px;">
        <a href="?page=topup_pending" style="padding:22px 20px; border:1px solid var(--admin-border); background:var(--bg-elev); text-decoration:none; transition:border-color var(--transition); display:block;">
          <div style="font-family:var(--font-display); font-size:13px; color:var(--yellow); margin-bottom:6px; letter-spacing:-0.01em;">$[ Approve Topup ]</div>
          <div style="font-size:0.84rem; color:var(--muted); line-height:1.5;"><?= $counts['pending_topup'] ?> requests menunggu. Klik untuk review bukti & approve.</div>
        </a>
        <a href="?page=users" style="padding:22px 20px; border:1px solid var(--admin-border); background:var(--bg-elev); text-decoration:none; transition:border-color var(--transition); display:block;">
          <div style="font-family:var(--font-display); font-size:13px; color:var(--text); margin-bottom:6px; letter-spacing:-0.01em;">## [ Manage Users ]</div>
          <div style="font-size:0.84rem; color:var(--muted); line-height:1.5;">Suspend, activate, atau hapus user. View saldo & account mereka.</div>
        </a>
        <a href="?page=servers" style="padding:22px 20px; border:1px solid var(--admin-border); background:var(--bg-elev); text-decoration:none; transition:border-color var(--transition); display:block;">
          <div style="font-family:var(--font-display); font-size:13px; color:var(--text); margin-bottom:6px; letter-spacing:-0.01em;">&gt;&gt; [ Servers ]</div>
          <div style="font-size:0.84rem; color:var(--muted); line-height:1.5;">Tambah server baru, disable maintenance, atau hapus yang sudah tidak aktif.</div>
        </a>
        <a href="?page=promos" style="padding:22px 20px; border:1px solid var(--admin-border); background:var(--bg-elev); text-decoration:none; transition:border-color var(--transition); display:block;">
          <div style="font-family:var(--font-display); font-size:13px; color:var(--text); margin-bottom:6px; letter-spacing:-0.01em;">%% [ Promo Codes ]</div>
          <div style="font-size:0.84rem; color:var(--muted); line-height:1.5;">Buat kode diskon untuk user. Set max_uses, expiry, dan diskon %.</div>
        </a>
      </div>

    <?php
    // ============================================================
    // [02] TOPUP PENDING — Approve / reject with proof preview
    // ============================================================
    elseif ($page === 'topup_pending'):
      $pendings = [];
      $processed = [];
      if ($db) {
        try {
          $pq = $db->query("SELECT t.*, u.username, u.email FROM topup_requests t LEFT JOIN users u ON u.id=t.user_id WHERE t.status='pending' ORDER BY t.created_at ASC LIMIT 50");
          $pendings = $pq->fetchAll();
          $pr = $db->query("SELECT t.*, u.username FROM topup_requests t LEFT JOIN users u ON u.id=t.user_id WHERE t.status<>'pending' ORDER BY t.processed_at DESC LIMIT 20");
          $processed = $pr->fetchAll();
        } catch (Exception $ex) {}
      }
    ?>
      <p class="admin-sub">Approve atau reject permintaan topup. Approve akan otomatis mengkredit saldo user dan mencatat transaksi.</p>

      <?php if (empty($pendings)): ?>
        <div class="section-card"><div class="body" style="padding:48px; text-align:center; color:var(--muted); font-family:var(--font-display); font-size:11px; letter-spacing:0.2em;">
          [ NO PENDING TOPUP ]<br>
          <span style="font-size:10px; color:var(--muted);">Semua request sudah diproses.</span>
        </div></div>
      <?php else: ?>
        <?php foreach ($pendings as $t): ?>
          <div class="section-card">
            <div class="head">
              <h3>[ #<?= (int)$t['id'] ?> &middot; <?= htmlspecialchars($t['username'] ?? '?') ?> &middot; Rp <?= number_format((int)$t['amount'], 0, ',', '.') ?> ]</h3>
              <span class="pill pill-pending"><?= htmlspecialchars($t['method'] ?? '-') ?></span>
            </div>
            <div class="body" style="display:grid; grid-template-columns:200px 1fr; gap:18px;">
              <div>
                <div style="font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.2em; text-transform:uppercase; margin-bottom:8px;">[ Bukti ]</div>
                <?php if (!empty($t['proof_image'])): ?>
                  <a href="../<?= htmlspecialchars($t['proof_image']) ?>" target="_blank">
                    <img src="../<?= htmlspecialchars($t['proof_image']) ?>" alt="Bukti" class="proof-thumb" onerror="this.outerHTML='<div style=&quot;padding:20px; border:1px dashed var(--border); font-family:var(--font-display); font-size:9px; color:var(--muted); text-align:center;&quot;>[ IMG NOT FOUND ]</div>'">
                  </a>
                <?php else: ?>
                  <div style="padding:20px; border:1px dashed var(--border); font-family:var(--font-display); font-size:9px; color:var(--muted); text-align:center;">[ NO UPLOAD ]</div>
                <?php endif; ?>
                <div style="font-family:var(--font-display); font-size:9px; color:var(--muted); margin-top:8px;"><?= htmlspecialchars($t['created_at'] ?? '-') ?></div>
              </div>
              <div>
                <div style="font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.2em; text-transform:uppercase; margin-bottom:8px;">[ User ]</div>
                <div style="margin-bottom:14px; font-size:0.92rem;">
                  <strong style="color:var(--text);"><?= htmlspecialchars($t['username']) ?></strong><br>
                  <span style="color:var(--muted); font-family:var(--font-display); font-size:11px;"><?= htmlspecialchars($t['email']) ?></span>
                </div>
                <form method="POST" style="display:flex; flex-direction:column; gap:8px;">
                  <input type="hidden" name="action" value="approve_topup">
                  <input type="hidden" name="topup_id" value="<?= (int)$t['id'] ?>">
                  <?= csrfField() ?>
                  <div class="form-group" style="margin-bottom:0;">
                    <label>Admin Note (opsional)</label>
                    <input type="text" name="admin_note" placeholder="Bukti valid, dicek tanggal ..." maxlength="120">
                  </div>
                  <div style="display:flex; gap:6px;">
                    <button type="submit" class="btn btn-success btn-sm" data-confirm="Approve topup Rp <?= number_format((int)$t['amount']) ?> dan kredit saldo user?">[ + APPROVE ]</button>
                  </div>
                </form>
                <form method="POST" onsubmit="return false;" id="reject-<?= (int)$t['id'] ?>" style="margin-top:8px; display:flex; flex-direction:column; gap:8px;">
                  <input type="hidden" name="action" value="reject_topup">
                  <input type="hidden" name="topup_id" value="<?= (int)$t['id'] ?>">
                  <?= csrfField() ?>
                  <div class="form-group" style="margin-bottom:0;">
                    <label>Rejection Reason</label>
                    <input type="text" name="admin_note" placeholder="Alasan reject (misal: bukti tidak terbaca)" required>
                  </div>
                  <button type="submit" class="btn btn-danger btn-sm" data-confirm="Reject topup ini?">[ - REJECT ]</button>
                </form>
              </div>
            </div>
          </div>
        <?php endforeach; ?>
      <?php endif; ?>

      <?php if (!empty($processed)): ?>
        <h2 style="font-family:var(--font-display); font-size:11px; color:var(--cyan); letter-spacing:0.25em; text-transform:uppercase; margin:32px 0 14px;">[ Recently Processed ]</h2>
        <div class="table-wrap">
          <table class="data">
            <thead><tr><th>ID</th><th>User</th><th>Amount</th><th>Method</th><th>Status</th><th>Note</th><th>Processed</th></tr></thead>
            <tbody>
            <?php foreach ($processed as $t): ?>
              <tr>
                <td class="mono">#<?= (int)$t['id'] ?></td>
                <td><?= htmlspecialchars($t['username'] ?? '?') ?></td>
                <td class="mono">Rp <?= number_format((int)$t['amount'], 0, ',', '.') ?></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['method'] ?? '-') ?></td>
                <td><span class="pill <?= $t['status']==='approved'?'pill-active':'pill-expired' ?>"><?= htmlspecialchars($t['status']) ?></span></td>
                <td style="font-size:11px;"><?= htmlspecialchars($t['admin_note'] ?? '-') ?></td>
                <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['processed_at'] ?? '-') ?></td>
              </tr>
            <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      <?php endif; ?>

    <?php
    // ============================================================
    // [03] USERS — list, search, view, suspend/delete
    // ============================================================
    elseif ($page === 'users'):
      $q = sanitize($_GET['q'] ?? '');
      $users = [];
      if ($db) {
        try {
          if ($q !== '') {
            $uq = $db->prepare("SELECT u.*, (SELECT COUNT(*) FROM vpn_accounts WHERE user_id=u.id) AS acc_count FROM users u WHERE u.username LIKE ? OR u.email LIKE ? ORDER BY u.id DESC LIMIT 100");
            $uq->execute(['%' . $q . '%', '%' . $q . '%']);
          } else {
            $uq = $db->query("SELECT u.*, (SELECT COUNT(*) FROM vpn_accounts WHERE user_id=u.id) AS acc_count FROM users u ORDER BY u.id DESC LIMIT 50");
          }
          $users = $uq->fetchAll();
        } catch (Exception $ex) {}
      }
      $uid_focus = (int)($_GET['uid'] ?? 0);
      $focus = null;
      $userTxs = [];
      $userAccs = [];
      if ($uid_focus > 0 && $db) {
        try {
          $fq = $db->prepare("SELECT * FROM users WHERE id=?");
          $fq->execute([$uid_focus]);
          $focus = $fq->fetch();
          if ($focus) {
            $txq = $db->prepare("SELECT * FROM transactions WHERE user_id=? ORDER BY created_at DESC LIMIT 20");
            $txq->execute([$uid_focus]);
            $userTxs = $txq->fetchAll();
            $acq = $db->prepare("SELECT a.*, s.name AS server_name FROM vpn_accounts a LEFT JOIN servers s ON s.id=a.server_id WHERE a.user_id=? ORDER BY a.created_at DESC LIMIT 20");
            $acq->execute([$uid_focus]);
            $userAccs = $acq->fetchAll();
          }
        } catch (Exception $ex) {}
      }
    ?>
      <p class="admin-sub">List semua user registered. Klik user untuk lihat detail, suspend, atau hapus permanen.</p>

      <div class="section-card" style="padding:14px;">
        <form method="GET" style="display:flex; gap:8px;">
          <input type="hidden" name="page" value="users">
          <input type="text" name="q" value="<?= htmlspecialchars($q) ?>" placeholder="Cari username atau email..." style="flex:1; padding:10px 12px; background:var(--bg); border:1px solid var(--border); color:var(--text); font-family:var(--font-body); font-size:0.92rem;">
          <button type="submit" class="btn btn-sm">[ SEARCH ]</button>
        </form>
      </div>

      <?php if ($focus): ?>
        <div class="section-card">
          <div class="head">
            <h3>[ FOCUS: User #<?= (int)$focus['id'] ?> &middot; <?= htmlspecialchars($focus['username']) ?> ]</h3>
            <a href="?page=users<?= $q !== '' ? '&q=' . urlencode($q) : '' ?>" style="font-family:var(--font-display); font-size:10px; color:var(--cyan); text-decoration:none;">[ CLOSE &rarr; ]</a>
          </div>
          <div class="body">
            <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:12px; margin-bottom:18px; font-family:var(--font-display); font-size:11px;">
              <div><span style="color:var(--muted); letter-spacing:0.2em;">EMAIL</span> &middot; <span style="color:var(--text);"><?= htmlspecialchars($focus['email']) ?></span></div>
              <div><span style="color:var(--muted); letter-spacing:0.2em;">ROLE</span> &middot; <span class="pill <?= ($focus['role'] ?? '')==='admin'?'pill-admin':'pill-user' ?>"><?= htmlspecialchars($focus['role'] ?? 'user') ?></span></div>
              <div><span style="color:var(--muted); letter-spacing:0.2em;">SALDO</span> &middot; <span style="color:var(--yellow);">Rp <?= number_format((int)$focus['saldo']) ?></span></div>
              <div><span style="color:var(--muted); letter-spacing:0.2em;">VERIFIED</span> &middot; <span style="color:<?= $focus['is_verified']?'var(--success)':'var(--danger)' ?>;"><?= $focus['is_verified']?'YES':'NO' ?></span></div>
            </div>

            <form method="POST" style="margin-bottom:14px; background:var(--bg); border:1px dashed var(--border); padding:12px;">
              <input type="hidden" name="action" value="toggle_user">
              <input type="hidden" name="user_id" value="<?= (int)$focus['id'] ?>">
              <input type="hidden" name="mode" value="<?= $focus['is_verified']?'suspend':'activate' ?>">
              <?= csrfField() ?>
              <input type="text" name="admin_note" placeholder="Alasan toggle (audit log)" style="width:60%; padding:8px; background:var(--bg-elev); border:1px solid var(--border); color:var(--text); font-family:var(--font-body); font-size:0.85rem;">
              <button type="submit" class="btn btn-sm btn-warn" data-confirm="<?= $focus['is_verified']?'Suspend user ini (unverify)? Login akan ditolak sampai di-activate lagi.':'Activate user ini?' ?>" style="margin-left:8px;">[ <?= $focus['is_verified']?'SUSPEND':'ACTIVATE' ?> ]</button>
            </form>

            <form method="POST" style="background:var(--bg); border:1px dashed var(--danger); padding:12px;">
              <input type="hidden" name="action" value="force_delete_user">
              <input type="hidden" name="user_id" value="<?= (int)$focus['id'] ?>">
              <?= csrfField() ?>
              <div style="font-family:var(--font-display); font-size:10px; color:var(--danger); letter-spacing:0.2em; margin-bottom:8px;">[ DANGER ZONE — PERMANENT DELETE ]</div>
              <input type="text" name="confirm_username" placeholder="Ketik username: <?= htmlspecialchars($focus['username']) ?>" required style="width:60%; padding:8px; background:var(--bg-elev); border:1px solid var(--danger); color:var(--text); font-family:var(--font-body); font-size:0.85rem;">
              <button type="submit" class="btn btn-sm btn-danger" data-confirm="PERMANENT. Hapus user + semua akun VPN + semua transaksi + topup request?" style="margin-left:8px;">[ DELETE PERMANENT ]</button>
            </form>

            <?php if (!empty($userAccs)): ?>
              <h4 style="font-family:var(--font-display); font-size:10px; color:var(--cyan); letter-spacing:0.22em; text-transform:uppercase; margin:18px 0 10px;">[ VPN Accounts (<?= count($userAccs) ?>) ]</h4>
              <table class="data"><thead><tr><th>ID</th><th>Username</th><th>Protocol</th><th>Server</th><th>Status</th><th>Expires</th></tr></thead><tbody>
              <?php foreach ($userAccs as $a): ?>
                <tr>
                  <td class="mono">#<?= (int)$a['id'] ?></td>
                  <td class="mono"><?= htmlspecialchars($a['username']) ?></td>
                  <td><span class="pill pill-pending"><?= htmlspecialchars($a['protocol']) ?></span></td>
                  <td><?= htmlspecialchars($a['server_name'] ?? '-') ?></td>
                  <td><span class="pill <?= ($a['status']==='active' && strtotime($a['expiry_date'])>time())?'pill-active':'pill-expired' ?>"><?= htmlspecialchars($a['status']) ?></span></td>
                  <td class="mono" style="font-size:10px;"><?= htmlspecialchars($a['expiry_date']) ?></td>
                </tr>
              <?php endforeach; ?>
              </tbody></table>
            <?php endif; ?>

            <?php if (!empty($userTxs)): ?>
              <h4 style="font-family:var(--font-display); font-size:10px; color:var(--cyan); letter-spacing:0.22em; text-transform:uppercase; margin:18px 0 10px;">[ Recent Transactions (<?= count($userTxs) ?>) ]</h4>
              <table class="data"><thead><tr><th>ID</th><th>Type</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead><tbody>
              <?php foreach ($userTxs as $t): ?>
                <tr>
                  <td class="mono">#<?= (int)$t['id'] ?></td>
                  <td><span class="pill pill-pending"><?= htmlspecialchars($t['type']) ?></span></td>
                  <td class="mono">Rp <?= number_format((int)$t['amount']) ?></td>
                  <td><span class="pill <?= $t['status']==='success'?'pill-active':'pill-expired' ?>"><?= htmlspecialchars($t['status']) ?></span></td>
                  <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['created_at']) ?></td>
                </tr>
              <?php endforeach; ?>
              </tbody></table>
            <?php endif; ?>
          </div>
        </div>
      <?php endif; ?>

      <div class="table-wrap">
        <table class="data">
          <thead><tr><th>ID</th><th>Username</th><th>Email</th><th>Role</th><th>Saldo</th><th>Verified</th><th>Akun</th><th>Joined</th><th></th></tr></thead>
          <tbody>
          <?php foreach ($users as $u): ?>
            <tr>
              <td class="mono">#<?= (int)$u['id'] ?></td>
              <td><a href="?page=users&uid=<?= (int)$u['id'] ?>" style="color:var(--cyan); text-decoration:none; font-family:var(--font-display);"><?= htmlspecialchars($u['username']) ?></a></td>
              <td style="font-size:11px;"><?= htmlspecialchars($u['email']) ?></td>
              <td><span class="pill <?= ($u['role'] ?? '')==='admin'?'pill-admin':'pill-user' ?>"><?= htmlspecialchars($u['role'] ?? 'user') ?></span></td>
              <td class="mono">Rp <?= number_format((int)$u['saldo']) ?></td>
              <td><span class="pill <?= $u['is_verified']?'pill-active':'pill-expired' ?>"><?= $u['is_verified']?'YES':'NO' ?></span></td>
              <td class="mono"><?= (int)$u['acc_count'] ?></td>
              <td class="mono" style="font-size:10px;"><?= htmlspecialchars($u['created_at'] ?? '-') ?></td>
              <td class="actions-cell"><a href="?page=users&uid=<?= (int)$u['id'] ?><?= $q !== ''?'&q='.urlencode($q):'' ?>" class="btn btn-xs">[ VIEW ]</a></td>
            </tr>
          <?php endforeach; ?>
          <?php if (empty($users)): ?>
            <tr><td colspan="9" style="text-align:center; padding:32px; color:var(--muted); font-family:var(--font-display); font-size:11px;">[ NO USERS FOUND ]</td></tr>
          <?php endif; ?>
          </tbody>
        </table>
      </div>

    <?php
    // ============================================================
    // [04] SERVERS — list, add, toggle, delete
    // ============================================================
    elseif ($page === 'servers'):
      $servers = [];
      if ($db) {
        try {
          $sq = $db->query("SELECT s.*, (SELECT COUNT(*) FROM vpn_accounts WHERE server_id=s.id) AS used_count FROM servers s ORDER BY s.id ASC");
          $servers = $sq->fetchAll();
        } catch (Exception $ex) {}
      }
    ?>
      <p class="admin-sub">Tambah server baru, disable untuk maintenance, atau hapus server yang sudah tidak aktif.</p>

      <div class="section-card">
        <div class="head"><h3>[ Tambah Server Baru ]</h3></div>
        <div class="body">
          <form method="POST">
            <input type="hidden" name="action" value="add_server">
            <?= csrfField() ?>
            <div class="form-row three">
              <div class="form-group">
                <label>Nama Server</label>
                <input type="text" name="name" placeholder="SG-1 Premium" required maxlength="64">
              </div>
              <div class="form-group">
                <label>Region Code</label>
                <input type="text" name="region" placeholder="SG" required maxlength="16">
              </div>
              <div class="form-group">
                <label>Host</label>
                <input type="text" name="host" placeholder="sg1.example.com" required maxlength="128">
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Harga Bulanan (Rp)</label>
                <input type="number" name="monthly_price" value="10000" min="1000" max="1000000" required>
              </div>
              <div class="form-group">
                <label>Maks Akun</label>
                <input type="number" name="max_accounts" value="100" min="1" max="10000" required>
              </div>
            </div>
            <button type="submit" class="btn btn-success">[ + TAMBAH SERVER ]</button>
          </form>
        </div>
      </div>

      <div class="table-wrap">
        <table class="data">
          <thead><tr><th>ID</th><th>Name</th><th>Region</th><th>Host</th><th>Harga</th><th>Used</th><th>Status</th><th></th></tr></thead>
          <tbody>
          <?php foreach ($servers as $s): ?>
            <tr>
              <td class="mono">#<?= (int)$s['id'] ?></td>
              <td><?= htmlspecialchars($s['name']) ?></td>
              <td class="mono" style="font-size:10px;"><?= htmlspecialchars($s['region']) ?></td>
              <td class="mono" style="font-size:11px;"><?= htmlspecialchars($s['host']) ?></td>
              <td class="mono">Rp <?= number_format((int)$s['monthly_price']) ?></td>
              <td class="mono"><?= (int)$s['used_count'] ?> / <?= (int)$s['max_accounts'] ?></td>
              <td><span class="pill <?= $s['status']==='ready'?'pill-active':'pill-disabled' ?>"><?= htmlspecialchars($s['status']) ?></span></td>
              <td class="actions-cell">
                <form method="POST" style="display:inline;">
                  <input type="hidden" name="action" value="toggle_server">
                  <input type="hidden" name="server_id" value="<?= (int)$s['id'] ?>">
                  <?= csrfField() ?>
                  <button type="submit" class="btn btn-xs btn-warn" data-confirm="Toggle server status?">[ TOGGLE ]</button>
                </form>
                <form method="POST" style="display:inline;">
                  <input type="hidden" name="action" value="delete_server">
                  <input type="hidden" name="server_id" value="<?= (int)$s['id'] ?>">
                  <?= csrfField() ?>
                  <button type="submit" class="btn btn-xs btn-danger" data-confirm="Hapus server? (Gagal jika masih punya akun)">[ DEL ]</button>
                </form>
              </td>
            </tr>
          <?php endforeach; ?>
          <?php if (empty($servers)): ?>
            <tr><td colspan="8" style="text-align:center; padding:32px; color:var(--muted); font-family:var(--font-display); font-size:11px;">[ NO SERVERS YET ]</td></tr>
          <?php endif; ?>
          </tbody>
        </table>
      </div>

    <?php
    // ============================================================
    // [05] TRANSACTIONS — full history with filter
    // ============================================================
    elseif ($page === 'transactions'):
      $tx_filter = sanitize($_GET['type'] ?? '');
      $tx_status = sanitize($_GET['status'] ?? '');
      $tx_q      = sanitize($_GET['q'] ?? '');
      $txs = [];
      $totalRev = 0;
      if ($db) {
        try {
          $where = ['1=1']; $args = [];
          if (in_array($tx_filter, ['topup','order','renew'], true)) { $where[] = 't.type=?'; $args[] = $tx_filter; }
          if (in_array($tx_status, ['success','pending','failed'], true)) { $where[] = 't.status=?'; $args[] = $tx_status; }
          if ($tx_q !== '') { $where[] = '(u.username LIKE ? OR u.email LIKE ?)'; $args[] = '%' . $tx_q . '%'; $args[] = '%' . $tx_q . '%'; }
          $sql = "SELECT t.*, u.username FROM transactions t LEFT JOIN users u ON u.id=t.user_id WHERE " . implode(' AND ', $where) . " ORDER BY t.created_at DESC LIMIT 200";
          $tq = $db->prepare($sql);
          $tq->execute($args);
          $txs = $tq->fetchAll();
          $totalRev = (int)$db->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE status='success'")->fetchColumn();
        } catch (Exception $ex) {}
      }
      $filterAmount = array_sum(array_column($txs, 'amount'));
    ?>
      <p class="admin-sub">Semua transaksi sukses tercatat: <strong style="color:var(--yellow);">Rp <?= number_format($totalRev, 0, ',', '.') ?></strong>. Gunakan filter untuk mempersempit.</p>

      <div class="section-card" style="padding:14px;">
        <form method="GET" style="display:grid; grid-template-columns:1fr 1fr 1fr auto; gap:8px;">
          <input type="hidden" name="page" value="transactions">
          <input type="text" name="q" value="<?= htmlspecialchars($tx_q) ?>" placeholder="Username / email..." style="padding:8px 10px; background:var(--bg); border:1px solid var(--border); color:var(--text); font-size:0.85rem;">
          <select name="type" style="padding:8px 10px; background:var(--bg); border:1px solid var(--border); color:var(--text); font-size:0.85rem;">
            <option value="">[ ALL TYPES ]</option>
            <option value="topup" <?= $tx_filter==='topup'?'selected':'' ?>>TOPUP</option>
            <option value="order" <?= $tx_filter==='order'?'selected':'' ?>>ORDER</option>
            <option value="renew" <?= $tx_filter==='renew'?'selected':'' ?>>RENEW</option>
          </select>
          <select name="status" style="padding:8px 10px; background:var(--bg); border:1px solid var(--border); color:var(--text); font-size:0.85rem;">
            <option value="">[ ALL STATUS ]</option>
            <option value="success" <?= $tx_status==='success'?'selected':'' ?>>SUCCESS</option>
            <option value="pending" <?= $tx_status==='pending'?'selected':'' ?>>PENDING</option>
            <option value="failed" <?= $tx_status==='failed'?'selected':'' ?>>FAILED</option>
          </select>
          <button type="submit" class="btn btn-sm">[ FILTER ]</button>
        </form>
      </div>

      <div class="table-wrap">
        <table class="data">
          <thead><tr><th>ID</th><th>Date</th><th>User</th><th>Type</th><th>Method</th><th>Amount</th><th>Status</th></tr></thead>
          <tbody>
          <?php foreach ($txs as $t): ?>
            <tr>
              <td class="mono">#<?= (int)$t['id'] ?></td>
              <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['created_at'] ?? '-') ?></td>
              <td><?= htmlspecialchars($t['username'] ?? '#' . (int)$t['user_id']) ?></td>
              <td><span class="pill pill-pending"><?= htmlspecialchars($t['type']) ?></span></td>
              <td class="mono" style="font-size:10px;"><?= htmlspecialchars($t['method'] ?? '-') ?></td>
              <td class="mono">Rp <?= number_format((int)$t['amount']) ?></td>
              <td><span class="pill <?= $t['status']==='success'?'pill-active':'pill-expired' ?>"><?= htmlspecialchars($t['status']) ?></span></td>
            </tr>
          <?php endforeach; ?>
          <?php if (empty($txs)): ?>
            <tr><td colspan="7" style="text-align:center; padding:32px; color:var(--muted); font-family:var(--font-display); font-size:11px;">[ NO TRANSACTIONS ]</td></tr>
          <?php endif; ?>
          </tbody>
          <?php if (!empty($txs)): ?>
          <tfoot>
            <tr><td colspan="5" style="text-align:right; font-family:var(--font-display); font-size:10px; color:var(--muted); letter-spacing:0.2em;">[ FILTERED TOTAL ]</td><td class="mono" style="color:var(--yellow); font-weight:700;">Rp <?= number_format((int)$filterAmount) ?></td><td colspan="1"></td></tr>
          </tfoot>
          <?php endif; ?>
        </table>
      </div>

    <?php
    // ============================================================
    // [06] PROMO CODES — list, create, delete
    // ============================================================
    elseif ($page === 'promos'):
      $promos = [];
      if ($db) {
        try { $promos = $db->query("SELECT * FROM promo_codes ORDER BY created_at DESC LIMIT 50")->fetchAll(); }
        catch (Exception $ex) {}
      }
    ?>
      <p class="admin-sub">Buat kode promo diskon untuk user. Set max_uses, diskon %, dan expiry.</p>

      <div class="section-card">
        <div class="head"><h3>[ Tambah Promo Code ]</h3></div>
        <div class="body">
          <form method="POST">
            <input type="hidden" name="action" value="add_promo">
            <?= csrfField() ?>
            <div class="form-row three">
              <div class="form-group">
                <label>Code</label>
                <input type="text" name="code" placeholder="DISKON50" required maxlength="32" style="text-transform:uppercase; font-family:var(--font-display);">
              </div>
              <div class="form-group">
                <label>Diskon (%)</label>
                <input type="number" name="discount" value="10" min="1" max="100" required>
              </div>
              <div class="form-group">
                <label>Max Uses (0=∞)</label>
                <input type="number" name="max_uses" value="100" min="0" max="99999">
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Expires (kosongkan = permanent)</label>
                <input type="date" name="expires">
              </div>
              <div class="form-group" style="display:flex; align-items:flex-end;">
                <button type="submit" class="btn btn-success btn-full">[ + BUAT PROMO ]</button>
              </div>
            </div>
          </form>
        </div>
      </div>

      <div class="table-wrap">
        <table class="data">
          <thead><tr><th>ID</th><th>Code</th><th>Discount</th><th>Used</th><th>Max</th><th>Expires</th><th>Created</th><th></th></tr></thead>
          <tbody>
          <?php foreach ($promos as $p): ?>
            <tr>
              <td class="mono">#<?= (int)$p['id'] ?></td>
              <td class="mono" style="color:var(--yellow);"><?= htmlspecialchars(strtoupper($p['code'])) ?></td>
              <td class="mono"><?= (int)$p['discount'] ?>%</td>
              <td class="mono"><?= (int)($p['used_count'] ?? 0) ?></td>
              <td class="mono"><?= $p['max_uses'] ? (int)$p['max_uses'] : '∞' ?></td>
              <td class="mono" style="font-size:10px;"><?= htmlspecialchars($p['expires'] ?? '-') ?></td>
              <td class="mono" style="font-size:10px;"><?= htmlspecialchars($p['created_at'] ?? '-') ?></td>
              <td class="actions-cell">
                <form method="POST" style="display:inline;">
                  <input type="hidden" name="action" value="delete_promo">
                  <input type="hidden" name="promo_id" value="<?= (int)$p['id'] ?>">
                  <?= csrfField() ?>
                  <button type="submit" class="btn btn-xs btn-danger" data-confirm="Hapus promo <?= htmlspecialchars(strtoupper($p['code'])) ?>?">[ DEL ]</button>
                </form>
              </td>
            </tr>
          <?php endforeach; ?>
          <?php if (empty($promos)): ?>
            <tr><td colspan="8" style="text-align:center; padding:32px; color:var(--muted); font-family:var(--font-display); font-size:11px;">[ NO PROMO CODES YET ]</td></tr>
          <?php endif; ?>
          </tbody>
        </table>
      </div>

    <?php
    // ============================================================
    // [07] SETTINGS — app name, contacts, payment numbers, announcements
    // ============================================================
    elseif ($page === 'settings'):
      // Reload fresh after save
      foreach (['app_name','contact_wa','contact_tg','contact_ig','dana_number','gopay_number','shopee_number','ovo_number','bank_name','bank_account','bank_holder','qris_image','announce_1','announce_2','announce_3'] as $k) {
        $$k = getSetting($k, '');
      }
    ?>
      <p class="admin-sub">Konfigurasi branding, kontak support, payment method, dan announcement cards (max 3).</p>

      <div class="section-card">
        <div class="head"><h3>[ Branding ]</h3></div>
        <div class="body">
          <form method="POST">
            <input type="hidden" name="action" value="save_settings">
            <?= csrfField() ?>
            <div class="form-group">
              <label>App Name (ditampilkan di topbar & landing)</label>
              <input type="text" name="app_name" value="<?= htmlspecialchars($appName ?? '') ?>" required maxlength="64">
            </div>
            <div class="form-row three">
              <div class="form-group">
                <label>WhatsApp Admin</label>
                <input type="text" name="contact_wa" value="<?= htmlspecialchars($contact_wa ?? '') ?>" placeholder="628123456789">
              </div>
              <div class="form-group">
                <label>Telegram Admin</label>
                <input type="text" name="contact_tg" value="<?= htmlspecialchars($contact_tg ?? '') ?>" placeholder="@ordervpn_admin">
              </div>
              <div class="form-group">
                <label>Instagram (display only)</label>
                <input type="text" name="contact_ig" value="<?= htmlspecialchars($contact_ig ?? '') ?>" placeholder="@ordervpn">
              </div>
            </div>
            <button type="submit" class="btn btn-success">[ SIMPAN BRANDING ]</button>
          </form>
        </div>
      </div>

      <div class="section-card">
        <div class="head"><h3>[ Payment Methods ]</h3></div>
        <div class="body">
          <form method="POST">
            <input type="hidden" name="action" value="save_settings">
            <?= csrfField() ?>
            <div class="form-row">
              <div class="form-group">
                <label>DANA Number</label>
                <input type="text" name="dana_number" value="<?= htmlspecialchars($dana_number ?? '') ?>" placeholder="081234567890">
              </div>
              <div class="form-group">
                <label>GoPay Number</label>
                <input type="text" name="gopay_number" value="<?= htmlspecialchars($gopay_number ?? '') ?>" placeholder="081234567890">
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>ShopeePay Number</label>
                <input type="text" name="shopee_number" value="<?= htmlspecialchars($shopee_number ?? '') ?>" placeholder="081234567890">
              </div>
              <div class="form-group">
                <label>OVO Number</label>
                <input type="text" name="ovo_number" value="<?= htmlspecialchars($ovo_number ?? '') ?>" placeholder="081234567890">
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Bank Name</label>
                <input type="text" name="bank_name" value="<?= htmlspecialchars($bank_name ?? '') ?>" placeholder="BCA">
              </div>
              <div class="form-group">
                <label>Bank Account</label>
                <input type="text" name="bank_account" value="<?= htmlspecialchars($bank_account ?? '') ?>" placeholder="1234567890">
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Account Holder Name</label>
                <input type="text" name="bank_holder" value="<?= htmlspecialchars($bank_holder ?? '') ?>" placeholder="PT OrderVPN">
              </div>
              <div class="form-group">
                <label>QRIS Image Path</label>
                <input type="text" name="qris_image" value="<?= htmlspecialchars($qris_image ?? '') ?>" placeholder="uploads/qris.png">
              </div>
            </div>
            <button type="submit" class="btn btn-success">[ SIMPAN PAYMENT METHODS ]</button>
          </form>
        </div>
      </div>

      <div class="section-card">
        <div class="head"><h3>[ Announcement Cards (max 3) ]</h3><span style="font-family:var(--font-display); font-size:9px; color:var(--muted); letter-spacing:0.2em;">Format: TAG|Text (TAG = NEW/PROMO/INFO/UPDATE)</span></div>
        <div class="body">
          <form method="POST">
            <input type="hidden" name="action" value="save_settings">
            <?= csrfField() ?>
            <div class="form-group">
              <label>Announcement 1</label>
              <input type="text" name="announce_1" value="<?= htmlspecialchars($announce_1 ?? '') ?>" placeholder="PROMO|Diskon 25% untuk paket bulanan.">
            </div>
            <div class="form-group">
              <label>Announcement 2</label>
              <input type="text" name="announce_2" value="<?= htmlspecialchars($announce_2 ?? '') ?>" placeholder="INFO|Server baru Japan Tokyo sudah aktif.">
            </div>
            <div class="form-group">
              <label>Announcement 3</label>
              <input type="text" name="announce_3" value="<?= htmlspecialchars($announce_3 ?? '') ?>" placeholder="NEW|Trial 3 hari untuk user baru.">
            </div>
            <button type="submit" class="btn btn-success">[ SIMPAN ANNOUNCEMENTS ]</button>
          </form>
        </div>
      </div>

      <div class="section-card">
        <div class="head"><h3>[ Live Preview ]</h3><span style="font-family:var(--font-display); font-size:9px; color:var(--muted); letter-spacing:0.2em;">[ TIRUAN FOOTER LANDING ]</span></div>
        <div class="body">
          <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:24px; background:var(--bg-deep); padding:18px; border:1px dashed var(--border);">
            <div>
              <div style="font-family:var(--font-display); font-size:10px; color:var(--cyan); letter-spacing:0.28em; text-transform:uppercase; margin-bottom:12px; padding-bottom:8px; border-bottom:1px solid var(--border);">[ Kontak ]</div>
              <a href="https://wa.me/<?= htmlspecialchars(preg_replace('/[^0-9]/', '', $contact_wa ?? '')) ?>" target="_blank" style="display:block; font-size:0.85rem; color:var(--muted); text-decoration:none; margin-bottom:6px;">WhatsApp: <?= htmlspecialchars($contact_wa ?? '0812-3456-7890') ?></a>
              <a href="https://t.me/<?= htmlspecialchars(ltrim($contact_tg ?? '@ordervpn_admin', '@')) ?>" target="_blank" style="display:block; font-size:0.85rem; color:var(--muted); text-decoration:none; margin-bottom:6px;">Telegram: <?= htmlspecialchars($contact_tg ?? '@ordervpn_admin') ?></a>
            </div>
            <div>
              <div style="font-family:var(--font-display); font-size:10px; color:var(--cyan); letter-spacing:0.28em; text-transform:uppercase; margin-bottom:12px; padding-bottom:8px; border-bottom:1px solid var(--border);">[ Payment ]</div>
              <div style="font-size:0.85rem; color:var(--muted); line-height:1.6;">
                DANA: <?= htmlspecialchars($dana_number ?? '-') ?><br>
                GoPay: <?= htmlspecialchars($gopay_number ?? '-') ?><br>
                QRIS: <?= htmlspecialchars($qris_image ?: '(belum di-upload)') ?>
              </div>
            </div>
            <div>
              <div style="font-family:var(--font-display); font-size:10px; color:var(--cyan); letter-spacing:0.28em; text-transform:uppercase; margin-bottom:12px; padding-bottom:8px; border-bottom:1px solid var(--border);">[ Announcement ]</div>
              <?php for ($i = 1; $i <= 3; $i++):
                $a_text = ${"announce_$i"} ?? '';
                if (empty($a_text)) continue;
                $tag = ''; $body = $a_text;
                if (strpos($a_text, '|') !== false) { list($tag, $body) = explode('|', $a_text, 2); }
              ?>
                <div style="padding:8px 10px; background:var(--bg); border-left:2px solid var(--cyan); margin-bottom:6px; font-size:0.82rem; color:var(--text-dim);">
                  <?php if ($tag): ?><span style="font-family:var(--font-display); font-size:9px; background:var(--cyan); color:var(--bg); padding:2px 5px; margin-right:6px; letter-spacing:0.2em;"><?= htmlspecialchars(strtoupper($tag)) ?></span><?php endif; ?>
                  <?= htmlspecialchars($body) ?>
                </div>
              <?php endfor; ?>
            </div>
          </div>
        </div>
      </div>

    <?php endif; ?>

  </main>
</div>

<script>
// Universal data-confirm handler — safe from server-data interpolation
document.querySelectorAll('[data-confirm]').forEach(function(el){
  el.addEventListener('click', function(e){
    if (!confirm(el.dataset.confirm)) e.preventDefault();
  });
});
// Logout link
document.querySelector('a[href="../index.php?logout=1"]')?.addEventListener('click', function(e) {
  if (!confirm('Logout dari sesi admin?')) e.preventDefault();
});
</script>
</body>
</html>
