/* ══════════════════════════════════════════════════════════════════════════
   renzu_customs 2.0 - NUI controller
   No jQuery, no CDN, no external requests.
   ══════════════════════════════════════════════════════════════════════════ */

'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'renzu_customs';

/* ── dom ──────────────────────────────────────────────────────────────── */

const el = (id) => document.getElementById(id);

const ui = {
  app: el('app'),
  shopName: el('shop-name'),
  vehicleName: el('vehicle-name'),
  balance: el('balance'),
  cartTotal: el('cart-total'),
  cartCount: el('cart-count'),
  crumbs: el('crumbs'),
  grid: el('grid'),
  search: el('search'),
  btnBack: el('btn-back'),
  btnClose: el('btn-close'),
  btnCheckout: el('btn-checkout'),
  freeBadge: el('free-badge'),

  repair: el('repair'),
  repairCost: el('repair-cost'),
  btnRepair: el('btn-repair'),
  btnRepairCancel: el('btn-repair-cancel'),

  invoice: el('invoice'),
  invoiceShop: el('invoice-shop'),
  invoiceList: el('invoice-list'),
  invoiceTotal: el('invoice-total'),
  btnPay: el('btn-pay'),
  btnInvoiceCancel: el('btn-invoice-cancel'),

  spray: el('spray'),
  sprayColor: el('spray-color'),
  btnSprayDone: el('btn-spray-done'),
};

const show = (node) => node.classList.remove('is-hidden');
const hide = (node) => node.classList.add('is-hidden');

/* ── state ────────────────────────────────────────────────────────────── */

const state = {
  open: false,
  data: null,
  stack: [],
  cart: new Map(),
  filter: '',
};

/* ── helpers ──────────────────────────────────────────────────────────── */

/**
 * Fire a NUI callback. Nothing in the UI ever blocks on this: the reply is only
 * awaited where the answer is actually needed, and a timeout guarantees the
 * promise settles even if the Lua side never calls cb().
 */
async function post(name, body, timeout) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout || 8000);

  try {
    const response = await fetch(`https://${RESOURCE}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
      signal: controller.signal,
    });
    return await response.json();
  } catch (err) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

const money = (value) => `$${Math.round(Number(value) || 0).toLocaleString('en-US')}`;

const audioCache = {};
let lastHoverSound = 0;

function playSound(name, volume) {
  try {
    let base = audioCache[name];
    if (!base) {
      base = new Audio(`audio/${name}.ogg`);
      audioCache[name] = base;
    }
    const node = base.cloneNode();
    node.volume = Math.min(Math.max(volume === undefined ? 0.3 : volume, 0), 1);
    const played = node.play();
    if (played && played.catch) played.catch(() => {});
  } catch (err) {
    /* audio is cosmetic, never break the menu over it */
  }
}

function hexToRgb(hex) {
  const match = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!match) return { r: 0, g: 0, b: 0 };
  return {
    r: parseInt(match[1], 16),
    g: parseInt(match[2], 16),
    b: parseInt(match[3], 16),
  };
}

/* ── cart ─────────────────────────────────────────────────────────────── */

function cartTotal() {
  let total = 0;
  state.cart.forEach((entry) => {
    total += entry.cost;
  });
  return total;
}

function refreshCart() {
  ui.cartTotal.textContent = money(cartTotal());
  ui.cartCount.textContent = String(state.cart.size);
}

function charge(key, label, cost) {
  if (!cost || cost <= 0) {
    state.cart.delete(key);
  } else {
    state.cart.set(key, { label, cost });
  }
  refreshCart();
}

const uncharge = (key) => charge(key, '', 0);

/* ── navigation ───────────────────────────────────────────────────────── */

function drawCrumbs() {
  ui.crumbs.innerHTML = '';

  state.stack.forEach((view, index) => {
    if (index > 0) {
      const sep = document.createElement('span');
      sep.className = 'crumb--sep';
      sep.textContent = '/';
      ui.crumbs.appendChild(sep);
    }

    const crumb = document.createElement('button');
    crumb.type = 'button';
    crumb.textContent = view.label;

    if (index === state.stack.length - 1) {
      crumb.className = 'crumb--active';
    } else {
      crumb.addEventListener('click', () => {
        state.stack.length = index + 1;
        resetFilter();
        draw();
      });
    }

    ui.crumbs.appendChild(crumb);
  });
}

function resetFilter() {
  state.filter = '';
  ui.search.value = '';
}

function applyFilter() {
  const query = state.filter;
  ui.grid.querySelectorAll('.tile').forEach((tile) => {
    const haystack = tile.dataset.search || '';
    tile.classList.toggle('is-hidden', Boolean(query) && !haystack.includes(query));
  });
}

function draw() {
  const view = state.stack[state.stack.length - 1];
  if (!view) return;

  drawCrumbs();
  ui.grid.innerHTML = '';
  view.render();
  applyFilter();
  ui.btnBack.disabled = state.stack.length <= 1;
}

function pushView(label, render) {
  state.stack.push({ label, render });
  resetFilter();
  draw();
}

function popView() {
  if (state.stack.length <= 1) return;
  state.stack.pop();
  resetFilter();
  draw();
  post('closeDoors');
  post('resetCamera');
}

function resetTo(label, render) {
  state.stack = [{ label, render }];
  resetFilter();
  draw();
}

/* ── tiles ────────────────────────────────────────────────────────────── */

function addTile(options) {
  const tile = document.createElement('button');
  tile.type = 'button';
  tile.className = 'tile';
  tile.dataset.search = String(options.label || '').toLowerCase();

  if (options.wide) tile.classList.add('tile--wide');
  if (options.active) tile.classList.add('tile--active');

  if (options.icon) {
    const icon = document.createElement('img');
    icon.className = 'tile__icon';
    icon.src = `img/${options.icon}.svg`;
    icon.alt = '';
    icon.addEventListener('error', () => icon.remove());
    tile.appendChild(icon);
  }

  const label = document.createElement('span');
  label.className = 'tile__label';
  label.textContent = options.label;
  tile.appendChild(label);

  if (options.meta) {
    const meta = document.createElement('span');
    meta.className = 'tile__meta';
    meta.textContent = options.meta;
    tile.appendChild(meta);
  }

  if (options.price) {
    const price = document.createElement('span');
    price.className = 'tile__price';
    price.textContent = options.price;
    tile.appendChild(price);
  }

  if (options.flag) {
    const flag = document.createElement('span');
    flag.className = 'tile__flag';
    flag.textContent = options.flag;
    tile.appendChild(flag);
  }

  if (options.control) {
    tile.appendChild(options.control);
  }

  if (options.onClick) {
    tile.addEventListener('click', (event) => {
      if (event.target !== tile && event.target.tagName === 'INPUT') return;
      playSound('click', 0.4);
      options.onClick();
    });
  }

  tile.addEventListener('mouseenter', () => {
    const now = Date.now();
    if (now - lastHoverSound < 90) return;
    lastHoverSound = now;
    playSound('menu', 0.22);
  });

  ui.grid.appendChild(tile);
  return tile;
}

function addEmpty(message) {
  const node = document.createElement('div');
  node.className = 'tile tile--empty';
  node.textContent = message;
  ui.grid.appendChild(node);
}

function addColorPicker(label, initial, onPick) {
  const input = document.createElement('input');
  input.type = 'color';
  input.className = 'colorpicker';
  input.value = initial || '#ff0000';

  const apply = () => onPick(hexToRgb(input.value), input.value);
  input.addEventListener('input', apply);
  input.addEventListener('change', apply);

  addTile({ label, wide: true, control: input });
}

/* ── views ────────────────────────────────────────────────────────────── */

function renderHome() {
  if (!state.data.categories.length) {
    return addEmpty('No upgrades available for this vehicle.');
  }

  state.data.categories.forEach((category) => {
    addTile({
      label: category.label,
      icon: category.icon,
      meta: `${category.items.length} ${category.items.length === 1 ? 'option' : 'options'}`,
      onClick: () => pushView(category.label, () => renderCategory(category)),
    });
  });
}

function renderCategory(category) {
  category.items.forEach((item) => {
    addTile({
      label: item.label,
      icon: item.icon,
      price: item.cost > 0 ? money(item.cost) : 'Free',
      onClick: () => openItem(item),
    });
  });
}

function openItem(item) {
  post('focusMod', { bone: item.bone, camera: item.camera, action: item.action });

  switch (item.kind) {
    case 'wheels':
      return pushView(item.label, () => renderWheels(item));
    case 'toggle':
      return pushView(item.label, () => renderToggle(item));
    case 'paint':
      return pushView(item.label, () => renderPaintGroups(item));
    case 'headlight':
      return pushView(item.label, () => renderHeadlight(item));
    case 'neon':
      return pushView(item.label, () => renderNeon(item));
    case 'extra':
      return pushView(item.label, () => renderExtras(item));
    case 'custom':
      return pushView(item.label, () => renderCustomPart(item));
    case 'plate':
      return pushView(item.label, () => renderSimpleOptions(item, 'setPlate'));
    case 'window':
      return pushView(item.label, () => renderSimpleOptions(item, 'setWindowTint'));
    default:
      return pushView(item.label, () => renderLevels(item));
  }
}

/* standard mod levels ---------------------------------------------------- */

function levelPrice(item, level) {
  if (level < 0 || level === item.current) return 0;
  return item.multicost ? item.cost * (level + 1) : item.cost;
}

function renderLevels(item) {
  if (!item.levels || item.levels.length <= 1) {
    return addEmpty('This vehicle has no parts for this slot.');
  }

  const selected = item.selected === undefined ? item.current : item.selected;

  item.levels.forEach((entry) => {
    const price = levelPrice(item, entry.level);

    addTile({
      label: entry.label,
      icon: item.icon,
      meta: entry.level < 0 ? 'Remove part' : `Level ${entry.level + 1}`,
      price: price > 0 ? money(price) : 'Free',
      active: selected === entry.level,
      flag: item.current === entry.level ? 'Fitted' : null,
      onClick: () => {
        post('setMod', {
          index: item.index,
          level: entry.level,
          wheelType: item.selectedType,
          customTires: item.customTires === true,
        });

        item.selected = entry.level;
        charge(`mod:${item.index}`, `${item.label} - ${entry.label}`, price);
        draw();
      },
    });
  });
}

/* wheels ----------------------------------------------------------------- */

function renderWheels(item) {
  addTile({
    label: 'Wheel type',
    icon: 'WheelType',
    meta: 'Pick a rim family',
    onClick: () => pushView('Wheel type', () => renderWheelTypes(item)),
  });

  addTile({
    label: 'Wheel colour',
    icon: 'WheelColor',
    meta: 'Free',
    onClick: () => pushView('Wheel colour', () => renderWheelColors(item)),
  });

  if (item.accessories && item.accessories.length) {
    addTile({
      label: 'Accessories',
      icon: 'Accessories',
      meta: 'Tyres and smoke',
      onClick: () => pushView('Accessories', () => renderWheelAccessories(item)),
    });
  }
}

function renderWheelTypes(item) {
  item.wheelTypes.forEach((type) => {
    addTile({
      label: type.label,
      // the raw config key, because the svg filenames are case sensitive
      icon: type.icon || String(type.label).replace(/\s+/g, ''),
      active: item.selectedType === type.value || (item.selectedType === undefined && item.currentType === type.value),
      onClick: async () => {
        item.selectedType = type.value;

        // navigate straight away, then fill in the rims once the game answers
        pushView(type.label, () => renderLevels(item));
        const depth = state.stack.length;

        const result = await post('getModLevels', {
          index: item.index,
          wheelType: type.value,
          name: item.name,
        });

        if (!result || !result.levels || state.stack.length !== depth) return;

        item.levels = result.levels;
        item.current = result.current;
        item.selected = result.current;
        draw();
      },
    });
  });
}

function renderWheelColors(item) {
  item.colors.forEach((color) => {
    addTile({
      label: color.label,
      icon: 'color',
      onClick: () => post('setWheelColor', { index: color.value }),
    });
  });
}

function renderWheelAccessories(item) {
  item.accessories.forEach((accessory) => {
    if (accessory.value === 'SmokeColor') {
      return addColorPicker('Tyre smoke colour', '#ffffff', (rgb) => post('setSmokeColor', rgb));
    }

    if (accessory.value === 'CustomTire') {
      return addTile({
        label: 'Custom tyre walls',
        icon: 'custom_tires',
        meta: item.customTires ? 'Enabled' : 'Disabled',
        active: item.customTires === true,
        onClick: () => {
          item.customTires = !item.customTires;
          post('toggleCustomTires', { enabled: item.customTires });
          charge('wheels:customtires', 'Custom tyre walls', item.customTires ? item.cost : 0);
          draw();
        },
      });
    }

    if (accessory.value === 'BulletProof') {
      return addTile({
        label: 'Bulletproof tyres',
        icon: 'wheel',
        meta: item.bulletProof ? 'Enabled' : 'Disabled',
        active: item.bulletProof === true,
        onClick: () => {
          item.bulletProof = !item.bulletProof;
          post('toggleBulletProof', { enabled: item.bulletProof });
          draw();
        },
      });
    }

    if (accessory.value === 'DriftTires') {
      const enabled = item.driftSelected === undefined ? item.driftEnabled : item.driftSelected;

      return addTile({
        label: 'Drift tyres',
        icon: 'custom_tires',
        meta: enabled ? 'Enabled' : 'Disabled',
        price: item.driftEnabled ? 'Free' : money(item.cost),
        active: enabled,
        onClick: () => {
          item.driftSelected = !enabled;
          post('toggleDrift', { enabled: item.driftSelected });
          charge('wheels:drift', 'Drift tyres', item.driftSelected && !item.driftEnabled ? item.cost : 0);
          draw();
        },
      });
    }
  });
}

/* turbo ------------------------------------------------------------------ */

function renderToggle(item) {
  const enabled = item.selected === undefined ? item.enabled : item.selected;

  [
    { label: 'Not installed', value: false },
    { label: 'Installed', value: true },
  ].forEach((option) => {
    addTile({
      label: option.label,
      icon: item.icon,
      price: option.value && !item.enabled ? money(item.cost) : 'Free',
      active: enabled === option.value,
      onClick: () => {
        item.selected = option.value;
        post('toggleTurbo', { enabled: option.value });
        charge(`toggle:${item.index}`, item.label, option.value && !item.enabled ? item.cost : 0);
        draw();
      },
    });
  });
}

/* paint ------------------------------------------------------------------ */

function renderPaintGroups(item) {
  addColorPicker('Custom RGB colour', '#ff0000', (rgb) => {
    post('setCustomColor', { target: item.target, r: rgb.r, g: rgb.g, b: rgb.b });
    charge(`paint:${item.target}`, `${item.label} (custom)`, item.cost);
  });

  item.groups.forEach((group) => {
    addTile({
      label: group.label,
      icon: item.icon,
      meta: `${group.colors.length} colours`,
      onClick: () => pushView(group.label, () => renderPaintColors(item, group)),
    });
  });
}

function renderPaintColors(item, group) {
  group.colors.forEach((color) => {
    const price = color.value === item.current ? 0 : item.cost;

    addTile({
      label: color.label,
      icon: item.icon,
      price: price > 0 ? money(price) : 'Free',
      active: item.selected === color.value,
      flag: item.current === color.value ? 'Current' : null,
      onClick: () => {
        item.selected = color.value;
        post('setPaint', { index: color.value, target: item.target, option: group.option });
        charge(`paint:${item.target}`, `${item.label} - ${color.label}`, price);
        draw();
      },
    });
  });
}

/* headlights ------------------------------------------------------------- */

function renderHeadlight(item) {
  const enabled = item.selected === undefined ? item.enabled : item.selected;

  const chargeHeadlight = () => {
    const on = item.selected === undefined ? item.enabled : item.selected;
    const colorChanged = item.selectedColor !== undefined && item.selectedColor !== item.current;
    const turnedOn = on && !item.enabled;
    charge('headlight', item.label, on && (turnedOn || colorChanged) ? item.cost : 0);
  };

  addTile({
    label: 'Standard headlights',
    icon: item.icon,
    meta: 'Remove xenon',
    active: enabled === false,
    onClick: () => {
      item.selected = false;
      post('setXenon', { enabled: false });
      chargeHeadlight();
      draw();
    },
  });

  addTile({
    label: 'Xenon headlights',
    icon: '22',
    price: item.enabled ? 'Free' : money(item.cost),
    active: enabled === true,
    onClick: () => {
      item.selected = true;
      post('setXenon', { enabled: true });
      chargeHeadlight();
      draw();
    },
  });

  item.colors.forEach((color) => {
    addTile({
      label: color.label,
      icon: 'xenon',
      active: item.selectedColor === color.value,
      flag: item.current === color.value && item.enabled ? 'Current' : null,
      onClick: () => {
        item.selected = true;
        item.selectedColor = color.value;
        post('setXenonColor', { index: color.value });
        chargeHeadlight();
        draw();
      },
    });
  });
}

/* neon ------------------------------------------------------------------- */

function renderNeon(item) {
  const enabled = item.selected === undefined ? item.enabled : item.selected;

  addTile({
    label: 'Neon off',
    icon: item.icon,
    active: enabled === false,
    onClick: () => {
      item.selected = false;
      post('setNeon', { enabled: false });
      uncharge('neon');
      draw();
    },
  });

  addTile({
    label: 'Neon kit',
    icon: item.icon,
    price: item.enabled ? 'Free' : money(item.cost),
    active: enabled === true,
    onClick: () => {
      item.selected = true;
      post('setNeon', { enabled: true });
      charge('neon', item.label, item.enabled ? 0 : item.cost);
      draw();
    },
  });

  addColorPicker('Neon colour', '#ff00c8', (rgb) => {
    item.selected = true;
    post('setNeonColor', { r: rgb.r, g: rgb.g, b: rgb.b });
    charge('neon', item.label, item.enabled ? 0 : item.cost);
  });
}

/* extras ----------------------------------------------------------------- */

function renderExtras(item) {
  if (!item.options.length) {
    return addEmpty('This vehicle has no extras.');
  }

  item.options.forEach((extra) => {
    const enabled = extra.selected === undefined ? extra.enabled : extra.selected;

    addTile({
      label: extra.label,
      icon: item.icon,
      meta: enabled ? 'Fitted' : 'Removed',
      active: enabled,
      onClick: () => {
        extra.selected = !enabled;
        post('setExtra', { index: extra.value, enabled: extra.selected });

        const changed = item.options.some((option) => option.selected !== undefined && option.selected !== option.enabled);
        charge('extra', item.label, changed ? item.cost : 0);
        draw();
      },
    });
  });
}

/* custom engine / turbo / tyres ------------------------------------------ */

function renderCustomPart(item) {
  item.options.forEach((option) => {
    const isDefault = option.key === 'Default';
    const isCurrent = item.slot === 'custom_engine'
      ? option.model === item.current
      : option.key === item.current;
    const price = isDefault || isCurrent ? 0 : option.value || item.cost;

    addTile({
      label: option.label,
      icon: item.icon,
      meta: isDefault ? 'Back to stock' : item.label,
      price: price > 0 ? money(price) : 'Free',
      active: item.selected === option.key,
      flag: isCurrent && !isDefault ? 'Fitted' : null,
      onClick: () => {
        item.selected = option.key;
        post('setCustomPart', { slot: item.slot, key: option.key, model: option.model });
        charge(`custom:${item.slot}`, `${item.label} - ${option.label}`, price);
        draw();
      },
    });
  });
}

/* plate / window tint ---------------------------------------------------- */

function renderSimpleOptions(item, callback) {
  item.options.forEach((option) => {
    const price = option.value === item.current ? 0 : item.cost;

    addTile({
      label: option.label,
      icon: item.icon,
      price: price > 0 ? money(price) : 'Free',
      active: item.selected === option.value,
      flag: item.current === option.value ? 'Current' : null,
      onClick: () => {
        item.selected = option.value;
        post(callback, { index: option.value });
        charge(`opt:${item.key}`, `${item.label} - ${option.label}`, price);
        draw();
      },
    });
  });
}

/* ── invoice / checkout ───────────────────────────────────────────────── */

function openInvoice() {
  ui.invoiceList.innerHTML = '';

  if (state.cart.size === 0) {
    const empty = document.createElement('li');
    empty.className = 'invoice__empty';
    empty.textContent = 'Nothing selected yet.';
    ui.invoiceList.appendChild(empty);
  } else {
    state.cart.forEach((entry) => {
      const row = document.createElement('li');

      const label = document.createElement('span');
      label.textContent = entry.label;

      const cost = document.createElement('strong');
      cost.textContent = money(entry.cost);

      row.append(label, cost);
      ui.invoiceList.appendChild(row);
    });
  }

  ui.invoiceShop.textContent = state.data ? state.data.shopLabel : '';
  ui.invoiceTotal.textContent = money(cartTotal());
  show(ui.invoice);
}

/* ── open / close ─────────────────────────────────────────────────────── */

function openMenu(data) {
  state.data = data;
  state.open = true;
  state.cart.clear();
  refreshCart();

  ui.shopName.textContent = data.shopLabel || 'Customs';
  ui.vehicleName.textContent = [data.vehicle, data.vehicleClass, (data.plate || '').trim()]
    .filter(Boolean)
    .join('  ·  ');
  ui.balance.textContent = `$${data.money || '0'}`;
  ui.repairCost.textContent = `$${data.repairCost || '0'}`;

  ui.freeBadge.classList.toggle('is-hidden', !data.free);

  hide(ui.invoice);
  hide(ui.spray);

  if (data.needsRepair) {
    show(ui.repair);
  } else {
    hide(ui.repair);
  }

  show(ui.app);
  resetTo('Categories', renderHome);
}

function closeMenu() {
  state.open = false;
  state.data = null;
  state.stack = [];
  state.cart.clear();
  refreshCart();

  ui.grid.innerHTML = '';
  ui.crumbs.innerHTML = '';
  ui.invoiceList.innerHTML = '';

  hide(ui.app);
  hide(ui.invoice);
  hide(ui.repair);
  hide(ui.spray);
}

/* ── events ───────────────────────────────────────────────────────────── */

ui.btnBack.addEventListener('click', popView);

ui.btnClose.addEventListener('click', () => {
  post('close');
  closeMenu();
});

ui.btnCheckout.addEventListener('click', openInvoice);

ui.btnInvoiceCancel.addEventListener('click', () => hide(ui.invoice));

ui.btnPay.addEventListener('click', async () => {
  ui.btnPay.disabled = true;
  const result = await post('pay');
  ui.btnPay.disabled = false;

  hide(ui.invoice);
  if (result && result.success) closeMenu();
});

ui.btnRepair.addEventListener('click', async () => {
  ui.btnRepair.disabled = true;
  const result = await post('repair');
  ui.btnRepair.disabled = false;

  if (result && result.success) hide(ui.repair);
});

ui.btnRepairCancel.addEventListener('click', () => {
  post('close');
  closeMenu();
});

ui.btnSprayDone.addEventListener('click', () => {
  post('sprayColorDone');
  hide(ui.spray);
});

ui.sprayColor.addEventListener('input', () => {
  post('sprayColor', hexToRgb(ui.sprayColor.value));
});

ui.search.addEventListener('input', () => {
  state.filter = ui.search.value.trim().toLowerCase();
  applyFilter();
});

document.addEventListener('keydown', (event) => {
  const typing = document.activeElement && document.activeElement.tagName === 'INPUT';

  if (!ui.spray.classList.contains('is-hidden')) {
    if (event.key === 'Escape') {
      post('sprayColorDone');
      hide(ui.spray);
    }
    return;
  }

  if (!state.open) return;

  if (event.key === 'Escape') {
    if (!ui.invoice.classList.contains('is-hidden')) return hide(ui.invoice);
    post('close');
    closeMenu();
    return;
  }

  if (typing) return;

  if (event.key === 'Backspace') {
    event.preventDefault();
    popView();
  } else if (event.key === 'e' || event.key === 'E') {
    post('toggleCamera');
  }
});

window.addEventListener('message', (event) => {
  const payload = event.data || {};

  switch (payload.action) {
    case 'open':
      openMenu(payload.data);
      break;
    case 'close':
      closeMenu();
      break;
    case 'playSound':
      if (payload.data) playSound(payload.data.file, payload.data.volume);
      break;
    case 'openSprayPicker':
      show(ui.spray);
      break;
    case 'closeSprayPicker':
      hide(ui.spray);
      break;
    default:
      break;
  }
});
