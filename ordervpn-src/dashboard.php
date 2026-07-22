<?php
require_once __DIR__.'/includes/config.php';
$session = requireLogin();
$db = getDB();

$userId = $session['user_id'];
$username = $session['username'];
$role = $session['role'];

// Ambil data user fresh
$u = $db->prepare("SELECT * FROM users WHERE id=?");
$u->execute([$userId]); $user = $u->fetch();

// Statistik
$totalAkun = $db->prepare("SELECT COUNT(*) FROM vpn_accounts WHERE user_id=? AND status='active'");
$totalAkun->execute([$userId]); $totalAkun = $totalAkun->fetchColumn();

$totalTrx = $db->prepare("SELECT COUNT(*) FROM transactions WHERE user_id=?");
$totalTrx->execute([$userId]); $totalTrx = $totalTrx->fetchColumn();

$totalTopup = $db->prepare("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE user_id=? AND type='topup' AND status='success'");
$totalTopup->execute([$userId]); $totalTopup = $totalTopup->fetchColumn();

// Akun aktif terbaru
$akuns = $db->prepare("SELECT va.*, s.name AS nama_server, s.region AS lokasi, s.flag FROM vpn_accounts va 
    JOIN servers s ON va.server_id=s.id 
    WHERE va.user_id=? AND va.status='active' ORDER BY va.created_at DESC LIMIT 5");
$akuns->execute([$userId]); $akuns = $akuns->fetchAll();

// Transaksi terbaru
$trxs = $db->prepare("SELECT * FROM transactions WHERE user_id=? ORDER BY created_at DESC LIMIT 5");
$trxs->execute([$userId]); $trxs = $trxs->fetchAll();

// Servers untuk order
$servers = $db->query("SELECT * FROM servers WHERE status='ready' ORDER BY name")->fetchAll();

$appName = getSetting('app_name','OrderVPN');
$appLogo = getSetting('app_logo','[SIG]');
$contactWa = getSetting('contact_wa');
$contactTg = getSetting('contact_tg');

// Trial sudah dipakai hari ini?
$trialUsed = $db->prepare("SELECT COUNT(*) FROM vpn_accounts WHERE user_id=? AND is_trial=1 AND DATE(created_at)=CURDATE()");
$trialUsed->execute([$userId]); $trialUsed = (int)$trialUsed->fetchColumn();

$showGithub = true;
$wcDomains = $db->query("SELECT * FROM wildcard_domains ORDER BY domain ASC")->fetchAll();
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title><?=$appName?> — Dashboard</title>
<link rel="stylesheet" href="assets/css/style.css">
</head>
<body>

<!-- Sidebar -->
<div class="sidebar-backdrop" id="sidebarBackdrop" onclick="document.getElementById('sidebar').classList.remove('open');this.classList.remove('show')"></div>
<aside class="sidebar" id="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon" style="width:36px;height:36px;border-radius:8px">
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2"/></svg>
    </div>
    <div><h1><?=$appName?></h1><p>Premium VPN Service</p></div>
  </div>
  <nav>
    <div class="nav-section">Menu</div>
    <button class="nav-item active" onclick="showPage('home')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg></span> Dashboard</button>
    <button class="nav-item" onclick="showPage('order')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg></span> Order VPN</button>
    <button class="nav-item" onclick="showPage('akun')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg></span> Akun VPN <span class="nav-badge"><?=$totalAkun?></span></button>
    <button class="nav-item" onclick="showPage('topup')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></svg></span> Isi Saldo</button>
    <div class="nav-section">Info</div>
    <button class="nav-item" onclick="showPage('server')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg></span> Status Server</button>
    <button class="nav-item" onclick="showPage('wildcard')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg></span> Wildcard</button>
    <button class="nav-item" onclick="showPage('riwayat')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg></span> Riwayat</button>
    <button class="nav-item" onclick="showPage('setting')"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg></span> Setting Akun</button>
    <?php if($role==='admin'):?>
    <div class="nav-section">Admin</div>
    <a class="nav-item" href="/admin/"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg></span> Admin Panel</a>
    <?php endif;?>
  </nav>
  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-avatar" style="overflow:hidden;background:linear-gradient(135deg,#6366f1,#8b5cf6)"><?php if(!empty($user['avatar'])):?><img src="<?=esc($user['avatar'])?>" style="width:100%;height:100%;object-fit:cover;border-radius:8px"><?php else:?><?=strtoupper(substr($username,0,1))?><?php endif;?></div>
      <div><div class="user-name"><?=esc($username)?></div>
        <div class="user-role"><?=$role==='admin'?'<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:2px"><path d="M2 20l3-15 7 5 7-5 3 15H2z"/></svg> Admin':'<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:2px"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg> User'?></div></div>
    </div>
    <a href="/api/logout.php" class="nav-item" style="margin-top:.75rem;color:var(--red)"><span class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg></span> Logout</a>
  </div>
</aside>

<!-- Main -->
<div class="main">
  <div class="topbar">
    <div style="display:flex;align-items:center;gap:.75rem">
      <button class="hamburger" onclick="toggleSidebar()"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg></button>
      <span class="topbar-title" id="pageTitle">Dashboard</span>
    </div>
    <div class="saldo-chip"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:4px"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></svg> <?=formatRupiah($user['saldo'])?></div>
  </div>

  <div class="content">

    <!-- ANNOUNCEMENT TOAST -->
    <?php
    $_announcements = [];
    for ($_i=1; $_i<=3; $_i++) {
        $_val = getSetting('announce_'.$_i, '');
        if ($_val) {
            $_parts = explode('|', $_val, 2);
            $_announcements[] = ['badge' => $_parts[0] ?? 'INFO', 'text' => $_parts[1] ?? $_parts[0]];
        }
    }
    if ($_announcements):?>
    <div id="announceToast" style="position:relative;margin-bottom:.75rem;overflow:hidden;border-radius:12px;border:1px solid rgba(99,102,241,0.15);background:linear-gradient(135deg,rgba(99,102,241,0.08),rgba(139,92,246,0.08));transition:opacity .4s ease,transform .4s ease">
      <div style="display:flex;flex-direction:column;gap:.35rem;padding:.75rem 1rem">
        <?php foreach($_announcements as $_a):?>
        <div style="display:flex;align-items:center;gap:.5rem;font-size:.82rem;color:var(--text)">
          <span style="display:inline-block;padding:.15rem .5rem;border-radius:4px;font-size:.65rem;font-weight:700;text-transform:uppercase;background:<?php if($_a['badge']==='PROMO'):?>linear-gradient(135deg,#f59e0b,#ef4444)<?php elseif($_a['badge']==='BARU'):?>linear-gradient(135deg,#22c55e,#16a34a)<?php else:?>linear-gradient(135deg,#6366f1,#8b5cf6)<?php endif;?>;color:#fff;flex-shrink:0"><?=esc($_a['badge'])?></span>
          <span><?=esc($_a['text'])?></span>
        </div>
        <?php endforeach;?>
      </div>
      <button onclick="document.getElementById('announceToast').style.display='none'" style="position:absolute;top:6px;right:8px;background:none;border:none;color:var(--muted);font-size:1.1rem;cursor:pointer;line-height:1;padding:2px">&times;</button>
    </div>
    <script>
    setTimeout(function(){
      var el=document.getElementById('announceToast');
      if(el){el.style.opacity='0';el.style.transform='translateY(-10px)';setTimeout(function(){if(el)el.style.display='none'},400);}
    },<?=(int)(getSetting('announce_duration','7')*1000)?>);
    </script>
    <?php endif;?>

    <!-- ALERT -->
    <div id="pageAlert"></div>

    <!-- PAGE: HOME -->
    <div id="page-home">
      <div class="stats">
        <div class="stat-card blue"><div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg></div><div class="stat-val"><?=$totalAkun?></div><div class="stat-label">Akun Aktif</div></div>
        <div class="stat-card green"><div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></svg></div><div class="stat-val"><?=formatRupiah($user['saldo'])?></div><div class="stat-label">Saldo</div></div>
        <div class="stat-card purple"><div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg></div><div class="stat-val"><?=$totalTrx?></div><div class="stat-label">Total Transaksi</div></div>
        <div class="stat-card yellow"><div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg></div><div class="stat-val"><?=formatRupiah($totalTopup)?></div><div class="stat-label">Total Topup</div></div>
      </div>
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>Informasi Akun</div></div>
        <div class="card-body">
          <div style="display:flex;align-items:center;gap:1rem">
            <div style="width:56px;height:56px;border-radius:14px;overflow:hidden;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:1.5rem;font-weight:700;color:#fff;flex-shrink:0">
              <?php if(!empty($user['avatar'])):?><img src="<?=esc($user['avatar'])?>" style="width:100%;height:100%;object-fit:cover"><?php else:?><?=strtoupper(substr($username,0,1))?><?php endif;?>
            </div>
            <div><div style="font-weight:700;font-size:1rem"><?=esc($user['username'])?></div>
              <div style="font-size:.82rem;color:var(--muted)"><?=esc($user['email'])?><?php if($user['whatsapp']):?> · <?=esc($user['whatsapp'])?><?php endif;?></div>
              <div style="font-size:.75rem;color:var(--muted);margin-top:.2rem">Bergabung <?=date('d M Y',strtotime($user['created_at']))?></div>
            </div>
          </div>
        </div>
      </div>
      <?php if($contactWa||$contactTg||$contactIg): $_adminName = getSetting('app_name','Admin');?>
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>Admin</div></div>
        <div class="card-body">
          <div style="display:flex;flex-direction:column;gap:.65rem">
            <div style="font-weight:700;font-size:.9rem;color:var(--accent)"><?=esc($_adminName)?></div>
            <?php if($contactTg):?><div style="display:flex;align-items:center;gap:.7rem"><svg width="18" height="18" viewBox="0 0 24 24" fill="#24A1DE"><path d="M9.78 18.65l.28-4.23 7.68-6.92c.34-.31-.07-.46-.52-.19L7.74 13.3 3.64 11.96c-1.29-.4-1.29-1.29.28-1.91l15.77-6.08c1.08-.43 2.01.24 1.66 2.17l-2.66 12.6c-.22 1.04-.86 1.29-1.75.8l-4.82-3.56-2.33 2.26c-.26.26-.47.47-.91.47z"/></svg><span style="font-size:.85rem"><?=esc(ltrim($contactTg,'@'))?></span></div><?php endif;?>
            <?php if($contactWa):?><div style="display:flex;align-items:center;gap:.7rem"><svg width="18" height="18" viewBox="0 0 24 24" fill="#25D366"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg><span style="font-size:.85rem"><?=esc($contactWa)?></span></div><?php endif;?>
            <?php if($contactIg):?><div style="display:flex;align-items:center;gap:.7rem"><svg width="18" height="18" viewBox="0 0 24 24" fill="#E4405F"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg><span style="font-size:.85rem"><?=esc(ltrim($contactIg,'@'))?></span></div><?php endif;?>
          </div>
        </div>
      </div>
      <?php endif;?>
      <div class="card" style="background:linear-gradient(135deg,rgba(99,102,241,0.08),rgba(139,92,246,0.08));border:1px solid rgba(99,102,241,.15)">
        <div class="card-body">
          <div style="display:flex;align-items:flex-start;gap:.85rem">
            <div style="width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;flex-shrink:0">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="#fff"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>
            </div>
            <div>
              <div style="font-weight:700;font-size:.9rem;color:var(--text);margin-bottom:.35rem">Script Tunneling Gratis!</div>
              <p style="font-size:.82rem;color:var(--muted);line-height:1.6;margin:0">
                Ingin menggunakan script ini? Bisa <strong>install gratis</strong>, tidak perlu izin IP dan tanpa password. 
                Jangan lupa kasi bintang di GitHub ya! Terima kasih sudah menggunakan script tunneling dari kami.
              </p>
              <a href="https://github.com/putrinuroktavia234-max/Tunnel.git" target="_blank" style="display:inline-flex;align-items:center;gap:.4rem;margin-top:.75rem;padding:.5rem 1.1rem;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;border-radius:8px;text-decoration:none;font-size:.82rem;font-weight:600">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>
                Kasi Bintang di GitHub
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- PAGE: WILDCARD -->
    <div id="page-wildcard" style="display:none">
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>Domain Wildcard</div></div>
        <div class="card-body">
          <?php if($wcDomains):?>
          <p style="font-size:.85rem;color:var(--muted);margin-bottom:.75rem">Domain wildcard yang tersedia untuk konfigurasi akun VPN kamu:</p>
          <?php foreach($wcDomains as $w):?>
          <div style="display:flex;align-items:center;gap:.75rem;padding:.6rem .85rem;background:var(--card2);border-radius:8px;margin-bottom:.4rem">
            <span style="width:36px;height:36px;border-radius:8px;background:rgba(99,102,241,0.12);display:flex;align-items:center;justify-content:center;flex-shrink:0"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg></span>
            <div><div style="font-family:monospace;font-size:.85rem;font-weight:600"><?=esc($w['domain'])?></div><?php if($w['keterangan']):?><div style="font-size:.75rem;color:var(--muted)"><?=esc($w['keterangan'])?></div><?php endif;?></div>
          </div>
          <?php endforeach;?>
          <?php else:?>
          <div class="empty-state"><div class="icon"><svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg></div><p>Belum ada domain wildcard</p></div>
          <?php endif;?>
        </div>
      </div>
    </div>

    <!-- PAGE: ORDER -->
    <div id="page-order" style="display:none">
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>Order VPN</div></div>
        <div class="card-body">
          <?php if(empty($servers)):?><div class="alert alert-error">Tidak ada server tersedia saat ini.</div>
          <?php else:?>
          <div class="form-group"><label class="lbl">Pilih Server</label>
            <select id="orderServer">
              <?php foreach($servers as $s):?>
              <option value="<?=$s['id']?>" data-harga-hari="<?=$s['harga_hari']?>" data-harga-bulan="<?=$s['harga_bulan']?>" data-name="<?=esc($s['nama_server'])?>"><?=$s['flag']??'&#127470;&#127465;'?> <?=esc($s['nama_server'])?> — <?=esc($s['lokasi'])?></option>
              <?php endforeach;?>
            </select>
          </div>
          <div class="form-group"><label class="lbl">Protokol</label>
            <div class="proto-grid">
              <button class="proto-btn active" data-proto="vmess" onclick="selectProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg></span>VMess</button>
              <button class="proto-btn" data-proto="vless" onclick="selectProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg></span>VLess</button>
              <button class="proto-btn" data-proto="trojan" onclick="selectProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></span>Trojan</button>
              <button class="proto-btn" data-proto="ssh" onclick="selectProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg></span>SSH</button>
            </div>
          </div>
          <div class="form-group"><label class="lbl">Durasi</label>
            <div class="proto-grid">
              <button class="proto-btn active" data-days="7" onclick="selectDuration(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></span>7 Hari</button>
              <button class="proto-btn" data-days="30" onclick="selectDuration(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></span>30 Hari</button>
              <button class="proto-btn" data-days="60" onclick="selectDuration(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></span>60 Hari</button>
              <button class="proto-btn" data-days="90" onclick="selectDuration(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></span>90 Hari</button>
            </div>
          </div>
          <div class="form-group"><label class="lbl">Username</label>
            <input type="text" id="orderUsername" placeholder="Buat username (huruf, angka, _)" oninput="this.value=this.value.replace(/[^a-zA-Z0-9_\-]/g,'')"></div>
          <div class="form-group"><label class="lbl">Kode Promo <span style="color:var(--muted);font-size:.7rem">(opsional)</span></label>
            <div style="display:flex;gap:.5rem">
              <input type="text" id="promoCode" placeholder="Masukkan kode promo" style="text-transform:uppercase;flex:1" oninput="this.value=this.value.toUpperCase()">
              <button type="button" class="btn btn-outline" onclick="applyPromo()" id="promoBtn" style="padding:.5rem .8rem;font-size:.82rem">Cek</button>
            </div>
            <div id="promoStatus" style="font-size:.78rem;margin-top:.35rem"></div>
          </div>
          <div id="orderHarga" style="background:#0a1628;border:1px solid var(--border);border-radius:10px;padding:1rem;margin:.75rem 0;display:flex;justify-content:space-between;align-items:center">
            <span style="color:var(--muted);font-size:.875rem">Total Harga</span>
            <span id="hargaVal" style="font-size:1.1rem;font-weight:800;color:var(--green)">Rp 0</span>
          </div>
          <div class="order-actions" style="display:flex;gap:.75rem">
            <button class="btn btn-primary" style="flex:1" onclick="doOrder()"><span id="orderBtnTxt"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:4px"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>Order Sekarang</span></button>
            <?php if($trialUsed===0):?>
            <button class="btn btn-outline" onclick="showTrialModal()" title="Trial 1 jam gratis"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:4px"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>Trial</button>
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
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>Semua Akun VPN</div></div>
        <div class="card-body" id="akunList">
          <?php
          $allAkuns = $db->prepare("SELECT va.*, s.name AS nama_server, s.flag, s.region AS lokasi FROM vpn_accounts va JOIN servers s ON va.server_id=s.id WHERE va.user_id=? ORDER BY va.status ASC, va.masa_aktif ASC");
          $allAkuns->execute([$userId]); $allAkuns=$allAkuns->fetchAll();
          if(empty($allAkuns)):?><div class="empty-state"><div class="icon"><svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg></div><p>Belum ada akun</p></div>
          <?php else: foreach($allAkuns as $a):
            $exp=strtotime($a['masa_aktif']); $sisa=ceil(($exp-time())/86400);
            $expClass=$sisa>7?'exp-ok':($sisa>3?'exp-warn':'exp-danger');
          ?>
          <div class="akun-item">
            <span class="akun-badge badge-<?=$a['tipe']?>"><?=strtoupper($a['tipe'])?><?=$a['is_trial']?' <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><line x1="12" y1="22" x2="12" y2="7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>':''?></span>
            <div class="akun-info">
              <div class="akun-name"><?=esc($a['username'])?></div>
              <div class="akun-meta"><?=$a['flag']??'&#127470;&#127465;'?> <?=esc($a['nama_server'])?> · <?=esc($a['status'])?></div>
            </div>
            <div style="display:flex;flex-direction:column;align-items:flex-end;gap:.3rem">
              <div class="akun-exp <?=$expClass?>"><?=$a['is_trial']?'<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:2px"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> Trial':($a['status']==='active'?'<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:2px"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> '.$sisa.' hari':'<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:2px"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg> Expired')?></div>
              <div style="display:flex;gap:.35rem">
                <button class="btn btn-sm btn-outline" onclick="showAkunDetail(<?=json_encode($a)?>)"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
                <?php if($a['status']==='active'):?>
                <button class="btn btn-sm btn-red" onclick="confirmDelete(<?=$a['id']?>, '<?=esc($a['username'])?>','<?=$a['tipe']?>')"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg></button>
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
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></svg>Isi Saldo</div></div>
        <div class="card-body">
          <div class="form-group"><label class="lbl">Nominal Topup</label>
            <input type="number" id="topupAmount" placeholder="Min. Rp 5.000" min="5000" step="1000"></div>
          <div class="form-group"><label class="lbl">Metode Pembayaran</label>
            <div class="topup-methods" id="topupMethods">
              <button class="method-btn active" data-method="manual_transfer" onclick="selectMethod(this)"><span class="m-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><line x1="9" y1="22" x2="15" y2="22"/><line x1="8" y1="6" x2="16" y2="6"/><line x1="8" y1="10" x2="16" y2="10"/><line x1="8" y1="14" x2="12" y2="14"/></svg></span><span class="m-name">Transfer Bank</span></button>
              <?php if(getSetting('qris_image')):?><button class="method-btn" data-method="qris" onclick="selectMethod(this)"><span class="m-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg></span><span class="m-name">QRIS</span></button><?php endif;?>
              <?php if(getSetting('dana_number')):?><button class="method-btn" data-method="dana" onclick="selectMethod(this)"><span class="m-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></span><span class="m-name">Dana</span></button><?php endif;?>
              <?php if(getSetting('gopay_number')):?><button class="method-btn" data-method="gopay" onclick="selectMethod(this)"><span class="m-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></span><span class="m-name">GoPay</span></button><?php endif;?>
              <?php if(getSetting('shopee_number')):?><button class="method-btn" data-method="shopepay" onclick="selectMethod(this)"><span class="m-icon"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></span><span class="m-name">ShopeePay</span></button><?php endif;?>
            </div>
          </div>
          <div id="paymentInfo" style="background:#0a1628;border:1px solid var(--border);border-radius:10px;padding:1rem;margin:.75rem 0">
            <div id="bankInfo">
              <p style="font-size:.8rem;color:var(--muted);margin-bottom:.5rem">Transfer ke rekening berikut:</p>
              <p style="font-weight:700"><?=getSetting('bank_name')?> — <?=getSetting('bank_account')?></p>
              <p style="color:var(--muted);font-size:.875rem">a/n <?=getSetting('bank_holder')?></p>
            </div>
            <div id="danaInfo" style="display:none"><p style="font-weight:700">Dana: <?=getSetting('dana_number')?></p></div>
            <div id="gopayInfo" style="display:none"><p style="font-weight:700">GoPay: <?=getSetting('gopay_number')?></p></div>
            <div id="shopeeInfo" style="display:none"><p style="font-weight:700">ShopeePay: <?=getSetting('shopee_number')?></p></div>
            <div id="qrisInfo" style="display:none">
              <?php if(getSetting('qris_image')):?><img src="<?=esc(getSetting('qris_image'))?>" style="max-width:200px;border-radius:8px;margin-top:.5rem"><?php endif;?>
            </div>
          </div>
          <div class="form-group"><label class="lbl">Upload Bukti Transfer (opsional)</label>
            <input type="file" id="buktiFile" accept="image/*"></div>
          <button class="btn btn-primary" style="width:100%" onclick="doTopup()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>Kirim Permintaan Topup</button>
          <div id="topupResult" style="margin-top:1rem"></div>
        </div>
      </div>
    </div>

    <!-- PAGE: SERVER -->
    <div id="page-server" style="display:none">
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>Status Server</div></div>
        <div class="card-body">
          <?php foreach($servers as $s): $st=$s['status'];?>
          <div class="akun-item">
            <div><?=$s['flag']??'&#127470;&#127465;'?></div>
            <div class="akun-info">
              <div class="akun-name"><?=esc($s['nama_server'])?></div>
              <div class="akun-meta"><?=esc($s['lokasi'])?> · <?=esc($s['code_server'])?></div>
            </div>
            <div style="text-align:right">
              <span><span class="server-status s-<?=$st?>"></span><?=$st==='ready'?'Online':($st==='maintenance'?'Maintenance':'Offline')?></span>
              <div style="font-size:.75rem;color:var(--muted);margin-top:.2rem"><?=formatRupiah($s['harga_hari'])?>/hari · <?=formatRupiah($s['harga_bulan'])?>/bulan</div>
            </div>
          </div>
          <?php endforeach;?>
        </div>
      </div>
    </div>
    </div>

    <!-- PAGE: RIWAYAT -->
    <div id="page-riwayat" style="display:none">
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>Riwayat Transaksi</div></div>
        <div class="card-body">
          <?php $allTrx=$db->prepare("SELECT * FROM transactions WHERE user_id=? ORDER BY created_at DESC LIMIT 50");
          $allTrx->execute([$userId]); $allTrx=$allTrx->fetchAll();
          if(empty($allTrx)):?><div class="empty-state"><div class="icon"><svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg></div><p>Belum ada transaksi</p></div>
          <?php else: foreach($allTrx as $t):?>
          <div class="trx-item trx-<?=$t['type']?>">
            <div class="trx-icon"><?=$t['type']==='topup'?'<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/></svg>':($t['type']==='refund'?'<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>':'<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>')?></div>
            <div class="trx-info"><div class="trx-desc"><?=esc($t['keterangan']??ucfirst($t['type']))?></div>
              <div class="trx-date"><?=date('d M Y, H:i',strtotime($t['created_at']))?> · <?=$t['status']?></div></div>
            <div class="trx-amount" style="color:<?=$t['type']==='topup'||$t['type']==='refund'?'var(--green)':'var(--red)'?>"><?=$t['type']==='topup'||$t['type']==='refund'?'+':'-'?><?=formatRupiah($t['amount'])?></div>
          </div>
          <?php endforeach; endif;?>
        </div>
      </div>
    </div>

    <!-- PAGE: SETTING -->
    <div id="page-setting" style="display:none">
      <div class="card">
        <div class="card-header"><div class="card-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>Setting Akun</div></div>
        <div class="card-body">
            <div id="settingAlert"></div>
          <form id="profileForm">
            <div class="form-group"><label class="lbl">Foto Profil</label>
              <div style="display:flex;align-items:center;gap:1rem">
                <div style="width:64px;height:64px;border-radius:12px;overflow:hidden;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:1.5rem;font-weight:700;color:#fff;flex-shrink:0">
                  <?php if(!empty($user['avatar'])):?><img src="<?=esc($user['avatar'])?>" style="width:100%;height:100%;object-fit:cover"><?php else:?><?=strtoupper(substr($username,0,1))?><?php endif;?>
                </div>
                <div>
                  <input type="file" id="avatarFile" accept="image/*" style="font-size:.82rem">
                  <button type="button" class="btn btn-sm btn-outline" onclick="uploadAvatar()" style="margin-top:.35rem"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:3px"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg> Upload</button>
                  <?php if(!empty($user['avatar'])):?><button type="button" class="btn btn-sm btn-red" onclick="deleteAvatar()" style="margin-top:.35rem"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:3px"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Hapus</button><?php endif;?>
                </div>
              </div>
            </div>
            <div class="form-group"><label class="lbl">Username</label>
              <input type="text" value="<?=esc($user['username'])?>" disabled style="opacity:.5"></div>
            <div class="form-group"><label class="lbl">Email</label>
              <input type="email" id="settingEmail" value="<?=esc($user['email'])?>"></div>
            <div class="form-group"><label class="lbl">WhatsApp (opsional)</label>
              <input type="text" id="settingWa" value="<?=esc($user['whatsapp']??'')?>" placeholder="08xxxxxxxxxx"></div>
            <div class="form-group"><label class="lbl">Password Baru (kosongkan jika tidak diganti)</label>
              <input type="password" id="settingPass" placeholder="••••••••"></div>
            <div class="form-group"><label class="lbl">Konfirmasi Password Baru</label>
              <input type="password" id="settingPassConfirm" placeholder="••••••••"></div>
            <button type="button" class="btn btn-primary" onclick="saveProfile()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Simpan Perubahan</button>
          </form>
        </div>
      </div>
    </div>

  </div><!-- .content -->
</div><!-- .main -->

<!-- MODAL: GitHub CTA -->
<div class="modal" id="modalGithub">
  <div class="modal-backdrop" onclick="closeModal('modalGithub')"></div>
  <div class="modal-box" style="max-width:460px">
    <button class="modal-close" onclick="closeModal('modalGithub')"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
    <div style="text-align:center;padding:.5rem 0">
      <div style="width:56px;height:56px;border-radius:16px;background:linear-gradient(135deg,rgba(99,102,241,0.15),rgba(139,92,246,0.15));display:flex;align-items:center;justify-content:center;margin:0 auto 1rem">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="#818cf8"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>
      </div>
      <div style="font-weight:800;font-size:1.15rem;color:var(--text);margin-bottom:.4rem">Script Tunneling Gratis!</div>
      <div style="font-size:.85rem;color:var(--text-muted);margin-bottom:1.25rem;line-height:1.6">Dapatkan script tunneling premium ini secara <strong>GRATIS</strong>! Full fitur, multi-protokol, siap install di VPS kamu.</div>
      <a href="https://github.com/putrinuroktavia234-max/Tunnel.git" target="_blank" style="display:inline-flex;align-items:center;gap:.5rem;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;padding:.6rem 1.5rem;border-radius:10px;font-size:.85rem;font-weight:700;text-decoration:none">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>
        Ambil Script di GitHub
      </a>
      <div style="margin-top:1rem"><button class="btn btn-outline" style="font-size:.78rem" onclick="closeModal('modalGithub')">Nanti Saja</button></div>
    </div>
  </div>
</div>

<!-- MODAL: Akun Detail -->
<div class="modal" id="modalAkun">
  <div class="modal-backdrop" onclick="closeModal('modalAkun')"></div>
  <div class="modal-box">
    <button class="modal-close" onclick="closeModal('modalAkun')"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
    <div class="modal-title"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-5px;margin-right:6px"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>Detail Akun VPN</div>
    <div id="akunDetailContent"></div>
  </div>
</div>

<!-- MODAL: Trial -->
<div class="modal" id="modalTrial">
  <div class="modal-backdrop" onclick="closeModal('modalTrial')"></div>
  <div class="modal-box">
    <button class="modal-close" onclick="closeModal('modalTrial')"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
    <div class="modal-title"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-5px;margin-right:6px"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>Trial VPN Gratis</div>
    <div class="alert alert-info" style="font-size:.82rem">Trial 1 jam gratis, 1x per hari, quota 1GB.</div>
    <div class="form-group"><label class="lbl">Server</label>
      <select id="trialServer">
        <?php foreach($servers as $s):?><option value="<?=$s['id']?>"><?=$s['flag']??'&#127470;&#127465;'?> <?=esc($s['nama_server'])?></option><?php endforeach;?>
      </select></div>
    <div class="form-group"><label class="lbl">Protokol</label>
      <div class="proto-grid">
        <button class="proto-btn active" data-proto="vmess" onclick="selectTrialProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg></span>VMess</button>
        <button class="proto-btn" data-proto="vless" onclick="selectTrialProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg></span>VLess</button>
        <button class="proto-btn" data-proto="trojan" onclick="selectTrialProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></span>Trojan</button>
        <button class="proto-btn" data-proto="ssh" onclick="selectTrialProto(this)"><span class="icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg></span>SSH</button>
      </div></div>
    <div class="form-group"><label class="lbl">Username</label>
      <input type="text" id="trialUsername" placeholder="Buat username trial"></div>
    <button class="btn btn-primary" style="width:100%;margin-top:.5rem" onclick="doTrial()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:4px"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>Ambil Trial Gratis</button>
    <div id="trialResult" class="result-box"></div>
  </div>
</div>

<!-- MODAL: Konfirmasi Delete -->
<div class="modal" id="modalDelete">
  <div class="modal-backdrop" onclick="closeModal('modalDelete')"></div>
  <div class="modal-box" style="max-width:380px">
    <div class="modal-title"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-4px;margin-right:6px"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>Hapus Akun</div>
    <p style="color:var(--muted);font-size:.875rem;margin-bottom:1.25rem">Yakin ingin menghapus akun <strong id="deleteUsername"></strong>? Akun akan dihapus dari server.</p>
    <div style="display:flex;gap:.75rem">
      <button class="btn btn-outline" style="flex:1" onclick="closeModal('modalDelete')">Batal</button>
      <button class="btn btn-red" style="flex:1" onclick="doDelete()" id="deleteBtn"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:4px"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>Hapus</button>
    </div>
  </div>
</div>

<script>
const SVG = {
  cart: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:3px"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>',
  ok: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:3px"><path d="M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z"/><polyline points="9 12 11 14 15 10"/></svg>',
  no: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px;margin-right:3px"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>',
  gift: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-2px;margin-right:2px"><polyline points="20 12 20 22 4 22 4 12"/><rect x="2" y="7" width="20" height="5"/><line x1="12" y1="22" x2="12" y2="7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>',
  eye: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>',
  trash: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
  dl: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>',
  check: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>',
  copy: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
  terminal: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>'
};
let currentProto = 'vmess';
let currentDays = 7;
let currentTrialProto = 'vmess';
let deleteAkunId = null;
let deleteAkunType = null;
const pages = ['home','order','akun','topup','server','wildcard','riwayat','setting'];
const pageTitles = {home:'Dashboard',order:'Order VPN',akun:'Akun VPN',topup:'Isi Saldo',server:'Status Server',wildcard:'Wildcard',riwayat:'Riwayat',setting:'Setting Akun'};

function showPage(p) {
  pages.forEach(n => document.getElementById('page-'+n).style.display = n===p?'':'none');
  document.getElementById('pageTitle').textContent = pageTitles[p]||p;
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  document.getElementById('pageAlert').innerHTML = '';
  if(window.innerWidth<=768){document.getElementById('sidebar').classList.remove('open');document.getElementById('sidebarBackdrop').classList.remove('show');}
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
document.getElementById('orderServer')?.addEventListener('change', function(){updateHarga();applyPromo(true)});
updateHarga();

let promoApplied = null;

function applyPromo(skipAlert) {
  const code = document.getElementById('promoCode').value.trim();
  const status = document.getElementById('promoStatus');
  const btn = document.getElementById('promoBtn');
  if (!code) {
    promoApplied = null;
    status.innerHTML = '';
    updateHarga();
    return;
  }
  btn.disabled = true;
  btn.innerHTML = '<span class="loading"></span>';
  fetch('/api/check_promo.php', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:'code='+encodeURIComponent(code)})
  .then(r=>r.json()).then(res=>{
    if(res.success) {
      promoApplied = res.data;
      status.innerHTML = '<span style="color:var(--success)">&#10003; '+res.data.label+'</span>';
      updateHarga();
    } else {
      promoApplied = null;
      if(!skipAlert) status.innerHTML = '<span style="color:var(--danger)">&#10007; '+escHtml(res.message)+'</span>';
      updateHarga();
    }
  }).catch(()=>{promoApplied=null;}).finally(()=>{btn.disabled=false;btn.innerHTML='Cek'});
}

function updateHarga() {
  const sel=document.getElementById('orderServer');
  if(!sel) return;
  const opt=sel.options[sel.selectedIndex];
  if(!opt) return;
  const hPd=parseFloat(opt.dataset.hargaHari||0), hPm=parseFloat(opt.dataset.hargaBulan||0);
  let h = currentDays >= 30 ? (hPm * Math.floor(currentDays/30)) + (hPd * (currentDays%30)) : hPd * currentDays;
  let diskon = 0;
  let el = document.getElementById('hargaVal');
  if(promoApplied) {
    if(promoApplied.type==='percent') diskon = Math.floor(h * promoApplied.val / 100);
    else diskon = promoApplied.val;
    if(diskon > h) diskon = h;
    let total = h - diskon;
    el.innerHTML = '<span style="text-decoration:line-through;color:var(--muted);font-size:.85rem;font-weight:400;margin-right:6px">Rp '+new Intl.NumberFormat('id-ID').format(h)+'</span> Rp '+new Intl.NumberFormat('id-ID').format(total);
  } else {
    el.innerHTML = 'Rp '+new Intl.NumberFormat('id-ID').format(h);
  }
}

function selectMethod(btn) {
  document.querySelectorAll('.method-btn').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  const m=btn.dataset.method;
  ['bankInfo','danaInfo','gopayInfo','shopeeInfo','qrisInfo'].forEach(id=>document.getElementById(id).style.display='none');
  const map={manual_transfer:'bankInfo',dana:'danaInfo',gopay:'gopayInfo',shopepay:'shopeeInfo',qris:'qrisInfo'};
  if(map[m]) document.getElementById(map[m]).style.display='';
}

function toggleSidebar(){
  const s=document.getElementById('sidebar');
  const b=document.getElementById('sidebarBackdrop');
  s.classList.toggle('open');
  b.classList.toggle('show',s.classList.contains('open'));
}
function showModal(id){document.getElementById(id).classList.add('show')}
function closeModal(id){document.getElementById(id).classList.remove('show')}
function showTrialModal(){showModal('modalTrial');document.getElementById('trialResult').classList.remove('show')}
<?php if ($showGithub):?>showModal('modalGithub');<?php endif;?>

function doOrder() {
  const username=document.getElementById('orderUsername').value.trim();
  const serverId=document.getElementById('orderServer').value;
  if(!username){showAlert('pageAlert','Username wajib diisi!','error');return;}
  const btn=document.getElementById('orderBtnTxt');
  btn.innerHTML='<span class="loading"></span> Memproses...';
  const fd=new FormData();
  fd.append('server_id',serverId); fd.append('tipe',currentProto);
  fd.append('username',username); fd.append('days',currentDays);
  if(promoApplied) fd.append('promo_code',promoApplied.code);
  fetch('/api/create_order.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    btn.innerHTML=SVG.cart+' Order Sekarang';
    if(res.success){
      let sel=document.getElementById('orderServer');
      let opt=sel.options[sel.selectedIndex];
      res.tipe = currentProto;
      res.server = opt?.dataset?.name||'';
      document.getElementById('akunDetailContent').innerHTML = buildDetailHTML(res, true);
      document.querySelector('#modalAkun .modal-title').innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-5px;margin-right:6px"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>Akun Berhasil Dibuat';
      showModal('modalAkun');
      showAlert('pageAlert',SVG.ok+' Akun berhasil dibuat!','success');
    } else {
      const box=document.getElementById('orderResult');
      box.innerHTML='<div class="alert alert-error">'+SVG.no+' '+escHtml(res.message)+'</div>';
      box.classList.add('show');
    }
  }).catch(()=>{btn.innerHTML=SVG.cart+' Order Sekarang';});
}

function doTrial() {
  const username=document.getElementById('trialUsername').value.trim();
  const serverId=document.getElementById('trialServer').value;
  if(!username){return;}
  const fd=new FormData();
  fd.append('server_id',serverId); fd.append('tipe',currentTrialProto);
  fd.append('username',username); fd.append('days',1); fd.append('is_trial',1);
  fetch('/api/create_order.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    closeModal('modalTrial');
    if(res.success){
      res.tipe = currentTrialProto;
      res.server = 'Trial';
      document.getElementById('akunDetailContent').innerHTML = buildDetailHTML(res, true);
      document.querySelector('#modalAkun .modal-title').innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-5px;margin-right:6px"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>Trial Berhasil';
      showModal('modalAkun');
      showAlert('pageAlert',SVG.ok+' Akun trial berhasil dibuat!','success');
    } else {
      showAlert('pageAlert',SVG.no+' '+escHtml(res.message),'error');
    }
  });
}

function detailRow(label, value, canCopy) {
  let v = escHtml(value||'');
  let copyBtn = canCopy
    ? `<button class="copy-btn" onclick="event.stopPropagation();copyText('${encodeURIComponent(value)}',this)" title="Salin ${label}">${SVG.copy}</button>`
    : '';
  return `<div class="result-row"><span class="result-key">${label}</span><span class="result-val">${v}${copyBtn}</span></div>`;
}

function buildDetailHTML(d, isOrderResult) {
  let html = '';
  if(isOrderResult) html += `<div class="alert alert-success" style="margin-bottom:.75rem">${SVG.ok} Akun berhasil dibuat!</div>`;

  // Badge tipe
  let tipeBadge = d.tipe ? `<span class="akun-badge badge-${d.tipe}" style="font-size:.75rem;padding:.2rem .5rem">${d.tipe.toUpperCase()}</span>` : '';
  if(d.is_trial) tipeBadge += ' <span style="color:var(--orange);font-size:.75rem">Trial</span>';

  // Detail rows
  html += detailRow('Username', d.username, true);
  html += `<div class="result-row"><span class="result-key">Tipe</span><span class="result-val">${tipeBadge}</span></div>`;
  if(d.uuid) html += detailRow('UUID', d.uuid, true);
  if(d.password) html += detailRow('Password', d.password, true);
  if(d.server) html += detailRow('Server', d.server, false);
  let expiry = d.expired || d.masa_aktif || '';
  if(expiry) html += detailRow('Masa Aktif', expiry, false);
  if(d.status) html += detailRow('Status', d.status, false);

  // Config Links
  let hasLinks = d.link_tls || d.link_nontls || d.link_grpc;
  if(hasLinks) {
    html += `<div style="margin-top:.75rem;padding-top:.75rem;border-top:1px solid var(--border)">
      <div style="font-size:.78rem;font-weight:600;color:var(--muted);margin-bottom:.5rem">Konfigurasi</div>`;
    if(d.link_tls) html += linkRow('TLS', d.link_tls);
    if(d.link_nontls) html += linkRow('NonTLS', d.link_nontls);
    if(d.link_grpc) html += linkRow('gRPC', d.link_grpc);
    html += `</div>`;
  }

  // Download
  if(d.download) {
    html += `<a href="${escHtml(d.download)}" target="_blank" class="btn btn-outline btn-sm" style="width:100%;margin-top:.75rem">${SVG.dl} Download Config</a>`;
  }

  // Copy All button
  html += `<button class="btn btn-outline btn-sm" onclick="copyAllDetails(this)" style="width:100%;margin-top:.5rem" data-d='${encodeURIComponent(JSON.stringify(d))}'>${SVG.copy} Salin Semua Detail</button>`;

  // Footer actions for order result
  if(isOrderResult) {
    html += `<div style="display:flex;gap:.5rem;margin-top:.75rem;padding-top:.75rem;border-top:1px solid var(--border)">
      <button class="btn btn-outline" onclick="closeModal('modalAkun')" style="flex:1">Tutup</button>
      <button class="btn btn-primary" onclick="closeModal('modalAkun');showPage('akun');location.reload()" style="flex:1">Lihat di Akun VPN</button>
    </div>`;
  }

  return html;
}

function linkRow(label, link) {
  return `<div class="result-row link-row">
    <span class="result-key">${label}</span>
    <span class="result-val" style="font-size:.7rem;word-break:break-all;font-family:monospace">${escHtml(link.substring(0,45))}...</span>
    <button class="copy-btn" onclick="event.stopPropagation();copyText('${encodeURIComponent(link)}',this)" title="Salin ${label}">${SVG.copy}</button>
  </div>`;
}

function copyAllDetails(btn) {
  let raw = decodeURIComponent(btn.dataset.d);
  let d = JSON.parse(raw);
  let lines = ['=== Detail Akun VPN ==='];
  lines.push('Username: ' + (d.username||''));
  if(d.tipe) lines.push('Tipe: ' + d.tipe.toUpperCase());
  if(d.is_trial) lines.push('(Trial)');
  if(d.uuid) lines.push('UUID: ' + d.uuid);
  if(d.password) lines.push('Password: ' + d.password);
  if(d.server) lines.push('Server: ' + d.server);
  lines.push('Masa Aktif: ' + (d.expired||d.masa_aktif||''));
  if(d.status) lines.push('Status: ' + d.status);
  lines.push('');
  lines.push('--- Config Links ---');
  if(d.link_tls) lines.push('[TLS] ' + d.link_tls);
  if(d.link_nontls) lines.push('[NonTLS] ' + d.link_nontls);
  if(d.link_grpc) lines.push('[gRPC] ' + d.link_grpc);
  const txt = lines.join('\n');
  navigator.clipboard?.writeText(txt).then(() => {
    btn.innerHTML = SVG.check + ' Tersalin!';
    setTimeout(() => { btn.innerHTML = SVG.copy + ' Salin Semua Detail'; }, 2000);
  });
}

function showAkunDetail(a) {
  let d = {
    username: a.username,
    tipe: a.tipe,
    is_trial: a.is_trial,
    uuid: a.uuid,
    password: a.password_vpn,
    server: a.nama_server,
    masa_aktif: a.masa_aktif,
    status: a.status,
    link_tls: a.link_tls,
    link_nontls: a.link_nontls,
    link_grpc: a.link_grpc
  };
  document.getElementById('akunDetailContent').innerHTML = buildDetailHTML(d, false);
  document.querySelector('#modalAkun .modal-title').innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-5px;margin-right:6px"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>Detail Akun VPN';
  showModal('modalAkun');
}

function confirmDelete(id,name,type){deleteAkunId=id;deleteAkunType=type;document.getElementById('deleteUsername').textContent=name;showModal('modalDelete');}
function doDelete(){
  if(!deleteAkunId) return;
  document.getElementById('deleteBtn').innerHTML='<span class="loading"></span>';
  fetch('/api/delete_account.php',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'akun_id='+deleteAkunId})
  .then(r=>r.json()).then(res=>{
    closeModal('modalDelete');
    if(res.success){showAlert('pageAlert',SVG.ok+' Akun berhasil dihapus dari server!','success');setTimeout(()=>location.reload(),1500);}
    else{showAlert('pageAlert',SVG.no+' '+escHtml(res.message),'error');}
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
  fetch('/api/topup.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    document.getElementById('topupResult').innerHTML=res.success
      ?'<div class="alert alert-success">'+SVG.ok+' '+escHtml(res.message)+'</div>'
      :'<div class="alert alert-error">'+SVG.no+' '+escHtml(res.message)+'</div>';
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
  fetch('/api/update_profile.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    showAlert('settingAlert',res.success?SVG.ok+' Profil berhasil disimpan!':SVG.no+' '+escHtml(res.message),res.success?'success':'error');
  });
}

function uploadAvatar(){
  const file=document.getElementById('avatarFile').files[0];
  if(!file){showAlert('settingAlert','Pilih file gambar dulu!','error');return;}
  const fd=new FormData(); fd.append('avatar',file);
  fetch('/api/upload_avatar.php',{method:'POST',body:fd})
  .then(r=>r.json()).then(res=>{
    if(res.success){showAlert('settingAlert',SVG.ok+' Foto profil berhasil diupdate!','success');setTimeout(()=>location.reload(),1200);}
    else{showAlert('settingAlert',SVG.no+' '+escHtml(res.message),'error');}
  }).catch(()=>{showAlert('settingAlert','Gagal upload','error');});
}

function deleteAvatar(){
  if(!confirm('Hapus foto profil?'))return;
  fetch('/api/delete_avatar.php',{method:'POST'})
  .then(r=>r.json()).then(res=>{
    if(res.success){showAlert('settingAlert',SVG.ok+' Foto profil dihapus!','success');setTimeout(()=>location.reload(),1200);}
    else{showAlert('settingAlert',SVG.no+' '+escHtml(res.message),'error');}
  });
}

function showAlert(containerId,msg,type){
  const el=document.getElementById(containerId);
  if(el){el.innerHTML=`<div class="alert alert-${type}">${msg}</div>`;setTimeout(()=>{el.innerHTML=''},5000);}
}
function copyText(text,el){
  const decoded=decodeURIComponent(text);
  navigator.clipboard?.writeText(decoded).then(()=>{
    const orig=el.innerHTML; el.innerHTML=SVG.check+' Tersalin!'; setTimeout(()=>{el.innerHTML=orig},1500);
  }).catch(()=>{});
}
function escHtml(s){return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
</script>


</body>
</html>