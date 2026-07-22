<?php
// ============================================================
// OrderVPN - Landing + Auth (single file)
// Tema: Midnight Console — Bahasa Indonesia
// CATATAN: Jangan ubah name/input/POST action — contract backend
// ============================================================
require_once __DIR__.'/includes/config.php';
if (session_status() === PHP_SESSION_NONE) session_start();

// Handle logout BEFORE the redirect check (so logged-in users don't bounce back to dashboard)
if (isset($_GET['logout'])) {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
            $params['path'], $params['domain'],
            $params['secure'], $params['httponly']);
    }
    session_destroy();
    header('Location: index.php?logged_out=1');
    exit;
}

if (isset($_SESSION['user_id'])) { header('Location: /ordervpn/dashboard.php'); exit; }

$appName = getSetting('app_name','OrderVPN');
$error   = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // ----- LOGIN -----
    if ($action === 'login') {
        $u = sanitize($_POST['username'] ?? '');
        $p = $_POST['password'] ?? '';
        if (empty($u) || empty($p)) { $error = 'Username dan password wajib diisi!'; }
        else {
            $db = getDB();
            $st = $db->prepare("SELECT * FROM users WHERE username=? OR email=?");
            $st->execute([$u, $u]);
            $user = $st->fetch();
            if ($user && password_verify($p, $user['password'])) {
                if (!$user['is_verified'] && $user['role'] === 'user') {
                    $error = 'Email belum diverifikasi! Cek inbox kamu.';
                } else {
                    $_SESSION['user_id']  = $user['id'];
                    $_SESSION['username'] = $user['username'];
                    $_SESSION['role']     = $user['role'];
                    $_SESSION['saldo']    = $user['saldo'];
                    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
                    $db->prepare("UPDATE users SET ip_address=? WHERE id=?")->execute([$ip, $user['id']]);
                    header('Location: /ordervpn/dashboard.php');
                    exit;
                }
            } else { $error = 'Username atau password salah!'; }
        }
    }

    // ----- REGISTER -----
    if ($action === 'register') {
        $u = sanitize($_POST['reg_username'] ?? '');
        $e = sanitize($_POST['reg_email'] ?? '');
        $p = $_POST['reg_password'] ?? '';
        $c = $_POST['reg_confirm'] ?? '';
        if (empty($u) || empty($e) || empty($p)) {
            $error = 'Semua field wajib diisi!';
        } elseif ($p !== $c) {
            $error = 'Password tidak cocok!';
        } elseif (strlen($p) < 6) {
            $error = 'Password minimal 6 karakter!';
        } elseif (!filter_var($e, FILTER_VALIDATE_EMAIL)) {
            $error = 'Format email tidak valid!';
        } else {
            $db  = getDB();
            $chk = $db->prepare("SELECT id FROM users WHERE username=? OR email=?");
            $chk->execute([$u, $e]);
            if ($chk->fetch()) {
                $error = 'Username atau email sudah digunakan!';
            } else {
                $otp    = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
                $otpExp = date('Y-m-d H:i:s', strtotime('+15 minutes'));
                $hash   = password_hash($p, PASSWORD_BCRYPT);
                try {
                    $db->prepare("INSERT INTO users (username,email,password,otp_code,otp_expires,is_verified) VALUES (?,?,?,?,?,0)")
                       ->execute([$u, $e, $hash, $otp, $otpExp]);
                } catch (PDOException $ex) {
                    if ($ex->getCode() == 23000) {
                        $error = 'Username atau email sudah terdaftar!';
                    } else { throw $ex; }
                }
                if (empty($error)) {
                    $emailBody = "
                    <div style='font-family:monospace;max-width:480px;margin:0 auto;background:#090C10;color:#00FFAA;padding:32px;'>
                      <pre style='margin:0;color:#00FFAA;'>[ OrderVPN ]</pre>
                      <p style='color:#8B949E;margin:8px 0 24px;'>Verifikasi akun kamu.</p>
                      <div style='background:#131920;border-left:3px solid #00FFAA;padding:24px;margin:24px 0;text-align:center;'>
                        <p style='color:#8B949E;font-size:11px;margin-bottom:8px;letter-spacing:.2em;'>KODE OTP:</p>
                        <div style='font-size:36px;font-weight:700;letter-spacing:14px;color:#00FFAA;font-family:monospace;'>{$otp}</div>
                        <p style='color:#8B949E;font-size:10px;margin-top:12px;'>BERLAKU 15 MENIT</p>
                      </div>
                      <p style='color:#8B949E;font-size:10px;'>Abaikan email ini jika kamu tidak mendaftar.</p>
                    </div>";
                    sendEmail($e, "Kode OTP Verifikasi - {$appName}", $emailBody);
                    $success = 'Akun berhasil dibuat! Cek email untuk kode OTP verifikasi.';
                }
            }
        }
    }

    // ----- VERIFY OTP -----
    if ($action === 'verify_otp') {
        $e   = sanitize($_POST['otp_email'] ?? '');
        $otp = sanitize($_POST['otp_code'] ?? '');
        $db  = getDB();
        $st  = $db->prepare("SELECT * FROM users WHERE email=? AND otp_code=? AND otp_expires > NOW()");
        $st->execute([$e, $otp]);
        $user = $st->fetch();
        if ($user) {
            $db->prepare("UPDATE users SET is_verified=1, otp_code=NULL, otp_expires=NULL WHERE id=?")
               ->execute([$user['id']]);
            $success = 'Email berhasil diverifikasi! Silakan login.';
        } else { $error = 'Kode OTP salah atau sudah expired!'; }
    }

    // ----- RESEND OTP -----
    if ($action === 'resend_otp') {
        $e  = sanitize($_POST['resend_email'] ?? '');
        $db = getDB();
        $st = $db->prepare("SELECT * FROM users WHERE email=? AND is_verified=0");
        $st->execute([$e]);
        $user = $st->fetch();
        if ($user) {
            $otp    = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
            $otpExp = date('Y-m-d H:i:s', strtotime('+15 minutes'));
            $db->prepare("UPDATE users SET otp_code=?, otp_expires=? WHERE id=?")
               ->execute([$otp, $otpExp, $user['id']]);
            $emailBody = "<div style='font-family:monospace;background:#090C10;color:#00FFAA;padding:32px;'><p>Kode OTP Baru:</p><div style='font-size:32px;letter-spacing:12px;text-align:center;margin:24px 0;'>{$otp}</div><p style='color:#8B949E;font-size:10px;'>BERLAKU 15 MENIT</p></div>";
            sendEmail($e, "Kode OTP Baru - {$appName}", $emailBody);
            $success = 'OTP baru sudah dikirim ke email kamu.';
        } else { $error = 'Email tidak ditemukan atau sudah terverifikasi.'; }
    }

    // ----- FORGOT PASSWORD -----
    if ($action === 'forgot_password') {
        $e = sanitize($_POST['forgot_email'] ?? '');
        if (empty($e) || !filter_var($e, FILTER_VALIDATE_EMAIL)) {
            $error = 'Masukkan email yang valid!';
        } else {
            $db = getDB();
            $st = $db->prepare("SELECT * FROM users WHERE email=?");
            $st->execute([$e]);
            $user = $st->fetch();
            if ($user) {
                $otp    = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
                $otpExp = date('Y-m-d H:i:s', strtotime('+15 minutes'));
                $db->prepare("UPDATE users SET otp_code=?, otp_expires=? WHERE id=?")
                   ->execute([$otp, $otpExp, $user['id']]);
                $emailBody = "<div style='font-family:monospace;background:#090C10;color:#00FFAA;padding:32px;'><p>Reset Password untuk <b>{$user['username']}</b>:</p><div style='font-size:32px;letter-spacing:12px;text-align:center;margin:24px 0;color:#00FFAA;'>{$otp}</div><p style='color:#8B949E;font-size:10px;'>BERLAKU 15 MENIT</p></div>";
                sendEmail($e, "Reset Password - {$appName}", $emailBody);
            }                $success        = 'Jika email terdaftar, kode reset password telah dikirim ke inbox Anda. Cek juga folder spam.';
                if ($user) $triggerReset = true;
        }
    }

    // ----- RESET PASSWORD -----
  if ($action === 'reset_password') {
        $e   = sanitize($_POST['reset_email'] ?? '');
        $otp = sanitize($_POST['reset_otp'] ?? '');
        $np  = $_POST['new_password'] ?? '';
        $cp  = $_POST['confirm_password'] ?? '';
        if (empty($e) || empty($otp) || empty($np)) {
            $error = 'Semua field wajib diisi!';
        } elseif (strlen($np) < 6) {
            $error = 'Password baru minimal 6 karakter!';
        } elseif ($np !== $cp) {
            $error = 'Password tidak cocok!';
        } else {
            $db = getDB();
            $st = $db->prepare("SELECT * FROM users WHERE email=? AND otp_code=? AND otp_expires > NOW()");
            $st->execute([$e, $otp]);
            $user = $st->fetch();
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
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($appName) ?> — Hardened Tunnel Infrastructure</title>
<meta name="description" content="OrderVPN - Infrastruktur tunneling multi-protokol. SSH, VMess, VLess, Trojan, ZIVPN. Aktivasi instan via Tripay.">
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><rect width=%22100%22 height=%22100%22 fill=%22%23090C10%22/><text x=%2250%22 y=%2270%22 font-size=%2270%22 text-anchor=%22middle%22 fill=%22%2300FFAA%22>%26gt;_</text></svg>">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/ordervpn.css?v=3.12.0">
</head>
<body>

<!-- ============================================================
     SIGNATURE ELEMENT: Routing Line (left edge)
     ============================================================ -->
<aside class="routing-line" aria-hidden="true">
  <div class="routing-node" style="top: 8%"><span class="routing-label">[ 01 ] Hero</span></div>
  <div class="routing-node" style="top: 26%"><span class="routing-label">[ 02 ] Protocols</span></div>
  <div class="routing-node" style="top: 50%"><span class="routing-label">[ 03 ] Pricing</span></div>
  <div class="routing-node" style="top: 70%"><span class="routing-label">[ 04 ] Bootstrap</span></div>
  <div class="routing-node" style="top: 88%"><span class="routing-label">[ 05 ] FAQ &amp; Metrics</span></div>
</aside>

<!-- ============================================================
     NAV
     ============================================================ -->
<nav class="nav" role="navigation">
  <div class="nav-brand">
    <span class="prompt">&gt;_</span><span class="name"><?= htmlspecialchars($appName) ?></span>
    <span class="ver">v3.12.0</span>
  </div>
  <div class="nav-actions">
    <button class="btn" type="button" onclick="openAuth('login')">[ Autentikasi ]</button>
    <button class="btn btn-primary" type="button" onclick="openAuth('register')">[ Deploy Akun ]</button>
  </div>
</nav>

<!-- ============================================================
     HERO
     ============================================================ -->
<header class="hero">
  <div class="hero-eyebrow"><span class="dot"></span>SYSTEM ONLINE • UPTIME 99.97%</div>
  <h1>Jalur Privat<br><span class="accent">Kecepatan Tinggi.</span></h1>
  <p class="lead">Infrastruktur tunneling kelas server. Bypass DPI, enkripsi berlapis, dan kontrol penuh dari satu panel — tanpa intervensi manual, tanpa biaya tersembunyi.</p>
  <div class="hero-actions">
    <button class="btn btn-yellow" type="button" onclick="openAuth('register')">[ Mulai Sekarang ]</button>
    <a href="#pricing" class="btn">[ Lihat Topologi ]</a>
  </div>
  <div class="hero-stats">
    <div class="stat-mini"><strong>14</strong>NODE AKTIF</div>
    <div class="stat-mini"><strong>3 REGION</strong>SG / ID / GLOBAL</div>
    <div class="stat-mini"><strong>6 PROTOKOL</strong>XRAY NATIVE</div>
    <div class="stat-mini"><strong>INSTAN</strong>AKTIVASI VIA TRIPAY</div>
  </div>
</header>

<!-- ============================================================
     [02] FEATURES
     ============================================================ -->
<section id="protocols">
  <div class="container">
    <div class="section-eyebrow">[ 02 // Protocols &amp; Capability ]</div>
    <h2 class="section-title">Arsitektur Multi-Protokol.</h2>
    <p class="section-sub">Enam pilar yang menjadi fondasi setiap tunnel yang kami deploy. Bukan jargon marketing — ini capabilities yang dieksekusi otomatis oleh installer kami.</p>
    <div class="features-grid">
      <div class="feature">
        <div class="feature-num">[01]</div>
        <h3>Multi-Protocol Native</h3>
        <p>Dukungan natif XRAY, VMess, VLess, Trojan, Dropbear SSH, dan ZIVPN dalam satu panel terpadu.</p>
      </div>
      <div class="feature">
        <div class="feature-num">[02]</div>
        <h3>Bypass Pemblokiran ISP</h3>
        <p>Obfuscation tingkat kernel. Tembus limitasi ISP tanpa proksi berlapis yang menambah latensi.</p>
      </div>
      <div class="feature">
        <div class="feature-num">[03]</div>
        <h3>Panel Otonom</h3>
        <p>Manajemen durasi, batas IP, dan rotasi sesi otomatis. Tidak ada antrian konfirmasi admin.</p>
      </div>
      <div class="feature">
        <div class="feature-num">[04]</div>
        <h3>Failover Berlapis</h3>
        <p>Node geographically distributed. Script keep-alive memantau koneksi dan restart otomatis saat anomali.</p>
      </div>
      <div class="feature">
        <div class="feature-num">[05]</div>
        <h3>Enkripsi Berlapis</h3>
        <p>Rotasi TLS fingerprint harian. Isolated credential namespace per akun. Dump trafik nol-persisten.</p>
      </div>
      <div class="feature">
        <div class="feature-num">[06]</div>
        <h3>Gateway Pembayaran</h3>
        <p>Integrasi Tripay. Aktivasi otomatis begitu invoice lunas — tanpa kontak manual, tanpa delay.</p>
      </div>
    </div>
  </div>
</section>

<!-- ============================================================
     [03] PRICING
     ============================================================ -->
<section id="pricing">
  <div class="container">
    <div class="section-eyebrow">[ 03 // Topology &amp; Pricing ]</div>
    <h2 class="section-title">Pilih Jalur. Sesuaikan Beban.</h2>
    <p class="section-sub">Tiga topologi dengan karakteristik berbeda. Migrasi kapan saja gratis dengan cooldown 15 menit antar perpindahan server.</p>
    <div class="pricing-grid">
      <div class="price-card">
        <div class="price-region">[ SG — CORE NODE ]</div>
        <h3 class="price-name">Singapore Premium</h3>
        <div class="price-tier">
          <span class="amount">Rp 10.000</span><span class="unit">/ bulan</span>
          <div class="secondary">atau Rp 15.62 / jam (Pay-As-You-Go)</div>
        </div>
        <ul class="price-features">
          <li>Port 1 Gbps unmetered</li>
          <li>Singapore datacenter premium IP</li>
          <li>Xray VMess / VLess / Trojan</li>
          <li>WebSocket + gRPC transport</li>
          <li>Wildcard domain support</li>
          <li>Maks 2 device concurrent</li>
        </ul>
        <button class="btn btn-full" type="button" onclick="openAuth('register')">[ Deploy Sekarang ]</button>
      </div>

      <div class="price-card featured">
        <div class="price-region">[ ID — LOCAL ROUTE ]</div>
        <h3 class="price-name">Indonesia Local</h3>
        <div class="price-tier">
          <span class="amount yellow">Rp 12.500</span><span class="unit">/ bulan</span>
          <div class="secondary">atau Rp 19.09 / jam (Pay-As-You-Go)</div>
        </div>
        <ul class="price-features">
          <li>Latensi lokal &lt;20ms ke server nasional</li>
          <li>ID datacenter routing</li>
          <li>SSH OpenSSH + Dropbear included</li>
          <li>UDP Custom gateway aktif</li>
          <li>Cocok untuk streaming &amp; game lokal</li>
          <li>Maks 2 device concurrent</li>
        </ul>
        <button class="btn btn-full btn-yellow" type="button" onclick="openAuth('register')">[ Deploy Sekarang ]</button>
      </div>

      <div class="price-card">
        <div class="price-region">[ GLOBAL — MULTI PATH ]</div>
        <h3 class="price-name">Always-On Multi</h3>
        <div class="price-tier">
          <span class="amount">Rp 15.000</span><span class="unit">/ 135 GB</span>
          <div class="secondary">bandwidth rollover enabled</div>
        </div>
        <ul class="price-features">
          <li>Akses seluruh region aktif</li>
          <li>IP rotation otomatis per sesi</li>
          <li>Cocok untuk kebutuhan konten global</li>
          <li>Priority queue saat kepadatan tinggi</li>
          <li>Support ZIVPN UDP gateway</li>
          <li>Maks 2 device concurrent</li>
        </ul>
        <button class="btn btn-full" type="button" onclick="openAuth('register')">[ Deploy Sekarang ]</button>
      </div>
    </div>
  </div>
</section>

<!-- ============================================================
     [04] HOW-TO
     ============================================================ -->
<section id="bootstrap">
  <div class="container">
    <div class="section-eyebrow">[ 04 // Onboarding ]</div>
    <h2 class="section-title">Tiga Langkah. Tanpa Antre.</h2>
    <p class="section-sub">Proses dari registrasi hingga tunnel aktif dirancang untuk selesai dalam waktu kurang dari satu menit.</p>
    <div class="howto-grid">
      <div class="step">
        <h3>Registrasi Kredensial</h3>
        <p>Buat akun dengan email valid. Verifikasi OTP otomatis tanpa kontak admin dan tanpa dokumen tambahan.</p>
      </div>
      <div class="step">
        <h3>Tentukan Topologi</h3>
        <p>Pilih region server dan paket langganan. Auto-renew tersedia bila saldo dompet mencukupi di akhir siklus.</p>
      </div>
      <div class="step">
        <h3>Injeksi Koneksi</h3>
        <p>Konfigurasi ter-generate otomatis. Tempel ke aplikasi client pilihan — tunnel aktif seketika tanpa restart.</p>
      </div>
    </div>
  </div>
</section>

<!-- ============================================================
     [05] FAQ
     ============================================================ -->
<section id="faq">
  <div class="container">
    <div class="section-eyebrow">[ 05 // Knowledge Base ]</div>
    <h2 class="section-title">Pertanyaan yang Sering Muncul.</h2>
    <p class="section-sub">Tidak menemukan jawaban yang kamu butuhkan? Kontak admin via Telegram atau WhatsApp untuk respon cepat 24/7.</p>

    <div class="faq-group">
      <div class="faq-group-title">[ Generale ]</div>
      <details class="faq-item">
        <summary>Apakah trafik saya di-logging di server?</summary>
        <div class="answer">Tidak. Kami tidak menyimpan log koneksi atau record destination apapun. Session berakhir ketika tunnel dimatikan, dan metadata koneksi hanya tersedia di memory process — tidak dipersistensi ke disk sama sekali.</div>
      </details>
      <details class="faq-item">
        <summary>Bagaimana cara kerja sistem batas IP secara teknis?</summary>
        <div class="answer">Sistem menghitung sesi aktif berdasarkan session identifier unik per device. Saat device ketiga mencoba konek, sesi terlama diputus secara otomatis. Tidak ada intervensi manual yang diperlukan.</div>
      </details>
      <details class="faq-item">
        <summary>Apakah kredensial bisa digunakan di STB atau OpenWrt router?</summary>
        <div class="answer">Ya. Konfigurasi yang ter-generate kompatibel dengan aplikasi client mainstream — termasuk STB Android, router OpenWrt dengan passwall/shadowsocks-libev, dan seluruh klien resmi Xray / V2RayNG di mobile.</div>
      </details>
      <details class="faq-item">
        <summary>Berapa lama waktu aktivasi setelah pembayaran?</summary>
        <div class="answer">Seketika. Gateway Tripay mengirim callback ke server begitu invoice berstatus lunas. Akun di-upgrade ke tier berbayar secara otomatis tanpa antrian approval.</div>
      </details>
    </div>

    <div class="faq-group">
      <div class="faq-group-title">[ Lanjutan ]</div>
      <details class="faq-item">
        <summary>Bisakah saya migrasi server tanpa membuat akun baru?</summary>
        <div class="answer">Bisa. Perubahan server tunduk pada cooldown 15 menit antar migrasi untuk mencegah churning akun. Perpindahan protokol berlaku untuk layanan Trojan, VMess, dan VLess tanpa downtime.</div>
      </details>
      <details class="faq-item">
        <summary>Bagaimana aturan auto-renew di akhir masa aktif?</summary>
        <div class="answer">Jika saldo dompet Anda cukup dan auto-renew aktif, sistem akan memperpanjang otomatis. Anda menerima notifikasi 3 hari sebelumnya melalui bot Telegram dan email.</div>
      </details>
      <details class="faq-item">
        <summary>Apakah ada batasan jumlah akun yang boleh saya buat?</summary>
        <div class="answer">Tidak ada batas kuantitas akun per identitas. Anda dapat berlangganan multipel akun aktif secara simultan tanpa batasan administratif apapun dari sisi kami.</div>
      </details>
    </div>
  </div>
</section>

<!-- ============================================================
     STATS
     ============================================================ -->
<section id="stats">
  <div class="container">
    <div class="stats-grid">
      <div class="stat">
        <span class="stat-num" data-target="14">0</span>
        <span class="stat-label">[ Node Aktif ]</span>
      </div>
      <div class="stat">
        <span class="stat-num" data-target="2847">0</span>
        <span class="stat-label">[ Tunnel Tereksekusi ]</span>
      </div>
      <div class="stat">
        <span class="stat-num" data-target="36">0</span>
        <span class="stat-label">[ Volume Trafik TB ]</span>
      </div>
      <div class="stat">
        <span class="stat-num" data-target="9210">0</span>
        <span class="stat-label">[ Transaksi Selesai ]</span>
      </div>
    </div>
  </div>
</section>

<!-- ============================================================
     FOOTER
     ============================================================ -->
<footer class="footer" role="contentinfo">
  <div class="footer-grid">
    <div class="footer-col">
      <h4>[ Infrastruktur ]</h4>
      <p>Single-binary installer</p>
      <p>Multi-region failover</p>
      <p>Auto-renew engine</p>
      <p>Tripay payment gateway</p>
      <p>Telegram bot integration</p>
    </div>

    <div class="footer-col">
      <h4>[ Pengumuman ]</h4>
      <?php
      $announcements = [];
      for ($i = 1; $i <= 3; $i++) {
        $a = getSetting('announce_'.$i, '');
        if (!empty($a) && strpos($a, '|') !== false) {
          list($tag, $text) = explode('|', $a, 2);
          $announcements[] = ['tag' => trim($tag), 'text' => trim($text)];
        }
      }
      if (empty($announcements)):
      ?>
        <div class="announce-item">
          <span class="tag">NEW</span>
          <p>Trial 3 hari untuk user baru. Hubungi admin untuk aktivasi awal tanpa biaya.</p>
        </div>
        <div class="announce-item yellow">
          <span class="tag">PROMO</span>
          <p>Diskon 25% untuk paket ID Local bulan ini. Berlaku hingga akhir bulan.</p>
        </div>
        <div class="announce-item">
          <span class="tag">INFO</span>
          <p>Server baru Japan Tokyo dan SG-2 sudah aktif. Auto-rotated via panel.</p>
        </div>
      <?php else:
        $yellowTags = ['PROMO', 'DISKON', 'BONUS'];
        foreach ($announcements as $a):
          $isYellow = in_array(strtoupper($a['tag']), $yellowTags);
      ?>
        <div class="announce-item<?= $isYellow ? ' yellow' : '' ?>">
          <span class="tag"><?= htmlspecialchars(strtoupper($a['tag'])) ?></span>
          <p><?= htmlspecialchars($a['text']) ?></p>
        </div>
      <?php endforeach; endif; ?>
    </div>

    <div class="footer-col">
      <h4>[ Kontak ]</h4>
      <a href="https://t.me/<?= urlencode(ltrim(getSetting('contact_tg','@ordervpn_admin'), '@')) ?>" target="_blank" rel="noopener">
        Telegram: <?= htmlspecialchars(getSetting('contact_tg','@ordervpn_admin')) ?>
      </a>
      <a href="https://wa.me/<?= preg_replace('/[^0-9]/','', getSetting('contact_wa','081234567890')) ?>" target="_blank" rel="noopener">
        WhatsApp: <?= htmlspecialchars(getSetting('contact_wa','0812-3456-7890')) ?>
      </a>
      <p>Response time: &lt; 30 menit</p>
      <p>Layanan: 24/7</p>
    </div>
  </div>

  <div class="footer-meta">
    &gt;_&nbsp;<span class="text-cyan"><?= htmlspecialchars($appName) ?></span>
    &nbsp;//&nbsp;powered by Youzin Crabz Tunel
    &nbsp;//&nbsp;v3.12.0
    &nbsp;//&nbsp;build_commit: 7f7a62c
  </div>
</footer>

<!-- ============================================================
     AUTH MODAL
     ============================================================ -->
<div class="auth-overlay" id="authModal" role="dialog" aria-modal="true" aria-labelledby="authTitle">
  <div class="auth-card">
    <button class="auth-close" type="button" onclick="closeAuth()" aria-label="Tutup dialog">[ X ]</button>
    <div class="auth-eyebrow" id="authEyebrow">[ AUTHENTICATION REQUIRED ]</div>
    <h2 class="auth-title" id="authTitle">Masuk.</h2>
    <p class="auth-sub" id="authSub">Akses panel menggunakan kredensial Anda.</p>

    <?php if ($error): ?>
      <div class="alert alert-error">[ ERR ]&nbsp;<?= htmlspecialchars($error) ?></div>
    <?php endif; ?>
    <?php if ($success): ?>
      <div class="alert alert-success">[ OK ]&nbsp;<?= htmlspecialchars($success) ?></div>
    <?php endif; ?>

    <div class="tabs" role="tablist">
      <button class="tab-btn active" data-tab="login" role="tab" type="button">[ Masuk ]</button>
      <button class="tab-btn" data-tab="register" role="tab" type="button">[ Daftar ]</button>
      <button class="tab-btn" data-tab="forgot" role="tab" type="button" hidden>[ Lupa Password ]</button>
      <button class="tab-btn" data-tab="otp" role="tab" type="button" hidden>[ Verifikasi OTP ]</button>
      <button class="tab-btn" data-tab="reset" role="tab" type="button" hidden>[ Reset Password ]</button>
    </div>    <!-- LOGIN -->
        <div class="tab-content active" id="tab-login" role="tabpanel">
          <form method="POST" autocomplete="on">
            <input type="hidden" name="action" value="login">
            <?= csrfField() ?>
        <div class="form-group">
          <label>Username / Email</label>
          <input type="text" name="username" placeholder="username atau email" required autocomplete="username">
        </div>
        <div class="form-group">
          <label>Password</label>
          <input type="password" name="password" placeholder="••••••••" required autocomplete="current-password">
        </div>
        <button type="submit" class="btn btn-primary btn-full">[ AUTHENTICATE ]</button>
        <button type="button" class="form-link" data-switch="forgot">Lupa password?</button>
      </form>
    </div>    <!-- REGISTER -->
        <div class="tab-content" id="tab-register" role="tabpanel">
          <form method="POST" id="regForm" autocomplete="on">
            <input type="hidden" name="action" value="register">
            <?= csrfField() ?>
        <div class="form-group">
          <label>Username</label>
          <input type="text" name="reg_username" placeholder="username unik, 3-32 karakter" required autocomplete="username">
        </div>
        <div class="form-group">
          <label>Email</label>
          <input type="email" name="reg_email" id="regEmail" placeholder="email@domain.com" required autocomplete="email">
        </div>
        <div class="form-group">
          <label>Password</label>
          <input type="password" name="reg_password" placeholder="minimal 6 karakter" required autocomplete="new-password">
        </div>
        <div class="form-group">
          <label>Konfirmasi</label>
          <input type="password" name="reg_confirm" placeholder="ulangi password" required autocomplete="new-password">
        </div>
        <button type="submit" class="btn btn-primary btn-full">[ CREATE ACCOUNT ]</button>
        <button type="button" class="form-link" data-switch="login">Sudah punya akun? Masuk</button>
      </form>
    </div>    <!-- FORGOT -->
        <div class="tab-content" id="tab-forgot" role="tabpanel">
          <form method="POST" id="forgotForm">
            <input type="hidden" name="action" value="forgot_password">
            <?= csrfField() ?>
        <div class="form-group">
          <label>Email Terdaftar</label>
          <input type="email" name="forgot_email" id="forgotEmail" placeholder="email@domain.com" required>
        </div>
        <button type="submit" class="btn btn-primary btn-full">[ SEND RESET CODE ]</button>
        <button type="button" class="form-link" data-switch="login">Kembali ke login</button>
      </form>
    </div>

    <!-- OTP VERIFY -->
    <div class="tab-content" id="tab-otp" role="tabpanel">
      <p style="color:var(--muted);font-size:0.84rem;margin-bottom:18px;line-height:1.5;">
        Masukkan 6-digit kode yang dikirim ke email Anda. Berlaku selama 15 menit.
      </p>        <form method="POST">
            <input type="hidden" name="action" value="verify_otp">
            <?= csrfField() ?>
            <input type="hidden" name="otp_email" id="otpEmail" value="">
        <div class="form-group">
          <label>Kode OTP</label>
          <input type="text" name="otp_code" placeholder="000000" maxlength="6"
                 inputmode="numeric" pattern="[0-9]{6}" required
                 style="font-family:var(--font-display); text-align:center; font-size:1.4rem; letter-spacing:0.5em; font-weight:700;">
        </div>
        <button type="submit" class="btn btn-primary btn-full">[ VERIFY ]</button>
      </form>      <form method="POST" style="margin-top:14px;">
        <input type="hidden" name="action" value="resend_otp">
        <?= csrfField() ?>
        <input type="hidden" name="resend_email" id="resendEmail" value="">
        <button type="submit" class="btn btn-full">[ Resend OTP ]</button>
      </form>
    </div>

    <!-- RESET PASSWORD (after forgot_password sends code) -->
    <div class="tab-content" id="tab-reset" role="tabpanel">
      <p style="color:var(--muted);font-size:0.84rem;margin-bottom:18px;line-height:1.5;">
        Masukkan kode OTP dari email dan password baru Anda. OTP berlaku 15 menit.
      </p>
      <form method="POST" id="resetForm" autocomplete="off">
        <input type="hidden" name="action" value="reset_password">
        <?= csrfField() ?>
        <input type="hidden" name="reset_email" id="resetEmail" value="">
        <div class="form-group">
          <label>Email</label>
          <input type="email" id="resetEmailDisplay" value="" disabled style="opacity:0.6;cursor:not-allowed;">
        </div>
        <div class="form-group">
          <label>Kode OTP</label>
          <input type="text" name="reset_otp" placeholder="000000" maxlength="6"
                 inputmode="numeric" pattern="[0-9]{6}" required
                 style="font-family:var(--font-display); text-align:center; font-size:1.4rem; letter-spacing:0.5em; font-weight:700;">
        </div>
        <div class="form-group">
          <label>Password Baru</label>
          <input type="password" name="new_password" placeholder="minimal 6 karakter" required autocomplete="new-password">
        </div>
        <div class="form-group">
          <label>Konfirmasi Password</label>
          <input type="password" name="confirm_password" placeholder="ulangi password baru" required autocomplete="new-password">
        </div>
        <button type="submit" class="btn btn-primary btn-full">[ RESET PASSWORD ]</button>
        <button type="button" class="form-link" data-switch="login">Kembali ke login</button>
      </form>
    </div>
  </div>
</div>

<script>
// ============================================================
// Auth modal control
// ============================================================
function openAuth(tab) {
  var modal = document.getElementById('authModal');
  modal.classList.add('open');
  document.body.style.overflow = 'hidden';
  switchAuth(tab);
}
function closeAuth() {
  var modal = document.getElementById('authModal');
  modal.classList.remove('open');
  document.body.style.overflow = '';
}
function switchAuth(tab) {
  ['login','register','forgot','otp','reset'].forEach(function(t) {
    var el = document.getElementById('tab-' + t);
    if (el) el.classList.toggle('active', t === tab);
  });
  var contextualTabs = ['forgot','otp','reset'];
  document.querySelectorAll('.tab-btn').forEach(function(b) {
    var bt = b.dataset.tab;
    var isContextual = contextualTabs.indexOf(bt) !== -1;
    if (isContextual) {
      b.hidden = (bt !== tab);
      b.classList.toggle('active', bt === tab);
    } else {
      b.hidden = false;
      b.classList.toggle('active', bt === tab);
    }
  });
  var titles = {
    login:    ['[ AUTHENTICATION REQUIRED ]', 'Masuk.',          'Akses panel menggunakan kredensial Anda.'],
    register: ['[ NEW IDENTITY ]',             'Daftar Akun.',    'Buat akun baru untuk mengakses layanan.'],
    forgot:   ['[ PASSWORD RECOVERY ]',        'Reset Password.', 'Masukkan email terdaftar untuk menerima kode.'],
    otp:      ['[ VERIFY ]',                   'Verifikasi OTP.', 'Masukkan 6 digit kode dari email Anda.'],
    reset:    ['[ NEW CREDENTIALS ]',          'Reset Password.', 'Masukkan kode OTP dan password baru Anda.']
  };
  var t = titles[tab] || titles.login;
  document.getElementById('authEyebrow').textContent = t[0];
  document.getElementById('authTitle').textContent   = t[1];
  document.getElementById('authSub').textContent     = t[2];
}

// Tab-button clicking switches tab too
document.querySelectorAll('.tab-btn').forEach(function(b) {
  b.addEventListener('click', function() { switchAuth(this.dataset.tab); });
});

// Form-link [data-switch="login|forgot|register|otp"]
document.querySelectorAll('.form-link').forEach(function(b) {
  b.addEventListener('click', function() { switchAuth(this.dataset.switch); });
});

// Close on overlay click or ESC key
document.getElementById('authModal').addEventListener('click', function(e) {
  if (e.target === this) closeAuth();
});
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') closeAuth();
});

// Carry email from register form to OTP form
document.getElementById('regForm')?.addEventListener('submit', function() {
  var e = document.getElementById('regEmail').value;
  if (e) {
    document.getElementById('otpEmail').value = e;
    document.getElementById('resendEmail').value = e;
  }
});

// Carry email from forgot-email field to OTP + reset forms on next step
document.getElementById('forgotForm')?.addEventListener('submit', function() {
  var e = document.getElementById('forgotEmail').value;
  if (e) {
    document.getElementById('otpEmail').value = e;
    document.getElementById('resendEmail').value = e;
    document.getElementById('resetEmail').value = e;
    var display = document.getElementById('resetEmailDisplay');
    if (display) display.value = e;
  }
});

// After server-side actions, auto-open correct tab
<?php if (strpos($success, 'OTP') !== false || strpos($success, 'Akun berhasil') !== false): ?>
document.addEventListener('DOMContentLoaded', function() { openAuth('otp'); });
<?php endif; ?>
<?php if (strpos($success, 'diverifikasi') !== false || strpos($success, 'Password berhasil') !== false): ?>
document.addEventListener('DOMContentLoaded', function() { openAuth('login'); });
<?php endif; ?>
<?php if (!empty($triggerReset)): ?>
document.addEventListener('DOMContentLoaded', function() {
  openAuth('reset');
  var fe = document.getElementById('forgotEmail');
  var re = document.getElementById('resetEmail');
  var rd = document.getElementById('resetEmailDisplay');
  if (fe && re && rd) {
    var v = fe.value || <?= json_encode($_POST['forgot_email'] ?? '', JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
    re.value = v;
    rd.value = v;
  }
});
<?php endif; ?>

// ============================================================
// Stat counter animation on viewport entry
// ============================================================
(function() {
  if (!('IntersectionObserver' in window)) {
    document.querySelectorAll('.stat-num[data-target]').forEach(function(el) {
      el.textContent = parseInt(el.dataset.target || '0', 10).toLocaleString();
    });
    return;
  }
  var counters = document.querySelectorAll('.stat-num[data-target]');
  var animate = function(el) {
    var target = parseInt(el.dataset.target, 10) || 0;
    var duration = 1400;
    var start = performance.now();
    var step = function(now) {
      var t = Math.min((now - start) / duration, 1);
      var eased = 1 - Math.pow(1 - t, 3);
      el.textContent = Math.round(eased * target).toLocaleString('id-ID');
      if (t < 1) requestAnimationFrame(step);
      else el.textContent = target.toLocaleString('id-ID');
    };
    requestAnimationFrame(step);
  };
  var obs = new IntersectionObserver(function(entries) {
    entries.forEach(function(e) {
      if (e.isIntersecting) { animate(e.target); obs.unobserve(e.target); }
    });
  }, { threshold: 0.4 });
  counters.forEach(function(c) { obs.observe(c); });
})();
</script>
</body>
</html>
