(() => {
  /* In-car terminal: graphite chassis, amber CAD accent. Records print as a light booking sheet with a stamp.
     Tablet: rail (unit plate, status, sections) + work area. Phone: plate bar + wrapping section chips + work area. */
  const FONTS = `
@font-face{font-family:'PWP Barlow';font-weight:600;font-style:normal;src:url(fonts/BarlowCondensed-600.woff2) format('woff2')}
@font-face{font-family:'PWP Barlow';font-weight:700;font-style:normal;src:url(fonts/BarlowCondensed-700.woff2) format('woff2')}
@font-face{font-family:'PWP Plex';font-weight:400 700;font-style:normal;src:url(fonts/IBMPlexSans.woff2) format('woff2')}
@font-face{font-family:'PWP Mono';font-weight:500;font-style:normal;src:url(fonts/IBMPlexMono-500.woff2) format('woff2')}`;

  const CSS = `
:host{
  --chassis:#101215; --panel:#181b20; --panel2:#20242b; --line:#2b3038; --text:#e8ebf0; --mute:#929baa;
  --amber:#f2a93b; --amber-ink:#1c1405; --ok:#3fb97a; --route:#5b9bff; --red:#e5484d; --busy:#a3acb9;
  --paper:#eceff3; --paper-ink:#172230; --paper-mute:#566476; --paper-line:#c6ced8; --stamp:#c8323c;
  --display:'PWP Barlow','Barlow Condensed','Arial Narrow',sans-serif;
  --body:'PWP Plex','IBM Plex Sans','Segoe UI',system-ui,sans-serif;
  --mono:'PWP Mono','IBM Plex Mono',Consolas,monospace;
  --top:var(--safe-top,1.875rem); --bottom:var(--safe-bottom,1.25rem);
  background:var(--chassis);color:var(--text);font-family:var(--body);font-size:.9375rem;line-height:1.4;
}
*{box-sizing:border-box}
button,input,textarea{font:inherit;color:inherit}
button{cursor:pointer;background:none;border:0;padding:0}
::selection{background:var(--amber);color:var(--amber-ink)}
::-webkit-scrollbar{width:.375rem;height:.375rem}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--line);border-radius:1rem}
::-webkit-scrollbar-button,::-webkit-scrollbar-corner{display:none;background:transparent}
svg{width:1.125rem;height:1.125rem;flex:none}
:focus-visible{outline:.125rem solid var(--amber);outline-offset:.125rem}

.mdt{position:absolute;inset:0;display:grid;grid-template-columns:13.75rem 1fr;padding:var(--top) 0 var(--bottom)}
.mdt.phone{grid-template-columns:1fr;grid-template-rows:auto 1fr}

.mdt-rail{display:flex;flex-direction:column;gap:1rem;padding:.5rem .75rem .75rem 1.25rem;min-height:0;overflow-y:auto}
.mdt-plate{background:#000;border:1px solid var(--line);border-radius:.5rem;padding:.7rem .8rem;display:grid;gap:.15rem}
.mdt-plate .cs{font-family:var(--mono);font-size:1.5rem;color:var(--amber);letter-spacing:.06em;line-height:1.1}
.mdt-plate .who{font-weight:600}
.mdt-plate .rk{color:var(--mute);font-size:.8125rem}
.mdt-plate .dept{font-family:var(--display);font-weight:700;letter-spacing:.12em;font-size:.75rem;color:var(--mute);text-transform:uppercase}
.mdt-status{display:grid;grid-template-columns:1fr 1fr;gap:.375rem}
.mdt-status button{display:flex;align-items:center;justify-content:center;gap:.4rem;min-height:2.25rem;border:1px solid var(--line);border-radius:.4rem;font-size:.8125rem;font-weight:600;color:var(--mute)}
.mdt-status .dot{width:.5rem;height:.5rem;border-radius:50%;background:currentColor}
.mdt-status button.on.available{color:var(--ok);border-color:var(--ok)}
.mdt-status button.on.busy{color:var(--text);border-color:var(--busy)}
.mdt-status .live{grid-column:span 2;color:var(--route);border-color:var(--route)}
.mdt-nav{display:flex;flex-direction:column;gap:.125rem}
.mdt-nav button{display:flex;align-items:center;gap:.7rem;min-height:2.5rem;padding:0 .7rem;border-radius:.4rem;color:var(--mute);text-align:left}
.mdt-nav button:hover{background:var(--panel)}
.mdt-nav button.on{background:var(--panel2);color:var(--text)}
.mdt-nav button.on svg{color:var(--amber)}
.mdt-nav .n{margin-left:auto;font-family:var(--mono);font-size:.75rem;color:var(--amber)}

.mdt-pbar{display:flex;align-items:center;gap:.6rem;padding:.25rem 1rem .5rem;flex-wrap:wrap}
.mdt-pbar .cs{font-family:var(--mono);color:var(--amber);font-size:1.125rem}
.mdt-pbar .who{flex:1;min-width:0;font-size:.8125rem;color:var(--mute);overflow-wrap:anywhere}
.mdt-pbar .mdt-status{grid-template-columns:auto auto}
.mdt-pbar .mdt-status button{min-height:2rem;padding:0 .6rem}
.mdt-chips{display:flex;flex-wrap:nowrap;gap:.3rem;padding:0 1rem .6rem;overflow-x:auto;scrollbar-width:none}
.mdt-chips::-webkit-scrollbar{height:0}
.mdt-chips button{flex:none}
.mdt-chips button{display:flex;align-items:center;gap:.35rem;min-height:2.125rem;padding:0 .65rem;border-radius:.4rem;border:1px solid var(--line);font-size:.8125rem;color:var(--mute)}
.mdt-chips button.on{border-color:var(--amber);color:var(--text)}
.mdt-chips svg{width:1rem;height:1rem}

.mdt-work{background:var(--panel);border-radius:.875rem 0 0 .875rem;min-width:0;min-height:0;display:flex;flex-direction:column}
.mdt.phone .mdt-work{border-radius:.875rem .875rem 0 0}
.mdt-head{display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;padding:1rem 1.5rem .75rem}
.mdt.phone .mdt-head{padding:.875rem 1rem .5rem}
.mdt-head h1{margin:0;font-family:var(--display);font-weight:700;font-size:1.75rem;letter-spacing:.01em;line-height:1.05;text-wrap:balance;flex:1;min-width:0}
.mdt.phone .mdt-head h1{font-size:1.5rem}
.mdt-scroll{flex:1;min-height:0;overflow-y:auto;padding:0 1.5rem 1.5rem}
.mdt.phone .mdt-scroll{padding:0 1rem 1rem}

.mdt-err{display:flex;align-items:flex-start;gap:.6rem;margin:0 1.5rem .75rem;padding:.6rem .8rem;border-radius:.4rem;background:rgba(229,72,77,.14);border:1px solid var(--red);color:#ffd9da}
.mdt.phone .mdt-err{margin:0 1rem .6rem}
.mdt-err span{flex:1;overflow-wrap:anywhere}

.mdt-sec{display:flex;align-items:baseline;gap:.5rem;margin:1.25rem 0 .5rem;font-family:var(--display);font-weight:600;font-size:.875rem;letter-spacing:.14em;text-transform:uppercase;color:var(--mute)}
.mdt-sec:first-child{margin-top:0}
.mdt-sec .c{font-family:var(--mono);letter-spacing:0;color:var(--amber)}

.mdt-btn{display:inline-flex;align-items:center;justify-content:center;gap:.4rem;min-height:2.375rem;padding:0 .9rem;border-radius:.4rem;border:1px solid var(--line);background:var(--panel2);font-weight:600;font-size:.875rem;white-space:nowrap}
.mdt-btn:hover{border-color:var(--mute)}
.mdt-btn.go{background:var(--amber);border-color:var(--amber);color:var(--amber-ink)}
.mdt-btn.stop{border-color:var(--red);color:#ff9ea1;background:transparent}
.mdt-btn.ok{border-color:var(--ok);color:var(--ok);background:transparent}
.mdt-btn.ghost{background:transparent}
.mdt-btn[disabled]{opacity:.45;cursor:default}

.mdt-field{display:flex;gap:.5rem;align-items:stretch;flex-wrap:wrap}
.mdt-field input,.mdt-in{flex:1;min-width:10rem;min-height:2.625rem;padding:.55rem .8rem;border-radius:.4rem;border:1px solid var(--line);background:var(--chassis);outline:none}
.mdt-field input:focus,.mdt-in:focus{border-color:var(--amber)}
input::placeholder,textarea::placeholder{color:var(--mute)}
textarea.mdt-in{min-height:9rem;resize:vertical;width:100%}

.mdt-rows{display:flex;flex-direction:column;border:1px solid var(--line);border-radius:.6rem;overflow:hidden}
.mdt-row{display:flex;align-items:center;gap:.9rem;padding:.75rem .9rem;text-align:left;width:100%;min-width:0}
.mdt-row+.mdt-row{border-top:1px solid var(--line)}
button.mdt-row:hover{background:var(--panel2)}
.mdt-row .main{flex:1;min-width:0;overflow-wrap:anywhere}
.mdt-row .t{font-weight:600}
.mdt-row .s{color:var(--mute);font-size:.8125rem}
.mdt-row .acts{display:flex;gap:.4rem;flex-wrap:wrap;justify-content:flex-end}
.mdt-id{font-family:var(--mono);font-size:.8125rem;color:var(--mute);min-width:2.75rem}

.mdt-call{display:grid;grid-template-columns:auto 1fr auto;gap:.9rem;align-items:center;padding:.85rem .9rem;border:1px solid var(--line);border-left:.25rem solid var(--amber);border-radius:.6rem;background:var(--panel2)}
.mdt-call.high{border-left-color:var(--red)}
.mdt-call+.mdt-call{margin-top:.5rem}
.mdt-code{font-family:var(--mono);font-size:1.125rem;color:var(--amber);min-width:3.25rem}
.mdt-call.high .mdt-code{color:var(--red)}
.mdt-call .t{font-family:var(--display);font-weight:600;font-size:1.25rem;line-height:1.1}
.mdt-call .s{color:var(--mute);font-size:.8125rem;overflow-wrap:anywhere}
.mdt-call .acts{display:flex;gap:.4rem;flex-wrap:wrap;justify-content:flex-end}
.mdt.phone .mdt-call{grid-template-columns:auto 1fr}
.mdt.phone .mdt-call .acts{grid-column:1 / -1;justify-content:flex-start}

.mdt-tag{display:inline-flex;align-items:center;gap:.3rem;font-size:.6875rem;font-weight:600;letter-spacing:.08em;text-transform:uppercase;padding:.15rem .45rem;border-radius:.25rem;border:1px solid var(--line);color:var(--mute);white-space:nowrap}
.mdt-tag.red{border-color:var(--red);color:#ff9ea1}
.mdt-tag.ok{border-color:var(--ok);color:var(--ok)}
.mdt-tag.route{border-color:var(--route);color:var(--route)}
.mdt-tag.amber{border-color:var(--amber);color:var(--amber)}

.mdt-plateno{display:inline-block;font-family:var(--mono);font-size:.9375rem;letter-spacing:.08em;padding:.15rem .5rem;border-radius:.25rem;background:#f4f5f0;color:#1b2a4a;border:1px solid #9aa3b2;white-space:nowrap}

.mdt-split{display:grid;grid-template-columns:1.6fr 1fr;gap:1.25rem;align-items:start}
.mdt.phone .mdt-split{grid-template-columns:1fr}
.mdt-figs{display:grid;grid-template-columns:repeat(3,1fr);gap:.5rem}
.mdt-fig{border:1px solid var(--line);border-radius:.6rem;padding:.7rem .8rem;display:grid;gap:.1rem}
.mdt-fig b{font-family:var(--mono);font-size:1.5rem;font-weight:500}
.mdt-fig span{color:var(--mute);font-size:.8125rem}
.mdt-empty{padding:1.5rem 1rem;text-align:center;color:var(--mute);border:1px dashed var(--line);border-radius:.6rem}

.mdt-sheet{background:var(--paper);color:var(--paper-ink);border-radius:.375rem;padding:1.25rem 1.4rem 1.4rem;position:relative}
.mdt.phone .mdt-sheet{padding:1rem}
.mdt-sheet .hd{display:flex;align-items:flex-start;gap:1rem;flex-wrap:wrap;border-bottom:2px solid var(--paper-ink);padding-bottom:.75rem;margin-bottom:1rem}
.mdt-sheet .nm{flex:1;min-width:0}
.mdt-sheet .nm small{display:block;font-family:var(--display);font-weight:600;letter-spacing:.16em;font-size:.75rem;color:var(--paper-mute);text-transform:uppercase}
.mdt-sheet .nm b{display:block;font-family:var(--display);font-weight:700;font-size:2.125rem;line-height:1;text-wrap:balance}
.mdt-sheet .no{font-family:var(--mono);font-size:.875rem;color:var(--paper-mute);text-align:right}
.mdt-stamp{position:absolute;top:1.1rem;right:7rem;transform:rotate(-7deg);border:.1875rem solid var(--stamp);color:var(--stamp);font-family:var(--display);font-weight:700;font-size:1.375rem;letter-spacing:.14em;padding:.05rem .6rem;border-radius:.3rem;opacity:.9;pointer-events:none}
.mdt.phone .mdt-stamp{right:1rem;top:3.6rem;font-size:1.125rem}
.mdt-boxes{display:grid;grid-template-columns:repeat(4,1fr);border-top:1px solid var(--paper-line);border-left:1px solid var(--paper-line)}
.mdt.phone .mdt-boxes{grid-template-columns:1fr 1fr}
.mdt-box{padding:.4rem .6rem .55rem;border-right:1px solid var(--paper-line);border-bottom:1px solid var(--paper-line);min-width:0}
.mdt-box small{display:block;font-family:var(--display);font-weight:600;font-size:.6875rem;letter-spacing:.14em;text-transform:uppercase;color:var(--paper-mute)}
.mdt-box span{overflow-wrap:anywhere}
.mdt-sheet .mdt-sec{color:var(--paper-mute)}
.mdt-sheet .mdt-sec .c{color:var(--stamp)}
.mdt-sheet .mdt-rows{border-color:var(--paper-line);background:#fff}
.mdt-sheet .mdt-row+.mdt-row{border-color:var(--paper-line)}
.mdt-sheet button.mdt-row:hover{background:#f3f5f8}
.mdt-sheet .mdt-row .s,.mdt-sheet .mdt-id{color:var(--paper-mute)}
.mdt-sheet .mdt-btn{background:#fff;border-color:var(--paper-line);color:var(--paper-ink)}
.mdt-sheet .mdt-btn.go{background:var(--paper-ink);border-color:var(--paper-ink);color:#fff}
.mdt-sheet .mdt-btn.stop{background:transparent;border-color:var(--stamp);color:var(--stamp)}
.mdt-sheet .mdt-btn.ok{background:transparent;border-color:#2f8a5c;color:#2f8a5c}
.mdt-sheet .mdt-field input{background:#fff;border-color:var(--paper-line)}
.mdt-sheet .mdt-field input:focus{border-color:var(--paper-ink)}
.mdt-sheet input::placeholder{color:#7d8999}
.mdt-sheet .mdt-tag{border-color:var(--paper-line);color:var(--paper-mute)}
.mdt-sheet .mdt-tag.ok{border-color:#2f8a5c;color:#2f8a5c}
.mdt-sheet .mdt-empty{border-color:var(--paper-line);color:var(--paper-mute)}

.mdt-charges{display:grid;grid-template-columns:1fr 1fr;gap:1rem}
.mdt.phone .mdt-charges{grid-template-columns:1fr}
.mdt-pick{max-height:15rem;overflow-y:auto}
.mdt-pick .mdt-row{padding:.55rem .75rem}
.mdt-cat{font-size:.6875rem;font-weight:600;letter-spacing:.08em;text-transform:uppercase}
.mdt-cat.felony{color:var(--stamp)}
.mdt-step{display:flex;align-items:center;gap:.25rem}
.mdt-step button{width:2rem;height:2rem;border-radius:.3rem;border:1px solid var(--paper-line);display:grid;place-items:center;background:#fff}
.mdt-step span{font-family:var(--mono);min-width:1.5rem;text-align:center}
.mdt-total{display:flex;align-items:center;gap:1.25rem;flex-wrap:wrap;margin-top:.75rem;padding-top:.75rem;border-top:2px solid var(--paper-ink)}
.mdt-total div{display:grid}
.mdt-total small{font-family:var(--display);font-weight:600;font-size:.6875rem;letter-spacing:.14em;text-transform:uppercase;color:var(--paper-mute)}
.mdt-total b{font-family:var(--mono);font-size:1.25rem;font-weight:500}
.mdt-total .acts{margin-left:auto;display:flex;gap:.5rem;flex-wrap:wrap}

.mdt-table{width:100%;border-collapse:collapse}
.mdt-table th{text-align:left;font-family:var(--display);font-weight:600;font-size:.75rem;letter-spacing:.14em;text-transform:uppercase;color:var(--mute);padding:.5rem .6rem;border-bottom:1px solid var(--line)}
.mdt-table td{padding:.55rem .6rem;border-bottom:1px solid var(--line);vertical-align:top;overflow-wrap:anywhere}
.mdt-table td.num,.mdt-table th.num{font-family:var(--mono);text-align:right;white-space:nowrap}
.mdt-seg{display:flex;flex-wrap:wrap;gap:.375rem}
.mdt-seg button{min-height:2.25rem;padding:0 .75rem;border-radius:.4rem;border:1px solid var(--line);font-size:.8125rem;color:var(--mute)}
.mdt-seg button.on{border-color:var(--amber);color:var(--text)}
.mdt-form{display:grid;gap:.6rem}
.mdt-form .two{display:grid;grid-template-columns:1fr 1fr;gap:.6rem}
.mdt.phone .mdt-form .two{grid-template-columns:1fr}
.mdt-gap{height:.75rem}
.mdt-short{flex:0 1 9rem;min-width:7rem}
.mdt-spacer{flex:1}
@media (prefers-reduced-motion:no-preference){.mdt-btn,.mdt-row,.mdt-nav button{transition:background-color .12s,border-color .12s}}
`;

  const ICON = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;
  const I = {
    badge: ICON('<path d="M12 2.5l7.5 3v5.7c0 4.6-3.2 8.5-7.5 10.3-4.3-1.8-7.5-5.7-7.5-10.3V5.5z"/><path d="M12 8.2l1.3 2.6 2.9.4-2.1 2 .5 2.9-2.6-1.4-2.6 1.4.5-2.9-2.1-2 2.9-.4z"/>'),
    home: ICON('<rect x="3.5" y="3.5" width="7" height="7" rx="1"/><rect x="13.5" y="3.5" width="7" height="7" rx="1"/><rect x="3.5" y="13.5" width="7" height="7" rx="1"/><rect x="13.5" y="13.5" width="7" height="7" rx="1"/>'),
    calls: ICON('<path d="M4 17h16"/><path d="M6 17V12a6 6 0 0112 0v5"/><path d="M12 3v2M4.2 6.2l1.4 1.4M19.8 6.2l-1.4 1.4"/><path d="M9 20h6"/>'),
    people: ICON('<circle cx="12" cy="8" r="3.8"/><path d="M4.5 20.5c1-3.8 4-5.8 7.5-5.8s6.5 2 7.5 5.8"/>'),
    car: ICON('<path d="M5 15l1.6-4.8A2 2 0 018.5 9h7a2 2 0 011.9 1.2L19 15"/><rect x="3" y="15" width="18" height="4" rx="1"/><path d="M7 19v1.5M17 19v1.5"/>'),
    report: ICON('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 12h5M10 16h5"/>'),
    warrant: ICON('<path d="M14 4l6 6M12 6l6 6M11 7l-7 7 3 3 7-7"/><path d="M4 20h9"/>'),
    bolo: ICON('<circle cx="11" cy="11" r="6"/><path d="M20 20l-4.5-4.5M11 8v3l2 1.5"/>'),
    penal: ICON('<path d="M12 3v18M6 21h12M5 7h14"/><path d="M7 7l-3 6.5h6zM17 7l-3 6.5h6z"/>'),
    prison: ICON('<rect x="4" y="4" width="16" height="16" rx="1"/><path d="M9 4v16M15 4v16"/>'),
    units: ICON('<circle cx="8" cy="9" r="3"/><circle cx="16.5" cy="9" r="3"/><path d="M2.5 20c.8-3 3-5 5.5-5s4.7 2 5.5 5M13.5 15.6c.9-.4 1.9-.6 3-.6 2.5 0 4.6 2 5.5 5"/>'),
    plus: ICON('<path d="M12 5v14M5 12h14"/>'),
    minus: ICON('<path d="M5 12h14"/>'),
    back: ICON('<path d="M15 5l-7 7 7 7"/>'),
    close: ICON('<path d="M6 6l12 12M18 6L6 18"/>'),
    search: ICON('<circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.2-4.2"/>'),
    alert: ICON('<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17.5v.5"/>'),
  };

  const TABS = [
    ['home', 'Shift', 'home'], ['calls', 'Calls', 'calls'], ['people', 'People', 'people'], ['vehicles', 'Vehicles', 'car'],
    ['reports', 'Reports', 'report'], ['warrants', 'Warrants', 'warrant'], ['bolos', 'BOLOs', 'bolo'],
    ['penal', 'Penal code', 'penal'], ['prison', 'Prison', 'prison'], ['units', 'Units', 'units'],
  ];
  const TITLE = { home: 'Shift overview', calls: 'Calls', people: 'People', vehicles: 'Vehicles', reports: 'Reports',
    warrants: 'Active warrants', bolos: 'Be on the lookout', penal: 'Penal code', prison: 'Prisoners', units: 'Units on duty' };
  const STATUS = { available: 'Available', enroute: 'En route', onscene: 'On scene', busy: 'Busy' };
  const CAT = { infraction: 'Infraction', misdemeanor: 'Misdemeanor', felony: 'Felony' };

  const live = new WeakMap();
  const esc = (v) => String(v == null ? '' : v).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const money = (n) => '$' + Math.round(Number(n) || 0).toLocaleString('en-US');
  const ms = (v) => (typeof v === 'number' ? (v < 1e12 ? v * 1000 : v) : Date.parse(v));
  const when = (v) => {
    const t = ms(v); if (!t) return v == null ? '' : String(v);
    const d = new Date(t);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) + ' ' + d.toTimeString().slice(0, 5);
  };
  const ago = (sec) => {
    const s = Math.max(0, Math.floor(Date.now() / 1000 - sec));
    return s < 60 ? 'just now' : s < 3600 ? Math.floor(s / 60) + ' min ago' : Math.floor(s / 3600) + ' h ago';
  };
  const day = (v) => String(v || '').slice(0, 10);

  const draw = (app) => {
    const ctx = live.get(app);
    if (!ctx) return;
    const { el, view } = ctx;
    const doc = el.ownerDocument;
    const active = doc.activeElement;
    const keep = active && el.contains(active) && active.id ? { id: active.id, a: active.selectionStart, b: active.selectionEnd } : null;
    const oldScroll = el.querySelector('.mdt-scroll');
    const same = app.state.tab === ctx.tab && app.state.screen === ctx.screen;
    const top = oldScroll && same ? oldScroll.scrollTop : 0;
    el.querySelector('.mdt-root').innerHTML = render(app, view);
    ctx.tab = app.state.tab; ctx.screen = app.state.screen;
    const sc = el.querySelector('.mdt-scroll');
    if (sc) sc.scrollTop = top;
    if (keep) {
      const n = el.querySelector('#' + keep.id);
      if (n) { n.focus(); try { n.setSelectionRange(keep.a, keep.b); } catch (e) { /* not a text field */ } }
    }
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
    } finally {
      app.state.busy = false;
      draw(app);
    }
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
    if (!s.penal) await ask(app, 'penal', {}, (r) => { s.penal = r; });
    if (tab === 'home') await ask(app, 'dashboard', {}, (r) => { s.dash = r; s.calls = r.calls; });
    if (tab === 'calls' || tab === 'units') await ask(app, 'calls', {}, (r) => { s.calls = r.calls; s.units = r.units; });
    if (tab === 'reports') await ask(app, 'reports', { q: s.f.reportQ || '' }, (r) => { s.reports = r; });
    if (tab === 'warrants') await ask(app, 'warrants', {}, (r) => { s.warrants = r; });
    if (tab === 'bolos') await ask(app, 'bolos', {}, (r) => { s.bolos = r; });
    if (tab === 'prison' && s.me && s.me.perms.prison_staff) await ask(app, 'prisoners', {}, (r) => { s.prisoners = r; });
  };

  const perms = (app) => (app.state.me && app.state.me.perms) || {};
  const val = (app, k) => esc(app.state.f[k] || '');

  const statusButtons = (app) => {
    const st = (app.state.me || {}).status;
    if (st === 'enroute' || st === 'onscene') {
      return `<div class="mdt-status"><button class="live" data-act="status" data-s="available"><span class="dot"></span>${STATUS[st]} · tap when clear</button></div>`;
    }
    return `<div class="mdt-status">${['available', 'busy'].map((k) => `<button class="${k} ${st === k ? 'on' : ''}" data-act="status" data-s="${k}" aria-pressed="${st === k}"><span class="dot"></span>${STATUS[k]}</button>`).join('')}</div>`;
  };

  const tabsFor = (app) => TABS.filter(([id]) => id !== 'prison' || perms(app).prison_staff);
  const count = (app, id) => {
    const s = app.state;
    if (id === 'calls') return (s.calls || []).length || '';
    if (id === 'warrants' && s.dash) return s.dash.warrants || '';
    if (id === 'bolos' && s.dash) return s.dash.bolos || '';
    return '';
  };

  const headAction = (app) => {
    const s = app.state;
    if (s.screen === 'person' || s.screen === 'report') return `<button class="mdt-btn ghost" data-act="backScreen">${I.back}Back</button>`;
    if (s.tab === 'reports' && perms(app).records) return `<button class="mdt-btn go" data-act="newReport">${I.plus}New report</button>`;
    return '';
  };

  const chrome = (app, phone, inner) => {
    const s = app.state; const me = s.me || {};
    const err = s.err ? `<div class="mdt-err" role="alert">${I.alert}<span>${esc(s.err)}</span><button data-act="dismissErr" aria-label="Dismiss">${I.close}</button></div>` : '';
    const title = s.screen === 'person' && s.person ? 'Citizen record' : s.screen === 'report' ? (s.edit && s.edit.id ? 'Report #' + s.edit.id : 'New report') : TITLE[s.tab] || '';
    const work = `<section class="mdt-work"><div class="mdt-head"><h1>${esc(title)}</h1>${headAction(app)}</div>${err}<div class="mdt-scroll">${inner}</div></section>`;
    if (phone) {
      return `<div class="mdt phone"><div><div class="mdt-pbar"><span class="cs">${esc(me.callsign || '')}</span><span class="who">${esc(me.short || '')} · ${esc(me.name || '')}</span>${statusButtons(app)}</div>
        <nav class="mdt-chips" aria-label="Sections">${tabsFor(app).map(([id, label, icon]) => `<button class="${s.tab === id ? 'on' : ''}" data-act="tab" data-t="${id}">${I[icon]}${label}</button>`).join('')}</nav></div>${work}</div>`;
    }
    return `<div class="mdt"><aside class="mdt-rail">
      <div class="mdt-plate"><span class="dept">${esc(me.deptLabel || me.short || '')}</span><span class="cs">${esc(me.callsign || '')}</span><span class="who">${esc(me.name || '')}</span><span class="rk">${esc(me.rank || '')}</span></div>
      ${statusButtons(app)}
      <nav class="mdt-nav" aria-label="Sections">${tabsFor(app).map(([id, label, icon]) => `<button class="${s.tab === id ? 'on' : ''}" data-act="tab" data-t="${id}">${I[icon]}<span>${label}</span><span class="n">${count(app, id)}</span></button>`).join('')}</nav>
      </aside>${work}</div>`;
  };

  const callCard = (app, c) => {
    const me = app.state.me || {}; const mine = (c.responders || []).some((r) => r.callsign === me.callsign);
    const p = perms(app);
    const units = (c.responders || []).length;
    return `<article class="mdt-call ${c.priority === 'high' ? 'high' : ''}">
      <span class="mdt-code">${esc(c.code)}</span>
      <div><div class="t">${esc(c.title)}</div>
        ${(c.info || []).map((l) => `<div class="s">${esc(l)}</div>`).join('')}
        <div class="s">${ago(c.createdAt)} · ${units} of ${c.maxResponders} units${units ? ': ' + c.responders.map((r) => esc(r.callsign)).join(', ') : ''}</div></div>
      ${p.dispatch ? `<div class="acts">${mine ? `<button class="mdt-btn" data-act="detach" data-id="${c.id}">Leave call</button>` : `<button class="mdt-btn go" data-act="attach" data-id="${c.id}">Respond</button>`}<button class="mdt-btn stop" data-act="clearCall" data-id="${c.id}">Close</button></div>` : ''}
    </article>`;
  };

  const screens = {
    home(app) {
      const d = app.state.dash || {}; const calls = app.state.calls || d.calls || [];
      return `<div class="mdt-split"><div>
          <div class="mdt-sec">Open calls <span class="c">${calls.length}</span></div>
          ${calls.length ? calls.slice(0, 5).map((c) => callCard(app, c)).join('') : '<div class="mdt-empty">No open calls. Calls from dispatch, panic buttons and 911 land here.</div>'}
        </div><div>
          <div class="mdt-sec">On the board</div>
          <div class="mdt-figs"><div class="mdt-fig"><b>${(d.units || []).length}</b><span>Units</span></div><div class="mdt-fig"><b>${d.warrants || 0}</b><span>Warrants</span></div><div class="mdt-fig"><b>${d.bolos || 0}</b><span>BOLOs</span></div></div>
          <div class="mdt-sec">Recent reports</div>
          ${(d.reports || []).length ? `<div class="mdt-rows">${d.reports.map((r) => `<button class="mdt-row" data-act="openReport" data-id="${r.id}"><span class="mdt-id">#${r.id}</span><span class="main"><span class="t">${esc(r.title)}</span><br><span class="s">${esc((r.dept || '').toUpperCase())} · ${when(r.createdAt)}</span></span></button>`).join('')}</div>` : '<div class="mdt-empty">No reports yet</div>'}
        </div></div>`;
    },
    calls(app) {
      const calls = app.state.calls || [];
      return calls.length ? calls.map((c) => callCard(app, c)).join('') : '<div class="mdt-empty">All quiet. New calls appear here and on your map.</div>';
    },
    units(app) {
      const u = app.state.units || [];
      return u.length ? `<div class="mdt-rows">${u.map((x) => `<div class="mdt-row"><span class="mdt-code">${esc(x.callsign)}</span><span class="main"><span class="t">${esc((x.dept || '').toUpperCase())}</span></span><span class="mdt-tag ${x.status === 'available' ? 'ok' : x.status === 'busy' ? '' : 'route'}">${STATUS[x.status] || esc(x.status)}</span></div>`).join('')}</div>` : '<div class="mdt-empty">Nobody is on duty</div>';
    },
    people(app) {
      const s = app.state; const list = s.peopleList || [];
      return `<div class="mdt-field"><input id="f-peopleQ" class="mdt-in" data-bind="peopleQ" data-enter="searchPeople" value="${val(app, 'peopleQ')}" placeholder="Name or citizen ID" autocomplete="off"><button class="mdt-btn go" data-act="searchPeople">${I.search}Search</button></div>
        <div class="mdt-gap"></div>
        ${list.length ? `<div class="mdt-rows">${list.map((p) => `<button class="mdt-row" data-act="openPerson" data-id="${p.charId}"><span class="mdt-id">${p.charId}</span><span class="main"><span class="t">${esc(p.firstName)} ${esc(p.lastName)}</span><br><span class="s">Born ${esc(day(p.dateOfBirth))} · ${esc(p.gender)}</span></span>${p.warrant ? '<span class="mdt-tag red">Warrant</span>' : ''}</button>`).join('')}</div>`
          : `<div class="mdt-empty">${s.peopleSearched ? 'Nobody matches that search.' : 'Search by first name, last name or citizen ID.'}</div>`}`;
    },
    person(app) {
      const s = app.state; const p = s.person; const pm = perms(app);
      const active = (p.warrants || []).filter((w) => w.status === 'active');
      const unpaid = (p.fines || []).filter((f) => f.status === 'unpaid');
      const ch = s.charges || []; const t = totals(app, ch);
      const q = String(s.f.chargeQ || '').toLowerCase();
      const penal = (s.penal || []).filter((x) => !q || (x.title + ' ' + x.code).toLowerCase().includes(q));
      const stamp = active.length ? 'WANTED' : p.sentence ? 'IN CUSTODY' : '';
      const pm2 = penalMap(app);
      return `<div class="mdt-sheet">
        ${stamp ? `<div class="mdt-stamp">${stamp}</div>` : ''}
        <div class="hd"><div class="nm"><small>${esc((app.state.me && app.state.me.short) || "")} records</small><b>${esc(p.firstName)} ${esc(p.lastName)}</b></div><div class="no">ID ${p.charId}${p.online ? '<br><span class="mdt-tag ok">In town</span>' : ''}</div></div>
        <div class="mdt-boxes">
          <div class="mdt-box"><small>Born</small><span>${esc(day(p.dateOfBirth))}</span></div>
          <div class="mdt-box"><small>Sex</small><span>${esc(p.gender)}</span></div>
          <div class="mdt-box"><small>Unpaid fines</small><span>${unpaid.length ? money(unpaid.reduce((a, f) => a + f.amount, 0)) + ' · ' + unpaid.length : 'None'}</span></div>
          <div class="mdt-box"><small>Sentence</small><span>${p.sentence ? esc(p.sentence.minutesLeft) + ' min left' : 'None'}</span></div>
        </div>

        <div class="mdt-sec">Warrants <span class="c">${active.length || ''}</span></div>
        ${active.length ? `<div class="mdt-rows">${active.map((w) => `<div class="mdt-row"><span class="main"><span class="t">${esc(w.reason)}</span><br><span class="s">Valid until ${when(w.expiresAt)}</span></span>${pm.warrants ? `<button class="mdt-btn ok" data-act="closeWarrant" data-id="${w.id}" data-s="served">Served</button>` : ''}</div>`).join('')}</div>` : '<div class="mdt-empty">No active warrants</div>'}
        ${pm.warrants ? `<div class="mdt-gap"></div><div class="mdt-field"><input id="f-warrantReason" data-bind="warrantReason" value="${val(app, 'warrantReason')}" placeholder="Reason for a new warrant"><button class="mdt-btn" data-act="issueWarrant">${I.plus}Issue warrant</button></div>` : ''}

        <div class="mdt-sec">Charges</div>
        <div class="mdt-charges"><div>
            <div class="mdt-field"><input id="f-chargeQ" data-bind="chargeQ" data-enter="noop" value="${val(app, 'chargeQ')}" placeholder="Find a charge: code or words"><button class="mdt-btn" data-act="noop">${I.search}</button></div>
            <div class="mdt-gap"></div>
            <div class="mdt-rows mdt-pick">${penal.map((x) => `<button class="mdt-row" data-act="addCharge" data-code="${esc(x.code)}"><span class="mdt-id">${esc(x.code)}</span><span class="main">${esc(x.title)}<br><span class="s"><span class="mdt-cat ${x.category}">${CAT[x.category] || ''}</span> · ${money(x.fine)} · ${x.months} mo</span></span>${I.plus}</button>`).join('') || '<div class="mdt-empty">No charge matches</div>'}</div>
          </div><div>
            ${ch.length ? `<div class="mdt-rows">${ch.map((c, i) => `<div class="mdt-row"><span class="mdt-id">${esc(c.code)}</span><span class="main">${esc((pm2[c.code] || {}).title)}</span><span class="mdt-step"><button data-act="chargeCount" data-i="${i}" data-d="-1" aria-label="One less">${I.minus}</button><span>${c.count}</span><button data-act="chargeCount" data-i="${i}" data-d="1" aria-label="One more">${I.plus}</button></span></div>`).join('')}</div>` : '<div class="mdt-empty">Pick charges on the left. Totals add up here.</div>'}
            <div class="mdt-total"><div><small>Fine</small><b>${money(t.fine)}</b></div><div><small>Prison</small><b>${t.months} mo</b></div>
              <div class="acts">${pm.fine ? `<button class="mdt-btn go" data-act="fine" ${t.fine > 0 ? '' : 'disabled'}>Fine ${money(t.fine)}</button>` : ''}${pm.jail ? `<button class="mdt-btn stop" data-act="jail" ${t.months > 0 ? '' : 'disabled'}>Send to prison</button>` : ''}</div></div>
          </div></div>

        <div class="mdt-sec">Vehicles</div>
        ${(p.vehicles || []).length ? `<div class="mdt-rows">${p.vehicles.map((v) => `<div class="mdt-row"><span class="mdt-plateno">${esc(v.plate)}</span><span class="main">${esc(v.model)}</span><span class="mdt-tag">${esc(v.state)}</span></div>`).join('')}</div>` : '<div class="mdt-empty">No registered vehicles</div>'}

        <div class="mdt-sec">Reports</div>
        ${(p.reports || []).length ? `<div class="mdt-rows">${p.reports.map((r) => `<button class="mdt-row" data-act="openReport" data-id="${r.id}"><span class="mdt-id">#${r.id}</span><span class="main"><span class="t">${esc(r.title)}</span><br><span class="s">${when(r.createdAt)}</span></span></button>`).join('')}</div>` : '<div class="mdt-empty">Not named in any report</div>'}

        <div class="mdt-sec">Notes</div>
        ${(p.notes || []).length ? `<div class="mdt-rows">${p.notes.map((n) => `<div class="mdt-row"><span class="main">${esc(n.text)}<br><span class="s">${esc(n.author || '')} · ${when(n.createdAt)}</span></span></div>`).join('')}</div>` : '<div class="mdt-empty">No notes</div>'}
        ${pm.records ? `<div class="mdt-gap"></div><div class="mdt-field"><input id="f-noteText" data-bind="noteText" data-enter="addNote" value="${val(app, 'noteText')}" placeholder="Add a note to this record"><button class="mdt-btn" data-act="addNote">${I.plus}Add note</button></div>
        <div class="mdt-gap"></div><div class="mdt-field"><input id="f-boloReason" data-bind="boloReason" value="${val(app, 'boloReason')}" placeholder="Reason to look out for this person"><button class="mdt-btn" data-act="boloPerson">${I.plus}Issue BOLO</button></div>` : ''}
      </div>`;
    },
    vehicles(app) {
      const s = app.state; const list = s.vehicleList || []; const pm = perms(app);
      return `<div class="mdt-field"><input id="f-plateQ" class="mdt-in" data-bind="plateQ" data-enter="searchPlate" value="${val(app, 'plateQ')}" placeholder="Plate, e.g. 4ZX 811" autocomplete="off"><button class="mdt-btn go" data-act="searchPlate">${I.search}Run plate</button></div>
        <div class="mdt-gap"></div>
        ${list.length ? `<div class="mdt-rows">${list.map((v) => `<div class="mdt-row"><span class="mdt-plateno">${esc(v.plate)}</span><span class="main"><span class="t">${esc(v.model)}</span><br><span class="s">Owner ${esc(v.owner || '#' + v.ownerCharId)} · ${esc(v.state)}${v.bolo ? ' · BOLO: ' + esc(v.bolo.reason) : ''}</span></span>${v.bolo ? '<span class="mdt-tag red">BOLO</span>' : ''}<button class="mdt-btn" data-act="openPerson" data-id="${v.ownerCharId}">Owner record</button></div>`).join('')}</div>`
          : `<div class="mdt-empty">${s.plateSearched ? 'No vehicle with that plate.' : 'Run a plate to see the car, its owner and any BOLO.'}</div>`}
        ${pm.records ? `<div class="mdt-sec">Lookout on a plate</div><div class="mdt-field"><input id="f-boloPlate" class="mdt-in mdt-short" data-bind="boloPlate" value="${val(app, 'boloPlate')}" placeholder="Plate"><input id="f-boloPlateReason" class="mdt-in" data-bind="boloPlateReason" value="${val(app, 'boloPlateReason')}" placeholder="Why officers should stop it"><button class="mdt-btn" data-act="boloPlate">${I.plus}Issue BOLO</button></div>` : ''}`;
    },
    reports(app) {
      const list = app.state.reports || [];
      return `<div class="mdt-field"><input id="f-reportQ" class="mdt-in" data-bind="reportQ" data-enter="searchReports" value="${val(app, 'reportQ')}" placeholder="Search report titles"><button class="mdt-btn" data-act="searchReports">${I.search}Search</button></div>
        <div class="mdt-gap"></div>
        ${list.length ? `<div class="mdt-rows">${list.map((r) => `<button class="mdt-row" data-act="openReport" data-id="${r.id}"><span class="mdt-id">#${r.id}</span><span class="main"><span class="t">${esc(r.title)}</span><br><span class="s">${esc((r.dept || '').toUpperCase())} · ${when(r.createdAt)}</span></span><span class="mdt-tag ${r.status === 'open' ? 'amber' : ''}">${esc(r.status)}</span></button>`).join('')}</div>` : '<div class="mdt-empty">No reports match</div>'}`;
    },
    report(app) {
      const s = app.state; const r = s.edit; const pm = perms(app); const t = totals(app, r.charges); const pm2 = penalMap(app);
      return `<div class="mdt-form">
        <input id="f-editTitle" class="mdt-in" data-bind="editTitle" value="${esc(r.title || '')}" placeholder="Title: what happened, where">
        <textarea id="f-editBody" class="mdt-in" data-bind="editBody" placeholder="Narrative: who, what, when, where, and what you did">${esc(r.body || '')}</textarea>
        ${r.author ? `<div class="mdt-id">Written by ${esc(r.author)}</div>` : ''}
      </div>
      <div class="mdt-sec">People</div>
      ${(r.people || []).length ? `<div class="mdt-rows">${r.people.map((p, i) => `<div class="mdt-row"><span class="mdt-id">${p.charId}</span><span class="main">${esc(p.name || '')}</span><span class="mdt-tag">${esc(p.role)}</span><button class="mdt-btn ghost" data-act="removePerson" data-i="${i}" aria-label="Remove">${I.close}</button></div>`).join('')}</div>` : '<div class="mdt-empty">Nobody added yet</div>'}
      <div class="mdt-gap"></div>
      <div class="mdt-field"><input id="f-addPersonId" class="mdt-in mdt-short" data-bind="addPersonId" value="${val(app, 'addPersonId')}" placeholder="Citizen ID"><div class="mdt-seg">${['suspect', 'victim', 'witness'].map((role) => `<button data-act="addPerson" data-role="${role}">Add ${role}</button>`).join('')}</div></div>
      <div class="mdt-sec">Charges</div>
      ${(r.charges || []).length ? `<div class="mdt-rows">${r.charges.map((c, i) => `<div class="mdt-row"><span class="mdt-id">${esc(c.code)}</span><span class="main">${esc((pm2[c.code] || {}).title)}<br><span class="s">Citizen ${esc(c.charId)} · ×${c.count}</span></span><button class="mdt-btn ghost" data-act="removeReportCharge" data-i="${i}" aria-label="Remove">${I.close}</button></div>`).join('')}</div>` : '<div class="mdt-empty">No charges</div>'}
      <div class="mdt-gap"></div>
      <div class="mdt-field"><input id="f-addChargeCode" class="mdt-in mdt-short" data-bind="addChargeCode" value="${val(app, 'addChargeCode')}" placeholder="Code, e.g. P105"><input id="f-addChargeFor" class="mdt-in mdt-short" data-bind="addChargeFor" value="${val(app, 'addChargeFor')}" placeholder="Citizen ID"><button class="mdt-btn" data-act="addReportCharge">${I.plus}Add charge</button></div>
      <div class="mdt-sec">Totals</div>
      <div class="mdt-field" style="align-items:center"><span class="mdt-tag amber">Fines ${money(t.fine)}</span><span class="mdt-tag amber">Prison ${t.months} mo</span><span class="mdt-spacer"></span>
        <div class="mdt-seg"><button class="${r.status !== 'closed' ? 'on' : ''}" data-act="setStatus" data-v="open">Open</button><button class="${r.status === 'closed' ? 'on' : ''}" data-act="setStatus" data-v="closed">Closed</button></div>
        ${pm.records ? `<button class="mdt-btn go" data-act="saveReport">Save report</button>` : ''}</div>`;
    },
    warrants(app) {
      const list = app.state.warrants || []; const pm = perms(app);
      return list.length ? `<div class="mdt-rows">${list.map((w) => `<div class="mdt-row"><span class="mdt-id">${w.charId}</span><span class="main"><span class="t">${esc(w.name || '')}</span><br><span class="s">${esc(w.reason)} · until ${when(w.expiresAt)}</span></span><span class="acts"><button class="mdt-btn" data-act="openPerson" data-id="${w.charId}">Record</button>${pm.warrants ? `<button class="mdt-btn ok" data-act="closeWarrant" data-id="${w.id}" data-s="served">Served</button><button class="mdt-btn stop" data-act="closeWarrant" data-id="${w.id}" data-s="cancelled">Cancel</button>` : ''}</span></div>`).join('')}</div>` : '<div class="mdt-empty">No active warrants</div>';
    },
    bolos(app) {
      const list = app.state.bolos || []; const pm = perms(app);
      return list.length ? `<div class="mdt-rows">${list.map((b) => `<div class="mdt-row">${b.plate ? `<span class="mdt-plateno">${esc(b.plate)}</span>` : `<span class="mdt-id">${esc(b.charId)}</span>`}<span class="main"><span class="t">${esc(b.plate ? 'Vehicle' : (b.name || 'Person'))}</span><br><span class="s">${esc(b.reason)} · until ${when(b.expiresAt)}</span></span>${pm.records ? `<button class="mdt-btn" data-act="closeBolo" data-id="${b.id}">Close</button>` : ''}</div>`).join('')}</div>` : '<div class="mdt-empty">No lookouts out</div>';
    },
    penal(app) {
      const s = app.state; const pm = perms(app);
      const table = ['infraction', 'misdemeanor', 'felony'].map((g) => {
        const rows = (s.penal || []).filter((p) => p.category === g);
        if (!rows.length) return '';
        return `<div class="mdt-sec">${CAT[g]} <span class="c">${rows.length}</span></div><table class="mdt-table"><thead><tr><th>Code</th><th>Charge</th><th class="num">Fine</th><th class="num">Prison</th>${pm.command ? '<th></th>' : ''}</tr></thead><tbody>${rows.map((p) => `<tr><td class="mdt-id">${esc(p.code)}</td><td>${esc(p.title)}</td><td class="num">${money(p.fine)}</td><td class="num">${p.months} mo</td>${pm.command ? `<td class="num"><button class="mdt-btn ghost" data-act="removePenal" data-code="${esc(p.code)}" aria-label="Remove ${esc(p.code)}">${I.close}</button></td>` : ''}</tr>`).join('')}</tbody></table>`;
      }).join('');
      const form = pm.command ? `<div class="mdt-sec">Add or change a charge</div><div class="mdt-form"><div class="two"><input id="f-pCode" class="mdt-in" data-bind="pCode" value="${val(app, 'pCode')}" placeholder="Code, e.g. P110"><input id="f-pTitle" class="mdt-in" data-bind="pTitle" value="${val(app, 'pTitle')}" placeholder="Charge"></div>
        <div class="two"><input id="f-pFine" class="mdt-in" data-bind="pFine" value="${val(app, 'pFine')}" placeholder="Fine in $" inputmode="numeric"><input id="f-pMonths" class="mdt-in" data-bind="pMonths" value="${val(app, 'pMonths')}" placeholder="Prison months" inputmode="numeric"></div>
        <div class="mdt-field" style="align-items:center"><div class="mdt-seg">${['infraction', 'misdemeanor', 'felony'].map((g) => `<button class="${s.f.pCat === g ? 'on' : ''}" data-act="pCat" data-g="${g}">${CAT[g]}</button>`).join('')}</div><span class="mdt-spacer"></span><button class="mdt-btn go" data-act="savePenal">Save charge</button></div></div>` : '';
      return table + form;
    },
    prison(app) {
      const list = app.state.prisoners || [];
      return list.length ? `<div class="mdt-rows">${list.map((p) => `<div class="mdt-row"><span class="mdt-id">${p.charId}</span><span class="main"><span class="t">${esc(p.name || '')}</span><br><span class="s">${esc(p.reason)} · ${p.months} mo · ${p.minutesLeft} min left</span></span>${p.online ? '<span class="mdt-tag ok">Inside</span>' : '<span class="mdt-tag">Away</span>'}${p.online ? `<button class="mdt-btn stop" data-act="release" data-id="${p.charId}">Release now</button>` : ''}</div>`).join('')}</div>` : '<div class="mdt-empty">Nobody is serving time</div>';
    },
  };

  const render = (app, view) => {
    const s = app.state; const phone = view && view.size === 'phone';
    if (!s.me) {
      const body = s.err ? esc(s.err) : 'Connecting to dispatch…';
      return `<div class="mdt ${phone ? 'phone' : ''}" style="display:grid;place-items:center"><div class="mdt-empty" style="margin:2rem">${body}</div></div>`;
    }
    const inner = s.screen === 'person' && s.person ? screens.person(app) : s.screen === 'report' && s.edit ? screens.report(app) : (screens[s.tab] || screens.home)(app);
    return chrome(app, phone, inner);
  };

  const reloadPerson = (app, id) => ask(app, 'person', { charId: id }, (r) => { app.state.person = r; app.state.screen = 'person'; });

  const actions = {
    noop() {},
    dismissErr(app) { app.state.err = null; },
    async tab(app, d) { const s = app.state; s.tab = d.t; s.screen = null; s.person = null; s.edit = null; s.err = null; await loadTab(app, d.t); },
    backScreen(app) { const s = app.state; s.screen = null; s.person = null; s.edit = null; s.charges = []; },
    async status(app, d) { await ask(app, 'status', { status: d.s }, () => { app.state.me.status = d.s; }); },
    async attach(app, d) { await ask(app, 'attach', { id: Number(d.id) }, async () => { app.state.me.status = 'enroute'; await loadTab(app, app.state.tab); }); },
    async detach(app, d) { await ask(app, 'detach', { id: Number(d.id) }, async () => { app.state.me.status = 'available'; await loadTab(app, app.state.tab); }); },
    async clearCall(app, d) { await ask(app, 'clearCall', { id: Number(d.id) }, () => loadTab(app, app.state.tab)); },
    async searchPeople(app) { await ask(app, 'people', { q: app.state.f.peopleQ || '' }, (r) => { app.state.peopleList = r; app.state.peopleSearched = true; }); },
    async openPerson(app, d) { app.state.tab = 'people'; app.state.charges = []; await reloadPerson(app, Number(d.id)); },
    addCharge(app, d) { const ch = app.state.charges; const hit = ch.find((c) => c.code === d.code); if (hit) hit.count = Math.min(20, hit.count + 1); else ch.push({ code: d.code, count: 1 }); },
    chargeCount(app, d) { const ch = app.state.charges; const i = Number(d.i); const c = ch[i]; if (!c) return; c.count = Math.min(20, c.count + Number(d.d)); if (c.count < 1) ch.splice(i, 1); },
    async fine(app) {
      const p = app.state.person;
      await ask(app, 'fine', { charId: p.charId, charges: app.state.charges }, async (r) => { app.toast('Fined ' + money(r.amount)); app.state.charges = []; await reloadPerson(app, p.charId); });
    },
    async jail(app) {
      const p = app.state.person;
      await ask(app, 'jail', { charId: p.charId, charges: app.state.charges, reason: app.state.charges.map((c) => c.code).join(', ') }, async (r) => { app.toast('Sent to prison for ' + r.months + ' months'); app.state.charges = []; await reloadPerson(app, p.charId); });
    },
    async issueWarrant(app) { const p = app.state.person; await ask(app, 'issueWarrant', { charId: p.charId, reason: app.state.f.warrantReason || '' }, async () => { app.state.f.warrantReason = ''; await reloadPerson(app, p.charId); }); },
    async closeWarrant(app, d) { await ask(app, 'closeWarrant', { id: Number(d.id), status: d.s }, async () => { if (app.state.person) await reloadPerson(app, app.state.person.charId); else await loadTab(app, 'warrants'); }); },
    async addNote(app) { const p = app.state.person; await ask(app, 'addNote', { charId: p.charId, text: app.state.f.noteText || '' }, async () => { app.state.f.noteText = ''; await reloadPerson(app, p.charId); }); },
    async boloPerson(app) { const p = app.state.person; await ask(app, 'addBolo', { charId: p.charId, reason: app.state.f.boloReason || '' }, () => { app.state.f.boloReason = ''; app.toast('Lookout issued'); }); },
    async searchPlate(app) { await ask(app, 'vehicles', { q: app.state.f.plateQ || '' }, (r) => { app.state.vehicleList = r; app.state.plateSearched = true; }); },
    async boloPlate(app) { await ask(app, 'addBolo', { plate: app.state.f.boloPlate || '', reason: app.state.f.boloPlateReason || '' }, () => { app.state.f.boloPlate = ''; app.state.f.boloPlateReason = ''; app.toast('Lookout issued'); }); },
    async closeBolo(app, d) { await ask(app, 'closeBolo', { id: Number(d.id) }, () => loadTab(app, 'bolos')); },
    async searchReports(app) { await loadTab(app, 'reports'); },
    newReport(app) { app.state.edit = { title: '', body: '', status: 'open', people: [], charges: [] }; app.state.screen = 'report'; },
    async openReport(app, d) { app.state.tab = 'reports'; await ask(app, 'report', { id: Number(d.id) }, (r) => { app.state.edit = r; app.state.screen = 'report'; app.state.person = null; }); },
    addPerson(app, d) { const s = app.state; const id = Number(s.f.addPersonId); if (!id) { s.err = 'Type the citizen ID first'; return; } s.edit.people.push({ charId: id, role: d.role }); s.f.addPersonId = ''; },
    removePerson(app, d) { app.state.edit.people.splice(Number(d.i), 1); },
    addReportCharge(app) {
      const s = app.state; const code = String(s.f.addChargeCode || '').trim().toUpperCase(); const who = Number(s.f.addChargeFor);
      if (!penalMap(app)[code]) { s.err = 'There is no charge with that code. The penal code lists them all.'; return; }
      if (!who) { s.err = 'Add the citizen ID of the person charged'; return; }
      const hit = s.edit.charges.find((c) => c.code === code && Number(c.charId) === who);
      if (hit) hit.count += 1; else s.edit.charges.push({ code, charId: who, count: 1 });
      s.f.addChargeCode = '';
    },
    removeReportCharge(app, d) { app.state.edit.charges.splice(Number(d.i), 1); },
    setStatus(app, d) { app.state.edit.status = d.v; },
    async saveReport(app) {
      const r = app.state.edit;
      await ask(app, 'saveReport', { id: r.id, rev: r.rev, title: r.title, body: r.body, status: r.status, people: r.people, charges: r.charges },
        (res) => { r.id = res.id; r.rev = res.rev; app.toast('Report saved'); });
    },
    pCat(app, d) { app.state.f.pCat = d.g; },
    async savePenal(app) {
      const f = app.state.f;
      await ask(app, 'savePenal', { code: String(f.pCode || '').trim().toUpperCase(), title: f.pTitle, category: f.pCat, fine: Number(f.pFine), months: Number(f.pMonths) },
        async () => { f.pCode = f.pTitle = f.pFine = f.pMonths = ''; app.state.penal = null; await loadTab(app, 'penal'); app.toast('Charge saved'); });
    },
    async removePenal(app, d) { await ask(app, 'removePenal', { code: d.code }, async () => { app.state.penal = null; await loadTab(app, 'penal'); }); },
    async release(app, d) { await ask(app, 'release', { charId: Number(d.id) }, () => loadTab(app, 'prison')); },
  };

  const BIND = { editTitle: (s, v) => { s.edit.title = v; }, editBody: (s, v) => { s.edit.body = v; } };
  const LIVE_BIND = { chargeQ: true };

  const wire = (app, root) => {
    root.addEventListener('click', async (e) => {
      const t = e.target.closest('[data-act]');
      if (!t || !root.contains(t) || t.disabled) return;
      const fn = actions[t.dataset.act];
      if (!fn) return;
      const r = fn(app, { ...t.dataset });
      draw(app);
      if (r && typeof r.then === 'function') await r;
    });
    root.addEventListener('input', (e) => {
      const t = e.target; const k = t.dataset && t.dataset.bind;
      if (!k) return;
      if (BIND[k]) BIND[k](app.state, t.value); else app.state.f[k] = t.value;
      if (LIVE_BIND[k]) draw(app);
    });
    root.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter' || e.shiftKey) return;
      const t = e.target; const act = t.dataset && t.dataset.enter;
      if (!act || !actions[act]) return;
      e.preventDefault();
      const r = actions[act](app, { ...t.dataset });
      draw(app);
      if (r && typeof r.then === 'function') r.then(() => draw(app));
    });
  };

  WhipPhone.module({
    id: 'pwpmdt', name: 'MDT', version: '0.2.0', order: 5, icon: I.badge, css: CSS, globalCss: FONTS, statusBar: 'light',
    state: () => ({ tab: 'home', screen: null, me: null, err: null, busy: false, charges: [], f: { pCat: 'misdemeanor' } }),
    mount(app, el, view) {
      el.innerHTML = '<div class="mdt-root"></div>';
      live.set(app, { el, view });
      wire(app, el);
      draw(app);
    },
    update(app, el, view) {
      const ctx = live.get(app);
      if (!ctx) return;
      if (ctx.el !== el || (view && ctx.view && ctx.view.size !== view.size)) { ctx.el = el; ctx.view = view; draw(app); }
    },
    unmount(app) { live.delete(app); },
    async open(app) {
      await ask(app, 'me', {}, (r) => { app.state.me = r; });
      if (app.state.me) await loadTab(app, app.state.tab);
    },
    back(app) {
      const s = app.state;
      if (s.screen) { s.screen = null; s.person = null; s.edit = null; s.charges = []; draw(app); return true; }
      if (s.tab !== 'home') { s.tab = 'home'; loadTab(app, 'home'); draw(app); return true; }
      return false;
    },
    on: {
      alert(app, a) { const s = app.state; s.calls = [a].concat((s.calls || []).filter((c) => c.id !== a.id)); draw(app); },
      alertCleared(app, d) { const s = app.state; s.calls = (s.calls || []).filter((c) => c.id !== d.id); draw(app); },
    },
    badge(app) { return (app.state.calls || []).length || 0; },
  });
})();
