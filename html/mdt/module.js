(() => {
  const ICON = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
  const I = {
    badge: ICON('<path d="M12 2l7 3v6c0 5-3.5 9-7 11-3.5-2-7-6-7-11V5z"/><path d="M9 12l2 2 4-4"/>'),
    home: ICON('<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>'),
    calls: ICON('<path d="M12 3v3M5.6 5.6l2.1 2.1M3 12h3M18 12h3M16.3 7.7l2.1-2.1"/><circle cx="12" cy="14" r="5"/>'),
    people: ICON('<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4.5-6 8-6s7 2 8 6"/>'),
    car: ICON('<path d="M5 16l1.5-5h11L19 16"/><rect x="3" y="16" width="18" height="4" rx="1"/><circle cx="7.5" cy="20" r="1"/><circle cx="16.5" cy="20" r="1"/>'),
    report: ICON('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 12h5M10 16h5"/>'),
    warrant: ICON('<path d="M4 20h16M6 20V9l6-5 6 5v11"/><path d="M10 20v-6h4v6"/>'),
    bolo: ICON('<circle cx="11" cy="11" r="6"/><path d="M20 20l-4.5-4.5"/>'),
    penal: ICON('<path d="M12 3v18M5 7h14M7 7l-3 7h6zM17 7l-3 7h6z"/>'),
    prison: ICON('<rect x="4" y="4" width="16" height="16" rx="1"/><path d="M9 4v16M15 4v16"/>'),
    units: ICON('<circle cx="8" cy="9" r="3"/><circle cx="16" cy="9" r="3"/><path d="M2 20c.8-3 3.2-5 6-5s5.2 2 6 5M12 20c.8-3 3.2-5 6-5"/>'),
    plus: ICON('<path d="M12 5v14M5 12h14"/>'),
    minus: ICON('<path d="M5 12h14"/>'),
    back: ICON('<path d="M15 5l-7 7 7 7"/>'),
    close: ICON('<path d="M6 6l12 12M18 6L6 18"/>'),
  };

  const TABS = [
    ['home', 'Home', 'home'], ['calls', 'Calls', 'calls'], ['people', 'People', 'people'], ['vehicles', 'Vehicles', 'car'],
    ['reports', 'Reports', 'report'], ['warrants', 'Warrants', 'warrant'], ['bolos', 'BOLOs', 'bolo'],
    ['penal', 'Penal code', 'penal'], ['prison', 'Prison', 'prison'], ['units', 'Units', 'units'],
  ];
  const STATUS = { available: 'Available', enroute: 'En route', onscene: 'On scene', busy: 'Busy' };
  const CAT = { infraction: 'Infraction', misdemeanor: 'Misdemeanor', felony: 'Felony' };

  const css = `

.pm{--ink:#0b1220;--panel:#111a2e;--raise:#16223b;--line:#22304d;--text:#e6ecf5;--mute:#8a97ae;--accent:#4c8dff;--ok:#2fbf71;--warn:#f5a524;--bad:#f2545b;
  position:absolute;inset:0;display:flex;flex-direction:column;background:var(--ink);color:var(--text);font-family:system-ui,-apple-system,"Segoe UI",sans-serif;font-size:.875rem;line-height:1.35}
.pm *{box-sizing:border-box}
.pm svg{width:1.1rem;height:1.1rem;flex:none}
.pm ::selection{background:var(--accent);color:#fff}
.pm ::-webkit-scrollbar{width:.375rem;height:.375rem}
.pm ::-webkit-scrollbar-track{background:transparent}
.pm ::-webkit-scrollbar-thumb{background:var(--line);border-radius:1rem}
.pm ::-webkit-scrollbar-button,.pm ::-webkit-scrollbar-corner{display:none;background:transparent}
.pm .top{display:flex;align-items:center;gap:.75rem;padding:.75rem 1rem;border-bottom:1px solid var(--line);background:var(--panel);flex-wrap:wrap}
.pm .brand{display:flex;align-items:center;gap:.5rem;font-weight:700;letter-spacing:.04em}
.pm .brand svg{width:1.4rem;height:1.4rem;color:var(--accent)}
.pm .tag{font-size:.7rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;padding:.15rem .45rem;border-radius:.3rem;background:var(--raise);color:var(--mute)}
.pm .who{display:flex;flex-direction:column;margin-right:auto}
.pm .who b{font-size:.9rem}
.pm .who span{color:var(--mute);font-size:.75rem}
.pm .seg{display:flex;gap:.25rem;flex-wrap:wrap}
.pm .seg button{font:inherit;font-size:.75rem;font-weight:600;padding:.35rem .6rem;border-radius:.4rem;border:1px solid var(--line);background:transparent;color:var(--mute);cursor:pointer}
.pm .seg button.on.available{background:var(--ok);border-color:var(--ok);color:#06210f}
.pm .seg button.on.busy{background:var(--warn);border-color:var(--warn);color:#2a1a00}
.pm .seg button.on.enroute,.pm .seg button.on.onscene{background:var(--accent);border-color:var(--accent);color:#fff}
.pm .body{flex:1;display:flex;min-height:0}
.pm .rail{display:flex;flex-direction:column;gap:.15rem;padding:.6rem .4rem;border-right:1px solid var(--line);background:var(--panel);overflow-y:auto;width:9.5rem;flex:none}
.pm .rail button,.pm .tabs button{font:inherit;display:flex;align-items:center;gap:.6rem;padding:.55rem .65rem;border:0;border-radius:.45rem;background:transparent;color:var(--mute);cursor:pointer;text-align:left}
.pm .rail button svg,.pm .tabs button svg{width:1.15rem;height:1.15rem;flex:none}
.pm .rail button.on,.pm .tabs button.on{background:var(--raise);color:var(--text)}
.pm .rail button.on svg,.pm .tabs button.on svg{color:var(--accent)}
.pm .tabs{display:flex;flex-wrap:wrap;gap:.2rem;padding:.4rem .5rem;border-bottom:1px solid var(--line);background:var(--panel)}
.pm .tabs button{padding:.4rem .55rem;font-size:.78rem}
.pm .main{flex:1;overflow-y:auto;padding:1rem;min-width:0}
.pm h2{margin:0 0 .75rem;font-size:1.15rem;display:flex;align-items:center;gap:.5rem;flex-wrap:wrap}
.pm h3{margin:1rem 0 .5rem;font-size:.78rem;letter-spacing:.08em;text-transform:uppercase;color:var(--mute)}
.pm .search{display:flex;gap:.5rem;margin-bottom:.9rem}
.pm input,.pm textarea{font:inherit;color:var(--text);background:var(--panel);border:1px solid var(--line);border-radius:.5rem;padding:.6rem .75rem;width:100%;outline:none}
.pm input::placeholder,.pm textarea::placeholder{color:var(--mute)}
.pm input:focus,.pm textarea:focus{border-color:var(--accent)}
.pm textarea{min-height:9rem;resize:vertical}
.pm .btn{font:inherit;font-weight:600;font-size:.8rem;display:inline-flex;align-items:center;justify-content:center;gap:.35rem;padding:.55rem .85rem;border-radius:.5rem;border:1px solid var(--line);background:var(--raise);color:var(--text);cursor:pointer;white-space:nowrap}
.pm .btn svg{width:1rem;height:1rem}
.pm .btn.primary{background:var(--accent);border-color:var(--accent);color:#fff}
.pm .btn.danger{background:transparent;border-color:var(--bad);color:var(--bad)}
.pm .btn.ok{background:transparent;border-color:var(--ok);color:var(--ok)}
.pm .btn:focus-visible,.pm .seg button:focus-visible,.pm .rail button:focus-visible{outline:.125rem solid var(--accent);outline-offset:.0625rem}
.pm .row{display:flex;gap:.5rem;flex-wrap:wrap;align-items:center}
.pm .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(9rem,1fr));gap:.6rem}
.pm .stat{background:var(--panel);border:1px solid var(--line);border-radius:.6rem;padding:.75rem}
.pm .stat b{display:block;font-size:1.5rem;font-variant-numeric:tabular-nums}
.pm .stat span{color:var(--mute);font-size:.75rem}
.pm .list{display:flex;flex-direction:column;gap:.4rem}
.pm .item{display:flex;gap:.75rem;align-items:flex-start;background:var(--panel);border:1px solid var(--line);border-radius:.6rem;padding:.7rem .8rem;cursor:pointer}
.pm .item.static{cursor:default}
.pm .item:hover{border-color:var(--accent)}
.pm .item.static:hover{border-color:var(--line)}
.pm .item .grow{flex:1;min-width:0;overflow-wrap:anywhere}
.pm .item .sub{color:var(--mute);font-size:.78rem}
.pm .mono{font-family:ui-monospace,Consolas,monospace;font-variant-numeric:tabular-nums}
.pm .pill{display:inline-block;font-size:.68rem;font-weight:700;letter-spacing:.05em;text-transform:uppercase;padding:.15rem .45rem;border-radius:1rem;background:var(--raise);color:var(--mute)}
.pm .pill.bad{background:var(--bad);color:#fff}.pm .pill.warn{background:var(--warn);color:#2a1a00}
.pm .pill.ok{background:var(--ok);color:#06210f}.pm .pill.accent{background:var(--accent);color:#fff}
.pm .call{border-left:.25rem solid var(--warn)}
.pm .call.high{border-left-color:var(--bad)}
.pm .card{background:var(--panel);border:1px solid var(--line);border-radius:.6rem;padding:.9rem;margin-bottom:.75rem}
.pm dl{margin:0}
.pm .kv{display:grid;grid-template-columns:auto 1fr;gap:.3rem .9rem}
.pm .kv dt{color:var(--mute)}
.pm .kv dd{margin:0;overflow-wrap:anywhere}
.pm .empty{color:var(--mute);padding:1.5rem;text-align:center;border:1px dashed var(--line);border-radius:.6rem}
.pm .err{background:var(--bad);color:#fff;padding:.55rem .8rem;border-radius:.5rem;margin-bottom:.75rem;display:flex;justify-content:space-between;gap:.5rem}
.pm .err button{background:transparent;border:0;color:#fff;cursor:pointer}
.pm .err button svg{width:1rem;height:1rem}
.pm .total{display:flex;gap:1.25rem;font-weight:700;font-size:1rem;flex-wrap:wrap}
.pm .total span{color:var(--mute);font-weight:500;font-size:.78rem;display:block}
.pm .cnt{display:flex;align-items:center;gap:.3rem}
.pm .cnt button{width:1.8rem;height:1.8rem;padding:0}
.pm .two{display:grid;grid-template-columns:1fr 1fr;gap:.75rem}
.pm.phone .two{grid-template-columns:1fr}
.pm .back{margin-bottom:.75rem}
`;

  const e = (app, v) => app.esc(String(v == null ? '' : v));
  const money = (n) => '$' + Math.round(Number(n) || 0).toLocaleString('en-US');
  const when = (v) => {
    if (v == null) return '';
    const t = typeof v === 'number' ? (v < 1e12 ? v * 1000 : v) : Date.parse(v);
    if (!t) return String(v);
    const d = new Date(t);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) + ' ' + d.toTimeString().slice(0, 5);
  };
  const ago = (sec) => {
    const s = Math.max(0, Math.floor(Date.now() / 1000 - sec));
    return s < 60 ? 'now' : s < 3600 ? Math.floor(s / 60) + ' min' : Math.floor(s / 3600) + ' h';
  };

  const ask = async (app, action, args, after) => {
    app.state.busy = true;
    try {
      const r = await app.request(action, args || {});
      app.state.err = null;
      if (after) await after(r);
      return r;
    } catch (err) {
      app.state.err = (err && err.reason) || 'Something went wrong';
      return null;
    } finally { app.state.busy = false; }
  };

  const penalMap = (app) => {
    const m = {};
    (app.state.penal || []).forEach((p) => { m[p.code] = p; });
    return m;
  };
  const totals = (app, charges) => {
    const m = penalMap(app); let fine = 0, months = 0;
    (charges || []).forEach((c) => { const p = m[c.code]; if (p) { fine += p.fine * c.count; months += p.months * c.count; } });
    return { fine, months };
  };

  const loadTab = async (app, tab) => {
    const s = app.state;
    if (tab === 'home') await ask(app, 'dashboard', {}, (r) => { s.dash = r; });
    if (tab === 'calls' || tab === 'units') await ask(app, 'calls', {}, (r) => { s.calls = r.calls; s.units = r.units; });
    if (tab === 'reports') await ask(app, 'reports', { q: s.reportQ || '' }, (r) => { s.reports = r; });
    if (tab === 'warrants') await ask(app, 'warrants', {}, (r) => { s.warrants = r; });
    if (tab === 'bolos') await ask(app, 'bolos', {}, (r) => { s.bolos = r; });
    if (tab === 'prison' && s.me && s.me.perms.prison_staff) await ask(app, 'prisoners', {}, (r) => { s.prisoners = r; });
    if (!s.penal) await ask(app, 'penal', {}, (r) => { s.penal = r; });
  };

  const top = (app) => {
    const me = app.state.me || {};
    const seg = ['available', 'busy'].concat(me.status === 'enroute' || me.status === 'onscene' ? [me.status] : [])
      .map((k) => `<button class="${k} ${me.status === k ? 'on' : ''}" data-act="status" data-s="${k}">${STATUS[k]}</button>`).join('');
    return `<div class="top"><div class="brand">${I.badge}<span>MDT</span></div>
      <span class="tag">${e(app, me.short || '')}</span>
      <div class="who"><b>${e(app, me.callsign || '')} ${e(app, me.name || '')}</b><span>${e(app, me.rank || '')}</span></div>
      <div class="seg">${seg}</div></div>`;
  };

  const nav = (app, phone) => {
    const s = app.state;
    const btns = TABS.filter(([id]) => id !== 'prison' || (s.me && s.me.perms.prison_staff))
      .map(([id, label, icon]) => `<button class="${s.tab === id ? 'on' : ''}" data-act="tab" data-t="${id}">${I[icon]}<span>${label}</span></button>`).join('');
    return phone ? `<div class="tabs">${btns}</div>` : `<div class="rail">${btns}</div>`;
  };

  const callItem = (app, c) => {
    const mine = (c.responders || []).some((r) => app.state.me && r.callsign === app.state.me.callsign);
    const can = app.state.me && app.state.me.perms.dispatch;
    return `<div class="item static call ${c.priority === 'high' ? 'high' : ''}"><div class="grow">
      <div class="row"><span class="mono">${e(app, c.code)}</span><b>${e(app, c.title)}</b>${c.priority === 'high' ? '<span class="pill bad">Priority</span>' : ''}</div>
      ${(c.info || []).map((l) => `<div class="sub">${e(app, l)}</div>`).join('')}
      <div class="sub">${ago(c.createdAt)} · ${(c.responders || []).length}/${c.maxResponders} units ${(c.responders || []).map((r) => e(app, r.callsign)).join(', ')}</div></div>
      ${can ? `<div class="row">${mine ? `<button class="btn" data-act="detach" data-id="${c.id}">Detach</button>` : `<button class="btn primary" data-act="attach" data-id="${c.id}">Respond</button>`}
      <button class="btn danger" data-act="clearCall" data-id="${c.id}">Close</button></div>` : ''}</div>`;
  };

  const screens = {
    home(app) {
      const d = app.state.dash || {}; const calls = d.calls || [];
      return `<h2>Shift overview</h2>
        <div class="grid"><div class="stat"><b>${calls.length}</b><span>Open calls</span></div>
        <div class="stat"><b>${(d.units || []).length}</b><span>Units on duty</span></div>
        <div class="stat"><b>${d.warrants || 0}</b><span>Active warrants</span></div>
        <div class="stat"><b>${d.bolos || 0}</b><span>Active BOLOs</span></div></div>
        <h3>Latest calls</h3>${calls.length ? `<div class="list">${calls.slice(0, 4).map((c) => callItem(app, c)).join('')}</div>` : '<div class="empty">No open calls</div>'}
        <h3>Recent reports</h3>${(d.reports || []).length ? `<div class="list">${d.reports.map((r) => `<div class="item" data-act="openReport" data-id="${r.id}"><span class="mono">#${r.id}</span><div class="grow"><b>${e(app, r.title)}</b><div class="sub">${e(app, (r.dept || '').toUpperCase())} · ${when(r.createdAt)}</div></div><span class="pill ${r.status === 'open' ? 'accent' : ''}">${e(app, r.status)}</span></div>`).join('')}</div>` : '<div class="empty">No reports yet</div>'}`;
    },
    calls(app) {
      const calls = app.state.calls || [];
      return `<h2>Calls <span class="pill">${calls.length}</span></h2>${calls.length ? `<div class="list">${calls.map((c) => callItem(app, c)).join('')}</div>` : '<div class="empty">All quiet</div>'}`;
    },
    units(app) {
      const u = app.state.units || [];
      return `<h2>Units on duty <span class="pill">${u.length}</span></h2>${u.length ? `<div class="list">${u.map((x) => `<div class="item static"><span class="mono">${e(app, x.callsign)}</span><div class="grow"><b>${e(app, (x.dept || '').toUpperCase())}</b></div><span class="pill ${x.status === 'available' ? 'ok' : x.status === 'busy' ? 'warn' : 'accent'}">${STATUS[x.status] || x.status}</span></div>`).join('')}</div>` : '<div class="empty">Nobody on duty</div>'}`;
    },
    people(app) {
      const s = app.state;
      if (s.person) return screens.person(app);
      const list = s.peopleList || [];
      return `<h2>People</h2><div class="search"><input data-bind="peopleQ" data-enter="searchPeople" value="${e(app, s.peopleQ || '')}" placeholder="Name or citizen id"><button class="btn primary" data-act="searchPeople">${I.bolo}Search</button></div>
        ${list.length ? `<div class="list">${list.map((p) => `<div class="item" data-act="openPerson" data-id="${p.charId}"><span class="mono">${p.charId}</span><div class="grow"><b>${e(app, p.firstName)} ${e(app, p.lastName)}</b><div class="sub">Born ${e(app, String(p.dateOfBirth || '').slice(0, 10))} · ${e(app, p.gender)}</div></div>${p.warrant ? '<span class="pill bad">Warrant</span>' : ''}</div>`).join('')}</div>` : (s.peopleSearched ? '<div class="empty">Nobody found</div>' : '<div class="empty">Search by name or citizen id</div>')}`;
    },
    person(app) {
      const s = app.state; const p = s.person; const perms = (s.me && s.me.perms) || {};
      const active = (p.warrants || []).filter((w) => w.status === 'active');
      const unpaid = (p.fines || []).filter((f) => f.status === 'unpaid');
      const ch = s.charges || []; const t = totals(app, ch);
      const penal = (s.penal || []).filter((x) => !s.chargeQ || (x.title + ' ' + x.code).toLowerCase().includes(String(s.chargeQ).toLowerCase()));
      return `<button class="btn back" data-act="closePerson">${I.back}People</button>
        <h2>${e(app, p.firstName)} ${e(app, p.lastName)} <span class="mono tag">${p.charId}</span>${p.online ? '<span class="pill ok">Online</span>' : ''}${active.length ? '<span class="pill bad">Wanted</span>' : ''}${p.sentence ? '<span class="pill warn">In prison</span>' : ''}</h2>
        <div class="two"><div class="card"><dl class="kv"><dt>Born</dt><dd>${e(app, String(p.dateOfBirth || '').slice(0, 10))}</dd><dt>Gender</dt><dd>${e(app, p.gender)}</dd>
          <dt>Unpaid fines</dt><dd>${unpaid.length ? money(unpaid.reduce((a, f) => a + f.amount, 0)) + ' (' + unpaid.length + ')' : 'None'}</dd>
          <dt>Sentence</dt><dd>${p.sentence ? e(app, p.sentence.minutesLeft) + ' min left · ' + e(app, p.sentence.reason) : 'None'}</dd></dl></div>
        <div class="card"><h3 style="margin-top:0">Vehicles</h3>${(p.vehicles || []).length ? p.vehicles.map((v) => `<div class="row"><span class="mono">${e(app, v.plate)}</span><span>${e(app, v.model)}</span><span class="pill">${e(app, v.state)}</span></div>`).join('') : '<div class="sub">None registered</div>'}</div></div>
        <h3>Warrants</h3>${active.length ? `<div class="list">${active.map((w) => `<div class="item static"><div class="grow"><b>${e(app, w.reason)}</b><div class="sub">Until ${when(w.expiresAt)}</div></div>${perms.warrants ? `<button class="btn ok" data-act="closeWarrant" data-id="${w.id}" data-s="served">Served</button>` : ''}</div>`).join('')}</div>` : '<div class="sub">No active warrants</div>'}
        ${perms.warrants ? `<div class="search" style="margin-top:.5rem"><input data-bind="warrantReason" value="${e(app, s.warrantReason || '')}" placeholder="Reason for a warrant"><button class="btn" data-act="issueWarrant">${I.plus}Warrant</button></div>` : ''}
        <h3>Charges</h3><div class="card">
          <div class="search"><input data-bind="chargeQ" value="${e(app, s.chargeQ || '')}" placeholder="Filter the penal code"></div>
          <div class="list" style="max-height:14rem;overflow-y:auto">${penal.map((x) => `<div class="item" data-act="addCharge" data-code="${e(app, x.code)}"><span class="mono">${e(app, x.code)}</span><div class="grow">${e(app, x.title)}<div class="sub">${CAT[x.category] || ''} · ${money(x.fine)} · ${x.months} months</div></div>${I.plus}</div>`).join('')}</div>
          ${ch.length ? `<h3>Selected</h3><div class="list">${ch.map((c, i) => `<div class="item static"><span class="mono">${e(app, c.code)}</span><div class="grow">${e(app, (penalMap(app)[c.code] || {}).title)}</div><div class="cnt"><button class="btn" data-act="chargeCount" data-i="${i}" data-d="-1">${I.minus}</button><span class="mono">${c.count}</span><button class="btn" data-act="chargeCount" data-i="${i}" data-d="1">${I.plus}</button></div></div>`).join('')}</div>
          <div class="row" style="margin-top:.75rem;justify-content:space-between"><div class="total"><div><span>Fine</span>${money(t.fine)}</div><div><span>Prison</span>${t.months} months</div></div>
          <div class="row">${perms.fine && t.fine > 0 ? `<button class="btn primary" data-act="fine">Fine ${money(t.fine)}</button>` : ''}${perms.jail && t.months > 0 ? `<button class="btn danger" data-act="jail">Prison ${t.months} months</button>` : ''}</div></div>` : '<div class="sub" style="margin-top:.5rem">Tap charges to add them</div>'}
        </div>
        <h3>Reports</h3>${(p.reports || []).length ? `<div class="list">${p.reports.map((r) => `<div class="item" data-act="openReport" data-id="${r.id}"><span class="mono">#${r.id}</span><div class="grow"><b>${e(app, r.title)}</b><div class="sub">${when(r.createdAt)}</div></div></div>`).join('')}</div>` : '<div class="sub">None</div>'}
        <h3>Notes</h3>${(p.notes || []).map((n) => `<div class="item static"><div class="grow">${e(app, n.text)}<div class="sub">${e(app, n.author || '')} · ${when(n.createdAt)}</div></div></div>`).join('') || '<div class="sub">None</div>'}
        ${perms.records ? `<div class="search" style="margin-top:.5rem"><input data-bind="noteText" data-enter="addNote" value="${e(app, s.noteText || '')}" placeholder="Add a note"><button class="btn" data-act="addNote">${I.plus}Note</button></div>
        <div class="search"><input data-bind="boloReason" value="${e(app, s.boloReason || '')}" placeholder="Reason for a BOLO on this person"><button class="btn" data-act="boloPerson">${I.plus}BOLO</button></div>` : ''}`;
    },
    vehicles(app) {
      const s = app.state; const list = s.vehicleList || []; const perms = (s.me && s.me.perms) || {};
      return `<h2>Vehicles</h2><div class="search"><input data-bind="plateQ" data-enter="searchPlate" value="${e(app, s.plateQ || '')}" placeholder="Plate"><button class="btn primary" data-act="searchPlate">${I.bolo}Search</button></div>
        ${list.length ? `<div class="list">${list.map((v) => `<div class="item static"><span class="mono">${e(app, v.plate)}</span><div class="grow"><b>${e(app, v.model)}</b><div class="sub">Owner ${e(app, v.owner || ('#' + v.ownerCharId))} · ${e(app, v.state)}</div>${v.bolo ? `<div class="sub">BOLO: ${e(app, v.bolo.reason)}</div>` : ''}</div>${v.bolo ? '<span class="pill bad">BOLO</span>' : ''}<button class="btn" data-act="openPerson" data-id="${v.ownerCharId}">Owner</button></div>`).join('')}</div>` : (s.plateSearched ? '<div class="empty">No vehicle with that plate</div>' : '<div class="empty">Search by plate</div>')}
        ${perms.records ? `<h3>BOLO on a plate</h3><div class="search"><input data-bind="boloPlate" value="${e(app, s.boloPlate || '')}" placeholder="Plate"><input data-bind="boloPlateReason" value="${e(app, s.boloPlateReason || '')}" placeholder="Reason"><button class="btn" data-act="boloPlate">${I.plus}BOLO</button></div>` : ''}`;
    },
    reports(app) {
      const s = app.state;
      if (s.edit) return screens.editor(app);
      const list = s.reports || []; const perms = (s.me && s.me.perms) || {};
      return `<h2>Reports ${perms.records ? `<button class="btn primary" data-act="newReport">${I.plus}New report</button>` : ''}</h2>
        <div class="search"><input data-bind="reportQ" data-enter="searchReports" value="${e(app, s.reportQ || '')}" placeholder="Search titles"><button class="btn" data-act="searchReports">${I.bolo}Search</button></div>
        ${list.length ? `<div class="list">${list.map((r) => `<div class="item" data-act="openReport" data-id="${r.id}"><span class="mono">#${r.id}</span><div class="grow"><b>${e(app, r.title)}</b><div class="sub">${e(app, (r.dept || '').toUpperCase())} · ${when(r.createdAt)}</div></div><span class="pill ${r.status === 'open' ? 'accent' : ''}">${e(app, r.status)}</span></div>`).join('')}</div>` : '<div class="empty">No reports</div>'}`;
    },
    editor(app) {
      const s = app.state; const r = s.edit; const perms = (s.me && s.me.perms) || {};
      const t = totals(app, r.charges);
      return `<button class="btn back" data-act="closeReport">${I.back}Reports</button>
        <h2>${r.id ? 'Report #' + r.id : 'New report'} ${r.author ? `<span class="sub">by ${e(app, r.author)}</span>` : ''}</h2>
        <div class="card"><input data-bind="editTitle" value="${e(app, r.title || '')}" placeholder="Title" style="margin-bottom:.6rem">
        <textarea data-bind="editBody" placeholder="What happened">${e(app, r.body || '')}</textarea></div>
        <h3>People</h3><div class="list">${(r.people || []).map((p, i) => `<div class="item static"><span class="mono">${p.charId}</span><div class="grow">${e(app, p.name || '')}</div><span class="pill">${e(app, p.role)}</span><button class="btn" data-act="removePerson" data-i="${i}">${I.close}</button></div>`).join('') || '<div class="sub">Nobody added</div>'}</div>
        <div class="search" style="margin-top:.5rem"><input data-bind="addPersonId" value="${e(app, s.addPersonId || '')}" placeholder="Citizen id"><button class="btn" data-act="addPerson" data-role="suspect">Suspect</button><button class="btn" data-act="addPerson" data-role="victim">Victim</button><button class="btn" data-act="addPerson" data-role="witness">Witness</button></div>
        <h3>Charges</h3><div class="list">${(r.charges || []).map((c, i) => `<div class="item static"><span class="mono">${e(app, c.code)}</span><div class="grow">${e(app, (penalMap(app)[c.code] || {}).title)}<div class="sub">on ${e(app, c.charId)}</div></div><span class="mono">×${c.count}</span><button class="btn" data-act="removeReportCharge" data-i="${i}">${I.close}</button></div>`).join('') || '<div class="sub">No charges</div>'}</div>
        <div class="search" style="margin-top:.5rem"><input data-bind="addChargeCode" value="${e(app, s.addChargeCode || '')}" placeholder="Charge code, e.g. P105"><input data-bind="addChargeFor" value="${e(app, s.addChargeFor || '')}" placeholder="On citizen id"><button class="btn" data-act="addReportCharge">${I.plus}Add</button></div>
        <div class="row" style="margin-top:1rem;justify-content:space-between"><div class="total"><div><span>Fines</span>${money(t.fine)}</div><div><span>Prison</span>${t.months} months</div></div>
        <div class="row"><button class="btn ${r.status === 'closed' ? 'ok' : ''}" data-act="toggleClosed">${r.status === 'closed' ? 'Closed' : 'Open'}</button>${perms.records ? `<button class="btn primary" data-act="saveReport">Save</button>` : ''}</div></div>`;
    },
    warrants(app) {
      const list = app.state.warrants || []; const perms = (app.state.me && app.state.me.perms) || {};
      return `<h2>Active warrants <span class="pill">${list.length}</span></h2>${list.length ? `<div class="list">${list.map((w) => `<div class="item static"><span class="mono">${w.charId}</span><div class="grow"><b>${e(app, w.name || '')}</b><div class="sub">${e(app, w.reason)} · until ${when(w.expiresAt)}</div></div><button class="btn" data-act="openPerson" data-id="${w.charId}">Profile</button>${perms.warrants ? `<button class="btn ok" data-act="closeWarrant" data-id="${w.id}" data-s="served">Served</button><button class="btn danger" data-act="closeWarrant" data-id="${w.id}" data-s="cancelled">Cancel</button>` : ''}</div>`).join('')}</div>` : '<div class="empty">No active warrants</div>'}`;
    },
    bolos(app) {
      const list = app.state.bolos || []; const perms = (app.state.me && app.state.me.perms) || {};
      return `<h2>BOLOs <span class="pill">${list.length}</span></h2>${list.length ? `<div class="list">${list.map((b) => `<div class="item static"><span class="mono">${e(app, b.plate || b.charId)}</span><div class="grow"><b>${e(app, b.plate ? 'Vehicle ' + b.plate : (b.name || 'Person'))}</b><div class="sub">${e(app, b.reason)} · until ${when(b.expiresAt)}</div></div>${perms.records ? `<button class="btn" data-act="closeBolo" data-id="${b.id}">Close</button>` : ''}</div>`).join('')}</div>` : '<div class="empty">No BOLOs</div>'}`;
    },
    penal(app) {
      const s = app.state; const perms = (s.me && s.me.perms) || {};
      const groups = ['infraction', 'misdemeanor', 'felony'];
      return `<h2>Penal code</h2>${groups.map((g) => {
        const rows = (s.penal || []).filter((p) => p.category === g);
        return rows.length ? `<h3>${CAT[g]}</h3><div class="list">${rows.map((p) => `<div class="item static"><span class="mono">${e(app, p.code)}</span><div class="grow">${e(app, p.title)}</div><span class="mono">${money(p.fine)}</span><span class="mono">${p.months} mo</span>${perms.command ? `<button class="btn" data-act="removePenal" data-code="${e(app, p.code)}">${I.close}</button>` : ''}</div>`).join('')}</div>` : '';
      }).join('')}
      ${perms.command ? `<h3>Add or change a charge</h3><div class="card"><div class="two"><input data-bind="pCode" value="${e(app, s.pCode || '')}" placeholder="Code"><input data-bind="pTitle" value="${e(app, s.pTitle || '')}" placeholder="Title"></div>
        <div class="two" style="margin-top:.5rem"><input data-bind="pFine" value="${e(app, s.pFine || '')}" placeholder="Fine $"><input data-bind="pMonths" value="${e(app, s.pMonths || '')}" placeholder="Months"></div>
        <div class="row" style="margin-top:.6rem">${groups.map((g) => `<button class="btn ${s.pCat === g ? 'primary' : ''}" data-act="pCat" data-g="${g}">${CAT[g]}</button>`).join('')}<button class="btn primary" data-act="savePenal" style="margin-left:auto">Save</button></div></div>` : ''}`;
    },
    prison(app) {
      const list = app.state.prisoners || [];
      return `<h2>Prisoners <span class="pill">${list.length}</span></h2>${list.length ? `<div class="list">${list.map((p) => `<div class="item static"><span class="mono">${p.charId}</span><div class="grow"><b>${e(app, p.name || '')}</b><div class="sub">${e(app, p.reason)} · ${p.months} months · ${p.minutesLeft} min left</div></div>${p.online ? '<span class="pill ok">Inside</span>' : '<span class="pill">Away</span>'}${p.online ? `<button class="btn danger" data-act="release" data-id="${p.charId}">Release</button>` : ''}</div>`).join('')}</div>` : '<div class="empty">Nobody in prison</div>'}`;
    },
  };

  const reloadPerson = (app, id) => ask(app, 'person', { charId: id }, (r) => { app.state.person = r; });

  WhipPhone.module({
    id: 'pwpmdt', name: 'MDT', version: '0.1.0', order: 5, icon: I.badge, css,
    state: () => ({ tab: 'home', me: null, err: null, busy: false, charges: [], pCat: 'misdemeanor' }),
    async open(app) {
      await ask(app, 'me', {}, (r) => { app.state.me = r; });
      await loadTab(app, app.state.tab);
    },
    render(app, view) {
      const s = app.state; const phone = view.size === 'phone';
      if (!s.me) return `<div class="pm ${phone ? 'phone' : ''}"><div class="main">${s.err ? `<div class="err">${e(app, s.err)}</div>` : '<div class="empty">Connecting…</div>'}</div></div>`;
      const screen = (screens[s.tab] || screens.home)(app);
      return `<div class="pm ${phone ? 'phone' : ''}">${top(app)}${phone ? nav(app, true) : ''}<div class="body">${phone ? '' : nav(app, false)}<div class="main">${s.err ? `<div class="err"><span>${e(app, s.err)}</span><button data-act="dismissErr">${I.close}</button></div>` : ''}${screen}</div></div></div>`;
    },
    back(app) {
      const s = app.state;
      if (s.person) { s.person = null; s.charges = []; return true; }
      if (s.edit) { s.edit = null; return true; }
      if (s.tab !== 'home') { s.tab = 'home'; loadTab(app, 'home'); return true; }
      return false;
    },
    bind: {
      peopleQ: (app, v) => { app.state.peopleQ = v; }, plateQ: (app, v) => { app.state.plateQ = v; },
      reportQ: (app, v) => { app.state.reportQ = v; }, chargeQ: (app, v) => { app.state.chargeQ = v; },
      noteText: (app, v) => { app.state.noteText = v; }, warrantReason: (app, v) => { app.state.warrantReason = v; },
      boloReason: (app, v) => { app.state.boloReason = v; }, boloPlate: (app, v) => { app.state.boloPlate = v; },
      boloPlateReason: (app, v) => { app.state.boloPlateReason = v; },
      editTitle: (app, v) => { app.state.edit.title = v; }, editBody: (app, v) => { app.state.edit.body = v; },
      addPersonId: (app, v) => { app.state.addPersonId = v; }, addChargeCode: (app, v) => { app.state.addChargeCode = v; },
      addChargeFor: (app, v) => { app.state.addChargeFor = v; },
      pCode: (app, v) => { app.state.pCode = v; }, pTitle: (app, v) => { app.state.pTitle = v; },
      pFine: (app, v) => { app.state.pFine = v; }, pMonths: (app, v) => { app.state.pMonths = v; },
    },
    actions: {
      dismissErr(app) { app.state.err = null; },
      async tab(app, d) { app.state.tab = d.t; app.state.person = null; app.state.edit = null; await loadTab(app, d.t); },
      async status(app, d) { await ask(app, 'status', { status: d.s }, () => { app.state.me.status = d.s; }); },
      async attach(app, d) { await ask(app, 'attach', { id: Number(d.id) }, () => loadTab(app, app.state.tab)); },
      async detach(app, d) { await ask(app, 'detach', { id: Number(d.id) }, () => loadTab(app, app.state.tab)); },
      async clearCall(app, d) { await ask(app, 'clearCall', { id: Number(d.id) }, () => loadTab(app, app.state.tab)); },
      async searchPeople(app) { await ask(app, 'people', { q: app.state.peopleQ || '' }, (r) => { app.state.peopleList = r; app.state.peopleSearched = true; }); },
      async openPerson(app, d) { app.state.tab = 'people'; app.state.charges = []; await reloadPerson(app, Number(d.id)); },
      closePerson(app) { app.state.person = null; app.state.charges = []; },
      addCharge(app, d) {
        const ch = app.state.charges; const hit = ch.find((c) => c.code === d.code);
        if (hit) hit.count = Math.min(20, hit.count + 1); else ch.push({ code: d.code, count: 1 });
      },
      chargeCount(app, d) {
        const ch = app.state.charges; const c = ch[Number(d.i)]; if (!c) return;
        c.count += Number(d.d); if (c.count < 1) ch.splice(Number(d.i), 1); if (c.count > 20) c.count = 20;
      },
      async fine(app) {
        const p = app.state.person;
        await ask(app, 'fine', { charId: p.charId, charges: app.state.charges }, async (r) => { app.toast('Fined ' + money(r.amount)); app.state.charges = []; await reloadPerson(app, p.charId); });
      },
      async jail(app) {
        const p = app.state.person;
        await ask(app, 'jail', { charId: p.charId, charges: app.state.charges, reason: app.state.charges.map((c) => c.code).join(', ') }, async (r) => { app.toast('Sent to prison: ' + r.months + ' months'); app.state.charges = []; await reloadPerson(app, p.charId); });
      },
      async issueWarrant(app) {
        const p = app.state.person;
        await ask(app, 'issueWarrant', { charId: p.charId, reason: app.state.warrantReason || '' }, async () => { app.state.warrantReason = ''; await reloadPerson(app, p.charId); });
      },
      async closeWarrant(app, d) {
        await ask(app, 'closeWarrant', { id: Number(d.id), status: d.s }, async () => {
          if (app.state.person) await reloadPerson(app, app.state.person.charId); else await loadTab(app, 'warrants');
        });
      },
      async addNote(app) {
        const p = app.state.person;
        await ask(app, 'addNote', { charId: p.charId, text: app.state.noteText || '' }, async () => { app.state.noteText = ''; await reloadPerson(app, p.charId); });
      },
      async boloPerson(app) {
        const p = app.state.person;
        await ask(app, 'addBolo', { charId: p.charId, reason: app.state.boloReason || '' }, () => { app.state.boloReason = ''; app.toast('BOLO out'); });
      },
      async searchPlate(app) { await ask(app, 'vehicles', { q: app.state.plateQ || '' }, (r) => { app.state.vehicleList = r; app.state.plateSearched = true; }); },
      async boloPlate(app) {
        await ask(app, 'addBolo', { plate: app.state.boloPlate || '', reason: app.state.boloPlateReason || '' }, () => { app.state.boloPlate = ''; app.state.boloPlateReason = ''; app.toast('BOLO out'); });
      },
      async closeBolo(app, d) { await ask(app, 'closeBolo', { id: Number(d.id) }, () => loadTab(app, 'bolos')); },
      async searchReports(app) { await loadTab(app, 'reports'); },
      newReport(app) { app.state.edit = { title: '', body: '', status: 'open', people: [], charges: [] }; },
      async openReport(app, d) { app.state.tab = 'reports'; app.state.person = null; await ask(app, 'report', { id: Number(d.id) }, (r) => { app.state.edit = r; }); },
      closeReport(app) { app.state.edit = null; },
      addPerson(app, d) {
        const id = Number(app.state.addPersonId); if (!id) { app.state.err = 'Type a citizen id'; return; }
        app.state.edit.people.push({ charId: id, role: d.role }); app.state.addPersonId = '';
      },
      removePerson(app, d) { app.state.edit.people.splice(Number(d.i), 1); },
      addReportCharge(app) {
        const s = app.state; const code = String(s.addChargeCode || '').trim().toUpperCase(); const who = Number(s.addChargeFor);
        if (!penalMap(app)[code]) { s.err = 'No charge with that code'; return; }
        if (!who) { s.err = 'Say whose charge it is (citizen id)'; return; }
        const hit = s.edit.charges.find((c) => c.code === code && Number(c.charId) === who);
        if (hit) hit.count += 1; else s.edit.charges.push({ code, charId: who, count: 1 });
        s.addChargeCode = '';
      },
      removeReportCharge(app, d) { app.state.edit.charges.splice(Number(d.i), 1); },
      toggleClosed(app) { app.state.edit.status = app.state.edit.status === 'closed' ? 'open' : 'closed'; },
      async saveReport(app) {
        const r = app.state.edit;
        await ask(app, 'saveReport', { id: r.id, rev: r.rev, title: r.title, body: r.body, status: r.status, people: r.people, charges: r.charges },
          (res) => { r.id = res.id; r.rev = res.rev; app.toast('Saved'); });
      },
      pCat(app, d) { app.state.pCat = d.g; },
      async savePenal(app) {
        const s = app.state;
        await ask(app, 'savePenal', { code: String(s.pCode || '').trim().toUpperCase(), title: s.pTitle, category: s.pCat, fine: Number(s.pFine), months: Number(s.pMonths) },
          async () => { s.pCode = s.pTitle = s.pFine = s.pMonths = ''; s.penal = null; await loadTab(app, 'penal'); });
      },
      async removePenal(app, d) { await ask(app, 'removePenal', { code: d.code }, async () => { app.state.penal = null; await loadTab(app, 'penal'); }); },
      async release(app, d) { await ask(app, 'release', { charId: Number(d.id) }, () => loadTab(app, 'prison')); },
    },
    on: {
      alert(app, a) {
        const s = app.state; s.calls = [a].concat((s.calls || []).filter((c) => c.id !== a.id));
        if (s.dash) s.dash.calls = [a].concat((s.dash.calls || []).filter((c) => c.id !== a.id));
      },
      alertCleared(app, d) {
        const s = app.state; s.calls = (s.calls || []).filter((c) => c.id !== d.id);
        if (s.dash) s.dash.calls = (s.dash.calls || []).filter((c) => c.id !== d.id);
      },
    },
    badge(app) { return (app.state.calls || []).length || 0; },
  });
})();
