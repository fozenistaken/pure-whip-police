(() => {
  const SELF = document.currentScript && document.currentScript.src;

  const CSS = `
.mdt{position:absolute;inset:0;background:var(--bg);display:grid;padding:var(--safe-top,0) 0 var(--safe-bottom,0)}
.mdt.tab{grid-template-columns:5.25rem minmax(0,1fr) 16.875rem;grid-template-rows:3.875rem minmax(0,1fr)}
.mdt.ph{grid-template-columns:minmax(0,1fr);grid-template-rows:auto minmax(0,1fr) auto}

.mdt-top{grid-column:1/-1;display:flex;align-items:center;gap:.875rem;padding:0 1rem;border-bottom:1px solid var(--line);min-width:0}
.mdt.ph .mdt-top{flex-wrap:wrap;gap:.5rem .75rem;padding:.375rem 1rem .75rem}
.mdt-cs{font-family:var(--mono);font-weight:600;font-size:1rem;letter-spacing:.04em}
.mdt-who{display:grid;line-height:1.2;min-width:0}
.mdt-who b{font-size:.875rem;font-weight:700}
.mdt-who span{font-size:.75rem;color:var(--mute)}
.mdt.ph .mdt-who{flex:1}
.mdt-top .pwp-search{flex:1;min-width:12rem}
.mdt.ph .mdt-top .pwp-search{flex-basis:100%;order:3}
.mdt-status button[data-s=available]{--dot:var(--ok)}
.mdt-status button[data-s=busy]{--dot:var(--warn)}
.mdt-status button[data-s=enroute],.mdt-status button[data-s=onscene]{--dot:var(--route)}

.mdt-nav{position:relative;display:flex;flex-direction:column;gap:.25rem;padding:.625rem .5rem;border-right:1px solid var(--line)}
.mdt-nav>button{position:relative;z-index:1;display:grid;justify-items:center;gap:.25rem;padding:.625rem 0;border-radius:var(--r);color:var(--mute);font-size:.6875rem;font-weight:600;transition:color .15s,transform .16s var(--out)}
.mdt-nav>button:hover:not(.on){color:var(--text)}
.mdt-nav>button:active{transform:scale(.97)}
.mdt-nav>button.on{color:var(--on-sel)}
.mdt-nav svg{width:1.375rem;height:1.375rem}
.mdt-nav>.pwp-glider{border-radius:var(--r)}
.mdt.ph .mdt-nav{flex-direction:row;justify-content:space-around;border-right:0;border-top:1px solid var(--line);padding:.375rem .5rem}
.mdt.ph .mdt-nav>button{flex:1;padding:.4375rem 0}
.mdt-nav .n{position:absolute;top:.25rem;right:calc(50% - 1.375rem);min-width:1.125rem;height:1.125rem;padding:0 .25rem;border-radius:1rem;background:var(--danger);color:#fff;font-family:var(--mono);font-size:.625rem;display:grid;place-items:center}

.mdt-main{position:relative;min-width:0;min-height:0;display:flex;flex-direction:column}
.mdt-view{flex:1;min-height:0;display:flex;flex-direction:column;gap:.875rem;padding:1.125rem 1.25rem 0}
.mdt.ph .mdt-view{padding:.875rem 1rem 0;gap:.75rem}
.mdt-scroll{flex:1;min-height:0;overflow-y:auto;display:grid;align-content:start;gap:.75rem;padding-bottom:1rem;margin-right:-.5rem;padding-right:.5rem}
.mdt-h{display:flex;align-items:center;gap:.75rem;flex-wrap:wrap}
.mdt-h h1{margin:0;flex:1;min-width:0;font-size:1.5rem;font-weight:800;letter-spacing:-.025em;line-height:1.1;text-wrap:balance}
.mdt.ph .mdt-h h1{font-size:1.25rem}

.mdt-rec{display:flex;align-items:flex-start;gap:.875rem}
.mdt-ava{width:3.5rem;height:3.5rem;flex:none;border-radius:var(--r);background:var(--panel2);display:grid;place-items:center;font-weight:700;font-size:1.1875rem}
.mdt.ph .mdt-ava{width:2.75rem;height:2.75rem;font-size:1rem}
.mdt-name{flex:1;min-width:0}
.mdt-name h1{margin:0;font-size:1.875rem;line-height:1.05;font-weight:800;letter-spacing:-.025em;text-wrap:balance;overflow-wrap:anywhere}
.mdt.ph .mdt-name h1{font-size:1.375rem}
.mdt-name p{margin:.375rem 0 0;font-size:.75rem;color:var(--mute)}
.mdt-flags{display:flex;gap:.375rem;flex-wrap:wrap;margin-top:.5625rem}

.mdt-tabs{position:relative;display:flex;gap:.125rem;border-bottom:1px solid var(--line);overflow-x:auto;scrollbar-width:none}
.mdt-tabs::-webkit-scrollbar{height:0}
.mdt-tabs>button{position:relative;z-index:1;flex:none;padding:.625rem .75rem;font-size:.8125rem;font-weight:600;color:var(--mute);transition:color .15s}
.mdt-tabs>button:hover{color:var(--text)}
.mdt-tabs>button.on{color:var(--text)}
.mdt-tabs>.pwp-glider{top:auto;bottom:0;height:.125rem!important;border-radius:.125rem;background:var(--accent)}

.mdt-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(15rem,1fr));gap:.75rem}
.mdt-big{font-size:1.375rem}
.mdt-kv{display:grid;grid-template-columns:auto 1fr;gap:.375rem 1rem;font-size:.8125rem;margin:0}
.mdt-kv dt{color:var(--mute)}
.mdt-kv dd{margin:0;font-weight:600;overflow-wrap:anywhere}

.mdt-act{display:flex;align-items:center;justify-content:flex-end;gap:.5rem;flex-wrap:wrap;padding:.75rem 1.25rem;border-top:1px solid var(--line);background:var(--bg)}
.mdt.ph .mdt-act{padding:.625rem 1rem}
.mdt-act .grow{flex:1}
.mdt.ph .mdt-act{flex-wrap:nowrap}
.mdt.ph .mdt-act .pwp-btn.mdt-side-act{width:2.75rem;min-height:2.75rem;padding:0;flex:none}
.mdt.ph .mdt-act .pwp-btn.mdt-side-act svg{width:1.125rem;height:1.125rem;color:var(--text)}
.mdt.ph .mdt-act .mdt-at{display:none}
.mdt.ph .mdt-act .pwp-cta{flex:1}
.mdt.ph .pwp-cta .pwp-kbd{display:none}
.mdt.ph .pwp-cta.has-kbd{padding-right:1.125rem}

.mdt-side{border-left:1px solid var(--line);background:var(--panel);display:flex;flex-direction:column;min-height:0}
.mdt-side .pwp-lbl{margin:0;padding:.875rem .75rem .625rem}
.mdt-calls{flex:1;min-height:0;overflow-y:auto;display:grid;align-content:start;gap:.625rem;padding:0 .75rem .875rem}
.mdt-call{border-radius:var(--r);padding:.6875rem .75rem;background:var(--bg);display:grid;gap:.1875rem}
.mdt.ph .mdt-call{background:var(--panel)}
.mdt-call .c{font-family:var(--mono);font-weight:600;font-size:.75rem;color:var(--warn)}
.mdt-call.hi .c{color:var(--danger)}
.mdt-call b{font-size:.9375rem;line-height:1.2;overflow-wrap:anywhere}
.mdt-call span{font-size:.75rem;color:var(--mute);overflow-wrap:anywhere}
.mdt-call .acts{display:flex;gap:.375rem;margin-top:.375rem}
.mdt-call .acts .pwp-btn{flex:1}
.mdt-call .acts .pwp-btn.ghost{flex:none}
.mdt-call .acts .pwp-btn.icon{flex:none;width:2rem}
.mdt-call.on{box-shadow:inset 0 0 0 1px var(--accent)}
.mdt-call .pick{display:grid;gap:.1875rem;border-radius:.25rem}
.mdt-mapwrap{position:relative;flex:1;min-height:0;margin-bottom:1rem}
.mdt.ph .mdt-mapwrap{margin:0 -1rem;border-radius:0}
.mdt.ph .mdt-mapwrap .mm{border-radius:0}
.mdt-map-slot{position:absolute;inset:0}
.mdt-mapcard{position:absolute;left:.75rem;right:.75rem;bottom:.75rem;z-index:4}
.mdt-mapcard .mdt-call{background:var(--panel);box-shadow:inset 0 0 0 1px var(--line)}

.mdt-pick{border-radius:var(--r);background:var(--bg);padding:.25rem .625rem}
.mdt-pick .pwp-row{padding:.5rem 0}
.mdt-cat{font-size:.625rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--faint)}
.mdt-cat.felony{color:var(--danger)}
.mdt-table{width:100%;border-collapse:collapse;font-size:.8125rem}
.mdt-table th{text-align:left;font-size:.6875rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint);padding:.375rem .5rem;border-bottom:1px solid var(--line)}
.mdt-table td{padding:.5rem;border-bottom:1px solid var(--line);vertical-align:middle;overflow-wrap:anywhere}
.mdt-table .r{text-align:right;white-space:nowrap}
.mdt-wait{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:.75rem;height:100%;color:var(--mute);font-size:.9375rem;font-weight:600;padding:2rem;text-align:center}
.mdt-wait svg{width:2.25rem;height:2.25rem;color:var(--faint)}
.mdt>.pwp-busy{z-index:3}
`;

  const STATUS = { available: 'Available', busy: 'Busy', enroute: 'En route', onscene: 'On scene' };
  const CAT = { infraction: 'Infraction', misdemeanor: 'Misdemeanor', felony: 'Felony' };
  const NAV = [['dispatch', 'Dispatch', 'dispatch'], ['records', 'Records', 'records'], ['reports', 'Reports', 'report'], ['wanted', 'Wanted', 'wanted'], ['command', 'Command', 'command']];
  const RTABS = [['overview', 'Overview'], ['history', 'History'], ['vehicles', 'Vehicles'], ['notes', 'Notes']];
  const SHEET_TITLE = { note: 'Add a note', bolo: 'Look out for', warrant: 'Issue a warrant', plate: 'Look out for a plate', penal: 'Add or change a charge' };

  let B = null;
  const live = new WeakMap();
  const ms = (v) => (typeof v === 'number' ? (v < 1e12 ? v * 1000 : v) : Date.parse(v));
  const when = (v) => {
    const t = ms(v);
    if (!t) return v == null ? '' : String(v);
    const d = new Date(t);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) + ' ' + d.toTimeString().slice(0, 5);
  };
  const ago = (sec) => {
    const s = Math.max(0, Math.floor(Date.now() / 1000 - sec));
    return s < 60 ? 'now' : s < 3600 ? Math.floor(s / 60) + ' min' : Math.floor(s / 3600) + ' h';
  };
  const day = (v) => String(v || '').slice(0, 10);
  const initials = (p) => ((p.firstName || ' ')[0] + (p.lastName || ' ')[0]).toUpperCase();
  const perms = (app) => (app.state.me && app.state.me.perms) || {};
  const val = (app, k) => B.esc(app.state.f[k] || '');
  const penalMap = (app) => Object.fromEntries((app.state.penal || []).map((p) => [p.code, p]));
  const totalsOf = (app, list) => {
    const m = penalMap(app);
    let fine = 0, months = 0;
    for (const c of list) { const p = m[c.code]; if (p) { fine += p.fine * c.count; months += p.months * c.count; } }
    return { fine, months };
  };
  const chargeList = (app) => Object.entries(app.state.charges).filter(([, n]) => n > 0).map(([code, count]) => ({ code, count }));
  const navFor = (app) => NAV.filter(([id]) => id !== 'command' || perms(app).command || perms(app).prison_staff);

  const showBusy = (app) => {
    const ctx = live.get(app);
    const bar = ctx && ctx.el.querySelector('.mdt-main > .pwp-busy');
    if (bar) bar.classList.toggle('on', !!app.state.busyShown);
  };

  const ask = async (app, action, args, after, quiet) => {
    const s = app.state;
    let timer = 0;
    if (!quiet) {
      s.busy += 1;
      timer = setTimeout(() => { s.busyShown = true; showBusy(app); }, 300);
    }
    try {
      const r = await app.request(action, args || {});
      if (!quiet) s.err = null;
      if (after) await after(r);
      return r;
    } catch (e) {
      s.err = (e && e.reason) || 'Something went wrong';
      return null;
    } finally {
      if (!quiet) {
        clearTimeout(timer);
        s.busy -= 1;
        if (s.busy <= 0) { s.busy = 0; s.busyShown = false; }
        showBusy(app);
        draw(app);
      }
    }
  };

  const shown = (s) => JSON.stringify([s.nav, s.penal && s.penal.length, s.calls, s.units, s.recent, s.reports, s.warrants, s.bolos, s.prisoners, s.err]);

  const load = async (app) => {
    const s = app.state;
    const before = shown(s);
    const jobs = [];
    if (!s.penal) jobs.push(ask(app, 'penal', {}, (r) => { s.penal = r; }, true));
    if (s.nav === 'dispatch') jobs.push(ask(app, 'dashboard', {}, (r) => { s.calls = r.calls; s.units = r.units; s.recent = r.reports; }, true));
    else jobs.push(ask(app, 'calls', {}, (r) => { s.calls = r.calls; s.units = r.units; }, true));
    if (s.nav === 'reports' && !s.edit) jobs.push(ask(app, 'reports', { q: '' }, (r) => { s.reports = r; }, true));
    if (s.nav === 'wanted') {
      jobs.push(ask(app, 'warrants', {}, (r) => { s.warrants = r; }, true));
      jobs.push(ask(app, 'bolos', {}, (r) => { s.bolos = r; }, true));
    }
    if (s.nav === 'command' && perms(app).prison_staff) jobs.push(ask(app, 'prisoners', {}, (r) => { s.prisoners = r; }, true));
    await Promise.all(jobs);
    if (shown(s) !== before) draw(app);
  };

  const statusSeg = (app) => {
    const st = (app.state.me || {}).status || 'available';
    const list = ['available', 'busy'];
    if (st === 'enroute' || st === 'onscene') list.push(st);
    return `<div class="pwp-seg mdt-status" data-glide="status">${list.map((k) => `<button class="${st === k ? 'on' : ''}" data-act="status" data-s="${k}" aria-pressed="${st === k}"><i></i>${STATUS[k]}</button>`).join('')}</div>`;
  };

  const callCard = (app, c) => {
    const me = app.state.me || {};
    const mine = (c.responders || []).some((r) => r.callsign === me.callsign);
    const n = (c.responders || []).length;
    const hi = c.priority === 'high';
    const p = perms(app);
    const who = n ? ': ' + c.responders.map((r) => B.esc(r.callsign)).join(', ') : '';
    const picked = app.state.pick === c.id;
    return `<article class="mdt-call ${hi ? 'hi pwp-bracket danger' : mine ? 'pwp-bracket' : ''} ${picked ? 'on' : ''}" data-call="${c.id}">
      <button class="pick" data-act="pickCall" data-id="${c.id}" aria-pressed="${picked}"><span class="c">${B.esc(c.code)} · ${ago(c.createdAt)}</span><b>${B.esc(c.title)}</b>
      ${(c.info || []).map((l) => `<span>${B.esc(l)}</span>`).join('')}
      <span>${n} of ${c.maxResponders} units${who}</span></button>
      <div class="acts">${p.dispatch ? (mine ? `<button class="pwp-btn sm pwp-press" data-act="detach" data-id="${c.id}">Leave</button>` : `<button class="pwp-btn sm inv pwp-press" data-act="attach" data-id="${c.id}">Respond</button>`) : ''}<button class="pwp-btn sm ghost icon pwp-press" data-act="waypoint" data-id="${c.id}" aria-label="Set a waypoint">${B.icons.pin}</button>${p.dispatch ? `<button class="pwp-btn sm ghost pwp-press" data-act="clearCall" data-id="${c.id}">Close</button>` : ''}</div>
    </article>`;
  };
  const callList = (app) => {
    const calls = app.state.calls || [];
    return calls.length ? calls.map((c) => callCard(app, c)).join('') : '<div class="pwp-empty">All quiet. New calls land here.</div>';
  };

  const unitRows = (app) => {
    const u = app.state.units || [];
    const me = (app.state.me || {}).callsign;
    if (!u.length) return '<div class="pwp-empty">Nobody is on duty</div>';
    return u.map((x) => `<div class="pwp-row"><span class="pwp-code" style="color:var(--text)">${B.esc(x.callsign)}</span><span class="t">${B.esc((x.dept || '').toUpperCase())}${x.callsign === me ? '<span class="s">You</span>' : ''}</span><span class="pwp-flag ${x.status === 'available' ? 'ok' : x.status === 'busy' ? 'warn' : 'route'}">${STATUS[x.status] || B.esc(x.status)}</span></div>`).join('');
  };

  const reportRow = (r) => `<button class="pwp-row" data-act="openReport" data-id="${r.id}"><span class="pwp-code">#${r.id}</span><span class="t">${B.esc(r.title)}<span class="s">${B.esc((r.dept || '').toUpperCase())} · ${when(r.createdAt)}</span></span>${r.status === 'closed' ? '<span class="pwp-flag">Closed</span>' : ''}</button>`;

  const head = (title, back, extra) => `<div class="mdt-h">${back ? `<button class="pwp-btn ghost pwp-press" data-act="${back}">${B.icons.back}Back</button>` : ''}<h1>${B.esc(title)}</h1>${extra || ''}</div>`;
  const hasMap = () => !!window.PWPLiveMap;
  const onMap = (s) => s.nav === 'dispatch' && s.dview === 'map' && hasMap();
  const scroll = (inner, key) => `<div class="mdt-scroll" data-scroll="${key}">${inner}</div>`;

  const screens = {
    dispatch(app, phone) {
      const s = app.state;
      const recent = s.recent || [];
      const seg = hasMap() ? `<div class="pwp-seg" data-glide="dview">${[['map', 'Map', 'map'], ['board', 'Board', 'list']].map(([v, label, ic]) => `<button class="${s.dview === v ? 'on' : ''}" data-act="dview" data-v="${v}" aria-pressed="${s.dview === v}">${B.icons[ic]}${label}</button>`).join('')}</div>` : '';
      if (onMap(s)) {
        const c = phone && s.pick != null ? (s.calls || []).find((x) => x.id === s.pick) : null;
        return { body: head('Dispatch', null, seg) + `<div class="mdt-mapwrap"><div class="mdt-map-slot"></div>${c ? `<div class="mdt-mapcard pwp-fade">${callCard(app, c)}</div>` : ''}</div>` };
      }
      const calls = phone ? `<section class="pwp-card"><p class="pwp-lbl">Live calls</p><div style="display:grid;gap:.625rem">${callList(app)}</div></section>` : '';
      return { body: head('Dispatch', null, seg) + scroll(`${calls}
        <section class="pwp-card"><p class="pwp-lbl">Units on duty</p>${unitRows(app)}</section>
        <section class="pwp-card"><p class="pwp-lbl">Latest reports</p>${recent.length ? recent.map(reportRow).join('') : '<div class="pwp-empty">No reports yet</div>'}</section>`, 'dispatch') };
    },

    records(app) {
      const s = app.state;
      if (s.person) return screens.person(app);
      const r = s.results;
      if (!r) return { body: head('Records') + scroll('<div class="pwp-empty">Search a name, citizen ID, plate or report number above.</div>', 'records') };
      const people = r.people.length ? r.people.map((p) => `<button class="pwp-row" data-act="openPerson" data-id="${p.charId}"><span class="pwp-code">${p.charId}</span><span class="t">${B.esc(p.firstName)} ${B.esc(p.lastName)}<span class="s">Born ${B.esc(day(p.dateOfBirth))} · ${B.esc(p.gender)}</span></span>${p.warrant ? '<span class="pwp-flag danger">Wanted</span>' : ''}</button>`).join('') : '';
      const cars = r.vehicles.length ? r.vehicles.map((v) => `<div class="pwp-row"><span class="pwp-plate">${B.esc(v.plate)}</span><span class="t">${B.esc(v.model)}<span class="s">${v.bolo ? 'BOLO: ' + B.esc(v.bolo.reason) : B.esc(v.owner || 'Owner #' + v.ownerCharId) + ' · ' + B.esc(v.state)}</span></span><span class="acts">${!v.bolo && perms(app).records ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="plate" data-plate="${B.esc(v.plate)}">BOLO</button>` : ''}<button class="pwp-btn sm pwp-press" data-act="openPerson" data-id="${v.ownerCharId}">Owner</button></span></div>`).join('') : '';
      const reps = r.reports.length ? r.reports.map(reportRow).join('') : '';
      const none = !people && !cars && !reps;
      return { body: head(`Results for “${s.lastQ}”`) + scroll(none ? '<div class="pwp-empty">Nothing matches that search.</div>' : `
        ${people ? `<section class="pwp-card"><p class="pwp-lbl">People</p>${people}</section>` : ''}
        ${cars ? `<section class="pwp-card"><p class="pwp-lbl">Vehicles</p>${cars}</section>` : ''}
        ${reps ? `<section class="pwp-card"><p class="pwp-lbl">Reports</p>${reps}</section>` : ''}`, 'results') };
    },

    person(app) {
      const s = app.state; const p = s.person; const pm = perms(app);
      const active = (p.warrants || []).filter((w) => w.status === 'active');
      const unpaid = (p.fines || []).filter((f) => f.status === 'unpaid');
      const flags = [active.length ? '<span class="pwp-flag danger">Wanted</span>' : '', p.sentence ? '<span class="pwp-flag route">In prison</span>' : '', p.online ? '<span class="pwp-flag">In town</span>' : ''].join('');
      const tab = {
        overview: () => `<div class="mdt-grid">
            <section class="pwp-card"><p class="pwp-lbl">Warrants</p>${active.length ? active.map((w) => `<div class="pwp-row"><span class="t">${B.esc(w.reason)}<span class="s">Valid until ${when(w.expiresAt)}</span></span>${pm.warrants ? `<button class="pwp-btn sm pwp-press" data-act="closeWarrant" data-id="${w.id}" data-s="served">Served</button>` : ''}</div>`).join('') : '<div class="pwp-empty">None active</div>'}</section>
            <section class="pwp-card"><p class="pwp-lbl">Unpaid fines</p>${unpaid.length ? `<div class="pwp-row"><span class="t">${unpaid.length === 1 ? '1 citation' : unpaid.length + ' citations'}</span><span class="mdt-big num">${B.money(unpaid.reduce((a, f) => a + f.amount, 0))}</span></div>` : '<div class="pwp-empty">None</div>'}</section>
            ${p.sentence ? `<section class="pwp-card"><p class="pwp-lbl">Sentence</p><div class="pwp-row"><span class="t">${B.esc(p.sentence.reason || 'Serving time')}</span><span class="mdt-big num">${B.esc(p.sentence.minutesLeft)} min</span></div></section>` : ''}
          </div>`,
        history: () => `<section class="pwp-card"><p class="pwp-lbl">Reports</p>${(p.reports || []).length ? p.reports.map((r) => `<button class="pwp-row" data-act="openReport" data-id="${r.id}"><span class="pwp-code">#${r.id}</span><span class="t">${B.esc(r.title)}<span class="s">${when(r.createdAt)}</span></span></button>`).join('') : '<div class="pwp-empty">Not named in any report</div>'}</section>
          <section class="pwp-card"><p class="pwp-lbl">Fines</p>${(p.fines || []).length ? p.fines.map((f) => `<div class="pwp-row"><span class="t">${B.esc(f.reason || 'Fine')}<span class="s">${when(f.createdAt)}</span></span><span class="num">${B.money(f.amount)}</span><span class="pwp-flag ${f.status === 'unpaid' ? 'warn' : ''}">${B.esc(f.status)}</span></div>`).join('') : '<div class="pwp-empty">No fines</div>'}</section>`,
        vehicles: () => `<section class="pwp-card"><p class="pwp-lbl">Registered vehicles</p>${(p.vehicles || []).length ? p.vehicles.map((v) => `<div class="pwp-row"><span class="pwp-plate">${B.esc(v.plate)}</span><span class="t">${B.esc(v.model)}<span class="s">${B.esc(v.state)}</span></span>${pm.records ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="plate" data-plate="${B.esc(v.plate)}">BOLO</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No registered vehicles</div>'}</section>`,
        notes: () => `<section class="pwp-card"><p class="pwp-lbl">Notes</p>${(p.notes || []).length ? p.notes.map((n) => `<div class="pwp-row"><span class="t">${B.esc(n.text)}<span class="s">${B.esc(n.author || '')} · ${when(n.createdAt)}</span></span></div>`).join('') : '<div class="pwp-empty">No notes</div>'}</section>`,
      };
      const canCharge = pm.fine || pm.jail;
      const acts = [
        pm.records ? `<button class="pwp-btn mdt-side-act pwp-press" data-act="openSheet" data-k="note" aria-label="Note">${B.icons.note}<span class="mdt-at">Note</span></button>` : '',
        pm.records ? `<button class="pwp-btn mdt-side-act pwp-press" data-act="openSheet" data-k="bolo" aria-label="BOLO">${B.icons.wanted}<span class="mdt-at">BOLO</span></button>` : '',
        pm.warrants ? `<button class="pwp-btn mdt-side-act pwp-press" data-act="openSheet" data-k="warrant" aria-label="Warrant">${B.icons.command}<span class="mdt-at">Warrant</span></button>` : '',
        canCharge ? `<button class="pwp-cta has-kbd pwp-press" data-act="openSheet" data-k="charge">${B.icons.gavel}Charge<span class="pwp-kbd">C</span></button>` : '',
      ].join('');
      return {
        body: `<div class="mdt-rec"><div class="mdt-ava">${B.esc(initials(p))}</div><div class="mdt-name"><h1>${B.esc(p.firstName)} ${B.esc(p.lastName)}</h1><p class="mono">ID ${p.charId} · born ${B.esc(day(p.dateOfBirth))} · ${B.esc(p.gender)}</p>${flags ? `<div class="mdt-flags">${flags}</div>` : ''}</div>
          <button class="pwp-btn ghost icon pwp-press" data-act="closePerson" aria-label="Close record">${B.icons.x}</button></div>
          <div class="mdt-tabs" role="tablist" data-glide="rtab">${RTABS.map(([id, label]) => `<button class="${s.rtab === id ? 'on' : ''}" role="tab" aria-selected="${s.rtab === id}" data-act="rtab" data-t="${id}">${label}</button>`).join('')}</div>
          ${scroll(`<div class="${s.fadeTab ? 'pwp-fade' : ''}" style="display:grid;gap:.75rem">${tab[s.rtab]()}</div>`, 'person-' + s.rtab)}`,
        act: acts,
      };
    },

    reports(app) {
      const s = app.state;
      if (s.edit) return screens.report(app);
      const list = s.reports || [];
      return {
        body: head('Reports') + scroll(`<section class="pwp-card">${list.length ? list.map(reportRow).join('') : '<div class="pwp-empty">No reports yet</div>'}</section>`, 'reports'),
        act: perms(app).records ? `<button class="pwp-cta pwp-press" data-act="newReport">${B.icons.plus}New report</button>` : '',
      };
    },

    report(app) {
      const s = app.state; const r = s.edit; const pm = perms(app); const pmap = penalMap(app);
      const t = totalsOf(app, r.charges || []);
      const edit = pm.records;
      return {
        body: head(r.id ? 'Report #' + r.id : 'New report', 'closeReport') + scroll(`
          <section class="pwp-card" style="display:grid;gap:.625rem">
            <input id="f-editTitle" class="pwp-in" data-bind="editTitle" value="${B.esc(r.title || '')}" placeholder="Title: what happened, where" ${edit ? '' : 'readonly'}>
            <textarea id="f-editBody" class="pwp-in" data-bind="editBody" placeholder="Who, what, when, where, and what you did" ${edit ? '' : 'readonly'}>${B.esc(r.body || '')}</textarea>
            ${r.author ? `<span class="pwp-code" style="color:var(--faint)">Written by ${B.esc(r.author)}</span>` : ''}
          </section>
          <section class="pwp-card"><p class="pwp-lbl">People</p>
            ${(r.people || []).length ? r.people.map((p, i) => `<div class="pwp-row"><span class="pwp-code">${p.charId}</span><span class="t">${B.esc(p.name || 'Citizen ' + p.charId)}<span class="s">${B.esc(p.role)}</span></span>${edit ? `<button class="pwp-btn ghost icon pwp-press" data-act="removePerson" data-i="${i}" aria-label="Remove">${B.icons.x}</button>` : ''}</div>`).join('') : '<div class="pwp-empty">Nobody added</div>'}
            ${edit ? `<div class="pwp-row"><input id="f-addPersonId" class="pwp-in" style="max-width:8rem" data-bind="addPersonId" value="${val(app, 'addPersonId')}" placeholder="Citizen ID" inputmode="numeric">
              <span class="acts">${['suspect', 'victim', 'witness'].map((role) => `<button class="pwp-btn sm pwp-press" data-act="addPerson" data-role="${role}">${B.icons.plus}${role[0].toUpperCase() + role.slice(1)}</button>`).join('')}</span></div>` : ''}
          </section>
          <section class="pwp-card"><p class="pwp-lbl">Charges</p>
            ${(r.charges || []).length ? r.charges.map((c, i) => `<div class="pwp-row"><span class="pwp-code">${B.esc(c.code)}</span><span class="t">${B.esc((pmap[c.code] || {}).title || '')}<span class="s">Citizen ${B.esc(c.charId)}${c.count > 1 ? ' · ×' + c.count : ''}</span></span>${edit ? `<button class="pwp-btn ghost icon pwp-press" data-act="removeReportCharge" data-i="${i}" aria-label="Remove">${B.icons.x}</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No charges</div>'}
            ${edit ? `<div class="pwp-row"><input id="f-addChargeCode" class="pwp-in mono" style="max-width:8rem" data-bind="addChargeCode" value="${val(app, 'addChargeCode')}" placeholder="Code"><input id="f-addChargeFor" class="pwp-in" style="max-width:8rem" data-bind="addChargeFor" value="${val(app, 'addChargeFor')}" placeholder="Citizen ID" inputmode="numeric"><span class="acts"><button class="pwp-btn sm pwp-press" data-act="addReportCharge">${B.icons.plus}Add</button></span></div>` : ''}
            ${(r.charges || []).length ? `<div class="pwp-tot"><div><small>Fines</small><b class="num">${B.money(t.fine)}</b></div><div><small>Prison</small><b class="num">${t.months} mo</b></div></div>` : ''}
          </section>`, 'report'),
        act: edit ? `<div class="pwp-seg" data-glide="rstatus">${['open', 'closed'].map((v) => `<button class="${(r.status || 'open') === v ? 'on' : ''}" data-act="setStatus" data-v="${v}">${v === 'open' ? 'Open' : 'Closed'}</button>`).join('')}</div><span class="grow"></span><button class="pwp-cta pwp-press" data-act="saveReport">Save report</button>` : '',
      };
    },

    wanted(app) {
      const s = app.state; const pm = perms(app);
      const w = s.warrants || []; const b = s.bolos || [];
      return { body: head('Wanted') + scroll(`
        <section class="pwp-card"><p class="pwp-lbl">Warrants</p>${w.length ? w.map((x) => `<div class="pwp-row"><span class="pwp-code">${x.charId}</span><button class="t" style="text-align:left" data-act="openPerson" data-id="${x.charId}">${B.esc(x.name || 'Citizen ' + x.charId)}<span class="s">${B.esc(x.reason)} · until ${when(x.expiresAt)}</span></button>${pm.warrants ? `<span class="acts"><button class="pwp-btn sm pwp-press" data-act="closeWarrant" data-id="${x.id}" data-s="served">Served</button><button class="pwp-btn sm ghost pwp-press" data-act="closeWarrant" data-id="${x.id}" data-s="cancelled">Cancel</button></span>` : ''}</div>`).join('') : '<div class="pwp-empty">No active warrants</div>'}</section>
        <section class="pwp-card"><p class="pwp-lbl">Be on the lookout</p>${b.length ? b.map((x) => `<div class="pwp-row">${x.plate ? `<span class="pwp-plate">${B.esc(x.plate)}</span>` : `<span class="pwp-code">${B.esc(x.charId)}</span>`}<span class="t">${B.esc(x.plate ? 'Vehicle' : (x.name || 'Person'))}<span class="s">${B.esc(x.reason)} · until ${when(x.expiresAt)}</span></span>${pm.records ? `<button class="pwp-btn sm ghost pwp-press" data-act="closeBolo" data-id="${x.id}">Close</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No lookouts out</div>'}</section>`, 'wanted') };
    },

    command(app) {
      const s = app.state; const pm = perms(app);
      const penal = ['infraction', 'misdemeanor', 'felony'].map((g) => {
        const rows = (s.penal || []).filter((p) => p.category === g);
        if (!rows.length) return '';
        return `<section class="pwp-card"><p class="pwp-lbl">${CAT[g]}</p><table class="mdt-table"><tbody>${rows.map((p) => `<tr><td class="pwp-code">${B.esc(p.code)}</td><td>${B.esc(p.title)}</td><td class="r num">${B.money(p.fine)}</td><td class="r num">${p.months} mo</td>${pm.command ? `<td class="r"><button class="pwp-btn ghost icon pwp-press" data-act="editPenal" data-code="${B.esc(p.code)}" aria-label="Change ${B.esc(p.code)}">${B.icons.note}</button><button class="pwp-btn ghost icon pwp-press" data-act="removePenal" data-code="${B.esc(p.code)}" aria-label="Remove ${B.esc(p.code)}">${B.icons.x}</button></td>` : ''}</tr>`).join('')}</tbody></table></section>`;
      }).join('');
      const pr = s.prisoners || [];
      const prison = pm.prison_staff ? `<section class="pwp-card"><p class="pwp-lbl">Prisoners</p>${pr.length ? pr.map((p) => `<div class="pwp-row"><span class="pwp-code">${p.charId}</span><span class="t">${B.esc(p.name || '')}<span class="s">${B.esc(p.reason)} · ${p.minutesLeft} min left</span></span>${p.online ? `<button class="pwp-btn sm danger pwp-press" data-act="release" data-id="${p.charId}">Release</button>` : '<span class="pwp-flag">Away</span>'}</div>`).join('') : '<div class="pwp-empty">Nobody is serving time</div>'}</section>` : '';
      return {
        body: head('Command') + scroll(prison + (pm.command ? penal : ''), 'command'),
        act: pm.command ? `<button class="pwp-cta pwp-press" data-act="openSheet" data-k="penal">${B.icons.plus}Add charge</button>` : '',
      };
    },
  };

  const errBar = (app) => (app.state.err ? `<div class="pwp-err" role="alert">${B.icons.alert}<span>${B.esc(app.state.err)}</span><button class="pwp-btn ghost icon" data-act="dismissErr" aria-label="Dismiss">${B.icons.x}</button></div>` : '');

  const sheet = (app, phone) => {
    const s = app.state; const k = s.sheet && s.sheet.kind;
    if (!k) return '';
    const pm = perms(app);
    let title, body, foot;
    if (k === 'charge') {
      const q = String(s.f.chargeQ || '').toLowerCase();
      const list = (s.penal || []).filter((x) => !q || (x.title + ' ' + x.code).toLowerCase().includes(q));
      const t = totalsOf(app, chargeList(app));
      const both = pm.fine && pm.jail;
      const jail = pm.jail && (!pm.fine || s.outcome === 'jail');
      title = 'Charge ' + s.person.firstName + ' ' + s.person.lastName;
      body = `<label class="pwp-search">${B.icons.search}<input id="f-chargeQ" data-bind="chargeQ" value="${val(app, 'chargeQ')}" placeholder="Find a charge" autocomplete="off"></label>
        <div class="mdt-pick">${list.map((x) => `<div class="pwp-row"><span class="pwp-code">${B.esc(x.code)}</span><span class="t">${B.esc(x.title)}<span class="s"><span class="mdt-cat ${x.category}">${CAT[x.category] || ''}</span> · ${B.money(x.fine)} · ${x.months} mo</span></span><span class="pwp-step"><button data-act="count" data-c="${B.esc(x.code)}" data-d="-1" aria-label="One less">${B.icons.minus}</button><span class="num">${s.charges[x.code] || 0}</span><button data-act="count" data-c="${B.esc(x.code)}" data-d="1" aria-label="One more">${B.icons.plus}</button></span></div>`).join('') || '<div class="pwp-empty">No charge matches</div>'}</div>`;
      foot = `<div class="pwp-tot"><div><small>Fine</small><b class="num">${B.money(t.fine)}</b></div><div><small>Prison</small><b class="num">${t.months} mo</b></div></div>
        ${both ? `<div class="pwp-seg" data-glide="outcome" style="justify-self:start"><button class="${!jail ? 'on' : ''}" data-act="outcome" data-v="fine">Citation</button><button class="${jail ? 'on' : ''}" data-act="outcome" data-v="jail">Arrest</button></div>` : ''}
        <button class="pwp-cta wide pwp-press" data-act="${jail ? 'jail' : 'fine'}" ${(jail ? t.months : t.fine) > 0 ? '' : 'disabled'}>${jail ? 'Send to prison' : 'Write citation'}</button>`;
    } else if (k === 'note') {
      title = SHEET_TITLE.note;
      body = `<textarea id="f-noteText" class="pwp-in" data-bind="noteText" placeholder="What other officers should know about ${B.esc(s.person.firstName)}">${val(app, 'noteText')}</textarea>`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="addNote">Save note</button>`;
    } else if (k === 'bolo' || k === 'warrant') {
      title = SHEET_TITLE[k] + ': ' + s.person.firstName + ' ' + s.person.lastName;
      body = `<input id="f-reason" class="pwp-in" data-bind="reason" data-enter="${k === 'bolo' ? 'boloPerson' : 'issueWarrant'}" value="${val(app, 'reason')}" placeholder="${k === 'bolo' ? 'Why officers should stop them' : 'Reason for the warrant'}">`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="${k === 'bolo' ? 'boloPerson' : 'issueWarrant'}">${k === 'bolo' ? 'Issue BOLO' : 'Issue warrant'}</button>`;
    } else if (k === 'plate') {
      title = SHEET_TITLE.plate;
      body = `<input id="f-plate" class="pwp-in mono" data-bind="plate" value="${val(app, 'plate')}" placeholder="Plate">
        <input id="f-reason" class="pwp-in" data-bind="reason" data-enter="boloPlate" value="${val(app, 'reason')}" placeholder="Why officers should stop it">`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="boloPlate">Issue BOLO</button>`;
    } else if (k === 'penal') {
      title = SHEET_TITLE.penal;
      body = `<div class="pwp-two"><input id="f-pCode" class="pwp-in mono" data-bind="pCode" value="${val(app, 'pCode')}" placeholder="Code, e.g. P110"><input id="f-pTitle" class="pwp-in" data-bind="pTitle" value="${val(app, 'pTitle')}" placeholder="Charge"></div>
        <div class="pwp-two"><input id="f-pFine" class="pwp-in" data-bind="pFine" value="${val(app, 'pFine')}" placeholder="Fine in $" inputmode="numeric"><input id="f-pMonths" class="pwp-in" data-bind="pMonths" value="${val(app, 'pMonths')}" placeholder="Prison months" inputmode="numeric"></div>
        <div class="pwp-seg" data-glide="pcat" style="justify-self:start">${['infraction', 'misdemeanor', 'felony'].map((g) => `<button class="${s.f.pCat === g ? 'on' : ''}" data-act="pCat" data-g="${g}">${CAT[g]}</button>`).join('')}</div>`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="savePenal">Save charge</button>`;
    }
    return `<div class="pwp-scrim on" data-act="closeSheet"></div>
      <aside class="pwp-sheet ${phone ? 'pwp-from-below' : 'pwp-from-right'} on" aria-label="${B.esc(title)}">
        <h2>${B.esc(title)}<button class="pwp-btn icon pwp-press" data-act="closeSheet" aria-label="Close">${B.icons.x}</button></h2>
        ${s.err ? errBar(app) : ''}
        <div class="body">${body}</div><div class="foot">${foot}</div>
      </aside>`;
  };

  const render = (app, phone) => {
    const s = app.state;
    if (!s.me) return `<div class="pwp mdt ${phone ? 'ph' : 'tab'}"><div class="pwp-busy ${s.err ? '' : 'on'}"></div><div class="mdt-wait" style="grid-column:1/-1;grid-row:1/-1">${s.err ? B.icons.alert : B.icons.badge}<span>${B.esc(s.err || 'Connecting to dispatch')}</span></div></div>`;
    const me = s.me;
    const view = (screens[s.nav] || screens.dispatch)(app, phone);
    const callCount = (s.calls || []).length;
    const nav = `<nav class="mdt-nav" data-glide="nav" aria-label="Sections">${navFor(app).map(([id, label, icon]) => `<button class="${s.nav === id ? 'on' : ''}" data-act="nav" data-t="${id}" aria-current="${s.nav === id ? 'page' : 'false'}">${B.icons[icon]}${label}${phone && id === 'dispatch' && s.nav !== 'dispatch' && callCount ? `<span class="n">${callCount}</span>` : ''}</button>`).join('')}</nav>`;
    const top = `<header class="mdt-top"><span class="mdt-cs">${B.esc(me.callsign || '')}</span><div class="mdt-who"><b>${B.esc(me.name || '')}</b><span>${B.esc([me.rank, me.short].filter(Boolean).join(' · '))}</span></div>
      ${statusSeg(app)}
      <label class="pwp-search">${B.icons.search}<input id="f-q" data-bind="q" data-enter="search" value="${val(app, 'q')}" placeholder="Search name, citizen ID, plate or report #" autocomplete="off">${phone ? '' : '<span class="pwp-kbd">/</span>'}</label></header>`;
    const main = `<main class="mdt-main"><div class="pwp-busy ${s.busyShown ? 'on' : ''}"></div><div class="mdt-view">${s.sheet ? '' : errBar(app)}${view.body}</div>${view.act ? `<div class="mdt-act">${view.act}</div>` : ''}${sheet(app, phone)}</main>`;
    if (phone) return `<div class="pwp mdt ph">${top}${main}${nav}</div>`;
    return `<div class="pwp mdt tab">${top}${nav}${main}<aside class="mdt-side"><p class="pwp-lbl">Live calls</p><div class="mdt-calls">${callList(app)}</div></aside></div>`;
  };

  const POLL_MS = 2000;
  const mapControls = () => `<button class="pwp-btn pwp-press" data-act="mapZoom" data-d="1" aria-label="Zoom in">${B.icons.plus}</button><button class="pwp-btn pwp-press" data-act="mapZoom" data-d="-1" aria-label="Zoom out">${B.icons.minus}</button><button class="pwp-btn pwp-press" data-act="mapMe" aria-label="Centre on me">${B.icons.locate}</button><button class="pwp-btn pwp-press mm-3d" data-act="mapTilt" aria-label="3D view">3D</button>`;
  const mapOf = (app) => {
    const ctx = live.get(app);
    if (!ctx || !hasMap() || !B) return null;
    if (!ctx.map) {
      ctx.map = new window.PWPLiveMap.LiveMap({
        controls: mapControls(),
        onTap: () => { if (app.state.pick != null) run(app, 'unpick'); },
        onWaypoint: (x, y) => ask(app, 'waypoint', { x, y }, () => app.toast('Waypoint set'), true),
      });
    }
    return ctx.map;
  };
  const pollMap = (app) => ask(app, 'map', {}, (r) => {
    const s = app.state; const map = mapOf(app);
    if (!r || !map) return;
    const before = JSON.stringify(s.calls);
    s.calls = r.calls;
    map.setUnits(r.units);
    if (JSON.stringify(s.calls) !== before) draw(app);
  }, true);
  const stopPoll = (ctx) => { if (ctx && ctx.poll) { clearInterval(ctx.poll); ctx.poll = 0; } };
  const startPoll = (app, ctx) => {
    if (ctx.poll) return;
    ctx.poll = setInterval(() => { if (ctx.el.isConnected && ctx.el.offsetParent) pollMap(app); }, POLL_MS);
    pollMap(app);
  };
  const syncMap = (app, ctx, root) => {
    const map = mapOf(app);
    if (!map) return;
    const slot = root.querySelector('.mdt-map-slot');
    if (slot) { map.attach(slot); map.setCalls(app.state.calls, app.state.pick); startPoll(app, ctx); }
    else { map.detach(); stopPoll(ctx); }
  };

  const draw = (app) => {
    const ctx = live.get(app);
    if (!ctx || !B) return;
    const { el, view } = ctx;
    const root = el.querySelector('.mdt-root');
    if (!root) return;
    const doc = el.ownerDocument;
    const active = doc.activeElement;
    const keep = active && el.contains(active) && active.id ? { id: active.id, a: active.selectionStart, b: active.selectionEnd } : null;
    const scrolls = {};
    root.querySelectorAll('[data-scroll]').forEach((n) => { scrolls[n.dataset.scroll] = n.scrollTop; });
    const sheetWas = !!root.querySelector('.pwp-sheet');
    root.innerHTML = render(app, view && view.size === 'phone');
    root.querySelectorAll('[data-scroll]').forEach((n) => { if (scrolls[n.dataset.scroll]) n.scrollTop = scrolls[n.dataset.scroll]; });
    root.querySelectorAll('[data-glide]').forEach((g) => B.glide(g, ctx.mem, g.dataset.glide));
    syncMap(app, ctx, root);
    if (app.state.scrollCall != null) {
      const card = root.querySelector(`.mdt-side [data-call="${app.state.scrollCall}"]`);
      if (card) card.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      app.state.scrollCall = null;
    }
    const sh = root.querySelector('.pwp-sheet');
    if (sh && !sheetWas) {
      B.settle(sh, sh.classList.contains('pwp-from-below') ? 'y' : 'x', 102);
      const scrim = root.querySelector('.pwp-scrim');
      if (scrim && scrim.animate) scrim.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 240, easing: 'cubic-bezier(.23,1,.32,1)' });
    }
    app.state.fadeTab = false;
    if (keep) {
      const n = root.querySelector('#' + keep.id);
      if (n) { n.focus(); try { n.setSelectionRange(keep.a, keep.b); } catch (e) { /* not a text field */ } }
    }
  };

  const closeSheet = (app) => {
    const ctx = live.get(app);
    const root = ctx && ctx.el.querySelector('.mdt-root');
    const sh = root && root.querySelector('.pwp-sheet');
    const done = () => { app.state.sheet = null; app.state.err = null; draw(app); };
    if (!sh || !sh.animate) return done();
    const out = sh.classList.contains('pwp-from-below') ? 'translateY(102%)' : 'translateX(102%)';
    const scrim = root.querySelector('.pwp-scrim');
    if (scrim) scrim.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 160, fill: 'forwards' });
    sh.animate([{ transform: 'none' }, { transform: out }], { duration: 160, easing: 'cubic-bezier(.23,1,.32,1)', fill: 'forwards' }).onfinish = done;
  };

  const shownFirst = async (app, action, args, status) => {
    const me = app.state.me;
    const before = me.status;
    me.status = status;
    draw(app);
    const r = await ask(app, action, args, null, true);
    if (r === null) { me.status = before; draw(app); return; }
    if (action !== 'status') await load(app);
  };

  const reloadPerson = (app, id) => ask(app, 'person', { charId: id }, (r) => { app.state.person = r; });

  const actions = {
    dismissErr(app) { app.state.err = null; },
    async nav(app, d) {
      const s = app.state;
      s.nav = d.t; s.err = null; s.sheet = null;
      if (d.t !== 'records') { s.person = null; }
      if (d.t !== 'reports') s.edit = null;
      await load(app);
    },
    async status(app, d) { await shownFirst(app, 'status', { status: d.s }, d.s); },
    async attach(app, d) { await shownFirst(app, 'attach', { id: Number(d.id) }, 'enroute'); },
    async detach(app, d) { await shownFirst(app, 'detach', { id: Number(d.id) }, 'available'); },
    async clearCall(app, d) { await ask(app, 'clearCall', { id: Number(d.id) }, () => { if (app.state.pick === Number(d.id)) app.state.pick = null; return load(app); }); },
    dview(app, d) { app.state.dview = d.v; if (d.v !== 'map') app.state.pick = null; },
    async pickCall(app, d) {
      const s = app.state; const id = Number(d.id);
      const c = (s.calls || []).find((x) => x.id === id);
      if (!c) return;
      s.pick = id; s.scrollCall = id;
      if (!hasMap()) return;
      const moved = s.nav !== 'dispatch';
      s.nav = 'dispatch'; s.dview = 'map'; s.person = null; s.edit = null; s.sheet = null; s.err = null;
      const map = mapOf(app);
      const ctx = live.get(app);
      const phone = ctx && ctx.view && ctx.view.size === 'phone';
      if (map && c.coords) map.slideTo(c.coords.x, c.coords.y, undefined, 420, phone ? map.host.clientHeight * 0.25 : 0);
      if (moved) await load(app);
    },
    unpick(app) { app.state.pick = null; },
    mapZoom(app, d) { const map = mapOf(app); if (map) map.zoomBy(Number(d.d)); return 'skip'; },
    mapMe(app) { const map = mapOf(app); if (map) map.centreOnMe(); return 'skip'; },
    mapTilt(app) { const map = mapOf(app); if (map) map.toggleTilt(); return 'skip'; },
    async waypoint(app, d) {
      const c = (app.state.calls || []).find((x) => x.id === Number(d.id));
      await ask(app, 'waypoint', { id: Number(d.id) }, () => {
        const map = mapOf(app);
        if (map && c && c.coords) map.setWaypoint({ x: c.coords.x, y: c.coords.y });
        app.toast('Waypoint set');
      });
    },
    async search(app) {
      const s = app.state; const q = String(s.f.q || '').trim();
      if (!q) return;
      s.nav = 'records'; s.person = null; s.edit = null; s.sheet = null; s.lastQ = q;
      const rep = /^#\s*(\d+)$/.exec(q);
      if (rep) { await actions.openReport(app, { id: rep[1] }); return; }
      const out = { people: [], vehicles: [], reports: [] };
      await ask(app, 'people', { q }, (r) => { out.people = r || []; });
      if (q.length <= 8) await ask(app, 'vehicles', { q }, (r) => { out.vehicles = r || []; });
      await ask(app, 'reports', { q }, (r) => { out.reports = r || []; });
      s.results = out;
      if (out.people.length === 1 && !out.vehicles.length && !out.reports.length) await actions.openPerson(app, { id: out.people[0].charId });
    },
    async openPerson(app, d) {
      const s = app.state;
      s.nav = 'records'; s.edit = null; s.charges = {}; s.rtab = 'overview'; s.sheet = null;
      await reloadPerson(app, Number(d.id));
    },
    closePerson(app) { app.state.person = null; app.state.charges = {}; },
    rtab(app, d) { app.state.rtab = d.t; app.state.fadeTab = true; },
    openSheet(app, d) {
      const s = app.state;
      if (d.k === 'charge' && !(perms(app).fine || perms(app).jail)) return;
      s.err = null;
      s.sheet = { kind: d.k };
      if (d.k === 'plate') s.f.plate = d.plate || '';
      if (d.k === 'bolo' || d.k === 'warrant' || d.k === 'plate') s.f.reason = '';
      if (d.k === 'penal' && !d.keep) { s.f.pCode = s.f.pTitle = s.f.pFine = s.f.pMonths = ''; s.f.pCat = 'misdemeanor'; }
    },
    closeSheet(app) { closeSheet(app); return 'skip'; },
    count(app, d) { const c = app.state.charges; c[d.c] = Math.max(0, Math.min(20, (c[d.c] || 0) + Number(d.d))); },
    outcome(app, d) { app.state.outcome = d.v; },
    async fine(app) {
      const p = app.state.person;
      await ask(app, 'fine', { charId: p.charId, charges: chargeList(app) }, async (r) => { app.toast('Fined ' + B.money(r.amount)); app.state.charges = {}; app.state.sheet = null; await reloadPerson(app, p.charId); });
    },
    async jail(app) {
      const p = app.state.person; const list = chargeList(app);
      await ask(app, 'jail', { charId: p.charId, charges: list, reason: list.map((c) => c.code).join(', ') }, async (r) => { app.toast('Sent to prison for ' + r.months + ' months'); app.state.charges = {}; app.state.sheet = null; await reloadPerson(app, p.charId); });
    },
    async addNote(app) {
      const p = app.state.person;
      await ask(app, 'addNote', { charId: p.charId, text: app.state.f.noteText || '' }, async () => { app.state.f.noteText = ''; app.state.sheet = null; app.state.rtab = 'notes'; await reloadPerson(app, p.charId); });
    },
    async boloPerson(app) {
      const p = app.state.person;
      await ask(app, 'addBolo', { charId: p.charId, reason: app.state.f.reason || '' }, () => { app.state.sheet = null; app.toast('Lookout issued'); });
    },
    async issueWarrant(app) {
      const p = app.state.person;
      await ask(app, 'issueWarrant', { charId: p.charId, reason: app.state.f.reason || '' }, async () => { app.state.sheet = null; app.toast('Warrant issued'); await reloadPerson(app, p.charId); });
    },
    async boloPlate(app) {
      await ask(app, 'addBolo', { plate: app.state.f.plate || '', reason: app.state.f.reason || '' }, () => { app.state.sheet = null; app.toast('Lookout issued'); });
    },
    async closeWarrant(app, d) {
      await ask(app, 'closeWarrant', { id: Number(d.id), status: d.s }, async () => { if (app.state.person) await reloadPerson(app, app.state.person.charId); else await load(app); });
    },
    async closeBolo(app, d) { await ask(app, 'closeBolo', { id: Number(d.id) }, () => load(app)); },
    newReport(app) { app.state.edit = { title: '', body: '', status: 'open', people: [], charges: [] }; },
    async openReport(app, d) {
      const s = app.state;
      await ask(app, 'report', { id: Number(d.id) }, (r) => { s.nav = 'reports'; s.edit = r; s.person = null; s.sheet = null; });
    },
    async closeReport(app) { app.state.edit = null; await load(app); },
    addPerson(app, d) {
      const s = app.state; const id = Number(s.f.addPersonId);
      if (!id) { s.err = 'Type the citizen ID first'; return; }
      s.edit.people.push({ charId: id, role: d.role }); s.f.addPersonId = '';
    },
    removePerson(app, d) { app.state.edit.people.splice(Number(d.i), 1); },
    addReportCharge(app) {
      const s = app.state; const code = String(s.f.addChargeCode || '').trim().toUpperCase(); const who = Number(s.f.addChargeFor);
      if (!penalMap(app)[code]) { s.err = 'No charge has that code. Command lists them all.'; return; }
      if (!who) { s.err = 'Add the citizen ID of the person charged'; return; }
      const hit = s.edit.charges.find((c) => c.code === code && Number(c.charId) === who);
      if (hit) hit.count += 1; else s.edit.charges.push({ code, charId: who, count: 1 });
      s.f.addChargeCode = ''; s.err = null;
    },
    removeReportCharge(app, d) { app.state.edit.charges.splice(Number(d.i), 1); },
    setStatus(app, d) { app.state.edit.status = d.v; },
    async saveReport(app) {
      const r = app.state.edit;
      await ask(app, 'saveReport', { id: r.id, rev: r.rev, title: r.title, body: r.body, status: r.status, people: r.people, charges: r.charges },
        (res) => { r.id = res.id; r.rev = res.rev; app.toast('Report saved'); });
    },
    pCat(app, d) { app.state.f.pCat = d.g; },
    editPenal(app, d) {
      const p = penalMap(app)[d.code]; const f = app.state.f;
      if (!p) return;
      f.pCode = p.code; f.pTitle = p.title; f.pFine = String(p.fine); f.pMonths = String(p.months); f.pCat = p.category;
      actions.openSheet(app, { k: 'penal', keep: true });
    },
    async savePenal(app) {
      const f = app.state.f;
      await ask(app, 'savePenal', { code: String(f.pCode || '').trim().toUpperCase(), title: f.pTitle, category: f.pCat, fine: Number(f.pFine), months: Number(f.pMonths) },
        async () => { app.state.sheet = null; app.state.penal = null; await load(app); app.toast('Charge saved'); });
    },
    async removePenal(app, d) { await ask(app, 'removePenal', { code: d.code }, async () => { app.state.penal = null; await load(app); }); },
    async release(app, d) { await ask(app, 'release', { charId: Number(d.id) }, () => load(app)); },
  };

  const BIND = { editTitle: (s, v) => { s.edit.title = v; }, editBody: (s, v) => { s.edit.body = v; } };
  const LIVE = { chargeQ: true };

  const run = (app, name, data) => {
    const fn = actions[name];
    if (!fn) return;
    const r = fn(app, data);
    if (r === 'skip') return;
    draw(app);
    if (r && typeof r.then === 'function') r.then(() => draw(app));
  };

  const wire = (app, el) => {
    el.addEventListener('click', (e) => {
      const t = e.target.closest('[data-act]');
      if (!t || !el.contains(t) || t.disabled) return;
      run(app, t.dataset.act, { ...t.dataset });
    });
    el.addEventListener('input', (e) => {
      const t = e.target; const k = t.dataset && t.dataset.bind;
      if (!k) return;
      if (BIND[k]) BIND[k](app.state, t.value); else app.state.f[k] = t.value;
      if (LIVE[k]) draw(app);
    });
    el.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter' || e.shiftKey) return;
      const act = e.target.dataset && e.target.dataset.enter;
      if (!act) return;
      e.preventDefault();
      run(app, act, { ...e.target.dataset });
    });
    const doc = el.ownerDocument;
    const onKey = (e) => {
      if (!el.isConnected || !el.offsetParent || e.ctrlKey || e.altKey || e.metaKey) return;
      const tag = (e.target && e.target.tagName) || '';
      if (tag === 'INPUT' || tag === 'TEXTAREA') return;
      const s = app.state;
      if (e.key === '/') { const q = el.querySelector('#f-q'); if (q) { e.preventDefault(); q.focus(); q.select(); } }
      else if ((e.key === '+' || e.key === '=' || e.key === '-') && onMap(s) && !s.sheet) { e.preventDefault(); run(app, 'mapZoom', { d: e.key === '-' ? -1 : 1 }); }
      else if ((e.key === 'c' || e.key === 'C') && s.person && !s.sheet && s.nav === 'records') { e.preventDefault(); run(app, 'openSheet', { k: 'charge' }); }
    };
    doc.addEventListener('keydown', onKey);
    return () => doc.removeEventListener('keydown', onKey);
  };

  const DEF = {
    id: 'pwpmdt', name: 'MDT', version: '0.3.0', order: 5, statusBar: 'light',
    icon: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 2.5l7.5 3v5.7c0 4.6-3.2 8.5-7.5 10.3-4.3-1.8-7.5-5.7-7.5-10.3V5.5z"/><path d="M12 8.2l1.3 2.6 2.9.4-2.1 2 .5 2.9-2.6-1.4-2.6 1.4.5-2.9-2.1-2 2.9-.4z"/></svg>',
    state: () => ({ nav: 'dispatch', dview: 'map', pick: null, me: null, err: null, busy: 0, charges: {}, rtab: 'overview', outcome: 'fine', sheet: null, f: { pCat: 'misdemeanor' } }),
    mount(app, el, view) {
      el.innerHTML = '<div class="mdt-root"></div>';
      const ctx = { el, view, mem: {} };
      live.set(app, ctx);
      ctx.off = wire(app, el);
      draw(app);
    },
    update(app, el, view) {
      const ctx = live.get(app);
      if (!ctx) return;
      if (ctx.el !== el || (view && ctx.view && ctx.view.size !== view.size)) { ctx.el = el; ctx.view = view; ctx.mem = {}; draw(app); }
    },
    unmount(app) {
      const ctx = live.get(app);
      if (ctx) { if (ctx.off) ctx.off(); stopPoll(ctx); if (ctx.map) ctx.map.detach(); }
      live.delete(app);
    },
    async open(app) {
      await ask(app, 'me', {}, (r) => { app.state.me = r; });
      if (app.state.me) await load(app);
    },
    back(app) {
      const s = app.state;
      if (s.sheet) { closeSheet(app); return true; }
      if (s.pick != null) { s.pick = null; draw(app); return true; }
      if (s.edit) { s.edit = null; load(app); draw(app); return true; }
      if (s.person) { s.person = null; draw(app); return true; }
      if (s.nav !== 'dispatch') { s.nav = 'dispatch'; load(app); draw(app); return true; }
      return false;
    },
    on: {
      alert(app, a) { const s = app.state; s.calls = [a].concat((s.calls || []).filter((c) => c.id !== a.id)); draw(app); },
      alertCleared(app, d) { const s = app.state; s.calls = (s.calls || []).filter((c) => c.id !== d.id); if (s.pick === d.id) s.pick = null; draw(app); },
    },
    badge(app) { return (app.state.calls || []).length || 0; },
  };

  WhipPhone.module(DEF);

  const need = (name, path) => new Promise((resolve) => {
    if (!SELF) return resolve(!!window[name]);
    const url = new URL(path, SELF);
    url.search = new URL(SELF).search;
    if (window[name] && window[name].src === url.href) return resolve(true);
    const s = document.createElement('script');
    s.src = url.href;
    s.onload = () => resolve(!!window[name]);
    s.onerror = () => { console.warn('[pure-whip-police] MDT: could not load ' + path); resolve(!!window[name]); };
    document.head.appendChild(s);
  });
  Promise.all([need('PWPBracket', '../shared/bracket.js'), need('PWPLiveMap', './livemap.js')]).then(([style]) => {
    if (!style) return;
    B = window.PWPBracket;
    WhipPhone.module({ ...DEF, css: B.css + (window.PWPLiveMap ? window.PWPLiveMap.css : '') + CSS, globalCss: B.fonts });
  });
})();
