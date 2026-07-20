<?php
require_once __DIR__.'/includes/config.php';
if (session_status()===PHP_SESSION_NONE) session_start();
if (isset($_SESSION['user_id'])) { header('Location: /ordervpn/dashboard.php'); exit; }

$appName = getSetting('app_name','OrderVPN');
$error = ''; $success = '';

if ($_SERVER['REQUEST_METHOD']==='POST') {
    $action = $_POST['action'] ?? '';

    if ($action==='login') {
        $u = sanitize($_POST['username']??'');
        $p = $_POST['password']??'';
        if (empty($u)||empty($p)) { $error='Username dan password wajib diisi!'; }
        else {
            $db=getDB();
            $st=$db->prepare("SELECT * FROM users WHERE username=? OR email=?");
            $st->execute([$u,$u]); $user=$st->fetch();
            if ($user && password_verify($p,$user['password'])) {
                if (!$user['is_verified'] && $user['role']==='user') {
                    $error='Email belum diverifikasi! Cek inbox kamu.';
                } else {
                    $_SESSION['user_id']=$user['id'];
                    $_SESSION['username']=$user['username'];
                    $_SESSION['role']=$user['role'];
                    $_SESSION['saldo']=$user['saldo'];
                    $ip=$_SERVER['HTTP_X_FORWARDED_FOR']??$_SERVER['REMOTE_ADDR'];
                    $db->prepare("UPDATE users SET ip_address=? WHERE id=?")->execute([$ip,$user['id']]);
                    header('Location: /ordervpn/dashboard.php'); exit;
                }
            } else { $error='Username atau password salah!'; }
        }
    }

    if ($action==='register') {
        $u=sanitize($_POST['reg_username']??'');
        $e=sanitize($_POST['reg_email']??'');
        $p=$_POST['reg_password']??'';
        $c=$_POST['reg_confirm']??'';
        if (empty($u)||empty($e)||empty($p)) { $error='Semua field wajib diisi!'; }
        elseif ($p!==$c) { $error='Password tidak cocok!'; }
        elseif (strlen($p)<6) { $error='Password minimal 6 karakter!'; }
        elseif (!filter_var($e,FILTER_VALIDATE_EMAIL)) { $error='Format email tidak valid!'; }
        else {
            $db=getDB();
            $chk=$db->prepare("SELECT id FROM users WHERE username=? OR email=?");
            $chk->execute([$u,$e]);
            if ($chk->fetch()) { $error='Username atau email sudah digunakan!'; }
            else {
                $otp = str_pad(rand(0,999999),6,'0',STR_PAD_LEFT);
                $otpExp = date('Y-m-d H:i:s', strtotime('+15 minutes'));
                $hash = password_hash($p, PASSWORD_BCRYPT);
    try {
        $db->prepare("INSERT INTO users (username,email,password,otp_code,otp_expires,is_verified) VALUES (?,?,?,?,?,0)")
           ->execute([$u,$e,$hash,$otp,$otpExp]);
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) {
            $error = "Username atau email sudah terdaftar! Gunakan yang lain.";
        } else {
            throw $e;
        }
    }

                $emailBody = "
                <div style='font-family:sans-serif;max-width:480px;margin:0 auto;background:#0f172a;color:#f1f5f9;padding:32px;border-radius:16px;'>
                  <h2 style='color:#60a5fa;margin-bottom:8px;'>&#9889; {$appName}</h2>
                  <p style='color:#94a3b8;'>Verifikasi akun kamu</p>
                  <div style='background:#1e293b;border-radius:12px;padding:24px;margin:24px 0;text-align:center;'>
                    <p style='color:#94a3b8;font-size:14px;margin-bottom:8px;'>Kode OTP kamu:</p>
                    <div style='font-size:40px;font-weight:800;letter-spacing:12px;color:#60a5fa;'>{$otp}</div>
                    <p style='color:#475569;font-size:12px;margin-top:12px;'>Berlaku 15 menit</p>
                  </div>
                  <p style='color:#64748b;font-size:12px;'>Jika kamu tidak mendaftar, abaikan email ini.</p>
                </div>";
                sendEmail($e, "Kode OTP Verifikasi - {$appName}", $emailBody);
                $success='Akun berhasil dibuat! Cek email untuk kode OTP verifikasi.';
            }
        }
    }

    if ($action==='verify_otp') {
        $e=sanitize($_POST['otp_email']??'');
        $otp=sanitize($_POST['otp_code']??'');
        $db=getDB();
        $st=$db->prepare("SELECT * FROM users WHERE email=? AND otp_code=? AND otp_expires > NOW()");
        $st->execute([$e,$otp]); $user=$st->fetch();
        if ($user) {
            $db->prepare("UPDATE users SET is_verified=1, otp_code=NULL, otp_expires=NULL WHERE id=?")->execute([$user['id']]);
            $success='Email berhasil diverifikasi! Silakan login.';
        } else { $error='Kode OTP salah atau sudah expired!'; }
    }

    if ($action==='resend_otp') {
        $e=sanitize($_POST['resend_email']??'');
        $db=getDB();
        $st=$db->prepare("SELECT * FROM users WHERE email=? AND is_verified=0");
        $st->execute([$e]); $user=$st->fetch();
        if ($user) {
            $otp=str_pad(rand(0,999999),6,'0',STR_PAD_LEFT);
            $otpExp=date('Y-m-d H:i:s',strtotime('+15 minutes'));
            $db->prepare("UPDATE users SET otp_code=?,otp_expires=? WHERE id=?")->execute([$otp,$otpExp,$user['id']]);
            $emailBody="<div style='font-family:sans-serif;padding:32px;background:#0f172a;color:#f1f5f9;border-radius:16px;'><h2 style='color:#60a5fa;'>Kode OTP Baru</h2><div style='font-size:40px;font-weight:800;letter-spacing:12px;color:#60a5fa;text-align:center;margin:24px 0;'>{$otp}</div><p style='color:#64748b;font-size:12px;'>Berlaku 15 min.</p></div>";
            sendEmail($e,"Kode OTP Baru - {$appName}",$emailBody);
            $success='OTP baru sudah dikirim ke email kamu.';
        } else { $error='Email tidak ditemukan atau sudah terverifikasi.'; }
    }
}

    // === FORGOT PASSWORD ===
    if ($action==='forgot_password') {
        $e = sanitize($_POST['forgot_email']??'');
        if (empty($e) || !filter_var($e, FILTER_VALIDATE_EMAIL)) {
            $error = 'Masukkan email yang valid!';
        } else {
            $db = getDB();
            $st = $db->prepare("SELECT * FROM users WHERE email=?");
            $st->execute([$e]); $user = $st->fetch();
            if ($user) {
                $otp = str_pad(rand(0,999999), 6, '0', STR_PAD_LEFT);
                $otpExp = date('Y-m-d H:i:s', strtotime('+15 minutes'));
                $db->prepare("UPDATE users SET otp_code=?, otp_expires=? WHERE id=?")
                   ->execute([$otp, $otpExp, $user['id']]);
                $emailBody = "<div style='font-family:sans-serif;max-width:480px;margin:0 auto;background:#0f172a;color:#f1f5f9;padding:32px;border-radius:16px;'>
                  <h2 style='color:#60a5fa;margin-bottom:8px;'>Reset Password - {$appName}</h2>
                  <p style='color:#94a3b8;'>Anda meminta reset password untuk akun <b>{$user['username']}</b>.</p>
                  <div style='background:#1e293b;border-radius:12px;padding:24px;margin:24px 0;text-align:center;'>
                    <p style='color:#94a3b8;font-size:14px;margin-bottom:8px;'>Kode reset password:</p>
                    <div style='font-size:40px;font-weight:800;letter-spacing:12px;color:#60a5fa;'>{$otp}</div>
                    <p style='color:#475569;font-size:12px;margin-top:12px;'>Berlaku 15 menit</p>
                  </div>
                  <p style='color:#64748b;font-size:12px;'>Jika Anda tidak meminta reset password, abaikan email ini.</p>
                </div>";
                sendEmail($e, "Reset Password - {$appName}", $emailBody);
            }
            $success = 'Jika email terdaftar, kode reset password telah dikirim ke inbox Anda. Cek juga folder spam.';
        }
    }

    if ($action==='reset_password') {
        $e = sanitize($_POST['reset_email']??'');
        $otp = sanitize($_POST['reset_otp']??'');
        $np = $_POST['new_password']??'';
        $cp = $_POST['confirm_password']??'';
        if (empty($e) || empty($otp) || empty($np)) {
            $error = 'Semua field wajib diisi!';
        } elseif (strlen($np) < 6) {
            $error = 'Password baru minimal 6 karakter!';
        } elseif ($np !== $cp) {
            $error = 'Password tidak cocok!';
        } else {
            $db = getDB();
            $st = $db->prepare("SELECT * FROM users WHERE email=? AND otp_code=? AND otp_expires > NOW()");
            $st->execute([$e, $otp]); $user = $st->fetch();
            if ($user) {
                $hash = password_hash($np, PASSWORD_BCRYPT);
                $db->prepare("UPDATE users SET password=?, otp_code=NULL, otp_expires=NULL WHERE id=?")
                   ->execute([$hash, $user['id']]);
                $success = 'Password berhasil direset! Silakan login dengan password baru Anda.';
            } else {
                $error = 'Kode OTP salah atau sudah expired!';
            }
        }
    }
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?=$appName?> — Login</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}

:root {
  --bg-deep: #070b14;
  --bg-surface: #0a0f1e;
  --bg-elevated: #101827;
  --bg-card: rgba(15,23,42,0.65);
  --border: rgba(30,58,95,0.4);
  --border-hover: rgba(96,165,250,0.25);
  --text-primary: #f1f5f9;
  --text-secondary: #94a3b8;
  --text-muted: #475569;
  --accent: #6366f1;
  --accent-light: #818cf8;
  --accent-dark: #4f46e5;
  --accent-glow: rgba(99,102,241,0.35);
  --purple: #8b5cf6;
  --danger: #ef4444;
  --danger-bg: rgba(239,68,68,0.1);
  --success: #10b981;
  --success-bg: rgba(16,185,129,0.1);
  --radius: 16px;
  --radius-sm: 10px;
  --radius-xs: 6px;
  --shadow-card: 0 24px 80px rgba(0,0,0,0.5);
  --shadow-glow: 0 8px 32px var(--accent-glow);
  --transition: 0.35s cubic-bezier(0.16,1,0.3,1);
}

body {
  font-family:'Inter','Segoe UI',system-ui,-apple-system,sans-serif;
  background:var(--bg-deep);
  min-height:100vh;overflow-x:hidden;
  color:var(--text-primary);
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale;
}

/* Ambient Background */
.bg-layer{position:fixed;inset:0;pointer-events:none;z-index:0;overflow:hidden}
.bg-grid{position:absolute;inset:0;background-image:linear-gradient(rgba(30,58,95,0.1) 1px,transparent 1px),linear-gradient(90deg,rgba(30,58,95,0.1) 1px,transparent 1px);background-size:64px 64px;mask-image:radial-gradient(ellipse 70% 60% at 30% 50%,black 30%,transparent 70%);-webkit-mask-image:radial-gradient(ellipse 70% 60% at 30% 50%,black 30%,transparent 70%)}
.bg-orb{position:absolute;width:600px;height:600px;border-radius:50%;filter:blur(120px);opacity:0.08;animation:orbFloat 25s ease-in-out infinite}
.bg-orb:nth-child(2){background:var(--accent);top:-200px;left:-150px;animation-delay:-5s}
.bg-orb:nth-child(3){background:var(--purple);bottom:-250px;right:-100px;animation-delay:-10s}
@keyframes orbFloat{0%,100%{transform:translate(0,0) scale(1)}33%{transform:translate(40px,-30px) scale(1.05)}66%{transform:translate(-20px,20px) scale(0.95)}}

/* Main Layout */
.main-layout{position:relative;z-index:1;display:flex;min-height:100vh;align-items:stretch}

/* Left Panel */
.left-panel{flex:1;display:flex;align-items:center;justify-content:center;padding:3rem;position:relative}
.left-content{max-width:480px;width:100%}

.logo-mark{width:56px;height:56px;background:linear-gradient(135deg,var(--accent),var(--purple));border-radius:16px;display:flex;align-items:center;justify-content:center;margin-bottom:1.25rem;box-shadow:0 12px 40px var(--accent-glow);transition:var(--transition)}
.logo-mark:hover{transform:scale(1.05) rotate(-2deg)}
.logo-section h1{font-size:2.25rem;font-weight:800;letter-spacing:-0.03em;background:linear-gradient(135deg,#f8fafc 30%,#c7d2fe 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:0.35rem;line-height:1.15}
.logo-section .tagline{font-size:0.9rem;color:var(--text-secondary);font-weight:400;margin-bottom:2rem}

/* Info Cards */
.info-group{display:flex;flex-direction:column;gap:0.75rem}
.info-card{background:rgba(15,23,42,0.35);border:1px solid var(--border);border-radius:var(--radius-sm);overflow:hidden;backdrop-filter:blur(8px);transition:var(--transition)}
.info-card:hover{border-color:var(--border-hover);background:rgba(15,23,42,0.5);transform:translateY(-1px)}
.info-card-header{display:flex;align-items:center;gap:0.5rem;padding:0.7rem 1rem;font-size:0.78rem;font-weight:600;color:var(--text-primary);background:rgba(30,58,95,0.12);border-bottom:1px solid var(--border);letter-spacing:0.02em}
.info-card-header svg{color:var(--accent-light)}
.info-card-body{padding:0.7rem 1rem}

/* Promo */
.promo-item{display:flex;align-items:flex-start;gap:0.5rem;padding:0.45rem 0}
.promo-item+.promo-item{border-top:1px solid rgba(30,58,95,0.2)}
.promo-item p{font-size:0.75rem;color:var(--text-secondary);line-height:1.5;margin:0}
.promo-badge{flex-shrink:0;font-size:0.55rem;font-weight:700;padding:0.15rem 0.4rem;border-radius:var(--radius-xs);text-transform:uppercase;letter-spacing:0.06em;margin-top:3px;background:rgba(99,102,241,0.2);color:var(--accent-light)}
.promo-badge.discount{background:rgba(16,185,129,0.2);color:#34d399}
.promo-badge.info{background:rgba(139,92,246,0.2);color:#a78bfa}

/* Steps */
.step-list{display:flex;flex-direction:column;gap:0.55rem}
.step-item{display:flex;align-items:flex-start;gap:0.7rem}
.step-num{width:24px;height:24px;min-width:24px;background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;border-radius:50%;font-size:0.7rem;font-weight:700;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 8px rgba(99,102,241,0.3)}
.step-text strong{display:block;font-size:0.75rem;color:var(--text-primary)}
.step-text span{font-size:0.68rem;color:var(--text-muted)}

/* Contact */
.contact-links{display:flex;flex-direction:column;gap:0.25rem}
.contact-link{display:flex;align-items:center;gap:0.6rem;padding:0.5rem 0.5rem;text-decoration:none;font-size:0.78rem;color:var(--text-secondary);border-radius:var(--radius-xs);transition:var(--transition)}
.contact-link:hover{background:rgba(30,58,95,0.25);color:var(--text-primary)}
.contact-link svg{flex-shrink:0;opacity:0.6}

/* Right Panel */
.right-panel{flex:0.85;display:flex;align-items:center;justify-content:center;padding:2rem;position:relative}
.auth-wrap{width:100%;max-width:420px}
.auth-card{background:var(--bg-card);border:1px solid var(--border);border-radius:20px;padding:2.25rem;backdrop-filter:blur(24px) saturate(180%);-webkit-backdrop-filter:blur(24px) saturate(180%);box-shadow:var(--shadow-card),0 0 0 1px rgba(99,102,241,0.04) inset;transition:var(--transition)}
.auth-card:hover{border-color:rgba(99,102,241,0.15)}
.auth-header{text-align:center;margin-bottom:1.5rem}
.auth-header h2{font-size:1.4rem;font-weight:700;color:var(--text-primary);letter-spacing:-0.02em;margin-bottom:0.25rem}
.auth-header p{font-size:0.85rem;color:var(--text-muted)}

/* Tabs */
.tabs{display:flex;background:rgba(10,22,40,0.5);border-radius:var(--radius-sm);padding:4px;margin-bottom:1.5rem;gap:2px}
.tab-btn{flex:1;padding:0.6rem 0.5rem;border:none;border-radius:7px;cursor:pointer;font-size:0.82rem;font-weight:600;font-family:inherit;transition:var(--transition);position:relative;overflow:hidden}
.tab-btn.active{background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;box-shadow:0 4px 15px rgba(99,102,241,0.35)}
.tab-btn:not(.active){background:transparent;color:var(--text-muted)}
.tab-btn:not(.active):hover{color:var(--text-secondary);background:rgba(30,58,95,0.25)}
.tab-content{display:none;animation:fadeSlideIn 0.35s ease}
.tab-content.active{display:block}
@keyframes fadeSlideIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}

/* Form */
.form-group{margin-bottom:1rem}
.form-group label{display:block;font-size:0.72rem;font-weight:600;color:var(--text-secondary);margin-bottom:0.4rem;text-transform:uppercase;letter-spacing:0.06em}
input[type=text],input[type=email],input[type=password],input[type=number]{width:100%;padding:0.8rem 1rem;background:rgba(10,22,40,0.55);border:1px solid var(--border);border-radius:var(--radius-sm);color:var(--text-primary);font-size:0.9rem;font-family:inherit;outline:none;transition:var(--transition)}
input:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(99,102,241,0.12),inset 0 1px 0 rgba(99,102,241,0.05)}
input::placeholder{color:#334155}
input:hover:not(:focus){border-color:rgba(30,58,95,0.6)}

/* Buttons */
.btn{width:100%;padding:0.85rem;border:none;border-radius:var(--radius-sm);font-size:0.9rem;font-weight:700;cursor:pointer;font-family:inherit;transition:var(--transition);margin-top:0.25rem;letter-spacing:0.02em;position:relative;overflow:hidden}
.btn-primary{background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;box-shadow:0 4px 20px rgba(99,102,241,0.3)}
.btn-primary:hover{transform:translateY(-2px);box-shadow:0 8px 30px rgba(99,102,241,0.45)}
.btn-primary:active{transform:translateY(0)}
.btn-secondary{background:transparent;border:1px solid var(--border);color:var(--text-secondary)}
.btn-secondary:hover{border-color:var(--accent);color:var(--accent-light);background:rgba(30,58,95,0.15)}

/* Alerts */
.alert{padding:0.8rem 1rem;border-radius:var(--radius-sm);font-size:0.84rem;margin-bottom:1rem;display:flex;align-items:flex-start;gap:0.5rem;animation:fadeSlideIn 0.3s ease}
.alert-error{background:rgba(127,29,29,0.15);border:1px solid rgba(127,29,29,0.4);color:#fca5a5}
.alert-success{background:rgba(6,78,59,0.15);border:1px solid rgba(6,95,70,0.4);color:#6ee7b7}

/* OTP */
.otp-note{color:var(--text-secondary);font-size:0.85rem;margin-bottom:1.25rem;line-height:1.6}

/* Forgot */
.forgot-link{display:block;text-align:center;margin-top:0.85rem;color:var(--text-muted);font-size:0.8rem;cursor:pointer;text-decoration:none;transition:color 0.2s}
.forgot-link:hover{color:var(--accent-light)}

/* Divider */
.divider{display:flex;align-items:center;gap:0.75rem;margin:1rem 0;color:#334155;font-size:0.78rem}
.divider::before,.divider::after{content:'';flex:1;border-top:1px solid #1e293b}

/* Footer */
.left-footer{margin-top:1rem;padding:0.7rem 0.8rem;background:rgba(15,23,42,0.3);border-radius:8px;border:1px dashed var(--border)}
.left-footer p{font-size:0.7rem;color:var(--text-muted);line-height:1.5;margin:0}

/* Responsive */
@media(max-width:900px){.left-panel{display:none}.right-panel{flex:1;padding:1.5rem}.auth-card{padding:1.75rem}}
@media(min-width:901px)and (max-width:1100px){.left-panel{padding:1.5rem}}
@media(prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:0.01ms!important;animation-iteration-count:1!important;transition-duration:0.01ms!important}}
</style>
</head>
<body>

<!-- Ambient Background -->
<div class="bg-layer">
  <div class="bg-grid"></div>
  <div class="bg-orb"></div>
  <div class="bg-orb"></div>
</div>

<div class="main-layout">

  <!-- LEFT PANEL -->
  <div class="left-panel">
    <div class="left-content">

      <div class="logo-mark">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      </div>
      <div class="logo-section">
        <h1><?=$appName?></h1>
        <p class="tagline">Premium VPN Service Indonesia</p>
      </div>

      <div class="info-group">

        <!-- Announcements -->
        <div class="info-card">
          <div class="info-card-header">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            <span>Pengumuman & Promo</span>
          </div>
          <div class="info-card-body">
<?php
$announcements = [];
for ($i = 1; $i <= 3; $i++) {
    $a = getSetting('announce_'.$i, '');
    if (!empty($a) && strpos($a, '|') !== false) {
        list($badge, $text) = explode('|', $a, 2);
        if (trim($text) !== '') {
            $announcements[] = ['badge' => trim($badge), 'text' => trim($text)];
        }
    }
}
if (empty($announcements)) {
    $announcements = [
        ['badge' => 'BARU', 'text' => 'Free trial 3 hari untuk semua user baru! Buat akun sekarang dan nikmati akses penuh.'],
        ['badge' => 'PROMO', 'text' => 'Diskon 25% paket bulanan, hanya Rp 9.000/bulan. Berlaku hingga akhir bulan.'],
        ['badge' => 'INFO', 'text' => 'Server baru: Singapore 10Gbps, Japan Tokyo, dan Netherlands Amsterdam.']
    ];
}
$badgeClass = ['BARU' => '', 'PROMO' => 'discount', 'INFO' => 'info'];
foreach ($announcements as $a):
    $cls = $badgeClass[$a['badge']] ?? '';
?>
            <div class="promo-item">
              <span class="promo-badge<?= $cls ? ' '.$cls : '' ?>"><?= htmlspecialchars($a['badge']) ?></span>
              <p><?= htmlspecialchars($a['text']) ?></p>
            </div>
<?php endforeach; ?>
          </div>
        </div>

        <!-- Cara Daftar -->
        <div class="info-card">
          <div class="info-card-header">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
            <span>Cara Mendaftar</span>
          </div>
          <div class="info-card-body">
            <div class="step-list">
              <div class="step-item"><div class="step-num">1</div><div class="step-text"><strong>Klik tab Daftar</strong><span>di form sebelah kanan</span></div></div>
              <div class="step-item"><div class="step-num">2</div><div class="step-text"><strong>Isi username & email</strong><span>pastikan email aktif</span></div></div>
              <div class="step-item"><div class="step-num">3</div><div class="step-text"><strong>Buat password</strong><span>minimal 6 karakter</span></div></div>
              <div class="step-item"><div class="step-num">4</div><div class="step-text"><strong>Verifikasi OTP</strong><span>cek kode di email kamu</span></div></div>
              <div class="step-item"><div class="step-num">5</div><div class="step-text"><strong>Login & Order VPN</strong><span>pilih paket, bayar, langsung aktif</span></div></div>
            </div>
          </div>
        </div>

        <!-- Kontak Admin -->
        <div class="info-card">
          <div class="info-card-header">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
            <span>Kontak Admin</span>
          </div>
          <div class="info-card-body">
            <div class="contact-links">
              <a href="https://t.me/<?= urlencode(str_replace('@','', getSetting('contact_tg', 'ordervpn_admin'))) ?>" target="_blank" rel="noopener" class="contact-link">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.18 3.047-2.79 3.101-3.028.016-.136.018-.236-.163-.316s-.506-.098-.724-.058c-.311.055-1.99 1.264-3.476 2.113-.34.194-.65.29-.93.287-.604-.006-1.282-.159-1.973-.311-.748-.184-1.262-.262-1.17-.552.064-.231.356-.47.786-.661 1.106-.513 3.197-1.348 3.326-1.387.562-.209 1.194-.18.897.478-.074.133-1.572 2.562-1.572 2.562s-.519.418 1.357.795c0 0 .785.294 1.472-.3.555-.48 1.434-1.37 1.434-1.37z"/></svg>
                <span>Telegram: <?= htmlspecialchars(getSetting('contact_tg', '@ordervpn_admin')) ?></span>
              </a>
              <a href="https://wa.me/<?= urlencode(preg_replace('/[^0-9]/','', getSetting('contact_wa', '081234567890'))) ?>" target="_blank" rel="noopener" class="contact-link">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413z"/></svg>
                <span>WhatsApp: <?= htmlspecialchars(getSetting('contact_wa', '0812-3456-7890')) ?></span>
              </a>
            </div>
          </div>
        </div>

      </div>

      <div class="left-footer">
        <p>Butuh bantuan? Hubungi admin kami melalui Telegram atau WhatsApp. Response cepat 24/7.</p>
      </div>

    </div>
  </div>

  <!-- RIGHT PANEL -->
  <div class="right-panel">
    <div class="auth-wrap">
      <div class="auth-card">

        <div class="auth-header">
          <h2 id="authTitle">Selamat Datang</h2>
          <p id="authSub">Masuk ke akun <?=$appName?> kamu</p>
        </div>

        <div class="tabs">
          <button class="tab-btn active" id="btnLogin" onclick="showTab('login')">Masuk</button>
          <button class="tab-btn" id="btnReg" onclick="showTab('register')">Daftar</button>
          <button class="tab-btn" id="btnOtp" onclick="showTab('otp')" style="display:none">Verifikasi</button>
          <button class="tab-btn" id="btnForgot" onclick="showTab('forgot')" style="display:none">Lupa Password</button>
        </div>

        <?php if($error):?>
        <div class="alert alert-error">
          <span><?=$error?></span>
        </div>
        <?php endif;?>
        <?php if($success):?>
        <div class="alert alert-success">
          <span><?=$success?></span>
        </div>
        <?php endif;?>

        <!-- LOGIN -->
        <div class="tab-content active" id="tab-login">
          <form method="POST">
            <input type="hidden" name="action" value="login">
            <div class="form-group">
              <label>Username / Email</label>
              <input type="text" name="username" placeholder="Masukkan username atau email" required autocomplete="username">
            </div>
            <div class="form-group">
              <label>Password</label>
              <input type="password" name="password" placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;" required autocomplete="current-password">
            </div>
            <button type="submit" class="btn btn-primary">Masuk Sekarang</button>
            <a class="forgot-link" onclick="showTab('forgot');var u=document.querySelector('[name=username]');if(u)document.getElementById('forgotEmail').value=u.value||''">Lupa Password?</a>
          </form>
        </div>

        <!-- REGISTER -->
        <div class="tab-content" id="tab-register">
          <form method="POST" id="regForm">
            <input type="hidden" name="action" value="register">
            <div class="form-group">
              <label>Username</label>
              <input type="text" name="reg_username" placeholder="Buat username unik" required autocomplete="username">
            </div>
            <div class="form-group">
              <label>Email</label>
              <input type="email" name="reg_email" id="regEmail" placeholder="email@kamu.com" required autocomplete="email">
            </div>
            <div class="form-group">
              <label>Password</label>
              <input type="password" name="reg_password" placeholder="Minimal 6 karakter" required autocomplete="new-password">
            </div>
            <div class="form-group">
              <label>Konfirmasi Password</label>
              <input type="password" name="reg_confirm" placeholder="Ulangi password" required autocomplete="new-password">
            </div>
            <button type="submit" class="btn btn-primary">Buat Akun Baru</button>
          </form>
        </div>

        <!-- OTP VERIFY -->
        <div class="tab-content" id="tab-otp">
          <p class="otp-note">Masukkan kode 6 digit yang telah dikirim ke email kamu.</p>
          <form method="POST">
            <input type="hidden" name="action" value="verify_otp">
            <input type="hidden" name="otp_email" id="otpEmail" value="">
            <div class="form-group">
              <label>Kode OTP</label>
              <input type="number" name="otp_code" placeholder="000000" maxlength="6" style="text-align:center;font-size:1.5rem;font-weight:700;letter-spacing:0.3em;" required>
            </div>
            <button type="submit" class="btn btn-primary">Verifikasi Sekarang</button>
          </form>
          <div class="divider">atau</div>
          <form method="POST">
            <input type="hidden" name="action" value="resend_otp">
            <input type="hidden" name="resend_email" id="resendEmail" value="">
            <button type="submit" class="btn btn-secondary">Kirim Ulang OTP</button>
          </form>
        </div>

        <!-- FORGOT PASSWORD -->
        <div class="tab-content" id="tab-forgot">
          <form method="POST" id="forgotForm">
            <input type="hidden" name="action" value="forgot_password">
            <div class="form-group">
              <label>Email</label>
              <input type="email" name="forgot_email" id="forgotEmail" placeholder="email@kamu.com" required>
            </div>
            <button type="submit" class="btn btn-primary">Kirim Kode Reset</button>
          </form>
          <div class="divider">atau</div>
          <button class="btn btn-secondary" onclick="showTab('login')">Kembali ke Login</button>
        </div>

      </div>
    </div>
  </div>

</div>

<script>
function showTab(t){
  ['login','register','otp','forgot'].forEach(function(n){
    var el = document.getElementById('tab-'+n);
    if(el) el.classList.toggle('active', n===t);
  });
  var btnMap = {login:'Login', register:'Reg', otp:'Otp', forgot:'Forgot'};
  ['Login','Reg','Otp','Forgot'].forEach(function(n){
    var b = document.getElementById('btn'+n);
    if(b) {
      b.classList.toggle('active', btnMap[t]===n);
      b.style.display = (n==='Otp' && (t==='otp'||t==='forgot')) ? '' : (n==='Otp' ? 'none' : '');
      b.style.display = (n==='Forgot' && t==='forgot') ? '' : (n==='Forgot' ? 'none' : '');
    }
  });
  var titles = {login:'Selamat Datang Kembali', register:'Buat Akun Baru', otp:'Verifikasi Email', forgot:'Lupa Password'};
  var subs = {login:'Masuk ke akun <?=$appName?> kamu', register:'Daftar dan nikmati VPN premium', otp:'Konfirmasi kode OTP dari email', forgot:'Reset password akun Anda'};
  var tEl = document.getElementById('authTitle');
  var sEl = document.getElementById('authSub');
  if(tEl) tEl.textContent = titles[t] || titles['login'];
  if(sEl) sEl.textContent = subs[t] || subs['login'];
}

// Auto-show OTP tab after registration
var urlParams = new URLSearchParams(window.location.search);
document.getElementById('regForm')?.addEventListener('submit',function(){
  var e=document.getElementById('regEmail').value;
  document.getElementById('otpEmail').value=e;
  document.getElementById('resendEmail').value=e;
});

// Auto-fill forgot email
document.getElementById('forgotForm')?.addEventListener('submit', function(){
  var e = document.getElementById('forgotEmail').value;
  document.getElementById('resetEmail').value = e;
});

// Auto redirect to tabs from PHP messages
<?php if(strpos($success,'OTP')!==false||strpos($success,'Akun berhasil')!==false):?>showTab('otp');<?php endif;?>
<?php if(strpos($success,'diverifikasi')!==false||strpos($success,'Password berhasil')!==false):?>showTab('login');<?php endif;?>
</script>
</body>
</html>