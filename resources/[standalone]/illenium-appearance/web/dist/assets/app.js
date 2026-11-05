/* ============================================================
   Our appearance menus (Nov 4, 2026). Replaces illenium's React UI.
   Modes: the character creator (identity, face, looks, clothes),
   clothing store, barber, plastic surgeon, tattoo parlor, and the
   staff /pedmenu. All text comes from ../text.json (for Liam).
   Clothing pictures come from the rp_clothing_images resource when
   it's running; without it, items show their number.
   ============================================================ */
(() => {
  'use strict';

  const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'illenium-appearance';
  const IMAGES = 'https://cfx-nui-rp_clothing_images/img/';
  const PORTRAITS = 'https://nui-img/char_creator_portraits/';
  const app = document.getElementById('app');

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------
  async function post(name, data) {
    try {
      const res = await fetch(`https://${RES}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data === undefined ? {} : data),
      });
      const text = await res.text();
      return text ? JSON.parse(text) : null;
    } catch (e) {
      return null;
    }
  }

  const clone = (o) => JSON.parse(JSON.stringify(o));
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const range = (a, b) => { const out = []; for (let i = a; i <= b; i++) out.push(i); return out; };

  let TEXT = {};
  function t(path, vars) {
    let v = path.split('.').reduce((o, k) => (o && o[k] !== undefined ? o[k] : undefined), TEXT);
    if (typeof v !== 'string') v = path;
    if (vars) v = v.replace(/\{(\w+)\}/g, (_, k) => (vars[k] !== undefined ? vars[k] : `{${k}}`));
    return v;
  }

  function h(tag, attrs, ...children) {
    const el = document.createElement(tag);
    if (attrs) {
      for (const [k, v] of Object.entries(attrs)) {
        if (v === undefined || v === null || v === false) continue;
        if (k === 'class') el.className = v;
        else if (k === 'style') el.style.cssText = v;
        else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
        else if (k === 'html') el.innerHTML = v;
        else el.setAttribute(k, v === true ? '' : v);
      }
    }
    for (const c of children.flat()) {
      if (c === undefined || c === null || c === false) continue;
      el.appendChild(typeof c === 'string' || typeof c === 'number' ? document.createTextNode(String(c)) : c);
    }
    return el;
  }

  // ------------------------------------------------------------
  // Fixed data
  // ------------------------------------------------------------
  // Parent faces: 0-20 and 42-44 are men, 21-41 and 45 are women (GTA's own creator).
  const FATHERS = [...range(0, 20), 42, 43, 44];
  const MOTHERS = [...range(21, 41), 45];
  const PARENT_NAMES = ['Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew', 'Juan', 'Alex', 'Isaac', 'Evan', 'Ethan', 'Vincent',
    'Angel', 'Diego', 'Adrian', 'Gabriel', 'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel', 'Anthony',
    'Hannah', 'Audrey', 'Jasmine', 'Giselle', 'Amelia', 'Isabella', 'Zoe', 'Ava', 'Camila', 'Violet', 'Sophia',
    'Evelyn', 'Nicole', 'Ashley', 'Grace', 'Brianna', 'Natalie', 'Olivia', 'Elizabeth', 'Charlotte', 'Emma',
    'Claude', 'Niko', 'John', 'Misty'];
  function portrait(i) {
    if (i <= 20) return `male_${i}`;
    if (i <= 41) return `female_${i - 21}`;
    if (i <= 44) return `special_male_${i - 42}`;
    return 'special_female_0';
  }

  const FACE_GROUPS = [
    ['group_nose', ['noseWidth', 'nosePeakHigh', 'nosePeakSize', 'noseBoneHigh', 'nosePeakLowering', 'noseBoneTwist']],
    ['group_brows', ['eyeBrownHigh', 'eyeBrownForward']],
    ['group_cheeks', ['cheeksBoneHigh', 'cheeksBoneWidth', 'cheeksWidth']],
    ['group_eyes', ['eyesOpening']],
    ['group_lips', ['lipsThickness']],
    ['group_jaw', ['jawBoneWidth', 'jawBoneBackSize']],
    ['group_chin', ['chinBoneLowering', 'chinBoneLenght', 'chinBoneSize', 'chinHole']],
    ['group_neck', ['neckThickness']],
  ];

  // Natural eye colors only (Pillar C: a grounded world). 9+ are fantasy colors.
  const EYE_COLORS = range(0, 8);

  // Clothing categories, in menu order. cfg = illenium's componentConfig/propConfig key.
  const CATS = [
    { key: 'c11', type: 'c', id: 11, cfg: 'jackets', cam: 'body' },
    { key: 'c8', type: 'c', id: 8, cfg: 'shirts', cam: 'body' },
    { key: 'c3', type: 'c', id: 3, cfg: 'upperBody', cam: 'body' },
    { key: 'c4', type: 'c', id: 4, cfg: 'lowerBody', cam: 'bottom' },
    { key: 'c6', type: 'c', id: 6, cfg: 'shoes', cam: 'bottom' },
    { key: 'p0', type: 'p', id: 0, cfg: 'hats', cam: 'head' },
    { key: 'p1', type: 'p', id: 1, cfg: 'glasses', cam: 'head' },
    { key: 'c1', type: 'c', id: 1, cfg: 'masks', cam: 'head' },
    { key: 'c7', type: 'c', id: 7, cfg: 'scarfAndChains', cam: 'body', tracker: true },
    { key: 'c5', type: 'c', id: 5, cfg: 'bags', cam: 'body' },
    { key: 'p2', type: 'p', id: 2, cfg: 'ear', cam: 'head' },
    { key: 'p6', type: 'p', id: 6, cfg: 'watches', cam: 'body' },
    { key: 'p7', type: 'p', id: 7, cfg: 'bracelets', cam: 'body' },
    { key: 'c9', type: 'c', id: 9, cfg: 'bodyArmor', cam: 'body' },
    { key: 'c10', type: 'c', id: 10, cfg: 'decals', cam: 'body' },
  ];

  const SKIN_OVERLAYS = ['ageing', 'complexion', 'blemishes', 'sunDamage', 'moleAndFreckles', 'bodyBlemishes'];
  const MAKEUP_OVERLAYS = ['makeUp', 'blush', 'lipstick'];

  // ------------------------------------------------------------
  // State
  // ------------------------------------------------------------
  const S = {
    open: false,
    mode: null,          // creator | clothing | barber | surgeon | tattoo | staff | identity
    config: null,
    settings: null,
    data: null,
    extras: { gender: 'male', isStaff: false, hidden: {} },
    images: undefined,   // undefined = not loaded yet, null = none
    step: 1,
    tab: null,
    cat: 'c11',
    cam: 'default',
    without: { head: false, body: false, bottom: false },
    openGroups: {},
    tattooZone: null,
    tattooOpacity: 1,
    pedSearch: '',
    dialog: null,
    busy: null,
    identity: null,
    scroll: {},
  };

  // ------------------------------------------------------------
  // Loading
  // ------------------------------------------------------------
  async function loadText() {
    try { TEXT = await (await fetch('text.json')).json(); } catch (e) { TEXT = {}; }
  }

  async function loadImages() {
    if (S.images !== undefined) return;
    try {
      const res = await fetch(IMAGES + 'index.json');
      S.images = res.ok ? await res.json() : null;
    } catch (e) { S.images = null; }
  }

  function modeFromConfig(c) {
    if (c.rpCreator) return 'creator';
    if (c.ped) return 'staff';
    if (c.tattoos && !c.components && !c.props && !c.headOverlays && !c.headBlend) return 'tattoo';
    if (c.components || c.props) return 'clothing';
    if (c.headOverlays) return 'barber';
    if (c.headBlend || c.faceFeatures) return 'surgeon';
    return 'clothing';
  }

  async function openAppearance() {
    S.busy = '...';
    S.open = true;
    render();
    const [settingsRes, dataRes, extras] = await Promise.all([
      post('appearance_get_settings'),
      post('appearance_get_data'),
      post('rp_get_extras'),
      loadImages(),
    ]);
    S.settings = settingsRes ? settingsRes.appearanceSettings : null;
    S.config = dataRes ? dataRes.config : {};
    S.data = dataRes ? dataRes.appearanceData : null;
    S.extras = extras || S.extras;
    S.mode = modeFromConfig(S.config || {});
    S.step = 1;
    S.without = { head: false, body: false, bottom: false };
    S.tab = firstTab();
    S.cat = firstCat();
    S.busy = null;
    S.cam = 'default'; // the game starts every menu on the full-body camera
    render();
    setCamera(S.mode === 'creator' ? 'head' : defaultCamForTab());
  }

  function closeAll() {
    S.open = false; S.mode = null; S.settings = null; S.data = null; S.dialog = null; S.busy = null; S.identity = null;
    render();
  }

  // ------------------------------------------------------------
  // Game calls
  // ------------------------------------------------------------
  function setCamera(key) {
    if (!key || S.cam === key) return;
    S.cam = key;
    post('appearance_set_camera', key);
    renderControls();
  }

  const compSettings = (id) => S.settings && S.settings.components.find((c) => c.component_id === id);
  const propSettings = (id) => S.settings && S.settings.props.find((p) => p.prop_id === id);
  const compData = (id) => S.data && S.data.components.find((c) => c.component_id === id);
  const propData = (id) => S.data && S.data.props.find((p) => p.prop_id === id);

  function replaceSetting(list, keyName, value) {
    const i = list.findIndex((x) => x[keyName] === value[keyName]);
    if (i >= 0) list[i] = value; else list.push(value);
  }

  async function changeComponent(id, drawable, texture) {
    const cur = compData(id);
    if (!cur) return;
    cur.drawable = drawable; cur.texture = texture;
    renderBody(true);
    const res = await post('appearance_change_component', { component_id: id, drawable, texture });
    if (res && res.component_id !== undefined) {
      // Arms (and sometimes the undershirt) matched to the top by the game itself
      if (Array.isArray(res.forced)) {
        for (const f of res.forced) {
          const fc = compData(f.component_id);
          if (fc) { fc.drawable = f.drawable; fc.texture = f.texture; }
        }
        delete res.forced;
      }
      replaceSetting(S.settings.components, 'component_id', res);
      renderBody(true);
    }
  }

  async function changeProp(id, drawable, texture) {
    const cur = propData(id);
    if (!cur) return;
    cur.drawable = drawable; cur.texture = texture;
    renderBody(true);
    const res = await post('appearance_change_prop', { prop_id: id, drawable, texture });
    if (res && res.prop_id !== undefined) {
      replaceSetting(S.settings.props, 'prop_id', res);
      renderBody(true);
    }
  }

  // Ask the game for fresh settings of a slot (texture counts change with the item).
  async function refreshSlot(cat) {
    if (cat.type === 'c') {
      const cur = compData(cat.id);
      if (!cur) return;
      const res = await post('appearance_change_component', { component_id: cat.id, drawable: cur.drawable, texture: cur.texture, refresh: true });
      if (res && res.component_id !== undefined) { delete res.forced; replaceSetting(S.settings.components, 'component_id', res); renderBody(true); }
    } else {
      const cur = propData(cat.id);
      if (!cur) return;
      const res = await post('appearance_change_prop', { prop_id: cat.id, drawable: cur.drawable, texture: cur.texture });
      if (res && res.prop_id !== undefined) { replaceSetting(S.settings.props, 'prop_id', res); renderBody(true); }
    }
  }

  function changeHeadBlend(patch) {
    Object.assign(S.data.headBlend, patch);
    post('appearance_change_head_blend', S.data.headBlend);
    renderBody(true);
  }

  function changeFaceFeature(key, value) {
    S.data.faceFeatures[key] = value;
    post('appearance_change_face_feature', S.data.faceFeatures);
  }

  function changeOverlay(name, patch, rerender = true) {
    S.data.headOverlays[name] = Object.assign({}, S.data.headOverlays[name], patch);
    post('appearance_change_head_overlay', S.data.headOverlays);
    if (rerender) renderBody(true);
  }

  async function changeHair(patch) {
    Object.assign(S.data.hair, patch);
    renderBody(true);
    const res = await post('appearance_change_hair', S.data.hair);
    if (res && res.style) { S.settings.hair = res; renderBody(true); }
  }

  function changeEyes(i) {
    S.data.eyeColor = i;
    post('appearance_change_eye_color', i);
    renderBody(true);
  }

  async function changeModel(model) {
    S.busy = '...'; render();
    const res = await post('appearance_change_model', model);
    if (res) { S.settings = res.appearanceSettings; S.data = res.appearanceData; }
    const extras = await post('rp_get_extras');
    if (extras) S.extras = extras;
    S.busy = null; render();
  }

  async function toggleWithout(key) {
    S.without[key] = !S.without[key];
    if (S.without[key]) post('appearance_remove_clothes', key);
    else post('appearance_wear_clothes', { data: S.data, key });
    renderControls();
  }

  async function toggleHidden(cat, drawable, hide) {
    const res = await post('rp_hide_item', { kind: cat.type, slot: cat.id, drawable, hide });
    if (res && res.hidden) { S.extras.hidden = res.hidden; renderBody(true); }
  }

  // ------------------------------------------------------------
  // Tabs, steps, cameras
  // ------------------------------------------------------------
  function visibleCats() {
    const c = S.config || {};
    return CATS.filter((cat) => {
      if (cat.type === 'c' && (!c.components || (c.componentConfig && c.componentConfig[cat.cfg] === false))) return false;
      if (cat.type === 'p' && (!c.props || (c.propConfig && c.propConfig[cat.cfg] === false))) return false;
      if (cat.tracker && c.hasTracker) return false;
      if (cat.type === 'c' && !compSettings(cat.id)) return false;
      if (cat.type === 'p' && !propSettings(cat.id)) return false;
      return true;
    });
  }

  function tabsForMode() {
    const c = S.config || {};
    if (S.mode !== 'staff') return [];
    const tabs = [];
    if (c.ped) tabs.push('model');
    if (c.headBlend || c.faceFeatures) tabs.push('face');
    if (c.headOverlays) tabs.push('looks');
    if (c.components || c.props) tabs.push('clothes');
    if (c.tattoos) tabs.push('tattoos');
    return tabs;
  }

  function firstTab() { return tabsForMode()[0] || null; }
  function firstCat() { const v = visibleCats(); return v.length ? v[0].key : 'c11'; }

  function page() {
    if (S.mode === 'creator') return ['face', 'face', 'looks', 'clothes', 'done'][S.step] || 'face';
    if (S.mode === 'staff') return S.tab || 'clothes';
    if (S.mode === 'tattoo') return 'tattoos';
    if (S.mode === 'barber') return 'looks';
    if (S.mode === 'surgeon') return 'face';
    return 'clothes';
  }

  function defaultCamForTab() {
    const p = page();
    if (p === 'face' || p === 'looks') return 'head';
    if (p === 'clothes') { const cat = CATS.find((c) => c.key === S.cat); return cat ? cat.cam : 'body'; }
    return 'default';
  }

  function goStep(n) {
    S.step = Math.max(1, Math.min(4, n));
    renderAll();
    setCamera(defaultCamForTab());
    if (page() === 'clothes') { const cat = CATS.find((c) => c.key === S.cat); if (cat) refreshSlot(cat); }
  }

  // ------------------------------------------------------------
  // Picture tiles
  // ------------------------------------------------------------
  function imageSet(cat) {
    if (!S.images || !S.images.sets) return null;
    return S.images.sets[`${S.extras.gender}_${cat.key}`] || null;
  }

  function picture(set, drawable) {
    if (!set || !set.tiles) return null;
    const idx = set.tiles[String(drawable)];
    if (idx === undefined) return null;
    const cols = set.cols, rows = set.rows;
    const col = idx % cols, row = Math.floor(idx / cols);
    const x = cols > 1 ? (col / (cols - 1)) * 100 : 0;
    const y = rows > 1 ? (row / (rows - 1)) * 100 : 0;
    return h('div', {
      class: 'pic',
      style: `background-image:url('${IMAGES}${set.file}');background-size:${cols * 100}% ${rows * 100}%;background-position:${x}% ${y}%`,
    });
  }

  // The list of items a slot shows: blacklist removed; with pictures, empty items fold into one "None".
  function slotItems(cat) {
    const st = cat.type === 'c' ? compSettings(cat.id) : propSettings(cat.id);
    if (!st) return { items: [], noneValue: null };
    const black = new Set((st.blacklist && st.blacklist.drawables) || []);
    const set = imageSet(cat);
    const empty = new Set(set && Array.isArray(set.empty) ? set.empty : []);
    // items the photo tool found broken (the game's pink "missing texture"): staff only
    const broken = new Set(set && Array.isArray(set.broken) && !S.extras.isStaff ? set.broken : []);
    const items = [];
    let noneValue = cat.type === 'p' ? -1 : null;
    for (let d = Math.max(0, st.drawable.min); d <= st.drawable.max; d++) {
      if (black.has(d) || broken.has(d)) continue;
      if (empty.has(d)) { if (noneValue === null) noneValue = d; continue; }
      items.push(d);
    }
    return { items, noneValue };
  }

  function hiddenFor(cat) {
    const list = (S.extras.hidden || {})[cat.key];
    return new Set(Array.isArray(list) ? list : []);
  }

  // ------------------------------------------------------------
  // Rendering
  // ------------------------------------------------------------
  function render() {
    app.innerHTML = '';
    app.classList.toggle('hidden', !S.open);
    if (!S.open) return;
    if (S.mode === 'identity') { app.appendChild(identityPanel()); }
    else if (S.settings && S.data) {
      app.appendChild(mainPanel());
      app.appendChild(controls());
    }
    if (S.busy) app.appendChild(h('div', { class: 'busy' }, S.busy));
    if (S.dialog) app.appendChild(dialog());
  }
  const renderAll = render;

  function renderBody(keepScroll) {
    const body = app.querySelector('.panel-body');
    if (!body) return render();
    const top = body.scrollTop;
    body.replaceWith(panelBody());
    if (keepScroll) { const nb = app.querySelector('.panel-body'); if (nb) nb.scrollTop = top; }
  }

  function renderControls() {
    const old = app.querySelector('.controls');
    if (old) old.replaceWith(controls());
  }

  function stepsBar(active) {
    const names = ['identity', 'face', 'looks', 'clothes', 'done'];
    return h('div', { class: 'steps' }, names.map((n, i) =>
      h('div', { class: `step ${i < active ? 'done' : ''} ${i === active ? 'active' : ''}` }, h('div', { class: 'bar' }), t(`steps.${n}`))));
  }

  function mainPanel() {
    const titleKey = { creator: 'creator', clothing: 'clothing', barber: 'barber', surgeon: 'surgeon', tattoo: 'tattoo', staff: 'staff' }[S.mode];
    const head = h('div', { class: 'panel-head' }, h('div', { class: 'panel-title' }, t(`titles.${titleKey}`)));
    if (S.mode === 'creator') head.appendChild(stepsBar(S.step));
    const panel = h('div', { class: 'panel' }, head);
    const tabs = tabsForMode();
    if (tabs.length > 1) {
      panel.appendChild(h('div', { class: 'tabs' }, tabs.map((tab) =>
        h('button', { class: `tab ${S.tab === tab ? 'active' : ''}`, onclick: () => { S.tab = tab; renderAll(); setCamera(defaultCamForTab()); } },
          { model: t('ped.title'), face: t('steps.face'), looks: t('steps.looks'), clothes: t('steps.clothes'), tattoos: t('titles.tattoo') }[tab]))));
    }
    panel.appendChild(panelBody());
    panel.appendChild(footer());
    return panel;
  }

  function panelBody() {
    const body = h('div', { class: 'panel-body' });
    const p = page();
    if (p === 'face') body.append(...facePage());
    else if (p === 'looks') body.append(...looksPage());
    else if (p === 'clothes') body.append(...clothesPage());
    else if (p === 'tattoos') body.append(...tattooPage());
    else if (p === 'model') body.append(...modelPage());
    else if (p === 'done') body.append(...donePage());
    return body;
  }

  function footer() {
    const foot = h('div', { class: 'panel-foot' });
    if (S.mode === 'creator') {
      foot.appendChild(h('button', { class: 'btn', disabled: S.step <= 1, onclick: () => goStep(S.step - 1) }, t('buttons.back')));
      if (S.step < 4) foot.appendChild(h('button', { class: 'btn primary', onclick: () => goStep(S.step + 1) }, t('buttons.next')));
      else foot.appendChild(h('button', { class: 'btn primary', onclick: () => confirm(t('buttons.confirm_finish'), save) }, t('buttons.finish')));
      return foot;
    }
    if (S.config && S.config.enableExit !== false) {
      foot.appendChild(h('button', { class: 'btn danger', onclick: () => confirm(t('buttons.confirm_cancel'), exitMenu) }, t('buttons.cancel')));
    }
    foot.appendChild(h('button', { class: 'btn primary', onclick: save }, t('buttons.save')));
    return foot;
  }

  function save() {
    S.dialog = null; S.busy = '...'; render();
    post('appearance_save', S.data);
  }

  function exitMenu() {
    S.dialog = null; render();
    post('appearance_exit');
  }

  function confirm(text, onYes) {
    S.dialog = { text, onYes };
    render();
  }

  function dialog() {
    const d = S.dialog;
    return h('div', { class: 'dialog-wrap' }, h('div', { class: 'dialog' },
      h('p', null, d.text),
      h('div', { class: 'panel-foot' },
        h('button', { class: 'btn', onclick: () => { S.dialog = null; render(); } }, t('buttons.no')),
        h('button', { class: 'btn primary', onclick: () => d.onYes() }, t('buttons.yes')))));
  }

  function controls() {
    const ctl = (label, on, fn) => h('button', { class: `ctl ${on ? 'on' : ''}`, onclick: fn }, label);
    const wrap = h('div', { class: 'controls' },
      ctl(t('camera.head'), S.cam === 'head', () => setCamera('head')),
      ctl(t('camera.body'), S.cam === 'body', () => setCamera('body')),
      ctl(t('camera.bottom'), S.cam === 'bottom', () => setCamera('bottom')),
      ctl(t('camera.default'), S.cam === 'default', () => setCamera('default')),
      h('div', { class: 'sep' }),
      ctl('⟲', false, () => post('appearance_rotate_camera', 'left')),
      ctl('⟳', false, () => post('appearance_rotate_camera', 'right')),
      ctl(t('camera.turn'), false, () => post('appearance_turn_around')));
    if (S.config && (S.config.components || S.config.props)) {
      wrap.append(h('div', { class: 'sep' }), h('span', { class: 'lbl' }, t('camera.try_without')),
        ctl(t('camera.hat'), S.without.head, () => toggleWithout('head')),
        ctl(t('camera.top'), S.without.body, () => toggleWithout('body')),
        ctl(t('camera.pants'), S.without.bottom, () => toggleWithout('bottom')));
    }
    return wrap;
  }

  // ---------- Face ----------
  function slider(label, value, min, max, step, onInput, ends) {
    const val = h('span', null, ends ? '' : String(value));
    const input = h('input', { type: 'range', min, max, step, value });
    input.addEventListener('input', () => { onInput(parseFloat(input.value)); if (!ends) val.textContent = input.value; });
    return h('div', { class: 'slider' },
      h('div', { class: 'slider-top' }, h('span', null, label), ends ? h('span', { class: 'ends' }, `${ends[0]} ← → ${ends[1]}`) : val),
      input);
  }

  function parentGrid(list, selected, onPick) {
    return h('div', { class: 'parents' }, list.map((i) => {
      const img = h('img', { src: PORTRAITS + portrait(i), alt: '' });
      img.addEventListener('error', () => { img.style.visibility = 'hidden'; });
      return h('button', { class: `parent ${selected === i ? 'selected' : ''}`, onclick: () => onPick(i) }, img, h('span', null, PARENT_NAMES[i] || String(i)));
    }));
  }

  function facePage() {
    const out = [];
    const c = S.config || {};
    const hb = S.data.headBlend;
    if (c.headBlend) {
      out.push(h('div', { class: 'section' },
        h('div', { class: 'section-title' }, t('face.parents')),
        h('div', { class: 'hint' }, t('face.parents_hint')),
        h('div', { class: 'section-title' }, t('face.mother')),
        parentGrid(MOTHERS, hb.shapeFirst, (i) => changeHeadBlend({ shapeFirst: i, skinFirst: i })),
        h('div', { class: 'section-title', style: 'margin-top:14px' }, t('face.father')),
        parentGrid(FATHERS, hb.shapeSecond, (i) => changeHeadBlend({ shapeSecond: i, skinSecond: i })),
        slider(t('face.resemblance'), hb.shapeMix, 0, 1, 0.05, (v) => { hb.shapeMix = v; post('appearance_change_head_blend', hb); }, [t('face.mother'), t('face.father')]),
        slider(t('face.skin'), hb.skinMix, 0, 1, 0.05, (v) => { hb.skinMix = v; post('appearance_change_head_blend', hb); }, [t('face.mother'), t('face.father')])));
    }
    if (c.faceFeatures) {
      const sec = h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('face.details'),
        h('button', { class: 'chip', onclick: () => { for (const k of Object.keys(S.data.faceFeatures)) S.data.faceFeatures[k] = 0; post('appearance_change_face_feature', S.data.faceFeatures); renderBody(true); } }, t('face.reset'))));
      for (const [groupKey, keys] of FACE_GROUPS) {
        const open = !!S.openGroups[groupKey];
        const body = h('div', { class: 'group-body' }, keys.map((k) =>
          slider(t(`face.${k}`), S.data.faceFeatures[k] ?? 0, -1, 1, 0.1, (v) => changeFaceFeature(k, v))));
        sec.appendChild(h('div', { class: `group ${open ? 'open' : ''}` },
          h('button', { class: 'group-head', onclick: () => { S.openGroups[groupKey] = !open; renderBody(true); } }, t(`face.${groupKey}`), h('span', { class: 'arrow' }, '›')),
          body));
      }
      out.push(sec);
    }
    return out;
  }

  // ---------- Looks ----------
  function swatches(colors, selected, onPick) {
    return h('div', { class: 'swatches' }, (colors || []).map((rgb, i) =>
      h('button', { class: `swatch ${selected === i ? 'selected' : ''}`, style: `background: rgb(${rgb[0]},${rgb[1]},${rgb[2]})`, onclick: () => onPick(i) })));
  }

  function chips(values, selected, label, onPick) {
    return h('div', { class: 'chips' }, values.map((v) =>
      h('button', { class: `chip ${selected === v ? 'selected' : ''}`, onclick: () => onPick(v) }, label(v))));
  }

  // One head overlay: None + styles, amount, and colors if it has them.
  function overlayBlock(name, titleKey, opts = {}) {
    const st = S.settings.headOverlays && S.settings.headOverlays[name];
    const cur = S.data.headOverlays[name];
    if (!st || !cur) return null;
    const on = cur.opacity > 0;
    const styles = range(st.style.min, st.style.max);
    const block = h('div', { class: 'section' }, h('div', { class: 'section-title' }, t(titleKey || `looks.${name}`)));
    const values = opts.noNone ? styles : [-1, ...styles];
    block.appendChild(chips(values, on || opts.noNone ? cur.style : -1, (v) => (v === -1 ? t('looks.none') : String(v + 1)), (v) => {
      if (v === -1) changeOverlay(name, { opacity: 0 });
      else changeOverlay(name, { style: v, opacity: cur.opacity > 0 ? cur.opacity : (opts.defaultOpacity ?? 1) });
    }));
    if (on || opts.noNone) {
      block.appendChild(slider(t('looks.amount'), cur.opacity, 0, 1, 0.1, (v) => changeOverlay(name, { opacity: v }, false)));
      if (st.color && st.color.items) {
        block.appendChild(h('div', { class: 'hint', style: 'margin-top:4px' }, t('looks.color')));
        block.appendChild(swatches(st.color.items, cur.color, (i) => changeOverlay(name, { color: i, secondColor: i })));
      }
    }
    return block;
  }

  function hairSection() {
    const st = S.settings.hair;
    const cur = S.data.hair;
    if (!st || !cur) return [];
    const cat = { key: 'c2', type: 'h', id: 2 };
    const set = imageSet(cat);
    const black = new Set((st.blacklist && st.blacklist.drawables) || []);
    const empty = new Set(set && Array.isArray(set.empty) ? set.empty : []);
    const grid = h('div', { class: 'grid' });
    for (let d = st.style.min; d <= st.style.max; d++) {
      if (black.has(d) || (empty.has(d) && d !== 0)) continue;
      const pic = picture(set, d);
      grid.appendChild(h('button', { class: `tile ${cur.style === d ? 'selected' : ''}`, onclick: () => changeHair({ style: d, texture: 0 }) },
        pic || h('span', { class: 'big' }, String(d)), pic ? h('span', { class: 'num' }, String(d)) : null));
    }
    const out = [h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('looks.hair')), grid)];
    if (st.texture && st.texture.max > 0) {
      out.push(h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('clothes.colors')),
        chips(range(0, st.texture.max), cur.texture, (v) => String(v + 1), (v) => changeHair({ texture: v }))));
    }
    out.push(h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('looks.hair_color')),
      swatches(st.color && st.color.items, cur.color, (i) => changeHair({ color: i })),
      h('div', { class: 'section-title', style: 'margin-top:14px' }, t('looks.highlight')),
      swatches(st.highlight && st.highlight.items, cur.highlight, (i) => changeHair({ highlight: i }))));
    // Hair fades (shaved sides) are hair "tattoos"
    const fades = S.settings.tattoos && S.settings.tattoos.items && S.settings.tattoos.items.ZONE_HAIR;
    if (fades && fades.length && !(S.config && S.config.automaticFade)) {
      const curFade = S.data.tattoos && S.data.tattoos.ZONE_HAIR && S.data.tattoos.ZONE_HAIR[0];
      const selected = curFade ? fades.findIndex((f) => f.name === curFade.name) : -1;
      out.push(h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('looks.fade')),
        chips([-1, ...range(0, fades.length - 1)], selected, (v) => (v === -1 ? t('looks.none') : String(v + 1)), (v) => {
          const tattoos = clone(S.data.tattoos || {});
          tattoos.ZONE_HAIR = v === -1 ? [] : [fades[v]];
          S.data.tattoos = tattoos;
          post(v === -1 ? 'appearance_delete_tattoo' : 'appearance_apply_tattoo', tattoos);
          renderBody(true);
        })));
    }
    return out;
  }

  function looksPage() {
    const male = S.extras.gender === 'male';
    const out = [...hairSection()];
    out.push(overlayBlock('eyebrows', 'looks.eyebrows'));
    if (male) out.push(overlayBlock('beard', 'looks.beard'));
    out.push(h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('looks.eyes')),
      chips(EYE_COLORS, S.data.eyeColor, (v) => t(`looks.eye_${v}`), changeEyes)));
    if (male) out.push(overlayBlock('chestHair', 'looks.chestHair'));
    const skin = h('div', { class: `group ${S.openGroups.skin ? 'open' : ''}` },
      h('button', { class: 'group-head', onclick: () => { S.openGroups.skin = !S.openGroups.skin; renderBody(true); } }, t('looks.skin'), h('span', { class: 'arrow' }, '›')),
      h('div', { class: 'group-body' }, SKIN_OVERLAYS.map((n) => overlayBlock(n, `looks.${n}`))));
    const makeup = h('div', { class: `group ${S.openGroups.makeup ? 'open' : ''}` },
      h('button', { class: 'group-head', onclick: () => { S.openGroups.makeup = !S.openGroups.makeup; renderBody(true); } }, t('looks.makeup'), h('span', { class: 'arrow' }, '›')),
      h('div', { class: 'group-body' }, MAKEUP_OVERLAYS.map((n) => overlayBlock(n, `looks.${n}`))));
    out.push(skin, makeup);
    return out.filter(Boolean);
  }

  // ---------- Clothes ----------
  function clothesPage() {
    const cats = visibleCats();
    if (!cats.find((c) => c.key === S.cat)) S.cat = cats.length ? cats[0].key : null;
    const cat = cats.find((c) => c.key === S.cat);
    const out = [h('div', { class: 'tabs', style: 'padding:0 0 14px' }, cats.map((c) =>
      h('button', { class: `tab ${c.key === S.cat ? 'active' : ''}`, onclick: () => { S.cat = c.key; renderBody(); setCamera(c.cam); refreshSlot(c); } }, t(`clothes.${c.key}`))))];
    if (!cat) return out;

    const set = imageSet(cat);
    if (S.images === null || !set) out.push(h('div', { class: 'note' }, t('clothes.no_pictures')));
    if (cat.key === 'c3') out.push(h('div', { class: 'hint' }, t('clothes.auto_arms')));
    if (S.extras.isStaff) out.push(h('div', { class: 'hint' }, t('clothes.staff_hint')));

    const cur = cat.type === 'c' ? compData(cat.id) : propData(cat.id);
    const st = cat.type === 'c' ? compSettings(cat.id) : propSettings(cat.id);
    if (!cur || !st) return out;

    // Colors of the current item
    if (st.texture && st.texture.max > 0 && cur.drawable >= 0) {
      const blackTex = new Set((st.blacklist && st.blacklist.textures) || []);
      const textures = range(Math.max(0, st.texture.min), st.texture.max).filter((x) => !blackTex.has(x));
      out.push(h('div', { class: 'section' }, h('div', { class: 'section-title' }, t('clothes.colors')),
        chips(textures, cur.texture, (v) => String(v + 1), (v) => (cat.type === 'c' ? changeComponent(cat.id, cur.drawable, v) : changeProp(cat.id, cur.drawable, v)))));
    }

    const { items, noneValue } = slotItems(cat);
    const hidden = hiddenFor(cat);
    const pick = (d) => (cat.type === 'c' ? changeComponent(cat.id, d, 0) : changeProp(cat.id, d, 0));
    const grid = h('div', { class: 'grid' });
    if (noneValue !== null) {
      grid.appendChild(h('button', { class: `tile none ${cur.drawable === noneValue ? 'selected' : ''}`, onclick: () => pick(noneValue) }, h('span', { class: 'big' }, t('clothes.none'))));
    }
    for (const d of items) {
      const isHidden = hidden.has(d);
      const pic = picture(set, d);
      const tile = h('button', { class: `tile ${cur.drawable === d ? 'selected' : ''} ${isHidden ? 'is-hidden' : ''}`, onclick: () => pick(d) },
        pic || h('span', { class: 'big' }, String(d)),
        pic ? h('span', { class: 'num' }, String(d)) : null,
        isHidden ? h('span', { class: 'badge' }, t('clothes.hidden')) : null);
      if (S.extras.isStaff) {
        tile.appendChild(h('span', {
          class: 'staff-btn', title: isHidden ? t('clothes.unhide') : t('clothes.hide'),
          onclick: (e) => { e.stopPropagation(); toggleHidden(cat, d, !isHidden); },
        }, isHidden ? '↺' : '✕'));
      }
      grid.appendChild(tile);
    }
    out.push(grid);
    return out;
  }

  // ---------- Tattoos ----------
  function tattooPage() {
    const items = (S.settings.tattoos && S.settings.tattoos.items) || {};
    const zones = Object.keys(items).filter((z) => z !== 'ZONE_HAIR' && items[z].length);
    if (!zones.includes(S.tattooZone)) S.tattooZone = zones[0];
    const mine = S.data.tattoos || {};
    const has = (tat) => (mine[tat.zone] || []).some((x) => x.name === tat.name);
    const out = [h('div', { class: 'tabs', style: 'padding:0 0 14px' }, zones.map((z) =>
      h('button', { class: `tab ${z === S.tattooZone ? 'active' : ''}`, onclick: () => { S.tattooZone = z; renderBody(); } }, t(`tattoo.zone_${z}`))))];
    const op = S.settings.tattoos.opacity || { min: 0.1, max: 1, factor: 0.1 };
    out.push(slider(t('tattoo.opacity'), S.tattooOpacity, op.min, op.max, op.factor, (v) => { S.tattooOpacity = v; }));
    const list = h('div', { class: 'list' });
    for (const tat of items[S.tattooZone] || []) {
      const on = has(tat);
      const row = h('div', { class: 'row' },
        h('span', null, tat.label || tat.name, on ? h('span', { class: 'tag' }, `  ${t('tattoo.has')}`) : null),
        h('div', { class: 'actions' },
          on
            ? h('button', { class: 'mini danger', onclick: (e) => { e.stopPropagation(); removeTattoo(tat); } }, t('tattoo.remove'))
            : h('button', { class: 'mini primary', onclick: (e) => { e.stopPropagation(); addTattoo(tat); } }, t('tattoo.add'))));
      row.addEventListener('click', () => {
        if (on) return;
        const preview = Object.assign({}, tat, { opacity: S.tattooOpacity });
        post('appearance_preview_tattoo', { data: S.data.tattoos || {}, tattoo: preview });
      });
      list.appendChild(row);
    }
    out.push(list);
    out.push(h('div', { class: 'section', style: 'margin-top:14px' }, h('button', { class: 'btn danger', style: 'width:100%', onclick: removeAllTattoos }, t('tattoo.remove_all'))));
    return out;
  }

  async function addTattoo(tat) {
    const tattoo = Object.assign({}, tat, { opacity: S.tattooOpacity });
    const updated = clone(S.data.tattoos || {});
    if (!updated[tat.zone]) updated[tat.zone] = [];
    updated[tat.zone].push(tattoo);
    const paid = await post('appearance_apply_tattoo', { tattoo, updatedTattoos: updated });
    if (paid) { S.data.tattoos = updated; renderBody(true); }
  }

  function removeTattoo(tat) {
    const updated = clone(S.data.tattoos || {});
    updated[tat.zone] = (updated[tat.zone] || []).filter((x) => x.name !== tat.name);
    S.data.tattoos = updated;
    post('appearance_delete_tattoo', updated);
    renderBody(true);
  }

  function removeAllTattoos() {
    const updated = clone(S.data.tattoos || {});
    for (const z of Object.keys(updated)) if (z !== 'ZONE_HAIR') updated[z] = [];
    S.data.tattoos = updated;
    post('appearance_delete_tattoo', updated);
    renderBody(true);
  }

  // ---------- Model (staff) ----------
  function modelPage() {
    const models = (S.settings.ped && S.settings.ped.model && S.settings.ped.model.items) || [];
    const search = h('input', { class: 'search', placeholder: t('ped.search'), value: S.pedSearch });
    const list = h('div', { class: 'list' });
    const fill = () => {
      list.innerHTML = '';
      const q = S.pedSearch.toLowerCase();
      for (const m of models.filter((x) => x.toLowerCase().includes(q)).slice(0, 300)) {
        list.appendChild(h('button', { class: `row ${S.data.model === m ? 'selected' : ''}`, onclick: () => changeModel(m) }, m));
      }
    };
    search.addEventListener('input', () => { S.pedSearch = search.value; fill(); });
    fill();
    return [search, list];
  }

  // ---------- Done (creator) ----------
  function donePage() {
    return [h('div', { class: 'section' },
      h('div', { class: 'panel-title', style: 'font-size:18px;margin-bottom:10px' }, t('done.title')),
      h('p', { class: 'hint', style: 'font-size:14px;margin:0' }, t('done.text')))];
  }

  // ------------------------------------------------------------
  // Identity (step 1 of the creator, before the character exists)
  // ------------------------------------------------------------
  function identityPanel() {
    const id = S.identity;
    const v = id.values;
    const err = h('div', { class: 'error' }, id.error || '');
    const field = (key, label, input) => h('div', { class: 'field' }, h('label', null, label), input);
    const text = (key) => {
      const el = h('input', { type: 'text', maxlength: 20, value: v[key] || '' });
      el.addEventListener('input', () => { v[key] = el.value; });
      return el;
    };
    if (!v.birthdate && id.defaultDate) v.birthdate = id.defaultDate;
    const date = h('input', { type: 'date', min: id.dateMin, max: id.dateMax, value: v.birthdate || '' });
    date.addEventListener('input', () => { v.birthdate = date.value; });

    let nationality;
    if (id.nationalities && id.nationalities.length) {
      nationality = h('select', null, id.nationalities.map((n) => h('option', { value: n, selected: v.nationality === n }, n)));
      if (!v.nationality) v.nationality = id.nationalities.includes('American') ? 'American' : id.nationalities[0];
      nationality.value = v.nationality;
      nationality.addEventListener('change', () => { v.nationality = nationality.value; });
    } else {
      nationality = text('nationality');
    }

    const genderRow = h('div', { class: 'gender' },
      h('button', { class: v.gender === 0 ? 'selected' : '', onclick: () => { v.gender = 0; post('rp_identity_gender', 0); render(); } }, t('identity.man')),
      h('button', { class: v.gender === 1 ? 'selected' : '', onclick: () => { v.gender = 1; post('rp_identity_gender', 1); render(); } }, t('identity.woman')));

    const submit = () => {
      const nameOk = (s) => /^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ' -]{1,19}$/.test((s || '').trim());
      if (!nameOk(v.firstname) || !nameOk(v.lastname)) { id.error = t('identity.error_name'); return render(); }
      if (!v.birthdate || v.birthdate < id.dateMin || v.birthdate > id.dateMax) { id.error = t('identity.error_date', { min: id.dateMin, max: id.dateMax }); return render(); }
      if (!v.nationality || !String(v.nationality).trim()) { id.error = t('identity.error_nationality'); return render(); }
      if (v.gender !== 0 && v.gender !== 1) { id.error = t('identity.error_gender'); return render(); }
      S.busy = t('identity.working'); render();
      post('rp_identity_submit', {
        firstname: v.firstname.trim(), lastname: v.lastname.trim(), nationality: String(v.nationality).trim(),
        gender: v.gender, birthdate: v.birthdate,
      });
    };

    return h('div', { class: 'panel' },
      h('div', { class: 'panel-head' }, h('div', { class: 'panel-title' }, t('titles.creator')), stepsBar(0)),
      h('div', { class: 'panel-body' },
        h('div', { class: 'hint', style: 'font-size:14px;margin-bottom:16px' }, t('identity.intro')),
        h('div', { class: 'field-row' }, field('firstname', t('identity.firstname'), text('firstname')), field('lastname', t('identity.lastname'), text('lastname'))),
        field('birthdate', t('identity.birthdate'), date),
        field('nationality', t('identity.nationality'), nationality),
        h('div', { class: 'field' }, h('label', null, t('identity.gender')), genderRow),
        err),
      h('div', { class: 'panel-foot' },
        id.canCancel ? h('button', { class: 'btn', onclick: () => post('rp_identity_cancel') }, t('identity.back')) : null,
        h('button', { class: 'btn primary', onclick: submit }, t('identity.next'))));
  }

  // ------------------------------------------------------------
  // Messages from the game
  // ------------------------------------------------------------
  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.type) {
      case 'appearance_display':
        S.dialog = null;
        openAppearance();
        break;
      case 'appearance_hide':
        closeAll();
        break;
      case 'rp_identity_show': {
        const p = msg.payload || {};
        const prev = S.identity && S.identity.values;
        S.identity = {
          values: Object.assign({ gender: 0 }, prev || {}, p.prefill || {}),
          nationalities: p.nationalities || [],
          dateMin: p.dateMin || '1900-01-01',
          dateMax: p.dateMax || '2008-12-31',
          defaultDate: p.defaultDate,
          error: p.errorKey ? t(p.errorKey) : (p.error || ''),
          canCancel: p.canCancel !== false,
        };
        S.open = true; S.mode = 'identity'; S.busy = null; S.dialog = null;
        render();
        break;
      }
      case 'rp_identity_hide':
        if (S.mode === 'identity') closeAll();
        break;
      default:
        break;
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape' || !S.open) return;
    if (S.dialog) { S.dialog = null; render(); return; }
    if (S.mode && S.mode !== 'creator' && S.mode !== 'identity' && S.config && S.config.enableExit !== false) {
      confirm(t('buttons.confirm_cancel'), exitMenu);
    }
  });

  loadText();
})();
