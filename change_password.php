<?php
session_start();
require_once __DIR__ . '/includes/config.php';

if (!isset($_SESSION['user_id'])) {
    header('Location: admin/'); exit;
}

$msg = ''; $msg_type = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_pass = $_POST['old_password'] ?? '';
    $new_pass = $_POST['new_password'] ?? '';
    $confirm  = $_POST['confirm_password'] ?? '';
    
    if (empty($old_pass) || empty($new_pass) || empty($confirm)) {
        $msg = 'Semua field harus diisi!';
        $msg_type = 'error';
    } elseif ($new_pass !== $confirm) {
        $msg = 'Password baru tidak cocok!';
        $msg_type = 'error';
    } elseif (strlen($new_pass) < 6) {
        $msg = 'Password minimal 6 karakter!';
        $msg_type = 'error';
    } else {
        $db = getDB();
        $stmt = $db->prepare('SELECT password FROM users WHERE id = ?');
        $stmt->execute([$_SESSION['user_id']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user && password_verify($old_pass, $user['password'])) {
            $new_hash = password_hash($new_pass, PASSWORD_BCRYPT);
            $stmt = $db->prepare('UPDATE users SET password = ? WHERE id = ?');
            $stmt->execute([$new_hash, $_SESSION['user_id']]);
            $msg = 'Password berhasil diubah!';
            $msg_type = 'success';
        } else {
            $msg = 'Password lama salah!';
            $msg_type = 'error';
        }
    }
}

$db = getDB();
$stmt = $db->prepare('SELECT username, email, role FROM users WHERE id = ?');
$stmt->execute([$_SESSION['user_id']]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
$appName = getSetting('app_name','OrderVPN');
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ganti Password - <?=$appName?></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
:root {
  --bg: #070b14; --bg-alt: #0a0f1e;
  --card: #111827; --border: #1e293b;
  --text: #e2e8f0; --text-dim: #94a3b8;
  --primary: #6366f1; --accent: #818cf8;
  --danger: #ef4444; --success: #10b981;
  --muted: #64748b;
  --radius: 12px; --radius-sm: 8px;
  --transition: 0.25s cubic-bezier(0.16,1,0.3,1);
}
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:'Inter','Segoe UI',system-ui,sans-serif;
  background:var(--bg);
  min-height:100vh;display:flex;align-items:center;justify-content:center;
  -webkit-font-smoothing:antialiased;
  position:relative;
}
body::before{
  content:'';position:fixed;inset:0;pointer-events:none;
  background-image:linear-gradient(rgba(30,58,95,0.08) 1px,transparent 1px),linear-gradient(90deg,rgba(30,58,95,0.08) 1px,transparent 1px);
  background-size:64px 64px;
  mask-image:radial-gradient(ellipse 60% 50% at 50% 50%,black 40%,transparent 70%);
}
.card{
  position:relative;z-index:1;
  background:var(--card);border:1px solid var(--border);
  border-radius:16px;padding:36px;width:100%;max-width:420px;
  box-shadow:0 24px 60px rgba(0,0,0,.5);
}
.card h2{color:var(--text);text-align:center;margin-bottom:4px;font-size:1.3em;font-weight:700;letter-spacing:-.3px}
.card .subtitle{color:var(--muted);text-align:center;margin-bottom:24px;font-size:.85em}
.user-info{
  background:rgba(99,102,241,.06);border-radius:10px;
  padding:12px 14px;margin-bottom:20px;
  color:var(--text-dim);font-size:.85em;text-align:center;
  border:1px solid rgba(99,102,241,.1);
}
.user-info strong{color:var(--primary);font-weight:600}
.logo-icon{
  width:44px;height:44px;
  background:linear-gradient(135deg,var(--primary),#8b5cf6);
  border-radius:12px;display:flex;align-items:center;justify-content:center;
  margin:0 auto 16px;box-shadow:0 8px 24px rgba(99,102,241,.3);
}
.form-group{margin-bottom:14px}
.form-group label{display:block;margin-bottom:5px;font-size:.72em;font-weight:600;text-transform:uppercase;letter-spacing:.5px;color:var(--muted)}
.form-group input{
  width:100%;padding:11px 14px;
  background:var(--bg-alt);border:1px solid var(--border);border-radius:10px;
  color:var(--text);font-size:.9em;font-family:inherit;
  transition:var(--transition);outline:none;
}
.form-group input:focus{border-color:var(--primary);box-shadow:0 0 0 3px rgba(99,102,241,.12)}
.btn{
  width:100%;padding:13px;border:none;border-radius:10px;
  background:linear-gradient(135deg,var(--primary),#8b5cf6);color:#fff;
  font-size:.9em;font-weight:600;cursor:pointer;
  transition:var(--transition);letter-spacing:.2px;font-family:inherit;
}
.btn:hover{box-shadow:0 6px 24px rgba(99,102,241,.35);transform:translateY(-1px)}
.btn:active{transform:translateY(0)}
.alert{padding:10px 14px;border-radius:8px;margin-bottom:14px;font-size:.84em;font-weight:500;display:flex;align-items:center;gap:8px}
.alert-success{background:rgba(16,185,129,.1);color:var(--success);border:1px solid rgba(16,185,129,.2)}
.alert-error{background:rgba(239,68,68,.08);color:var(--danger);border:1px solid rgba(239,68,68,.15)}
.back-link{display:block;text-align:center;margin-top:16px;color:var(--muted);text-decoration:none;font-size:.82em;transition:var(--transition)}
.back-link:hover{color:var(--primary)}
@media(prefers-reduced-motion:reduce){*,*::before,*::after{transition-duration:0.01ms!important}}
</style>
</head>
<body>
    <div class="card">
        <div class="logo-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="3" width="22" height="18" rx="2" ry="2"/><line x1="9" y1="3" x2="9" y2="21"/><line x1="15" y1="3" x2="15" y2="21"/></svg>
        </div>
        <h2>Ganti Password</h2>
        <p class="subtitle"><?=$appName?> Admin Panel</p>
        
        <div class="user-info">
            Login sebagai: <strong><?= htmlspecialchars($user['username']) ?></strong>
            (<?= htmlspecialchars($user['role']) ?>)
        </div>
        
        <?php if ($msg): ?>
        <div class="alert alert-<?= $msg_type === 'success' ? 'success' : 'error' ?>">
            <?= htmlspecialchars($msg) ?>
        </div>
        <?php endif; ?>
        
        <form method="POST">
            <div class="form-group">
                <label>Password Lama</label>
                <input type="password" name="old_password" placeholder="Masukkan password saat ini" required>
            </div>
            <div class="form-group">
                <label>Password Baru</label>
                <input type="password" name="new_password" placeholder="Minimal 6 karakter" required minlength="6">
            </div>
            <div class="form-group">
                <label>Konfirmasi Password Baru</label>
                <input type="password" name="confirm_password" placeholder="Ulangi password baru" required minlength="6">
            </div>
            <button type="submit" class="btn">Simpan Password Baru</button>
        </form>
        
        <a href="admin/" class="back-link">Kembali ke Dashboard</a>
    </div>
</body>
</html>