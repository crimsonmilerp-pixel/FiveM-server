// ============================================================
//  rp_clothing_images - turns screenshots into clothing pictures (runs inside the game, never visible)
//
//  For each slot, and each camera angle ("view") of that slot, the game sends:
//    baseline A (x5)  the bare mannequin (several, to see what moves a little by itself)
//    baseline B       the empty scene (mannequin hidden)
//    shot             the mannequin wearing one item
//  An item is whatever changed between A and the shot. "item" mode keeps just those pixels;
//  "body" mode also keeps the head around it (hair, hats, glasses). When a slot has two views
//  (earrings: left and right), each item keeps the view where more of it shows.
//  Pictures are packed into one sheet per slot, which goes back to the game as a WebP image
//  plus a list of where each item is.
// ============================================================
(() => {
  const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rp_clothing_images';
  const STRONG = 38;      // a channel must change this much to count as "the item is here"
  const SOFT_LOW = 12;    // below this change a pixel is fully see-through
  const SOFT_HIGH = 60;   // above this change a pixel is fully solid
  const MIN_PIXELS = 30;  // fewer item pixels than this = an empty (invisible) item
  const PAD = 0.08;       // space around the item in its picture
  const MIN_SIDE = 72;    // tiny items (earrings) are not blown up more than this allows

  let job = null;

  function reply(id, result) {
    fetch(`https://${RES}/result`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ id, result }),
    }).catch(() => {});
  }

  async function decode(dataUrl) {
    const img = new Image();
    img.src = dataUrl;
    await img.decode();
    const c = document.createElement('canvas');
    c.width = img.naturalWidth;
    c.height = img.naturalHeight;
    const ctx = c.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(img, 0, 0);
    return ctx.getImageData(0, 0, c.width, c.height);
  }

  // ---------- pixel helpers ----------
  function diffAt(a, b, i) {
    const p = i * 4;
    return Math.max(Math.abs(a[p] - b[p]), Math.abs(a[p + 1] - b[p + 1]), Math.abs(a[p + 2] - b[p + 2]));
  }

  function diffMask(a, b, n, t) {
    const m = new Uint8Array(n);
    for (let i = 0; i < n; i++) if (diffAt(a, b, i) > t) m[i] = 1;
    return m;
  }

  // square erode (all) or dilate (any) with radius r, done as two 1-D passes
  function morph(src, w, h, r, dilate) {
    if (r <= 0) return src;
    const tmp = new Uint8Array(src.length);
    const out = new Uint8Array(src.length);
    for (let y = 0; y < h; y++) {
      let sum = 0;
      const row = y * w;
      for (let x = -r; x < w + r; x++) {
        const add = x + r;
        if (add >= 0 && add < w) sum += src[row + add];
        const rem = x - r - 1;
        if (rem >= 0 && rem < w) sum -= src[row + rem];
        if (x >= 0 && x < w) {
          const lo = Math.max(0, x - r), hi = Math.min(w - 1, x + r);
          tmp[row + x] = dilate ? (sum > 0 ? 1 : 0) : (sum === hi - lo + 1 ? 1 : 0);
        }
      }
    }
    for (let x = 0; x < w; x++) {
      let sum = 0;
      for (let y = -r; y < h + r; y++) {
        const add = y + r;
        if (add >= 0 && add < h) sum += tmp[add * w + x];
        const rem = y - r - 1;
        if (rem >= 0 && rem < h) sum -= tmp[rem * w + x];
        if (y >= 0 && y < h) {
          const lo = Math.max(0, y - r), hi = Math.min(h - 1, y + r);
          out[y * w + x] = dilate ? (sum > 0 ? 1 : 0) : (sum === hi - lo + 1 ? 1 : 0);
        }
      }
    }
    return out;
  }

  // What moves by itself between the bare-mannequin photos: ignored when looking for the item.
  function prepare(view) {
    const { w, h } = job;
    const A = view.A;
    const n = w * h;
    const moving = new Uint8Array(n);
    for (let i = 0; i < A.length; i++) {
      for (let j = i + 1; j < A.length; j++) {
        const d = diffMask(A[i].data, A[j].data, n, 20);
        for (let k = 0; k < n; k++) if (d[k]) moving[k] = 1;
      }
    }
    view.noise = morph(moving, w, h, 2, true);
    view.ready = true;
  }

  // Groups of touching pixels. The item is the biggest group, plus other groups at least half its size
  // (the second shoe, the other arm, the other lens), plus mid-size groups close to it.
  // Small loose bits, like the item's shadow on the ground, are dropped.
  function mainParts(m, w, h) {
    const n = w * h;
    const label = new Int32Array(n);
    const stack = new Int32Array(n);
    const comps = [];
    let next = 1, total = 0;
    for (let i = 0; i < n; i++) {
      if (!m[i] || label[i]) continue;
      let sp = 0, count = 0, x0 = w, y0 = h, x1 = -1, y1 = -1;
      stack[sp++] = i;
      label[i] = next;
      while (sp) {
        const k = stack[--sp];
        count++;
        const x = k % w, y = (k - x) / w;
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
        for (let dy = -1; dy <= 1; dy++) {
          const ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          for (let dx = -1; dx <= 1; dx++) {
            const nx = x + dx;
            if (nx < 0 || nx >= w) continue;
            const j = ny * w + nx;
            if (m[j] && !label[j]) { label[j] = next; stack[sp++] = j; }
          }
        }
      }
      comps.push({ id: next, count, x0, y0, x1, y1 });
      total += count;
      next++;
    }
    if (total < MIN_PIXELS || !comps.length) return null;

    comps.sort((a, b) => b.count - a.count);
    const big = comps[0];
    const box = { x0: big.x0, y0: big.y0, x1: big.x1, y1: big.y1, count: big.count };
    const kept = new Set([big.id]);
    const reach = 0.8 * Math.max(big.x1 - big.x0 + 1, big.y1 - big.y0 + 1);
    for (let c = 1; c < comps.length; c++) {
      const part = comps[c];
      if (part.count < 0.25 * big.count) break;
      const gap = Math.max(0, part.x0 - box.x1, box.x0 - part.x1, part.y0 - box.y1, box.y0 - part.y1);
      if (part.count < 0.5 * big.count && gap > reach) continue;
      kept.add(part.id);
      box.x0 = Math.min(box.x0, part.x0); box.y0 = Math.min(box.y0, part.y0);
      box.x1 = Math.max(box.x1, part.x1); box.y1 = Math.max(box.y1, part.y1);
      box.count += part.count;
    }
    const keep = new Uint8Array(n);
    for (let i = 0; i < n; i++) if (label[i] && kept.has(label[i])) keep[i] = 1;
    return { keep, box };
  }

  // The game's "missing texture" is a hot pink checker: an item that is mostly that pink is broken.
  function looksBroken(s, keep, n) {
    let pink = 0, all = 0;
    for (let i = 0; i < n; i++) {
      if (!keep[i]) continue;
      all++;
      const p = i * 4;
      const r = s[p], g = s[p + 1], b = s[p + 2];
      if (r > 215 && b > 185 && g < 150 && r - g > 100 && b - g > 70) pink++;
    }
    return all > 0 && pink / all > 0.6;
  }

  // ---------- one item ----------
  function cutOut(view, S) {
    const { w, h, mode } = job;
    const n = w * h;
    const A = view.A[0].data;
    const B = view.B ? view.B.data : A;
    const s = S.data;

    let item = diffMask(s, A, n, STRONG);
    for (let i = 0; i < n; i++) if (view.noise[i]) item[i] = 0;
    item = morph(morph(item, w, h, 1, false), w, h, 1, true); // drop thin specks and edges
    const parts = mainParts(item, w, h);
    if (!parts) return null;
    const box = parts.box;

    // which reference the colors are measured against
    const ref = mode === 'body' ? B : A;
    const keep = mode === 'body' ? null : morph(parts.keep, w, h, 3, true);
    const out = new ImageData(w, h);
    const o = out.data;
    for (let i = 0; i < n; i++) {
      if (keep && !keep[i]) continue;
      const d = diffAt(s, ref, i);
      if (d <= SOFT_LOW) continue;
      const a = Math.min(1, (d - SOFT_LOW) / (SOFT_HIGH - SOFT_LOW));
      const p = i * 4;
      for (let c = 0; c < 3; c++) {
        // take the backdrop color back out of see-through edge pixels
        const v = ref[p + c] + (s[p + c] - ref[p + c]) / a;
        o[p + c] = v < 0 ? 0 : v > 255 ? 255 : v;
      }
      o[p + 3] = Math.round(a * 255);
    }

    // a square around the item, with some space
    const bw = box.x1 - box.x0 + 1, bh = box.y1 - box.y0 + 1;
    const side = Math.max(Math.max(bw, bh) * (1 + PAD * 2), MIN_SIDE);
    const cx = (box.x0 + box.x1) / 2, cy = (box.y0 + box.y1) / 2;
    return {
      image: out, sx: cx - side / 2, sy: cy - side / 2, side,
      score: box.count, broken: looksBroken(s, parts.keep, n),
    };
  }

  // the cut item drawn into its own small picture
  function toTile(cut) {
    const t = job.tile;
    job.scratchCtx.putImageData(cut.image, 0, 0);
    const c = document.createElement('canvas');
    c.width = t; c.height = t;
    const ctx = c.getContext('2d');
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(job.scratch, cut.sx, cut.sy, cut.side, cut.side, 0, 0, t, t);
    return c;
  }

  function smallJpeg(img) {
    const full = document.createElement('canvas');
    full.width = img.width; full.height = img.height;
    full.getContext('2d').putImageData(img, 0, 0);
    const c = document.createElement('canvas');
    c.width = 640; c.height = Math.round(640 * img.height / img.width);
    c.getContext('2d').drawImage(full, 0, 0, c.width, c.height);
    return c.toDataURL('image/jpeg', 0.8);
  }

  function getView(v) {
    const key = String(v || 1);
    if (!job.views[key]) job.views[key] = { A: [], B: null, noise: null, ready: false };
    return job.views[key];
  }

  // ---------- messages from the game ----------
  const handlers = {
    begin(p) {
      job = {
        name: p.name, tile: p.tile, cols: p.cols, mode: p.mode,
        scratch: null, scratchCtx: null, w: 0, h: 0,
        views: {},
        best: {},      // drawable -> { score, canvas, broken }
        seen: {},      // drawable -> true once photographed
        debug: {},
      };
      return { ok: true };
    },

    baselines_reset(p) {
      if (job) { const view = getView(p.view); view.A = []; view.B = null; view.ready = false; }
      return { ok: true };
    },

    async baseline(p) {
      if (!job) return { error: 'no job' };
      const img = await decode(p.image);
      if (!job.w) {
        job.w = img.width; job.h = img.height;
        job.scratch = document.createElement('canvas');
        job.scratch.width = job.w; job.scratch.height = job.h;
        job.scratchCtx = job.scratch.getContext('2d');
      }
      if (img.width !== job.w || img.height !== job.h) return { error: 'size changed' };
      const view = getView(p.view);
      if (p.kind === 'B') view.B = img; else view.A.push(img);
      view.ready = false;
      return { ok: true };
    },

    async shot(p) {
      if (!job) return { error: 'no job', empty: true };
      const view = getView(p.view);
      if (!view.A.length) return { error: 'no baseline', empty: true };
      if (!view.ready) prepare(view);
      const d = Number(p.drawable);
      job.seen[d] = true;
      const img = await decode(p.image);
      if (img.width !== job.w || img.height !== job.h) return { error: 'size changed', empty: true };
      const cut = cutOut(view, img);
      if (!cut) return { empty: true };
      const old = job.best[d];
      if (!old || cut.score > old.score) {
        job.best[d] = { score: cut.score, canvas: toTile(cut), broken: cut.broken };
        if (!job.debug.shot && !cut.broken) {
          job.debug.shot = img;
          job.debug.a = view.A[0];
          job.debug.b = view.B;
        }
      }
      return { empty: false, broken: cut.broken };
    },

    finish() {
      if (!job) return { error: 'no job' };
      const drawables = Object.keys(job.seen).map(Number).sort((a, b) => a - b);
      const withPicture = drawables.filter((d) => job.best[d]);
      const used = Math.max(1, withPicture.length);
      const rows = Math.max(1, Math.ceil(used / job.cols));
      const cols = used < job.cols ? used : job.cols;
      const out = document.createElement('canvas');
      out.width = cols * job.tile;
      out.height = rows * job.tile;
      const ctx = out.getContext('2d');
      const tiles = {}, broken = [], empty = [];
      withPicture.forEach((d, idx) => {
        ctx.drawImage(job.best[d].canvas, (idx % cols) * job.tile, Math.floor(idx / cols) * job.tile);
        tiles[d] = idx;
        if (job.best[d].broken) broken.push(d);
      });
      for (const d of drawables) if (!job.best[d]) empty.push(d);

      let data = out.toDataURL('image/webp', 0.86);
      if (!data.startsWith('data:image/webp')) data = out.toDataURL('image/png');
      const meta = { tile: job.tile, cols, rows, count: withPicture.length, tiles, empty, broken };
      // small copies of the raw photos, so Claude can check the camera and backdrop
      const debug = {};
      if (job.debug.a) debug.a = smallJpeg(job.debug.a);
      if (job.debug.b) debug.b = smallJpeg(job.debug.b);
      if (job.debug.shot) debug.shot = smallJpeg(job.debug.shot);
      job = null;
      // meta also goes as text, so the drawable numbers reach the server exactly as written
      return { data, meta, metaJson: JSON.stringify(meta), debug };
    },
  };

  window.addEventListener('message', async (event) => {
    const msg = event.data || {};
    const fn = handlers[msg.action];
    if (!fn) return;
    let result;
    try {
      result = await fn(msg.payload || {});
    } catch (e) {
      result = { error: String(e && e.message || e), empty: true };
    }
    reply(msg.id, result);
  });
})();
