(() => {
  const SELF = document.currentScript && document.currentScript.src;

  const CSS = `
.tb{position:absolute;inset:0;background:var(--bg);display:grid;grid-template-rows:auto minmax(0,1fr) auto;padding:var(--safe-top,0) 0 var(--safe-bottom,0)}
.tb-top{display:flex;align-items:center;gap:.75rem;padding:.875rem 1.125rem .5rem}
.tb-top h1{margin:0;flex:1 1 10rem;min-width:0;font-size:1.375rem;font-weight:800;letter-spacing:-.02em}
.tb-top .place{font-size:.75rem;color:var(--mute);text-align:right}
.tb-body{min-height:0;overflow-y:auto;padding:.25rem 1.125rem 1rem;display:grid;align-content:start;gap:.75rem}
.tb-body::-webkit-scrollbar{width:.375rem}.tb-body::-webkit-scrollbar-track{background:transparent}
.tb-body::-webkit-scrollbar-thumb{background:var(--line);border-radius:1rem}.tb-body::-webkit-scrollbar-button{display:none;height:0}
.tb-pick{display:grid;gap:.375rem}
.tb-pick .pwp-row.on{border-color:var(--accent);outline:1px solid var(--accent)}
.tb-pick .pwp-row[aria-disabled="true"]{opacity:.5}
.tb-charges{display:grid;gap:.375rem}
.tb-foot{display:flex;align-items:center;gap:.75rem;padding:.75rem 1.125rem;border-top:1px solid var(--line)}
.tb-foot .sum{flex:1;display:grid;line-height:1.15}
.tb-foot .sum small{font-size:.625rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint)}
.tb-foot .sum b{font-size:1.25rem;font-variant-numeric:tabular-nums}
.tb-done{display:grid;place-items:center;align-content:center;gap:.5rem;text-align:center;padding:2rem 1rem}
.tb-done b{font-family:var(--mono);font-size:1.5rem;letter-spacing:.06em}
.tb-done span{color:var(--mute)}
`;

  const KINDS = [['citation', 'Citation'], ['parking', 'Parking'], ['warning', 'Warning']];
  let B = null;
  const live = new WeakMap();

  const ask = async (app, action, args) => {
    const s = app.state;
    try { const r = await app.request(action, args || {}); s.err = null; return r; } catch (e) { s.err = (e && e.reason) || 'Something went wrong'; return null; }
  };

  const chargesFor = (s) => (s.data ? s.data.penal : []).filter((c) => (s.kind === 'parking' ? c.parking : c.citation));
  const total = (s) => {
    if (s.kind === 'warning') return 0;
    const sum = chargesFor(s).filter((c) => s.codes[c.code]).reduce((a, c) => a + c.fine, 0);
    return Math.min(sum, (s.data && s.data.maxAmount) || sum);
  };
  const ready = (s) => Object.values(s.codes).some(Boolean) && (s.kind === 'parking' ? s.car != null : s.person != null);

  const render = (app) => {
    const s = app.state;
    if (s.done) return `<div class="tb pwp"><div class="tb-done"><span>${B.esc(s.done.label)} written</span><b>${B.esc(s.done.number)}</b><span>${s.done.amount ? B.money(s.done.amount) + ' · ' : ''}both copies printed</span></div></div>`;
    if (!s.data) return `<div class="tb pwp"><div class="tb-done"><span>${B.esc(s.err || 'Looking around')}</span></div></div>`;
    const d = s.data;
    const who = s.kind === 'parking'
      ? (d.cars.length ? d.cars.map((c) => `<button class="pwp-row ${s.car === c.vehicleId ? 'on' : ''}" data-act="car" data-id="${c.vehicleId}" aria-pressed="${s.car === c.vehicleId}" aria-disabled="${!c.owned}"><span class="pwp-plate">${B.esc(c.plate || '')}</span><span class="t">${B.esc(c.model || 'Car')}<span class="s">${c.owned ? 'Registered' : 'No owner on record: tow it'}</span></span></button>`).join('') : '<div class="pwp-empty">No car close by</div>')
      : (d.people.length ? d.people.map((p) => `<button class="pwp-row ${s.person === p.source ? 'on' : ''}" data-act="person" data-id="${p.source}" aria-pressed="${s.person === p.source}"><span class="pwp-code">${p.charId}</span><span class="t">${B.esc(p.name || 'Citizen ' + p.charId)}</span></button>`).join('') : '<div class="pwp-empty">Nobody close by</div>');
    const q = String(s.q || '').toLowerCase();
    const charges = chargesFor(s).filter((c) => !q || (c.title + ' ' + c.code).toLowerCase().includes(q))
      .map((c) => `<button class="pwp-row ${s.codes[c.code] ? 'on' : ''}" data-act="code" data-c="${B.esc(c.code)}" aria-pressed="${!!s.codes[c.code]}"><span class="pwp-code">${B.esc(c.code)}</span><span class="t">${B.esc(c.title)}</span>${s.kind === 'warning' ? '' : `<span class="num">${B.money(c.fine)}</span>`}</button>`).join('');
    const t = total(s);
    return `<div class="tb pwp"><header class="tb-top"><h1>Ticket book</h1><span class="place">${B.esc(s.place || '')}</span></header>
      <div class="tb-body" data-scroll="tb">
        ${s.err ? `<div class="pwp-err" role="alert">${B.icons.alert}<span>${B.esc(s.err)}</span></div>` : ''}
        <div class="pwp-seg" data-glide="tbkind" style="justify-self:start">${KINDS.map(([v, l]) => `<button class="${s.kind === v ? 'on' : ''}" data-act="kind" data-v="${v}" aria-pressed="${s.kind === v}">${l}</button>`).join('')}</div>
        <section class="pwp-card"><p class="pwp-lbl">${s.kind === 'parking' ? 'Car' : 'Person'}</p><div class="tb-pick">${who}</div></section>
        <section class="pwp-card"><p class="pwp-lbl">Charges</p>
          <label class="pwp-search">${B.icons.search}<input id="f-tbq" data-bind="q" value="${B.esc(s.q || '')}" placeholder="Find a charge" autocomplete="off"></label>
          <div class="tb-charges tb-pick">${charges || '<div class="pwp-empty">No charge matches</div>'}</div></section>
        <section class="pwp-card"><p class="pwp-lbl">Note</p><input id="f-tbnote" class="pwp-in" data-bind="notes" value="${B.esc(s.notes || '')}" placeholder="What you saw, e.g. 65 in a 40"></section>
      </div>
      <div class="tb-foot"><div class="sum"><small>${s.kind === 'warning' ? 'Warning' : 'Fine'}</small><b>${s.kind === 'warning' ? 'No fine' : B.money(t)}</b></div>
        <button class="pwp-cta pwp-press" data-act="write" ${ready(s) && !s.sending ? '' : 'disabled'}>${s.kind === 'warning' ? 'Give warning' : 'Write ticket'}</button></div></div>`;
  };

  const draw = (app) => {
    const ctx = live.get(app);
    if (!ctx || !B) return;
    const root = ctx.el.querySelector('.tb-root');
    if (!root) return;
    const active = ctx.el.ownerDocument.activeElement;
    const keep = active && ctx.el.contains(active) && active.id ? { id: active.id, a: active.selectionStart, b: active.selectionEnd } : null;
    const sc = root.querySelector('[data-scroll]');
    const top = sc ? sc.scrollTop : 0;
    root.innerHTML = render(app);
    const sc2 = root.querySelector('[data-scroll]');
    if (sc2) sc2.scrollTop = top;
    root.querySelectorAll('[data-glide]').forEach((g) => B.glide(g, ctx.mem, g.dataset.glide));
    if (keep) { const n = root.querySelector('#' + keep.id); if (n) { n.focus(); n.setSelectionRange(keep.a, keep.b); } }
  };

  const actions = {
    kind(app, d) { const s = app.state; s.kind = d.v; s.codes = {}; },
    person(app, d) { app.state.person = Number(d.id); },
    car(app, d) {
      const s = app.state; const c = (s.data.cars || []).find((x) => x.vehicleId === Number(d.id));
      if (!c || !c.owned) return 'skip';
      s.car = c.vehicleId;
    },
    code(app, d) { const c = app.state.codes; c[d.c] = !c[d.c]; },
    async write(app) {
      const s = app.state;
      if (!ready(s) || s.sending) return;
      s.sending = true; draw(app);
      const r = await ask(app, 'write', { kind: s.kind, target: s.person, vehicleId: s.car, codes: Object.keys(s.codes).filter((k) => s.codes[k]), notes: s.notes || '', place: s.place || '' });
      s.sending = false;
      if (!r) return;
      s.done = { number: r.number, amount: r.amount, label: KINDS.find(([v]) => v === s.kind)[1] };
      draw(app);
      setTimeout(() => { if (app.forced) app.done({ number: r.number }); }, 1400);
    },
  };

  const run = (app, name, data) => {
    const fn = actions[name];
    if (!fn) return;
    const r = fn(app, data);
    if (r === 'skip') return;
    draw(app);
    if (r && typeof r.then === 'function') r.then(() => draw(app));
  };

  const DEF = {
    id: 'pwpticket', name: 'Ticket book', version: '1.0.0', order: 7, statusBar: 'light',
    icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6M9 16h3"/></svg>',
    state: () => ({ kind: 'citation', data: null, person: null, car: null, codes: {}, q: '', notes: '', place: '', err: null, done: null, sending: false }),
    mount(app, el, view) {
      el.innerHTML = '<div class="tb-root"></div>';
      const ctx = { el, view, mem: {} };
      live.set(app, ctx);
      el.addEventListener('click', (e) => { const t = e.target.closest('[data-act]'); if (t && el.contains(t) && !t.disabled) run(app, t.dataset.act, { ...t.dataset }); });
      el.addEventListener('input', (e) => { const k = e.target.dataset && e.target.dataset.bind; if (!k) return; app.state[k] = e.target.value; if (k === 'q') draw(app); });
      draw(app);
    },
    update(app, el, view) { const ctx = live.get(app); if (ctx && ctx.el !== el) { ctx.el = el; ctx.view = view; ctx.mem = {}; draw(app); } },
    unmount(app) { live.delete(app); },
    async open(app, args) {
      const s = app.state;
      Object.assign(s, DEF.state(), { place: (args && args.place) || '' });
      draw(app);
      s.data = await ask(app, 'nearby', { people: (args && args.people) || [], cars: (args && args.cars) || [] });
      if (s.data && s.data.people.length === 1) s.person = s.data.people[0].source;
      draw(app);
    },
    back(app) { if (app.forced) { app.done({}); return true; } return false; },
  };

  WhipPhone.module(DEF);

  const need = (name, path) => new Promise((resolve) => {
    if (!SELF) return resolve(!!window[name]);
    const url = new URL(path, SELF);
    url.search = new URL(SELF).search;
    if (window[name]) return resolve(true);
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
