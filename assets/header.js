// /assets/header.js
// Reusable header + auth indicator + viewer controls (open/download/print)

function $(sel, root = document) { return root.querySelector(sel); }
function create(tag, props = {}, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (k === 'class') el.className = v;
    else if (k === 'text') el.textContent = v;
    else el.setAttribute(k, v);
  }
  for (const kid of kids) {
    if (kid == null || kid === false) continue;
    if (typeof kid === 'string' || typeof kid === 'number') {
      el.appendChild(document.createTextNode(String(kid)));
    } else if (kid && typeof kid.nodeType === 'number') {
      el.appendChild(kid);
    }
  }
  return el;
}

// ---------- Header / breadcrumbs / logout ----------
async function setupHeader() {
  const hdr = $('.site-header');
  if (!hdr) return;

  // Ensure crumb container + title element exist
  let crumbs = hdr.querySelector('.crumbs');
  if (!crumbs) crumbs = hdr.appendChild(create('nav', { class: 'crumbs', 'aria-label': 'Breadcrumb' }));
  const titleEl = hdr.querySelector('.page-title') || hdr.appendChild(create('h1', { class: 'page-title' }));

  // Build breadcrumbs from data-crumbs attribute
  let parts = [];
  try { parts = JSON.parse(hdr.getAttribute('data-crumbs') || '[]'); } catch {}
  crumbs.innerHTML = '';

  const backText = hdr.getAttribute('data-back-text') || 'Home';
  const backHref = hdr.getAttribute('data-back-href') || '/';
  crumbs.appendChild(create('a', { class: 'back', href: backHref }, `← ${backText}`));

  parts.forEach(([href, text]) => {
    crumbs.appendChild(create('span', { class: 'sep', text: '›' }));
    crumbs.appendChild(create('a', { href }, text));
  });

  // Spacer then title
  if (!$('.spacer', hdr)) hdr.appendChild(create('span', { class: 'spacer' }));
  titleEl.textContent = hdr.getAttribute('data-title') || document.title || 'Page';

  // Auth probe for Logout button + status badge
  try {
    const r = await fetch('/__session', { cache: 'no-store' });
    const s = r.ok ? await r.json() : { any: false };
    // Tiny status badge (remove these two lines later if you want)
    const badge = create('span', { text: s.any ? '· signed in' : '· guest' });
    badge.style.cssText = 'margin-left:10px;font-size:12px;color:#a9b4cf';
    hdr.appendChild(badge);

    if (s.any && !$('.logout', hdr)) {
      hdr.appendChild(create(
        'a',
        {
          class: 'logout',
          href: '/__logout?return=' + encodeURIComponent(location.pathname + location.search),
          role: 'button'
        },
        'Logout'
      ));
    }

    // Show warm/build status for all visitors
    try {
      const ws = await fetch('/__warm-status', { cache: 'no-store' });
      if (ws.ok) {
        const j = await ws.json();
        const short = (j.commit || '').slice(0, 7) || 'dev';
        const warmed = j.warmed === true;
        const warmedAt = j.warmedAt ? new Date(j.warmedAt) : null;
        const builtAt = j.builtAtEpoch ? new Date(j.builtAtEpoch * 1000) : (j.builtAt ? new Date(j.builtAt) : null);
        const whenWarm = warmedAt ? `warmed ${warmedAt.toLocaleString()}` : 'not warmed yet';
        const whenBuilt = builtAt ? `built ${builtAt.toLocaleString()}` : '';
        const txt = warmed ? `warm ✓ ${short}` : `cold • ${short}`;
        const tip = `${whenBuilt}${whenBuilt && whenWarm ? ' • ' : ''}${whenWarm}`;
        const tag = create('span', { title: tip.trim() }, ` · ${txt}`);
        tag.style.cssText = 'margin-left:8px;font-size:12px;color:#9ecbff';
        hdr.appendChild(tag);
      }
    } catch {}
  } catch (e) {
    // Silent fail; check worker route if needed
    // console.warn('Session probe failed', e);
  }
}

// ---------- Version helpers (for current.pdf) ----------
async function getBuildVersion() {
  try {
    const r = await fetch('/version.json', { cache: 'no-store' });
    if (r.ok) { const j = await r.json(); return j?.commit || 'dev'; }
  } catch {}
  return 'dev';
}

async function ensureVersionedPdf(urlStr) {
  try {
    const u = new URL(urlStr, location.origin);
    const isProtectedPdf = /^\/(summons|minutes|other|appendices|guides\/(?:1|2|3|inst))\/[^/]+\.pdf$/i.test(u.pathname);
    if (isProtectedPdf) {
      const v = await getBuildVersion();
      u.searchParams.set('v', v); // override any stale value
    }
    return u.toString();
  } catch { return urlStr; }
}

// ---------- Viewer controls (open / download / print) ----------
async function setupViewerControls() {
  // Only run on viewer pages (has ?pdf=…)
  const qs = new URLSearchParams(location.search);
  const pdfParam = qs.get('pdf');
  if (!pdfParam) return;

  const rawUrl = pdfParam;
  const versionedUrl = await ensureVersionedPdf(rawUrl);

  // Primary controls (new buttons)
  const openBtn = $('#btn-open');
  if (openBtn) openBtn.href = versionedUrl;

  const dlBtn = $('#btn-download');
  if (dlBtn) {
    dlBtn.href = versionedUrl;
    try {
      const name = new URL(versionedUrl, location.origin).pathname.split('/').pop() || 'document.pdf';
      dlBtn.setAttribute('download', name);
    } catch {
      dlBtn.setAttribute('download', 'document.pdf');
    }
  }

  const printBtn = $('#btn-print');
  if (printBtn) {
    printBtn.onclick = () => {
      const w = window.open(versionedUrl, '_blank', 'noopener');
      if (w) setTimeout(() => { try { w.focus(); w.print(); } catch {} }, 1000);
    };
  }

  // Back-compat with older viewer header IDs (guarded)
  const openPdfEl = $('#open-pdf');
  if (openPdfEl) openPdfEl.href = versionedUrl;

  const copyBtn = $('#copy-link');
  if (copyBtn) {
    copyBtn.onclick = async () => {
      const link = location.origin + '/viewer.html?pdf=' + encodeURIComponent(versionedUrl);
      try { await navigator.clipboard.writeText(link); alert('Viewer link copied.'); }
      catch { prompt('Copy this link:', link); }
    };
  }

  const titleEl = $('#title');
  if (titleEl) {
    try {
      titleEl.textContent = new URL(versionedUrl, location.href).pathname.split('/').pop();
    } catch {}
  }
}

// ---------- Boot ----------
function boot() {
  setupHeader();
  setupViewerControls();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot);
} else {
  boot();
}