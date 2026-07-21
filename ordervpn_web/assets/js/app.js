document.addEventListener('DOMContentLoaded', () => {
  /* ── SIDEBAR TOGGLE ── */
  const sidebar = document.getElementById('sidebar');
  const hamburger = document.getElementById('hamburger');
  if (hamburger && sidebar) {
    hamburger.addEventListener('click', (e) => {
      e.stopPropagation();
      sidebar.classList.toggle('open');
    });
    document.addEventListener('click', (e) => {
      if (window.innerWidth <= 768 && sidebar.classList.contains('open') && !sidebar.contains(e.target) && !hamburger.contains(e.target)) {
        sidebar.classList.remove('open');
      }
    });
  }

  /* ── TABS ── */
  document.querySelectorAll('.tabs').forEach((tabGroup) => {
    const btns = tabGroup.querySelectorAll('.tab-btn');
    const contents = document.querySelectorAll(tabGroup.dataset.target ? `${tabGroup.dataset.target} .tab-content` : '.tab-content');
    btns.forEach((btn) => {
      btn.addEventListener('click', () => {
        btns.forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        contents.forEach((c) => c.classList.remove('active'));
        const target = document.getElementById(btn.dataset.tab);
        if (target) target.classList.add('active');
      });
    });
  });

  /* ── ADMIN TABS ── */
  document.querySelectorAll('.admin-tabs').forEach((group) => {
    const btns = group.querySelectorAll('.admin-tab');
    btns.forEach((btn) => {
      btn.addEventListener('click', () => {
        btns.forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        document.querySelectorAll('.page').forEach((p) => p.classList.remove('active'));
        const target = document.getElementById(btn.dataset.page);
        if (target) target.classList.add('active');
      });
    });
  });
});

/* ── TOAST ── */
function showToast(message, type = 'success') {
  let container = document.querySelector('.toast-container');
  if (!container) {
    container = document.createElement('div');
    container.className = 'toast-container';
    document.body.appendChild(container);
  }
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  const icons = { success: '✓', error: '✗', info: 'ℹ' };
  toast.innerHTML = `<span>${icons[type] || ''}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(20px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

/* ── COPY ── */
function copyText(text, el) {
  const fallback = (t, e) => {
    const ta = document.createElement('textarea');
    ta.value = t; ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta); ta.select();
    try { document.execCommand('copy'); if (e) { e.textContent = 'Copied!'; setTimeout(() => { e.textContent = 'Copy'; }, 2000); } showToast('Copied!', 'success'); }
    catch (ex) { showToast('Copy failed', 'error'); }
    document.body.removeChild(ta);
  };
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      if (el) { el.textContent = 'Copied!'; setTimeout(() => { el.textContent = 'Copy'; }, 2000); }
      showToast('Copied to clipboard!', 'success');
    }).catch(() => fallback(text, el));
  } else { fallback(text, el); }
}

function escHtml(s) {
  const d = document.createElement('div');
  d.appendChild(document.createTextNode(s));
  return d.innerHTML;
}
