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
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ganti Password - OrderVPN</title>
    <style>
        :root {
            --bg: #080c14; --card: #111827; --border: #1e293b;
            --text: #e2e8f0; --primary: #6366f1; --primary-dim: #4f46e5;
            --danger: #ef4444; --success: #10b981; --muted: #64748b;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body {
            font-family: 'Inter','Segoe UI',system-ui,sans-serif;
            background: var(--bg);
            min-height:100vh; display:flex; align-items:center; justify-content:center;
            -webkit-font-smoothing: antialiased;
        }
        .card {
            background: var(--card); border:1px solid var(--border);
            border-radius:14px; padding:36px; width:100%; max-width:420px;
            box-shadow: 0 20px 50px rgba(0,0,0,.4);
        }
        .card h2 { color:var(--text); text-align:center; margin-bottom:6px; font-size:1.3em; font-weight:700; letter-spacing:-.2px; }
        .card .subtitle { color:var(--muted); text-align:center; margin-bottom:24px; font-size:.85em; }
        .user-info {
            background: rgba(99,102,241,.06); border-radius:10px;
            padding:12px 14px; margin-bottom:20px;
            color: var(--muted); font-size:.85em; text-align:center;
        }
        .user-info strong { color: var(--primary); font-weight:600; }
        .form-group { margin-bottom:14px; }
        .form-group label { display:block; margin-bottom:5px; font-size:.78em; font-weight:600; text-transform:uppercase; letter-spacing:.5px; color:var(--muted); }
        .form-group input {
            width:100%; padding:11px 14px;
            background:var(--bg); border:1px solid var(--border); border-radius:10px;
            color:var(--text); font-size:.92em; font-family:inherit;
            transition: .2s; outline:none;
        }
        .form-group input:focus { border-color:var(--primary); box-shadow: 0 0 0 3px rgba(99,102,241,.12); }
        .btn {
            width:100%; padding:13px; border:none; border-radius:10px;
            background: var(--primary); color:#fff;
            font-size:.93em; font-weight:600; cursor:pointer;
            transition: .2s; letter-spacing:.2px;
        }
        .btn:hover { background: var(--primary-dim); box-shadow: 0 6px 20px rgba(99,102,241,.3); }
        .alert { padding:10px 14px; border-radius:8px; margin-bottom:14px; font-size:.84em; font-weight:500; }
        .alert-success { background:rgba(16,185,129,.1); color:var(--success); border:1px solid rgba(16,185,129,.2); }
        .alert-error { background:rgba(239,68,68,.08); color:var(--danger); border:1px solid rgba(239,68,68,.15); }
        .back-link { display:block; text-align:center; margin-top:16px; color:var(--muted); text-decoration:none; font-size:.82em; transition:.2s; }
        .back-link:hover { color:var(--primary); }
</style>
</head>
<body>
    <div class="card">
        <h2>Change Password</h2>
        <p class="subtitle">OrderVPN Admin Panel</p>
        
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
            <button type="submit" class="btn">Save New Password</button>
        </form>
        
        <a href="admin/" class="back-link">Back to Dashboard</a>
    </div>
</body>
</html>