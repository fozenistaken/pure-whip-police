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
.mdt.ph .mdt-top{flex-wrap:wrap;padding:.375rem .75rem .5rem;gap:.5rem}
.mdt.ph .mdt-who span{display:none}
.mdt-find{display:none}
.mdt.ph .mdt-find{display:grid;place-items:center;width:2.25rem;height:2.25rem;flex:none;border-radius:var(--rs);color:var(--text)}
.mdt.ph .mdt-find.on{background:var(--sel);color:var(--on-sel)}
.mdt.ph .mdt-find svg{width:1.125rem;height:1.125rem}
.mdt.ph .mdt-rec.min{align-items:center;gap:.625rem}
.mdt.ph .mdt-rec.min .mdt-ava{width:2rem;height:2rem;font-size:.75rem}
.mdt.ph .mdt-rec.min .mdt-name h1{font-size:1.0625rem}
.mdt.ph .mdt-rec.min .mdt-name p,.mdt.ph .mdt-rec.min .mdt-flags .pwp-flag:not(.danger){display:none}
.mdt.ph .mdt-rec.min .mdt-flags{margin-top:.25rem}
.mdt-acts{display:grid;gap:.25rem}
.mdt-acts .pwp-row svg{width:1.125rem;height:1.125rem;flex:none;color:var(--mute)}
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
.mdt-h h1{margin:0;flex:1 1 14rem;min-width:0;font-size:1.5rem;font-weight:800;letter-spacing:-.025em;line-height:1.1;text-wrap:balance}
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
.mdt-chips{display:flex;flex-wrap:wrap;gap:.375rem}
.mdt-chip{border:1px solid var(--line);background:var(--fill);color:var(--text);font:inherit;font-size:.8125rem;font-weight:600;padding:.4375rem .75rem;border-radius:var(--rs);cursor:pointer;text-align:left}
.mdt-chip.on{background:var(--sel);border-color:var(--sel);color:var(--on-sel)}
.mdt-note{color:var(--mute);font-size:.8125rem}
.mdt-boardwrap{display:grid;gap:.625rem;min-height:0}
.mdt-board{position:relative;overflow:auto;height:30rem;border:1px solid var(--line);border-radius:var(--r);background:var(--panel2)}
.mdt.ph .mdt-board{height:22rem}
.mdt-board::-webkit-scrollbar{width:.375rem;height:.375rem}.mdt-board::-webkit-scrollbar-track,.mdt-board::-webkit-scrollbar-corner{background:transparent}
.mdt-board::-webkit-scrollbar-thumb{background:var(--line);border-radius:1rem}.mdt-board::-webkit-scrollbar-button{display:none;width:0;height:0}
.mdt-canvas{position:relative;width:120rem;height:80rem}
.mdt-strings{position:absolute;left:0;top:0;width:120rem;height:80rem;pointer-events:none}
.mdt-strings line{stroke:var(--danger);stroke-width:.12;stroke-linecap:round}
.mdt-pin{position:absolute;left:0;top:0;width:11rem;min-height:6rem;display:grid;align-content:start;gap:.25rem;padding:.625rem .75rem;border:1px solid var(--line);border-radius:var(--rs);background:var(--panel);color:var(--text);text-align:left;font:inherit;cursor:grab;touch-action:none;user-select:none}
.mdt-pin.sel{border-color:var(--accent);outline:1px solid var(--accent)}
.mdt-pin.drag{cursor:grabbing;z-index:2}
.mdt-pin i{font-style:normal;font-size:.625rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint)}
.mdt-pin.k-person i{color:var(--accent)}.mdt-pin.k-vehicle i{color:var(--route)}.mdt-pin.k-evidence i{color:var(--warn)}.mdt-pin.k-report i{color:var(--ok)}
.mdt-pin b{font-size:.875rem;overflow-wrap:anywhere}
.mdt-pin span{font-size:.75rem;color:var(--mute);overflow-wrap:anywhere}
.mdt-boardbar{display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;min-height:2.25rem}
.mdt-boardbar .s{color:var(--mute);font-size:.8125rem}
.mdt-ev{display:grid;gap:.625rem}
.mdt-ev.gone{opacity:.62}
.mdt-facts{display:grid;grid-template-columns:repeat(auto-fill,minmax(10.5rem,1fr));gap:.5rem .875rem}
.mdt-fact{display:flex;align-items:flex-start;gap:.25rem;min-width:0}
.mdt-fact>span{display:grid;gap:.125rem;min-width:0;flex:1}
.mdt-fact small{font-size:.625rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint)}
.mdt-fact b{font-size:.875rem;font-weight:600;overflow-wrap:break-word}
.mdt-fact b.code{font-family:var(--mono);letter-spacing:.04em;overflow-wrap:anywhere}
.mdt-copy{flex:none;width:1.75rem;height:1.75rem;display:grid;place-items:center;border:0;border-radius:var(--rs);background:transparent;color:var(--faint);cursor:pointer}
.mdt-copy:hover{color:var(--text);background:var(--line)}
.mdt-copy svg{width:.875rem;height:.875rem}
.mdt-pm{margin:0;white-space:pre-wrap;overflow-wrap:anywhere;font:inherit;font-size:.8125rem;line-height:1.5;color:var(--text)}
.mdt-custody summary{cursor:pointer;font-size:.75rem;color:var(--mute);list-style:none}
.mdt-custody summary::-webkit-details-marker{display:none}
.mdt-custody ol{margin:.375rem 0 0;padding-left:1.125rem;display:grid;gap:.25rem;font-size:.75rem;color:var(--mute)}
.mdt-photo{display:block;width:100%;height:auto;border-radius:.5rem;background:var(--line)}
.mdt-pickrow.on{border-color:var(--accent);outline:1px solid var(--accent)}
.mdt-warn{display:flex;flex-wrap:wrap;gap:.375rem}
.mdt-cp{cursor:copy;border:0;font:inherit}
.mdt-ava.pic{padding:0;overflow:hidden;background:var(--panel2)}
.mdt-ava.pic img{width:100%;height:100%;object-fit:cover;display:block}
.mdt-cp:hover{outline:1px solid var(--accent);outline-offset:.0625rem}
button.pwp-code.mdt-cp{background:none;padding:0;text-align:left}
.pwp-row.mdt-wrap{flex-wrap:wrap}
.mdt-wrap>.t{flex:1 1 9rem;min-width:0}
.mdt-wrap>.acts{display:flex;flex-wrap:wrap;align-items:center;gap:.375rem;margin-left:auto}
.mdt-news{display:grid;gap:.375rem}
.mdt-news .pwp-row.urgent .t{color:var(--danger)}
.mdt-tiles{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.5rem}
.mdt-tiles div{display:grid;gap:.125rem;padding:.5rem .625rem;border-radius:var(--rs);background:var(--fill)}
.mdt-tiles b{font-family:var(--mono);font-size:1.125rem;font-weight:600}
.mdt-tiles small{font-size:.6875rem;color:var(--mute)}
.mdt-sop{margin:0;white-space:pre-wrap;overflow-wrap:anywhere;font-size:.8125rem;line-height:1.55;max-height:18rem;overflow-y:auto}
.mdt-cs.mdt-me{border:0;background:none;color:inherit;cursor:pointer;padding:0}
.mdt-cost{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.5rem}
.mdt-cost div{display:grid;gap:.125rem;padding:.5rem .625rem;border:1px solid var(--line);border-radius:var(--rs)}
.mdt-cost small{font-size:.625rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint)}
.mdt-cost b{font-size:1rem;font-variant-numeric:tabular-nums}
.mdt-pickrow[aria-disabled="true"]{opacity:.55}
`;

  const STATUS = { available: 'Available', busy: 'Busy', enroute: 'En route', onscene: 'On scene' };
  const OUTCOME = [['resolved', 'Resolved'], ['report', 'Report written'], ['arrest', 'Arrest'], ['unfounded', 'Unfounded'], ['no_contact', 'No contact'], ['gone', 'Gone on arrival']];
  const OUTCOME_LABEL = Object.fromEntries(OUTCOME.concat([['expired', 'Expired']]));
  const PLABEL = { 0: 'P0', 1: 'P1', 2: 'P2', 3: 'P3' };
  const CAT = { infraction: 'Infraction', misdemeanor: 'Misdemeanor', felony: 'Felony' };
  const NAV = [['dispatch', 'Dispatch', 'dispatch'], ['records', 'Records', 'records'], ['reports', 'Reports', 'report'], ['boards', 'Cases', 'board'], ['wanted', 'Wanted', 'wanted'], ['academy', 'Academy', 'badge'], ['command', 'Command', 'command']];
  const RTABS = [['overview', 'Overview'], ['history', 'History'], ['vehicles', 'Vehicles'], ['notes', 'Notes'], ['evidence', 'Evidence']];
  const PINKIND = { person: 'Person', vehicle: 'Vehicle', report: 'Report', evidence: 'Evidence', note: 'Note' };
  const EVKIND = { casing: 'Casing', fragment: 'Round', blood: 'Blood', prints: 'Prints', gun: 'Gun' };
  const SHEET_TITLE = { note: 'Add a note', bolo: 'Look out for', warrant: 'Issue a warrant', plate: 'Look out for a plate', penal: 'Add or change a charge' };
  const FACT = [['weapon_serial', 'Serial'], ['serial', 'Serial'], ['fingerprint', 'Print'], ['blood_type', 'Blood type'], ['blood_traces', 'Blood traces'], ['ballistics', 'Ballistics'], ['caliber', 'Calibre'], ['ammo', 'Ammunition'],
    ['paint', 'Paint'], ['gsr', 'Residue'], ['shoe_profile', 'Sole'], ['shoe_size', 'Shoe size'], ['tyre_profile', 'Tread'], ['tyre_width', 'Tyre width'], ['fiber', 'Fibres'],
    ['surface', 'Surface'], ['cleaner', 'Cleaned with'], ['age', 'Age when collected'], ['quality', 'Quality'], ['cause', 'Cause of death']];
  const COPYABLE = new Set(['weapon_serial', 'serial', 'fingerprint', 'blood_type', 'ballistics', 'paint', 'shoe_profile', 'tyre_profile', 'fiber']);
  const MONO = new Set(['weapon_serial', 'serial', 'fingerprint', 'dna', 'shoe_profile', 'tyre_profile']);
  const COPY_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>';

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
  const fact = (k, label, v, code) => `<div class="mdt-fact"><span><small>${label}</small><b class="${code ? 'code' : ''}">${B.esc(v)}</b></span>${COPYABLE.has(k) ? `<button class="mdt-copy" data-act="copy" data-v="${B.esc(v)}" aria-label="Copy ${label}">${COPY_ICON}</button>` : ''}</div>`;
  const evRank = (e) => (e.gone ? 2 : e.kind === 'autopsy' ? 0 : 1);
  const evCard = (e) => {
    const r = { ...(e.results || {}) };
    if (e.kind === 'weapon') { r.serial = e.serial; r.ballistics = e.ballistics; r.caliber = e.caliber; }
    const facts = FACT.filter(([k]) => r[k] != null && r[k] !== '' && r[k] !== '???').map(([k, label]) => fact(k, label, String(r[k]), MONO.has(k)));
    const sub = [e.tested_on, e.street, e.time, e.collected_by || e.taken_by].filter(Boolean).map(B.esc).join(' · ');
    const flags = (e.gone ? '<span class="pwp-flag">Not in locker</span>' : '') + (e.taken ? `<span class="pwp-flag warn">Out · ${B.esc(e.taken.by || '')}</span>` : '');
    const owner = e.printOwner ? `<button class="pwp-row" data-act="openPerson" data-id="${e.printOwner}"><span class="pwp-code">${e.printOwner}</span><span class="t">${B.esc(e.printOwnerName || 'Person ' + e.printOwner)}<span class="s">Print matches what is on file</span></span></button>` : '';
    const inFrame = e.kind === 'photo' ? [(e.entries || []).length ? (e.entries.length === 1 ? '1 trace' : e.entries.length + ' traces') : '', (e.bodies || []).length ? (e.bodies.length === 1 ? '1 body' : e.bodies.length + ' bodies') : ''].filter(Boolean).join(' · ') : '';
    const photo = e.kind === 'photo' && e.photo_id ? `<div class="pwp-row"><span class="t">${inFrame ? 'In frame' : 'Photo'}<span class="s">${B.esc(inFrame)}</span></span><button class="pwp-btn sm pwp-press" data-act="evPhoto" data-p="${B.esc(e.photo_id)}">View photo</button></div>` : '';
    const text = (e.report && e.report.text) || r.findings;
    const pm = text ? `<div class="mdt-fact"><span><small>Post-mortem</small><pre class="mdt-pm">${B.esc(text)}</pre></span><button class="mdt-copy" data-act="copy" data-v="${B.esc(text)}" aria-label="Copy the report">${COPY_ICON}</button></div>` : '';
    const steps = String(e.custody || '').split(/\n+/).filter(Boolean);
    const custody = steps.length ? `<details class="mdt-custody"><summary>Chain of custody · ${steps.length}</summary><ol>${steps.map((x) => `<li>${B.esc(x)}</li>`).join('')}</ol></details>` : '';
    return `<section class="pwp-card mdt-ev ${e.gone ? 'gone' : ''}" data-key="ev-${B.esc(e.ref)}"><div class="pwp-row">${e.marker ? `<span class="pwp-code">${B.esc(e.marker)}</span>` : ''}<span class="t">${B.esc(e.type || e.kind)}<span class="s">${sub}</span></span>${flags}</div>${facts.length ? `<div class="mdt-facts">${facts.join('')}</div>` : ''}${pm}${owner}${photo}${custody}</section>`;
  };
  const TICKET_FLAG = { open: ['Contested', 'warn'], dismissed: ['Dismissed', ''], reduced: ['Reduced', ''], upheld: ['Upheld', 'warn'], lapsed: ['Lapsed', ''] };
  const ticketFlag = (f) => {
    if (f.contest && f.contest !== 'none') { const [l, c] = TICKET_FLAG[f.contest] || [f.contest, '']; return `<span class="pwp-flag ${c}">${l}</span>`; }
    if (f.warrantId) return '<span class="pwp-flag danger">Warrant</span>';
    if (f.status === 'unpaid') return '<span class="pwp-flag warn">Unpaid</span>';
    return `<span class="pwp-flag">${B.esc(f.status === 'void' ? 'Void' : f.status === 'warning' ? 'Warning' : 'Paid')}</span>`;
  };
  const impCost = (s) => {
    const f = s.imp; const fee = Math.max(0, Number(String(s.f.impFee || '').replace(/[^0-9]/g, '')) || 0);
    const days = s.f.impHold === 'days' ? Math.max(0, Number(s.f.impDays) || 0) : 0;
    const pickup = fee + Math.min(days, f.maxDays) * f.perDay;
    return { fee, pickup, most: fee + f.maxDays * f.perDay };
  };
  const copyText = (app, text) => {
    const ctx = live.get(app);
    const doc = (ctx && ctx.el.ownerDocument) || document;
    const ta = doc.createElement('textarea');
    ta.value = text; ta.setAttribute('readonly', ''); ta.style.position = 'fixed'; ta.style.opacity = '0';
    doc.body.appendChild(ta); ta.select();
    let ok = false;
    try { ok = doc.execCommand('copy'); } catch { ok = false; }
    ta.remove();
    if (!ok && navigator.clipboard) navigator.clipboard.writeText(text).catch(() => {});
  };
  const chargeList = (app) => Object.entries(app.state.charges).filter(([, n]) => n > 0).map(([code, count]) => ({ code, count }));
  const navFor = (app) => NAV.filter(([id]) => (id !== 'command' || perms(app).command || perms(app).prison_staff)
    && (id !== 'academy' || (app.state.me && app.state.me.academy) || perms(app).command));

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

  const shown = (s) => JSON.stringify([s.nav, s.penal && s.penal.length, s.calls, s.units, s.recent, s.reports, s.warrants, s.bolos, s.prisoners, s.feeds, s.boards, s.board, s.caseEv, s.lot, s.callLog, s.news, s.roster, s.permitApps, s.complaints, s.sop, s.academy, s.exam, s.examResult, s.err]);

  const load = async (app) => {
    const s = app.state;
    const before = shown(s);
    const jobs = [];
    if (!s.penal) jobs.push(ask(app, 'penal', {}, (r) => { s.penal = r; }, true));
    if (s.nav === 'dispatch') jobs.push(ask(app, 'dashboard', {}, (r) => { s.calls = r.calls; s.units = r.units; s.recent = r.reports; }, true));
    if (s.nav === 'academy' && !s.exam) jobs.push(ask(app, 'academy', {}, (r) => { s.academy = r; }, true));
    if (s.nav === 'boards') jobs.push(s.board ? ask(app, 'board', { id: s.board.id }, (r) => { s.board = r; }, true) : ask(app, 'boards', {}, (r) => { s.boards = r; }, true));
    if (s.nav === 'boards' && s.board && s.bview === 'locker') jobs.push(loadEv(app));
    if (s.nav === 'dispatch') jobs.push(ask(app, 'news', {}, (r) => { s.news = r || []; }, true));
    if (s.nav === 'command') {
      jobs.push(ask(app, 'roster', {}, (r) => { s.roster = r || []; }, true));
      if (perms(app).command) {
        jobs.push(ask(app, 'permitApps', {}, (r) => { s.permitApps = r || []; }, true));
        jobs.push(ask(app, 'complaints', {}, (r) => { s.complaints = r || []; }, true));
        jobs.push(ask(app, 'sop', {}, (r) => { s.sop = r; if (s.f.sopText == null && r) s.f.sopText = r.text; }, true));
      }
    }
    if (s.nav === 'dispatch' && s.dview === 'log') jobs.push(ask(app, 'callHistory', {}, (r) => { s.callLog = r || []; }, true));
    if (s.nav === 'dispatch' && s.dview === 'board' && perms(app).records) jobs.push(ask(app, 'feeds', {}, (r) => { s.feeds = r; }, true));
    else jobs.push(ask(app, 'calls', {}, (r) => { s.calls = r.calls; s.units = r.units; }, true));
    if (s.nav === 'records' && !s.person && !s.results) jobs.push(ask(app, 'lot', { lot: s.lotPick || null }, (r) => { s.lot = r; }, true));
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
    const hi = c.level != null ? c.level <= 1 : c.priority === 'high';
    const p = perms(app);
    const who = n ? ': ' + c.responders.map((r) => B.esc(r.callsign)).join(', ') : '';
    const picked = app.state.pick === c.id;
    return `<article class="mdt-call ${hi ? 'hi pwp-bracket danger' : mine ? 'pwp-bracket' : ''} ${picked ? 'on' : ''}" data-call="${c.id}">
      <button class="pick" data-act="pickCall" data-id="${c.id}" aria-pressed="${picked}"><span class="c">${c.level != null ? PLABEL[c.level] + ' · ' : ''}${B.esc(c.code)} · ${ago(c.createdAt)}${c.count > 1 ? ' · ' + c.count + ' reports' : ''}</span><b>${B.esc(c.title)}</b>
      ${(c.info || []).map((l) => `<span>${B.esc(l)}</span>`).join('')}
      <span>${n} of ${c.maxResponders} units${who}</span></button>
      <div class="acts">${p.dispatch ? (mine ? `<button class="pwp-btn sm pwp-press" data-act="detach" data-id="${c.id}">Leave</button>` : `<button class="pwp-btn sm inv pwp-press" data-act="attach" data-id="${c.id}">Respond</button>`) : ''}<button class="pwp-btn sm ghost icon pwp-press" data-act="waypoint" data-id="${c.id}" aria-label="Set a waypoint">${B.icons.pin}</button>${p.dispatch ? `<button class="pwp-btn sm ghost pwp-press" data-act="openSheet" data-k="closeCall" data-id="${c.id}">Close</button>` : ''}</div>
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

  const feedRows = (app) => {
    const f = app.state.feeds;
    if (!f) return '';
    const last = (log) => (log && log[0] ? B.esc(log[0].text) + ' · ' + when(log[0].at) : 'Nothing logged');
    const cams = f.cameras.length ? f.cameras.map((c) => `<div class="pwp-row" data-key="cam${c.id}"><span class="pwp-code">${String(c.id).padStart(2, '0')}</span><span class="t">${B.esc(c.label)}<span class="s">${last(c.log)}</span></span>${c.dark ? '<span class="pwp-flag danger">Dark</span>' : `<button class="pwp-btn sm pwp-press" data-act="watch" data-k="cam" data-id="${c.id}">Watch</button>`}</div>`).join('') : '<div class="pwp-empty">No cameras placed yet (Settings → Police → CCTV cameras)</div>';
    const me = (app.state.me || {}).callsign;
    const units = f.units.filter((u) => u.callsign !== me).map((u) => `<div class="pwp-row" data-key="bc${u.source}"><span class="pwp-code" style="color:var(--text)">${B.esc(u.callsign)}</span><span class="t">${B.esc((u.dept || '').toUpperCase())}<span class="s">${last(u.log)}</span></span><button class="pwp-btn sm pwp-press" data-act="watch" data-k="unit" data-id="${u.source}">Body cam</button></div>`).join('');
    return `<section class="pwp-card"><p class="pwp-lbl">Cameras</p>${cams}</section>${units ? `<section class="pwp-card"><p class="pwp-lbl">Body cams</p>${units}</section>` : ''}`;
  };

  const reportRow = (r) => `<button class="pwp-row" data-act="openReport" data-id="${r.id}"><span class="pwp-code">#${r.id}</span><span class="t">${B.esc(r.title)}<span class="s">${B.esc((r.dept || '').toUpperCase())} · ${when(r.createdAt)}</span></span>${r.status === 'closed' ? '<span class="pwp-flag">Closed</span>' : ''}</button>`;

  const head = (title, back, extra) => `<div class="mdt-h">${back ? `<button class="pwp-btn ghost pwp-press" data-act="${back}">${B.icons.back}Back</button>` : ''}<h1>${B.esc(title)}</h1>${extra || ''}</div>`;
  const hasMap = () => !!window.PWPLiveMap;
  const onMap = (s) => s.nav === 'dispatch' && s.dview === 'map' && hasMap();
  const scroll = (inner, key) => `<div class="mdt-scroll" data-scroll="${key}">${inner}</div>`;
  const personActs = (app) => {
    const pm = perms(app); const p = app.state.person || {};
    return [
      pm.records && ['openSheet', 'note', 'note', 'Note'],
      pm.records && p.online && ['mugshot', '', 'camera', 'Mugshot'],
      pm.records && ['openSheet', 'tags', 'pin', 'Tags'],
      pm.records && ['openSheet', 'bolo', 'wanted', 'BOLO'],
      pm.warrants && ['openSheet', 'warrant', 'command', 'Warrant'],
    ].filter(Boolean);
  };
  const NAV_PHONE = 4;

  const screens = {
    dispatch(app, phone) {
      const s = app.state;
      const recent = s.recent || [];
      const views = (hasMap() ? [['map', 'Map', 'map']] : []).concat([['board', 'Board', 'list'], ['log', 'History', 'report']]);
      const seg = `<div class="pwp-seg" data-glide="dview">${views.map(([v, label, ic]) => `<button class="${s.dview === v ? 'on' : ''}" data-act="dview" data-v="${v}" aria-pressed="${s.dview === v}">${B.icons[ic] || ''}${label}</button>`).join('')}</div>`;
      if (s.dview === 'log') {
        const rows = (s.callLog || []).map((c) => `<div class="pwp-row mdt-wrap" data-key="cl${c.id}"><span class="pwp-code">${B.esc(c.code)}</span><span class="t">${B.esc(c.title)}${c.count > 1 ? ' · ' + c.count + ' reports' : ''}<span class="s">${B.esc([when(c.createdAt), c.units, c.note].filter(Boolean).join(' · '))}</span></span><span class="acts"><span class="pwp-flag ${c.outcome === 'arrest' ? 'danger' : c.outcome === 'expired' ? '' : 'ok'}">${B.esc(OUTCOME_LABEL[c.outcome] || c.outcome)}</span></span></div>`).join('');
        return { body: head('Dispatch', null, seg) + scroll(`<section class="pwp-card"><p class="pwp-lbl">Closed calls</p>${rows || '<div class="pwp-empty">No closed calls yet</div>'}</section>`, 'calllog') };
      }
      if (onMap(s)) {
        const c = phone && s.pick != null ? (s.calls || []).find((x) => x.id === s.pick) : null;
        return { body: head('Dispatch', null, seg) + `<div class="mdt-mapwrap"><div class="mdt-map-slot"></div>${c ? `<div class="mdt-mapcard pwp-fade">${callCard(app, c)}</div>` : ''}</div>` };
      }
      const calls = phone ? `<section class="pwp-card"><p class="pwp-lbl">Live calls</p><div style="display:grid;gap:.625rem">${callList(app)}</div></section>` : '';
      const news = (s.news || []);
      const newsCard = news.length || perms(app).command ? `<section class="pwp-card mdt-news"><p class="pwp-lbl">Notices</p>${news.map((n) => `<div class="pwp-row mdt-wrap ${n.urgent ? 'urgent' : ''}" data-key="n${n.id}"><span class="t">${B.esc(n.text)}<span class="s">${B.esc([n.by, when(n.at)].filter(Boolean).join(' · '))}</span></span>${perms(app).command ? `<span class="acts"><button class="pwp-btn sm ghost pwp-press" data-act="endNews" data-id="${n.id}">Take down</button></span>` : ''}</div>`).join('') || '<div class="pwp-empty">No notices</div>'}${perms(app).command ? '<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="announce" style="justify-self:start">Post a notice</button>' : ''}</section>` : '';
      return { body: head('Dispatch', null, seg) + scroll(`${newsCard}${calls}
        <section class="pwp-card"><p class="pwp-lbl">Units on duty</p>${unitRows(app)}</section>
        ${feedRows(app)}
        <section class="pwp-card"><p class="pwp-lbl">Latest reports</p>${recent.length ? recent.map(reportRow).join('') : '<div class="pwp-empty">No reports yet</div>'}</section>`, 'dispatch') };
    },

    records(app, phone) {
      const s = app.state;
      if (s.person) return screens.person(app, phone);
      const r = s.results;
      if (!r) {
        const lot = s.lot || { rows: [], lots: [] };
        const segLots = lot.lots.length > 1 ? `<div class="pwp-seg" data-glide="lotpick">${[['', 'All']].concat(lot.lots.map((l) => [l.id, l.label])).map(([v, l]) => `<button class="${(s.lotPick || '') === v ? 'on' : ''}" data-act="lotPick" data-v="${B.esc(v)}">${B.esc(l)}</button>`).join('')}</div>` : '';
        const rows = lot.rows.map((c) => `<div class="pwp-row mdt-wrap" data-key="lot${c.id}"><button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(c.plate || '')}" title="Copy">${B.esc(c.plate || '')}</button><span class="t">${B.esc(c.owner || 'Owner #' + c.ownerCharId)}<span class="s">${B.esc([c.reason, when(c.at), lot.lots.length > 1 ? c.lotLabel : ''].filter(Boolean).join(' · '))}</span></span>
          <span class="acts">${c.towState === 'waiting' ? '<span class="pwp-flag route">Waiting for tow</span>' : ''}<span class="num">${B.money(c.paid ? c.paidAmount : c.bill.total)}</span>${c.paid ? '<span class="pwp-flag ok">Paid</span>' : ''}${c.held ? `<span class="pwp-flag warn">${c.heldUntil ? 'Held to ' + B.esc(when(c.heldUntil)) : 'Held'}</span><button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="lift" data-id="${c.id}">Lift</button>` : ''}</span></div>`).join('');
        return { body: head('Records', null, segLots) + scroll(`<section class="pwp-card"><p class="pwp-lbl">Impound lot</p>${rows || '<div class="pwp-empty">Nothing held</div>'}</section>`, 'records') };
      }
      const people = r.people.length ? r.people.map((p) => `<button class="pwp-row" data-act="openPerson" data-id="${p.charId}"><span class="pwp-code">${p.charId}</span><span class="t">${B.esc(p.firstName)} ${B.esc(p.lastName)}<span class="s">Born ${B.esc(day(p.dateOfBirth))} · ${B.esc(p.gender)}</span></span>${(p.tags || []).slice(0, 2).map((t) => `<span class="pwp-flag warn">${B.esc(t)}</span>`).join('')}${p.warrant ? '<span class="pwp-flag danger">Wanted</span>' : ''}</button>`).join('') : '';
      const cars = r.vehicles.length ? r.vehicles.map((v) => `<div class="pwp-row"><button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(v.plate)}" title="Copy">${B.esc(v.plate)}</button><span class="t">${B.esc(v.model)}<span class="s">${v.bolo ? 'BOLO: ' + B.esc(v.bolo.reason) : B.esc(v.owner || 'Owner #' + v.ownerCharId) + ' · ' + B.esc(v.state)}${v.seen ? ' · seen ' + (ago(v.seen.at) === 'now' ? 'just now' : ago(v.seen.at) + ' ago') : ''}</span></span><span class="acts">${v.impound ? `<span class="pwp-flag warn">${B.esc(v.impound.lot)}</span>` : ''}${!v.impound && v.state === 'garaged' && perms(app).fine ? `<button class="pwp-btn sm pwp-press" data-act="impoundForm" data-id="${v.vehicleId}">Impound</button>` : ''}${v.seen ? `<button class="pwp-btn sm pwp-press" data-act="evWaypoint" data-x="${v.seen.x}" data-y="${v.seen.y}">Last seen</button>` : ''}${!v.bolo && perms(app).records ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="plate" data-plate="${B.esc(v.plate)}">BOLO</button>` : ''}<button class="pwp-btn sm pwp-press" data-act="openPerson" data-id="${v.ownerCharId}">Owner</button></span></div>`).join('') : '';
      const reps = r.reports.length ? r.reports.map(reportRow).join('') : '';
      const ev = r.evidence || { rows: [] };
      const match = ev.owner ? `<button class="pwp-row" data-act="openPerson" data-id="${ev.owner}"><span class="pwp-code">${ev.owner}</span><span class="t">${B.esc(ev.ownerName || 'Person ' + ev.owner)}<span class="s">Matches what is on file</span></span></button>` : '';
      const filed = (ev.cases || []).map((c) => `<button class="pwp-row" data-act="openCase" data-id="${c.caseId}"><span class="pwp-code">#${c.caseId}</span><span class="t">${B.esc(c.type || c.kind)}<span class="s">${[c.street, c.time].filter(Boolean).map(B.esc).join(' · ')}</span></span>${c.gone ? '<span class="pwp-flag">Not in locker</span>' : ''}</button>`).join('');
      const found = ev.rows.map((e) => `<div class="pwp-row"><span class="pwp-code">${B.esc(EVKIND[e.kind] || e.kind)}</span><span class="t">${B.esc(e.code || e.serial || 'No marks')}<span class="s">${[e.gunName, e.foundAt ? when(e.foundAt) : '', String(e.dept || '').toUpperCase()].filter(Boolean).map(B.esc).join(' · ')}</span></span><span class="acts">${e.owner && e.owner !== ev.owner ? `<button class="pwp-btn sm pwp-press" data-act="openPerson" data-id="${e.owner}">${B.esc(e.ownerName || 'Person')}</button>` : ''}${e.x != null ? `<button class="pwp-btn sm pwp-press" data-act="evWaypoint" data-x="${e.x}" data-y="${e.y}">Waypoint</button>` : ''}</span></div>`).join('');
      const w = r.weapon;
      const WEV = { registered: 'Registered', transferred: 'Transferred', stolen: 'Reported stolen', seized: 'Seized', destroyed: 'Destroyed' };
      const WST = { registered: ['Registered', 'ok'], stolen: ['Stolen', 'danger'], seized: ['Seized', 'warn'], destroyed: ['Destroyed', ''] };
      const gun = w ? `<section class="pwp-card"><p class="pwp-lbl">Weapon</p><div class="pwp-row mdt-wrap"><button class="pwp-code mdt-cp" data-act="copy" data-v="${B.esc(w.serial)}" title="Copy">${B.esc(w.serial)}</button><span class="t">${B.esc(w.name || w.item || 'Gun')}<span class="s">${w.owner ? 'Registered to ' + B.esc(w.owner) : 'No owner'}</span></span><span class="acts"><span class="pwp-flag ${(WST[w.status] || ['', ''])[1]}">${(WST[w.status] || [w.status])[0]}</span>${w.ownerCharId ? `<button class="pwp-btn sm pwp-press" data-act="openPerson" data-id="${w.ownerCharId}">Owner</button>` : ''}</span></div>
        ${perms(app).records ? `<div class="mdt-chips">${Object.entries(WST).filter(([k]) => k !== w.status).map(([k, [l]]) => `<button class="mdt-chip" data-act="weaponStatus" data-v="${k}" data-serial="${B.esc(w.serial)}">Mark ${l.toLowerCase()}</button>`).join('')}</div>` : ''}
        ${(w.history || []).map((h) => `<div class="pwp-row"><span class="t">${B.esc(WEV[h.event] || h.event)}${h.who ? ' · ' + B.esc(h.who) : ''}<span class="s">${B.esc([h.by ? 'by ' + h.by : '', h.note, when(h.at)].filter(Boolean).join(' · '))}</span></span></div>`).join('')}</section>` : '';
      const none = !people && !cars && !reps && !match && !found && !filed && !gun;
      return { body: head(`Results for “${s.lastQ}”`) + scroll(none ? '<div class="pwp-empty">Nothing matches that search.</div>' : `
        ${people ? `<section class="pwp-card"><p class="pwp-lbl">People</p>${people}</section>` : ''}
        ${cars ? `<section class="pwp-card"><p class="pwp-lbl">Vehicles</p>${cars}</section>` : ''}
        ${reps ? `<section class="pwp-card"><p class="pwp-lbl">Reports</p>${reps}</section>` : ''}
        ${gun}${match || found || filed ? `<section class="pwp-card"><p class="pwp-lbl">Evidence</p>${match}${found}${filed}</section>` : ''}`, 'results') };
    },

    person(app, phone) {
      const s = app.state; const p = s.person; const pm = perms(app);
      const active = (p.warrants || []).filter((w) => w.status === 'active');
      const unpaid = (p.fines || []).filter((f) => f.status === 'unpaid');
      const flags = [active.length ? '<span class="pwp-flag danger">Wanted</span>' : '', p.sentence ? '<span class="pwp-flag route">In prison</span>' : '', p.online ? '<span class="pwp-flag">In town</span>' : '',
        ...(p.tags || []).map((t) => `<span class="pwp-flag warn">${B.esc(t)}</span>`)].join('');
      const asked = (p.warrants || []).filter((w) => w.status === 'requested');
      const LIC = { valid: ['Valid', 'ok'], suspended: ['Suspended', 'warn'], revoked: ['Revoked', 'danger'] };
      const kinds = (s.me && s.me.licenceKinds) || {};
      const lic = Object.entries(kinds).map(([k, label]) => {
        const l = (p.licences || []).find((x) => x.kind === k);
        const st = l ? LIC[l.status] || [l.status, ''] : ['None', ''];
        return `<div class="pwp-row mdt-wrap" data-key="lic${k}"><span class="t">${B.esc(label)}<span class="s">${l && l.status === 'suspended' && l.untilAt ? 'until ' + B.esc(when(l.untilAt)) + ' · ' : ''}${B.esc((l && l.note) || '')}</span></span><span class="acts"><span class="pwp-flag ${st[1]}">${st[0]}</span>${pm.records ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="licence" data-v="${B.esc(k)}">Change</button>` : ''}</span></div>`;
      }).join('');
      const tab = {
        overview: () => `<div class="mdt-grid">
            <section class="pwp-card"><p class="pwp-lbl">Warrants</p>${active.length ? active.map((w) => `<div class="pwp-row"><span class="t">${B.esc(w.reason)}<span class="s">Valid until ${when(w.expiresAt)}</span></span>${pm.warrants ? `<button class="pwp-btn sm pwp-press" data-act="closeWarrant" data-id="${w.id}" data-s="served">Served</button>` : ''}</div>`).join('') : '<div class="pwp-empty">None active</div>'}</section>
            ${asked.length ? `<section class="pwp-card"><p class="pwp-lbl">Warrants asked for</p>${asked.map((w) => `<div class="pwp-row"><span class="t">${B.esc(w.reason)}<span class="s">Waiting for a judge</span></span><span class="pwp-flag route">Asked</span></div>`).join('')}</section>` : ''}
            ${lic ? `<section class="pwp-card"><p class="pwp-lbl">Licences</p>${lic}</section>` : ''}
            <section class="pwp-card"><p class="pwp-lbl">Unpaid fines</p>${unpaid.length ? `<div class="pwp-row"><span class="t">${unpaid.length === 1 ? '1 citation' : unpaid.length + ' citations'}</span><span class="mdt-big num">${B.money(unpaid.reduce((a, f) => a + f.amount, 0))}</span></div>` : '<div class="pwp-empty">None</div>'}</section>
            ${p.sentence ? `<section class="pwp-card"><p class="pwp-lbl">Sentence</p><div class="pwp-row"><span class="t">${B.esc(p.sentence.reason || 'Serving time')}</span><span class="mdt-big num">${B.esc(p.sentence.minutesLeft)} min</span></div></section>` : ''}
          </div>`,
        history: () => `<section class="pwp-card"><p class="pwp-lbl">Reports</p>${(p.reports || []).length ? p.reports.map((r) => `<button class="pwp-row" data-act="openReport" data-id="${r.id}"><span class="pwp-code">#${r.id}</span><span class="t">${B.esc(r.title)}<span class="s">${when(r.createdAt)}</span></span></button>`).join('') : '<div class="pwp-empty">Not named in any report</div>'}</section>
          <section class="pwp-card"><p class="pwp-lbl">Tickets and fines</p>${(p.fines || []).length ? p.fines.map((f) => `<div class="pwp-row mdt-wrap" data-key="f${f.id}"><button class="pwp-code mdt-cp" data-act="copy" data-v="${B.esc(f.number || '')}" title="Copy">${B.esc(f.number || '')}</button><span class="t">${B.esc(f.reason || f.label || 'Fine')}<span class="s">${B.esc([f.label, f.plate, when(f.createdAt)].filter(Boolean).join(' · '))}</span></span><span class="acts">${f.kind === 'warning' ? '' : `<span class="num">${B.money(f.amount)}</span>`}${ticketFlag(f)}
            ${f.contest === 'open' && pm.records ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="statement" data-id="${f.id}">${f.statement ? 'Statement' : 'Add statement'}</button>` : ''}${f.status === 'unpaid' && pm.command ? `<button class="pwp-btn sm ghost pwp-press" data-act="voidTicket" data-id="${f.id}">Void</button>` : ''}</span></div>`).join('') : '<div class="pwp-empty">No tickets or fines</div>'}</section>`,
        vehicles: () => `<section class="pwp-card"><p class="pwp-lbl">Registered guns</p>${(p.weapons || []).length ? p.weapons.map((g) => `<div class="pwp-row"><button class="pwp-code mdt-cp" data-act="copy" data-v="${B.esc(g.serial)}" title="Copy">${B.esc(g.serial)}</button><span class="t">${B.esc(g.name || g.item || 'Gun')}<span class="s">${when(g.registeredAt)}</span></span><span class="pwp-flag ${g.status === 'stolen' ? 'danger' : g.status === 'registered' ? 'ok' : 'warn'}">${B.esc(g.status)}</span></div>`).join('') : '<div class="pwp-empty">No guns registered</div>'}</section>
          <section class="pwp-card"><p class="pwp-lbl">Registered vehicles</p>${(p.vehicles || []).length ? p.vehicles.map((v) => `<div class="pwp-row"><button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(v.plate)}" title="Copy">${B.esc(v.plate)}</button><span class="t">${B.esc(v.model)}<span class="s">${B.esc(v.state)}</span></span>${pm.records ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="plate" data-plate="${B.esc(v.plate)}">BOLO</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No registered vehicles</div>'}</section>`,
        evidence: () => `<section class="pwp-card"><p class="pwp-lbl">On file</p>${p.samples ? `<div class="mdt-facts">
            ${p.samples.dna ? fact('dna', 'DNA', p.samples.dna, true) : ''}${fact('fingerprint', 'Print', p.samples.print, true)}${p.samples.blood ? fact('blood_type', 'Blood type', p.samples.blood, true) : ''}
            <div class="mdt-fact"><span><small>Taken</small><b>${when(p.samples.takenAt)}</b></span></div></div>` : `<div class="pwp-empty">Nothing taken yet</div>${pm.records && p.online ? `<button class="pwp-btn pwp-press" data-act="takeSamples">${s.me.forensics ? 'Take fingerprints' : 'Take prints and DNA'}</button>` : ''}`}</section>`,
        notes: () => `<section class="pwp-card"><p class="pwp-lbl">Notes</p>${(p.notes || []).length ? p.notes.map((n) => `<div class="pwp-row"><span class="t">${B.esc(n.text)}<span class="s">${B.esc(n.author || '')} · ${when(n.createdAt)}</span></span></div>`).join('') : '<div class="pwp-empty">No notes</div>'}</section>`,
      };
      const canCharge = pm.fine || pm.jail;
      const list = personActs(app);
      const acts = (phone
        ? (list.length ? `<button class="pwp-btn pwp-press" data-act="openSheet" data-k="pactions">${B.icons.more || B.icons.list}Actions</button>` : '')
        : list.map(([act, k, icon, label]) => `<button class="pwp-btn mdt-side-act pwp-press" data-act="${act}"${k ? ` data-k="${k}"` : ''} aria-label="${label}">${B.icons[icon] || B.icons.badge}<span class="mdt-at">${label}</span></button>`).join(''))
        + (canCharge ? `<button class="pwp-cta has-kbd pwp-press" data-act="openSheet" data-k="charge">${B.icons.gavel}Charge<span class="pwp-kbd">C</span></button>` : '');
      return {
        body: `<div class="mdt-rec">${(s.mugs || {})[p.charId] ? `<div class="mdt-ava pic"><img src="${B.esc(s.mugs[p.charId])}" alt="Mugshot of ${B.esc(p.firstName)}"></div>` : `<div class="mdt-ava">${B.esc(initials(p))}</div>`}<div class="mdt-name"><h1>${B.esc(p.firstName)} ${B.esc(p.lastName)}</h1><p class="mono"><button class="pwp-code mdt-cp" data-act="copy" data-v="${p.charId}" title="Copy">ID ${p.charId}</button> · born ${B.esc(day(p.dateOfBirth))} · ${B.esc(p.gender)}</p>${flags ? `<div class="mdt-flags">${flags}</div>` : ''}</div>
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
          ${edit && !r.id && !r.body && ((s.me && s.me.templates) || []).length ? `<div class="mdt-chips">${s.me.templates.map((t, i) => `<button class="mdt-chip" data-act="useTemplate" data-i="${i}">${B.esc(t.name)}</button>`).join('')}</div>` : ''}
          <section class="pwp-card"><p class="pwp-lbl">People</p>
            ${(r.people || []).length ? r.people.map((p, i) => `<div class="pwp-row"><span class="pwp-code">${p.charId}</span><span class="t">${B.esc(p.name || 'Citizen ' + p.charId)}<span class="s">${B.esc(p.role)}</span></span>${edit ? `<button class="pwp-btn ghost icon pwp-press" data-act="removePerson" data-i="${i}" aria-label="Remove">${B.icons.x}</button>` : ''}</div>`).join('') : '<div class="pwp-empty">Nobody added</div>'}
            ${edit ? `<div class="pwp-row"><input id="f-addPersonId" class="pwp-in" style="max-width:8rem" data-bind="addPersonId" value="${val(app, 'addPersonId')}" placeholder="Citizen ID" inputmode="numeric">
              <span class="acts">${['suspect', 'victim', 'witness'].map((role) => `<button class="pwp-btn sm pwp-press" data-act="addPerson" data-role="${role}">${B.icons.plus}${role[0].toUpperCase() + role.slice(1)}</button>`).join('')}</span></div>` : ''}
          </section>
          <section class="pwp-card"><p class="pwp-lbl">Vehicles</p>
            ${(r.plates || []).length ? r.plates.map((pl, i) => `<div class="pwp-row"><button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(pl)}" title="Copy">${B.esc(pl)}</button><span class="t"></span>${edit ? `<button class="pwp-btn ghost icon pwp-press" data-act="removePlate" data-i="${i}" aria-label="Remove">${B.icons.x}</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No vehicles</div>'}
            ${edit ? `<div class="pwp-row"><input id="f-addPlate" class="pwp-in mono" style="max-width:9rem" data-bind="addPlate" data-enter="addPlate" value="${val(app, 'addPlate')}" placeholder="Plate"><span class="acts"><button class="pwp-btn sm pwp-press" data-act="addPlate">${B.icons.plus}Add</button></span></div>` : ''}
          </section>
          <section class="pwp-card"><p class="pwp-lbl">Charges</p>
            ${(r.charges || []).length ? r.charges.map((c, i) => `<div class="pwp-row"><span class="pwp-code">${B.esc(c.code)}</span><span class="t">${B.esc((pmap[c.code] || {}).title || '')}<span class="s">Citizen ${B.esc(c.charId)}${c.count > 1 ? ' · ×' + c.count : ''}</span></span>${edit ? `<button class="pwp-btn ghost icon pwp-press" data-act="removeReportCharge" data-i="${i}" aria-label="Remove">${B.icons.x}</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No charges</div>'}
            ${edit ? `<div class="pwp-row"><input id="f-addChargeCode" class="pwp-in mono" style="max-width:8rem" data-bind="addChargeCode" value="${val(app, 'addChargeCode')}" placeholder="Code"><input id="f-addChargeFor" class="pwp-in" style="max-width:8rem" data-bind="addChargeFor" value="${val(app, 'addChargeFor')}" placeholder="Citizen ID" inputmode="numeric"><span class="acts"><button class="pwp-btn sm pwp-press" data-act="addReportCharge">${B.icons.plus}Add</button></span></div>` : ''}
            ${(r.charges || []).length ? `<div class="pwp-tot"><div><small>Fines</small><b class="num">${B.money(t.fine)}</b></div><div><small>Prison</small><b class="num">${t.months} mo</b></div></div>` : ''}
          </section>`, 'report'),
        act: edit ? `<div class="pwp-seg" data-glide="rstatus">${['open', 'closed'].map((v) => `<button class="${(r.status || 'open') === v ? 'on' : ''}" data-act="setStatus" data-v="${v}">${v === 'open' ? 'Open' : 'Closed'}</button>`).join('')}</div><span class="grow"></span><button class="pwp-cta pwp-press" data-act="saveReport">Save report</button>` : '',
      };
    },

    boards(app) {
      const s = app.state;
      if (s.board) return screens.board(app);
      const list = s.boards || [];
      const extra = `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="case">${B.icons.plus}New</button>`;
      return { body: head('Investigations', null, extra) + scroll(`<section class="pwp-card">${list.length ? list.map((c) => `<button class="pwp-row" data-act="openBoard" data-id="${c.id}" data-key="b${c.id}"><span class="pwp-code">#${c.id}</span><span class="t">${B.esc(c.title)}<span class="s">${c.items} pinned${c.lead ? ' · ' + B.esc(c.lead) : ''} · ${when(c.updatedAt)}</span></span>${c.status === 'closed' ? '<span class="pwp-flag">Closed</span>' : ''}</button>`).join('') : '<div class="pwp-empty">No investigations yet. Start one and pin people, cars, reports and evidence to it.</div>'}</section>`, 'boards') };
    },

    board(app) {
      const s = app.state; const b = s.board;
      const caseNo = `<button class="pwp-btn sm mdt-cp" data-act="copy" data-v="${b.id}" title="Copy the case number">#${b.id}</button>`;
      const seg = `<div class="pwp-seg" data-glide="bview">${[['board', 'Board'], ['file', 'File']].concat(s.me.forensics ? [['locker', 'Evidence']] : []).map(([v, l]) => `<button class="${(s.bview || 'board') === v ? 'on' : ''}" data-act="bview" data-v="${v}" aria-pressed="${(s.bview || 'board') === v}">${l}</button>`).join('')}</div>`;
      if (s.bview === 'file') {
        const officers = (b.officers || []).map((o) => `<div class="pwp-row" data-key="bo${o.charId}"><span class="pwp-code">${o.charId}</span><span class="t">${B.esc(o.name || 'Officer')}</span><button class="pwp-btn ghost icon pwp-press" data-act="boardAssign" data-id="${o.charId}" data-on="0" aria-label="Take off the case">${B.icons.x}</button></div>`).join('');
        const onDuty = (s.units || []).filter((u) => u.charId && !(b.officers || []).some((o) => o.charId === u.charId));
        const add = onDuty.length ? `<div class="mdt-chips">${onDuty.map((u) => `<button class="mdt-chip" data-act="boardAssign" data-id="${u.charId}" data-on="1">${B.icons.plus}${B.esc(u.callsign)}</button>`).join('')}</div>` : '';
        const log = (b.log || []).map((l) => `<div class="pwp-row" data-key="bl${l.id}"><span class="t">${B.esc(l.text)}<span class="s">${B.esc([l.by, when(l.at)].filter(Boolean).join(' · '))}</span></span></div>`).join('');
        return { body: head(b.title, 'closeBoard', caseNo + seg) + scroll(`<section class="pwp-card"><p class="pwp-lbl">Lead</p><div class="pwp-row"><span class="t">${B.esc(b.lead || 'Nobody')}<span class="s">${b.status === 'open' ? 'Open' : 'Closed'} · opened ${when(b.createdAt)}</span></span></div></section>
          <section class="pwp-card"><p class="pwp-lbl">On the case</p>${officers || '<div class="pwp-empty">Nobody else yet</div>'}${add}</section>
          <section class="pwp-card"><p class="pwp-lbl">Case log</p><div class="pwp-row"><input id="f-caseNote" class="pwp-in" data-bind="caseNote" data-enter="boardNote" value="${val(app, 'caseNote')}" placeholder="What happened, what is next"><span class="acts"><button class="pwp-btn sm pwp-press" data-act="boardNote">Add</button></span></div>${log || '<div class="pwp-empty">No notes yet</div>'}</section>`, 'file') };
      }
      if (s.me.forensics && s.bview === 'locker') {
        const c = s.caseEv;
        const items = c ? c.items.slice().sort((x, y) => evRank(x) - evRank(y)) : [];
        const extra = caseNo + seg + (b.status === 'open' ? `<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="evfile">${B.icons.plus}Add evidence</button>` : '') + '<button class="pwp-btn sm pwp-press" data-act="caseLocker">Open locker</button>';
        const off = c && !c.on ? '<p class="mdt-note">The forensics lab is offline: this is what was filed.</p>' : '';
        return { body: head(b.title, 'closeBoard', extra) + scroll(off + (c ? (items.length ? items.map(evCard).join('') : `<div class="pwp-empty">Nothing filed yet. Use Add evidence, or enter case number ${b.id} at the lab device.</div>`) : ''), 'locker') };
      }
      const pos = new Map((b.items || []).map((i) => [i.id, i]));
      const lines = (b.links || []).map((l) => { const a = pos.get(l.a); const c = pos.get(l.b); return a && c ? `<line data-a="${l.a}" data-b="${l.b}" x1="${a.x + 5.5}" y1="${a.y + 3}" x2="${c.x + 5.5}" y2="${c.y + 3}"/>` : ''; }).join('');
      const pins = (b.items || []).map((i) => `<button class="mdt-pin k-${i.kind} ${s.pinSel === i.id ? 'sel' : ''}" data-act="pin" data-pin="${i.id}" data-key="p${i.id}" style="transform:translate(${i.x}rem,${i.y}rem)"><i>${PINKIND[i.kind] || i.kind}</i><b>${B.esc(i.label)}</b>${i.sub ? `<span>${B.esc(i.sub)}</span>` : ''}</button>`).join('');
      const sel = s.pinSel && pos.get(s.pinSel);
      const bar = s.linking ? `<span class="s">Tap the item to tie to ${B.esc(sel ? sel.label : '')}</span><button class="pwp-btn sm pwp-press" data-act="cancelLink">Cancel</button>`
        : sel ? `${sel.kind !== 'note' ? '<button class="pwp-btn sm pwp-press" data-act="openPin">Open</button>' : ''}<button class="pwp-btn sm pwp-press" data-act="startLink">Tie to…</button><button class="pwp-btn sm pwp-press" data-act="removePin">Unpin</button>`
          : '<span class="s">Drag to arrange. Tap an item to open it or tie it to another.</span>';
      const extra = `${caseNo}${seg}<button class="pwp-btn sm pwp-press" data-act="openSheet" data-k="pin">${B.icons.pin}Pin</button><button class="pwp-btn sm pwp-press" data-act="boardStatus">${b.status === 'open' ? 'Close case' : 'Reopen'}</button>`;
      return { body: head(b.title, 'closeBoard', extra) + `<div class="mdt-boardwrap"><div class="mdt-board" data-scroll="board"><div class="mdt-canvas"><svg class="mdt-strings" viewBox="0 0 120 80" preserveAspectRatio="none">${lines}</svg>${pins}</div></div><div class="mdt-boardbar">${bar}</div></div>` };
    },

    academy(app) {
      const s = app.state; const a = s.academy || {};
      if (s.exam) {
        const done = s.exam.questions.every((q) => s.examAnswers[q.id]);
        const qs = s.exam.questions.map((q, n) => `<section class="pwp-card" data-key="q${q.id}"><p class="pwp-lbl">Question ${n + 1} of ${s.exam.questions.length}</p><p style="margin:0 0 .625rem;font-weight:600">${B.esc(q.text)}</p><div class="mdt-chips">${q.options.map((o, i) => `<button class="mdt-chip ${s.examAnswers[q.id] === i + 1 ? 'on' : ''}" data-act="examPick" data-q="${q.id}" data-i="${i + 1}">${B.esc(o)}</button>`).join('')}</div></section>`).join('');
        return { body: head('Academy exam') + scroll(qs + `<button class="pwp-cta wide pwp-press" data-act="examSubmit" ${done ? '' : 'disabled'}>Hand in the exam</button>`, 'exam') };
      }
      const r = s.examResult || (a.last && { right: a.last.right, total: a.last.total, passed: a.last.passed === 1 || a.last.passed === true });
      const result = r ? `<div class="pwp-row"><span class="t">${r.passed ? 'Passed' : 'Not passed yet'}<span class="s">${r.right} of ${r.total} right</span></span><span class="pwp-flag ${r.passed ? 'ok' : 'warn'}">${Math.round((r.right / r.total) * 100)}%</span></div>` : '<div class="pwp-empty">No exam taken yet</div>';
      const results = a.results ? `<section class="pwp-card"><p class="pwp-lbl">Department results</p>${a.results.length ? a.results.map((x) => `<div class="pwp-row"><span class="t">${B.esc(x.name || ('#' + x.charId))}<span class="s">${when(x.at)}</span></span><span class="num">${x.right}/${x.total}</span><span class="pwp-flag ${x.passed ? 'ok' : 'warn'}">${x.passed ? 'Passed' : 'Failed'}</span></div>`).join('') : '<div class="pwp-empty">Nobody has taken it yet</div>'}</section>` : '';
      const mine = s.me && s.me.academy ? `<section class="pwp-card"><p class="pwp-lbl">Your exam</p>${result}<p class="mdt-note" style="margin:.625rem 0">${a.questions || 10} questions on the penal code and how this department works. ${Math.round((a.pass || 0.8) * 100)}% to pass.</p>${r && r.passed ? '' : '<button class="pwp-cta wide pwp-press" data-act="examStart">Start the exam</button>'}</section>` : '';
      return { body: head('Academy') + scroll(mine + results, 'academy') };
    },

    wanted(app) {
      const s = app.state; const pm = perms(app);
      const w = s.warrants || []; const b = s.bolos || [];
      return { body: head('Wanted') + scroll(`
        <section class="pwp-card"><p class="pwp-lbl">Warrants</p>${w.length ? w.map((x) => `<div class="pwp-row"><span class="pwp-code">${x.charId}</span><button class="t" style="text-align:left" data-act="openPerson" data-id="${x.charId}">${B.esc(x.name || 'Citizen ' + x.charId)}<span class="s">${B.esc(x.reason)} · until ${when(x.expiresAt)}</span></button>${pm.warrants ? `<span class="acts"><button class="pwp-btn sm pwp-press" data-act="closeWarrant" data-id="${x.id}" data-s="served">Served</button><button class="pwp-btn sm ghost pwp-press" data-act="closeWarrant" data-id="${x.id}" data-s="cancelled">Cancel</button></span>` : ''}</div>`).join('') : '<div class="pwp-empty">No active warrants</div>'}</section>
        <section class="pwp-card"><p class="pwp-lbl">Be on the lookout</p>${b.length ? b.map((x) => `<div class="pwp-row">${x.plate ? `<button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(x.plate)}" title="Copy">${B.esc(x.plate)}</button>` : `<span class="pwp-code">${B.esc(x.charId)}</span>`}<span class="t">${B.esc(x.plate ? 'Vehicle' : (x.name || 'Person'))}<span class="s">${B.esc(x.reason)} · until ${when(x.expiresAt)}</span></span>${pm.records ? `<button class="pwp-btn sm ghost pwp-press" data-act="closeBolo" data-id="${x.id}">Close</button>` : ''}</div>`).join('') : '<div class="pwp-empty">No lookouts out</div>'}</section>`, 'wanted') };
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
      const roster = (s.roster || []).map((o) => `<button class="pwp-row" data-act="openOfficer" data-id="${o.charId}" data-key="ro${o.charId}"><span class="pwp-code">${B.esc(o.callsign || o.charId)}</span><span class="t">${B.esc(o.name || 'Officer')}<span class="s">${B.esc([o.rank, o.hours + ' h this week'].filter(Boolean).join(' · '))}</span></span><span class="pwp-flag ${o.onDuty ? 'ok' : ''}">${o.onDuty ? 'On duty' : 'Off'}</span></button>`).join('');
      const apps = pm.command ? (s.permitApps || []).map((a) => `<div class="pwp-row mdt-wrap" data-key="pa${a.id}"><span class="t">${B.esc(a.name || 'Citizen')} · ${B.esc(a.label)}<span class="s">${B.esc(a.reason)}</span></span><span class="acts"><button class="pwp-btn sm ghost pwp-press" data-act="openSheet" data-k="denyPermit" data-id="${a.id}">Deny</button><button class="pwp-btn sm inv pwp-press" data-act="decidePermit" data-id="${a.id}" data-v="1">Approve</button></span></div>`).join('') : '';
      const IA = { open: ['Open', 'warn'], sustained: ['Sustained', 'danger'], not_sustained: ['Not sustained', ''], unfounded: ['Unfounded', ''], closed: ['Closed', ''] };
      const ia = pm.command ? (s.complaints || []).map((c) => `<button class="pwp-row" data-act="openSheet" data-k="complaint" data-id="${c.id}" data-key="ia${c.id}"><span class="pwp-code">#${c.id}</span><span class="t">${B.esc(c.officer)}<span class="s">${B.esc([c.from, when(c.at)].filter(Boolean).join(' · '))}</span></span><span class="pwp-flag ${(IA[c.status] || ['', ''])[1]}">${(IA[c.status] || [c.status])[0]}</span></button>`).join('') : '';
      const sop = pm.command ? `<section class="pwp-card"><p class="pwp-lbl">Department rules${s.sop && s.sop.version ? ' · version ' + s.sop.version + ' · read by ' + (s.sop.readers || 0) : ''}</p><textarea id="f-sopText" class="pwp-in" data-bind="sopText" style="min-height:8rem" placeholder="The rules every officer reads and signs">${B.esc(s.f.sopText || '')}</textarea><button class="pwp-btn sm pwp-press" data-act="saveSop" style="justify-self:start;margin-top:.5rem">Publish (officers sign again)</button></section>` : '';
      return {
        body: head('Command') + scroll(`<section class="pwp-card"><p class="pwp-lbl">Roster</p>${roster || '<div class="pwp-empty">Nobody hired yet</div>'}</section>`
          + (apps ? `<section class="pwp-card"><p class="pwp-lbl">Permit applications</p>${apps}</section>` : '')
          + (pm.command ? `<section class="pwp-card"><p class="pwp-lbl">Complaints</p>${ia || '<div class="pwp-empty">No complaints</div>'}</section>` : '')
          + sop + prison + (pm.command ? penal : ''), 'command'),
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
      const court = !!(s.me && s.me.courts);
      title = 'Charge ' + s.person.firstName + ' ' + s.person.lastName;
      body = `<label class="pwp-search">${B.icons.search}<input id="f-chargeQ" data-bind="chargeQ" value="${val(app, 'chargeQ')}" placeholder="Find a charge" autocomplete="off"></label>
        <div class="mdt-pick">${list.map((x) => `<div class="pwp-row"><span class="pwp-code">${B.esc(x.code)}</span><span class="t">${B.esc(x.title)}<span class="s"><span class="mdt-cat ${x.category}">${CAT[x.category] || ''}</span> · ${B.money(x.fine)} · ${x.months} mo</span></span><span class="pwp-step"><button data-act="count" data-c="${B.esc(x.code)}" data-d="-1" aria-label="One less">${B.icons.minus}</button><span class="num">${s.charges[x.code] || 0}</span><button data-act="count" data-c="${B.esc(x.code)}" data-d="1" aria-label="One more">${B.icons.plus}</button></span></div>`).join('') || '<div class="pwp-empty">No charge matches</div>'}</div>`;
      foot = `<div class="pwp-tot"><div><small>Fine</small><b class="num">${B.money(t.fine)}</b></div><div><small>Prison</small><b class="num">${t.months} mo</b></div></div>
        ${both ? `<div class="pwp-seg" data-glide="outcome" style="justify-self:start"><button class="${!jail ? 'on' : ''}" data-act="outcome" data-v="fine">Citation</button><button class="${jail ? 'on' : ''}" data-act="outcome" data-v="jail">Arrest</button></div>` : ''}
        <button class="pwp-cta wide pwp-press" data-act="${jail ? (court ? 'book' : 'jail') : 'fine'}" ${(jail ? t.months : t.fine) > 0 ? '' : 'disabled'}>${jail ? (court ? 'Book: ask for a plea' : 'Send to prison') : 'Write citation'}</button>`;
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
        <input id="f-reason" class="pwp-in" data-bind="reason" data-enter="boloPlate" value="${val(app, 'reason')}" placeholder="Why officers should stop it">
        <div class="mdt-chips"><button class="mdt-chip ${s.f.stolen ? 'on' : ''}" data-act="toggleStolen" aria-pressed="${!!s.f.stolen}">Reported stolen</button></div>`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="boloPlate">Issue BOLO</button>`;
    } else if (k === 'pin') {
      title = 'Pin to ' + s.board.title;
      const kk = s.f.pinKind || 'person';
      const res = s.pinRes || [];
      const hint = { person: 'Name or citizen ID', vehicle: 'Plate', report: 'Report title', evidence: 'Serial or a DNA or print code' }[kk];
      body = `<div class="pwp-seg" data-glide="pinkind" style="justify-self:start">${Object.entries(PINKIND).map(([v, l]) => `<button class="${kk === v ? 'on' : ''}" data-act="pinKind" data-v="${v}">${l}</button>`).join('')}</div>
        ${kk === 'note' ? `<input id="f-pinNote" class="pwp-in" data-bind="pinNote" data-enter="pinNote" value="${val(app, 'pinNote')}" placeholder="What to remember, e.g. red van seen twice">`
          : `<label class="pwp-search">${B.icons.search}<input id="f-pinQ" data-bind="pinQ" data-enter="pinSearch" value="${val(app, 'pinQ')}" placeholder="${hint}" autocomplete="off"></label>
        <div class="mdt-pick">${res.map((r, i) => `<div class="pwp-row"><span class="t">${B.esc(r.label)}<span class="s">${B.esc(r.sub || '')}</span></span><button class="pwp-btn sm pwp-press" data-act="pinAdd" data-i="${i}">Pin</button></div>`).join('') || (s.searched ? '<div class="pwp-empty">Nothing matches</div>' : '')}</div>`}`;
      foot = kk === 'note' ? '<button class="pwp-cta wide pwp-press" data-act="pinNote">Pin the note</button>' : '';
    } else if (k === 'evfile') {
      title = 'Add evidence to #' + s.board.id;
      const list = s.upl;
      body = list == null ? '' : list.length ? `<div class="mdt-pick">${list.map((e) => {
        const other = e.case != null && String(e.case) !== String(s.board.id);
        const on = s.uplSel.includes(e.ref);
        return `<button class="pwp-row mdt-pickrow ${on ? 'on' : ''}" data-act="evPick" data-r="${B.esc(e.ref)}" aria-pressed="${on}" aria-disabled="${!e.analysed || other}">${e.marker ? `<span class="pwp-code">${B.esc(e.marker)}</span>` : ''}<span class="t">${B.esc(e.type || e.kind)}<span class="s">${[e.street, e.time].filter(Boolean).map(B.esc).join(' · ')}</span></span>${!e.analysed ? '<span class="pwp-flag">Lab first</span>' : other ? `<span class="pwp-flag">Case #${B.esc(e.case)}</span>` : ''}</button>`;
      }).join('')}</div>` : '<div class="pwp-empty">You carry no bags, photos or guns for a case</div>';
      const n = s.uplSel.length;
      foot = `<button class="pwp-cta wide pwp-press" data-act="fileEvidence" ${n ? '' : 'disabled'}>${n > 1 ? 'File ' + n + ' items' : 'File it'}</button>`;
    } else if (k === 'impound') {
      const f = s.imp;
      title = 'Impound ' + (f.plate || '');
      const reason = (f.reasons || []).find((x) => x.id === s.f.impReason);
      const c = impCost(s);
      const warn = [f.bolo && f.bolo.stolen ? '<span class="pwp-flag danger">Reported stolen</span>' : '', f.bolo ? `<span class="pwp-flag warn">BOLO: ${B.esc(f.bolo.reason)}</span>` : '',
        f.times ? `<span class="pwp-flag">${f.times === 1 ? 'Impounded once before' : 'Impounded ' + f.times + ' times before'}</span>` : ''].join('');
      body = `<div class="pwp-row"><button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(f.plate || '')}" title="Copy">${B.esc(f.plate || '')}</button><span class="t">${B.esc(f.ownerName || 'Owner #' + f.owner)}<span class="s">${B.esc(f.model || '')}${f.via === 'garage' ? ' · in a garage' : ''}</span></span></div>
        ${warn ? `<div class="mdt-warn">${warn}</div>` : ''}
        <p class="pwp-lbl">Reason</p><div class="mdt-chips">${(f.reasons || []).map((x) => `<button class="mdt-chip ${s.f.impReason === x.id ? 'on' : ''}" data-act="impReason" data-v="${B.esc(x.id)}">${B.esc(x.label)}</button>`).join('')}</div>
        ${(f.lots || []).length > 1 ? `<p class="pwp-lbl">Lot</p><div class="pwp-seg" data-glide="implot" style="justify-self:start">${f.lots.map((l) => `<button class="${s.f.impLot === l.id ? 'on' : ''}" data-act="impSet" data-k="impLot" data-v="${B.esc(l.id)}">${B.esc(l.label)}</button>`).join('')}</div>` : ''}
        <input id="f-impFee" class="pwp-in" data-bind="impFee" inputmode="numeric" value="${val(app, 'impFee')}" placeholder="Fee in $, up to ${B.money(f.maxFee)}">
        <div class="pwp-seg" data-glide="imphold" style="justify-self:start">${[['none', 'No hold'], ['days', 'Days'], ['officer', 'Until lifted']].map(([v, l]) => `<button class="${s.f.impHold === v ? 'on' : ''}" data-act="impSet" data-k="impHold" data-v="${v}" ${reason && reason.hold === 'officer' && v !== 'officer' ? 'disabled' : ''}>${l}</button>`).join('')}</div>
        ${s.f.impHold === 'days' ? `<div class="pwp-row"><span class="t">Hold for</span><span class="pwp-step"><button data-act="impDays" data-d="-1" aria-label="One day less">${B.icons.minus}</button><span class="num">${s.f.impDays} d</span><button data-act="impDays" data-d="1" aria-label="One day more">${B.icons.plus}</button></span></div>` : ''}
        <textarea id="f-impNotes" class="pwp-in" data-bind="impNotes" placeholder="Notes: where it was, what was in it">${val(app, 'impNotes')}</textarea>
        <input id="f-impPhoto" class="pwp-in" data-bind="impPhoto" value="${val(app, 'impPhoto')}" placeholder="Photo link (https://...)">
        ${f.tow && f.via === 'street' ? `<div class="mdt-chips"><button class="mdt-chip ${s.f.impTow ? 'on' : ''}" data-act="impTow" aria-pressed="${!!s.f.impTow}">Send a tow truck</button></div>` : ''}
        <div class="mdt-cost"><div><small>Fee</small><b>${B.money(c.fee)}</b></div><div><small>${s.f.impHold === 'days' ? 'At pickup' : 'Per day'}</small><b>${s.f.impHold === 'days' ? B.money(c.pickup) : '+' + B.money(f.perDay)}</b></div><div><small>At most</small><b>${B.money(c.most)}</b></div></div>`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="impoundFile" ${s.f.impReason ? '' : 'disabled'}>${s.f.impTow ? 'Call the tow for ' : 'Impound '}${B.esc(f.plate || '')}</button>`;
    } else if (k === 'pactions') {
      title = 'Actions';
      body = `<div class="mdt-acts">${personActs(app).map(([act, k2, icon, label]) => `<button class="pwp-row pwp-press" data-act="pact" data-a="${act}"${k2 ? ` data-k="${k2}"` : ''}>${B.icons[icon] || B.icons.badge}<span class="t">${label}</span></button>`).join('')}</div>`;
      foot = '';
    } else if (k === 'more') {
      title = 'More';
      body = `<div class="mdt-acts">${navFor(app).slice(NAV_PHONE).map(([id, label, icon]) => `<button class="pwp-row pwp-press ${s.nav === id ? 'on' : ''}" data-act="nav" data-t="${id}">${B.icons[icon]}<span class="t">${label}</span></button>`).join('')}</div>`;
      foot = '';
    } else if (k === 'announce') {
      title = 'Post a notice';
      body = `<textarea id="f-newsText" class="pwp-in" data-bind="newsText" placeholder="What every officer on duty should know">${val(app, 'newsText')}</textarea>
        <div class="mdt-chips"><button class="mdt-chip ${s.f.newsUrgent ? 'on' : ''}" data-act="toggleUrgent" aria-pressed="${!!s.f.newsUrgent}">Urgent</button></div>`;
      foot = '<button class="pwp-cta wide pwp-press" data-act="announce">Post</button>';
    } else if (k === 'officer') {
      const o = s.officer;
      title = o ? (o.name || 'Officer') : 'Officer';
      if (!o) { body = ''; foot = ''; } else {
        const st = o.stats || {};
        body = `<div class="pwp-row"><span class="t">${B.esc(o.rank || '')}<span class="s">${o.onDuty ? 'On duty' : 'Off duty'} · ${o.hours7} h this week · ${o.hours30} h this month</span></span></div>
          <div class="mdt-tiles">${[['reports', 'Reports'], ['tickets', 'Tickets'], ['arrests', 'Arrests'], ['impounds', 'Impounds'], ['calls', 'Calls closed'], ['complaints', 'Complaints held']].map(([k2, l]) => `<div><b>${st[k2] || 0}</b><small>${l}</small></div>`).join('')}</div>
          <p class="pwp-lbl" style="margin-top:.5rem">Awards</p>${(o.awards || []).map((a) => `<div class="pwp-row"><span class="t">${B.esc(a.award)}<span class="s">${B.esc([a.note, when(a.at)].filter(Boolean).join(' · '))}</span></span></div>`).join('') || '<div class="pwp-empty">None yet</div>'}
          ${!o.self && pm.command ? `<div class="mdt-chips">${((s.me && s.me.awards) || []).map((a) => `<button class="mdt-chip ${s.f.award === a ? 'on' : ''}" data-act="impSet" data-k="award" data-v="${B.esc(a)}">${B.esc(a)}</button>`).join('')}</div><input id="f-awardNote" class="pwp-in" data-bind="awardNote" value="${val(app, 'awardNote')}" placeholder="What for">` : ''}
          ${o.self && o.sop && o.sop.version ? `<p class="pwp-lbl" style="margin-top:.5rem">Department rules · version ${o.sop.version}</p><pre class="mdt-sop">${B.esc(o.sop.text)}</pre>` : ''}`;
        foot = !o.self && pm.command ? `<button class="pwp-cta wide pwp-press" data-act="giveAward" ${s.f.award ? '' : 'disabled'}>Give the award</button>`
          : o.self && o.sop && o.sop.version && !o.sop.acked ? '<button class="pwp-cta wide pwp-press" data-act="ackSop">I have read the rules</button>' : '';
      }
    } else if (k === 'denyPermit') {
      title = 'Deny the application';
      body = `<input id="f-permitNote" class="pwp-in" data-bind="permitNote" data-enter="denyPermit" value="${val(app, 'permitNote')}" placeholder="Why (the applicant reads it)">`;
      foot = '<button class="pwp-cta wide pwp-press" data-act="denyPermit">Deny</button>';
    } else if (k === 'complaint') {
      const c = (s.complaints || []).find((x) => x.id === s.sheet.id) || {};
      title = 'Complaint #' + (c.id || '');
      body = `<div class="pwp-row"><span class="t">About ${B.esc(c.officer || '')}<span class="s">${B.esc([c.from ? 'from ' + c.from : '', when(c.at)].filter(Boolean).join(' · '))}</span></span></div>
        <pre class="mdt-sop">${B.esc(c.text || '')}</pre>
        <div class="mdt-chips">${[['sustained', 'Sustained'], ['not_sustained', 'Not sustained'], ['unfounded', 'Unfounded'], ['closed', 'Closed']].map(([v, l]) => `<button class="mdt-chip ${s.f.iaStatus === v ? 'on' : ''}" data-act="impSet" data-k="iaStatus" data-v="${v}">${l}</button>`).join('')}</div>
        <input id="f-iaNote" class="pwp-in" data-bind="iaNote" value="${val(app, 'iaNote')}" placeholder="Finding (the person who complained reads it)">`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="reviewComplaint" ${s.f.iaStatus ? '' : 'disabled'}>Save the finding</button>`;
    } else if (k === 'tags') {
      title = 'Tags: ' + s.person.firstName + ' ' + s.person.lastName;
      const on = new Set(s.person.tags || []);
      body = `<div class="mdt-chips">${((s.me && s.me.tags) || []).map((t) => `<button class="mdt-chip ${on.has(t) ? 'on' : ''}" data-act="toggleTag" data-v="${B.esc(t)}" aria-pressed="${on.has(t)}">${B.esc(t)}</button>`).join('')}</div>`;
      foot = '';
    } else if (k === 'licence') {
      const kind = s.sheet.kind2; const label = ((s.me && s.me.licenceKinds) || {})[kind] || kind;
      const l = (s.person.licences || []).find((x) => x.kind === kind);
      const acts = (!l || l.status !== 'valid' ? [['grant', l ? 'Reinstate' : 'Issue']] : []).concat(l && l.status === 'valid' ? [['suspend', 'Suspend'], ['revoke', 'Revoke']] : []).concat(l && l.status === 'suspended' ? [['revoke', 'Revoke']] : []);
      title = label + ': ' + s.person.firstName + ' ' + s.person.lastName;
      body = `<div class="pwp-seg" data-glide="licact" style="justify-self:start">${acts.map(([v, l2]) => `<button class="${s.f.licAct === v ? 'on' : ''}" data-act="impSet" data-k="licAct" data-v="${v}">${l2}</button>`).join('')}</div>
        ${s.f.licAct === 'suspend' ? `<div class="pwp-row"><span class="t">Suspend for</span><span class="pwp-step"><button data-act="licDays" data-d="-1" aria-label="One day less">${B.icons.minus}</button><span class="num">${s.f.licDays} d</span><button data-act="licDays" data-d="1" aria-label="One day more">${B.icons.plus}</button></span></div>` : ''}
        <input id="f-licNote" class="pwp-in" data-bind="licNote" value="${val(app, 'licNote')}" placeholder="${s.f.licAct === 'grant' ? 'Note (optional)' : 'Why (the holder reads it)'}">`;
      foot = `<button class="pwp-cta wide pwp-press" data-act="licence" ${s.f.licAct ? '' : 'disabled'}>Save</button>`;
    } else if (k === 'closeCall') {
      const c = (s.calls || []).find((x) => x.id === s.sheet.id) || {};
      title = 'Close ' + (c.code || 'the call');
      body = `<p class="mdt-note" style="margin:0">${B.esc(c.title || '')}</p>
        <div class="mdt-chips">${OUTCOME.map(([v, l]) => `<button class="mdt-chip ${s.f.outcome === v ? 'on' : ''}" data-act="pickOutcome" data-v="${v}" aria-pressed="${s.f.outcome === v}">${l}</button>`).join('')}</div>
        <input id="f-callNote" class="pwp-in" data-bind="callNote" data-enter="closeCall" value="${val(app, 'callNote')}" placeholder="Note for the log (optional)">`;
      foot = '<button class="pwp-cta wide pwp-press" data-act="closeCall">Close the call</button>';
    } else if (k === 'lift') {
      title = 'Lift the hold';
      const c = ((s.lot || {}).rows || []).find((x) => x.id === s.sheet.id) || {};
      body = `<div class="pwp-row"><button class="pwp-plate mdt-cp" data-act="copy" data-v="${B.esc(c.plate || '')}" title="Copy">${B.esc(c.plate || '')}</button><span class="t">${B.esc(c.reason || '')}<span class="s">${c.heldUntil ? 'Held to ' + B.esc(when(c.heldUntil)) : 'Held until lifted'}</span></span></div>
        <input id="f-liftNote" class="pwp-in" data-bind="liftNote" data-enter="liftHold" value="${val(app, 'liftNote')}" placeholder="Why it goes early (logged)">`;
      foot = '<button class="pwp-cta wide pwp-press" data-act="liftHold">Lift the hold</button>';
    } else if (k === 'statement') {
      const f = ((s.person || {}).fines || []).find((x) => x.id === s.sheet.id) || {};
      title = 'Statement on ' + (f.number || '');
      body = `${f.contestReason ? `<p class="pwp-lbl">They say</p><p class="mdt-note" style="margin:0">${B.esc(f.contestReason)}</p>` : ''}
        <textarea id="f-stmt" class="pwp-in" data-bind="stmt" placeholder="What you saw, for the court">${B.esc(s.f.stmt != null ? s.f.stmt : f.statement || '')}</textarea>`;
      foot = '<button class="pwp-cta wide pwp-press" data-act="ticketStatement">Send to the court</button>';
    } else if (k === 'photo') {
      title = 'Crime scene photo';
      const img = (s.photos || {})[s.sheet.photoId];
      body = img ? `<img class="mdt-photo" src="${B.esc(img)}" alt="Crime scene photo">` : '<div class="mdt-photo" style="aspect-ratio:16/9"></div>';
      foot = '';
    } else if (k === 'case') {
      title = 'New investigation';
      body = `<input id="f-caseTitle" class="pwp-in" data-bind="caseTitle" data-enter="newCase" value="${val(app, 'caseTitle')}" placeholder="Name it, e.g. Strawberry 24/7 robberies">`;
      foot = '<button class="pwp-cta wide pwp-press" data-act="newCase">Open the investigation</button>';
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
    const all = navFor(app);
    const extra = phone && all.length > NAV_PHONE + 1 ? all.slice(NAV_PHONE) : [];
    const shownNav = extra.length ? all.slice(0, NAV_PHONE) : all;
    const navBtn = ([id, label, icon]) => `<button class="${s.nav === id ? 'on' : ''}" data-act="nav" data-t="${id}" aria-current="${s.nav === id ? 'page' : 'false'}">${B.icons[icon]}${label}${phone && id === 'dispatch' && s.nav !== 'dispatch' && callCount ? `<span class="n">${callCount}</span>` : ''}</button>`;
    const moreOn = extra.some(([id]) => id === s.nav);
    const nav = `<nav class="mdt-nav" data-glide="nav" aria-label="Sections">${shownNav.map(navBtn).join('')}${extra.length ? `<button class="${moreOn ? 'on' : ''}" data-act="openSheet" data-k="more" aria-current="${moreOn ? 'page' : 'false'}">${B.icons.more || B.icons.list}More</button>` : ''}</nav>`;
    const findOpen = !phone || s.findOpen || !!s.f.q;
    const top = `<header class="mdt-top"><button class="mdt-cs mdt-me" data-act="openOfficer" title="My profile">${B.esc(me.callsign || '')}</button><div class="mdt-who"><b>${B.esc(me.name || '')}</b><span>${B.esc([me.rank, me.short].filter(Boolean).join(' · '))}</span></div>
      ${statusSeg(app)}<button class="mdt-find pwp-press ${findOpen ? 'on' : ''}" data-act="toggleFind" aria-label="Search" aria-pressed="${findOpen}">${B.icons.search}</button>
      ${findOpen ? `<label class="pwp-search">${B.icons.search}<input id="f-q" data-bind="q" data-enter="search" value="${val(app, 'q')}" placeholder="Search name, ID, plate, report # or evidence" autocomplete="off">${phone ? '' : '<span class="pwp-kbd">/</span>'}</label>` : ''}</header>`;
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
    map.setBolos(r.bolos || []);
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

  const shrinkRecord = (root) => {
    const box = root.querySelector('.mdt.ph [data-scroll^="person-"]');
    const rec = root.querySelector('.mdt.ph .mdt-rec');
    if (box && rec) rec.classList.toggle('min', box.scrollTop > 24);
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
    shrinkRecord(root);
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

  const loadEv = (app) => ask(app, 'caseEvidence', { id: app.state.board.id }, (r) => { app.state.caseEv = r; }, true);
  const reloadBoard = (app) => ask(app, 'board', { id: app.state.board.id }, (r) => { app.state.board = r; }, true);
  const tie = async (app, a, b) => {
    const s = app.state;
    const l = s.board.links.find((x) => (x.a === a && x.b === b) || (x.a === b && x.b === a));
    if (l) s.board.links = s.board.links.filter((x) => x !== l); else s.board.links.push({ id: 0, a, b });
    s.pinSel = b;
    draw(app);
    await ask(app, 'boardLink', { a, b }, null, true);
  };

  const openImpound = (app, form) => {
    const s = app.state;
    s.imp = form; s.err = null;
    s.f.impReason = null; s.f.impFee = ''; s.f.impHold = 'none'; s.f.impTow = false; s.f.impDays = 1; s.f.impNotes = ''; s.f.impPhoto = '';
    s.f.impLot = ((form.lots || [])[0] || {}).id;
    s.sheet = { kind: 'impound' };
  };
  const loadMug = (app, id) => ask(app, 'mugshotImage', { charId: id }, (r) => { const s = app.state; s.mugs = s.mugs || {}; if (r && r.image) s.mugs[id] = r.image; }, true).then(() => draw(app));
  const reloadPerson = (app, id) => ask(app, 'person', { charId: id }, (r) => { app.state.person = r; if (r && r.mugshot && !(app.state.mugs || {})[id]) loadMug(app, id); });

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
    async closeCall(app) {
      const s = app.state; const id = s.sheet.id;
      s.calls = (s.calls || []).filter((c) => c.id !== id);
      if (s.pick === id) s.pick = null;
      const outcome = s.f.outcome || 'resolved'; const note = s.f.callNote || '';
      s.sheet = null; s.f.callNote = '';
      await ask(app, 'clearCall', { id, outcome, note }, () => load(app));
    },
    pickOutcome(app, d) { app.state.f.outcome = d.v; },
    toggleUrgent(app) { app.state.f.newsUrgent = !app.state.f.newsUrgent; },
    async announce(app) {
      const s = app.state;
      await ask(app, 'announce', { text: s.f.newsText || '', urgent: !!s.f.newsUrgent, hours: 24 }, async () => { s.sheet = null; app.toast('Notice posted'); await load(app); });
    },
    async endNews(app, d) { const s = app.state; s.news = (s.news || []).filter((n) => n.id !== Number(d.id)); await ask(app, 'endNews', { id: Number(d.id) }, null, true); },
    async openOfficer(app, d) {
      const s = app.state; s.officer = null; s.f.award = null; s.f.awardNote = '';
      s.sheet = { kind: 'officer' };
      draw(app);
      await ask(app, 'officer', d && d.id ? { charId: Number(d.id) } : {}, (r) => { s.officer = r; });
    },
    async giveAward(app) {
      const s = app.state; const o = s.officer;
      await ask(app, 'award', { charId: o.charId, award: s.f.award, note: s.f.awardNote || '' }, async () => { app.toast('Award given'); await actions.openOfficer(app, { id: o.charId }); });
    },
    async ackSop(app) { const s = app.state; await ask(app, 'ackSop', {}, async () => { app.toast('Signed'); await actions.openOfficer(app, {}); }); },
    async saveSop(app) { const s = app.state; await ask(app, 'setSop', { text: s.f.sopText || '' }, async () => { app.toast('Rules published'); await load(app); }); },
    async decidePermit(app, d) {
      const s = app.state; const id = Number(d.id);
      s.permitApps = (s.permitApps || []).filter((a) => a.id !== id);
      draw(app);
      await ask(app, 'decidePermit', { id, approve: true }, () => app.toast('Approved'));
      await load(app);
    },
    async denyPermit(app) {
      const s = app.state; const id = s.sheet.id;
      await ask(app, 'decidePermit', { id, approve: false, note: s.f.permitNote || '' }, async () => { s.sheet = null; app.toast('Denied'); await load(app); });
    },
    async reviewComplaint(app) {
      const s = app.state;
      await ask(app, 'reviewComplaint', { id: s.sheet.id, status: s.f.iaStatus, note: s.f.iaNote || '' }, async () => { s.sheet = null; app.toast('Finding saved'); await load(app); });
    },
    async weaponStatus(app, d) {
      const s = app.state;
      await ask(app, 'weaponStatus', { serial: d.serial, status: d.v }, async () => {
        app.toast('Marked ' + d.v);
        await ask(app, 'weapon', { serial: d.serial }, (r) => { if (s.results) s.results.weapon = r && r.weapon; });
      });
    },
    async mugshot(app) { const p = app.state.person; await ask(app, 'mugshot', { charId: p.charId }, () => app.toast('Hold still...')); },
    async toggleTag(app, d) {
      const s = app.state; const p = s.person; const tags = new Set(p.tags || []); const on = !tags.has(d.v);
      if (on) tags.add(d.v); else tags.delete(d.v);
      p.tags = [...tags].sort();
      draw(app);
      const r = await ask(app, 'setTag', { charId: p.charId, tag: d.v, on }, null, true);
      if (r === null) await reloadPerson(app, p.charId);
    },
    licDays(app, d) { const s = app.state; s.f.licDays = Math.max(1, Math.min(90, (Number(s.f.licDays) || 7) + Number(d.d))); },
    async licence(app) {
      const s = app.state; const p = s.person;
      await ask(app, 'licence', { charId: p.charId, kind: s.sheet.kind2, act: s.f.licAct, days: s.f.licDays, note: s.f.licNote || '' },
        async () => { s.sheet = null; app.toast('Licence updated'); await reloadPerson(app, p.charId); });
    },
    dview(app, d) { app.state.dview = d.v; if (d.v !== 'map') app.state.pick = null; if (d.v === 'board' || d.v === 'log') load(app); },
    async watch(app, d) { await ask(app, 'watch', d.k === 'cam' ? { kind: 'cam', id: Number(d.id) } : { kind: 'unit', target: Number(d.id) }); },
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
      const out = { people: [], vehicles: [], reports: [], evidence: { rows: [] } };
      await ask(app, 'people', { q }, (r) => { out.people = r || []; });
      if (q.length <= 8) await ask(app, 'vehicles', { q }, (r) => { out.vehicles = r || []; });
      await ask(app, 'reports', { q }, (r) => { out.reports = r || []; });
      if (/^\S{6,32}$/.test(q)) await ask(app, 'evidence', { q }, (r) => { out.evidence = r || { rows: [] }; });
      if (/^[\w-]{5,32}$/.test(q)) await ask(app, 'weapon', { serial: q }, (r) => { out.weapon = r && r.weapon; });
      s.results = out;
      if (out.people.length === 1 && !out.vehicles.length && !out.reports.length && !out.evidence.rows.length && !(out.evidence.cases || []).length && !out.evidence.owner && !out.weapon) await actions.openPerson(app, { id: out.people[0].charId });
    },
    async openPerson(app, d) {
      const s = app.state;
      s.nav = 'records'; s.edit = null; s.charges = {}; s.rtab = 'overview'; s.sheet = null;
      await reloadPerson(app, Number(d.id));
    },
    closePerson(app) { app.state.person = null; app.state.charges = {}; },
    async takeSamples(app) {
      const p = app.state.person;
      await ask(app, 'takeSamples', { charId: p.charId }, async () => { app.toast(app.state.me.forensics ? 'Fingerprints taken' : 'Prints and DNA taken'); await reloadPerson(app, p.charId); });
    },
    async evWaypoint(app, d) { await ask(app, 'waypoint', { x: Number(d.x), y: Number(d.y) }, () => app.toast('Waypoint set')); },
    rtab(app, d) { app.state.rtab = d.t; app.state.fadeTab = true; },
    openSheet(app, d) {
      const s = app.state;
      if (d.k === 'charge' && !(perms(app).fine || perms(app).jail)) return;
      s.err = null;
      s.sheet = { kind: d.k };
      if (d.k === 'plate') s.f.plate = d.plate || '';
      if (d.k === 'bolo' || d.k === 'warrant' || d.k === 'plate') s.f.reason = '';
      if (d.k === 'announce') { s.f.newsText = ''; s.f.newsUrgent = false; }
      if (d.k === 'denyPermit' || d.k === 'complaint') { s.sheet.id = Number(d.id); s.f.permitNote = ''; s.f.iaStatus = null; s.f.iaNote = ''; }
      if (d.k === 'licence') { s.sheet.kind2 = d.v; const l = (s.person.licences || []).find((x) => x.kind === d.v); s.f.licAct = !l || l.status !== 'valid' ? 'grant' : 'suspend'; s.f.licDays = 7; s.f.licNote = ''; }
      if (d.k === 'closeCall') { s.sheet.id = Number(d.id); s.f.outcome = 'resolved'; s.f.callNote = ''; }
      if (d.k === 'lift' || d.k === 'statement') { s.sheet.id = Number(d.id); s.f.liftNote = ''; s.f.stmt = null; }
      if (d.k === 'evfile') { s.upl = null; s.uplSel = []; ask(app, 'uploadable', {}, (r) => { s.upl = r || []; }, true).then(() => draw(app)); }
      if (d.k === 'penal' && !d.keep) { s.f.pCode = s.f.pTitle = s.f.pFine = s.f.pMonths = ''; s.f.pCat = 'misdemeanor'; }
    },
    closeSheet(app) { closeSheet(app); return 'skip'; },
    toggleFind(app) {
      const s = app.state; s.findOpen = !s.findOpen;
      if (s.findOpen) setTimeout(() => { const ctx = live.get(app); const i = ctx && ctx.el.querySelector('#f-q'); if (i) i.focus(); }, 0);
    },
    pact(app, d) {
      const s = app.state; s.sheet = null;
      return actions[d.a](app, d);
    },
    count(app, d) { const c = app.state.charges; c[d.c] = Math.max(0, Math.min(20, (c[d.c] || 0) + Number(d.d))); },
    outcome(app, d) { app.state.outcome = d.v; },
    async fine(app) {
      const p = app.state.person;
      await ask(app, 'fine', { charId: p.charId, charges: chargeList(app) }, async (r) => { app.toast('Fined ' + B.money(r.amount)); app.state.charges = {}; app.state.sheet = null; await reloadPerson(app, p.charId); });
    },
    async book(app) {
      const p = app.state.person;
      await ask(app, 'book', { charId: p.charId, charges: chargeList(app) }, () => { app.toast('Asking ' + p.firstName + ' for a plea'); app.state.charges = {}; app.state.sheet = null; });
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
      await ask(app, 'issueWarrant', { charId: p.charId, reason: app.state.f.reason || '' }, async (r) => { app.state.sheet = null; app.toast(r && r.requested ? 'Sent to a judge to sign' : 'Warrant issued'); await reloadPerson(app, p.charId); });
    },
    async boloPlate(app) {
      await ask(app, 'addBolo', { plate: app.state.f.plate || '', reason: app.state.f.reason || '', stolen: !!app.state.f.stolen }, () => { app.state.sheet = null; app.state.f.stolen = false; app.toast('Lookout issued'); });
    },
    async openBoard(app, d) { const s = app.state; s.pinSel = null; s.linking = false; s.caseEv = null; await ask(app, 'board', { id: Number(d.id) }, (r) => { s.board = r; }); },
    async closeBoard(app) { const s = app.state; s.board = null; s.pinSel = null; s.linking = false; s.bview = 'board'; s.caseEv = null; ask(app, 'boardLeave', {}, null, true); await load(app); },
    async newCase(app) { const s = app.state; await ask(app, 'boardNew', { title: s.f.caseTitle || '' }, async (r) => { s.f.caseTitle = ''; s.sheet = null; await actions.openBoard(app, { id: r.id }); }); },
    pinKind(app, d) { const s = app.state; s.f.pinKind = d.v; s.pinRes = []; s.searched = false; },
    async pinSearch(app) {
      const s = app.state; const q = String(s.f.pinQ || '').trim(); const kk = s.f.pinKind || 'person';
      if (!q) return;
      if (kk === 'person') await ask(app, 'people', { q }, (r) => { s.pinRes = (r || []).map((p) => ({ ref: p.charId, label: p.firstName + ' ' + p.lastName, sub: 'ID ' + p.charId + ' · born ' + day(p.dateOfBirth) })); });
      else if (kk === 'vehicle') await ask(app, 'vehicles', { q }, (r) => { s.pinRes = (r || []).map((v) => ({ ref: v.plate, label: v.plate, sub: v.model + (v.owner ? ' · ' + v.owner : '') })); });
      else if (kk === 'report') await ask(app, 'reports', { q }, (r) => { s.pinRes = (r || []).map((x) => ({ ref: x.id, label: x.title, sub: 'Report #' + x.id })); });
      else await ask(app, 'evidence', { q }, (r) => {
        const rows = (r && r.rows) || [];
        s.pinRes = rows.map((e) => ({ ref: e.code || e.serial, label: (EVKIND[e.kind] || e.kind) + ' ' + (e.code || e.serial || ''), sub: [e.gunName, e.ownerName].filter(Boolean).join(' · ') }));
        for (const c of (r && r.cases) || []) s.pinRes.push({ ref: c.ref, label: c.type || c.kind, sub: 'Filed in #' + c.caseId });
        if (r && r.owner) s.pinRes.unshift({ ref: q, label: q.toUpperCase(), sub: 'Belongs to ' + (r.ownerName || 'a person on file') });
      });
      s.searched = true;
    },
    async pinAdd(app, d) {
      const s = app.state; const r = (s.pinRes || [])[Number(d.i)];
      if (!r) return;
      await ask(app, 'boardAdd', { id: s.board.id, kind: s.f.pinKind || 'person', ref: r.ref, label: r.label, sub: r.sub }, async () => { s.sheet = null; s.pinRes = []; s.f.pinQ = ''; s.searched = false; await reloadBoard(app); });
    },
    async pinNote(app) { const s = app.state; await ask(app, 'boardAdd', { id: s.board.id, kind: 'note', label: s.f.pinNote || '' }, async () => { s.sheet = null; s.f.pinNote = ''; await reloadBoard(app); }); },
    pin(app, d) {
      const s = app.state; const id = Number(d.pin);
      const ctx = live.get(app);
      const n = ctx && ctx.el.querySelector(`[data-pin="${id}"]`);
      if (n && n.dataset.moved) { delete n.dataset.moved; return 'skip'; }
      if (s.linking && s.pinSel && s.pinSel !== id) { const a = s.pinSel; s.linking = false; tie(app, a, id); return 'skip'; }
      s.pinSel = s.pinSel === id ? null : id;
    },
    pinMoved(app, d) {
      const s = app.state; const it = (s.board.items || []).find((i) => i.id === Number(d.id));
      if (it) ask(app, 'boardMove', { itemId: it.id, x: Math.round(it.x * 100) / 100, y: Math.round(it.y * 100) / 100 }, null, true);
      return 'skip';
    },
    startLink(app) { app.state.linking = true; },
    cancelLink(app) { app.state.linking = false; },
    async removePin(app) {
      const s = app.state; const id = s.pinSel;
      s.board.items = s.board.items.filter((i) => i.id !== id);
      s.board.links = s.board.links.filter((l) => l.a !== id && l.b !== id);
      s.pinSel = null;
      draw(app);
      await ask(app, 'boardRemove', { itemId: id }, null, true);
    },
    async openPin(app) {
      const s = app.state; const it = (s.board.items || []).find((i) => i.id === s.pinSel);
      if (!it) return;
      if (it.kind === 'person') return actions.openPerson(app, { id: it.ref });
      if (it.kind === 'report') return actions.openReport(app, { id: it.ref });
      s.f.q = String(it.ref);
      return actions.search(app);
    },
    async boardStatus(app) { const s = app.state; const st = s.board.status === 'open' ? 'closed' : 'open'; s.board.status = st; draw(app); await ask(app, 'boardStatus', { id: s.board.id, status: st }, (r) => { if (r && r.warn) app.toast(r.warn); }, true); },
    bview(app, d) { const s = app.state; s.bview = d.v; if (d.v === 'locker') return loadEv(app); if (d.v === 'file') return ask(app, 'calls', {}, (r) => { s.units = r.units; }, true); },
    async boardAssign(app, d) {
      const s = app.state; const on = d.on === '1'; const charId = Number(d.id);
      await ask(app, 'boardAssign', { id: s.board.id, charId, on }, () => reloadBoard(app));
    },
    async boardNote(app) {
      const s = app.state; const text = s.f.caseNote || '';
      if (!text.trim()) return 'skip';
      s.f.caseNote = '';
      await ask(app, 'boardNote', { id: s.board.id, text }, () => reloadBoard(app));
    },
    async openCase(app, d) { const s = app.state; s.nav = 'boards'; s.person = null; s.edit = null; s.sheet = null; await actions.openBoard(app, d); if (s.board) { s.bview = 'locker'; await loadEv(app); } },
    evPick(app, d) {
      const s = app.state; const e = (s.upl || []).find((x) => x.ref === d.r);
      if (!e || !e.analysed || (e.case != null && String(e.case) !== String(s.board.id))) return 'skip';
      s.uplSel = s.uplSel.includes(d.r) ? s.uplSel.filter((x) => x !== d.r) : s.uplSel.concat(d.r);
    },
    async fileEvidence(app) {
      const s = app.state;
      await ask(app, 'fileEvidence', { id: s.board.id, refs: s.uplSel.slice() }, async (r) => {
        s.sheet = null; s.uplSel = [];
        const why = r.failed.map((f) => f.why).filter(Boolean)[0];
        if (why) s.err = r.done ? `${r.failed.length} not filed: ${why}` : why;
        if (r.done) app.toast(r.done === 1 ? 'Filed' : r.done + ' items filed');
        await loadEv(app);
      });
    },
    async caseLocker(app) { await ask(app, 'caseLocker', { id: app.state.board.id }, () => app.toast('Locker open')); },
    async evPhoto(app, d) {
      const s = app.state; const pid = d.p;
      s.photos = s.photos || {};
      s.sheet = { kind: 'photo', photoId: pid };
      if (s.photos[pid]) return;
      draw(app);
      const chunks = [];
      for (let i = 1, parts = 1; i <= parts; i += 1) {
        const r = await ask(app, 'casePhoto', { id: s.board.id, photoId: pid, part: i }, null, true);
        if (!r) return;
        parts = r.parts; chunks.push(r.data);
      }
      s.photos[pid] = chunks.join('');
    },
    lotPick(app, d) { app.state.lotPick = d.v || null; return load(app); },
    toggleStolen(app) { app.state.f.stolen = !app.state.f.stolen; },
    async impoundForm(app, d) {
      await ask(app, 'impoundPreview', { vehicleId: Number(d.id) }, (r) => { if (r) openImpound(app, { ...r, via: 'garage' }); });
    },
    impReason(app, d) {
      const s = app.state; const r = (s.imp.reasons || []).find((x) => x.id === d.v);
      if (!r) return;
      s.f.impReason = r.id; s.f.impFee = String(r.fee || 0);
      s.f.impHold = r.hold === 'officer' ? 'officer' : (r.holdDays ? 'days' : 'none');
      s.f.impDays = r.holdDays || 1;
    },
    impSet(app, d) { app.state.f[d.k] = d.v; },
    impTow(app) { app.state.f.impTow = !app.state.f.impTow; },
    impDays(app, d) { const s = app.state; s.f.impDays = Math.max(1, Math.min(s.imp.maxHoldDays || 30, (Number(s.f.impDays) || 1) + Number(d.d))); },
    async impoundFile(app) {
      const s = app.state; const f = s.imp;
      const spec = { vehicleId: f.vehicleId, via: f.via, reason: s.f.impReason, lot: s.f.impLot,
        fee: Number(String(s.f.impFee || '').replace(/[^0-9]/g, '')) || 0, holdOpen: s.f.impHold === 'officer',
        holdDays: s.f.impHold === 'days' ? Number(s.f.impDays) || 0 : 0, notes: s.f.impNotes || '', photo: s.f.impPhoto || '', tow: !!s.f.impTow };
      await ask(app, 'impoundFile', { spec }, (r) => {
        s.sheet = null; s.imp = null;
        app.toast((r.tow ? 'Tow truck called for ' : 'Impounded ') + (r.plate || '') + (r.bolo ? ' · BOLO closed' : ''));
        if (app.forced) app.done({ filed: true });
        else load(app);
      });
    },
    async liftHold(app) {
      const s = app.state; const id = s.sheet.id;
      await ask(app, 'liftHold', { id, note: s.f.liftNote || '' }, async () => { s.sheet = null; app.toast('Hold lifted'); await load(app); });
    },
    async ticketStatement(app) {
      const s = app.state; const id = s.sheet.id; const f = s.person.fines.find((x) => x.id === id) || {};
      await ask(app, 'ticketStatement', { id, text: s.f.stmt != null ? s.f.stmt : f.statement || '' }, async () => { s.sheet = null; app.toast('Statement sent'); await reloadPerson(app, s.person.charId); });
    },
    async voidTicket(app, d) {
      const s = app.state;
      await ask(app, 'voidTicket', { id: Number(d.id) }, async () => { app.toast('Voided'); await reloadPerson(app, s.person.charId); });
    },
    copy(app, d) { copyText(app, d.v || ''); app.toast('Copied'); return 'skip'; },
    async examStart(app) { const s = app.state; s.examResult = null; await ask(app, 'examStart', {}, (r) => { s.exam = r; s.examAnswers = {}; }); },
    examPick(app, d) { app.state.examAnswers[Number(d.q)] = Number(d.i); },
    async examSubmit(app) {
      const s = app.state;
      await ask(app, 'examSubmit', { answers: s.examAnswers }, (r) => { s.exam = null; s.examResult = r; app.toast(r.passed ? 'Passed the academy' : 'Not passed: study the penal code and try again'); });
      await load(app);
    },
    async closeWarrant(app, d) {
      await ask(app, 'closeWarrant', { id: Number(d.id), status: d.s }, async () => { if (app.state.person) await reloadPerson(app, app.state.person.charId); else await load(app); });
    },
    async closeBolo(app, d) { await ask(app, 'closeBolo', { id: Number(d.id) }, () => load(app)); },
    newReport(app) { app.state.edit = { title: '', body: '', status: 'open', people: [], charges: [], plates: [] }; },
    useTemplate(app, d) {
      const s = app.state; const t = ((s.me && s.me.templates) || [])[Number(d.i)];
      if (!t || !s.edit) return;
      s.edit.title = t.title || ''; s.edit.body = t.body || '';
    },
    addPlate(app) {
      const s = app.state; const plate = String(s.f.addPlate || '').trim().toUpperCase();
      if (!plate) { s.err = 'Type the plate first'; return; }
      s.edit.plates = (s.edit.plates || []).filter((x) => x !== plate).concat(plate); s.f.addPlate = '';
    },
    removePlate(app, d) { const s = app.state; s.edit.plates = (s.edit.plates || []).filter((_, i) => i !== Number(d.i)); },
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
      await ask(app, 'saveReport', { id: r.id, rev: r.rev, title: r.title, body: r.body, status: r.status, people: r.people, charges: r.charges, plates: r.plates || [] },
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

  const dragPins = (app, el) => {
    el.addEventListener('pointerdown', (e) => {
      const p = e.target.closest('.mdt-pin');
      if (!p || e.button !== 0 || !app.state.board) return;
      const canvas = p.parentElement;
      const it = (app.state.board.items || []).find((i) => i.id === Number(p.dataset.pin));
      if (!it) return;
      const unit = canvas.getBoundingClientRect().width / 120;
      const sx = e.clientX; const sy = e.clientY; const ox = it.x; const oy = it.y;
      let moved = false;
      const move = (ev) => {
        if (!moved && Math.hypot(ev.clientX - sx, ev.clientY - sy) < 4) return;
        moved = true;
        p.classList.add('drag');
        it.x = Math.max(0, Math.min(109, ox + (ev.clientX - sx) / unit));
        it.y = Math.max(0, Math.min(74, oy + (ev.clientY - sy) / unit));
        p.style.transform = `translate(${it.x}rem,${it.y}rem)`;
        canvas.querySelectorAll(`line[data-a="${it.id}"],line[data-b="${it.id}"]`).forEach((ln) => {
          const end = Number(ln.dataset.a) === it.id ? '1' : '2';
          ln.setAttribute('x' + end, it.x + 5.5);
          ln.setAttribute('y' + end, it.y + 3);
        });
      };
      const up = () => {
        p.removeEventListener('pointermove', move); p.removeEventListener('pointerup', up); p.removeEventListener('pointercancel', up);
        p.classList.remove('drag');
        if (moved) { p.dataset.moved = '1'; run(app, 'pinMoved', { id: String(it.id) }); }
      };
      try { p.setPointerCapture(e.pointerId); } catch { }
      p.addEventListener('pointermove', move); p.addEventListener('pointerup', up); p.addEventListener('pointercancel', up);
    });
  };

  const wire = (app, el) => {
    dragPins(app, el);
    el.addEventListener('scroll', (e) => { if (e.target.dataset && /^person-/.test(e.target.dataset.scroll || '')) shrinkRecord(el); }, true);
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
      if (view && view.size === 'phone' && !app.forced && typeof app.fold === 'function') app.fold();
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
    async open(app, args) {
      await ask(app, 'me', {}, (r) => { app.state.me = r; });
      if (!app.state.me) return;
      if (args && args.impound) { app.state.nav = 'records'; openImpound(app, args.impound); }
      await load(app);
    },
    back(app) {
      const s = app.state;
      if (s.sheet && s.sheet.kind === 'impound' && app.forced) { s.sheet = null; app.done({ filed: false }); return true; }
      if (s.sheet) { closeSheet(app); return true; }
      if (s.pick != null) { s.pick = null; draw(app); return true; }
      if (s.edit) { s.edit = null; load(app); draw(app); return true; }
      if (s.person) { s.person = null; draw(app); return true; }
      if (s.nav !== 'dispatch') { s.nav = 'dispatch'; load(app); draw(app); return true; }
      return false;
    },
    on: {
      alert(app, a) { const s = app.state; s.calls = [a].concat((s.calls || []).filter((c) => c.id !== a.id)); draw(app); },
      news(app) { const s = app.state; if (s.nav === 'dispatch') ask(app, 'news', {}, (r) => { s.news = r || []; draw(app); }, true); },
      mugshot(app, d) { const s = app.state; if (s.mugs) delete s.mugs[d.charId]; if (s.person && s.person.charId === d.charId) loadMug(app, d.charId); },
      board(app, d) { const s = app.state; if (s.board && s.board.id === d.id) Promise.all([reloadBoard(app), s.bview === 'locker' ? loadEv(app) : null]).then(() => draw(app)); },
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
