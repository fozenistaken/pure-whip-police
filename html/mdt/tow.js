(() => {
  const SELF = document.currentScript && document.currentScript.src;

  const CSS = `
.tw{position:absolute;inset:0;background:var(--bg);display:grid;grid-template-rows:auto minmax(0,1fr);padding:var(--safe-top,0) 0 var(--safe-bottom,0)}
.tw-top{display:flex;align-items:baseline;gap:.75rem;padding:.875rem 1.125rem .5rem}
.tw-top h1{margin:0;flex:1 1 10rem;min-width:0;font-size:1.375rem;font-weight:800;letter-spacing:-.02em}
.tw-body{min-height:0;overflow-y:auto;padding:.25rem 1.125rem 1rem;display:grid;align-content:start;gap:.75rem}
.tw-body::-webkit-scrollbar{width:.375rem}.tw-body::-webkit-scrollbar-track{background:transparent}
.tw-body::-webkit-scrollbar-thumb{background:var(--line);border-radius:1rem}.tw-body::-webkit-scrollbar-button{display:none;height:0}
.tw-row{flex-wrap:wrap}
.tw-row>.t{flex:1 1 9rem;min-width:0}
`;

  let B = null;
  const live = new WeakMap();
  const ago = (sec) => {
    const s = Math.max(0, Math.floor(Date.now() / 1000 - sec));
    return s < 60 ? 'just now' : s < 3600 ? Math.floor(s / 60) + ' min ago' : Math.floor(s / 3600) + ' h ago';
  };

  const render = (app) => {
    const s = app.state;
    const jobs = s.jobs || [];
    const rows = jobs.map((j) => `<div class="pwp-row tw-row" data-key="j${j.id}"><span class="pwp-plate">${B.esc(j.plate || '')}</span><span class="t">${B.esc(j.lotLabel)}<span class="s">${B.esc([j.model, j.reason, ago(j.at)].filter(Boolean).join(' · '))}</span></span>
      ${j.x != null ? `<button class="pwp-btn sm pwp-press" data-act="waypoint" data-x="${j.x}" data-y="${j.y}">Waypoint</button>` : '<span class="pwp-flag">Not out</span>'}</div>`).join('');
    return `<div class="tw pwp"><header class="tw-top"><h1>Tow jobs</h1></header><div class="tw-body" data-scroll="tw">
      ${s.err ? `<div class="pwp-err" role="alert">${B.icons.alert}<span>${B.esc(s.err)}</span></div>` : ''}
      <section class="pwp-card">${s.jobs == null ? '' : rows || '<div class="pwp-empty">No cars waiting. Police tow requests land here.</div>'}</section></div></div>`;
  };

  const draw = (app) => {
    const ctx = live.get(app);
    if (!ctx || !B) return;
    const root = ctx.el.querySelector('.tw-root');
    if (root) root.innerHTML = render(app);
  };

  const ask = async (app, action, args) => {
    try { const r = await app.request(action, args || {}); app.state.err = null; return r; } catch (e) { app.state.err = (e && e.reason) || 'Something went wrong'; return null; }
  };
  const load = async (app) => { const r = await ask(app, 'jobs'); if (r) app.state.jobs = r; draw(app); };

  const DEF = {
    id: 'pwptow', name: 'Tow', version: '1.0.0', order: 8, statusBar: 'light',
    icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 16V9h7l3 4h5l3 3"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/><path d="M10 9V5l6 4"/></svg>',
    state: () => ({ jobs: null, err: null }),
    mount(app, el) {
      el.innerHTML = '<div class="tw-root"></div>';
      live.set(app, { el });
      el.addEventListener('click', async (e) => {
        const t = e.target.closest('[data-act="waypoint"]');
        if (!t || !el.contains(t)) return;
        const r = await ask(app, 'waypoint', { x: Number(t.dataset.x), y: Number(t.dataset.y) });
        if (r) app.toast('Waypoint set');
        draw(app);
      });
      draw(app);
    },
    update(app, el) { const ctx = live.get(app); if (ctx && ctx.el !== el) { ctx.el = el; draw(app); } },
    unmount(app) { live.delete(app); },
    open(app) { return load(app); },
    badge(app) { return (app.state.jobs || []).length || 0; },
  };

  WhipPhone.module(DEF);

  const need = (name, path) => new Promise((resolve) => {
    if (!SELF) return resolve(!!window[name]);
    if (window[name]) return resolve(true);
    const url = new URL(path, SELF);
    url.search = new URL(SELF).search;
    const sc = document.createElement('script');
    sc.src = url.href;
    sc.onload = () => resolve(!!window[name]);
    sc.onerror = () => resolve(!!window[name]);
    document.head.appendChild(sc);
  });
  need('PWPBracket', '../shared/bracket.js').then((ok) => {
    if (!ok) return;
    B = window.PWPBracket;
    WhipPhone.module({ ...DEF, css: B.css + CSS, globalCss: B.fonts });
  });
})();
