(() => {
  const SRC = document.currentScript ? document.currentScript.src : '';
  if (window.PWPLiveMap && window.PWPLiveMap.src === SRC) return;
  if (window.PWPLiveMap && window.PWPLiveMap.dispose) window.PWPLiveMap.dispose();

  const K0 = 0.33 / 16;
  const BOUNDS = { x0: -5600, x1: 6700, y0: -4000, y1: 8300 };
  const ZOOM = { min: 1.4, max: 7.5, start: 4.2, far: 3.2 };
  const GLIDE_MS = 2000;
  const DRAG_PX = 6;
  const TILT = { pitch: 55, min: 25, ms: 450, turn: 0.3, lean: 0.25 };
  const MAX_SHARP = 3;
  const MEDIA = 'whip_media_map';
  const nuiUrl = (res, path) => (window.PWPDevNui ? window.PWPDevNui(res, path) : `https://cfx-nui-${res}/${path}`);

  let gl = null;
  let glState = 'idle';
  const glWaiting = new Set();

  const loadGl = () => {
    if (glState !== 'idle') return;
    glState = 'loading';
    const failed = (e) => {
      glState = 'failed';
      console.warn('[pure-whip-police] MDT map: the 3D map did not start', e);
      for (const m of glWaiting) m.failed();
      glWaiting.clear();
    };
    const s = document.createElement('script');
    s.src = nuiUrl(MEDIA, 'map/whip-map3d.js');
    s.onerror = () => failed(new Error('could not load ' + s.src));
    s.onload = () => {
      import(nuiUrl('whip_core', 'html/js/map3d/map3d.js')).then((mod) => {
        const m = new mod.WhipMap3D(document.createElement('canvas'), { data: window.WHIP_MAP3D, antialias: 2 });
        return m.ready.then(() => {
          window.WHIP_MAP3D = null;
          gl = m;
          glState = 'ready';
          for (const map of glWaiting) map.render();
          glWaiting.clear();
        });
      }).catch(failed);
    };
    document.head.appendChild(s);
  };

  const remOf = () => parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const esc = (v) => String(v == null ? '' : v).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  class LiveMap {
    constructor({ onTap, onWaypoint, controls } = {}) {
      this.onTap = onTap || null;
      this.onWaypoint = onWaypoint || null;
      this.waypoint = null;
      this.cx = 215; this.cy = -900; this.zoom = ZOOM.start;
      this.yaw = 0; this.pitch = 90; this.tiltTween = null;
      this.placed = false;
      this.calls = []; this.units = []; this.bolos = []; this.pick = null;
      this.marks = new Map();
      this.host = document.createElement('div');
      this.host.className = 'mm';
      this.host.innerHTML = `<canvas class="mm-pic"></canvas><svg class="mm-lines" aria-hidden="true"></svg><div class="mm-marks"></div><div class="mm-ctl">${controls || ''}</div><p class="mm-fail" hidden>The map did not load</p>`;
      this.canvas = this.host.querySelector('.mm-pic');
      this.ctx = this.canvas.getContext('2d', { alpha: false });
      this.layer = this.host.querySelector('.mm-marks');
      this.lineLayer = this.host.querySelector('.mm-lines');
      this.lines = new Map();
      this.pending = false;
      this.gliding = false;
      this.resizer = new ResizeObserver(() => this.render());
      this.bind();
    }

    attach(slot) {
      if (this.host.parentNode !== slot) slot.appendChild(this.host);
      this.resizer.observe(this.host);
      loadGl();
      if (glState === 'failed') this.failed();
      else if (glState !== 'ready') glWaiting.add(this);
      this.render();
    }

    detach() {
      if (!this.host.parentNode) return;
      this.host.remove();
      this.resizer.disconnect();
      glWaiting.delete(this);
      if (gl) gl.resize(1, 1, 1);
    }

    failed() { this.host.querySelector('.mm-fail').hidden = false; }

    ppm() { return K0 * 2 ** this.zoom; }

    flat() { return !gl || (this.pitch >= 89.95 && Math.abs(this.yaw) < 1e-6); }

    shownScale() {
      const r = this.host.getBoundingClientRect();
      return clamp(Math.max(r.width / (this.host.clientWidth || 1), r.height / (this.host.clientHeight || 1)), 0.25, 4);
    }

    sharpness() {
      return Math.round((window.devicePixelRatio || 1) * clamp(this.shownScale(), 1, MAX_SHARP) * 4) / 4;
    }

    aim() {
      const W = this.host.clientWidth, H = this.host.clientHeight, dpr = this.sharpness();
      if (gl.W !== W || gl.H !== H || gl.dpr !== dpr) gl.resize(W, H, dpr);
      gl.setView({ x: this.cx, y: this.cy, pxPerMetre: this.ppm(), offsetX: 0, offsetY: 0, yaw: this.yaw, pitch: this.pitch, heightScale: 1 });
    }

    screenOf(x, y) {
      if (!this.flat()) { this.aim(); const p = gl.project(x, y); return [p.sx, p.sy]; }
      const W = this.host.clientWidth, H = this.host.clientHeight, k = this.ppm();
      return [W / 2 + (x - this.cx) * k, H / 2 - (y - this.cy) * k];
    }

    worldAt(sx, sy) {
      if (!this.flat()) { this.aim(); const p = gl.pick(sx, sy); return p ? [p.x, p.y] : null; }
      const W = this.host.clientWidth, H = this.host.clientHeight, k = this.ppm();
      return [this.cx + (sx - W / 2) / k, this.cy - (sy - H / 2) / k];
    }

    tilted() { return this.pitch < 89.95; }

    setTilt(on) {
      if (!gl) on = false;
      const to = on ? { yaw: this.yaw, pitch: TILT.pitch } : { yaw: 0, pitch: 90 };
      const from = { yaw: this.yaw, pitch: this.pitch };
      const dyaw = ((to.yaw - from.yaw) % 360 + 540) % 360 - 180;
      const start = performance.now();
      const ease = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
      const id = {};
      this.tiltTween = id;
      this.host.classList.toggle('tilted', on);
      const tick = (now) => {
        if (this.tiltTween !== id) return;
        const t = Math.min(1, (now - start) / TILT.ms), e = ease(t);
        this.yaw = t < 1 ? from.yaw + dyaw * e : to.yaw;
        this.pitch = t < 1 ? from.pitch + (to.pitch - from.pitch) * e : to.pitch;
        this.draw();
        if (t < 1) requestAnimationFrame(tick); else this.tiltTween = null;
      };
      requestAnimationFrame(tick);
    }

    toggleTilt() { this.setTilt(!this.tilted()); }

    turnBy(dyaw, dpitch) {
      if (!gl) return;
      this.tiltTween = null;
      this.yaw = ((this.yaw + dyaw) % 360 + 540) % 360 - 180;
      this.pitch = clamp(this.pitch + dpitch, TILT.min, 90);
      this.host.classList.toggle('tilted', this.tilted());
      this.render();
    }

    keepIn() {
      this.cx = clamp(this.cx, BOUNDS.x0, BOUNDS.x1);
      this.cy = clamp(this.cy, BOUNDS.y0, BOUNDS.y1);
    }

    centre(x, y, zoom) {
      this.slide = null;
      this.cx = x; this.cy = y;
      if (typeof zoom === 'number') this.zoom = clamp(zoom, ZOOM.min, ZOOM.max);
      this.keepIn();
      this.render();
    }

    slideTo(x, y, zoom, ms = 420, lift = 0) {
      const from = { x: this.cx, y: this.cy, z: this.zoom };
      const z = typeof zoom === 'number' ? clamp(zoom, ZOOM.min, ZOOM.max) : this.zoom;
      const to = { x, y: y - lift / (K0 * 2 ** z), z };
      const start = performance.now();
      const id = {};
      this.slide = id;
      const tick = (now) => {
        if (this.slide !== id) return;
        const t = Math.min(1, (now - start) / ms), e = 1 - Math.pow(1 - t, 3);
        this.cx = from.x + (to.x - from.x) * e;
        this.cy = from.y + (to.y - from.y) * e;
        this.zoom = from.z + (to.z - from.z) * e;
        this.draw();
        if (t < 1) requestAnimationFrame(tick); else this.slide = null;
      };
      requestAnimationFrame(tick);
    }

    zoomBy(dz, sx, sy) {
      this.slide = null;
      const W = this.host.clientWidth, H = this.host.clientHeight;
      if (sx === undefined || !this.flat()) { sx = W / 2; sy = H / 2; }
      const [wx, wy] = this.worldAt(sx, sy);
      this.zoom = clamp(this.zoom + dz, ZOOM.min, ZOOM.max);
      const k = this.ppm();
      this.cx = wx - (sx - W / 2) / k;
      this.cy = wy + (sy - H / 2) / k;
      this.keepIn();
      this.render();
    }

    panBy(dx, dy) {
      this.slide = null;
      const k = this.ppm();
      const a = this.yaw * Math.PI / 180, sinP = Math.sin(this.pitch * Math.PI / 180);
      const r = dx / k, u = -dy / k / sinP;
      this.cx -= r * Math.cos(a) - u * Math.sin(a);
      this.cy -= r * Math.sin(a) + u * Math.cos(a);
      this.keepIn();
      this.render();
    }

    me() { return this.units.find((u) => u.me) || null; }

    setWaypoint(p) { this.waypoint = p || null; this.sync(); }

    centreOnMe() {
      const u = this.me();
      if (u) this.slideTo(u.x, u.y, Math.max(this.zoom, ZOOM.start));
    }

    setCalls(calls, pick) {
      this.calls = calls || [];
      this.pick = pick == null ? null : pick;
      this.sync();
    }

    setBolos(bolos) {
      this.bolos = bolos || [];
      this.sync();
    }

    setUnits(units) {
      const now = performance.now();
      const old = new Map(this.units.map((u) => [u.callsign, u]));
      this.units = (units || []).map((u) => {
        const was = old.get(u.callsign);
        const from = was ? this.unitAt(was, now) : { x: u.x, y: u.y, h: u.h };
        const far = Math.hypot(u.x - from.x, u.y - from.y) > 300;
        return { ...u, from: far ? { x: u.x, y: u.y, h: u.h } : from, t0: now };
      });
      if (!this.placed) {
        const me = this.me();
        if (me) { this.centre(me.x, me.y, ZOOM.start); this.placed = true; }
      }
      this.sync();
      this.glide();
    }

    unitAt(u, now) {
      if (!u.from) return { x: u.x, y: u.y, h: u.h };
      const t = Math.min(1, (now - u.t0) / GLIDE_MS);
      const dh = ((u.h - u.from.h) % 360 + 540) % 360 - 180;
      return { x: u.from.x + (u.x - u.from.x) * t, y: u.from.y + (u.y - u.from.y) * t, h: u.from.h + dh * t };
    }

    glide() {
      if (this.gliding) return;
      this.gliding = true;
      const tick = (now) => {
        this.place(now);
        if (this.host.isConnected && this.units.some((u) => now - u.t0 < GLIDE_MS)) requestAnimationFrame(tick);
        else this.gliding = false;
      };
      requestAnimationFrame(tick);
    }

    sync() {
      const want = new Map();
      for (const c of this.calls) {
        if (!c.coords) continue;
        const key = 'c' + c.id;
        const hi = c.level != null ? c.level <= 1 : c.priority === 'high';
        const on = this.pick === c.id;
        const html = `<b>${esc(c.code)}</b><span>${esc(c.title)}</span><i></i>`;
        want.set(key, { kind: 'call', x: c.coords.x, y: c.coords.y, html, cls: 'mm-call' + (hi ? ' hi' : '') + (on ? ' on pwp-bracket' + (hi ? ' danger' : '') : ''), id: c.id, label: `${c.code} ${c.title}` });
      }
      for (const u of this.units) {
        const key = 'u' + u.callsign;
        const html = u.me
          ? '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5L19.5 20.5L12 16.6L4.5 20.5Z"/></svg>'
          : `<i></i><span>${esc(u.callsign)}${u.speed >= 5 ? ' · ' + u.speed : ''}</span>`;
        want.set(key, { kind: 'unit', unit: u, html, cls: 'mm-unit' + (u.me ? ' mm-me' : '') + (u.sirens ? ' siren' : ''), status: u.status, move: u.kind || 'foot' });
      }
      for (const b of this.bolos) {
        if (b.x == null || b.y == null) continue;
        want.set('b' + b.plate, { kind: 'bolo', x: b.x, y: b.y, html: `<b>${esc(b.plate)}</b>`, cls: 'mm-bolo' + (b.stolen ? ' stolen' : '') });
      }
      if (this.waypoint) {
        want.set('wp', { kind: 'wp', x: this.waypoint.x, y: this.waypoint.y, html: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 22s-7-6-7-12a7 7 0 0114 0c0 6-7 12-7 12z"/><circle cx="12" cy="10" r="2.4"/></svg>', cls: 'mm-wp' });
      }
      for (const [key, el] of this.marks) {
        if (!want.has(key)) { el.remove(); this.marks.delete(key); }
      }
      for (const [key, m] of want) {
        let el = this.marks.get(key);
        if (!el) {
          el = document.createElement(m.kind === 'call' ? 'button' : 'span');
          if (m.kind === 'call') { el.type = 'button'; el.dataset.act = 'pickCall'; }
          this.layer.appendChild(el);
          this.marks.set(key, el);
        }
        if (el._html !== m.html) { el.innerHTML = m.html; el._html = m.html; }
        el.className = m.cls;
        el._m = m;
        if (m.kind === 'call') { el.dataset.id = m.id; el.setAttribute('aria-label', m.label); }
        else if (m.kind === 'unit') { el.dataset.s = m.status || 'available'; el.dataset.k = m.move; }
      }
      this.place(performance.now());
    }

    place(now) {
      const W = this.host.clientWidth, H = this.host.clientHeight;
      if (!W || !H) return;
      const rem = remOf();
      const flat = this.flat();
      if (!flat) this.aim();
      const k = this.ppm();
      this.host.classList.toggle('far', this.zoom < ZOOM.far);
      const seen = new Set();
      for (const u of this.units) {
        const c = u.alert != null && (u.status === 'enroute' || u.status === 'onscene') && this.calls.find((x) => x.id === u.alert);
        if (!c || !c.coords) continue;
        const p = this.unitAt(u, now);
        const a = flat ? { sx: W / 2 + (p.x - this.cx) * k, sy: H / 2 - (p.y - this.cy) * k } : gl.project(p.x, p.y);
        const b = flat ? { sx: W / 2 + (c.coords.x - this.cx) * k, sy: H / 2 - (c.coords.y - this.cy) * k } : gl.project(c.coords.x, c.coords.y);
        let ln = this.lines.get(u.callsign);
        if (!ln) { ln = document.createElementNS('http://www.w3.org/2000/svg', 'line'); this.lineLayer.appendChild(ln); this.lines.set(u.callsign, ln); }
        ln.setAttribute('x1', (a.sx / rem).toFixed(2)); ln.setAttribute('y1', (a.sy / rem).toFixed(2));
        ln.setAttribute('x2', (b.sx / rem).toFixed(2)); ln.setAttribute('y2', (b.sy / rem).toFixed(2));
        ln.classList.toggle('on', u.status === 'onscene');
        seen.add(u.callsign);
      }
      for (const [key, ln] of this.lines) if (!seen.has(key)) { ln.remove(); this.lines.delete(key); }
      this.lineLayer.setAttribute('viewBox', `0 0 ${(W / rem).toFixed(2)} ${(H / rem).toFixed(2)}`);
      for (const el of this.marks.values()) {
        const m = el._m;
        let x = m.x, y = m.y, turn = '';
        if (m.kind === 'call') turn = ' translate(-50%,calc(-100% - .625rem))';
        else if (m.kind === 'bolo') turn = ' translate(-50%,-50%)';
        else if (m.kind === 'unit') {
          const p = this.unitAt(m.unit, now);
          x = p.x; y = p.y;
          if (m.unit.me) turn = ` rotate(${(this.yaw - p.h).toFixed(1)}deg)`;
        }
        let sx, sy;
        if (flat) { sx = W / 2 + (x - this.cx) * k; sy = H / 2 - (y - this.cy) * k; }
        else { const p = gl.project(x, y); sx = p.sx; sy = p.sy; }
        const off = sx < -80 || sy < -80 || sx > W + 80 || sy > H + 80;
        el.style.visibility = off ? 'hidden' : '';
        if (m.kind === 'call') el.toggleAttribute('data-nofocus', sx < 0 || sy < 0 || sx > W || sy > H);
        if (!off) el.style.transform = `translate(${(sx / rem).toFixed(3)}rem,${(sy / rem).toFixed(3)}rem)${turn}`;
      }
    }

    render() {
      if (this.pending) return;
      this.pending = true;
      requestAnimationFrame(() => { this.pending = false; this.draw(); });
    }

    draw() {
      const W = this.host.clientWidth, H = this.host.clientHeight;
      if (!W || !H || !this.host.isConnected) return;
      if (gl) {
        this.aim();
        gl.render();
        const cw = Math.round(W * gl.dpr), ch = Math.round(H * gl.dpr);
        if (this.canvas.width !== cw || this.canvas.height !== ch) { this.canvas.width = cw; this.canvas.height = ch; }
        this.ctx.drawImage(gl.canvas, 0, 0, cw, ch);
      }
      this.place(performance.now());
    }

    bind() {
      const h = this.host;
      let drag = null;
      h.addEventListener('pointerdown', (e) => {
        if ((e.button !== 0 && e.button !== 2) || e.target.closest('button')) return;
        drag = { id: e.pointerId, x: e.clientX, y: e.clientY, moved: 0, turn: e.button === 2 || e.shiftKey, k: this.shownScale() };
        try { h.setPointerCapture(e.pointerId); } catch { }
      });
      h.addEventListener('pointermove', (e) => {
        if (!drag || drag.id !== e.pointerId) return;
        const dx = (e.clientX - drag.x) / drag.k, dy = (e.clientY - drag.y) / drag.k;
        drag.x = e.clientX; drag.y = e.clientY; drag.moved += Math.abs(dx) + Math.abs(dy);
        if (drag.moved <= DRAG_PX) return;
        h.classList.add('drag');
        if (drag.turn) this.turnBy(-dx * TILT.turn, dy * TILT.lean);
        else this.panBy(dx, dy);
      });
      h.addEventListener('contextmenu', (e) => e.preventDefault());
      const end = (e) => {
        if (!drag || drag.id !== e.pointerId) return;
        const tap = drag.moved <= DRAG_PX && !drag.turn;
        drag = null;
        h.classList.remove('drag');
        if (tap && e.type === 'pointerup' && this.onTap) this.onTap();
      };
      h.addEventListener('pointerup', end);
      h.addEventListener('pointercancel', end);
      h.addEventListener('dblclick', (e) => {
        if (!this.onWaypoint || e.target.closest('button')) return;
        const r = h.getBoundingClientRect(), k = h.clientWidth / (r.width || 1);
        const at = this.worldAt((e.clientX - r.left) * k, (e.clientY - r.top) * k);
        if (!at) return;
        const [x, y] = at;
        this.setWaypoint({ x, y });
        this.onWaypoint(x, y);
      });
      h.addEventListener('wheel', (e) => {
        e.preventDefault();
        const r = h.getBoundingClientRect(), k = h.clientWidth / (r.width || 1);
        const d = e.deltaMode === 1 ? e.deltaY * 33 : e.deltaY;
        this.zoomBy(-d * 0.0022, (e.clientX - r.left) * k, (e.clientY - r.top) * k);
      }, { passive: false });
    }
  }

  const CSS = `
.mm{position:absolute;inset:0;overflow:hidden;background:#0b1820;touch-action:none;user-select:none;cursor:grab;border-radius:var(--r)}
.mm.drag{cursor:grabbing}
.mm-pic{position:absolute;inset:0;width:100%;height:100%;display:block}
.mm-marks{position:absolute;inset:0;pointer-events:none}
.mm-marks>*{position:absolute;left:0;top:0;display:block;width:0;height:0;will-change:transform}
.mm-marks>.mm-call{pointer-events:auto;z-index:1;width:auto;height:auto;display:flex;align-items:center;gap:.375rem;padding:.3125rem .5rem;border-radius:var(--rs);background:var(--bg);color:var(--text);font-size:.75rem;font-weight:600;line-height:1.2;white-space:nowrap;box-shadow:inset 0 0 0 1px var(--line);transition:background-color .15s}
.mm-marks>.mm-call.on{z-index:2}
.mm-call b{font-family:var(--mono);font-weight:600;color:var(--warn)}
.mm-call.hi b{color:var(--danger)}
.mm-call:hover,.mm-call.on{background:var(--panel2)}
.mm-call>i{position:absolute;left:50%;bottom:-.9375rem;width:.625rem;height:.625rem;margin-left:-.3125rem;border-radius:50%;background:var(--warn);box-shadow:0 0 0 .125rem var(--bg)}
.mm-call.hi>i{background:var(--danger)}
.mm.far .mm-call>span{display:none}
.mm-unit>i{position:absolute;left:-.375rem;top:-.375rem;width:.75rem;height:.75rem;border-radius:50%;background:var(--ok);box-shadow:0 0 0 .125rem var(--bg)}
.mm-unit[data-s=busy]>i{background:var(--warn)}
.mm-unit[data-s=enroute]>i,.mm-unit[data-s=onscene]>i{background:var(--route)}
.mm-unit>span{position:absolute;left:.625rem;top:-.5625rem;padding:.0625rem .3125rem;border-radius:.25rem;background:var(--bg);font-family:var(--mono);font-size:.6875rem;font-weight:600;line-height:1.5;white-space:nowrap}
.mm.far .mm-unit>span{display:none}
.mm-unit[data-k=car]>i{border-radius:.1875rem}
.mm-unit[data-k=boat]>i{border-radius:50% 50% .1875rem .1875rem}
.mm-unit[data-k=air]>i{border-radius:.125rem;transform:rotate(45deg) scale(.85)}
.mm-unit.siren>i::after{content:'';position:absolute;inset:-.25rem;border-radius:inherit;box-shadow:0 0 0 .125rem var(--danger);animation:mm-siren 1s var(--out) infinite}
@keyframes mm-siren{from{opacity:1;transform:scale(.7)}to{opacity:0;transform:scale(1.6)}}
@media (prefers-reduced-motion:reduce){.mm-unit.siren>i::after{animation:none;opacity:.8}}
.mm-wp{color:var(--route)}
.mm-lines{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}
.mm-lines line{stroke:var(--route);stroke-width:.125;stroke-dasharray:.375 .25;opacity:.85}
.mm-lines line.on{stroke-dasharray:none;opacity:.5}
.mm-marks>.mm-bolo{width:auto;height:auto}
.mm-bolo b{display:block;padding:.0625rem .3125rem;border-radius:.1875rem;background:var(--bg);box-shadow:inset 0 0 0 1px var(--warn);color:var(--warn);font-family:var(--mono);font-size:.6875rem;font-weight:600;white-space:nowrap}
.mm-bolo.stolen b{box-shadow:inset 0 0 0 1px var(--danger);color:var(--danger)}
.mm.far .mm-bolo b{font-size:.625rem}
.mm-wp svg{position:absolute;left:-.8125rem;top:-1.5rem;width:1.625rem;height:1.625rem;fill:currentColor;stroke:var(--bg);stroke-width:1.4}
.mm-unit.mm-me{width:1.375rem;height:1.375rem;margin:-.6875rem 0 0 -.6875rem;color:var(--accent);z-index:3}
.mm-unit.mm-me svg{width:100%;height:100%;fill:currentColor;stroke:var(--bg);stroke-width:1.6;stroke-linejoin:round}
.mm-ctl{position:absolute;top:.75rem;right:.75rem;display:grid;gap:.375rem}
.mm-ctl .pwp-btn{width:2.5rem;min-height:2.5rem;padding:0;background:var(--bg);box-shadow:inset 0 0 0 1px var(--line)}
.mm-ctl .pwp-btn:hover:not([disabled]){background:var(--panel2)}
.mm-ctl .pwp-btn svg{color:var(--text)}
.mm-ctl .mm-3d{font-family:var(--mono);font-size:.75rem;font-weight:600;letter-spacing:.04em}
.mm.tilted .mm-ctl .mm-3d{background:var(--sel);color:var(--on-sel);box-shadow:none}
.mm-fail{position:absolute;left:50%;top:50%;margin:0;transform:translate(-50%,-50%);color:var(--faint);font-size:.8125rem;font-weight:600}
`;

  const dispose = () => {
    for (const m of glWaiting) m.detach();
    glWaiting.clear();
    if (gl) { gl.dispose(); gl = null; }
    glState = 'gone';
  };

  window.PWPLiveMap = Object.freeze({ src: SRC, LiveMap, css: CSS, dispose });
})();
