(() => {
  const B = window.PWPBracket;
  const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pure-whip-police';

  const CSS = `
html{--design-w:70;--design-h:67.5;font-size:max(min(calc(100vh / var(--design-h)),calc(100vw / var(--design-w))),.75rem)}
html,body{margin:0;height:100%;background:transparent;overflow:hidden}
#app{position:fixed;inset:0;display:flex;align-items:center;pointer-events:none}
#app.at-right{justify-content:flex-end;padding-right:6rem}
#app.at-right.wide{padding-right:4rem}
#app.at-center{justify-content:center}
.grow{flex:1}

.pick{position:relative;display:grid;gap:.125rem;padding:.25rem 0 1rem}
.pick>button{position:relative;z-index:1;display:flex;align-items:center;gap:.875rem;padding:.625rem .75rem;border-radius:var(--r);transition:color .15s,transform .16s var(--out)}
.pick>button:hover:not(.on):not(.locked){background:var(--fill)}
.pick>button:active:not(.locked){transform:scale(.985)}
.pick>button.on{color:var(--on-sel)}
.pick>button.locked{cursor:default}
.pick>button.locked .art{opacity:.45}
.pick>button.locked .t{color:var(--faint)}
.pick>.pwp-glider{border-radius:var(--r)}
.pick .t{flex:1;min-width:0;font-weight:700;font-size:.9375rem;overflow-wrap:anywhere}
.pick .t .s{display:block;font-weight:500;font-size:.75rem;color:var(--mute)}
.pick>button.on .t .s{color:rgba(14,16,19,.6)}

.art{position:relative;flex:none;display:grid;place-items:center;border-radius:var(--rs);background:var(--fill);color:var(--faint);overflow:hidden;transition:background-color .15s}
.art>svg{width:45%;height:45%}
.art>img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain}
.art>img.gone{display:none}
.art>img:not(.gone)+svg{display:none}
.pick>button.on .art{background:rgba(14,16,19,.08)}
.art.top{width:3.5rem;height:3.5rem}
.art.car{width:6rem;height:3.375rem}
.art.tier{width:2.75rem;height:2.75rem}

.side{width:26rem;max-height:46rem}
.out{display:flex;align-items:center;gap:.75rem;margin:0 1.25rem .75rem;padding:.625rem .75rem;border-radius:var(--r);background:var(--panel)}
.out .t{flex:1;min-width:0;font-weight:700;font-size:.875rem}
.out .t .s{display:block;font-weight:500;font-size:.75rem;color:var(--mute)}

.armory{width:54rem;height:42rem;display:grid;grid-template-columns:14rem minmax(0,1fr);grid-template-rows:auto minmax(0,1fr) auto}
.armory .pwp-panel-head{grid-column:1/-1}
.armory .tiers{grid-row:2/4;border-right:1px solid var(--line);padding:0 .75rem 1rem;overflow-y:auto}
.armory .tiers .pick{padding:0}
.items{overflow-y:auto;padding:0 1.25rem 1rem;display:grid;grid-template-columns:repeat(auto-fill,minmax(10.5rem,1fr));gap:.625rem;align-content:start}
.item{background:var(--panel);border-radius:var(--r);padding:.75rem;display:grid;gap:.5rem;box-shadow:inset 0 0 0 1px transparent;transition:box-shadow .15s}
.item.picked{box-shadow:inset 0 0 0 1px var(--accent)}
.item .art{width:100%;height:5.5rem}
.item .nm{font-weight:700;font-size:.875rem;line-height:1.2;overflow-wrap:anywhere}
.item .row{display:flex;align-items:center;justify-content:space-between;gap:.5rem}
.item .w{font-family:var(--mono);font-size:.75rem;color:var(--faint)}
.armory .pwp-panel-foot{grid-column:2}
.cost{font-size:.8125rem;color:var(--mute)}
.cost b{color:var(--text)}

.storage{width:64rem;height:44rem;display:grid;grid-template-rows:auto minmax(0,1fr) auto}
.stores{display:grid;grid-template-columns:1fr 1fr;gap:1.25rem;padding:0 1.25rem;min-height:0}
.store{display:flex;flex-direction:column;min-height:0}
.store-h{display:flex;align-items:baseline;justify-content:space-between;gap:.75rem;padding:0 0 .625rem}
.store-h b{font-size:1rem;font-weight:800}
.store-h span{font-family:var(--mono);font-size:.75rem;color:var(--mute)}
.slots{flex:1;min-height:0;overflow-y:auto;display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:.375rem;align-content:start;padding-right:.25rem}
.slot{aspect-ratio:1;border-radius:var(--rs);background:var(--panel);position:relative;display:block;transition:background-color .15s,transform .16s var(--out)}
.slot:hover{background:var(--panel2)}
.slot:active{transform:scale(.97)}
.slot.empty{background:rgba(255,255,255,.025);cursor:default}
.slot .art{position:absolute;inset:18% 14% 16%;background:transparent}
.slot .n{position:absolute;right:.375rem;bottom:.25rem;font-family:var(--mono);font-size:.6875rem;font-weight:600;color:var(--text)}
.slot .nm{position:absolute;left:.375rem;top:.3125rem;right:.375rem;font-size:.6875rem;font-weight:600;color:var(--faint);line-height:1.15;text-align:left;overflow-wrap:anywhere}

.enter{animation:st-enter .32s var(--out) both}
.leave{animation:st-leave .16s var(--out) both}
@keyframes st-enter{from{opacity:0;transform:translateY(.75rem)}to{opacity:1;transform:none}}
@keyframes st-leave{to{opacity:0;transform:translateY(.5rem)}}
@media (max-aspect-ratio:4/3){#app.at-right,#app.at-right.wide{padding-right:2rem}}
@media (prefers-reduced-motion:reduce){.enter,.leave{animation-duration:.01s}}
`;

  const style = document.createElement('style');
  style.textContent = B.css + CSS;
  document.head.appendChild(style);

  const I = B.icons;
  const esc = B.esc;
  const root = document.getElementById('app');
  const mem = {};
  let s = null;

  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) })
    .then((r) => r.json()).catch(() => ({ ok: false, why: 'No answer from the game' }));

  const art = (cls, src, glyph, alt) => {
    const pic = src || alt;
    const next = src ? alt : null;
    return `<span class="art ${cls}">${pic ? `<img src="${esc(pic)}" alt=""${next ? ` data-alt="${esc(next)}"` : ''}>` : ''}${glyph}</span>`;
  };
  const kg = (n) => (Math.round((Number(n) || 0) * 10) / 10).toFixed(1);
  const hint = (pairs) => `<div class="pwp-hint">${pairs.map(([k, l]) => `<span><span class="pwp-kbd">${k}</span>${l}</span>`).join('')}</div>`;
  const head = (title) => `<div class="pwp-panel-head"><div class="k"><small>${esc(s.data.short)} · ${esc(s.data.title)}</small><h1>${esc(title)}</h1></div><button class="pwp-btn ghost icon pwp-press" data-a="close" aria-label="Close">${I.x}</button></div>`;
  const err = () => (s.err ? `<div class="pwp-err" role="alert">${I.alert}<span>${esc(s.err)}</span></div>` : '');
  const busy = () => `<div class="pwp-busy ${s.busy ? 'on' : ''}"></div>`;

  const VIEWS = {
    wardrobe() {
      const d = s.data;
      const rows = d.uniforms.map((u) => `<button class="${s.pick === u.i ? 'on' : ''} ${u.locked ? 'locked' : ''}" data-a="wear" data-i="${u.i}" ${u.locked ? 'aria-disabled="true"' : ''}>${art('top', u.img, I.shirt)}<span class="t">${esc(u.label)}${u.locked ? `<span class="s">${esc(u.locked)}</span>` : ''}</span></button>`).join('')
        + `<button class="${s.pick === 'own' ? 'on' : ''}" data-a="wear" data-i="own">${art('top', d.ownImg, I.shirt)}<span class="t">Own clothes</span></button>`;
      return `<section class="pwp-panel side">${busy()}${head('Uniform')}<div class="pwp-panel-body"><div class="pick" data-g="list">${rows}</div></div>
        <div class="pwp-panel-foot">${err()}${hint([['↑↓', 'Change'], ['Esc', 'Close']])}</div></section>`;
    },
    garage() {
      const d = s.data;
      const car = d.cars.find((c) => c.i === s.pick);
      const canTake = car && !car.locked && !d.out;
      return `<section class="pwp-panel side">${busy()}${head('Take a car')}
        ${d.out ? `<div class="out pwp-bracket">${art('car', d.out.img, I.car)}<span class="t">Your ${esc(d.out.label)} is out<span class="s">Return it before you take another</span></span><button class="pwp-btn sm pwp-press" data-a="return">Return</button></div>` : ''}
        <div class="pwp-panel-body"><div class="pick" data-g="list">${d.cars.map((c) => `<button class="${s.pick === c.i ? 'on' : ''} ${c.locked ? 'locked' : ''}" data-a="pickCar" data-i="${c.i}">${art('car', c.img, I.car)}<span class="t">${esc(c.label)}<span class="s">${c.locked ? esc(c.locked) : `<span class="mono">${esc(c.model)}</span>`}</span></span></button>`).join('')}</div></div>
        <div class="pwp-panel-foot">${err()}${hint([['Esc', 'Close']])}<button class="pwp-cta has-kbd pwp-press" data-a="take" ${canTake ? '' : 'disabled'}>Take ${esc(car ? car.label : 'a car')}<span class="pwp-kbd">Enter</span></button></div></section>`;
    },
    armory() {
      const d = s.data;
      const tier = d.tiers.find((t) => t.id === s.pick) || d.tiers[0];
      const want = s.take[tier.id] || {};
      const n = Object.values(want).reduce((a, b) => a + b, 0);
      const cost = tier.items.reduce((a, it) => a + (want[it.key] || 0) * (it.price || 0), 0);
      return `<section class="pwp-panel armory">${busy()}${head('Sign out kit')}
        <div class="tiers"><div class="pick" data-g="tiers">${d.tiers.map((t) => `<button class="${t.id === tier.id ? 'on' : ''} ${t.locked ? 'locked' : ''}" data-a="tier" data-t="${esc(t.id)}">${art('tier', `../img/tiers/${t.id}.webp`, I.gun)}<span class="t">${esc(t.label)}${t.locked ? `<span class="s">${esc(t.locked)}</span>` : ''}</span></button>`).join('')}</div></div>
        <div class="items">${tier.locked ? `<div class="pwp-empty" style="grid-column:1/-1">${esc(tier.locked)}</div>` : tier.items.map((it) => `<div class="item ${want[it.key] ? 'picked' : ''}">${art('', it.img, I.box, `../img/items/${it.key}.webp`)}<span class="nm">${esc(it.label)}</span><div class="row"><span class="w">${it.price ? B.money(it.price) : it.weight != null ? kg(it.weight) + ' kg' : ''}</span><span class="pwp-step"><button data-a="count" data-k="${esc(it.key)}" data-d="-1" aria-label="One less">${I.minus}</button><span class="num">${want[it.key] || 0}</span><button data-a="count" data-k="${esc(it.key)}" data-d="1" aria-label="One more">${I.plus}</button></span></div></div>`).join('')}</div>
        <div class="pwp-panel-foot">${err()}${cost ? `<span class="cost">Cost <b class="num">${B.money(cost)}</b></span>` : ''}<span class="grow"></span><button class="pwp-cta has-kbd pwp-press" data-a="armory" ${n && !tier.locked ? '' : 'disabled'}>${n ? `Take ${n} ${n === 1 ? 'item' : 'items'}` : 'Take'}<span class="pwp-kbd">Enter</span></button></div></section>`;
    },
    storage() {
      const d = s.data;
      const side = (key, label, st) => {
        const bySlot = {};
        for (const it of st.items) bySlot[it.slot] = it;
        const cells = Array.from({ length: st.slots || 0 }, (_, i) => {
          const it = bySlot[i + 1];
          return it ? `<button class="slot" data-key="${key}${i + 1}" data-a="move" data-from="${key}" data-slot="${i + 1}" title="${esc(it.label)}"><span class="nm">${esc(it.label)}</span>${art('', it.img, I.box, `../img/items/${it.item}.webp`)}<span class="n">${it.amount > 1 ? it.amount : ''}</span></button>` : `<div class="slot empty" data-key="${key}${i + 1}"></div>`;
        }).join('');
        const weight = st.maxWeight ? `${kg(st.weight)} of ${kg(st.maxWeight)} kg` : `${kg(st.weight)} kg`;
        return `<div class="store"><div class="store-h"><b>${esc(label)}</b><span>${weight}</span></div><div class="slots">${cells}</div></div>`;
      };
      return `<section class="pwp-panel storage">${busy()}${head(s.data.kind === 'locker' ? 'Your locker' : s.data.title)}
        <div class="stores">${side('pockets', 'Pockets', d.pockets)}${side('store', d.storeLabel || 'Locker', d.store)}</div>
        <div class="pwp-panel-foot">${err()}${hint([['Click', 'Move the stack'], ['Shift', 'Move one'], ['Esc', 'Close']])}</div></section>`;
    },
  };

  const viewOf = (kind) => (kind === 'locker' || kind === 'stash' ? 'storage' : kind);

  function render(fresh) {
    if (!s) { root.innerHTML = ''; return; }
    const view = viewOf(s.data.kind);
    root.className = 'pwp ' + (view === 'storage' ? 'at-center' : view === 'armory' ? 'at-right wide' : 'at-right');
    const html = VIEWS[view]();
    if (fresh || !root.firstElementChild || root.dataset.view !== view) {
      root.innerHTML = html;
      root.dataset.view = view;
      if (fresh) root.firstElementChild.classList.add('enter');
    } else {
      B.morph(root, html);
    }
    root.querySelectorAll('[data-g]').forEach((g) => B.glide(g, mem, g.dataset.g));
  }

  const BUSY_MS = 300;
  const GAP_MS = 160;
  let pending = 0;
  let busyTimer = 0;
  let lastSent = 0;

  const paced = (body) => new Promise((done) => {
    const wait = Math.max(0, lastSent + GAP_MS - performance.now());
    setTimeout(() => { lastSent = performance.now(); done(post('act', body)); }, wait);
  });

  const SHOWN = { move: true, read: true, wear: true };

  function act(action, args, after, failed) {
    const mine = s;
    const waited = !SHOWN[action];
    if (waited) pending += 1;
    if (action !== 'read') s.err = null;
    s.inflight[action] = (s.inflight[action] || 0) + 1;
    if (waited && !busyTimer) busyTimer = setTimeout(() => { busyTimer = 0; if (s === mine && pending) { s.busy = true; render(); } }, BUSY_MS);
    s.queue = s.queue.then(() => paced({ action, args })).then((r) => {
      if (waited) pending -= 1;
      if (s !== mine) return;
      s.inflight[action] -= 1;
      if (!r.ok) { s.err = r.why || 'Something went wrong'; if (failed) failed(); }
      else if (after) after(r.data);
      if (!pending) { clearTimeout(busyTimer); busyTimer = 0; s.busy = false; }
      render();
    });
  }

  const SIDES = { pockets: 'store', store: 'pockets' };

  function predictMove(from, slot, one) {
    const src = s.data[from];
    const dst = s.data[SIDES[from]];
    const it = src.items.find((x) => x.slot === slot);
    if (!it) return;
    const amount = one ? 1 : it.amount;
    const onto = dst.items.find((x) => x.item === it.item);
    if (onto) onto.amount += amount;
    else {
      const used = new Set(dst.items.map((x) => x.slot));
      let free = 1;
      while (used.has(free)) free += 1;
      if (free > (dst.slots || 0)) return;
      dst.items.push({ ...it, slot: free, amount });
    }
    it.amount -= amount;
    if (it.amount <= 0) src.items.splice(src.items.indexOf(it), 1);
  }

  function close() {
    if (!s) return;
    const panel = root.firstElementChild;
    s = null;
    post('close');
    if (!panel) return render();
    panel.classList.add('leave');
    panel.addEventListener('animationend', () => { if (!s) root.innerHTML = ''; }, { once: true });
  }

  const ACTIONS = {
    close,
    wear(d) {
      const i = d.i === 'own' ? 'own' : Number(d.i);
      const u = s.data.uniforms.find((x) => x.i === i);
      if (u && u.locked) return;
      s.pick = i;
      render();
      if (s.inflight.wear) return;
      const send = (want) => act('wear', { i: want }, () => {
        s.worn = want;
        if (s.pick !== want) send(s.pick);
      }, () => { s.pick = s.worn; });
      send(i);
    },
    pickCar(d) { const c = s.data.cars.find((x) => x.i === Number(d.i)); if (c && !c.locked) { s.pick = c.i; render(); } },
    take() { if (!s.inflight.take) act('take', { i: s.pick }, (data) => { if (data) Object.assign(s.data, data); }); },
    return() { if (!s.inflight.return) act('return', {}, (data) => { if (data) Object.assign(s.data, data); }); },
    tier(d) { s.pick = d.t; render(); },
    count(d) {
      const tier = s.data.tiers.find((t) => t.id === s.pick) || s.data.tiers[0];
      if (tier.locked) return;
      const want = (s.take[tier.id] = s.take[tier.id] || {});
      want[d.k] = Math.max(0, Math.min(s.data.maxEach || 10, (want[d.k] || 0) + Number(d.d)));
      render();
    },
    armory() {
      if (s.inflight.take) return;
      const tier = s.data.tiers.find((t) => t.id === s.pick) || s.data.tiers[0];
      act('take', { tier: tier.id, items: s.take[tier.id] || {} }, () => { s.take[tier.id] = {}; });
    },
    move(d, e) {
      const one = !!(e && e.shiftKey);
      predictMove(d.from, Number(d.slot), one);
      render();
      act('move', { from: d.from, slot: Number(d.slot), one }, (data) => {
        if (data && !s.inflight.move && !s.inflight.read) Object.assign(s.data, data);
      }, () => {
        if (!s.inflight.read) act('read', {}, (data) => { if (data) Object.assign(s.data, data); });
      });
    },
  };

  root.addEventListener('click', (e) => {
    const t = e.target.closest('[data-a]');
    if (!t || !s || t.disabled) return;
    const fn = ACTIONS[t.dataset.a];
    if (fn) fn({ ...t.dataset }, e);
  });

  document.addEventListener('error', (e) => {
    const img = e.target;
    if (!(img instanceof HTMLImageElement)) return;
    if (img.dataset.alt) { const alt = img.dataset.alt; img.dataset.orig = img.getAttribute('src'); delete img.dataset.alt; img.src = alt; return; }
    img.classList.add('gone');
  }, true);

  const stepList = (dir) => {
    const d = s.data;
    if (d.kind === 'wardrobe') {
      const list = d.uniforms.filter((u) => !u.locked).map((u) => u.i).concat('own');
      const at = Math.max(0, list.indexOf(s.pick));
      const next = list[Math.min(list.length - 1, Math.max(0, at + dir))];
      if (next !== s.pick) ACTIONS.wear({ i: String(next) });
    } else if (d.kind === 'garage') {
      const list = d.cars.filter((c) => !c.locked).map((c) => c.i);
      const at = Math.max(0, list.indexOf(s.pick));
      const next = list[Math.min(list.length - 1, Math.max(0, at + dir))];
      if (next !== undefined && next !== s.pick) { s.pick = next; render(); }
    } else if (d.kind === 'armory') {
      const list = d.tiers.map((t) => t.id);
      const at = Math.max(0, list.indexOf(s.pick));
      s.pick = list[Math.min(list.length - 1, Math.max(0, at + dir))]; render();
    }
  };

  document.addEventListener('keydown', (e) => {
    if (!s) return;
    if (e.key === 'Escape' || e.key === 'Backspace') { e.preventDefault(); close(); return; }
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') { e.preventDefault(); stepList(e.key === 'ArrowDown' ? 1 : -1); return; }
    if (e.key === 'Enter') {
      const cta = root.querySelector('.pwp-cta:not([disabled])');
      if (cta) { e.preventDefault(); cta.click(); }
    }
  });

  window.addEventListener('message', (e) => {
    const m = e.data || {};
    if (m.action === 'open' && m.data) {
      const d = m.data;
      let pick = null;
      if (d.kind === 'wardrobe') pick = d.worn === 'own' || d.worn == null ? 'own' : d.worn;
      if (d.kind === 'garage') { const c = (d.cars || []).find((x) => !x.locked); pick = c ? c.i : null; }
      if (d.kind === 'armory') { const t = (d.tiers || []).find((x) => !x.locked) || (d.tiers || [])[0]; pick = t ? t.id : null; }
      for (const k in mem) delete mem[k];
      s = { data: d, pick, worn: pick, take: {}, err: null, busy: false, inflight: {}, queue: Promise.resolve() };
      render(true);
    } else if (m.action === 'close') {
      if (s) { const panel = root.firstElementChild; s = null; if (panel) { panel.classList.add('leave'); panel.addEventListener('animationend', () => { if (!s) root.innerHTML = ''; }, { once: true }); } }
    }
  });

  window.PWPStation = { open: (data) => window.postMessage({ action: 'open', data }, '*') };
})();
