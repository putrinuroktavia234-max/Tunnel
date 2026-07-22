<?php
require_once __DIR__.'/../includes/config.php';
require_once __DIR__.'/../includes/vpn_manager.php';
$session = requireAdmin();
function detectFlag($region) {
    $map = [
        'Indonesia'  => '🇮🇩', 'Singapore' => '🇸🇬', 'Malaysia'  => '🇲🇾',
        'Japan'      => '🇯🇵', 'Korea'     => '🇰🇷', 'Thailand'  => '🇹🇭',
        'Vietnam'    => '🇻🇳', 'India'      => '🇮🇳', 'Philippines'=>'🇵🇭',
        'USA'        => '🇺🇸', 'United States'=>'🇺🇸', 'Canada'    => '🇨🇦',
        'Germany'    => '🇩🇪', 'Netherlands'=>'🇳🇱', 'France'     => '🇫🇷',
        'UK'         => '🇬🇧', 'United Kingdom'=>'🇬🇧', 'Australia'=> '🇦🇺',
        'Brazil'     => '🇧🇷', 'Russia'     => '🇷🇺', 'Turkey'    => '🇹🇷',
    ];
    foreach ($map as $key => $flag) {
        if (stripos($region, $key) !== false) return $flag;
    }
    return '🌐';
}


$db = getDB();

// === SERVER MONITORING ===
function fetchServerMonitor($server_id, $code, $host, $port, $ssh_user, $ssh_pass, $ssh_key) {
    // Return JSON stats for a single server
    $cmd = "timeout 5 vpn-api monitor none none 0 0 0 --server " . escapeshellarg($code) . " 2>/dev/null";
    $out = shell_exec($cmd);
    $data = json_decode($out, true);
    if ($data && !empty($data['success'])) {
        return $data;
    }
    // Fallback: return offline status
    return ['success' => false, 'ping_ms' => null, 'uptime' => null, 'cpu' => null, 'ram' => null, 'disk' => null, 'ssh_count' => 0, 'vmess_count' => 0, 'vless_count' => 0, 'trojan_count' => 0, 'xray' => 'OFF', 'nginx' => 'OFF', 'ssh' => 'OFF', 'ssh_count' => 0, 'vmess_count' => 0, 'vless_count' => 0, 'trojan_count' => 0, 'xray' => 'OFF', 'nginx' => 'OFF', 'ssh' => 'OFF'];
}

// Endpoint: return JSON for all servers (called by AJAX)
if (isset($_GET['ajax_monitor_single'])) {
    // Monitor single server (called by JS per-server, parallel in browser)
    header('Content-Type: application/json');
    $code = sanitize($_GET['ajax_monitor_single'] ?? '');
    if ($code === 'local') {
        $cmd = "timeout 5 vpn-api monitor none none 0 0 0 2>/dev/null";
        $out = shell_exec($cmd);
        $data = json_decode($out, true);
        if ($data && !empty($data['success'])) {
            $data['name'] = 'VPS Lokal (Master)';
            $data['code_server'] = 'local';
            echo json_encode($data);
        } else {
            echo json_encode(['success' => false, 'ping_ms' => null, 'uptime' => null, 'cpu' => null, 'ram' => null, 'ssh_count' => 0, 'vmess_count' => 0, 'vless_count' => 0, 'trojan_count' => 0]);
        }
    } else {
        $srv = $db->prepare("SELECT * FROM servers WHERE code_server=? AND status='ready' LIMIT 1");
        $srv->execute([$code]);
        $s = $srv->fetch();
        if ($s) {
            $mon = fetchServerMonitor($s['id'], $s['code_server'], $s['host'], $s['port'], $s['ssh_user'], $s['ssh_password'], $s['ssh_key']);
            $mon['name'] = $s['name'];
            $mon['code_server'] = $s['code_server'];
            echo json_encode($mon);
        } else {
            echo json_encode(['success' => false, 'ping_ms' => null]);
        }
    }
    exit;
}

if (isset($_GET['ajax_monitor_list'])) {
    // Return list of server codes for JS to fetch individually
    header('Content-Type: application/json');
    $codes = [['code' => 'local', 'name' => 'VPS Lokal (Master)']];
    $servers = $db->query("SELECT code_server, name FROM servers WHERE status='ready' ORDER BY name")->fetchAll();
    foreach ($servers as $s) {
        $codes[] = ['code' => $s['code_server'], 'name' => $s['name']];
    }
    echo json_encode($codes);
    exit;
}


// Handle POST actions
if ($_SERVER['REQUEST_METHOD']==='POST') {
    verify_csrf();
    $act = $_POST['action'] ?? '';

    if ($act==='approve_topup') {
        $tid = (int)$_POST['topup_id'];
        $r = $db->prepare("SELECT * FROM topup_requests WHERE id=? AND status='pending'");
        $r->execute([$tid]); $req=$r->fetch();
        if ($req) {
            $db->prepare("UPDATE topup_requests SET status='approved', processed_at=NOW() WHERE id=?")->execute([$tid]);
            $db->prepare("UPDATE users SET saldo=saldo+? WHERE id=?")->execute([$req['amount'],$req['user_id']]);
            $db->prepare("INSERT INTO transactions (user_id,type,amount,keterangan,status) VALUES (?,?,?,?,'success',this)")
               ->execute([$req['user_id'],'topup',$req['amount'],'Topup disetujui admin']);
            $u=$db->prepare("SELECT username FROM users WHERE id=?");$u->execute([$req['user_id']]);$uname=$u->fetchColumn();
            sendTelegramNotif("Active Topup <b>{$uname}</b> ".formatRupiah($req['amount'])." disetujui");
        }
        header('Location: /admin/'); exit;
    }

    if ($act==='reject_topup') {
        $tid=(int)$_POST['topup_id'];
        $db->prepare("UPDATE topup_requests SET status='rejected', admin_note=?, processed_at=NOW() WHERE id=?")
           ->execute([sanitize($_POST['note']??''),$tid]);
        header('Location: /admin/'); exit;
    }

    if ($act==='adjust_saldo') {
        $uid = (int)$_POST['user_id'];
        $nom = (int)$_POST['nominal'];
        $mode = $_POST['mode']; // 'tambah' or 'kurang'
        if ($uid && $nom > 0) {
            if ($mode === 'tambah') {
                $db->prepare("UPDATE users SET saldo=saldo+? WHERE id=?")->execute([$nom,$uid]);
                $db->prepare("INSERT INTO transactions (user_id,type,amount,keterangan,status) VALUES (?,'topup',?,'Topup manual oleh admin','success')")
                   ->execute([$uid,$nom]);
            } else {
                $u=$db->prepare("SELECT saldo FROM users WHERE id=?");
                $u->execute([$uid]); $saldo=$u->fetchColumn();
                $nom = min($nom, (int)$saldo);
                $db->prepare("UPDATE users SET saldo=saldo-? WHERE id=?")->execute([$nom,$uid]);
                $db->prepare("INSERT INTO transactions (user_id,type,amount,keterangan,status) VALUES (?,'adjust',?,'Pengurangan saldo oleh admin','success')")
                   ->execute([$uid,$nom]);
            }
        }
        header('Location: /admin/'); exit;
    }

    if ($act==='auto_detect_server') {
        $ip      = sanitize($_POST['host'] ?? '');
        $port    = (int)($_POST['port'] ?? 22);
        $user    = sanitize($_POST['ssh_user'] ?? 'root');
        $pass    = $_POST['ssh_password'] ?? '';
        $sshKey  = $_POST['ssh_key'] ?? '';
        $authType = $_POST['auth_type'] ?? 'password';
        
        if ($authType === 'key' && empty($sshKey)) {
            header('Location: /admin/?auto_error=' . urlencode('SSH Key path wajib diisi'));
            exit;
        }
        if ($authType === 'password' && empty($pass)) {
            header('Location: /admin/?auto_error=' . urlencode('Password wajib diisi'));
            exit;
        }
        
        // Build probe command based on auth type
        if ($authType === 'key') {
            // For SSH key, use empty password (bridge will use key)
            $pass = '';
        }
        $code    = sanitize($_POST['code_server'] ?? '');
        $nama    = sanitize($_POST['name'] ?? '');
        
        if (empty($ip) || empty($pass) || empty($code)) {
            header('Location: /admin/?auto_error=' . urlencode('IP, Password, dan Kode Server wajib diisi'));
            exit;
        }
        
        // Panggil vpn-api probe
        $cmd = "timeout 30 vpn-api probe " . escapeshellarg($ip) . " " . escapeshellarg($user) . " " . escapeshellarg($pass) . " " . $port . " 2>/dev/null";
        $output = shell_exec($cmd);
        $result = json_decode($output, true);
        
        if (!$result || empty($result['success'])) {
            $msg = $result['message'] ?? 'Gagal koneksi ke server remote';
            header('Location: /admin/?auto_error=' . urlencode($msg));
            exit;
        }
        
        // Auto-fill dari hasil probe
        $lokasi = $result['region'] ?? 'Unknown';
        $domain = $result['domain'] ?? '';
        $flag   = detectFlag($lokasi);
        
        if (empty($nama)) {
            $nama = $result['region'] ? explode(',', $result['region'])[0] : $ip;
        }
        
        // Simpan ke database
        $db->prepare("INSERT INTO servers (name,code_server,lokasi,flag,harga_hari,harga_bulan,host,port,ssh_user,ssh_password,domain,status)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,'ready',this)")
           ->execute([
               $nama,
               $code,
               $lokasi,
               $flag,
               (float)($_POST['harga_hari'] ?? 300),
               (float)($_POST['harga_bulan'] ?? 9000),
               $ip,
               $port,
               $user,
               $pass,
               $sshKey,
               $domain,
           ]);
        
        header('Location: /admin/?auto_success=' . urlencode("Server $code ($ip) berhasil ditambahkan! Region: $lokasi"));
        exit;
    }
    
if ($act==='add_server') {
        $db->prepare("INSERT INTO servers (name,code_server,lokasi,flag,harga_hari,harga_bulan,host,port,ssh_user,ssh_password,ssh_key,domain,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'ready',this)")
           ->execute([
               sanitize($_POST['name']), sanitize($_POST['code_server']),
               sanitize($_POST['lokasi']), sanitize($_POST['flag']??'🇮🇩'),
               (float)$_POST['harga_hari'], (float)$_POST['harga_bulan'],
               sanitize($_POST['host']), (int)($_POST['port']??22),
               sanitize($_POST['ssh_user']??'root'), sanitize($_POST['ssh_password']??''),
               sanitize($_POST['ssh_key']??''), sanitize($_POST['domain']??''),
           ]);
        header('Location: /admin/'); exit;
    }

    if ($act==='delete_server') {
        $db->prepare("DELETE FROM servers WHERE id=?")->execute([(int)$_POST['server_id']]);
        header('Location: /admin/'); exit;
    }

    if ($act==='save_settings') {
        $keys=['app_name','app_logo','contact_wa','contact_tg','contact_ig',
               'bank_name','bank_account','bank_holder','dana_number','gopay_number','shopee_number',
               'smtp_host','smtp_port','smtp_user','smtp_pass','smtp_from',
               'tg_bot_token','tg_chat_id','tripay_api_key','tripay_private_key','tripay_merchant_code','tripay_mode',
                 'trial_duration_hours','trial_quota_gb','announce_1','announce_2','announce_3','announce_duration','marquee_text','marquee_enabled','vpn_join_secret'];
        foreach($keys as $k){
            if(isset($_POST[$k])){
                $db->prepare("INSERT INTO app_settings (setting_key,setting_value) VALUES (?,?) ON DUPLICATE KEY UPDATE setting_value=?")
                   ->execute([$k,sanitize($_POST[$k]),sanitize($_POST[$k])]);
            }
        }
        // QRIS image upload
        if (!empty($_FILES['qris_image']['tmp_name'])) {
            $uploadDir=__DIR__.'/../uploads/'; if(!is_dir($uploadDir)) mkdir($uploadDir,0755,true);
            $ext=pathinfo($_FILES['qris_image']['name'],PATHINFO_EXTENSION);
            $fname='qris.'.$ext;
            if(move_uploaded_file($_FILES['qris_image']['tmp_name'],$uploadDir.$fname)){
                $db->prepare("INSERT INTO app_settings (setting_key,setting_value) VALUES ('qris_image',?) ON DUPLICATE KEY UPDATE setting_value=?")
                   ->execute(['/uploads/'.$fname,'/uploads/'.$fname]);
            }
        }
        header('Location: /admin/?saved=1'); exit;
    }

    if ($act==='toggle_server') {
        $sid=(int)$_POST['server_id']; $s=sanitize($_POST['status']);
        $db->prepare("UPDATE servers SET status=? WHERE id=?")->execute([$s,$sid]);
        header('Location: /admin/'); exit;
    }

    if ($act==='delete_user') {
        $uid=(int)$_POST['user_id'];
        if($uid!==$session['user_id']) $db->prepare("DELETE FROM users WHERE id=?")->execute([$uid]);
        header('Location: /admin/'); exit;
    }

    if ($act==='add_wildcard') {
        $dom = sanitize($_POST['domain']??'');
        $ket = sanitize($_POST['keterangan']??'');
        if ($dom) $db->prepare("INSERT INTO wildcard_domains (domain,keterangan) VALUES (?,?)")->execute([$dom,$ket]);
        header('Location: /admin/'); exit;
    }
    if ($act==='delete_wildcard') {
        $db->prepare("DELETE FROM wildcard_domains WHERE id=?")->execute([(int)$_POST['id']]);
        header('Location: /admin/'); exit;
    }

    if ($act==='add_promo') {
        $code  = strtoupper(sanitize($_POST['code']??''));
        $type  = $_POST['discount_type']==='nominal' ? 'nominal' : 'percent';
        $value = (int)($_POST['discount_value']??0);
        $max   = (int)($_POST['max_uses']??0);
        $min   = (int)($_POST['min_price']??0);
        $exp   = sanitize($_POST['expires_at']??'');
        if ($code && $value > 0) {
            $db->prepare("INSERT INTO promo_codes (code,discount_type,discount_value,max_uses,min_price,expires_at) VALUES (?,?,?,?,?,?)")
               ->execute([$code,$type,$value,$max,$min,$exp?:null]);
        }
        header('Location: /admin/'); exit;
    }
    if ($act==='delete_promo') {
        $db->prepare("DELETE FROM promo_codes WHERE id=?")->execute([(int)$_POST['id']]);
        header('Location: /admin/'); exit;
    }
    if ($act==='toggle_promo') {
        $pid=(int)$_POST['id']; $s=sanitize($_POST['status']);
        $db->prepare("UPDATE promo_codes SET status=? WHERE id=?")->execute([$s,$pid]);
        header('Location: /admin/'); exit;
    }
}

// Stats
$stats = [
    'users'    => $db->query("SELECT COUNT(*) FROM users WHERE role='user'")->fetchColumn(),
    'akun'     => $db->query("SELECT COUNT(*) FROM vpn_accounts WHERE status='active'")->fetchColumn(),
    'topup_p'  => $db->query("SELECT COUNT(*) FROM topup_requests WHERE status='pending'")->fetchColumn(),
    'revenue'  => $db->query("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='topup' AND status='success'")->fetchColumn(),
    'orders'   => $db->query("SELECT COUNT(*) FROM transactions WHERE type='order'")->fetchColumn(),
];

$pendingTopups = $db->query("SELECT tr.*, u.username, u.email FROM topup_requests tr JOIN users u ON tr.user_id=u.id WHERE tr.status='pending' ORDER BY tr.created_at DESC")->fetchAll();
$allTopups     = $db->query("SELECT tr.*, u.username FROM topup_requests tr JOIN users u ON tr.user_id=u.id ORDER BY tr.created_at DESC LIMIT 50")->fetchAll();
$servers       = $db->query("SELECT * FROM servers ORDER BY name")->fetchAll();
$vpsNodes      = $db->query("SELECT * FROM servers WHERE last_heartbeat IS NOT NULL OR code_server LIKE 'sv%' ORDER BY last_heartbeat DESC")->fetchAll();
$wildcardDomains = $db->query("SELECT * FROM wildcard_domains ORDER BY created_at DESC")->fetchAll();
$promoCodes   = $db->query("SELECT * FROM promo_codes ORDER BY created_at DESC")->fetchAll();
$users         = $db->query("SELECT * FROM users ORDER BY created_at DESC LIMIT 100")->fetchAll();
$orders        = $db->query("SELECT t.*, u.username FROM transactions t JOIN users u ON t.user_id=u.id WHERE t.type='order' ORDER BY t.created_at DESC LIMIT 50")->fetchAll();
$allAkuns      = $db->query("SELECT va.*, u.username as uname, s.name FROM vpn_accounts va JOIN users u ON va.user_id=u.id JOIN servers s ON va.server_id=s.id ORDER BY va.created_at DESC LIMIT 50")->fetchAll();

$_adminUser = $db->prepare("SELECT avatar FROM users WHERE id=?");
$_adminUser->execute([$session['user_id']]); $_adminUser = $_adminUser->fetch();

$appName = getSetting('app_name','OrderVPN');
$saved   = isset($_GET['saved']);
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Admin &mdash; <?=$appName?></title>
<link rel="stylesheet" href="../assets/css/style.css">
</head>
<body>
<div class="admin-layout">
  <aside class="admin-sidebar">
    <div class="admin-sidebar-logo">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/></svg>
      <span><?=$appName?> <span class="admin-badge">Admin</span></span>
    </div>
    <nav class="admin-sidebar-nav">
      <button class="tab-btn active" onclick="showTab('dashboard',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
        Dashboard
      </button>
      <button class="tab-btn" onclick="showTab('topup',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        Topup<?php if($stats['topup_p']>0):?> <span class="badge-count"><?=$stats['topup_p']?></span><?php endif;?>
      </button>
      <button class="tab-btn" onclick="showTab('servers',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
        Server
      </button>
      <button class="tab-btn" onclick="showTab('users',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        Users
      </button>
      <button class="tab-btn" onclick="showTab('orders',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
        Orders
      </button>
      <button class="tab-btn" onclick="showTab('akuns',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
        VPN Accounts
      </button>
      <button class="tab-btn" onclick="showTab('settings',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        Settings
      </button>
      <button class="tab-btn" onclick="showTab('multivps',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/></svg>
        Multi-VPS
      </button>
      <button class="tab-btn" onclick="showTab('wildcard',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>
        Wildcard
      </button>
      <button class="tab-btn" onclick="showTab('promo',this)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="2" x2="12" y2="22"/><path d="M19 7l-7 5 7 5"/><path d="M5 7l7 5-7 5"/></svg>
        Promo
      </button>
      <a href="../change_password.php" class="tab-btn" style="color:#f59e0b;display:flex;align-items:center;gap:0.5rem;text-decoration:none;width:100%;padding:0.55rem 0.8rem;text-align:left;border-radius:8px">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
        Password
      </a>
    </nav>
    <div class="admin-sidebar-footer">
      <div style="display:flex;align-items:center;gap:.6rem;padding:.5rem .8rem;margin-bottom:.35rem;background:rgba(255,255,255,.03);border-radius:8px">
        <div style="width:32px;height:32px;border-radius:8px;overflow:hidden;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.85rem;color:#fff;flex-shrink:0">
          <?php if(!empty($_adminUser['avatar'])):?><img src="<?=esc($_adminUser['avatar'])?>" style="width:100%;height:100%;object-fit:cover"><?php else:?><?=strtoupper(substr($session['username'],0,1))?><?php endif;?>
        </div>
        <div style="flex:1;min-width:0"><div style="font-size:.82rem;font-weight:600;color:var(--text)"><?=esc($session['username'])?></div><div style="font-size:.7rem;color:var(--muted)">Admin</div></div>
      </div>
      <a href="/dashboard.php" class="tab-btn" style="display:flex;align-items:center;gap:0.5rem;text-decoration:none;width:100%;padding:0.55rem 0.8rem;border-radius:8px">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        User Panel
      </a>
      <a href="/api/logout.php" class="tab-btn" style="display:flex;align-items:center;gap:0.5rem;text-decoration:none;width:100%;padding:0.55rem 0.8rem;border-radius:8px;color:var(--danger)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Logout
      </a>
    </div>
  </aside>
  <main class="admin-main">

<div class="content">
  <?php if($saved):?><div class="alert alert-success">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
    Settings saved successfully.
  </div><?php endif;?>

  <!-- DASHBOARD -->
  <div class="page active admin-section" id="tab-dashboard">
    <div class="stats">
      <div class="stat-card">
        <div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>
        <div class="stat-val"><?=$stats['users']?></div><div class="stat-label">Total Users</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg></div>
        <div class="stat-val"><?=$stats['akun']?></div><div class="stat-label">Akun Aktif</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg></div>
        <div class="stat-val"><?=$stats['orders']?></div><div class="stat-label">Total Order</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></svg></div>
        <div class="stat-val"><?=formatRupiah($stats['revenue'])?></div><div class="stat-label">Total Revenue</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div>
        <div class="stat-val" style="color:var(--yellow)"><?=$stats['topup_p']?></div><div class="stat-label">Topup Pending</div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        Pending Topup
      </div></div>
      <div class="card-body">
        <?php if(empty($pendingTopups)):?><p style="color:var(--muted);font-size:.875rem">Tidak ada topup pending.</p>
        <?php else: foreach($pendingTopups as $t):?>
        <div style="display:flex;align-items:center;justify-content:space-between;padding:.75rem;background:var(--card2);border-radius:10px;margin-bottom:.5rem;border:1px solid #92400e44;gap:1rem;flex-wrap:wrap">
          <div>
            <div style="font-weight:600;font-size:.875rem"><?=esc($t['username'])?></div>
            <div style="font-size:.75rem;color:var(--muted)"><?=esc($t['payment_method'])?> &middot; <?=date('d M Y H:i',strtotime($t['created_at']))?></div>
            <?php if($t['bukti_transfer']):?><a href="<?=esc($t['bukti_transfer'])?>" target="_blank" class="btn btn-outline" style="margin-top:.35rem;font-size:.7rem">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              View Bukti
            </a><?php endif;?>
          </div>
          <div style="font-size:1rem;font-weight:800;color:var(--yellow)"><?=formatRupiah($t['amount'])?></div>
          <div style="display:flex;gap:.4rem;flex-wrap:wrap">
            <form method="POST" style="display:inline"><input type="hidden" name="action" value="approve_topup"><?=csrf_field()?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><button type="submit" class="btn btn-primary">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Active Approve
            </button></form>
            <form method="POST" style="display:inline"><input type="hidden" name="action" value="reject_topup"><?=csrf_field()?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><input type="hidden" name="note" value="Ditolak admin"><button type="submit" class="btn btn-danger">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              Tolak
            </button></form>
          </div>
        </div>
        <?php endforeach; endif;?>
      </div>
    </div>
  </div>

  <!-- TOPUP -->
  <div class="page admin-section" id="tab-topup">
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        Topup History
      </div></div>
      <div class="card-body overflow-x">
        <div class="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Nominal</th><th>Metode</th><th>Status</th><th>Tanggal</th><th>Aksi</th></tr></thead>
            <tbody>
            <?php foreach($allTopups as $t):?>
            <tr>
              <td><?=esc($t['username'])?></td>
              <td style="font-weight:700"><?=formatRupiah($t['amount'])?></td>
              <td><?=esc($t['payment_method'])?></td>
              <td><span class="badge b-<?=$t['status']?>"><?=$t['status']?></span></td>
              <td><?=date('d M Y H:i',strtotime($t['created_at']))?></td>
              <td>
                <?php if($t['status']==='pending'):?>
                <form method="POST" style="display:inline"><input type="hidden" name="action" value="approve_topup"><?=csrf_field()?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><button class="btn btn-primary">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                  Active
                </button></form>
                <form method="POST" style="display:inline"><input type="hidden" name="action" value="reject_topup"><?=csrf_field()?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><input type="hidden" name="note" value="Ditolak"><button class="btn btn-danger">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  Reject
                </button></form>
                <?php endif;?>
                <?php if($t['bukti_transfer']):?><a href="<?=esc($t['bukti_transfer'])?>" target="_blank" class="btn btn-outline">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  View
                </a><?php endif;?>
              </td>
            </tr>
            <?php endforeach;?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- SERVERS -->
  <div class="page admin-section" id="tab-servers">
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
        Server List
      </div><button class="btn btn-primary" onclick="document.getElementById('addServerForm').style.display=document.getElementById('addServerForm').style.display==='none'?'block':'none'">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Tambah Server
      </button></div>
      <div id="autoDetectForm" style="padding:1.25rem;border-bottom:1px solid var(--border);background:linear-gradient(135deg, rgba(99,102,241,.05), rgba(139,92,246,.05))">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem">
            <div>
                <strong style="font-size:.9rem;color:var(--primary)">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>
                  Auto-Detect &amp; Add Server
                </strong>
                <p style="font-size:.72rem;color:var(--muted);margin-top:2px">Deteksi otomatis: region, domain, port, OS &mdash; tinggal isi IP &amp; password</p>
            </div>
        </div>
        <form method="POST">
            <?=csrf_field()?>
            <input type="hidden" name="action" value="auto_detect_server">
            
            <div class="grid2">
            <div><label>Nama Server</label><input name="name" placeholder="BIZNET IDC" required></div>
            <div><label>Kode Server</label><input name="code_server" placeholder="sgp1" required></div>
            <div><label>Lokasi</label><input name="lokasi" placeholder="Singapura" required></div>
            <div><label>Flag Emoji</label><input name="flag" placeholder="&#x1F1F8;&#x1F1EC;" value="&#x1F1EE;&#x1F1E9;"></div>
            <div><label>IP/Host VPS</label><input name="host" placeholder="103.x.x.x" required></div>
            <div><label>Port SSH</label><input name="port" type="number" value="22"></div>
            <div><label>SSH User</label><input name="ssh_user" value="root"></div>
            <div><label>SSH Password (opsional)</label><input name="ssh_password" type="password" placeholder="Jika tidak pakai key"></div>
            <div><label>Path SSH Key (opsional)</label><input name="ssh_key" placeholder="/root/.ssh/id_rsa"></div>
            <div><label>Domain VPS</label><input name="domain" placeholder="domain.com (opsional)"></div>
            <div><label>Harga/Hari (Rp)</label><input name="harga_hari" type="number" value="300" required></div>
            <div><label>Harga/Bulan (Rp)</label><input name="harga_bulan" type="number" value="9000" required></div>
          </div>
          <p style="font-size:.75rem;color:var(--muted);margin-bottom:.75rem">Ensure <code>vpn-api</code> sudah terpasang di VPS target dengan <code>install-ordervpn.sh</code></p>
          <div class="grid2" style="margin-top:.75rem">
                <div><label>Harga/Hari (Rp)</label><input name="harga_hari" type="number" value="300"></div>
                <div><label>Harga/Bulan (Rp)</label><input name="harga_bulan" type="number" value="9000"></div>
            </div>
            <button type="submit" class="btn btn-primary">Save Server</button>
        </form>
      </div>
      <div class="card-body overflow-x">
        <div class="table-wrap">
          <table>
            <thead><tr><th>Server</th><th>Ping</th><th>Uptime</th><th>CPU</th><th>RAM</th><th>Akun</th><th>Lokasi</th><th>Harga/Hari</th><th>Status</th><th>Aksi</th></tr></thead>
            <tbody>
            <?php foreach($servers as $s):?>
            <tr data-server="<?=$s['code_server']?>">
              <td><strong><?=esc($s['name'])?></strong><br><span style="color:var(--muted);font-size:.72rem"><?=esc($s['code_server'])?></span></td>
              <td class="mon-ping" data-code="<?=$s['code_server']?>">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="spinner"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
              </td>
              <td class="mon-uptime" data-code="<?=$s['code_server']?>">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="spinner"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
              </td>
              <td class="mon-cpu" data-code="<?=$s['code_server']?>">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="spinner"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
              </td>
              <td class="mon-ram" data-code="<?=$s['code_server']?>">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="spinner"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
              </td>
              <td class="mon-accounts" data-code="<?=$s['code_server']?>">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="spinner"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
              </td>
              <td><?=$s['flag']??'&#x1F1EE;&#x1F1E9;'?> <?=esc($s['lokasi'])?></td>
              <td style="font-family:monospace;font-size:.78rem"><?=esc($s['host'])?></td>
              <td><?=formatRupiah($s['harga_hari'])?></td>
              <td><span class="badge b-<?=$s['status']?>"><?=$s['status']?></span></td>
              <td>
                <div style="display:flex;gap:.35rem;flex-wrap:wrap">
                  <form method="POST" style="display:inline">
                    <?=csrf_field()?>
                    <input type="hidden" name="action" value="toggle_server">
                    <input type="hidden" name="server_id" value="<?=$s['id']?>">
                    <input type="hidden" name="status" value="<?=$s['status']==='ready'?'maintenance':'ready'?>">
                    <button class="btn" title="<?=$s['status']==='ready'?'Maintenance':'Aktifkan'?>">
                      <?php if($s['status']==='ready'):?>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
                      MNT
                      <?php else:?>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                      ON
                      <?php endif;?>
                    </button>
                  </form>
                  <form method="POST" style="display:inline" onsubmit="return confirm('Hapus server ini?',this)">
                    <?=csrf_field()?>
                    <input type="hidden" name="action" value="delete_server">
                    <input type="hidden" name="server_id" value="<?=$s['id']?>">
                    <button class="btn btn-danger" title="Hapus server">
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                    </button>
                  </form>
                </div>
              </td>
            </tr>
            <?php endforeach;?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- USERS -->
  <div class="page admin-section" id="tab-users">
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        Daftar User (<?=count($users)?>)
      </div></div>
      <div class="card-body overflow-x">
        <div class="table-wrap">
          <table>
            <thead><tr><th>Username</th><th>Email</th><th>Saldo</th><th>Verified</th><th>Role</th><th>Daftar</th><th>Aksi</th></tr></thead>
            <tbody>
            <?php foreach($users as $u):?>
            <tr>
              <td><strong><?=esc($u['username'])?></strong></td>
              <td><?=esc($u['email'])?></td>
              <td style="color:var(--green);font-weight:600"><?=formatRupiah($u['saldo'])?></td>
              <td><?=$u['is_verified']?'Active':'Pending'?></td>
              <td><span class="badge" style="<?=$u['role']==='admin'?'background:#4c1d9522;color:#a78bfa':'background:#0a1628;color:var(--muted)'?>"><?=$u['role']?></span></td>
              <td style="font-size:.75rem"><?=date('d M Y',strtotime($u['created_at']))?></td>
              <td style="white-space:nowrap">
                <button class="btn btn-outline btn-sm" style="font-size:.7rem;margin-right:4px" onclick="showSaldoModal(<?=$u['id']?>,'<?=esc($u['username'])?>','<?=$u['saldo']?>')">Saldo</button>
                <?php if($u['role']!=='admin'):?>
                <form method="POST" style="display:inline" onsubmit="return confirm('Hapus user <?=esc($u['username'])?>?',this)">
                  <?=csrf_field()?>
                  <input type="hidden" name="action" value="delete_user">
                  <input type="hidden" name="user_id" value="<?=$u['id']?>">
                  <button class="btn btn-danger btn-sm" title="Hapus user">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                  </button>
                </form>
                <?php endif;?>
              </td>
            </tr>
            <?php endforeach;?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- ORDERS / LAPORAN -->
  <div class="page admin-section" id="tab-orders">
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
        Laporan Pembelian
      </div></div>
      <div class="card-body overflow-x">
        <div class="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Keterangan</th><th>Nominal</th><th>Status</th><th>Tanggal</th></tr></thead>
            <tbody>
            <?php foreach($orders as $o):?>
            <tr>
              <td><?=esc($o['username'])?></td>
              <td><?=esc($o['keterangan']??'')?></td>
              <td style="font-weight:700;color:var(--blue)"><?=formatRupiah($o['amount'])?></td>
              <td><span class="badge b-<?=$o['status']?>"><?=$o['status']?></span></td>
              <td style="font-size:.75rem"><?=date('d M Y H:i',strtotime($o['created_at']))?></td>
            </tr>
            <?php endforeach;?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- AKUN VPN -->
  <div class="page admin-section" id="tab-akuns">
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"/><rect x="2" y="14" width="20" height="8" rx="2" ry="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>
        All VPN Accounts
      </div></div>
      <div class="card-body overflow-x">
        <div class="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Username</th><th>Tipe</th><th>Server</th><th>Expired</th><th>Status</th></tr></thead>
            <tbody>
            <?php foreach($allAkuns as $a):?>
            <tr>
              <td><?=esc($a['uname'])?></td>
              <td style="font-family:monospace"><?=esc($a['username'])?><?=$a['is_trial']?' (Trial)':''?></td>
              <td><span class="badge b-active"><?=strtoupper($a['tipe'])?></span></td>
              <td><?=esc($a['name'])?></td>
              <td style="font-size:.75rem"><?=date('d M Y H:i',strtotime($a['masa_aktif']))?></td>
              <td><span class="badge b-<?=$a['status']?>"><?=$a['status']?></span></td>
            </tr>
            <?php endforeach;?>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- SETTINGS -->
  <div class="page admin-section" id="tab-settings">
    <form method="POST" enctype="multipart/form-data">
    <?=csrf_field()?>
    <input type="hidden" name="action" value="save_settings">
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
        Application Info
      </div></div>
      <div class="card-body">
        <div class="grid2">
          <div class="form-group"><label>Nama Aplikasi</label><input name="app_name" value="<?=esc(getSetting('app_name','OrderVPN'))?>"></div>
          <div class="form-group"><label>Logo (Emoji)</label><input name="app_logo" value="<?=esc(getSetting('app_logo','OVPN'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
        Admin Contact
      </div></div>
      <div class="card-body">
        <div class="grid3">
          <div class="form-group"><label>WhatsApp (nomor)</label><input name="contact_wa" placeholder="628xxxxxxxxxx" value="<?=esc(getSetting('contact_wa'))?>"></div>
          <div class="form-group"><label>Telegram (@username)</label><input name="contact_tg" placeholder="@username" value="<?=esc(getSetting('contact_tg'))?>"></div>
          <div class="form-group"><label>Instagram (@username)</label><input name="contact_ig" placeholder="@username" value="<?=esc(getSetting('contact_ig'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
        Manual Payment Methods
      </div></div>
      <div class="card-body">
        <div class="section-title">Bank Transfer</div>
        <div class="grid3">
          <div class="form-group"><label>Nama Bank</label><input name="bank_name" value="<?=esc(getSetting('bank_name','BCA'))?>"></div>
          <div class="form-group"><label>No. Rekening</label><input name="bank_account" value="<?=esc(getSetting('bank_account'))?>"></div>
          <div class="form-group"><label>Atas Nama</label><input name="bank_holder" value="<?=esc(getSetting('bank_holder'))?>"></div>
        </div>
        <div class="section-title">E-Wallet</div>
        <div class="grid3">
          <div class="form-group"><label>Dana (nomor HP)</label><input name="dana_number" placeholder="08xxxxxxxxxx" value="<?=esc(getSetting('dana_number'))?>"></div>
          <div class="form-group"><label>GoPay (nomor HP)</label><input name="gopay_number" placeholder="08xxxxxxxxxx" value="<?=esc(getSetting('gopay_number'))?>"></div>
          <div class="form-group"><label>ShopeePay (nomor HP)</label><input name="shopee_number" placeholder="08xxxxxxxxxx" value="<?=esc(getSetting('shopee_number'))?>"></div>
        </div>
        <div class="section-title">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="4"/><line x1="2" y1="10" x2="22" y2="10"/><line x1="10" y1="2" x2="10" y2="22"/></svg>
          QRIS
        </div>
        <div class="form-group"><label>Upload Gambar QRIS</label><input type="file" name="qris_image" accept="image/*" style="margin-bottom:.5rem"></div>
        <?php if(getSetting('qris_image')):?><img src="<?=esc(getSetting('qris_image'))?>" style="max-width:150px;border-radius:8px;margin-bottom:.75rem"><?php endif;?>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
        Email SMTP (Gmail)
      </div></div>
      <div class="card-body">
        <p style="font-size:.78rem;color:var(--muted);margin-bottom:.75rem">Untuk OTP verifikasi. Gmail: aktifkan 2FA &rarr; buat App Password di myaccount.google.com/security</p>
        <div class="grid3">
          <div class="form-group"><label>SMTP Host</label><input name="smtp_host" value="<?=esc(getSetting('smtp_host','smtp.gmail.com'))?>"></div>
          <div class="form-group"><label>Port</label><input name="smtp_port" value="<?=esc(getSetting('smtp_port','587'))?>"></div>
          <div class="form-group"><label>Email Pengirim</label><input name="smtp_from" placeholder="noreply@gmail.com" value="<?=esc(getSetting('smtp_from'))?>"></div>
          <div class="form-group"><label>Username Gmail</label><input name="smtp_user" placeholder="email@gmail.com" value="<?=esc(getSetting('smtp_user'))?>"></div>
          <div class="form-group"><label>App Password Gmail</label><input name="smtp_pass" type="password" placeholder="xxxx xxxx xxxx xxxx" value="<?=esc(getSetting('smtp_pass'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
        Telegram Bot Notifikasi
      </div></div>
      <div class="card-body">
        <div class="grid2">
          <div class="form-group"><label>Bot Token</label><input name="tg_bot_token" placeholder="123456:ABC..." value="<?=esc(getSetting('tg_bot_token'))?>"></div>
          <div class="form-group"><label>Chat ID Admin</label><input name="tg_chat_id" placeholder="-100..." value="<?=esc(getSetting('tg_chat_id'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>
        Pengaturan Trial
      </div></div>
      <div class="card-body">
        <div class="grid2">
          <div class="form-group"><label>Durasi Trial (jam)</label><input name="trial_duration_hours" type="number" value="<?=esc(getSetting('trial_duration_hours','1'))?>"></div>
          <div class="form-group"><label>Quota Trial (GB)</label><input name="trial_quota_gb" type="number" value="<?=esc(getSetting('trial_quota_gb','1'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10"/></svg>
        Pengumuman Pop-up (Muncul di Dashboard)
      </div></div>
      <div class="card-body">
        <p style="font-size:.78rem;color:#64748b;margin-bottom:.75rem">
          Format: <code style="background:#0a1628;padding:2px 6px;border-radius:4px;">BADGE|TEKS</code> &mdash; BADGE: BARU, PROMO, atau INFO. Kosongkan untuk menyembunyikan.
        </p>
        <?php for($_pi=1;$_pi<=3;$_pi++):
          $_pval = getSetting('announce_'.$_pi,'');
          $_parts = $_pval ? explode('|',$_pval,2) : ['BARU',''];
        ?>
        <div class="form-group">
          <label class="lbl">Pengumuman <?=$_pi?></label>
          <div style="display:flex;gap:.5rem;">
            <select name="announce_<?=$_pi?>_badge" style="width:100px;padding:.7rem .6rem;background:#0a1628;border:1px solid #1e3a5f;border-radius:8px;color:#f1f5f9;font-size:.85rem;font-family:inherit;">
              <option value="BARU" <?=$_parts[0]==='BARU'?'selected':''?>>BARU</option>
              <option value="PROMO" <?=$_parts[0]==='PROMO'?'selected':''?>>PROMO</option>
              <option value="INFO" <?=$_parts[0]==='INFO'?'selected':''?>>INFO</option>
            </select>
            <input type="text" name="announce_<?=$_pi?>_text" placeholder="Teks pengumuman <?=$_pi?>..." style="flex:1" value="<?=esc($_parts[1]??'')?>">
          </div>
          <input type="hidden" name="announce_<?=$_pi?>" id="announce_<?=$_pi?>_final" value="<?=esc($_pval)?>">
        </div>
        <?php endfor;?>
        <div style="margin-top:.5rem">
          <label class="lbl">Durasi Tampil (detik)</label>
          <div style="display:flex;align-items:center;gap:.5rem">
            <input type="number" name="announce_duration" style="width:100px;padding:.5rem .6rem;border-radius:6px;border:1px solid var(--border);background:var(--bg2);color:var(--fg);font-size:.85rem" value="<?=esc(getSetting('announce_duration','7'))?>" min="2" max="30">
            <span style="font-size:.75rem;color:var(--muted)">detik (2-30)</span>
          </div>
        </div>
        <script>
        (function(){
          var f=document.querySelector('form[action*="save_settings"]');
          if(f){
            f.addEventListener('submit',function(){
              for(var i=1;i<=3;i++){
                var b=f.querySelector('[name="announce_'+i+'_badge"]');
                var t=f.querySelector('[name="announce_'+i+'_text"]');
                var h=f.querySelector('#announce_'+i+'_final');
                if(b&&t&&h) h.value=t.value.trim()?(b.value+'|'+t.value.trim()):'';
              }
            });
          }
        })();
        </script>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
        Pengumuman Berjalan (Marquee)
      </div></div>
      <div class="card-body">
        <div class="grid2">
          <div class="form-group"><label>Teks Pengumuman</label>
            <textarea name="marquee_text" rows="2" style="width:100%;padding:.625rem .75rem;border-radius:8px;border:1px solid var(--border);background:var(--bg2);color:var(--fg);font-family:inherit;font-size:.85rem" placeholder="Selamat datang di OrderVPN! Nikmati layanan tunneling premium kami."><?=esc(getSetting('marquee_text'))?></textarea>
          </div>
          <div class="form-group"><label>Aktifkan</label>
            <select name="marquee_enabled" style="width:100%;padding:.625rem .75rem;border-radius:8px;border:1px solid var(--border);background:var(--bg2);color:var(--fg);font-family:inherit;font-size:.85rem">
              <option value="1" <?=getSetting('marquee_enabled','1')=='1'?'selected':''?>>Ya</option>
              <option value="0" <?=getSetting('marquee_enabled','1')=='0'?'selected':''?>>Tidak</option>
            </select>
          </div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
        Simpan Pengaturan
      </div></div>
      <div class="card-body">
        <button type="submit" class="btn btn-primary" style="width:100%;padding:.875rem;font-size:.9rem">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
              Simpan Semua Pengaturan
            </button>
      </div>
    </div>
    </form>
  </div>

  <!-- === WILDCARD PAGE === -->
  <div class="page" id="tab-wildcard">
    <div class="page-header">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>
      Daftar Domain Wildcard
    </div>
    <div class="card">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Tambah Domain Wildcard
      </div>
      <div class="card-body">
        <form method="POST">
          <?=csrf_field()?>
          <input type="hidden" name="action" value="add_wildcard">
          <div class="grid2">
            <div class="form-group"><label>Domain</label><input name="domain" placeholder="contoh: vpn.example.com" style="font-family:monospace" required></div>
            <div class="form-group"><label>Keterangan (opsional)</label><input name="keterangan" placeholder="Misal: Server SG"></div>
          </div>
          <button type="submit" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Tambah
          </button>
        </form>
      </div>
    </div>
    <div class="card">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        Wildcard Terdaftar (<?=count($wildcardDomains)?>)
      </div>
      <div class="card-body">
        <?php if(empty($wildcardDomains)):?>
        <p style="color:var(--muted);font-size:.85rem">Belum ada domain wildcard. Tambah domain baru di atas.</p>
        <?php else:?>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Domain</th><th>Keterangan</th><th>Ditambahkan</th><th>Aksi</th></tr></thead>
            <tbody>
              <?php foreach($wildcardDomains as $w):?>
              <tr>
                <td style="font-family:monospace"><?=esc($w['domain'])?></td>
                <td style="color:var(--muted)"><?=esc($w['keterangan'])?></td>
                <td style="font-size:.75rem"><?=date('d M Y',strtotime($w['created_at']))?></td>
                <td>
                  <form method="POST" style="display:inline" onsubmit="return confirm('Hapus domain <?=esc($w['domain'])?>?')">
                    <?=csrf_field()?>
                    <input type="hidden" name="action" value="delete_wildcard">
                    <input type="hidden" name="id" value="<?=$w['id']?>">
                    <button class="btn btn-danger btn-sm">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                    </button>
                  </form>
                </td>
              </tr>
              <?php endforeach;?>
            </tbody>
          </table>
        </div>
        <?php endif;?>
      </div>
    </div>
  </div>

  <!-- === PROMO PAGE === -->
  <div class="page" id="tab-promo">
    <div class="page-header">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="2" x2="12" y2="22"/><path d="M19 7l-7 5 7 5"/><path d="M5 7l7 5-7 5"/></svg>
      Kode Promo
    </div>
    <div class="card">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Tambah Kode Promo
      </div>
      <div class="card-body">
        <form method="POST">
          <?=csrf_field()?>
          <input type="hidden" name="action" value="add_promo">
          <div class="grid2">
            <div class="form-group"><label>Kode Promo</label><input name="code" placeholder="Contoh: HEMAT10" style="text-transform:uppercase;font-family:monospace" required></div>
            <div class="form-group"><label>Jenis Diskon</label>
              <select name="discount_type">
                <option value="percent">Persen (%)</option>
                <option value="nominal">Nominal (Rp)</option>
              </select>
            </div>
            <div class="form-group"><label>Nilai Diskon</label><input name="discount_value" type="number" min="1" placeholder="10 atau 5000" required></div>
            <div class="form-group"><label>Maks. Pemakaian (0 = tak terbatas)</label><input name="max_uses" type="number" min="0" value="0"></div>
            <div class="form-group"><label>Min. Pembelian (Rp, 0 = tanpa minimal)</label><input name="min_price" type="number" min="0" value="0"></div>
            <div class="form-group"><label>Berlaku Sampai (kosongkan = tidak ada batas)</label><input name="expires_at" type="date"></div>
          </div>
          <button type="submit" class="btn btn-primary">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Tambah Promo
          </button>
        </form>
      </div>
    </div>
    <div class="card">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="2" x2="12" y2="22"/><path d="M19 7l-7 5 7 5"/><path d="M5 7l7 5-7 5"/></svg>
        Daftar Promo (<?=count($promoCodes)?>)
      </div>
      <div class="card-body">
        <?php if(empty($promoCodes)):?>
        <p style="color:var(--muted);font-size:.85rem">Belum ada kode promo. Tambah promo baru di atas.</p>
        <?php else:?>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Kode</th><th>Diskon</th><th>Min. Beli</th><th>Pemakaian</th><th>Maks</th><th>Expired</th><th>Status</th><th>Aksi</th></tr></thead>
            <tbody>
              <?php foreach($promoCodes as $p):
                $expired = $p['expires_at'] && $p['expires_at'] < date('Y-m-d');
              ?>
              <tr>
                <td style="font-family:monospace;font-weight:700;color:var(--warning)"><?=esc($p['code'])?></td>
                <td><?=$p['discount_type']==='percent' ? $p['discount_value'].'%' : formatRupiah($p['discount_value'])?></td>
                <td><?=$p['min_price']>0?formatRupiah($p['min_price']):'-'?></td>
                <td><?=(int)$p['used_count']?> / <?=$p['max_uses']>0?$p['max_uses']:'&infin;'?></td>
                <td style="font-size:.75rem"><?=$p['max_uses']>0?$p['max_uses']:'&infin;'?></td>
                <td style="font-size:.75rem"><?=$p['expires_at']?date('d M Y',strtotime($p['expires_at'])):'-'; if($expired) echo ' <span style="color:var(--danger)">(exp)</span>';?></td>
                <td>
                  <form method="POST" style="display:inline">
                    <?=csrf_field()?>
                    <input type="hidden" name="action" value="toggle_promo">
                    <input type="hidden" name="id" value="<?=$p['id']?>">
                    <input type="hidden" name="status" value="<?=$p['status']==='active'?'inactive':'active'?>">
                    <button class="btn btn-sm <?=$p['status']==='active'?'b-online':'b-danger'?>" style="font-size:.7rem;padding:.2rem .5rem;border:none"><?=$p['status']==='active'?'Aktif':'Nonaktif'?></button>
                  </form>
                </td>
                <td>
                  <form method="POST" style="display:inline" onsubmit="return confirm('Hapus kode <?=esc($p['code'])?>?')">
                    <?=csrf_field()?>
                    <input type="hidden" name="action" value="delete_promo">
                    <input type="hidden" name="id" value="<?=$p['id']?>">
                    <button class="btn btn-danger btn-sm">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                    </button>
                  </form>
                </td>
              </tr>
              <?php endforeach;?>
            </tbody>
          </table>
        </div>
        <?php endif;?>
      </div>
    </div>
  </div>

  <!-- === MULTI-VPS PAGE === -->
  <div class="page" id="tab-multivps">
    <div class="page-header">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/></svg>
      Multi-VPS Management
    </div>

    <?php
    $joinSecret = getSetting('vpn_join_secret', '');
    $masterIP = $_SERVER['SERVER_ADDR'] ?? gethostbyname(gethostname());
    ?>

    <!-- Join Secret -->
    <div class="card" style="margin-bottom:1rem">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
        Join Secret
      </div>
      <div class="card-body">
        <p style="margin:0 0 .75rem;opacity:.8">Secret key used by new VPS nodes to authenticate when joining this cluster.</p>
        <div style="display:flex;gap:.5rem;align-items:center;flex-wrap:wrap">
          <input type="text" id="joinSecretInput" class="form-input" readonly value="<?=esc($joinSecret)?>" style="flex:1;min-width:200px;font-family:monospace;font-size:.9rem;padding:.6rem .75rem;background:var(--bg2);border:1px solid var(--border);border-radius:6px;color:var(--fg)">
          <?php if ($joinSecret): ?>
          <button class="btn btn-primary" onclick="copySecret()" style="padding:.6rem 1rem">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
            Copy
          </button>
          <button class="btn btn-warning" onclick="generateSecret()" style="padding:.6rem 1rem">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            Regenerate
          </button>
          <?php else: ?>
          <button class="btn btn-primary" onclick="generateSecret()" style="padding:.6rem 1rem">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
            Generate Secret
          </button>
          <?php endif; ?>
        </div>
        <div id="secretStatus" style="margin-top:.5rem;font-size:.85rem"></div>
      </div>
    </div>

    <!-- Join Command -->
    <?php if ($joinSecret): ?>
    <div class="card" style="margin-bottom:1rem">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
        Join Command
      </div>
      <div class="card-body">
        <p style="margin:0 0 .75rem;opacity:.8">Run this command on a new VPS to connect it to this master panel:</p>
        <div style="display:flex;gap:.5rem;align-items:center">
          <input type="text" class="form-input" readonly value="bash <(curl -s http://<?=$masterIP?>:8888/join.sh) --master=<?=$masterIP?> --secret=<?=esc($joinSecret)?>" style="flex:1;min-width:200px;font-family:monospace;font-size:.8rem;padding:.6rem .75rem;background:#1a1a2e;border:1px solid var(--border);border-radius:6px;color:#e2e8f0" id="joinCmdInput">
          <button class="btn btn-primary" onclick="copyCmd()" style="padding:.6rem 1rem">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
            Copy
          </button>
        </div>
        <p style="margin:.75rem 0 0;font-size:.8rem;opacity:.6">Replace <code>--name</code> and <code>--code</code> optionally to customize server identity.</p>
      </div>
    </div>
    <?php endif; ?>

    <!-- Connected VPS Nodes -->
    <div class="card" style="margin-bottom:1rem">
      <div class="card-header">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/></svg>
        Connected VPS Nodes (<?=count($vpsNodes)?>)
        <button class="btn btn-sm btn-primary" onclick="refreshNodes()" style="margin-left:auto">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
          Refresh
        </button>
      </div>
      <div class="card-body" style="padding:0">
        <?php if (empty($vpsNodes)): ?>
        <div style="padding:2rem;text-align:center;opacity:.5">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/></svg>
          <p style="margin-top:.5rem">No VPS nodes connected yet. Generate a secret and run the join command on a new VPS.</p>
        </div>
        <?php else: ?>
        <table class="table">
          <thead>
            <tr>
              <th>Node</th>
              <th>Code</th>
              <th>IP</th>
              <th>Location</th>
              <th>Status</th>
              <th>CPU</th>
              <th>RAM</th>
              <th>Disk</th>
              <th>Last Heartbeat</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($vpsNodes as $node): ?>
            <?php
              $isOnline = $node['last_heartbeat'] && (time() - strtotime($node['last_heartbeat'])) < 300;
              $statusColor = $isOnline ? '#22c55e' : (empty($node['last_heartbeat']) ? '#6b7280' : '#ef4444');
              $statusLabel = $isOnline ? 'Online' : (empty($node['last_heartbeat']) ? 'Pending' : 'Offline');
            ?>
            <tr>
              <td><strong><?=esc($node['name']?:$node['code_server'])?></strong></td>
              <td><code style="font-size:.8rem;opacity:.7"><?=esc($node['code_server'])?></code></td>
              <td><code style="font-size:.8rem"><?=esc($node['host'])?></code></td>
              <td><?=esc($node['flag'])?> <?=esc($node['lokasi'])?></td>
              <td>
                <span style="display:inline-flex;align-items:center;gap:4px;color:<?=$statusColor?>">
                  <span style="width:8px;height:8px;border-radius:50%;background:<?=$statusColor?>;display:inline-block"></span>
                  <?=$statusLabel?>
                </span>
              </td>
              <td style="font-size:.85rem"><?=esc($node['cpu']??'-')?>%</td>
              <td style="font-size:.85rem"><?=esc($node['ram']??'-')?>%</td>
              <td style="font-size:.85rem"><?=esc($node['disk']??'-')?>%</td>
              <td style="font-size:.8rem;opacity:.7"><?=$node['last_heartbeat'] ? date('d/m H:i', strtotime($node['last_heartbeat'])) : '-'?></td>
              <td>
                <form method="post" style="display:inline">
                  <?=csrf_field()?>
                  <input type="hidden" name="act" value="delete_server">
                  <input type="hidden" name="server_id" value="<?=$node['id']?>">
                  <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Remove this node?',this)">Remove</button>
                </form>
              </td>
            </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
        <?php endif; ?>
      </div>
    </div>
  </div>

</div><!-- .content -->
<script>
function showTab(t,el){
  document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
  document.getElementById('tab-'+t).classList.add('active');
  (el||event.target).classList.add('active');
}
</script>

<script>
// === SERVER MONITORING - Auto-refresh every 30s ===
let monitorTimer = null;
let monitorInterval = 30000;

function startMonitorRefresh() {
    fetchMonitorData();
    if (monitorTimer) clearInterval(monitorTimer);
    monitorTimer = setInterval(fetchMonitorData, monitorInterval);
}

function fetchMonitorData() {
    fetch('/admin/?ajax_monitor_list&t=' + Date.now())
        .then(r => r.json())
        .then(servers => {
            servers.forEach(s => {
                fetch('/admin/?ajax_monitor_single=' + encodeURIComponent(s.code) + '&t=' + Date.now())
                    .then(r => r.json())
                    .then(data => updateServerRow(s.code, data))
                    .catch(() => updateServerRow(s.code, null));
            });
        });
}

function updateServerRow(code, data) {
    const safeCode = encodeURIComponent(code);
    if (!data || !data.success) {
        updateCell('ping', code, '<span style="color:var(--danger)">OFF</span>');
        updateCell('uptime', code, '<span style="color:var(--danger)">-</span>');
        updateCell('cpu', code, '-');
        updateCell('ram', code, '-');
        updateCell('accounts', code, '-');
        updateCell('status', code, '<span class="badge b-danger">OFFLINE</span>');
        return;
    }
    updateCell('ping', code, data.ping_ms !== null ? (data.ping_ms || '?') + 'ms' : '<span style="color:var(--danger)">?</span>');
    updateCell('uptime', code, data.uptime || '?');
    updateCell('cpu', code, data.cpu !== null ? colorByLoad(data.cpu, 'cpu') : '-');
    updateCell('ram', code, data.ram !== null ? colorByLoad(data.ram, 'ram') : '-');
    
    const accts = (data.ssh_count||0) + (data.vmess_count||0) + (data.vless_count||0) + (data.trojan_count||0);
    updateCell('accounts', code, '<span title="SSH:' + (data.ssh_count||0) + ' V:' + (data.vmess_count||0) + '">' + accts + '</span>');
    
    const online = (data.xray === 'active' || data.nginx === 'active' || data.ssh === 'active');
    updateCell('status', code, online ? '<span class="badge b-online">ONLINE</span>' : '<span class="badge b-warning">DEGR</span>');
}

function updateCell(cls, code, html) {
    try {
        var safe = CSS.escape(code);
        document.querySelectorAll('.mon-' + cls + '[data-code="' + safe + '"]').forEach(function(el) {
            el.innerHTML = html;
        });
    } catch(e) {
        document.querySelectorAll('[data-code="' + code + '"].mon-' + cls).forEach(function(el) {
            el.innerHTML = html;
        });
    }
}

function colorByLoad(val, type) {
    const v = parseInt(val);
    let color = 'var(--success)';
    if (isNaN(v)) return val;
    if (type === 'cpu') {
        if (v > 200) color = 'var(--danger)';
        else if (v > 100) color = 'var(--warning)';
    } else if (type === 'ram') {
        if (v > 90) color = 'var(--danger)';
        else if (v > 70) color = 'var(--warning)';
    }
    return '<span style="color:' + color + ';font-weight:600">' + val + '</span>';
}

// Start monitoring when servers tab is shown
document.addEventListener('DOMContentLoaded', () => {
    const observer = new MutationObserver(() => {
        const serversTab = document.getElementById('tab-servers');
        if (serversTab && serversTab.classList.contains('active')) {
            startMonitorRefresh();
        }
    });
    const tab = document.getElementById('tab-servers');
    if (tab) observer.observe(tab, {attributes: true, attributeFilter: ['class']});
    if (tab && tab.classList.contains('active')) startMonitorRefresh();
});

// === MULTI-VPS ===
function copySecret() {
    const inp = document.getElementById('joinSecretInput');
    inp.select();
    document.execCommand('copy');
    document.getElementById('secretStatus').innerHTML = '<span style="color:var(--success)">&#10003; Copied!</span>';
    setTimeout(() => document.getElementById('secretStatus').innerHTML = '', 2000);
}

function copyCmd() {
    const inp = document.getElementById('joinCmdInput');
    inp.select();
    document.execCommand('copy');
    document.getElementById('secretStatus').innerHTML = '<span style="color:var(--success)">&#10003; Command copied!</span>';
    setTimeout(() => document.getElementById('secretStatus').innerHTML = '', 2000);
}

function generateSecret() {
    if (!confirm('Generate new join secret? Existing connected nodes will need the new secret to re-register.')) return;
    const secret = Array.from({length: 4}, () => Math.random().toString(36).substring(2, 8)).join('-');
    fetch('/admin/', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        credentials: 'same-origin',
        body: 'action=save_settings&vpn_join_secret=' + encodeURIComponent(secret)
    }).then(r => {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        document.getElementById('secretStatus').innerHTML = '<span style="color:var(--success)">&#10003; Secret generated! Refreshing...</span>';
        setTimeout(() => location.reload(), 1000);
    }).catch(e => {
        document.getElementById('secretStatus').innerHTML = '<span style="color:var(--danger)">&#10007; Gagal: ' + e.message + '</span>';
    });
}

function refreshNodes() {
    location.reload();
}

function showSaldoModal(uid,uname,saldo) {
  const m=document.getElementById('saldoModal');
  document.getElementById('saldoUser').textContent=uname;
  document.getElementById('saldoCurrent').textContent='Rp '+new Intl.NumberFormat('id-ID').format(saldo);
  document.getElementById('saldoUserId').value=uid;
  document.getElementById('saldoNominal').value='';
  document.getElementById('saldoResult').innerHTML='';
  m.style.display='flex';
}
function closeSaldoModal(){document.getElementById('saldoModal').style.display='none'}
function submitSaldo(mode){
  const uid=document.getElementById('saldoUserId').value;
  const nom=document.getElementById('saldoNominal').value;
  if(!nom||parseInt(nom)<=0){document.getElementById('saldoResult').innerHTML='<span style="color:var(--danger)">Masukkan nominal valid</span>';return}
  const fd=new FormData();
  fd.append('action','adjust_saldo');fd.append('user_id',uid);
  fd.append('nominal',nom);fd.append('mode',mode);
  fetch('/admin/',{method:'POST',body:fd}).then(()=>{closeSaldoModal();location.reload()});
}
</script>

<!-- Saldo Modal -->
<div id="saldoModal" style="display:none;position:fixed;inset:0;z-index:9999;background:rgba(0,0,0,0.6);backdrop-filter:blur(4px);align-items:center;justify-content:center">
  <div style="background:#0f1929;border:1px solid var(--border);border-radius:16px;padding:1.5rem;width:90%;max-width:380px;box-shadow:0 24px 80px rgba(0,0,0,0.5)">
    <div style="font-size:1rem;font-weight:700;margin-bottom:1rem">Atur Saldo</div>
    <p style="font-size:.85rem;margin-bottom:.75rem">User: <strong id="saldoUser"></strong> — Saldo saat ini: <strong id="saldoCurrent" style="color:var(--green)"></strong></p>
    <input type="hidden" id="saldoUserId">
    <div class="form-group"><label class="lbl">Nominal</label>
      <input type="number" id="saldoNominal" min="1" placeholder="Masukkan nominal" style="width:100%;padding:.65rem .75rem;border-radius:8px;border:1px solid var(--border);background:var(--bg2);color:var(--fg);font-size:.9rem"></div>
    <div id="saldoResult" style="font-size:.8rem;margin-bottom:.5rem"></div>
    <div style="display:flex;gap:.5rem;margin-top:.75rem">
      <button class="btn btn-primary" style="flex:1" onclick="submitSaldo('tambah')">+ Tambah</button>
      <button class="btn btn-danger" style="flex:1" onclick="submitSaldo('kurang')">- Kurang</button>
      <button class="btn btn-outline" onclick="closeSaldoModal()">Batal</button>
    </div>
  </div>
</div>

  </main>
</div>
</body>
</html>
