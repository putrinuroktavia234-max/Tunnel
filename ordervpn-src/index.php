<?php
require_once __DIR__.'/includes/config.php';
if (isset($_SESSION['user_id'])) { header('Location: /dashboard.php'); exit; }

$appName = getSetting('app_name','OrderVPN');

try {
    $db = getDB();
    $stats = [
        'member' => $db->query("SELECT COUNT(*) FROM users")->fetchColumn() ?: 0,
        'tunnel' => $db->query("SELECT COUNT(*) FROM vpn_accounts WHERE status='active'")->fetchColumn() ?: 0,
        'server' => $db->query("SELECT COUNT(*) FROM servers WHERE status='active'")->fetchColumn() ?: 0,
        'transaksi' => $db->query("SELECT COUNT(*) FROM vpn_accounts")->fetchColumn() ?: 0,
    ];
} catch (Exception $e) {
    $stats = ['member'=>0,'tunnel'=>0,'server'=>0,'transaksi'=>0];
}
function icon($p,$s=18){return '<svg width="'.$s.'" height="'.$s.'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'.$p.'</svg>';}
function featureIcon($p){return '<div class="feature-icon">'.icon($p,20).'</div>';}
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?=$appName?> — Layanan Tunneling Premium</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#070b14;--bg2:#0a0f1e;--card:rgba(255,255,255,0.03);
  --border:rgba(255,255,255,0.06);--text:#f1f5f9;--text2:#94a3b8;--text3:#475569;
  --accent:#6366f1;--accent-l:#818cf8;--purple:#8b5cf6;
  --glow:rgba(99,102,241,0.3);--radius:16px;--r-sm:10px;--r-xs:6px;
  --transition:0.3s ease;
}
html{scroll-behavior:smooth}
body{font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;background:var(--bg);color:var(--text);-webkit-font-smoothing:antialiased;overflow-x:hidden}

/* Navbar */
.navbar{position:fixed;top:0;left:0;right:0;z-index:100;padding:0.8rem 2rem;display:flex;align-items:center;justify-content:space-between;background:rgba(7,11,20,0.85);border-bottom:1px solid rgba(255,255,255,0.05);transition:var(--transition)}
.navbar .logo{display:flex;align-items:center;gap:0.6rem;font-size:1.15rem;font-weight:800;color:var(--text);text-decoration:none}
.nav-links{display:flex;gap:2rem;list-style:none}
.nav-links a{color:var(--text2);text-decoration:none;font-size:0.85rem;font-weight:500;transition:var(--transition);position:relative}
.nav-links a::after{content:'';position:absolute;bottom:-4px;left:0;width:0;height:2px;background:var(--accent);border-radius:2px;transition:var(--transition)}
.nav-links a:hover{color:var(--text)}.nav-links a:hover::after{width:100%}
.nav-actions{display:flex;gap:0.6rem}
.btn{display:inline-flex;align-items:center;gap:0.4rem;padding:0.55rem 1.25rem;border-radius:var(--r-sm);font-size:0.82rem;font-weight:600;font-family:inherit;cursor:pointer;transition:var(--transition);text-decoration:none;border:none}
.btn-ghost{color:var(--text2);background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.08)}
.btn-ghost:hover{color:var(--text);background:rgba(255,255,255,0.08);border-color:rgba(255,255,255,0.15)}
.btn-primary{background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;box-shadow:0 4px 20px var(--glow)}
.btn-primary:hover{transform:translateY(-2px);box-shadow:0 8px 30px var(--glow)}
.hamburger{display:none;flex-direction:column;gap:4px;cursor:pointer;background:none;border:none;padding:4px}
.hamburger span{width:22px;height:2px;background:var(--text2);border-radius:2px;transition:var(--transition)}

/* Hero */
.hero{min-height:60vh;display:flex;align-items:center;position:relative;overflow:hidden;padding:5rem 2rem 3rem}
.hero-orb{position:absolute;width:500px;height:500px;border-radius:50%;filter:blur(100px);opacity:0.1;pointer-events:none;will-change:transform}
.hero-orb:nth-child(1){background:var(--accent);top:-150px;left:-100px;animation:orb 20s ease-in-out infinite}
.hero-orb:nth-child(2){background:var(--purple);bottom:-150px;right:-100px;animation:orb 25s ease-in-out infinite reverse}
@keyframes orb{0%,100%{transform:translate(0,0)}50%{transform:translate(40px,-30px)}}
.hero-content{position:relative;z-index:1;max-width:800px;margin:0 auto;text-align:center;animation:fadeUp 0.8s ease both}
.hero-badge{display:inline-flex;align-items:center;gap:0.4rem;padding:0.35rem 0.9rem;border-radius:100px;font-size:0.75rem;font-weight:600;background:rgba(99,102,241,0.12);color:var(--accent-l);border:1px solid rgba(99,102,241,0.2);margin-bottom:1.5rem}
.hero h1{font-size:3.5rem;font-weight:900;line-height:1.1;letter-spacing:-0.04em;margin-bottom:1rem;background:linear-gradient(135deg,#f8fafc 30%,#c7d2fe 70%,#a78bfa 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.hero p{font-size:1.1rem;color:var(--text2);line-height:1.7;max-width:560px;margin:0 auto 2rem}
.hero-actions{display:flex;gap:1rem;justify-content:center;flex-wrap:wrap}
.hero-actions .btn{padding:0.75rem 2rem;font-size:0.9rem}

/* Section */
.section{padding:5rem 2rem;position:relative}
.section-header{text-align:center;max-width:600px;margin:0 auto 3.5rem}
.section-header h2{font-size:2rem;font-weight:800;letter-spacing:-0.03em;margin-bottom:0.75rem}
.section-header p{color:var(--text2);font-size:0.95rem;line-height:1.6}

/* Features */
.features{display:grid;grid-template-columns:repeat(3,1fr);gap:1.25rem;max-width:1100px;margin:0 auto}
.feature-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:1.75rem;transition:var(--transition);animation:fadeUp 0.6s ease both}
.feature-card:hover{border-color:rgba(99,102,241,0.2);transform:translateY(-3px);box-shadow:0 12px 48px rgba(0,0,0,0.3)}
.feature-icon{width:44px;height:44px;border-radius:12px;background:linear-gradient(135deg,var(--accent),var(--purple));display:flex;align-items:center;justify-content:center;margin-bottom:1rem;color:#fff}
.feature-card h3{font-size:1rem;font-weight:700;margin-bottom:0.4rem}
.feature-card p{font-size:0.82rem;color:var(--text2);line-height:1.6}

/* Pricing */
.pricing{display:grid;grid-template-columns:repeat(3,1fr);gap:1.5rem;max-width:1100px;margin:0 auto}
.pricing-card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);padding:2rem;text-align:center;transition:var(--transition);animation:fadeUp 0.6s ease both;position:relative}
.pricing-card.featured{border-color:var(--accent);box-shadow:0 0 40px rgba(99,102,241,0.1)}
.pricing-card.featured::before{content:'Terpopuler';position:absolute;top:-12px;left:50%;transform:translateX(-50%);padding:0.25rem 1rem;border-radius:100px;font-size:0.68rem;font-weight:700;background:linear-gradient(135deg,var(--accent),var(--purple));color:#fff;text-transform:uppercase;letter-spacing:0.06em}
.pricing-card:hover{transform:translateY(-4px);border-color:rgba(99,102,241,0.2)}
.pricing-card h3{font-size:1.1rem;font-weight:700;margin-bottom:0.25rem}
.pricing-card .server-loc{font-size:0.78rem;color:var(--text3);margin-bottom:1rem;display:flex;align-items:center;justify-content:center;gap:0.3rem}
.pricing-card .price{font-size:2.5rem;font-weight:900;letter-spacing:-0.03em;color:var(--accent-l);margin-bottom:0.2rem}
.pricing-card .price-sub{font-size:0.78rem;color:var(--text3);margin-bottom:1.25rem}
.pricing-card .features-list{list-style:none;text-align:left;margin-bottom:1.5rem}
.pricing-card .features-list li{padding:0.45rem 0;font-size:0.82rem;color:var(--text2);display:flex;align-items:center;gap:0.5rem;border-bottom:1px solid rgba(255,255,255,0.04)}
.pricing-card .features-list li:first-child{border-top:1px solid rgba(255,255,255,0.04)}
.pricing-card .features-list li::before{content:'';width:16px;height:16px;background:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%2310b981' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='20 6 9 17 4 12'/%3E%3C/svg%3E");flex-shrink:0}
.pricing-card .btn{width:100%;justify-content:center;padding:0.7rem}

/* Process */
.process{display:grid;grid-template-columns:repeat(3,1fr);gap:2rem;max-width:900px;margin:0 auto}
.process-step{text-align:center;animation:fadeUp 0.6s ease both}
.process-step .num{width:48px;height:48px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--purple));display:flex;align-items:center;justify-content:center;font-size:1.1rem;font-weight:800;margin:0 auto 1rem;box-shadow:0 8px 24px var(--glow);color:#fff}
.process-step h3{font-size:1rem;font-weight:700;margin-bottom:0.4rem}
.process-step p{font-size:0.82rem;color:var(--text2);line-height:1.5;max-width:280px;margin:0 auto}

/* FAQ */
.faq{max-width:700px;margin:0 auto}
.faq-item{border-bottom:1px solid var(--border)}
.faq-q{padding:1rem 0;display:flex;justify-content:space-between;align-items:center;cursor:pointer;font-size:0.9rem;font-weight:600;color:var(--text);transition:var(--transition);background:none;border:none;width:100%;text-align:left;font-family:inherit}
.faq-q:hover{color:var(--accent-l)}
.faq-q svg{flex-shrink:0;color:var(--text3);transition:var(--transition)}
.faq-q.active svg{transform:rotate(180deg)}
.faq-a{padding:0 0 1rem 0;font-size:0.85rem;color:var(--text2);line-height:1.7;display:none}
.faq-a.show{display:block;animation:fadeUp 0.3s ease}

/* Stats */
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;max-width:900px;margin:0 auto;padding:2rem;background:var(--card);border:1px solid var(--border);border-radius:var(--radius)}
.stat-item{text-align:center}
.stat-item .num{font-size:2rem;font-weight:900;color:var(--accent-l)}
.stat-item .label{font-size:0.78rem;color:var(--text2);margin-top:0.25rem}

/* Footer */
.footer{border-top:1px solid var(--border);padding:3rem 2rem 1.5rem;margin-top:3rem}
.footer-grid{max-width:1100px;margin:0 auto;display:grid;grid-template-columns:2fr 1fr 1fr 1fr;gap:2rem;margin-bottom:2rem}
.footer-brand h3{font-size:1rem;font-weight:800;margin-bottom:0.5rem}
.footer-brand p{font-size:0.82rem;color:var(--text2);line-height:1.6;max-width:300px}
.footer-col h4{font-size:0.82rem;font-weight:700;text-transform:uppercase;letter-spacing:0.06em;color:var(--text3);margin-bottom:1rem}
.footer-col a{display:block;font-size:0.82rem;color:var(--text2);text-decoration:none;padding:0.3rem 0;transition:var(--transition)}
.footer-col a:hover{color:var(--accent-l)}
.footer-bottom{text-align:center;padding-top:1.5rem;border-top:1px solid var(--border);font-size:0.78rem;color:var(--text3)}

/* Animations */
@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
.feature-card:nth-child(1){animation-delay:0s}
.feature-card:nth-child(2){animation-delay:0.08s}
.feature-card:nth-child(3){animation-delay:0.16s}
.feature-card:nth-child(4){animation-delay:0.24s}
.feature-card:nth-child(5){animation-delay:0.32s}
.feature-card:nth-child(6){animation-delay:0.4s}
.pricing-card:nth-child(1){animation-delay:0s}
.pricing-card:nth-child(2){animation-delay:0.1s}
.pricing-card:nth-child(3){animation-delay:0.2s}
.process-step:nth-child(1){animation-delay:0s}
.process-step:nth-child(2){animation-delay:0.15s}
.process-step:nth-child(3){animation-delay:0.3s}

/* Responsive */
@media(max-width:768px){
  .nav-links,.nav-actions{display:none}
  .hamburger{display:flex}
  .hero h1{font-size:2.2rem}
  .hero p{font-size:0.95rem}
  .features,.pricing,.process{grid-template-columns:1fr}
  .stats{grid-template-columns:repeat(2,1fr)}
  .footer-grid{grid-template-columns:1fr;text-align:center}
  .footer-brand p{margin:0 auto}
}
@media(max-width:480px){.hero{padding:5rem 1rem 3rem}.section{padding:3rem 1rem}}
.mobile-open .nav-links{display:flex;flex-direction:column;position:fixed;top:60px;left:0;right:0;background:rgba(7,11,20,0.98);padding:1.5rem 2rem;border-bottom:1px solid var(--border);gap:1rem}
.mobile-open .nav-actions{display:flex;position:fixed;top:330px;left:0;right:0;padding:0 2rem 1.5rem;background:rgba(7,11,20,0.98);border-bottom:1px solid var(--border)}
</style>
</head>
<body>

<nav class="navbar" id="navbar">
  <a href="#" class="logo">
    <?=icon('<path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2"/>',22)?>
    <?=$appName?>
  </a>

  <div class="nav-actions">
    <a href="login.php" class="btn btn-ghost"><?=icon('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/>')?> Masuk</a>
    <a href="login.php?register=1" class="btn btn-primary">Daftar <?=icon('<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/>')?></a>
  </div>
  <button class="hamburger" id="hamburger" onclick="document.getElementById('navbar').classList.toggle('mobile-open')">
    <span></span><span></span><span></span>
  </button>
</nav>

<section class="hero" id="hero">
  <div class="hero-orb"></div>
  <div class="hero-orb"></div>
  <div class="hero-content">
    <div class="hero-badge"><?=icon('<polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>',14)?> Premium VPN Service Indonesia</div>
    <h1>Layanan Tunneling Terbaik</h1>
    <p>Nikmati berselancar dengan layanan tunneling terbaik. SSH, Trojan, VMess, VLess, dan UDP Custom dengan harga termurah.</p>
    <div class="hero-actions">
      <a href="login.php?register=1" class="btn btn-primary">Daftar Sekarang <?=icon('<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>')?></a>
      <a href="login.php" class="btn btn-ghost"><?=icon('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/>')?> Masuk</a>
    </div>
  </div>
</section>

<section class="section" id="layanan">
  <div class="section-header">
    <h2>Layanan & Fitur Terlengkap</h2>
    <p>Dengan sistem yang fleksibel, kamu bisa mengelola akun tunnel dengan mudah tanpa ribet.</p>
  </div>
  <div class="features">
    <div class="feature-card"><?=featureIcon('<rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>')?><h3>Tampilan Responsif</h3><p>Tampilan yang responsif dan mudah dipahami di perangkat apapun.</p></div>
    <div class="feature-card"><?=featureIcon('<path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>')?><h3>Pelayanan Terbaik</h3><p>Nikmati pelayanan dengan respon cepat dan terbaik dari tim kami.</p></div>
    <div class="feature-card"><?=featureIcon('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>')?><h3>Berbagai Protokol</h3><p>Tersedia SSH, Trojan, VMess, VLess, UDP Custom dan ZIVPN.</p></div>
    <div class="feature-card"><?=featureIcon('<rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>')?><h3>Pembayaran Mudah</h3><p>Sistem serba otomatis dengan berbagai metode pembayaran lengkap.</p></div>
    <div class="feature-card"><?=featureIcon('<path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/>')?><h3>Sistem Billing</h3><p>Berlangganan bulanan, mingguan, atau bayar sesuai pemakaian (Pay As Go).</p></div>
    <div class="feature-card"><?=featureIcon('<path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/>')?><h3>Harga Terbaik</h3><p>Nikmati layanan dengan harga terbaik di kelasnya, tanpa biaya tersembunyi.</p></div>
  </div>
</section>



<section class="section" style="padding-bottom:2rem">
  <div class="section-header">
    <h2>Mulai Berlangganan Sekarang</h2>
    <p>Dapatkan akun tunneling kamu dengan cepat dan mudah dalam 3 langkah.</p>
  </div>
  <div class="process">
    <div class="process-step"><div class="num">1</div><h3>Daftarkan Akun</h3><p>Buat akun kamu dengan cepat dan mudah tanpa proses yang ribet.</p></div>
    <div class="process-step"><div class="num">2</div><h3>Pilih Server</h3><p>Tentukan server tunnel yang kamu inginkan sebelum melakukan pembayaran.</p></div>
    <div class="process-step"><div class="num">3</div><h3>Nikmati Layanan</h3><p>Buat akun tunnel dan langsung rasakan layanan tunnel terbaik dari kami.</p></div>
  </div>
</section>



<section class="section" id="faq">
  <div class="section-header">
    <h2>Pertanyaan Umum</h2>
    <p>Jika ada pertanyaan yang belum terjawab, hubungi support WhatsApp kami.</p>
  </div>
  <div class="faq">
    <div class="faq-item"><button class="faq-q" onclick="toggleFaq(this)">Apakah akun tunnel diaktifkan secara instan?<?=icon('<polyline points="6 9 12 15 18 9"/>')?></button><div class="faq-a">Ya, akun tunnel akan langsung aktif tanpa harus menunggu persetujuan. Kamu bisa langsung menikmati layanan setelah pembayaran berhasil.</div></div>
    <div class="faq-item"><button class="faq-q" onclick="toggleFaq(this)">Apakah bisa berpindah server dan protokol?<?=icon('<polyline points="6 9 12 15 18 9"/>')?></button><div class="faq-a">Server dapat diubah dengan interval 15 menit. Perpindahan protokol tersedia untuk layanan Trojan, VMess, dan VLess.</div></div>
    <div class="faq-item"><button class="faq-q" onclick="toggleFaq(this)">Berapa batas login sesi setiap akun tunnel?<?=icon('<polyline points="6 9 12 15 18 9"/>')?></button><div class="faq-a">Setiap akun tunnel hanya diizinkan maksimal 2 perangkat. Khusus STB, hanya diperbolehkan 1 STB dan 1 perangkat lainnya.</div></div>
    <div class="faq-item"><button class="faq-q" onclick="toggleFaq(this)">Apakah bisa melakukan perpanjangan otomatis?<?=icon('<polyline points="6 9 12 15 18 9"/>')?></button><div class="faq-a">Kamu dapat mengaktifkan auto renew pada setelan akun tunnel. Pastikan saldo cukup pada saat tanggal masa aktif tiba.</div></div>
    <div class="faq-item"><button class="faq-q" onclick="toggleFaq(this)">Mode berlangganan tersedia apa saja?<?=icon('<polyline points="6 9 12 15 18 9"/>')?></button><div class="faq-a">Tersedia langganan bulanan, mingguan, dan Pay As Go (bayar sesuai pemakaian per jam).</div></div>
  </div>
</section>

<footer class="footer">
  <div class="footer-grid">
    <div class="footer-brand"><h3><?=$appName?></h3><p>Layanan Tunneling Premium Indonesia. Berselancar dengan aman di dunia internet dengan tunneling terbaik.</p></div>
    <div class="footer-col"><h4>Layanan</h4><a href="#layanan">SSH</a><a href="#layanan">Trojan</a><a href="#layanan">VMess</a><a href="#layanan">VLess</a></div>
    <div class="footer-col"><h4>Halaman</h4><a href="#hero">Beranda</a><a href="#harga">Harga</a><a href="login.php">Masuk</a><a href="login.php?register=1">Daftar</a></div>
    <div class="footer-col"><h4>Kontak</h4><a href="#">Telegram: <?=esc(getSetting('contact_tg','@ordervpn_admin'))?></a><a href="#">WhatsApp: <?=esc(getSetting('contact_wa','0812-3456-7890'))?></a></div>
  </div>
  <div class="footer-bottom">2020-<?=date('Y')?> &copy; <?=$appName?> &mdash; All Rights Reserved</div>
</footer>

<script>
function toggleFaq(btn){
  var a=btn.nextElementSibling;
  var isOpen=a.classList.contains('show');
  document.querySelectorAll('.faq-a').forEach(function(e){e.classList.remove('show')});
  document.querySelectorAll('.faq-q').forEach(function(e){e.classList.remove('active')});
  if(!isOpen){a.classList.add('show');btn.classList.add('active')}
}
document.querySelectorAll('.nav-links a').forEach(function(a){
  a.addEventListener('click',function(){document.getElementById('navbar').classList.remove('mobile-open')});
});
</script>
</body>
</html>
