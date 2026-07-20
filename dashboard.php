<?php
require_once __DIR__.'/includes/config.php';
$session = requireLogin();
$db = getDB();

$userId = $session['user_id'];
$username = $session['username'];
$role = $session['role'];

// Fresh user data
$u = $db->prepare("SELECT * FROM users WHERE id=?");
$u->execute([$userId]); $user = $u->fetch();

// Stats
$totalAkun = $db->prepare("SELECT COUNT(*) FROM vpn_accounts WHERE user_id=? AND status='active'");
$totalAkun->execute([$userId]); $totalAkun = $totalAkun->fetchColumn();

$totalTrx = $db->prepare("SELECT COUNT(*) FROM transactions WHERE user_id=?");
$totalTrx->execute([$userId]); $totalTrx = $totalTrx->fetchColumn();

$totalTopup = $db->prepare("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE user_id=? AND type='topup' AND status='success'");
$totalTopup->execute([$userId]); $totalTopup = $totalTopup->fetchColumn();

// Active accounts
$akuns = $db->prepare("SELECT va.*, s.nama_server, s.lokasi, s.flag FROM vpn_accounts va 
    JOIN servers s ON va.server_id=s.id 
    WHERE va.user_id=? AND va.status='active' ORDER BY va.created_at DESC LIMIT 5");
$akuns->execute([$userId]); $akuns = $akuns->fetchAll();

// Recent transactions
$trxs = $db->prepare("SELECT * FROM transactions WHERE user_id=? ORDER BY created_at DESC LIMIT 5");
$trxs->execute([$userId]); $trxs = $trxs->fetchAll();

// Servers for ordering
$servers = $db->query("SELECT * FROM servers WHERE status='ready' ORDER BY nama_server")->fetchAll();

$appName = getSetting('app_name','OrderVPN');
$contactWa = getSetting('contact_wa');
$contactTg = getSetting('contact_tg');
$contactIg = getSetting('contact_ig');

// Trial check
$trialUsed = $db->prepare("SELECT COUNT(*) FROM vpn_accounts WHERE user_id=? AND is_trial=1 AND DATE(created_at)=CURDATE()");
$trialUsed->execute([$userId]); $trialUsed = (int)$trialUsed->fetchColumn();
?><!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title><?=$appName?> — Dashboard</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
:root {
  --bg: #070b14;
  --bg-alt: #0c111b;
  --card: #111827;
  --card-hover: #1a2235;
  --border: #1e293b;
  --border-light: #263348;
  --text: #e2e8f0;
  --text-dim: #94a3b8;
  --muted: #64748b;
  --primary: #6366f1;
  --primary-dim: #4f46e5;
  --accent: #818cf8;
  --success: #10b981;
  --success-bg: rgba(16,185,129,0.1);
  --warning: #f59e0b;
  --danger: #ef4444;
  --danger-bg: rgba(239,68,68,0.08);
  --info: #3b82f6;
  --purple: #8b5cf6;
  --radius: 12px;
  --radius-sm: 8px;
  --radius-lg: 16px;
  --shadow: 0 1px 3px rgba(0,0,0,.3);
  --shadow-lg: 0 8px 25px rgba(0,0,0,.4);
  --shadow-glow: 0 4px 20px rgba(99,102,241,0.25);
  --transition: 0.25s cubic-bezier(0.16,1,0.3,1);
}
* { box-sizing:border-box; margin:0; padding:0; }
body {
  font-family: 'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif;
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}
a { color: var(--accent); text-decoration:none; transition: var(--transition); }
a:hover { color: var(--primary); }

/* Layout */
.layout { display:flex; min-height: 100vh; }
.sidebar {
  width: 260px; min-width: 260px;
  background: linear-gradient(180deg, #0f1420 0%, #0a0f1a 100%);
  border-right: 1px solid var(--border);
  display:flex; flex-direction:column;
  position: sticky; top:0; height: 100vh;
  overflow-y: auto;
}
.main { flex:1; padding: 28px 32px; overflow-y: auto; max-width: 1200px; }

/* Sidebar */
.sidebar-brand {
  display:flex; align-items:center; gap: 12px;
  padding: 22px 20px 16px;
  border-bottom: 1px solid var(--border);
  margin-bottom: 8px;
}
.sidebar-brand svg { flex-shrink:0; filter: drop-shadow(0 0 8px rgba(99,102,241,0.3)); }
.sidebar-brand-text { line-height:1.3; }
.sidebar-brand-name { font-size:1.05em; font-weight:700; color:var(--text); letter-spacing:-.2px; }
.sidebar-brand-ver { font-size:.65em; color:var(--muted); font-weight:500; }

.sidebar-section {
  padding: 12px 20px 6px;
  font-size: .68em; font-weight: 600; text-transform: uppercase;
  letter-spacing: .1em; color: var(--muted);
}
.sidebar-nav { display:flex; flex-direction:column; gap: 2px; padding: 0 10px; flex:1; }
.sidebar-nav a, .nav-item {
  display:flex; align-items:center; gap: 10px;
  padding: 10px 14px; border-radius: var(--radius-sm);
  font-size: .85em; font-weight: 500; color: var(--text-dim);
  transition: var(--transition); cursor: pointer; border: none;
  background: transparent; width: 100%; text-align: left;
  font-family: inherit; position: relative;
}
.sidebar-nav a::before, .nav-item::before {
  content: ''; position: absolute; left: 0; top: 50%; transform: translateY(-50%);
  width: 3px; height: 0; border-radius: 0 3px 3px 0;
  background: var(--primary); transition: var(--transition);
}
.sidebar-nav a.active::before, .nav-item.active::before { height: 60%; }
.sidebar-nav a:hover, .nav-item:hover { background: rgba(99,102,241,.08); color: var(--text); }
.sidebar-nav a.active, .nav-item.active { background: rgba(99,102,241,.12); color: var(--primary); font-weight: 600; }
.sidebar-nav a svg, .nav-item svg { flex-shrink:0; opacity: .7; transition: var(--transition); }
.sidebar-nav a.active svg, .nav-item.active svg { opacity: 1; }
.nav-badge {
  margin-left: auto;
  background: rgba(99,102,241,.15); color: var(--primary);
  font-size: .65em; font-weight: 700; padding: 1px 7px;
  border-radius: 20px; min-width: 20px; text-align: center;
}

.sidebar-footer {
  margin-top: auto; padding: 12px 14px;
  border-top: 1px solid var(--border);
  display:flex; flex-direction:column; gap: 4px;
}
.user-card {
  display:flex; align-items:center; gap: 10px;
  padding: 8px 10px; border-radius: var(--radius-sm);
  background: rgba(99,102,241,.06);
  margin-bottom: 4px; border: 1px solid rgba(99,102,241,.08);
}
.user-avatar {
  width: 36px; height: 36px; border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), var(--purple));
  display:flex; align-items:center; justify-content:center;
  font-size: .8em; font-weight: 700; color: #fff;
  flex-shrink:0; box-shadow: 0 2px 8px rgba(99,102,241,0.3);
}
.user-name { font-size: .82em; font-weight:600; color: var(--text); }
.user-role { font-size: .65em; color: var(--muted); font-weight:500; }
.sidebar-footer a {
  display:flex; align-items:center; gap: 10px;
  padding: 8px 12px; border-radius: var(--radius-sm);
  font-size: .8em; font-weight: 500; color: var(--text-dim);
  transition: var(--transition);
}
.sidebar-footer a:hover { background: rgba(99,102,241,.08); color: var(--text); }
.sidebar-footer .logout-link { color: var(--danger); }
.sidebar-footer .logout-link:hover { background: rgba(239,68,68,.1); }

/* Topbar */
.topbar {
  display:flex; align-items:center; justify-content:space-between;
  margin-bottom: 28px; gap: 16px;
}
.topbar-left { display:flex; align-items:center; gap: 12px; }
.topbar h1 { font-size:1.35em; font-weight:700; letter-spacing:-.3px; }
.hamburger {
  display: none; background: none; border: none; color: var(--text-dim);
  cursor: pointer; padding: 4px;
}
.saldo-chip {
  background: var(--success-bg);
  color: var(--success);
  padding: 7px 16px; border-radius: 20px;
  font-size:.85em; font-weight:600;
  border: 1px solid rgba(16,185,129,.2);
  display:flex; align-items:center; gap: 6px;
  backdrop-filter: blur(8px);
}

/* Stats */
.stats { display:grid; grid-template-columns: repeat(auto-fit, minmax(200px,1fr)); gap: 16px; margin-bottom: 28px; }
.stat-card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px;
  display:flex; align-items:center; gap: 14px;
  box-shadow: var(--shadow);
  transition: var(--transition);
  position: relative; overflow: hidden;
}
.stat-card::after {
  content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px;
  opacity: 0; transition: var(--transition);
}
.stat-card.blue::after { background: linear-gradient(90deg, var(--primary), var(--accent)); }
.stat-card.green::after { background: linear-gradient(90deg, var(--success), #34d399); }
.stat-card.purple::after { background: linear-gradient(90deg, var(--purple), #a78bfa); }
.stat-card.amber::after { background: linear-gradient(90deg, var(--warning), #fbbf24); }
.stat-card:hover::after { opacity: 1; }
.stat-card:hover { border-color: var(--border-light); box-shadow: var(--shadow-lg); transform: translateY(-2px); }
.stat-icon {
  width: 46px; height: 46px; border-radius: var(--radius-sm);
  display:flex; align-items:center; justify-content:center;
  flex-shrink:0; position: relative;
}
.stat-icon.blue { background: rgba(99,102,241,.15); color: var(--primary); }
.stat-icon.green { background: rgba(16,185,129,.12); color: var(--success); }
.stat-icon.amber { background: rgba(245,158,11,.12); color: var(--warning); }
.stat-icon.purple { background: rgba(139,92,246,.12); color: var(--purple); }
.stat-info { line-height:1.3; }
.stat-val { font-size:1.5em; font-weight:700; letter-spacing:-.5px; }
.stat-label { font-size:.72em; color: var(--muted); font-weight:500; margin-top:2px; text-transform: uppercase; letter-spacing: .04em; }

/* Cards */
.card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  overflow: hidden;
  margin-bottom: 24px;
  transition: var(--transition);
}
.card:hover { box-shadow: var(--shadow-lg); border-color: var(--border-light); }
.card-header {
  display:flex; align-items:center; justify-content:space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border-light);
  gap: 12px;
}
.card-title { font-size: .92em; font-weight: 600; color: var(--text); display:flex; align-items:center; gap: 8px; }
.card-title svg { color: var(--primary); }
.card-body { padding: 20px; }

/* Account List */
.akun-list { display:flex; flex-direction:column; }
.akun-item {
  display:flex; align-items:center; justify-content:space-between;
  padding: 14px 16px;
  border-bottom: 1px solid var(--border);
  transition: var(--transition); gap: 16px;
  cursor: pointer;
}
.akun-item:last-child { border-bottom: none; }
.akun-item:hover { background: var(--card-hover); }
.akun-left { display:flex; align-items:center; gap: 12px; min-width:0; flex:1; }
.akun-icon {
  width: 40px; height: 40px; border-radius: var(--radius-sm);
  display:flex; align-items:center; justify-content:center;
  font-size: .7em; font-weight: 700; flex-shrink:0;
}
.akun-icon.ssh { background: rgba(99,102,241,.15); color: var(--primary); }
.akun-icon.vmess { background: rgba(16,185,129,.12); color: var(--success); }
.akun-icon.vless { background: rgba(245,158,11,.12); color: var(--warning); }
.akun-icon.trojan { background: rgba(239,68,68,.1); color: var(--danger); }
.akun-detail { min-width:0; }
.akun-detail .name { font-weight:600; font-size:.88em; }
.akun-detail .meta { font-size:.72em; color: var(--muted); margin-top: 2px; display:flex; gap:8px; align-items: center; flex-wrap: wrap; }
.akun-right { display:flex; align-items:center; gap: 10px; flex-shrink:0; }
.akun-exp { font-size:.72em; font-weight:600; padding:3px 10px; border-radius:20px; letter-spacing: .02em; }
.akun-exp.ok { background: rgba(16,185,129,.1); color: var(--success); }
.akun-exp.warn { background: rgba(245,158,11,.1); color: var(--warning); }
.akun-exp.danger { background: rgba(239,68,68,.1); color: var(--danger); }
.akun-exp.trial { background: rgba(59,130,246,.1); color: var(--info); }

/* Transaction Items */
.trx-item {
  display:flex; align-items:center; gap: 12px;
  padding: 10px 0; border-bottom: 1px solid var(--border);
}
.trx-item:last-child { border-bottom:none; }
.trx-icon {
  width: 36px; height: 36px; border-radius: 50%;
  display:flex; align-items:center; justify-content:center;
  font-size: .8em; flex-shrink:0;
}
.trx-topup .trx-icon { background: var(--success-bg); color: var(--success); }
.trx-order .trx-icon { background: var(--danger-bg); color: var(--danger); }
.trx-info { flex:1; min-width:0; }
.trx-info .desc { font-size:.84em; font-weight:500; }
.trx-info .date { font-size:.7em; color: var(--muted); margin-top:2px; }
.trx-amount { font-size:.9em; font-weight:700; white-space:nowrap; }

/* Buttons */
.btn {
  display:inline-flex; align-items:center; justify-content:center; gap: 6px;
  padding: 9px 18px; border-radius: var(--radius-sm);
  font-size:.82em; font-weight:600; letter-spacing:.2px;
  border: none; cursor: pointer; font-family: inherit;
  transition: var(--transition);
  white-space:nowrap;
}
.btn-primary { background: linear-gradient(135deg, var(--primary), #7c3aed); color: #fff; }
.btn-primary:hover { box-shadow: var(--shadow-glow); transform: translateY(-1px); }
.btn-primary:active { transform: translateY(0); }
.btn-success { background: var(--success-bg); color: var(--success); border: 1px solid rgba(16,185,129,.25); }
.btn-success:hover { background: rgba(16,185,129,.25); }
.btn-danger { background: var(--danger-bg); color: var(--danger); border: 1px solid rgba(239,68,68,.2); }
.btn-danger:hover { background: rgba(239,68,68,.2); }
.btn-outline { background: transparent; color: var(--text-dim); border: 1px solid var(--border); }
.btn-outline:hover { border-color: var(--primary); color: var(--primary); }
.btn-sm { padding: 5px 12px; font-size:.75em; }
.btn-xs { padding: 3px 10px; font-size:.68em; border-radius: 6px; }

/* Badges */
.badge {
  display:inline-flex; align-items:center; padding: 3px 10px; border-radius: 20px;
  font-size:.65em; font-weight:600; letter-spacing:.4px;
  text-transform: uppercase;
}
.badge-active { background: var(--success-bg); color: var(--success); }
.badge-expired { background: var(--danger-bg); color: var(--danger); }
.badge-trial { background: rgba(245,158,11,.12); color: var(--warning); }
.badge-vmess { background: var(--success-bg); color: var(--success); }
.badge-vless { background: rgba(245,158,11,.12); color: var(--warning); }
.badge-trojan { background: var(--danger-bg); color: var(--danger); }
.badge-ssh { background: rgba(99,102,241,.15); color: var(--primary); }

/* Forms */
input, select, textarea {
  width:100%; padding: 10px 14px;
  background: var(--bg-alt);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text);
  font-size:.88em; font-family: inherit;
  transition: var(--transition); outline: none;
}
input:focus, select:focus, textarea:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(99,102,241,.12);
}
.form-group { margin-bottom: 14px; }
label {
  display:block; margin-bottom: 5px;
  font-size:.75em; font-weight:600; text-transform:uppercase;
  letter-spacing:.5px; color: var(--muted);
}

/* Protocol Buttons */
.proto-grid { display:grid; grid-template-columns: repeat(4,1fr); gap: 8px; }
.proto-btn {
  display:flex; align-items:center; justify-content:center; gap: 5px;
  padding: 8px 6px; border-radius: var(--radius-sm);
  background: var(--bg-alt); border: 1px solid var(--border);
  color: var(--text-dim); font-size:.78em; font-weight:500;
  cursor: pointer; font-family: inherit; transition: var(--transition);
}
.proto-btn:hover { border-color: var(--primary); color: var(--primary); background: rgba(99,102,241,.05); }
.proto-btn.active { background: rgba(99,102,241,.12); border-color: var(--primary); color: var(--primary); font-weight:600; box-shadow: 0 0 0 1px rgba(99,102,241,.15) inset; }

/* Method Buttons */
.topup-methods { display:flex; flex-wrap:wrap; gap: 8px; }
.method-btn {
  display:flex; align-items:center; gap: 6px;
  padding: 10px 16px; border-radius: var(--radius-sm);
  background: var(--bg-alt); border: 1px solid var(--border);
  color: var(--text-dim); font-size:.82em; font-weight:500;
  cursor: pointer; font-family: inherit; transition: var(--transition);
}
.method-btn:hover { border-color: var(--primary); color: var(--primary); background: rgba(99,102,241,.05); }
.method-btn.active { background: var(--success-bg); border-color: var(--success); color: var(--success); font-weight:600; }

/* Order Result */
.result-box { display:none; margin-top: 16px; }
.result-box.show { display:block; animation: fadeSlideIn .3s ease; }
.result-row {
  display:flex; justify-content:space-between; align-items:center;
  padding: 8px 0; border-bottom: 1px solid var(--border);
}
.result-key { font-size:.78em; color: var(--muted); }
.result-val { font-size:.85em; font-weight:600; color: var(--text); word-break:break-all; }
.link-box {
  background: var(--bg-alt); border: 1px solid var(--border);
  border-radius: var(--radius-xs); padding: 8px 12px;
  font-size:.72em; font-family: 'SF Mono','Fira Code',monospace;
  color: var(--text-dim); cursor: pointer; transition: var(--transition);
  word-break: break-all; overflow-wrap: break-word;
  margin-top: 4px; line-height: 1.5;
}
.link-box:hover { border-color: var(--primary); color: var(--text); }
.link-box:hover { border-color: var(--primary); color: var(--text); }

/* Modals */
.modal {
  display:none; position:fixed; inset:0; z-index:200;
  align-items:center; justify-content:center;
}
.modal.show { display:flex; }
.modal-backdrop {
  position:absolute; inset:0;
  background: rgba(0,0,0,.6); backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}
.modal-box {
  position:relative; z-index:1;
  background: var(--card); border: 1px solid var(--border);
  border-radius: var(--radius-lg); padding: 28px;
  width: 90%; max-width: 480px; max-height: 85vh; overflow-y: auto;
  box-shadow: 0 24px 80px rgba(0,0,0,.6);
  animation: modalIn .3s ease;
}
@keyframes modalIn {
  from { opacity:0; transform: scale(.95) translateY(10px); }
  to { opacity:1; transform: scale(1) translateY(0); }
}
.modal-close {
  position:absolute; top:12px; right:12px;
  background: none; border: none; color: var(--muted);
  cursor: pointer; padding: 4px; transition: var(--transition);
  border-radius: 6px;
}
.modal-close:hover { color: var(--text); background: rgba(255,255,255,.05); }
.modal-title {
  font-size:1.1em; font-weight:700; color: var(--text);
  margin-bottom: 16px; display:flex; align-items:center; gap: 8px;
}
.modal-title svg { color: var(--primary); }

/* Empty State */
.empty-state { text-align:center; padding: 40px 20px; color: var(--muted); }
.empty-state svg { margin-bottom: 12px; opacity: .3; }
.empty-state h3 { font-size:1em; font-weight:600; color: var(--text-dim); margin-bottom: 6px; }
.empty-state p { font-size:.85em; margin-bottom: 20px; color: var(--muted); }

/* Alerts */
.alert { padding: 12px 16px; border-radius: var(--radius-sm); font-size:.85em; font-weight:500; margin-bottom:16px; display: flex; align-items: center; gap: 8px; }
.alert-success { background: var(--success-bg); color: var(--success); border: 1px solid rgba(16,185,129,.2); }
.alert-error { background: var(--danger-bg); color: var(--danger); border: 1px solid rgba(239,68,68,.15); }
.alert-info { background: rgba(59,130,246,.08); color: var(--info); border: 1px solid rgba(59,130,246,.15); }

/* Server Status */
.server-dot {
  display:inline-block; width: 8px; height: 8px; border-radius: 50%;
  margin-right: 6px; animation: pulse 2s infinite;
}
.server-dot.ready { background: var(--success); box-shadow: 0 0 8px rgba(16,185,129,.4); }
.server-dot.offline { background: var(--muted); animation: none; }
.server-dot.maintenance { background: var(--warning); animation: none; }
@keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:.5; } }

/* Payment Info */
.payment-box {
  background: var(--bg-alt); border: 1px solid var(--border);
  border-radius: 10px; padding: 16px;
  margin: 12px 0;
}
.payment-box p { font-size:.85em; margin-bottom: 4px; }
.payment-box .label { font-size:.7em; color: var(--muted); text-transform:uppercase; letter-spacing:.05em; font-weight: 600; }
.payment-box .value { font-size:.95em; font-weight:600; color: var(--text); }

/* Utilities */
.text-center { text-align:center; }
.text-muted { color: var(--muted); }
.text-success { color: var(--success); }
.text-danger { color: var(--danger); }
.flex { display:flex; }
.flex-between { display:flex; align-items:center; justify-content:space-between; }
.gap-sm { gap: 8px; }
.gap-md { gap: 16px; }
.mt-1 { margin-top: 8px; }
.mt-2 { margin-top: 16px; }
.mb-1 { margin-bottom: 8px; }
.mb-2 { margin-bottom: 16px; }
.w-full { width:100%; }

@keyframes fadeSlideIn {
  from { opacity:0; transform: translateY(8px); }
  to { opacity:1; transform: translateY(0); }
}

@media(max-width:768px) {
  .layout { flex-direction:column; }
  .sidebar { 
    width:100%; min-width:100%; height:auto; position:fixed;
    left:0; top:0; z-index:100; max-height: 100vh;
    transform: translateX(-100%); transition: var(--transition);
  }
  .sidebar.open { transform: translateX(0); }
  .main { padding: 20px 16px; }
  .stats { grid-template-columns: 1fr 1fr; }
  .akun-item { flex-wrap:wrap; }
  .akun-right { width:100%; justify-content:flex-end; margin-top:4px; }
  .hamburger { display:block; }
  .proto-grid { grid-template-columns: repeat(2,1fr); }
}
@media(max-width:480px) {
  .stats { grid-template-columns: 1fr; }
  .topbar { flex-direction:column; align-items:flex-start; }
}
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
</style>
</head>
<body>

<div class="layout">

<!-- Sidebar -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-brand">
    <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#818cf8" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4" stroke="#10b981"/></svg>
    <div class="sidebar-brand-text">
      <div class="sidebar-brand-name"><?=$appName?></div>
      <div class="sidebar-brand-ver">Premium VPN Service</div>
    </div>
  </div>

  <div class="sidebar-section">Menu</div>
  <div class="sidebar-nav">
    <a class="nav-item active" onclick="showPage('home')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
      Dashboard
    </a>
    <a class="nav-item" onclick="showPage('order')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
      Order VPN
    </a>
    <a class="nav-item" onclick="showPage('akun')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/></svg>
      Akun VPN
      <?php if($totalAkun>0):?><span class="nav-badge"><?=$totalAkun?></span><?php endif;?>
    </a>
    <a class="nav-item" onclick="showPage('topup')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
      Isi Saldo
    </a>
  </div>

  <div class="sidebar-section">Info</div>
  <div class="sidebar-nav">
    <a class="nav-item" onclick="showPage('server')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
      Status Server
    </a>
    <a class="nav-item" onclick="showPage('riwayat')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
      Riwayat
    </a>
    <a class="nav-item" onclick="showPage('setting')">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
      Setting Akun
    </a>
  </div>

  <?php if($role==='admin'):?>
  <div class="sidebar-section">Admin</div>
  <div class="sidebar-nav">
    <a class="nav-item" href="/ordervpn/admin/">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      Admin Panel
    </a>
  </div>
  <?php endif;?>

  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-avatar"><?=strtoupper(substr($username,0,1))?></div>
      <div>
        <div class="user-name"><?=htmlspecialchars($username)?></div>
        <div class="user-role"><?=$role==='admin'?'Admin':'User'?></div>
      </div>
    </div>
    <a href="/ordervpn/api/logout.php" class="logout-link">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
      Logout
    </a>
  </div>
</aside>

<!-- Main -->
<div class="main">
  <div class="topbar">
    <div class="topbar-left">
      <button class="hamburger" onclick="document.getElementById('sidebar').classList.toggle('open')">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
      </button>
      <h1 id="pageTitle">Dashboard</h1>
    </div>
    <div class="saldo-chip">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
      <?=formatRupiah($user['saldo'])?>
    </div>
  </div>

  <div class="content">
    <div id="pageAlert"></div>

    <!-- PAGE: HOME -->
    <div id="page-home">
      <div class="stats">
        <div class="stat-card blue">
          <div class="stat-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/></svg></div>
          <div class="stat-info"><div class="stat-val"><?=$totalAkun?></div><div class="stat-label">Akun Aktif</div></div>
        </div>
        <div class="stat-card green">
          <div class="stat-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg></div>
          <div class="stat-info"><div class="stat-val"><?=formatRupiah($user['saldo'])?></div><div class="stat-label">Saldo</div></div>
        </div>
        <div class="stat-card purple">
          <div class="stat-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div>
          <div class="stat-info"><div class="stat-val"><?=$totalTrx?></div><div class="stat-label">Total Transaksi</div></div>
        </div>
        <div class="stat-card amber">
          <div class="stat-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg></div>
          <div class="stat-info"><div class="stat-val"><?=formatRupiah($totalTopup)?></div><div class="stat-label">Total Topup</div></div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/></svg>
            Akun Aktif
          </div>
          <button class="btn btn-sm btn-primary" onclick="showPage('order')">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Order Baru
          </button>
        </div>
        <div class="card-body" style="padding:0">
          <?php if(empty($akuns)):?>
          <div class="empty-state">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/></svg>
            <h3>Belum ada akun VPN aktif</h3>
            <p>Order akun VPN sekarang dan nikmati akses internet tanpa batas.</p>
            <button class="btn btn-primary" onclick="showPage('order')">Order Sekarang</button>
          </div>
          <?php else: foreach($akuns as $a):
            $exp = strtotime($a['masa_aktif']);
            $sisa = ceil(($exp - time())/86400);
            $expClass = $sisa > 7 ? 'ok' : ($sisa > 3 ? 'warn' : 'danger');
          ?>
          <div class="akun-item" onclick="showAkunDetail(<?=htmlspecialchars(json_encode($a), ENT_QUOTES, 'UTF-8')?>)">
            <div class="akun-left">
              <div class="akun-icon <?=$a['tipe']?>">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              </div>
              <div class="akun-detail">
                <div class="name"><?=htmlspecialchars($a['username'])?></div>
                <div class="meta"><?=$a['flag']??'🌐'?> <?=htmlspecialchars($a['nama_server'])?> &middot; <span class="badge badge-<?=$a['tipe']?>"><?=strtoupper($a['tipe'])?></span></div>
              </div>
            </div>
            <div class="akun-right">
              <span class="akun-exp <?=$expClass?>"><?=$a['is_trial']?'Trial':$sisa.' hari'?></span>
            </div>
          </div>
          <?php endforeach; endif;?>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            Transaksi Terbaru
          </div>
        </div>
        <div class="card-body">
          <?php if(empty($trxs)):?><div class="empty-state"><p style="margin:0">Belum ada transaksi</p></div>
          <?php else: foreach($trxs as $t):?>
          <div class="trx-item trx-<?=$t['type']?>">
            <div class="trx-icon">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><?=$t['type']==='topup'?'<polyline points="9 18 15 12 9 6"/>':'<polyline points="15 18 9 12 15 6"/>'?></svg>
            </div>
            <div class="trx-info">
              <div class="desc"><?=htmlspecialchars($t['keterangan']??$t['type'])?></div>
              <div class="date"><?=date('d M Y, H:i',strtotime($t['created_at']))?></div>
            </div>
            <div class="trx-amount" style="color:<?=$t['type']==='topup'?'var(--success)':'var(--danger)'?>">
              <?=$t['type']==='topup'?'+':'-'?><?=formatRupiah($t['amount'])?>
            </div>
          </div>
          <?php endforeach; endif;?>
        </div>
      </div>
    </div>

    <!-- PAGE: ORDER -->
    <div id="page-order" style="display:none">
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
            Order VPN
          </div>
        </div>
        <div class="card-body">
          <?php if(empty($servers)):?><div class="alert alert-error">Tidak ada server tersedia saat ini.</div>
          <?php else:?>
          <div class="form-group"><label>Pilih Server</label>
            <select id="orderServer">
              <?php foreach($servers as $s):?>
              <option value="<?=$s['id']?>" data-harga-hari="<?=$s['harga_hari']?>" data-harga-bulan="<?=$s['harga_bulan']?>"><?=$s['flag']??'🌐'?> <?=htmlspecialchars($s['nama_server'])?> &mdash; <?=htmlspecialchars($s['lokasi'])?></option>
              <?php endforeach;?>
            </select>
          </div>
          <div class="form-group"><label>Protokol</label>
            <div class="proto-grid">
              <button class="proto-btn active" data-proto="vmess" onclick="selectProto(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="13 17 18 12 13 7"/><polyline points="6 17 11 12 6 7"/></svg>VMess
              </button>
              <button class="proto-btn" data-proto="vless" onclick="selectProto(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="13 17 18 12 13 7"/><polyline points="6 17 11 12 6 7"/></svg>VLess
              </button>
              <button class="proto-btn" data-proto="trojan" onclick="selectProto(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>Trojan
              </button>
              <button class="proto-btn" data-proto="ssh" onclick="selectProto(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>SSH
              </button>
            </div>
          </div>
          <div class="form-group"><label>Durasi</label>
            <div class="proto-grid">
              <button class="proto-btn active" data-days="7" onclick="selectDuration(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>7 Hari
              </button>
              <button class="proto-btn" data-days="30" onclick="selectDuration(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>30 Hari
              </button>
              <button class="proto-btn" data-days="60" onclick="selectDuration(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>60 Hari
              </button>
              <button class="proto-btn" data-days="90" onclick="selectDuration(this)">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>90 Hari
              </button>
            </div>
          </div>
          <div class="form-group"><label>Username</label>
            <input type="text" id="orderUsername" placeholder="Buat username (huruf, angka, _)" oninput="this.value=this.value.replace(/[^a-zA-Z0-9_\-]/g,'')">
          </div>
          <div class="payment-box" style="display:flex;justify-content:space-between;align-items:center">
            <span class="label">Total Harga</span>
            <span id="hargaVal" style="font-size:1.1rem;font-weight:800;color:var(--success)">Rp 0</span>
          </div>
          <div style="display:flex;gap:.75rem">
            <button class="btn btn-primary" style="flex:1" onclick="doOrder()">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
              <span id="orderBtnTxt">Order Sekarang</span>
            </button>
            <?php if($trialUsed===0):?>
            <button class="btn btn-outline" onclick="showTrialModal()">Trial Gratis</button>
            <?php endif;?>
          </div>
          <?php endif;?>
          <div id="orderResult" class="result-box"></div>
        </div>
      </div>
    </div>

    <!-- PAGE: AKUN -->
    <div id="page-akun" style="display:none">
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/></svg>
            Semua Akun VPN
          </div>
        </div>
        <div class="card-body" style="padding:0">
          <?php
          $allAkuns = $db->prepare("SELECT va.*, s.nama_server, s.flag, s.lokasi FROM vpn_accounts va JOIN servers s ON va.server_id=s.id WHERE va.user_id=? ORDER BY va.status ASC, va.masa_aktif ASC");
          $allAkuns->execute([$userId]); $allAkuns=$allAkuns->fetchAll();
          if(empty($allAkuns)):?>
          <div class="empty-state">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/></svg>
            <p>Belum ada akun VPN. Order sekarang untuk memulai.</p>
            <button class="btn btn-primary" onclick="showPage('order')">Order Sekarang</button>
          </div>
          <?php else: foreach($allAkuns as $a):
            $exp=strtotime($a['masa_aktif']); $sisa=ceil(($exp-time())/86400);
            $expClass=$sisa>7?'ok':($sisa>3?'warn':'danger');
          ?>
          <div class="akun-item">
            <div class="akun-left">
              <div class="akun-icon <?=$a['tipe']?>">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              </div>
              <div class="akun-detail">
                <div class="name"><?=htmlspecialchars($a['username'])?></div>
                <div class="meta"><?=$a['flag']??'🌐'?> <?=htmlspecialchars($a['nama_server'])?> &middot; <span class="badge badge-<?=$a['tipe']?>"><?=strtoupper($a['tipe'])?></span><?=$a['is_trial']?' &middot; <span class="badge badge-trial">TRIAL</span>':''?></div>
              </div>
            </div>
            <div class="akun-right" style="flex-direction:column;align-items:flex-end;gap:4px">
              <span class="akun-exp <?=$a['status']==='active'?$expClass:'danger'?>"><?=$a['status']==='active'?($a['is_trial']?'Trial':$sisa.' hari'):'Expired'?></span>
              <div style="display:flex;gap:4px">
                <button class="btn btn-sm btn-outline" onclick="showAkunDetail(<?=htmlspecialchars(json_encode($a), ENT_QUOTES, 'UTF-8')?>)" title="Lihat detail">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
                <?php
                // Find the first available config link for copy button
                $copyLink = $a['link_tls'] ?: $a['link_nontls'] ?: $a['link_grpc'] ?: '';
                if ($copyLink):
                ?>
                <button class="btn btn-sm btn-primary" onclick="copyText('<?=htmlspecialchars($copyLink, ENT_QUOTES)?>',this)" title="Salin config">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                </button>
                <?php endif;?>
                <?php if($a['status']==='active'):?>
                <button class="btn btn-sm btn-danger" onclick="confirmDelete(<?=$a['id']?>,'<?=htmlspecialchars(addslashes($a['username']))?>')">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                </button>
                <?php endif;?>
              </div>
            </div>
          </div>
          <?php endforeach; endif;?>
        </div>
      </div>
    </div>

    <!-- PAGE: TOPUP -->
    <div id="page-topup" style="display:none">
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
            Isi Saldo
          </div>
        </div>
        <div class="card-body">
          <div class="form-group"><label>Nominal Topup</label>
            <input type="number" id="topupAmount" placeholder="Min. Rp 5.000" min="5000" step="1000">
          </div>
          <div class="form-group"><label>Metode Pembayaran</label>
            <div class="topup-methods" id="topupMethods">
              <button class="method-btn active" data-method="manual_transfer" onclick="selectMethod(this)">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                Transfer Bank
              </button>
              <?php if(getSetting('qris_image')):?><button class="method-btn" data-method="qris" onclick="selectMethod(this)">QRIS</button><?php endif;?>
              <?php if(getSetting('dana_number')):?><button class="method-btn" data-method="dana" onclick="selectMethod(this)">Dana</button><?php endif;?>
              <?php if(getSetting('gopay_number')):?><button class="method-btn" data-method="gopay" onclick="selectMethod(this)">GoPay</button><?php endif;?>
              <?php if(getSetting('shopee_number')):?><button class="method-btn" data-method="shopepay" onclick="selectMethod(this)">ShopeePay</button><?php endif;?>
            </div>
          </div>
          <div id="paymentInfo">
            <div id="bankInfo">
              <div class="payment-box">
                <p class="label">Bank Transfer</p>
                <p class="value"><?=htmlspecialchars(getSetting('bank_name','BCA'))?> &mdash; <?=htmlspecialchars(getSetting('bank_account',''))?></p>
                <p style="color:var(--muted);font-size:.8rem">a/n <?=htmlspecialchars(getSetting('bank_holder',''))?></p>
              </div>
            </div>
            <div id="danaInfo" style="display:none"><div class="payment-box"><p class="label">Dana</p><p class="value"><?=htmlspecialchars(getSetting('dana_number',''))?></p></div></div>
            <div id="gopayInfo" style="display:none"><div class="payment-box"><p class="label">GoPay</p><p class="value"><?=htmlspecialchars(getSetting('gopay_number',''))?></p></div></div>
            <div id="shopeeInfo" style="display:none"><div class="payment-box"><p class="label">ShopeePay</p><p class="value"><?=htmlspecialchars(getSetting('shopee_number',''))?></p></div></div>
            <div id="qrisInfo" style="display:none">
              <?php if(getSetting('qris_image')):?>
              <div class="payment-box" style="text-align:center">
                <p class="label" style="margin-bottom:.5rem">QRIS</p>
                <img src="<?=htmlspecialchars(getSetting('qris_image'))?>" style="max-width:200px;border-radius:8px">
              </div>
              <?php endif;?>
            </div>
          </div>
          <div class="form-group"><label>Upload Bukti Transfer (opsional)</label>
            <input type="file" id="buktiFile" accept="image/*">
          </div>
          <button class="btn btn-primary w-full" onclick="doTopup()">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
            Kirim Permintaan Topup
          </button>
          <div id="topupResult" class="mt-2"></div>
        </div>
      </div>
    </div>

    <!-- PAGE: SERVER -->
    <div id="page-server" style="display:none">
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
            Status Server
          </div>
        </div>
        <div class="card-body">
          <?php foreach($servers as $s): $st=$s['status'];?>
          <div class="akun-item" style="cursor:default">
            <div class="akun-left">
              <div class="akun-detail">
                <div class="name"><?=$s['flag']??'🌐'?> <?=htmlspecialchars($s['nama_server'])?></div>
                <div class="meta"><?=htmlspecialchars($s['lokasi'])?> &middot; <span class="text-mono"><?=htmlspecialchars($s['code_server'])?></span></div>
              </div>
            </div>
            <div class="akun-right" style="flex-direction:column;align-items:flex-end;gap:2px">
              <span><span class="server-dot <?=$st?>"></span><?=$st==='ready'?'Online':($st==='maintenance'?'Maintenance':'Offline')?></span>
              <div style="font-size:.7rem;color:var(--muted)"><?=formatRupiah($s['harga_hari'])?>/hari &middot; <?=formatRupiah($s['harga_bulan'])?>/bulan</div>
            </div>
          </div>
          <?php endforeach;?>
        </div>
      </div>
      <?php if($contactWa||$contactTg||$contactIg):?>
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
            Hubungi Admin
          </div>
        </div>
        <div class="card-body" style="display:flex;flex-wrap:wrap;gap:.75rem">
          <?php if($contactWa):?><a href="https://wa.me/<?=preg_replace('/\D/','',$contactWa)?>" target="_blank" class="btn btn-success">WhatsApp</a><?php endif;?>
          <?php if($contactTg):?><a href="https://t.me/<?=ltrim($contactTg,'@')?>" target="_blank" class="btn btn-primary">Telegram</a><?php endif;?>
          <?php if($contactIg):?><a href="https://instagram.com/<?=ltrim($contactIg,'@')?>" target="_blank" class="btn btn-outline">Instagram</a><?php endif;?>
        </div>
      </div>
      <?php endif;?>
    </div>

    <!-- PAGE: RIWAYAT -->
    <div id="page-riwayat" style="display:none">
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            Riwayat Transaksi
          </div>
        </div>
        <div class="card-body">
          <?php $allTrx=$db->prepare("SELECT * FROM transactions WHERE user_id=? ORDER BY created_at DESC LIMIT 50");
          $allTrx->execute([$userId]); $allTrx=$allTrx->fetchAll();
          if(empty($allTrx)):?><div class="empty-state"><p>Belum ada transaksi</p></div>
          <?php else: foreach($allTrx as $t):?>
          <div class="trx-item trx-<?=$t['type']?>">
            <div class="trx-icon">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><?=$t['type']==='topup'?'<polyline points="9 18 15 12 9 6"/>':'<polyline points="15 18 9 12 15 6"/>'?></svg>
            </div>
            <div class="trx-info">
              <div class="desc"><?=htmlspecialchars($t['keterangan']??ucfirst($t['type']))?></div>
              <div class="date"><?=date('d M Y, H:i',strtotime($t['created_at']))?> &middot; <?=$t['status']?></div>
            </div>
            <div class="trx-amount" style="color:<?=$t['type']==='topup'||$t['type']==='refund'?'var(--success)':'var(--danger)'?>">
              <?=$t['type']==='topup'||$t['type']==='refund'?'+':'-'?><?=formatRupiah($t['amount'])?>
            </div>
          </div>
          <?php endforeach; endif;?>
        </div>
      </div>
    </div>

    <!-- PAGE: SETTING -->
    <div id="page-setting" style="display:none">
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
            Setting Akun
          </div>
        </div>
        <div class="card-body">
          <div id="settingAlert"></div>
          <form id="profileForm">
            <div class="form-group"><label>Username</label>
              <input type="text" value="<?=htmlspecialchars($user['username'])?>" disabled style="opacity:.5">
            </div>
            <div class="form-group"><label>Email</label>
              <input type="email" id="settingEmail" value="<?=htmlspecialchars($user['email'])?>">
            </div>
            <div class="form-group"><label>WhatsApp (opsional)</label>
              <input type="text" id="settingWa" value="<?=htmlspecialchars($user['whatsapp']??'')?>" placeholder="08xxxxxxxxxx">
            </div>
            <div class="form-group"><label>Password Baru (kosongkan jika tidak diganti)</label>
              <input type="password" id="settingPass" placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;">
            </div>
            <div class="form-group"><label>Konfirmasi Password Baru</label>
              <input type="password" id="settingPassConfirm" placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;">
            </div>
            <button type="button" class="btn btn-primary" onclick="saveProfile()">Simpan Perubahan</button>
          </form>
        </div>
      </div>
    </div>

  </div>
</div>

<!-- MODAL: Account Detail -->
<div class="modal" id="modalAkun">
  <div class="modal-backdrop" onclick="closeModal('modalAkun')"></div>
  <div class="modal-box">
    <button class="modal-close" onclick="closeModal('modalAkun')">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
    <div class="modal-title">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      Detail Akun VPN
    </div>
    <div id="akunDetailContent"></div>
  </div>
</div>

<!-- MODAL: Trial -->
<div class="modal" id="modalTrial">
  <div class="modal-backdrop" onclick="closeModal('modalTrial')"></div>
  <div class="modal-box">
    <button class="modal-close" onclick="closeModal('modalTrial')">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    </button>
    <div class="modal-title">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      Trial VPN Gratis
    </div>
    <div class="alert alert-info" style="font-size:.82rem">Trial 1 jam gratis, 1x per hari, kuota 1GB.</div>
    <div class="form-group"><label>Server</label>
      <select id="trialServer">
        <?php foreach($servers as $s):?><option value="<?=$s['id']?>"><?=$s['flag']??'🌐'?> <?=htmlspecialchars($s['nama_server'])?></option><?php endforeach;?>
      </select>
    </div>
    <div class="form-group"><label>Protokol</label>
      <div class="proto-grid">
        <button class="proto-btn active" data-proto="vmess" onclick="selectTrialProto(this)">VMess</button>
        <button class="proto-btn" data-proto="vless" onclick="selectTrialProto(this)">VLess</button>
        <button class="proto-btn" data-proto="trojan" onclick="selectTrialProto(this)">Trojan</button>
        <button class="proto-btn" data-proto="ssh" onclick="selectTrialProto(this)">SSH</button>
      </div>
    </div>
    <div class="form-group"><label>Username</label>
      <input type="text" id="trialUsername" placeholder="Buat username trial">
    </div>
    <button class="btn btn-primary w-full mt-1" onclick="doTrial()">Ambil Trial Gratis</button>
    <div id="trialResult" class="result-box"></div>
  </div>
</div>

<!-- MODAL: Delete Confirm -->
<div class="modal" id="modalDelete">
  <div class="modal-backdrop" onclick="closeModal('modalDelete')"></div>
  <div class="modal-box" style="max-width:380px">
    <div class="modal-title">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
      Hapus Akun
    </div>
    <p style="color:var(--muted);font-size:.875rem;margin-bottom:1.25rem">Yakin ingin menghapus akun <strong id="deleteUsername"></strong>? Akun akan dihapus dari server.</p>
    <div style="display:flex;gap:.75rem">
      <button class="btn btn-outline" style="flex:1" onclick="closeModal('modalDelete')">Batal</button>
      <button class="btn btn-danger" style="flex:1" onclick="doDelete()" id="deleteBtn">Hapus</button>
    </div>
  </div>
</div>

<script>
let currentProto = 'vmess';
let currentDays = 7;
let currentTrialProto = 'vmess';
let deleteAkunId = null;
const pages = ['home','order','akun','topup','server','riwayat','setting'];
const pageTitles = {home:'Dashboard',order:'Order VPN',akun:'Akun VPN',topup:'Isi Saldo',server:'Status Server',riwayat:'Riwayat',setting:'Setting Akun'};

function showPage(p) {
  pages.forEach(n => document.getElementById('page-'+n).style.display = n===p?'':'none');
  document.getElementById('pageTitle').textContent = pageTitles[p]||p;
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  document.querySelector('.nav-item[onclick*="showPage(\''+p+'\')"]')?.classList.add('active');
  document.getElementById('pageAlert').innerHTML = '';
  if(window.innerWidth<=768) document.getElementById('sidebar').classList.remove('open');
  updateHarga();
}

function selectProto(btn) {
  document.querySelectorAll('#page-order .proto-btn[data-proto]').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active'); currentProto=btn.dataset.proto;
}
function selectTrialProto(btn) {
  document.querySelectorAll('#modalTrial .proto-btn[data-proto]').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active'); currentTrialProto=btn.dataset.proto;
}
function selectDuration(btn) {
  document.querySelectorAll('.proto-btn[data-days]').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active'); currentDays=parseInt(btn.dataset.days); updateHarga();
}
function updateHarga() {
  const sel=document.getElementById('orderServer');
  if(!sel) return;
  const opt=sel.options[sel.selectedIndex];
  if(!opt) return;
  const hPd=parseFloat(opt.dataset.hargaHari||0), hPm=parseFloat(opt.dataset.hargaBulan||0);
  let h = currentDays >= 30 ? (hPm * Math.floor(currentDays/30)) + (hPd * (currentDays%30)) : hPd * currentDays;
  document.getElementById('hargaVal').textContent='Rp '+new Intl.NumberFormat('id-ID').format(h);
}
document.getElementById('orderServer')?.addEventListener('change', updateHarga);
updateHarga();

function selectMethod(btn) {
  document.querySelectorAll('.method-btn').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  const m=btn.dataset.method;
  ['bankInfo','danaInfo','gopayInfo','shopeeInfo','qrisInfo'].forEach(id=>document.getElementById(id).style.display='none');
  const map={manual_transfer:'bankInfo',dana:'danaInfo',gopay:'gopayInfo',shopepay:'shopeeInfo',qris:'qrisInfo'};
  if(map[m]) document.getElementById(map[m]).style.display='';
}

function showModal(id){document.getElementById(id).classList.add('show');document.body.style.overflow='hidden';}
function closeModal(id){document.getElementById(id).classList.remove('show');document.body.style.overflow='';}
function showTrialModal(){showModal('modalTrial');document.getElementById('trialResult').classList.remove('show');}

function doOrder() {
  const username=document.getElementById('orderUsername').value.trim();
  const serverId=document.getElementById('orderServer').value;
  if(!username){showAlert('pageAlert','Username wajib diisi!','error');return;}
  const btn=document.getElementById('orderBtnTxt');
  btn.innerHTML='Memproses...';
  const fd=new FormData();
  fd.append('server_id',serverId); fd.append('tipe',currentProto);
  fd.append('username',username); fd.append('days',currentDays);
  fetch('/ordervpn/api/create_order.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    btn.innerHTML='Order Sekarang';
    const box=document.getElementById('orderResult');
    box.classList.add('show');
    if(res.success){
      box.innerHTML=buildResultHTML(res);
      var link = res.link_tls || res.link_nontls || res.link_grpc || '';
      var msg = 'Akun berhasil dibuat!';
      if(link) {
        navigator.clipboard?.writeText(link).catch(function(){});
        msg += ' Link config sudah di-copy.';
      }
      showAlert('pageAlert', msg, 'success');
      setTimeout(()=>{showPage('akun');location.reload();},4000);
    } else {
      box.innerHTML='<div class="alert alert-error">'+escHtml(res.message)+'</div>';
    }
  }).catch(()=>{btn.innerHTML='Order Sekarang';});
}

function doTrial() {
  const username=document.getElementById('trialUsername').value.trim();
  const serverId=document.getElementById('trialServer').value;
  if(!username){return;}
  const fd=new FormData();
  fd.append('server_id',serverId); fd.append('tipe',currentTrialProto);
  fd.append('username',username); fd.append('days',1); fd.append('is_trial',1);
  fetch('/ordervpn/api/create_order.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    const box=document.getElementById('trialResult');
    box.classList.add('show');
    if(res.success){
      box.innerHTML=buildResultHTML(res);
      var link = res.link_tls || res.link_nontls || res.link_grpc || '';
      if(link) navigator.clipboard?.writeText(link).catch(function(){});
    }
    else{box.innerHTML='<div class="alert alert-error">'+escHtml(res.message)+'</div>';}
  });
}

function buildResultHTML(res) {
  let html='<div class="alert alert-success" style="margin-bottom:.75rem">Akun berhasil dibuat!</div>';
  html+='<div class="result-row"><span class="result-key">Username</span><span class="result-val">'+escHtml(res.username||'')+'</span></div>';
  if(res.uuid) html+='<div class="result-row"><span class="result-key">UUID</span><span class="result-val" style="font-family:monospace;font-size:.75rem">'+escHtml(res.uuid)+'</span></div>';
  if(res.password) html+='<div class="result-row"><span class="result-key">Password</span><span class="result-val">'+escHtml(res.password)+'</span></div>';
  html+='<div class="result-row"><span class="result-key">Expired</span><span class="result-val">'+escHtml(res.expired||'')+'</span></div>';
  if(res.link_tls){html+='<p style="font-size:.72rem;color:var(--muted);margin:.5rem 0 .25rem">Link TLS:</p><div class="link-box" onclick="copyText(\''+escHtml(res.link_tls)+'\',this)">'+escHtml(res.link_tls)+'</div>';}
  if(res.link_nontls){html+='<p style="font-size:.72rem;color:var(--muted);margin:.5rem 0 .25rem">Link NonTLS:</p><div class="link-box" onclick="copyText(\''+escHtml(res.link_nontls)+'\',this)">'+escHtml(res.link_nontls)+'</div>';}
  if(res.link_grpc){html+='<p style="font-size:.72rem;color:var(--muted);margin:.5rem 0 .25rem">Link gRPC:</p><div class="link-box" onclick="copyText(\''+escHtml(res.link_grpc)+'\',this)">'+escHtml(res.link_grpc)+'</div>';}
  if(res.download){html+='<br><a href="'+escHtml(res.download)+'" target="_blank" class="btn btn-outline btn-sm" style="margin-top:.5rem">Download Config</a>';}
  return html;
}

function showAkunDetail(a) {
  if(!a) return;
  var html='';
  html+='<div class="result-row"><span class="result-key">Username</span><span class="result-val">'+escHtml(a.username||'')+'</span></div>';
  html+='<div class="result-row"><span class="result-key">Tipe</span><span class="result-val">'+escHtml(a.tipe||'').toUpperCase()+(a.is_trial?' (Trial)':'')+'</span></div>';
  if(a.uuid) html+='<div class="result-row"><span class="result-key">UUID</span><span class="result-val" style="font-family:monospace;font-size:.75rem">'+escHtml(a.uuid)+'</span></div>';
  if(a.password_vpn) html+='<div class="result-row"><span class="result-key">Password</span><span class="result-val">'+escHtml(a.password_vpn)+'</span></div>';
  html+='<div class="result-row"><span class="result-key">Server</span><span class="result-val">'+escHtml(a.nama_server||'')+'</span></div>';
  html+='<div class="result-row"><span class="result-key">Expired</span><span class="result-val">'+escHtml(a.masa_aktif||'')+'</span></div>';

  // Helper: create copyable link box
  var makeLinkBox = function(label, link) {
    if(!link) return '';
    var safe = escHtml(link);
    return '<p style="font-size:.72rem;color:var(--muted);margin:.75rem 0 .25rem">'+label+':</p>'+
      '<div style="display:flex;gap:6px;align-items:stretch">'+
      '<div class="link-box" style="flex:1;margin:0" onclick="copyText(\''+safe+'\',this)">'+safe+'</div>'+
      '<button class="btn btn-sm btn-primary" style="flex-shrink:0;padding:4px 10px" onclick="copyText(\''+safe+'\',this)">Salin</button>'+
      '</div>';
  };
  if(a.link_tls) html += makeLinkBox('Link TLS', a.link_tls);
  if(a.link_nontls) html += makeLinkBox('Link NonTLS', a.link_nontls);
  if(a.link_grpc) html += makeLinkBox('Link gRPC', a.link_grpc);

  var el = document.getElementById('akunDetailContent');
  if(el) { el.innerHTML=html; showModal('modalAkun'); }
}

function confirmDelete(id,name){deleteAkunId=id;document.getElementById('deleteUsername').textContent=name;showModal('modalDelete');}
function doDelete(){
  if(!deleteAkunId) return;
  document.getElementById('deleteBtn').innerHTML='Memproses...';
  fetch('/ordervpn/api/delete_account.php',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'akun_id='+deleteAkunId})
  .then(r=>r.json()).then(res=>{
    closeModal('modalDelete');
    if(res.success){showAlert('pageAlert','Akun berhasil dihapus dari server!','success');setTimeout(()=>location.reload(),1500);}
    else{showAlert('pageAlert',escHtml(res.message),'error');}
  }).catch(()=>{closeModal('modalDelete');});
}

function doTopup(){
  const amount=document.getElementById('topupAmount').value;
  const method=document.querySelector('.method-btn.active')?.dataset.method||'manual_transfer';
  if(!amount||amount<5000){document.getElementById('topupResult').innerHTML='<div class="alert alert-error">Nominal minimal Rp 5.000</div>';return;}
  const fd=new FormData();
  fd.append('amount',amount); fd.append('payment_method',method);
  const file=document.getElementById('buktiFile').files[0];
  if(file) fd.append('bukti',file);
  fetch('/ordervpn/api/topup.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    document.getElementById('topupResult').innerHTML=res.success
      ?'<div class="alert alert-success">'+escHtml(res.message)+'</div>'
      :'<div class="alert alert-error">'+escHtml(res.message)+'</div>';
  });
}

function saveProfile(){
  const email=document.getElementById('settingEmail').value;
  const wa=document.getElementById('settingWa').value;
  const pass=document.getElementById('settingPass').value;
  const passC=document.getElementById('settingPassConfirm').value;
  if(pass && pass!==passC){showAlert('settingAlert','Password tidak cocok!','error');return;}
  const fd=new FormData();
  fd.append('email',email); fd.append('whatsapp',wa);
  if(pass) fd.append('password',pass);
  fetch('/ordervpn/api/update_profile.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    showAlert('settingAlert',res.success?'Profil berhasil disimpan!':escHtml(res.message),res.success?'success':'error');
  });
}

function showAlert(containerId,msg,type){
  const el=document.getElementById(containerId);
  if(el){el.innerHTML='<div class="alert alert-'+type+'">'+msg+'</div>';setTimeout(()=>{el.innerHTML=''},5000);}
}
function copyText(text,el){
  navigator.clipboard?.writeText(text).then(()=>{
    const orig=el.innerHTML; el.innerHTML='Tersalin!'; setTimeout(()=>{el.innerHTML=orig},1500);
  }).catch(()=>{});
}
function escHtml(s){return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
</script>
</body>
</html>