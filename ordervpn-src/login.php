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
            // Rate limiting: max 5 gagal per 5 menit per IP
            if (!check_rate_limit('login',5,300)) {
                $error='Terlalu banyak percobaan! Coba lagi 5 menit lagi.';
                log_login_attempt('login',false,$u);
            } else {
                $st=$db->prepare("SELECT * FROM users WHERE username=? OR email=?");
                $st->execute([$u,$u]); $user=$st->fetch();
                if ($user && password_verify($p,$user['password'])) {
                    log_login_attempt('login',true,$u);
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
                } else {
                    log_login_attempt('login',false,$u);
                    $error='Username atau password salah!';
                }
            }
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
                $otp = str_pad(random_int(0,999999),6,'0',STR_PAD_LEFT);
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
            $otp=str_pad(random_int(0,999999),6,'0',STR_PAD_LEFT);
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
<title><?=$appName?> — Masuk</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#070b14;--border:rgba(255,255,255,0.06);--text:#f1f5f9;--text2:#94a3b8;--text3:#475569;
  --accent:#6366f1;--accent-l:#818cf8;--purple:#8b5cf6;--glow:rgba(99,102,241,0.3);
  --radius:16px;--r-sm:10px;--transition:0.3s ease;
}
body{
  font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;
  background:linear-gradient(135deg,#070b14 0%,#0f0a2a 50%,#0a0f1e 100%);
  min-height:100vh;display:flex;align-items:center;justify-content:center;
  color:var(--text);-webkit-font-smoothing:antialiased;padding:1rem;
}
.orb{position:fixed;width:500px;height:500px;border-radius:50%;filter:blur(100px);opacity:0.1;pointer-events:none;z-index:0}
.orb:nth-child(1){background:var(--accent);top:-150px;left:-100px;animation:orb 20s ease-in-out infinite}
.orb:nth-child(2){background:var(--purple);bottom:-150px;right:-100px;animation:orb 25s ease-in-out infinite reverse}
@keyframes orb{0%,100%{transform:translate(0,0)}50%{transform:translate(40px,-30px)}}
.auth-wrap{position:relative;z-index:1;width:100%;max-width:420px;animation:fadeUp 0.6s ease both}
.auth-card{background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.1);border-radius:20px;padding:2.25rem;box-shadow:0 24px 80px rgba(0,0,0,0.5),0 0 40px rgba(99,102,241,0.06)}
.back-link{display:inline-flex;align-items:center;gap:0.3rem;color:var(--text3);text-decoration:none;font-size:0.78rem;margin-bottom:1.25rem;transition:var(--transition)}
.back-link:hover{color:var(--accent-l)}
.logo-head{text-align:center;margin-bottom:1.5rem}
.logo-head h1{font-size:1.5rem;font-weight:800;letter-spacing:-0.03em;background:linear-gradient(135deg,#f8fafc 30%,#c7d2fe 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.logo-head p{font-size:0.82rem;color:var(--text2);margin-top:0.25rem}
.tabs{display:flex;background:rgba(255,255,255,0.04);border-radius:var(--r-sm);padding:4px;margin-bottom:1.5rem;gap:2px}
.tab-btn{flex:1;padding:0.6rem;border:none;border-radius:7px;cursor:pointer;font-size:0.82rem;font-weight:600;font-family:inherit;transition:var(--transition)}
.tab-btn.active{background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;box-shadow:0 4px 15px rgba(99,102,241,0.35)}
.tab-btn:not(.active){background:transparent;color:var(--text3)}
.tab-btn:not(.active):hover{color:var(--text2);background:rgba(255,255,255,0.06)}
.tab-content{display:none;animation:fadeSlideIn 0.35s ease}
.tab-content.active{display:block}
@keyframes fadeSlideIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
.form-group{margin-bottom:1rem}
.form-group label{display:block;font-size:0.72rem;font-weight:600;color:var(--text2);margin-bottom:0.4rem;text-transform:uppercase;letter-spacing:0.06em}
input[type=text],input[type=email],input[type=password],input[type=number]{width:100%;padding:0.8rem 1rem;background:rgba(0,0,0,0.3);border:1px solid rgba(255,255,255,0.08);border-radius:var(--r-sm);color:var(--text);font-size:0.9rem;font-family:inherit;outline:none;transition:var(--transition)}
input:focus{border-color:var(--accent);box-shadow:0 0 0 3px rgba(99,102,241,0.12)}
input::placeholder{color:#334155}
.btn{width:100%;padding:0.85rem;border:none;border-radius:var(--r-sm);font-size:0.9rem;font-weight:700;cursor:pointer;font-family:inherit;transition:var(--transition);margin-top:0.25rem}
.btn-primary{background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;box-shadow:0 4px 20px var(--glow)}
.btn-primary:hover{transform:translateY(-2px);box-shadow:0 8px 30px var(--glow)}
.btn-secondary{background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.1);color:var(--text2)}
.btn-secondary:hover{border-color:var(--accent);color:var(--accent-l);background:rgba(99,102,241,0.1)}
.alert{padding:0.8rem 1rem;border-radius:var(--r-sm);font-size:0.84rem;margin-bottom:1rem;line-height:1.5}
.alert-error{background:rgba(127,29,29,0.15);border:1px solid rgba(239,68,68,0.3);color:#fca5a5}
.alert-success{background:rgba(6,78,59,0.15);border:1px solid rgba(16,185,129,0.3);color:#6ee7b7}
.forgot-link{display:block;text-align:center;margin-top:0.85rem;color:var(--text3);font-size:0.8rem;cursor:pointer;text-decoration:none}
.forgot-link:hover{color:var(--accent-l)}
.otp-note{color:var(--text2);font-size:0.85rem;margin-bottom:1.25rem;line-height:1.6}
.divider{display:flex;align-items:center;gap:0.75rem;margin:1rem 0;color:#334155;font-size:0.78rem}
.divider::before,.divider::after{content:'';flex:1;border-top:1px solid rgba(255,255,255,0.06)}
@media(max-width:480px){.auth-card{padding:1.5rem}}
</style>
</head>
<body>
<div class="orb"></div>
<div class="orb"></div>

<div class="auth-wrap">
  <div class="auth-card">
    <a href="/ordervpn/" class="back-link"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg> Kembali</a>
    <div class="logo-head">
      <h1><?=$appName?></h1>
      <p>Premium VPN Service Indonesia</p>
    </div>
    <div class="tabs">
      <button class="tab-btn active" id="btnLogin" onclick="showTab('login')">Masuk</button>
      <button class="tab-btn" id="btnReg" onclick="showTab('register')">Daftar</button>
      <button class="tab-btn" id="btnOtp" onclick="showTab('otp')" style="display:none">Verifikasi</button>
      <button class="tab-btn" id="btnForgot" onclick="showTab('forgot')" style="display:none">Lupa Password</button>
    </div>
    <?php if($error):?><div class="alert alert-error"><?=$error?></div><?php endif;?>
    <?php if($success):?><div class="alert alert-success"><?=$success?></div><?php endif;?>

    <div class="tab-content active" id="tab-login">
      <form method="POST">
        <input type="hidden" name="action" value="login">
        <div class="form-group">
          <label>Username / Email</label>
          <input type="text" name="username" placeholder="Masukkan username atau email" required autocomplete="username">
        </div>
        <div class="form-group">
          <label>Password</label>
          <input type="password" name="password" placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;" required autocomplete="current-password">
        </div>
        <button type="submit" class="btn btn-primary">Masuk Sekarang</button>
        <button type="button" class="forgot-link" onclick="showTab('forgot');var u=document.querySelector('[name=username]');if(u)document.getElementById('forgotEmail').value=u.value||''" style="background:none;border:none;width:auto;padding:0;cursor:pointer">Lupa Password?</button>
      </form>
    </div>

    <div class="tab-content" id="tab-register">
      <form method="POST" id="regForm">
        <input type="hidden" name="action" value="register">
        <div class="form-group"><label>Username</label><input type="text" name="reg_username" placeholder="Buat username unik" required autocomplete="username"></div>
        <div class="form-group"><label>Email</label><input type="email" name="reg_email" id="regEmail" placeholder="email@kamu.com" required autocomplete="email"></div>
        <div class="form-group"><label>Password</label><input type="password" name="reg_password" placeholder="Minimal 6 karakter" required autocomplete="new-password"></div>
        <div class="form-group"><label>Konfirmasi Password</label><input type="password" name="reg_confirm" placeholder="Ulangi password" required autocomplete="new-password"></div>
        <button type="submit" class="btn btn-primary">Buat Akun Baru</button>
      </form>
    </div>

    <div class="tab-content" id="tab-otp">
      <p class="otp-note">Masukkan kode 6 digit yang telah dikirim ke email kamu.</p>
      <form method="POST">
        <input type="hidden" name="action" value="verify_otp">
        <input type="hidden" name="otp_email" id="otpEmail" value="">
        <div class="form-group"><label>Kode OTP</label><input type="number" name="otp_code" placeholder="000000" maxlength="6" style="text-align:center;font-size:1.5rem;font-weight:700;letter-spacing:0.3em;" required></div>
        <button type="submit" class="btn btn-primary">Verifikasi Sekarang</button>
      </form>
      <div class="divider">atau</div>
      <form method="POST">
        <input type="hidden" name="action" value="resend_otp">
        <input type="hidden" name="resend_email" id="resendEmail" value="">
        <button type="submit" class="btn btn-secondary">Kirim Ulang OTP</button>
      </form>
    </div>

    <div class="tab-content" id="tab-forgot">
      <form method="POST" id="forgotForm">
        <input type="hidden" name="action" value="forgot_password">
        <div class="form-group"><label>Email</label><input type="email" name="forgot_email" id="forgotEmail" placeholder="email@kamu.com" required></div>
        <button type="submit" class="btn btn-primary">Kirim Kode Reset</button>
      </form>
      <div class="divider">atau</div>
      <button class="btn btn-secondary" onclick="showTab('login')">Kembali ke Login</button>
      <div style="margin-top:1.5rem;padding-top:1.5rem;border-top:1px solid rgba(255,255,255,0.06)">
        <form method="POST">
          <input type="hidden" name="action" value="reset_password">
          <input type="hidden" name="reset_email" id="resetEmail" value="">
          <div class="form-group"><label>Kode OTP</label><input type="text" name="reset_otp" placeholder="000000" maxlength="6" style="text-align:center;font-size:1.2rem;letter-spacing:0.3em;" required></div>
          <div class="form-group"><label>Password Baru</label><input type="password" name="new_password" placeholder="Minimal 6 karakter" required></div>
          <div class="form-group"><label>Konfirmasi Password</label><input type="password" name="confirm_password" placeholder="Ulangi password baru" required></div>
          <button type="submit" class="btn btn-primary">Reset Password</button>
        </form>
      </div>
    </div>

  </div>
</div>

<script>
function icon(p,s){return '<svg width="'+s+'" height="'+s+'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+p+'</svg>'}
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

// Auto-show register tab from landing page
var urlParams = new URLSearchParams(window.location.search);
if(urlParams.get('register')==='1') showTab('register');
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