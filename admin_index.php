<?php
require_once __DIR__.'/includes/config.php';
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
            $data['nama_server'] = 'VPS Lokal (Master)';
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
            $mon['nama_server'] = $s['nama_server'];
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
    $servers = $db->query("SELECT code_server, nama_server FROM servers WHERE status='ready' ORDER BY nama_server")->fetchAll();
    foreach ($servers as $s) {
        $codes[] = ['code' => $s['code_server'], 'name' => $s['nama_server']];
    }
    echo json_encode($codes);
    exit;
}


// Handle POST actions
if ($_SERVER['REQUEST_METHOD']==='POST') {
    $act = $_POST['action'] ?? '';

    if ($act==='approve_topup') {
        $tid = (int)$_POST['topup_id'];
        $r = $db->prepare("SELECT * FROM topup_requests WHERE id=? AND status='pending'");
        $r->execute([$tid]); $req=$r->fetch();
        if ($req) {
            $db->prepare("UPDATE topup_requests SET status='approved', processed_at=NOW() WHERE id=?")->execute([$tid]);
            $db->prepare("UPDATE users SET saldo=saldo+? WHERE id=?")->execute([$req['amount'],$req['user_id']]);
            $db->prepare("INSERT INTO transactions (user_id,type,amount,keterangan,status) VALUES (?,?,?,?,'success')")
               ->execute([$req['user_id'],'topup',$req['amount'],'Topup disetujui admin']);
            $u=$db->prepare("SELECT username FROM users WHERE id=?");$u->execute([$req['user_id']]);$uname=$u->fetchColumn();
            sendTelegramNotif("Active Topup <b>{$uname}</b> ".formatRupiah($req['amount'])." disetujui");
        }
        header('Location: /ordervpn/admin/'); exit;
    }

    if ($act==='reject_topup') {
        $tid=(int)$_POST['topup_id'];
        $db->prepare("UPDATE topup_requests SET status='rejected', admin_note=?, processed_at=NOW() WHERE id=?")
           ->execute([sanitize($_POST['note']??''),$tid]);
        header('Location: /ordervpn/admin/'); exit;
    }

    if ($act==='auto_detect_server') {
        $ip      = sanitize($_POST['host'] ?? '');
        $port    = (int)($_POST['port'] ?? 22);
        $user    = sanitize($_POST['ssh_user'] ?? 'root');
        $pass    = $_POST['ssh_password'] ?? '';
        $sshKey  = $_POST['ssh_key'] ?? '';
        $authType = $_POST['auth_type'] ?? 'password';
        
        if ($authType === 'key' && empty($sshKey)) {
            header('Location: /ordervpn/admin/?auto_error=' . urlencode('SSH Key path wajib diisi'));
            exit;
        }
        if ($authType === 'password' && empty($pass)) {
            header('Location: /ordervpn/admin/?auto_error=' . urlencode('Password wajib diisi'));
            exit;
        }
        
        // Build probe command based on auth type
        if ($authType === 'key') {
            // For SSH key, use empty password (bridge will use key)
            $pass = '';
        }
        $code    = sanitize($_POST['code_server'] ?? '');
        $nama    = sanitize($_POST['nama_server'] ?? '');
        
        if (empty($ip) || empty($pass) || empty($code)) {
            header('Location: /ordervpn/admin/?auto_error=' . urlencode('IP, Password, dan Kode Server wajib diisi'));
            exit;
        }
        
        // Panggil vpn-api probe
        $cmd = "timeout 30 vpn-api probe " . escapeshellarg($ip) . " " . escapeshellarg($user) . " " . escapeshellarg($pass) . " " . $port . " 2>/dev/null";
        $output = shell_exec($cmd);
        $result = json_decode($output, true);
        
        if (!$result || empty($result['success'])) {
            $msg = $result['message'] ?? 'Gagal koneksi ke server remote';
            header('Location: /ordervpn/admin/?auto_error=' . urlencode($msg));
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
        $db->prepare("INSERT INTO servers (nama_server,code_server,lokasi,flag,harga_hari,harga_bulan,host,port,ssh_user,ssh_password,domain,status)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,'ready')")
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
        
        header('Location: /ordervpn/admin/?auto_success=' . urlencode("Server $code ($ip) berhasil ditambahkan! Region: $lokasi"));
        exit;
    }
    
if ($act==='add_server') {
        $db->prepare("INSERT INTO servers (nama_server,code_server,lokasi,flag,harga_hari,harga_bulan,host,port,ssh_user,ssh_password,ssh_key,domain,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'ready')")
           ->execute([
               sanitize($_POST['nama_server']), sanitize($_POST['code_server']),
               sanitize($_POST['lokasi']), sanitize($_POST['flag']??'🇮🇩'),
               (float)$_POST['harga_hari'], (float)$_POST['harga_bulan'],
               sanitize($_POST['host']), (int)($_POST['port']??22),
               sanitize($_POST['ssh_user']??'root'), sanitize($_POST['ssh_password']??''),
               sanitize($_POST['ssh_key']??''), sanitize($_POST['domain']??''),
           ]);
        header('Location: /ordervpn/admin/'); exit;
    }

    if ($act==='delete_server') {
        $db->prepare("DELETE FROM servers WHERE id=?")->execute([(int)$_POST['server_id']]);
        header('Location: /ordervpn/admin/'); exit;
    }

    if ($act==='save_settings') {
        $keys=['app_name','app_logo','contact_wa','contact_tg','contact_ig',
               'bank_name','bank_account','bank_holder','dana_number','gopay_number','shopee_number',
               'smtp_host','smtp_port','smtp_user','smtp_pass','smtp_from',
               'tg_bot_token','tg_chat_id','tripay_api_key','tripay_private_key','tripay_merchant_code','tripay_mode',
               'trial_duration_hours','trial_quota_gb','announce_1','announce_2','announce_3'];
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
                   ->execute(['/ordervpn/uploads/'.$fname,'/ordervpn/uploads/'.$fname]);
            }
        }
        header('Location: /ordervpn/admin/?saved=1'); exit;
    }

    if ($act==='toggle_server') {
        $sid=(int)$_POST['server_id']; $s=sanitize($_POST['status']);
        $db->prepare("UPDATE servers SET status=? WHERE id=?")->execute([$s,$sid]);
        header('Location: /ordervpn/admin/'); exit;
    }

    if ($act==='delete_user') {
        $uid=(int)$_POST['user_id'];
        if($uid!==$session['user_id']) $db->prepare("DELETE FROM users WHERE id=?")->execute([$uid]);
        header('Location: /ordervpn/admin/'); exit;
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
$servers       = $db->query("SELECT * FROM servers ORDER BY nama_server")->fetchAll();
$users         = $db->query("SELECT * FROM users ORDER BY created_at DESC LIMIT 100")->fetchAll();
$orders        = $db->query("SELECT t.*, u.username FROM transactions t JOIN users u ON t.user_id=u.id WHERE t.type='order' ORDER BY t.created_at DESC LIMIT 50")->fetchAll();
$allAkuns      = $db->query("SELECT va.*, u.username as uname, s.nama_server FROM vpn_accounts va JOIN users u ON va.user_id=u.id JOIN servers s ON va.server_id=s.id ORDER BY va.created_at DESC LIMIT 50")->fetchAll();

$appName = getSetting('app_name','OrderVPN');
$saved   = isset($_GET['saved']);
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Admin — <?=$appName?></title>
<style>
:root {
  --bg: #080c14;
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
  --shadow-glow: 0 4px 12px rgba(99,102,241,0.3);
  --transition: 0.2s cubic-bezier(.4,0,.2,1);
}
*{box-sizing:border-box;margin:0;padding:0}
body{
  font-family:'Inter','Segoe UI',system-ui,-apple-system,sans-serif;
  background:var(--bg);color:var(--text);
  min-height:100vh;line-height:1.6;
  -webkit-font-smoothing:antialiased;
}
a{color:var(--accent);text-decoration:none;transition:var(--transition)}
a:hover{color:var(--primary)}

.topbar{
  position:sticky;top:0;z-index:100;
  display:flex;align-items:center;justify-content:space-between;
  padding:0 24px;height:60px;
  background:rgba(12,17,27,.85);
  backdrop-filter:blur(16px) saturate(180%);
  border-bottom:1px solid var(--border);gap:16px;
}
.topbar-brand{font-size:1.1em;font-weight:700;background:linear-gradient(135deg,var(--primary),var(--accent));-webkit-background-clip:text;background-clip:text;color:transparent;letter-spacing:-.3px}
.admin-badge{font-size:.75em;font-weight:600;text-transform:uppercase;letter-spacing:.8px;background:rgba(99,102,241,.15);color:var(--primary);padding:4px 10px;border-radius:20px;margin-left:6px}

.tabs-bar{
  display:flex;flex-wrap:wrap;gap:4px;
  padding:12px 24px;
  background:var(--card);
  border-bottom:1px solid var(--border);
  position:sticky;top:60px;z-index:99;
}
.tabs-bar .tab-btn{
  padding:8px 16px;border-radius:var(--radius-sm);
  background:transparent;border:none;color:var(--text-dim);
  font-size:.82em;font-weight:500;cursor:pointer;
  transition:var(--transition);letter-spacing:.1px;
  white-space:nowrap;
}
.tabs-bar .tab-btn:hover{background:rgba(99,102,241,.08);color:var(--text)}
.tabs-bar .tab-btn.active{background:rgba(99,102,241,.12);color:var(--primary);font-weight:600}
.tabs-bar .tab-btn .badge-count{
  display:inline-flex;align-items:center;justify-content:center;
  background:var(--danger);color:#fff;
  font-size:.62rem;min-width:18px;height:18px;padding:0 5px;
  border-radius:99px;margin-left:4px;vertical-align:middle;
}

.content-wrap{padding:24px 28px;max-width:1280px}

.page{display:none}
.page.active{display:block;animation:fadeIn .25s ease}
@keyframes fadeIn{from{opacity:0;transform:translateY(4px)}to{opacity:1;transform:translateY(0)}}

.card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);overflow:hidden;margin-bottom:24px;transition:var(--transition)}
.card:hover{border-color:var(--border-light);box-shadow:var(--shadow-lg)}
.card-header{display:flex;align-items:center;justify-content:space-between;padding:16px 20px;border-bottom:1px solid var(--border-light);gap:12px}
.card-title{font-size:.92em;font-weight:600;color:var(--text);letter-spacing:-.1px;display:flex;align-items:center;gap:8px}
.card-title svg{color:var(--primary)}
.card-body{padding:20px}

.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:16px;margin-bottom:24px}
.stat-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:20px;display:flex;align-items:center;gap:16px;box-shadow:var(--shadow);transition:var(--transition);position:relative;overflow:hidden}
.stat-card:hover{border-color:var(--border-light);box-shadow:var(--shadow-lg);transform:translateY(-2px)}
.stat-card::after{content:'';position:absolute;top:0;left:0;right:0;height:2px;opacity:0;transition:var(--transition)}
.stat-card:hover::after{opacity:1}
.si-users::after{background:linear-gradient(90deg,var(--primary),var(--accent))}
.si-vpn::after{background:linear-gradient(90deg,var(--success),#34d399)}
.si-orders::after{background:linear-gradient(90deg,var(--warning),#fbbf24)}
.si-revenue::after{background:linear-gradient(90deg,var(--purple),#a78bfa)}
.stat-icon{width:44px;height:44px;border-radius:var(--radius-sm);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.9em;flex-shrink:0}
.si-users .stat-icon{background:rgba(99,102,241,.15);color:var(--primary)}
.si-vpn .stat-icon{background:rgba(16,185,129,.12);color:var(--success)}
.si-orders .stat-icon{background:rgba(245,158,11,.12);color:var(--warning)}
.si-revenue .stat-icon{background:rgba(139,92,246,.12);color:var(--purple)}
.stat-val{font-size:1.5em;font-weight:700;line-height:1.2;letter-spacing:-.5px}
.stat-label{font-size:.78em;color:var(--muted);font-weight:500;margin-top:2px;text-transform:uppercase;letter-spacing:.04em}

.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:.86em}
th{text-align:left;padding:12px 14px;font-size:.72em;font-weight:600;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);border-bottom:2px solid var(--border);white-space:nowrap}
td{padding:11px 14px;border-bottom:1px solid var(--border);color:var(--text-dim)}
tr:hover td{background:rgba(99,102,241,.03)}
.text-mono{font-family:'SF Mono','Fira Code','Consolas',monospace;font-size:.82em}

.badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:.72em;font-weight:600;letter-spacing:.4px;text-transform:uppercase;white-space:nowrap}
.b-pending{background:rgba(245,158,11,.12);color:var(--warning)}
.b-approved,.b-active,.b-success{background:var(--success-bg);color:var(--success)}
.b-rejected,.b-danger{background:var(--danger-bg);color:var(--danger)}
.b-ready{background:rgba(59,130,246,.12);color:var(--info)}
.b-offline{background:rgba(100,116,139,.1);color:var(--muted)}
.b-maintenance{background:rgba(245,158,11,.1);color:var(--warning)}
.b-online,.b-yes{background:var(--success-bg);color:var(--success)}
.b-warning{background:rgba(245,158,11,.1);color:var(--warning)}

.btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;padding:9px 18px;border-radius:var(--radius-sm);font-size:.84em;font-weight:600;letter-spacing:.2px;border:none;cursor:pointer;transition:var(--transition);white-space:nowrap}
.btn-primary{background:linear-gradient(135deg,var(--primary),#7c3aed);color:#fff}
.btn-primary:hover{box-shadow:var(--shadow-glow);transform:translateY(-1px)}
.btn-green{background:var(--success-bg);color:var(--success);border:1px solid rgba(16,185,129,.25)}
.btn-green:hover{background:rgba(16,185,129,.25)}
.btn-red{background:var(--danger-bg);color:var(--danger);border:1px solid rgba(239,68,68,.2)}
.btn-red:hover{background:rgba(239,68,68,.2)}
.btn-outline{background:transparent;color:var(--text-dim);border:1px solid var(--border)}
.btn-outline:hover{border-color:var(--primary);color:var(--primary)}
.btn-yellow{background:rgba(245,158,11,.15);color:var(--warning);border:1px solid rgba(245,158,11,.25)}
.btn-yellow:hover{background:rgba(245,158,11,.25)}
.btn-sm{padding:5px 12px;font-size:.78em}
.btn-xs{padding:3px 8px;font-size:.7em;border-radius:6px}

label{display:block;margin-bottom:6px;font-size:.78em;font-weight:600;text-transform:uppercase;letter-spacing:.5px;color:var(--muted)}
input,select,textarea{width:100%;padding:10px 14px;background:var(--bg-alt);border:1px solid var(--border);border-radius:var(--radius-sm);color:var(--text);font-size:.9em;font-family:inherit;transition:var(--transition);outline:none}
input:focus,select:focus,textarea:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(99,102,241,.12)}
select{cursor:pointer}
textarea{resize:vertical;min-height:80px}
.form-group{margin-bottom:14px}
.form-row{display:flex;gap:12px}
.form-row>.form-group{flex:1}
.section-title{font-size:.82em;font-weight:700;color:var(--primary);text-transform:uppercase;letter-spacing:.8px;margin:20px 0 12px;padding-bottom:8px;border-bottom:1px solid var(--border)}
.alert{padding:12px 16px;border-radius:var(--radius-sm);font-size:.85em;font-weight:500;margin-bottom:16px;display:flex;align-items:center;gap:8px}
.alert-success{background:var(--success-bg);color:var(--success);border:1px solid rgba(16,185,129,.2)}
.alert-error{background:var(--danger-bg);color:var(--danger);border:1px solid rgba(239,68,68,.15)}

.grid2{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px}

@media(max-width:768px){.grid2,.grid3{grid-template-columns:1fr}}
@media(max-width:768px){
  .layout{flex-direction:column}
  .layout-sidebar{width:100%;min-width:100%;border-right:none;border-bottom:1px solid var(--border);max-height:50vh}
  .main-wrap{padding:20px 16px}
  .stats{grid-template-columns:1fr 1fr}
  .form-row{flex-direction:column}
  .topbar{padding:0 16px}
}
@media(max-width:480px){.stats{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="topbar">
  <div class="topbar-brand">
    <span><?=getSetting('app_logo','OVPN')?></span>
    <?=$appName?> <span class="admin-badge">Admin</span>
  </div>
  <div style="display:flex;gap:.5rem;align-items:center">
    <div class="sidebar-links">
                    <a href="/ordervpn/dashboard.php" class="sidebar-link">User Panel</a>
    <a href="/ordervpn/api/logout.php" class="sidebar-link danger">Logout</a>
                </div>
  </div>
</div>

<div class="tabs-bar">
  <button class="tab-btn active" onclick="showTab('dashboard')">Dashboard</button>
  <button class="tab-btn" onclick="showTab('topup')">Topup<?php if($stats['topup_p']>0):?><span class="badge-count"><?=$stats['topup_p']?></span><?php endif;?></button>
  <button class="tab-btn" onclick="showTab('servers')">Server</button>
  <button class="tab-btn" onclick="showTab('users')">Users</button>
  <button class="tab-btn" onclick="showTab('orders')">Orders</button>
  <button class="tab-btn" onclick="showTab('akuns')">VPN Accounts</button>
  <button class="tab-btn" onclick="showTab('settings')">Settings</button>
  <a href="../change_password.php" class="tab-btn" style="color:#f59e0b">Password</a>
</div>

<div class="content-wrap">
  <?php if($saved):?><div class="alert alert-success">Settings saved successfully.</div><?php endif;?>

  <!-- DASHBOARD -->
  <div class="page active" id="tab-dashboard">
    <div class="stats">
      <div class="stat-card si-users"><div class="stat-icon">U</div><div class="stat-val"><?=$stats['users']?></div><div class="stat-label">Total Users</div></div>
      <div class="stat-card si-vpn"><div class="stat-icon">V</div><div class="stat-val"><?=$stats['akun']?></div><div class="stat-label">Akun Aktif</div></div>
      <div class="stat-card si-orders"><div class="stat-icon">O</div><div class="stat-val"><?=$stats['orders']?></div><div class="stat-label">Total Order</div></div>
      <div class="stat-card si-revenue"><div class="stat-icon">Rp</div><div class="stat-val"><?=formatRupiah($stats['revenue'])?></div><div class="stat-label">Total Revenue</div></div>
      <div class="stat-card"><div class="stat-icon">!</div><div class="stat-val" style="color:var(--warning)"><?=$stats['topup_p']?></div><div class="stat-label">Topup Pending</div></div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Pending Topup</div></div>
      <div class="card-body">
        <?php if(empty($pendingTopups)):?><p style="color:var(--muted);font-size:.875rem">Tidak ada topup pending.</p>
        <?php else: foreach($pendingTopups as $t):?>
        <div style="display:flex;align-items:center;justify-content:space-between;padding:.75rem;background:var(--card2);border-radius:10px;margin-bottom:.5rem;border:1px solid #92400e44;gap:1rem;flex-wrap:wrap">
          <div>
            <div style="font-weight:600;font-size:.875rem"><?=htmlspecialchars($t['username'])?></div>
            <div style="font-size:.75rem;color:var(--muted)"><?=htmlspecialchars($t['payment_method'])?> · <?=date('d M Y H:i',strtotime($t['created_at']))?></div>
            <?php if($t['bukti_transfer']):?><a href="<?=htmlspecialchars($t['bukti_transfer'])?>" target="_blank" class="btn btn-outline" style="margin-top:.35rem;font-size:.7rem">View Bukti</a><?php endif;?>
          </div>
          <div style="font-size:1rem;font-weight:800;color:var(--yellow)"><?=formatRupiah($t['amount'])?></div>
              <hr style="border-color:#1e3a5f;margin:1.5rem 0 1rem">
              <h3 style="font-size:1rem;font-weight:700;color:#f1f5f9;margin-bottom:1rem;">[ Pengumuman / Promo di Halaman Login ]</h3>
              <p style="font-size:.78rem;color:#64748b;margin-bottom:1rem;">
                Format: <code style="background:#0a1628;padding:2px 6px;border-radius:4px;">BADGE|TEKS</code> — BADGE: BARU, PROMO, atau INFO. Kosongkan untuk menyembunyikan.
              </p>

              <div class="form-group">
                <label class="lbl">Pengumuman 1</label>
                <div style="display:flex;gap:.5rem;">
                  <select name="announce_1_badge" style="width:100px;padding:.7rem .6rem;background:#0a1628;border:1px solid #1e3a5f;border-radius:8px;color:#f1f5f9;font-size:.85rem;font-family:inherit;">
                    <option value="BARU">BARU</option>
                    <option value="PROMO">PROMO</option>
                    <option value="INFO">INFO</option>
                  </select>
                  <input type="text" name="announce_1_text" placeholder="Teks pengumuman 1..."
                         style="flex:1" value="">
                </div>
                <input type="hidden" name="announce_1" id="announce_1_final" value="<?=htmlspecialchars(getSetting('announce_1',''))?>">
              </div>

              <div class="form-group">
                <label class="lbl">Pengumuman 2</label>
                <div style="display:flex;gap:.5rem;">
                  <select name="announce_2_badge" style="width:100px;padding:.7rem .6rem;background:#0a1628;border:1px solid #1e3a5f;border-radius:8px;color:#f1f5f9;font-size:.85rem;font-family:inherit;">
                    <option value="BARU">BARU</option>
                    <option value="PROMO">PROMO</option>
                    <option value="INFO">INFO</option>
                  </select>
                  <input type="text" name="announce_2_text" placeholder="Teks pengumuman 2..."
                         style="flex:1" value="">
                </div>
                <input type="hidden" name="announce_2" id="announce_2_final" value="<?=htmlspecialchars(getSetting('announce_2',''))?>">
              </div>

              <div class="form-group">
                <label class="lbl">Pengumuman 3</label>
                <div style="display:flex;gap:.5rem;">
                  <select name="announce_3_badge" style="width:100px;padding:.7rem .6rem;background:#0a1628;border:1px solid #1e3a5f;border-radius:8px;color:#f1f5f9;font-size:.85rem;font-family:inherit;">
                    <option value="BARU">BARU</option>
                    <option value="PROMO">PROMO</option>
                    <option value="INFO">INFO</option>
                  </select>
                  <input type="text" name="announce_3_text" placeholder="Teks pengumuman 3..."
                         style="flex:1" value="">
                </div>
                <input type="hidden" name="announce_3" id="announce_3_final" value="<?=htmlspecialchars(getSetting('announce_3',''))?>">
              </div>

              <script>
              // Combine badge + text into final hidden fields before submit
              (function(){
                var form = document.querySelector('form[action*="save_settings"]') || 
                           Array.from(document.querySelectorAll('form')).find(function(f){ return f.querySelector('[name="action"][value="save_settings"]'); });
                if(form){
                  form.addEventListener('submit', function(){
                    for(var i=1;i<=3;i++){
                      var badge = form.querySelector('[name="announce_'+i+'_badge"]');
                      var text = form.querySelector('[name="announce_'+i+'_text"]');
                      var final = form.querySelector('#announce_'+i+'_final');
                      if(badge && text && final){
                        final.value = text.value.trim() ? (badge.value + '|' + text.value.trim()) : '';
                      }
                    }
                  });
                  // Pre-fill badge selects from saved values
                  if(form){
                    (function prefill(){
                      for(var i=1;i<=3;i++){
                        var final = form.querySelector('#announce_'+i+'_final');
                        var badge = form.querySelector('[name="announce_'+i+'_badge"]');
                        var text = form.querySelector('[name="announce_'+i+'_text"]');
                        if(final && badge && final.value){
                          var parts = final.value.split('|');
                          if(parts.length >= 2){
                            badge.value = parts[0];
                            if(!text.value) text.value = parts.slice(1).join('|');
                          }
                        }
                      }
                    })();
                  }
                }
              })();
              </script>

          <div style="display:flex;gap:.4rem;flex-wrap:wrap">
            <form method="POST" style="display:inline"><input type="hidden" name="action" value="approve_topup"><?php echo csrfField(); ?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><button type="submit" class="btn btn-green">Active Approve</button></form>
            <form method="POST" style="display:inline"><input type="hidden" name="action" value="reject_topup"><?php echo csrfField(); ?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><input type="hidden" name="note" value="Ditolak admin"><button type="submit" class="btn btn-red">Tolak</button></form>
          </div>
        </div>
        <?php endforeach; endif;?>
      </div>
    </div>
  </div>

  <!-- TOPUP -->
  <div class="page" id="tab-topup">
    <div class="card">
      <div class="card-header"><div class="card-title"> Topup History</div></div>
      <div class="card-body overflow-x">
        <table>
          <thead><tr><th>User</th><th>Nominal</th><th>Metode</th><th>Status</th><th>Tanggal</th><th>Server</th><th>Aksi</th></tr></thead>
          <tbody>
          <?php foreach($allTopups as $t):?>
          <tr>
            <td><?=htmlspecialchars($t['username'])?></td>
            <td style="font-weight:700"><?=formatRupiah($t['amount'])?></td>
            <td><?=htmlspecialchars($t['payment_method'])?></td>
            <td><span class="badge b-<?=$t['status']?>"><?=$t['status']?></span></td>
            <td><?=date('d M Y H:i',strtotime($t['created_at']))?></td>
            <td>
              <?php if($t['status']==='pending'):?>
              <form method="POST" style="display:inline"><input type="hidden" name="action" value="approve_topup"><?php echo csrfField(); ?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><button class="btn btn-green">Active</button></form>
              <form method="POST" style="display:inline"><input type="hidden" name="action" value="reject_topup"><?php echo csrfField(); ?><input type="hidden" name="topup_id" value="<?=$t['id']?>"><input type="hidden" name="note" value="Ditolak"><button class="btn btn-red">Reject</button></form>
              <?php endif;?>
              <?php if($t['bukti_transfer']):?><a href="<?=htmlspecialchars($t['bukti_transfer'])?>" target="_blank" class="btn btn-outline">View</a><?php endif;?>
            </td>
          </tr>
          <?php endforeach;?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- SERVERS -->
  <div class="page" id="tab-servers">
    <div class="card">
      <div class="card-header"><div class="card-title">Server List</div><button class="btn btn-primary" onclick="document.getElementById('addServerForm').style.display=document.getElementById('addServerForm').style.display==='none'?'block':'none'">+ Tambah Server</button></div>
      <div id="autoDetectForm" style="padding:1.25rem;border-bottom:1px solid var(--border);background:linear-gradient(135deg, rgba(99,102,241,.05), rgba(139,92,246,.05))">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:1rem">
            <div>
                <strong style="font-size:.9rem;color:var(--primary)">⚡ Auto-Detect & Add Server</strong>
                <p style="font-size:.72rem;color:var(--muted);margin-top:2px">Deteksi otomatis: region, domain, port, OS — tinggal isi IP & password</p>
            </div>
        </div>
        <form method="POST">
            <input type="hidden" name="action" value="auto_detect_server">
            <?php echo csrfField(); ?>
            <div class="grid2">
            <div><label>Nama Server</label><input name="nama_server" placeholder="BIZNET IDC" required></div>
            <div><label>Kode Server</label><input name="code_server" placeholder="sgp1" required></div>
            <div><label>Lokasi</label><input name="lokasi" placeholder="Singapura" required></div>
            <div><label>Flag Emoji</label><input name="flag" placeholder="🇸🇬" value="🇮🇩"></div>
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
        <table>
          <thead><tr><th>Server</th><th>Ping</th><th>Uptime</th><th>CPU</th><th>RAM</th><th>Akun</th><th>Lokasi</th><th>Harga/Hari</th><th>Status</th><th>Aksi</th></tr></thead>
          <tbody>
          <?php foreach($servers as $s):?>
          <tr data-server="<?=$s['code_server']?>">
            <td><strong><?=htmlspecialchars($s['nama_server'])?></strong><br><span class="text-mono"><?=htmlspecialchars($s['code_server'])?></span></td>
            <td class="mon-ping" data-code="<?=$s['code_server']?>">⟳</td>
            <td class="mon-uptime" data-code="<?=$s['code_server']?>">⟳</td>
            <td class="mon-cpu" data-code="<?=$s['code_server']?>">⟳</td>
            <td class="mon-ram" data-code="<?=$s['code_server']?>">⟳</td>
            <td class="mon-accounts" data-code="<?=$s['code_server']?>">⟳</td>
            <td><?=$s['flag']??'🇮🇩'?> <?=htmlspecialchars($s['lokasi'])?></td>
            <td><?=formatRupiah($s['harga_hari'])?></td>
            <td><span class="badge b-<?=$s['status']?>"><?=$s['status']?></span></td>
            <td style="display:flex;gap:.35rem;flex-wrap:wrap">
              <form method="POST" style="display:inline">
                <input type="hidden" name="action" value="toggle_server">
                <input type="hidden" name="server_id" value="<?=$s['id']?>">
                <input type="hidden" name="status" value="<?=$s['status']==='ready'?'maintenance':'ready'?>">
                <button class="btn btn-yellow btn-sm"><?=$s['status']==='ready'?'MNT':'▶ ON'?></button>
              </form>
              <form method="POST" style="display:inline" onsubmit="return confirm('Hapus server ini?')">
                <input type="hidden" name="action" value="delete_server"><?php echo csrfField(); ?>
                <input type="hidden" name="server_id" value="<?=$s['id']?>">
                <button class="btn btn-red btn-sm">Hapus</button>
              </form>
            </td>
          </tr>
          <?php endforeach;?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- USERS -->
  <div class="page" id="tab-users">
    <div class="card">
      <div class="card-header"><div class="card-title"> Daftar User (<?=count($users)?>)</div></div>
      <div class="card-body overflow-x">
        <table>
          <thead><tr><th>Username</th><th>Email</th><th>Saldo</th><th>Verified</th><th>Role</th><th>Daftar</th><th>Aksi</th></tr></thead>
          <tbody>
          <?php foreach($users as $u):?>
          <tr>
            <td><strong><?=htmlspecialchars($u['username'])?></strong></td>
            <td><?=htmlspecialchars($u['email'])?></td>
            <td style="color:var(--green);font-weight:600"><?=formatRupiah($u['saldo'])?></td>
            <td><?=$u['is_verified']?'Active':'Pending'?></td>
            <td><span class="badge" style="<?=$u['role']==='admin'?'background:#4c1d9522;color:#a78bfa':'background:#0a1628;color:var(--muted)'?>"><?=$u['role']?></span></td>
            <td style="font-size:.75rem"><?=date('d M Y',strtotime($u['created_at']))?></td>
            <td>
              <?php if($u['role']!=='admin'):?>
              <form method="POST" style="display:inline" onsubmit="return confirm('Hapus user <?=htmlspecialchars($u['username'])?>?')">
                <input type="hidden" name="action" value="delete_user"><?php echo csrfField(); ?>
                <input type="hidden" name="user_id" value="<?=$u['id']?>">
                <button class="btn btn-red btn-sm"></button>
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

  <!-- ORDERS / LAPORAN -->
  <div class="page" id="tab-orders">
    <div class="card">
      <div class="card-header"><div class="card-title"> Laporan Pembelian</div></div>
      <div class="card-body overflow-x">
        <table>
          <thead><tr><th>User</th><th>Keterangan</th><th>Nominal</th><th>Status</th><th>Tanggal</th></tr></thead>
          <tbody>
          <?php foreach($orders as $o):?>
          <tr>
            <td><?=htmlspecialchars($o['username'])?></td>
            <td><?=htmlspecialchars($o['keterangan']??'')?></td>
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

  <!-- AKUN VPN -->
  <div class="page" id="tab-akuns">
    <div class="card">
      <div class="card-header"><div class="card-title">All VPN Accounts</div></div>
      <div class="card-body overflow-x">
        <table>
          <thead><tr><th>User</th><th>Username</th><th>Tipe</th><th>Server</th><th>Expired</th><th>Status</th></tr></thead>
          <tbody>
          <?php foreach($allAkuns as $a):?>
          <tr>
            <td><?=htmlspecialchars($a['uname'])?></td>
            <td style="font-family:monospace"><?=htmlspecialchars($a['username'])?><?=$a['is_trial']?' (Trial)':''?></td>
            <td><span class="badge b-active"><?=strtoupper($a['tipe'])?></span></td>
            <td><?=htmlspecialchars($a['nama_server'])?></td>
            <td style="font-size:.75rem"><?=date('d M Y H:i',strtotime($a['masa_aktif']))?></td>
            <td><span class="badge b-<?=$a['status']?>"><?=$a['status']?></span></td>
          </tr>
          <?php endforeach;?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- SETTINGS -->
  <div class="page" id="tab-settings">
    <form method="POST" enctype="multipart/form-data">
    <input type="hidden" name="action" value="save_settings"><?php echo csrfField(); ?>>
    <div class="card">
      <div class="card-header"><div class="card-title">Application Info</div></div>
      <div class="card-body">
        <div class="grid2">
          <div><label>Nama Aplikasi</label><input name="app_name" value="<?=htmlspecialchars(getSetting('app_name','OrderVPN'))?>"></div>
          <div><label>Logo (Emoji)</label><input name="app_logo" value="<?=htmlspecialchars(getSetting('app_logo','OVPN'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Admin Contact</div></div>
      <div class="card-body">
        <div class="grid3">
          <div><label>WhatsApp (nomor)</label><input name="contact_wa" placeholder="628xxxxxxxxxx" value="<?=htmlspecialchars(getSetting('contact_wa'))?>"></div>
          <div><label>Telegram (@username)</label><input name="contact_tg" placeholder="@username" value="<?=htmlspecialchars(getSetting('contact_tg'))?>"></div>
          <div><label>Instagram (@username)</label><input name="contact_ig" placeholder="@username" value="<?=htmlspecialchars(getSetting('contact_ig'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Manual Payment Methods</div></div>
      <div class="card-body">
        <div class="section-title">Bank Transfer</div>
        <div class="grid3">
          <div><label>Nama Bank</label><input name="bank_name" value="<?=htmlspecialchars(getSetting('bank_name','BCA'))?>"></div>
          <div><label>No. Rekening</label><input name="bank_account" value="<?=htmlspecialchars(getSetting('bank_account'))?>"></div>
          <div><label>Atas Nama</label><input name="bank_holder" value="<?=htmlspecialchars(getSetting('bank_holder'))?>"></div>
        </div>
        <div class="section-title">E-Wallet</div>
        <div class="grid3">
          <div><label>Dana (nomor HP)</label><input name="dana_number" placeholder="08xxxxxxxxxx" value="<?=htmlspecialchars(getSetting('dana_number'))?>"></div>
          <div><label>GoPay (nomor HP)</label><input name="gopay_number" placeholder="08xxxxxxxxxx" value="<?=htmlspecialchars(getSetting('gopay_number'))?>"></div>
          <div><label>ShopeePay (nomor HP)</label><input name="shopee_number" placeholder="08xxxxxxxxxx" value="<?=htmlspecialchars(getSetting('shopee_number'))?>"></div>
        </div>
        <div class="section-title">QRIS</div>
        <div><label>Upload Gambar QRIS</label><input type="file" name="qris_image" accept="image/*" style="margin-bottom:.5rem"></div>
        <?php if(getSetting('qris_image')):?><img src="<?=htmlspecialchars(getSetting('qris_image'))?>" style="max-width:150px;border-radius:8px;margin-bottom:.75rem"><?php endif;?>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Email SMTP (Gmail)</div></div>
      <div class="card-body">
        <p style="font-size:.78rem;color:var(--muted);margin-bottom:.75rem">Untuk OTP verifikasi. Gmail: aktifkan 2FA → buat App Password di myaccount.google.com/security</p>
        <div class="grid3">
          <div><label>SMTP Host</label><input name="smtp_host" value="<?=htmlspecialchars(getSetting('smtp_host','smtp.gmail.com'))?>"></div>
          <div><label>Port</label><input name="smtp_port" value="<?=htmlspecialchars(getSetting('smtp_port','587'))?>"></div>
          <div><label>Email Pengirim</label><input name="smtp_from" placeholder="noreply@gmail.com" value="<?=htmlspecialchars(getSetting('smtp_from'))?>"></div>
          <div><label>Username Gmail</label><input name="smtp_user" placeholder="email@gmail.com" value="<?=htmlspecialchars(getSetting('smtp_user'))?>"></div>
          <div><label>App Password Gmail</label><input name="smtp_pass" type="password" placeholder="xxxx xxxx xxxx xxxx" value="<?=htmlspecialchars(getSetting('smtp_pass'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Telegram Bot Notifikasi</div></div>
      <div class="card-body">
        <div class="grid2">
          <div><label>Bot Token</label><input name="tg_bot_token" placeholder="123456:ABC..." value="<?=htmlspecialchars(getSetting('tg_bot_token'))?>"></div>
          <div><label>Chat ID Admin</label><input name="tg_chat_id" placeholder="-100..." value="<?=htmlspecialchars(getSetting('tg_chat_id'))?>"></div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><div class="card-title">Pengaturan Trial</div></div>
      <div class="card-body">
        <div class="grid2">
          <div><label>Durasi Trial (jam)</label><input name="trial_duration_hours" type="number" value="<?=htmlspecialchars(getSetting('trial_duration_hours','1'))?>"></div>
          <div><label>Quota Trial (GB)</label><input name="trial_quota_gb" type="number" value="<?=htmlspecialchars(getSetting('trial_quota_gb','1'))?>"></div>
        </div>
      </div>
    </div>
    <button type="submit" class="btn btn-primary" style="width:100%;padding:.875rem;font-size:.9rem;margin-top:.5rem">Simpan Semua Pengaturan</button>
    </form>
  </div>

</div><!-- .content -->
<script>
function showTab(t){
  document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
  document.getElementById('tab-'+t).classList.add('active');
  event.target.classList.add('active');
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
    // Fetch server list, then monitor each individually (parallel in browser)
    fetch('/ordervpn/admin/?ajax_monitor_list&t=' + Date.now())
        .then(r => r.json())
        .then(servers => {
            servers.forEach(s => {
                fetch('/ordervpn/admin/?ajax_monitor_single=' + encodeURIComponent(s.code) + '&t=' + Date.now())
                    .then(r => r.json())
                    .then(data => updateServerRow(s.code, data))
                    .catch(() => updateServerRow(s.code, null));
            });
        });
}

function updateServerRow(code, data) {
    const safeCode = encodeURIComponent(code); // used in DOM lookup
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
        // Fallback for browsers without CSS.escape
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
    // Watch for tab switches
    const observer = new MutationObserver(() => {
        const serversTab = document.getElementById('tab-servers');
        if (serversTab && serversTab.classList.contains('active')) {
            startMonitorRefresh();
        }
    });
    const tab = document.getElementById('tab-servers');
    if (tab) observer.observe(tab, {attributes: true, attributeFilter: ['class']});
    // Also check on load
    if (tab && tab.classList.contains('active')) startMonitorRefresh();
});
</script>
</body>
</html>
