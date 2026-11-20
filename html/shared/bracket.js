(() => {
  const SRC = document.currentScript ? document.currentScript.src : '';
  if (window.PWPBracket && window.PWPBracket.src === SRC) return;
  const BASE = new URL('.', document.currentScript.src).href;

  const FONTS = `
@font-face{font-family:'PWP Hanken';font-style:normal;font-weight:500 800;font-display:swap;src:url(${BASE}fonts/HankenGrotesk.woff2) format('woff2');unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}
@font-face{font-family:'PWP Hanken';font-style:normal;font-weight:500 800;font-display:swap;src:url(${BASE}fonts/HankenGrotesk-ext.woff2) format('woff2');unicode-range:U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+1E00-1E9F,U+1EF2-1EFF,U+20A0-20AB,U+20AD-20C4,U+2C60-2C7F,U+A720-A7FF}
@font-face{font-family:'PWP JetBrains';font-style:normal;font-weight:500 600;font-display:swap;src:url(${BASE}fonts/JetBrainsMono.woff2) format('woff2')}`;
  if (!document.getElementById('pwp-bracket-fonts')) {
    const s = document.createElement('style');
    s.id = 'pwp-bracket-fonts';
    s.textContent = FONTS;
    document.head.appendChild(s);
  }

  const CSS = `
.pwp{
  --bg:#0e1013;--panel:#15181c;--panel2:#1c2026;--line:rgba(255,255,255,.08);
  --text:rgba(255,255,255,.88);--mute:rgba(255,255,255,.6);--faint:rgba(255,255,255,.4);
  --fill:rgba(255,255,255,.06);--fill2:rgba(255,255,255,.11);--fill3:rgba(255,255,255,.16);
  --sel:#eef6f8;--on-sel:#0e1013;--accent:#4fd1e8;--on-accent:#04191d;
  --danger:#ff6b6b;--warn:#f2c94c;--ok:#57d38c;--route:#8fb8ff;
  --r:.625rem;--rs:.375rem;
  --ui:'PWP Hanken','Hanken Grotesk','Segoe UI',system-ui,sans-serif;
  --mono:'PWP JetBrains','JetBrains Mono',Consolas,monospace;
  --out:cubic-bezier(.23,1,.32,1);
  color:var(--text);font-family:var(--ui);font-size:.9375rem;line-height:1.4;font-weight:500;
  -webkit-font-smoothing:antialiased;
}
.pwp *,.pwp *::before,.pwp *::after{box-sizing:border-box}
.pwp :where(button,input,textarea){font:inherit;color:inherit}
.pwp :where(button){cursor:pointer;background:none;border:0;padding:0;text-align:inherit}
.pwp :where(button[disabled]){cursor:default;opacity:.4}
.pwp :where(svg){width:1.125rem;height:1.125rem;flex:none}
.pwp ::selection{background:var(--accent);color:var(--on-accent)}
.pwp :focus-visible{outline:.125rem solid var(--accent);outline-offset:.125rem}
.pwp ::-webkit-scrollbar{width:.375rem;height:.375rem}
.pwp ::-webkit-scrollbar-track{background:transparent}
.pwp ::-webkit-scrollbar-thumb{background:var(--fill2);border-radius:1rem}
.pwp ::-webkit-scrollbar-thumb:hover{background:var(--fill3)}
.pwp ::-webkit-scrollbar-button,.pwp ::-webkit-scrollbar-corner{display:none;background:transparent}
@supports not selector(::-webkit-scrollbar){.pwp *{scrollbar-width:thin;scrollbar-color:var(--fill2) transparent}}
.pwp .mono,.pwp .num{font-family:var(--mono);font-variant-numeric:tabular-nums}
.pwp .num{font-weight:600}

.pwp-kbd{font-family:var(--mono);font-size:.6875rem;font-weight:600;color:var(--text);background:var(--fill2);border-radius:.25rem;padding:.125rem .375rem;line-height:1.4;white-space:nowrap}
.pwp-lbl{font-size:.6875rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint);margin:0 0 .5rem}

.pwp-press{transition:background-color .15s,color .15s,transform .16s var(--out)}
.pwp-press:active:not([disabled]){transform:scale(.97)}
.pwp-btn{display:inline-flex;align-items:center;justify-content:center;gap:.5rem;min-height:2.5rem;padding:0 .875rem;border-radius:var(--rs);background:var(--fill);font-weight:600;font-size:.8125rem;white-space:nowrap}
.pwp-btn:hover:not([disabled]){background:var(--fill2)}
.pwp-btn svg{width:1rem;height:1rem;color:var(--mute)}
.pwp-btn.sm{min-height:2rem;padding:0 .625rem;font-size:.75rem}
.pwp-btn.inv{background:var(--sel);color:var(--on-sel)}
.pwp-btn.inv svg{color:inherit}
.pwp-btn.danger{background:transparent;box-shadow:inset 0 0 0 1px var(--danger);color:var(--danger)}
.pwp-btn.danger svg{color:inherit}
.pwp-btn.ghost{background:transparent}
.pwp-btn.ghost:hover:not([disabled]){background:var(--fill)}
.pwp-btn.icon{padding:0;width:2rem;min-height:2rem}
.pwp-cta{display:inline-flex;align-items:center;justify-content:center;gap:.625rem;min-height:2.75rem;padding:0 1.125rem;border-radius:var(--rs);background:var(--accent);color:var(--on-accent);font-weight:700;font-size:.9375rem;white-space:nowrap}
.pwp-cta svg{width:1.125rem;height:1.125rem}
.pwp-cta .pwp-kbd{background:rgba(0,0,0,.18);color:inherit}
.pwp-cta.has-kbd{padding-right:.625rem}
.pwp-cta.wide{width:100%}

.pwp-seg{position:relative;display:inline-flex;gap:.125rem;padding:.1875rem;border-radius:var(--rs);background:var(--fill)}
.pwp-seg>button{position:relative;z-index:1;min-height:1.875rem;padding:0 .75rem;border-radius:.25rem;font-size:.8125rem;font-weight:600;color:var(--mute);display:inline-flex;align-items:center;justify-content:center;gap:.4375rem;transition:color .15s}
.pwp-seg>button.on{color:var(--on-sel)}
.pwp-seg i{width:.4375rem;height:.4375rem;border-radius:50%;background:currentColor;flex:none}
.pwp-seg>button.on i{background:var(--dot,currentColor)}
.pwp-glider{position:absolute;left:0;top:0;z-index:0;pointer-events:none;background:var(--sel);border-radius:.25rem;will-change:transform}

.pwp-in{width:100%;min-height:2.625rem;padding:.5rem .75rem;border-radius:var(--rs);border:0;background:var(--fill);box-shadow:inset 0 0 0 1px transparent;outline:none;transition:box-shadow .15s,background-color .15s}
.pwp-in:hover{background:var(--fill2)}
.pwp-in:focus{box-shadow:inset 0 0 0 1px var(--accent);background:var(--fill)}
.pwp-in::placeholder{color:var(--faint)}
textarea.pwp-in{min-height:8rem;resize:vertical;line-height:1.5}
.pwp-in.mono{text-transform:uppercase}
.pwp-in.mono::placeholder{text-transform:none;font-family:var(--ui)}
.pwp-search{display:flex;align-items:center;gap:.625rem;min-height:2.375rem;padding:0 .75rem;border-radius:var(--rs);background:var(--fill);color:var(--faint);transition:box-shadow .15s}
.pwp-search:focus-within{box-shadow:inset 0 0 0 1px var(--accent)}
.pwp-search svg{width:1.0625rem;height:1.0625rem}
.pwp-search input{flex:1;min-width:0;background:none;border:0;outline:none;color:var(--text);font-size:.875rem}
.pwp-search input::placeholder{color:var(--faint)}
.pwp-search:focus-within .pwp-kbd{opacity:0}

.pwp-card{position:relative;background:var(--panel);border-radius:var(--r);padding:.8125rem .875rem}
.pwp-row{display:flex;align-items:center;gap:.75rem;padding:.5625rem 0;min-width:0}
.pwp-row+.pwp-row{border-top:1px solid var(--line)}
.pwp-row .t{flex:1;min-width:0;font-weight:600;font-size:.875rem;overflow-wrap:anywhere}
.pwp-row .s{display:block;font-weight:500;color:var(--mute);font-size:.75rem}
.pwp-row .acts{display:flex;gap:.375rem;flex-wrap:wrap;justify-content:flex-end}
button.pwp-row{width:100%;border-radius:.25rem;transition:background-color .15s,transform .16s var(--out)}
button.pwp-row:hover{background:var(--fill)}
button.pwp-row:active{transform:scale(.985)}
.pwp-code{font-family:var(--mono);font-size:.75rem;font-weight:600;color:var(--mute);min-width:2.5rem}
.pwp-empty{padding:1.25rem .75rem;text-align:center;color:var(--faint);font-size:.8125rem}

.pwp-flag{display:inline-flex;align-items:center;font-size:.6875rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;padding:.25rem .5rem;border-radius:var(--rs);background:var(--fill);color:var(--mute);white-space:nowrap}
.pwp-flag.danger{background:var(--danger);color:#fff}
.pwp-flag.warn{background:transparent;box-shadow:inset 0 0 0 1px var(--warn);color:var(--warn)}
.pwp-flag.ok{background:transparent;box-shadow:inset 0 0 0 1px var(--ok);color:var(--ok)}
.pwp-flag.route{background:transparent;box-shadow:inset 0 0 0 1px var(--route);color:var(--route)}
.pwp-plate{display:inline-block;font-family:var(--mono);font-weight:600;font-size:.75rem;letter-spacing:.06em;padding:.1875rem .4375rem;border-radius:.1875rem;background:#f4f4ee;color:#18295a;box-shadow:inset 0 0 0 1px #9aa3b2;white-space:nowrap}

.pwp-bracket{position:relative}
.pwp-bracket::before,.pwp-bracket::after{content:'';position:absolute;width:.625rem;height:.625rem;border-color:var(--bc,var(--accent));border-style:solid;pointer-events:none}
.pwp-bracket::before{left:-1px;top:-1px;border-width:.125rem 0 0 .125rem;border-top-left-radius:var(--r)}
.pwp-bracket::after{right:-1px;bottom:-1px;border-width:0 .125rem .125rem 0;border-bottom-right-radius:var(--r)}
.pwp-bracket.danger{--bc:var(--danger)}

.pwp-err{display:flex;align-items:flex-start;gap:.625rem;padding:.625rem .75rem;border-radius:var(--rs);background:rgba(255,107,107,.12);color:#ffd3d3;font-size:.8125rem}
.pwp-err svg{color:var(--danger);width:1rem;height:1rem;margin-top:.0625rem}
.pwp-err span{flex:1;overflow-wrap:anywhere}
.pwp-busy{position:absolute;left:0;right:0;top:0;height:.125rem;overflow:hidden;pointer-events:none;opacity:0;transition:opacity .2s}
.pwp-busy.on{opacity:1}
.pwp-busy::before{content:'';position:absolute;top:0;bottom:0;width:30%;background:var(--accent);animation:pwp-busy 1s linear infinite}
@keyframes pwp-busy{from{transform:translateX(-100%)}to{transform:translateX(340%)}}

.pwp-step{display:flex;align-items:center;gap:.25rem}
.pwp-step button{width:1.75rem;height:1.75rem;border-radius:var(--rs);background:var(--fill2);display:grid;place-items:center;transition:background-color .15s,transform .16s var(--out)}
.pwp-step button:hover{background:var(--fill3)}
.pwp-step button:active{transform:scale(.94)}
.pwp-step svg{width:.875rem;height:.875rem}
.pwp-step .num{min-width:1.25rem;text-align:center}

.pwp-scrim{position:absolute;inset:0;z-index:5;background:rgba(0,0,0,.4);opacity:0;pointer-events:none;transition:opacity .16s}
.pwp-scrim.on{opacity:1;pointer-events:auto;transition-duration:.24s}
.pwp-sheet{position:absolute;z-index:6;background:var(--panel);display:flex;flex-direction:column;gap:.75rem;padding:1.125rem;transition:transform .16s var(--out)}
.pwp-sheet.pwp-from-right{top:0;right:0;bottom:0;width:27.5rem;max-width:100%;border-left:1px solid var(--line);transform:translateX(102%)}
.pwp-sheet.pwp-from-below{left:0;right:0;bottom:0;max-height:88%;border-top:1px solid var(--line);border-radius:var(--r) var(--r) 0 0;transform:translateY(102%)}
.pwp-sheet.on{transform:none}
.pwp-sheet h2{margin:0;font-size:1.25rem;font-weight:800;letter-spacing:-.02em;line-height:1.15;display:flex;justify-content:space-between;align-items:flex-start;gap:.75rem;text-wrap:balance}
.pwp-sheet .body{flex:1;min-height:0;overflow-y:auto;display:grid;align-content:start;gap:.75rem}
.pwp-sheet .foot{display:grid;gap:.625rem}
.pwp-tot{display:flex;gap:1.375rem;align-items:flex-end;padding-top:.75rem;border-top:1px solid var(--line)}
.pwp-tot div{display:grid}
.pwp-tot small{font-size:.6875rem;font-weight:700;letter-spacing:.14em;text-transform:uppercase;color:var(--faint)}
.pwp-tot b{font-size:1.5rem}
.pwp-two{display:grid;grid-template-columns:1fr 1fr;gap:.625rem}

.pwp-fade{animation:pwp-fade .14s var(--out)}
@keyframes pwp-fade{from{opacity:0;transform:translateY(.1875rem)}to{opacity:1;transform:none}}
@media (prefers-reduced-motion:reduce){.pwp-fade{animation:none}.pwp-busy::before{animation-duration:2s}}
`;

  const icon = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;
  const icons = {
    board: icon('<rect x="3" y="4" width="18" height="15" rx="2"/><path d="M7.5 9.5l4.5 4 4.5-5"/><circle cx="7.5" cy="9.5" r="1.3"/><circle cx="12" cy="13.5" r="1.3"/><circle cx="16.5" cy="8.5" r="1.3"/>'),
    badge: icon('<path d="M12 2.5l7.5 3v5.7c0 4.6-3.2 8.5-7.5 10.3-4.3-1.8-7.5-5.7-7.5-10.3V5.5z"/><path d="M12 8.2l1.3 2.6 2.9.4-2.1 2 .5 2.9-2.6-1.4-2.6 1.4.5-2.9-2.1-2 2.9-.4z"/>'),
    dispatch: icon('<path d="M4 17h16M6 17v-5a6 6 0 0112 0v5M12 3v2M9 20h6"/>'),
    records: icon('<circle cx="12" cy="8" r="3.8"/><path d="M4.5 20.5c1-3.8 4-5.8 7.5-5.8s6.5 2 7.5 5.8"/>'),
    report: icon('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 12h5M10 16h5"/>'),
    wanted: icon('<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>'),
    command: icon('<path d="M12 2.5l7.5 3v5.7c0 4.6-3.2 8.5-7.5 10.3-4.3-1.8-7.5-5.7-7.5-10.3V5.5z"/>'),
    note: icon('<path d="M5 4h14v12l-4 4H5z"/><path d="M15 20v-4h4M9 9h6M9 13h4"/>'),
    gavel: icon('<path d="M14 4l6 6M12 6l6 6M11 7l-7 7 3 3 7-7M4 20h9"/>'),
    car: icon('<path d="M5 15l1.6-4.8A2 2 0 018.5 9h7a2 2 0 011.9 1.2L19 15"/><rect x="3" y="15" width="18" height="4" rx="1"/><path d="M7 19v1.5M17 19v1.5"/>'),
    shirt: icon('<path d="M8 3l-5 3 2 4 2-1v12h10V9l2 1 2-4-5-3c-.5 1.7-2 3-4 3s-3.5-1.3-4-3z"/>'),
    gun: icon('<path d="M3 8h16l2 2v2h-6l-1 2h-3l-1 5H6l1-5H3z"/><path d="M11 12v2"/>'),
    locker: icon('<rect x="5" y="3" width="14" height="18" rx="1"/><path d="M12 3v18M9 10v2M15 10v2"/>'),
    box: icon('<path d="M3 7l9-4 9 4v10l-9 4-9-4z"/><path d="M3 7l9 4 9-4M12 11v10"/>'),
    clock: icon('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>'),
    search: icon('<circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.2-4.2"/>'),
    plus: icon('<path d="M12 5v14M5 12h14"/>'),
    minus: icon('<path d="M5 12h14"/>'),
    x: icon('<path d="M6 6l12 12M18 6L6 18"/>'),
    back: icon('<path d="M15 5l-7 7 7 7"/>'),
    alert: icon('<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17.5v.5"/>'),
    arrow: icon('<path d="M5 12h14M13 6l6 6-6 6"/>'),
    locate: icon('<circle cx="12" cy="12" r="6.5"/><circle cx="12" cy="12" r="2"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3"/>'),
    map: icon('<path d="M3 6.5l6-2.5 6 2.5 6-2.5v13.5l-6 2.5-6-2.5-6 2.5z"/><path d="M9 4v13.5M15 6.5V20"/>'),
    list: icon('<path d="M9 6h11M9 12h11M9 18h11"/><circle cx="4.5" cy="6" r=".6"/><circle cx="4.5" cy="12" r=".6"/><circle cx="4.5" cy="18" r=".6"/>'),
    pin: icon('<path d="M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0113 0c0 5.4-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.3"/>'),
    more: icon('<circle cx="5.5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="18.5" cy="12" r="1"/>'),
    camera: icon('<path d="M4 8h3l1.6-2.5h6.8L17 8h3v11H4z"/><circle cx="12" cy="13.5" r="3.5"/>'),
  };

  const springAt = (t, response, damping) => {
    const w = (2 * Math.PI) / response;
    if (damping >= 1) return 1 - Math.exp(-w * t) * (1 + w * t);
    const wd = w * Math.sqrt(1 - damping * damping);
    return 1 - Math.exp(-damping * w * t) * (Math.cos(wd * t) + ((damping * w) / wd) * Math.sin(wd * t));
  };
  const reduced = () => window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  const STEPS = 30;
  const motion = () => (reduced() ? { seconds: 0.42, damping: 1 } : { seconds: 0.5, damping: 0.86 });
  const progressAt = (ms) => {
    const m = motion();
    return ms >= m.seconds * 1000 ? 1 : springAt(ms / 1000, 0.38, m.damping);
  };
  const springFrames = (frameAt) => {
    const m = motion();
    const frames = [];
    for (let i = 0; i <= STEPS; i++) frames.push({ offset: i / STEPS, transform: frameAt(i === STEPS ? 1 : springAt((i * m.seconds) / STEPS, 0.38, m.damping)) });
    return { frames, duration: m.seconds * 1000 };
  };
  const play = (el, frameAt, already) => {
    if (!el || !el.animate) return null;
    const { frames, duration } = springFrames(frameAt);
    return el.animate(frames, { duration, easing: 'linear', delay: already ? -already : 0 });
  };
  const lerp = (a, b, p) => a + (b - a) * p;

  const glide = (box, memory, key) => {
    if (!box) return;
    let g = box.querySelector(':scope > .pwp-glider');
    if (!g) { g = document.createElement('span'); g.className = 'pwp-glider'; box.insertBefore(g, box.firstChild); }
    const on = box.querySelector(':scope > .on');
    if (!on) { g.style.opacity = '0'; return; }
    g.style.opacity = '';
    const to = { x: on.offsetLeft, y: on.offsetTop, w: on.offsetWidth, h: on.offsetHeight };
    const last = memory && memory[key];
    const rem = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
    const r = (px) => (px / rem).toFixed(4) + 'rem';
    g.style.width = r(to.w);
    g.style.height = r(to.h);
    g.style.transformOrigin = '0 0';
    const near = (a, b) => Math.abs(a.x - b.x) <= 0.5 && Math.abs(a.y - b.y) <= 0.5 && Math.abs(a.w - b.w) <= 0.5 && Math.abs(a.h - b.h) <= 0.5;
    const frame = (from) => (p) => `translate(${r(lerp(from.x, to.x, p))},${r(lerp(from.y, to.y, p))}) scale(${lerp(from.w / to.w, 1, p)},${lerp(from.h / to.h, 1, p)})`;
    const now = performance.now();
    g.style.transform = `translate(${r(to.x)},${r(to.y)})`;
    if (last && last.from && near(last, to) && now - last.t0 < motion().seconds * 1000) {
      play(g, frame(last.from), now - last.t0);
      return;
    }
    let from = null;
    if (last) {
      const p = last.from ? progressAt(now - last.t0) : 1;
      from = last.from ? { x: lerp(last.from.x, last.x, p), y: lerp(last.from.y, last.y, p), w: lerp(last.from.w, last.w, p), h: lerp(last.from.h, last.h, p) } : last;
    }
    const moved = from && !near(from, to);
    if (moved) play(g, frame(from));
    if (memory) memory[key] = moved ? { ...to, from, t0: now } : { ...to };
  };

  const RUNTIME_CLASSES = ['gone', 'enter', 'leave', 'kf', 'drag'];
  const kept = (n) => n.nodeType === 1 && (n.classList.contains('pwp-glider') || n.hasAttribute('data-persist'));
  const sameKind = (a, b) => a.nodeType === b.nodeType && a.nodeName === b.nodeName
    && (a.nodeType !== 1 || (a.getAttribute('data-key') || '') === (b.getAttribute('data-key') || ''));

  const morphAttrs = (o, n) => {
    const fellBack = o.tagName === 'IMG' && o.dataset.orig && o.dataset.orig === n.getAttribute('src');
    for (const at of [...o.attributes]) {
      if (at.name === 'class' || at.name === 'style' || n.hasAttribute(at.name)) continue;
      if (fellBack && at.name === 'data-orig') continue;
      o.removeAttribute(at.name);
    }
    for (const at of [...n.attributes]) {
      if (at.name === 'class') continue;
      if (fellBack && (at.name === 'src' || at.name === 'data-alt')) continue;
      if (o.getAttribute(at.name) !== at.value) o.setAttribute(at.name, at.value);
    }
    const runtime = RUNTIME_CLASSES.filter((c) => o.classList.contains(c));
    const cls = [n.getAttribute('class') || '', ...runtime].join(' ').trim();
    if ((o.getAttribute('class') || '') !== cls) { if (cls) o.setAttribute('class', cls); else o.removeAttribute('class'); }
    if ((o.tagName === 'INPUT' || o.tagName === 'TEXTAREA') && document.activeElement !== o && o.value !== n.value) o.value = n.value;
  };

  const morphKids = (o, n) => {
    const old = [...o.childNodes].filter((c) => !kept(c));
    const want = [...n.childNodes];
    want.forEach((w, i) => {
      const c = old[i];
      if (!c) o.appendChild(w);
      else if (!sameKind(c, w)) o.replaceChild(w, c);
      else if (c.nodeType === 1) { morphAttrs(c, w); if (c.tagName !== 'TEXTAREA' || document.activeElement !== c) morphKids(c, w); }
      else if (c.nodeValue !== w.nodeValue) c.nodeValue = w.nodeValue;
    });
    for (let i = want.length; i < old.length; i++) old[i].remove();
  };

  const morph = (el, html) => {
    const t = document.createElement('template');
    t.innerHTML = html;
    morphKids(el, t.content);
  };

  const settle = (el, axis, percent) => {
    play(el, (p) => `translate${axis === 'y' ? 'Y' : 'X'}(${(percent * (1 - p)).toFixed(3)}%)`);
  };

  const esc = (v) => String(v == null ? '' : v).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const money = (n) => '$' + Math.round(Number(n) || 0).toLocaleString('en-US');

  window.PWPBracket = Object.freeze({ src: SRC, base: BASE, fonts: FONTS, css: CSS, icons, glide, settle, play, esc, money, morph });
})();
