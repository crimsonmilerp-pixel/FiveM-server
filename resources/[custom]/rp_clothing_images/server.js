// ============================================================
//  rp_clothing_images - server side of the photo tool
//  Staff (ACE "admin") start it with /clothingphotos. Each picture sheet is written to img/
//  inside this resource, and img/index.json lists them for the clothing menus.
// ============================================================
const fs = require('fs');
const path = require('path');

const RES = GetCurrentResourceName();
const IMG = path.join(GetResourcePath(RES), 'img');
const BUCKET_BASE = 7000;
const SLOT_NAME = /^(male|female)_(c|p)\d{1,2}$/;
const DEBUG_NAME = /^debug_(male|female)_(c|p)\d{1,2}_(a|b|shot)$/; // raw photos for checking the camera (not sent to players)
const okName = (name) => typeof name === 'string' && (SLOT_NAME.test(name) || DEBUG_NAME.test(name));

const isStaff = (src) => IsPlayerAceAllowed(String(src), 'admin');
const log = (msg) => console.log(`[clothingphotos] ${msg}`);

function readIndex() {
  try {
    const index = JSON.parse(fs.readFileSync(path.join(IMG, 'index.json'), 'utf8'));
    if (index && typeof index === 'object' && index.sets) return index;
  } catch (e) { /* first run */ }
  return { tile: 128, sets: {} };
}

RegisterCommand('clothingphotos', (source, args) => {
  if (source <= 0 || !isStaff(source)) return;
  if (args[0] === 'stop') {
    emitNet('rp_clothing_images:client:stop', source);
    return;
  }
  const gender = ['male', 'female'].includes(args[0]) ? args[0] : 'both';
  const slot = args[1] || 'all';
  const limit = Number(args[2]) || 0; // quick test: only the first N items of each slot
  const bucket = BUCKET_BASE + Number(source);
  SetRoutingBucketPopulationEnabled(bucket, false);
  SetPlayerRoutingBucket(String(source), bucket);
  log(`${GetPlayerName(source)} started the photo tool (${gender}, ${slot}${limit ? `, first ${limit} items` : ''})`);
  emitNet('rp_clothing_images:client:start', source, gender, slot, limit);
}, false);

onNet('rp_clothing_images:server:done', () => {
  const src = global.source;
  if (GetPlayerRoutingBucket(String(src)) === BUCKET_BASE + Number(src)) SetPlayerRoutingBucket(String(src), 0);
});

// A sheet arrives in small parts (one big event would overflow the network and kick the player).
const uploads = {}; // `${source}:${name}` -> { total, parts: [] }
const MAX_PARTS = 600;

onNet('rp_clothing_images:server:sheetPart', (name, part, total, text) => {
  const src = global.source;
  if (!isStaff(src)) return;
  if (!okName(name) || typeof text !== 'string') return;
  if (!Number.isInteger(part) || !Number.isInteger(total) || total < 1 || total > MAX_PARTS || part < 1 || part > total) return;
  const key = `${src}:${name}`;
  if (part === 1 || !uploads[key] || uploads[key].total !== total) uploads[key] = { total, parts: [] };
  uploads[key].parts[part - 1] = text;
  emitNet('rp_clothing_images:client:ack', src, name, part);
});

on('playerDropped', () => {
  const prefix = `${global.source}:`;
  for (const key of Object.keys(uploads)) if (key.startsWith(prefix)) delete uploads[key];
});

function saveSheet(name, dataUrl, meta) {
  const match = typeof dataUrl === 'string' && dataUrl.match(/^data:image\/(webp|png);base64,(.+)$/);
  if (!match || !meta || typeof meta !== 'object') {
    log(`refused sheet ${name}: not a picture`);
    return false;
  }
  const ext = match[1];
  const file = `${name}.${ext}`;
  try {
    fs.mkdirSync(IMG, { recursive: true });
    fs.writeFileSync(path.join(IMG, file), Buffer.from(match[2], 'base64'));

    const tiles = {};
    for (const [drawable, idx] of Object.entries(meta.tiles || {})) {
      if (/^\d+$/.test(drawable) && Number.isInteger(idx)) tiles[drawable] = idx;
    }
    const index = readIndex();
    index.tile = Number(meta.tile) || index.tile || 128;
    index.sets[name] = {
      file,
      cols: Number(meta.cols) || 1,
      rows: Number(meta.rows) || 1,
      tiles,
      empty: Array.isArray(meta.empty) ? meta.empty.filter((n) => Number.isInteger(n)) : [],
      broken: Array.isArray(meta.broken) ? meta.broken.filter((n) => Number.isInteger(n)) : [],
    };
    index.updated = new Date().toISOString();
    fs.writeFileSync(path.join(IMG, 'index.json'), JSON.stringify(index));
    log(`saved img/${file} (${Object.keys(tiles).length} pictures, ${index.sets[name].empty.length} empty, ${index.sets[name].broken.length} broken)`);
    return true;
  } catch (e) {
    log(`could not save ${file}: ${e.message}`);
    return false;
  }
}

function saveDebug(name, dataUrl) {
  const match = typeof dataUrl === 'string' && dataUrl.match(/^data:image\/jpeg;base64,(.+)$/);
  if (!match) return false;
  try {
    fs.mkdirSync(path.join(IMG, 'debug'), { recursive: true });
    fs.writeFileSync(path.join(IMG, 'debug', `${name}.jpg`), Buffer.from(match[1], 'base64'));
    return true;
  } catch (e) {
    log(`could not save debug photo ${name}: ${e.message}`);
    return false;
  }
}

onNet('rp_clothing_images:server:sheetDone', (name, metaJson) => {
  const src = global.source;
  if (!isStaff(src) || !okName(name) || typeof metaJson !== 'string') return;
  let meta;
  try { meta = JSON.parse(metaJson); } catch (e) { return log(`sheet ${name}: bad list`); }
  const key = `${src}:${name}`;
  const upload = uploads[key];
  delete uploads[key];
  if (!upload) return log(`sheet ${name}: no parts received`);
  for (let i = 0; i < upload.total; i++) {
    if (typeof upload.parts[i] !== 'string') return log(`sheet ${name}: part ${i + 1} of ${upload.total} missing`);
  }
  const data = upload.parts.join('');
  const saved = DEBUG_NAME.test(name) ? saveDebug(name, data) : saveSheet(name, data, meta);
  if (saved) emitNet('rp_clothing_images:client:ack', src, name, 0);
});

onNet('rp_clothing_images:server:report', (report) => {
  const src = global.source;
  if (!isStaff(src) || !report || typeof report !== 'object') return;
  try {
    fs.writeFileSync(path.join(GetResourcePath(RES), 'arms_report.json'), JSON.stringify(report, null, 2));
  } catch (e) { /* not important */ }
});
