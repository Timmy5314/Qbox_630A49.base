/* ══════════════════════════════════════════════════════════════════════
   renzu_clothes — shop UI
   Vanilla JS, no external libraries.

   The cart lives in Lua, not here: it has to survive walking from one rack
   to the next, exactly like the original script where you collected things
   around the store and settled up at the register.
   ══════════════════════════════════════════════════════════════════════ */

(function () {
    'use strict';

    const RESOURCE = (typeof GetParentResourceName === 'function')
        ? GetParentResourceName()
        : 'renzu_clothes';

    /* ── State ───────────────────────────────────────────────────────── */

    const state = {
        open: false,
        categories: [],
        activeSlot: null,
        page: 1,
        pages: 1,
        total: 0,
        items: [],
        selection: {},          // slot -> { drawable, texture }
        arms: {},               // slot -> arms drawable
        cart: [],
        atRegister: false,      // alleen bij de kassa mag je afrekenen
        account: 'bank',
        money: { cash: 0, bank: 0 },
        worn: {},
    };

    /* ── Elements ────────────────────────────────────────────────────── */

    const el = {};
    const ids = [
        'app', 'shop-name', 'money-cash', 'money-bank', 'btn-cart', 'cart-badge',
        'btn-close', 'btn-wardrobe', 'btn-revert', 'category-list', 'stage',
        'panel-title', 'search', 'arms-row', 'arms-value', 'item-grid',
        'pager', 'pager-label', 'detail', 'detail-name', 'detail-price',
        'detail-swatches', 'btn-add', 'panel-empty', 'cart', 'cart-close',
        'cart-note', 'cart-items', 'cart-total', 'btn-checkout',
        'pay-row', 'toasts',
    ];

    ids.forEach(function (id) {
        el[id.replace(/-(\w)/g, function (_, c) { return c.toUpperCase(); })] = document.getElementById(id);
    });

    /* ── Icons ───────────────────────────────────────────────────────── */

    const ICONS = {
        mask:     '<path d="M3 8c0-2 3-3 9-3s9 1 9 3c0 5-3 11-9 11S3 13 3 8z"/><circle cx="8.5" cy="10" r="1"/><circle cx="15.5" cy="10" r="1"/>',
        shirt:    '<path d="M8 3l4 2 4-2 5 3-2 4-2-1v11H7V9L5 10 3 6z"/>',
        shield:   '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/>',
        sparkles: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M18 15l.9 2.1L21 18l-2.1.9L18 21l-.9-2.1L15 18l2.1-.9z"/>',
        pants:    '<path d="M7 3h10l1 18h-5l-1-9-1 9H6z"/>',
        shoe:     '<path d="M3 15h10l3 2h5v3H3z"/><path d="M3 15V8h4l2 4"/>',
        bag:      '<path d="M5 8h14l1 12H4z"/><path d="M9 8V6a3 3 0 016 0v2"/>',
        chain:    '<path d="M6 5v5a6 6 0 0012 0V5"/><circle cx="12" cy="17" r="2.5"/>',
        hat:      '<path d="M6 13V8a6 6 0 0112 0v5"/><path d="M3 13h18v3H3z"/>',
        glasses:  '<circle cx="6.5" cy="13" r="3.5"/><circle cx="17.5" cy="13" r="3.5"/><path d="M10 13h4M3 10l2-3M21 10l-2-3"/>',
        gem:      '<path d="M6 3h12l3 6-9 12L3 9z"/><path d="M3 9h18M9 3l3 18M15 3l-3 18"/>',
        watch:    '<circle cx="12" cy="12" r="5"/><path d="M9 7l.5-4h5L15 7M9 17l.5 4h5l.5-4M12 10v2.5l1.5 1"/>',
        bracelet: '<circle cx="12" cy="12" r="7"/><path d="M12 5v-2M12 21v-2"/>',
    };

    function icon(name) {
        return '<svg class="category__icon" viewBox="0 0 24 24" aria-hidden="true">' +
            (ICONS[name] || ICONS.shirt) + '</svg>';
    }

    /* ── NUI bridge ──────────────────────────────────────────────────── */

    function post(name, data) {
        return fetch('https://' + RESOURCE + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).then(function (res) {
            return res.json().catch(function () { return null; });
        }).catch(function () { return null; });
    }

    /* ── Toasts ──────────────────────────────────────────────────────── */

    function toast(message, kind) {
        const node = document.createElement('div');
        node.className = 'toast' + (kind ? ' toast--' + kind : '');
        node.textContent = message;
        el.toasts.appendChild(node);

        setTimeout(function () {
            node.classList.add('is-out');
            setTimeout(function () { node.remove(); }, 200);
        }, 2400);
    }

    function money(value) {
        return '$' + Number(value || 0).toLocaleString('en-US');
    }

    /* ── Open / close ────────────────────────────────────────────────── */

    function open(data) {
        state.open = true;
        state.categories = data.categories || [];
        state.money = data.money || { cash: 0, bank: 0 };
        state.account = data.defaultAccount === 'cash' ? 'cash' : 'bank';
        state.cart = data.cart || [];
        state.selection = {};
        state.arms = {};
        state.activeSlot = null;
        state.items = [];
        state.page = 1;
        state.pages = 1;
        state.worn = {};

        state.categories.forEach(function (cat) {
            if (cat.worn) state.worn[cat.key] = cat.worn;
            if (cat.arms) state.arms[cat.key] = cat.arms.current;
        });

        el.shopName.textContent = data.shop || 'Clothing Store';
        el.payRow.hidden = data.allowPaymentChoice === false;
        // Kleren uitzoeken mag overal, afrekenen alleen bij de kassa. De server
        // controleert dit ook (zie server/shop.lua); dit is puur zodat de speler
        // niet op een knop drukt die toch geweigerd wordt.
        state.atRegister = data.atRegister === true;
        el.cartNote.hidden = !state.atRegister;
        el.search.value = '';

        renderMoney();
        renderCategories();
        renderCart();
        setPay(state.account);

        el.itemGrid.innerHTML = '';
        el.panelEmpty.hidden = false;
        el.panelTitle.textContent = 'Pick a category';
        el.armsRow.hidden = true;
        el.pager.hidden = true;
        el.detail.hidden = true;

        el.app.classList.add('is-open');
        el.app.setAttribute('aria-hidden', 'false');

        if (data.view === 'cart') {
            el.cart.classList.add('is-open');
        } else {
            el.cart.classList.remove('is-open');
            if (state.categories.length === 1) selectCategory(state.categories[0].key);
        }
    }

    function close(silent) {
        if (!state.open) return;
        state.open = false;
        el.app.classList.remove('is-open');
        el.app.setAttribute('aria-hidden', 'true');
        el.cart.classList.remove('is-open');
        if (!silent) post('close');
    }

    /* ── Rendering ───────────────────────────────────────────────────── */

    function renderMoney() {
        el.moneyCash.textContent = Number(state.money.cash || 0).toLocaleString('en-US');
        el.moneyBank.textContent = Number(state.money.bank || 0).toLocaleString('en-US');
    }

    function renderCategories() {
        el.categoryList.innerHTML = '';
        const frag = document.createDocumentFragment();

        state.categories.forEach(function (cat) {
            const li = document.createElement('li');
            const btn = document.createElement('button');

            btn.type = 'button';
            btn.className = 'category' + (state.activeSlot === cat.key ? ' is-active' : '');
            btn.title = cat.label;
            btn.innerHTML =
                icon(cat.icon) +
                '<span class="category__label"></span>' +
                (state.worn[cat.key] ? '<span class="category__dot" title="You are wearing something here"></span>' : '') +
                '<span class="category__count">' + cat.count + '</span>';

            btn.querySelector('.category__label').textContent = cat.label;
            btn.addEventListener('click', function () { selectCategory(cat.key); });

            li.appendChild(btn);
            frag.appendChild(li);
        });

        el.categoryList.appendChild(frag);
    }

    function currentCategory() {
        for (let i = 0; i < state.categories.length; i++) {
            if (state.categories[i].key === state.activeSlot) return state.categories[i];
        }
        return null;
    }

    function selectCategory(slot) {
        state.activeSlot = slot;
        state.page = 1;
        el.search.value = '';

        const cat = currentCategory();
        if (!cat) return;

        renderCategories();
        el.panelTitle.textContent = cat.label;
        el.panelEmpty.hidden = true;
        el.detail.hidden = true;

        post('camera', { zone: cat.camera || 'full' });

        if (cat.arms) {
            el.armsRow.hidden = false;
            post('previewState', { slot: slot }).then(function (res) {
                if (res && typeof res.arms === 'number') state.arms[slot] = res.arms;
                el.armsValue.textContent = state.arms[slot] || 0;
            });
        } else {
            el.armsRow.hidden = true;
        }

        loadPage(1);
    }

    function loadPage(page) {
        const slot = state.activeSlot;
        if (!slot) return;

        el.itemGrid.innerHTML = '<p class="item-grid__msg">Loading…</p>';

        post('getItems', { slot: slot, page: page }).then(function (res) {
            if (!res || state.activeSlot !== slot) return;

            state.items = res.items || [];
            state.page = res.page || 1;
            state.pages = res.pages || 1;
            state.total = res.total || 0;

            renderItems();
            renderPager();
        });
    }

    function inCart(slot, drawable) {
        return state.cart.some(function (entry) {
            return entry.slot === slot && entry.drawable === drawable;
        });
    }

    function renderItems() {
        el.itemGrid.innerHTML = '';

        if (!state.items.length) {
            el.itemGrid.innerHTML = '<p class="item-grid__msg">Nothing in this category.</p>';
            return;
        }

        const slot = state.activeSlot;
        const selected = state.selection[slot];
        const worn = state.worn[slot];
        const frag = document.createDocumentFragment();

        state.items.forEach(function (item) {
            const isSelected = selected && selected.drawable === item.drawable;
            const isWorn = worn && worn.drawable === item.drawable;
            const carted = inCart(slot, item.drawable);

            const tile = document.createElement('button');
            tile.type = 'button';
            tile.className = 'tile' + (isSelected ? ' is-active' : '');
            tile.title = item.label;
            tile.dataset.drawable = item.drawable;
            tile.innerHTML =
                (carted ? '<span class="tile__flag tile__flag--cart" title="In your cart"></span>'
                    : isWorn ? '<span class="tile__flag tile__flag--worn" title="You are wearing this"></span>' : '') +
                '<span class="tile__num">' + item.drawable + '</span>' +
                '<span class="tile__price">' + money(item.variants[0].price) + '</span>';

            tile.addEventListener('click', function () {
                selectItem(item, isSelected && selected ? selected.texture : 0);
            });

            frag.appendChild(tile);
        });

        el.itemGrid.appendChild(frag);
    }

    function renderPager() {
        el.pager.hidden = state.pages <= 1;
        el.pagerLabel.textContent = state.page + ' / ' + state.pages + '  ·  ' + state.total + ' items';

        el.pager.querySelector('[data-page="prev"]').disabled = state.page <= 1;
        el.pager.querySelector('[data-page="next"]').disabled = state.page >= state.pages;
    }

    function findItem(drawable) {
        for (let i = 0; i < state.items.length; i++) {
            if (state.items[i].drawable === drawable) return state.items[i];
        }
        return null;
    }

    function selectItem(item, texture) {
        const slot = state.activeSlot;
        if (texture >= item.variants.length) texture = 0;

        state.selection[slot] = { drawable: item.drawable, texture: texture };

        post('preview', {
            slot: slot,
            drawable: item.drawable,
            texture: texture,
            arms: state.arms[slot],
        });

        renderItems();
        renderDetail();
    }

    function renderDetail() {
        const slot = state.activeSlot;
        const selected = state.selection[slot];

        if (!selected) {
            el.detail.hidden = true;
            return;
        }

        const item = findItem(selected.drawable);
        if (!item) {
            el.detail.hidden = true;
            return;
        }

        const variant = item.variants[selected.texture] || item.variants[0];

        el.detail.hidden = false;
        el.detailName.textContent = item.label;
        el.detailPrice.textContent = money(variant.price);

        el.detailSwatches.innerHTML = '';
        const frag = document.createDocumentFragment();

        item.variants.forEach(function (v) {
            const sw = document.createElement('button');
            sw.type = 'button';
            sw.className = 'swatch' + (v.texture === selected.texture ? ' is-active' : '');
            sw.textContent = v.texture;
            sw.title = money(v.price);
            sw.addEventListener('click', function () { selectItem(item, v.texture); });
            frag.appendChild(sw);
        });

        el.detailSwatches.appendChild(frag);

        const carted = state.cart.some(function (entry) {
            return entry.slot === slot && entry.drawable === selected.drawable && entry.texture === selected.texture;
        });

        el.btnAdd.disabled = carted;
        el.btnAdd.textContent = carted ? 'Already in cart' : 'Add to cart — ' + money(variant.price);
    }

    /* ── Cart ────────────────────────────────────────────────────────── */

    function setCart(list) {
        state.cart = list || [];
        renderCart();
        renderItems();
        renderDetail();
    }

    function addSelectedToCart() {
        const slot = state.activeSlot;
        const selected = state.selection[slot];
        if (!selected) return;

        const item = findItem(selected.drawable);
        if (!item) return;

        post('addToCart', {
            slot: slot,
            drawable: selected.drawable,
            texture: selected.texture,
            label: item.label + ' · ' + selected.texture,
        }).then(function (res) {
            if (!res) return;

            if (!res.ok) {
                toast(res.message || 'Could not add that.', 'error');
                if (res.cart) setCart(res.cart);
                return;
            }

            setCart(res.cart);
            toast('Added — pay at the register', 'success');
        });
    }

    function cartTotal() {
        return state.cart.reduce(function (sum, entry) { return sum + entry.price; }, 0);
    }

    function renderCart() {
        el.cartItems.innerHTML = '';

        if (!state.cart.length) {
            el.cartItems.innerHTML = '<p class="cart__empty">Your cart is empty.</p>';
        } else {
            const frag = document.createDocumentFragment();

            state.cart.forEach(function (entry) {
                const row = document.createElement('div');
                row.className = 'cart-item';
                row.innerHTML =
                    '<span class="cart-item__body">' +
                        '<span class="cart-item__name"></span>' +
                        '<span class="cart-item__meta"></span>' +
                    '</span>' +
                    '<span class="cart-item__price">' + money(entry.price) + '</span>' +
                    '<button type="button" class="cart-item__del" title="Remove">' +
                        '<svg viewBox="0 0 24 24"><path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13"/></svg>' +
                    '</button>';

                row.querySelector('.cart-item__name').textContent = entry.label;
                row.querySelector('.cart-item__meta').textContent = entry.slotLabel;
                row.querySelector('.cart-item__del').addEventListener('click', function () {
                    post('removeFromCart', { index: entry.index }).then(function (res) {
                        if (res && res.cart) setCart(res.cart);
                    });
                });

                frag.appendChild(row);
            });

            el.cartItems.appendChild(frag);
        }

        const total = cartTotal();
        el.cartTotal.textContent = money(total);
        // Afrekenen kan alleen bij de kassa. De server weigert het anders toch.
        el.btnCheckout.disabled = state.cart.length === 0 || !state.atRegister;
        el.btnCheckout.title = state.atRegister
            ? ''
            : 'Take your cart to the register to pay';
        el.cartBadge.textContent = state.cart.length;
        el.cartBadge.hidden = state.cart.length === 0;
    }

    function setPay(account) {
        state.account = account;
        el.payRow.querySelectorAll('.pay__btn').forEach(function (btn) {
            btn.classList.toggle('is-active', btn.dataset.account === account);
        });
    }

    function checkout() {
        if (!state.cart.length) return;
        if (!state.atRegister) {
            toast('Take your cart to the register to pay.', 'error');
            return;
        }

        el.btnCheckout.disabled = true;
        el.btnCheckout.textContent = 'Working…';

        post('checkout', {
            account: state.account,
        }).then(function (result) {
            el.btnCheckout.textContent = 'Checkout';

            if (!result || !result.success) {
                el.btnCheckout.disabled = state.cart.length === 0 || !state.atRegister;
                toast(result && result.message ? result.message : 'Purchase failed.', 'error');
                return;
            }

            toast('Paid ' + money(result.total) + ' — clothing added to your inventory', 'success');

            state.selection = {};

            setCart(result.cart || []);
            renderCategories();
            el.detail.hidden = true;
            el.cart.classList.remove('is-open');
        });
    }

    /* ── Camera: drag and zoom ───────────────────────────────────────── */

    let dragging = false;
    let lastX = 0;
    let pending = 0;
    let rafId = null;

    function flushRotation() {
        rafId = null;
        if (pending === 0) return;
        post('rotate', { delta: pending });
        pending = 0;
    }

    el.stage.addEventListener('mousedown', function (event) {
        if (event.button !== 0) return;
        dragging = true;
        lastX = event.clientX;
        event.preventDefault();
    });

    window.addEventListener('mousemove', function (event) {
        if (!dragging) return;
        pending += (event.clientX - lastX) * 0.45;
        lastX = event.clientX;
        if (rafId === null) rafId = requestAnimationFrame(flushRotation);
    });

    window.addEventListener('mouseup', function () { dragging = false; });

    el.stage.addEventListener('wheel', function (event) {
        event.preventDefault();
        post('zoom', { delta: event.deltaY > 0 ? 0.18 : -0.18 });
    }, { passive: false });

    /* ── Other listeners ─────────────────────────────────────────────── */

    el.btnClose.addEventListener('click', function () { close(); });

    el.btnWardrobe.addEventListener('click', function () {
        state.open = false;
        el.app.classList.remove('is-open');
        el.app.setAttribute('aria-hidden', 'true');
        post('wardrobe');
    });

    el.cartClose.addEventListener('click', function () { el.cart.classList.remove('is-open'); });
    el.btnCart.addEventListener('click', function () { el.cart.classList.toggle('is-open'); });
    el.btnCheckout.addEventListener('click', checkout);
    el.btnAdd.addEventListener('click', addSelectedToCart);

    el.pager.addEventListener('click', function (event) {
        const btn = event.target.closest('[data-page]');
        if (!btn || btn.disabled) return;
        loadPage(btn.dataset.page === 'next' ? state.page + 1 : state.page - 1);
    });

    // The search box jumps straight to a garment number — with hundreds of
    // variations that beats scrolling.
    el.search.addEventListener('input', function () {
        const value = parseInt(el.search.value, 10);
        if (isNaN(value) || value < 0 || value >= state.total) return;
        loadPage(Math.floor(value / 60) + 1);
    });

    el.btnRevert.addEventListener('click', function () {
        const slot = state.activeSlot;
        if (!slot) return;

        delete state.selection[slot];
        post('revert', { slot: slot });
        el.detail.hidden = true;
        renderItems();
        toast('Back to what you are wearing');
    });

    el.payRow.addEventListener('click', function (event) {
        const btn = event.target.closest('.pay__btn');
        if (btn) setPay(btn.dataset.account);
    });

    document.querySelectorAll('.zone-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.zone-btn').forEach(function (other) {
                other.classList.toggle('is-active', other === btn);
            });
            post('camera', { zone: btn.dataset.zone });
        });
    });

    document.querySelectorAll('[data-rotate]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            post('rotate', { delta: Number(btn.dataset.rotate) });
        });
    });

    document.querySelectorAll('[data-arms]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            const slot = state.activeSlot;
            const cat = currentCategory();
            if (!cat || !cat.arms) return;

            const max = Math.max(1, cat.arms.count);
            let value = (state.arms[slot] || 0) + Number(btn.dataset.arms);
            if (value < 0) value = max - 1;
            if (value >= max) value = 0;

            state.arms[slot] = value;
            el.armsValue.textContent = value;

            const selected = state.selection[slot];
            const worn = state.worn[slot];

            post('preview', {
                slot: slot,
                drawable: selected ? selected.drawable : (worn ? worn.drawable : 0),
                texture: selected ? selected.texture : (worn ? worn.texture : 0),
                arms: value,
            });
        });
    });

    window.addEventListener('keydown', function (event) {
        if (!state.open) return;

        if (event.key === 'Escape') {
            event.preventDefault();
            if (el.cart.classList.contains('is-open')) {
                el.cart.classList.remove('is-open');
            } else {
                close();
            }
        }

        if (event.key === 'Enter' && event.ctrlKey) {
            event.preventDefault();
            checkout();
        }
    });

    /* ── Messages from Lua ───────────────────────────────────────────── */

    window.addEventListener('message', function (event) {
        const msg = event.data || {};

        if (msg.action === 'open') {
            open(msg.data || {});
        } else if (msg.action === 'close') {
            close(true);
        } else if (msg.action === 'money') {
            state.money = msg.data || state.money;
            renderMoney();
        }
    });
})();
