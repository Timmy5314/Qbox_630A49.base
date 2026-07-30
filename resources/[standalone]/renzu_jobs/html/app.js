/* ─────────────────────────────────────────────────────────────────────────────
   renzu_jobs 2.0 - NUI logic

   Vanilla JS, no jQuery, no CDN. Closing a view hides it and drops focus; the
   old build called window.location.reload() which threw away all state and was
   the reason menus sometimes came back empty.
   ───────────────────────────────────────────────────────────────────────────── */

'use strict';

const RESOURCE = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'renzu_jobs';

/* ── DOM refs ─────────────────────────────────────────────────────────────── */

const dom = {
    panel:     document.getElementById('panel'),
    logo:      document.getElementById('panel-logo'),
    title:     document.getElementById('panel-title'),
    subtitle:  document.getElementById('panel-subtitle'),
    meta:      document.getElementById('panel-meta'),
    tabs:      document.getElementById('panel-tabs'),
    body:      document.getElementById('panel-body'),
    close:     document.getElementById('panel-close'),
    modalRoot: document.getElementById('modal-root'),
    toastRoot: document.getElementById('toast-root'),
    turf: {
        root:   document.getElementById('turf-hud'),
        label:  document.getElementById('turf-hud-label'),
        timer:  document.getElementById('turf-hud-timer'),
        status: document.getElementById('turf-hud-status'),
        scores: document.getElementById('turf-hud-scores'),
    },
};

/* ── State ────────────────────────────────────────────────────────────────── */

const state = {
    view: null,
    data: null,
    theme: { logo: '', items: '', fallback: '' },
    tab: null,
    busy: false,
};

/* ── Helpers ──────────────────────────────────────────────────────────────── */

/**
 * Create an element. `props` supports className, text, html, attrs and on* handlers.
 */
function el(tag, props = {}, children = []) {
    const node = document.createElement(tag);

    for (const [key, value] of Object.entries(props)) {
        if (value === undefined || value === null || value === false) continue;

        if (key === 'className') node.className = value;
        else if (key === 'text') node.textContent = value;
        else if (key === 'dataset') Object.assign(node.dataset, value);
        else if (key.startsWith('on') && typeof value === 'function') {
            node.addEventListener(key.slice(2).toLowerCase(), value);
        } else if (value === true) node.setAttribute(key, '');
        else node.setAttribute(key, value);
    }

    for (const child of [].concat(children)) {
        if (child === null || child === undefined || child === false) continue;
        node.append(child.nodeType ? child : document.createTextNode(String(child)));
    }

    return node;
}

function clear(node) {
    while (node.firstChild) node.removeChild(node.firstChild);
}

function money(value) {
    return Number(value || 0).toLocaleString('en-US');
}

/** Item image with a graceful fallback so a missing png never shows a broken icon. */
function itemImage(name, className = 'card__img') {
    const img = el('img', {
        className,
        alt: name || '',
        src: `${state.theme.items || ''}${(name || '').toLowerCase()}.png`,
        loading: 'lazy',
    });

    img.addEventListener('error', () => {
        if (img.dataset.fallbackApplied) return;
        img.dataset.fallbackApplied = '1';
        img.src = state.theme.fallback || '';
    }, { once: true });

    return img;
}

function remoteImage(src, className = 'card__img card__img--wide') {
    const img = el('img', { className, src: src || '', alt: '', loading: 'lazy' });

    img.addEventListener('error', () => {
        if (img.dataset.fallbackApplied) return;
        img.dataset.fallbackApplied = '1';
        img.src = state.theme.fallback || '';
    }, { once: true });

    return img;
}

/** POST to a Lua NUI callback. Never throws: a dead callback resolves to null. */
async function post(name, data = {}) {
    try {
        const response = await fetch(`https://${RESOURCE}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        });
        return await response.json();
    } catch (err) {
        console.error(`[renzu_jobs] callback "${name}" failed`, err);
        return null;
    }
}

function toast(message) {
    const node = el('div', { className: 'toast', text: message });
    dom.toastRoot.append(node);
    setTimeout(() => node.remove(), 3200);
}

/** Read + validate a positive integer from a modal input. */
function readAmount(input, { min = 1, max = Infinity, label = 'amount' } = {}) {
    const value = Math.floor(Number(input.value));

    if (!Number.isFinite(value) || value < min) {
        toast(`Enter a ${label} of at least ${min}.`);
        input.focus();
        return null;
    }
    if (value > max) {
        toast(`The most you can enter is ${max}.`);
        input.focus();
        return null;
    }
    return value;
}

/* ── Modal ────────────────────────────────────────────────────────────────── */

let modalOpen = false;

/**
 * @param {object} opts
 * @param {string} opts.title
 * @param {Node[]} opts.body
 * @param {{label:string, variant?:string, onClick:function}[]} opts.actions
 * @param {boolean} [opts.wide]
 */
function openModal({ title, body = [], actions = [], wide = false }) {
    closeModal();

    const modal = el('div', { className: `modal${wide ? ' modal--wide' : ''}` }, [
        el('div', { className: 'modal__head' }, [
            el('h2', { text: title }),
            el('button', {
                className: 'icon-btn',
                type: 'button',
                'aria-label': 'Close',
                onClick: closeModal,
            }, [closeIcon()]),
        ]),
        el('div', { className: 'modal__body' }, body),
        actions.length
            ? el('div', { className: 'modal__foot' }, actions.map((action) => el('button', {
                className: `btn${action.variant ? ` btn--${action.variant}` : ''}`,
                type: 'button',
                onClick: action.onClick,
            }, [action.label])))
            : null,
    ]);

    clear(dom.modalRoot);
    dom.modalRoot.append(modal);
    dom.modalRoot.hidden = false;
    modalOpen = true;

    const firstInput = modal.querySelector('input, select');
    if (firstInput) setTimeout(() => firstInput.focus(), 30);
}

function closeModal() {
    clear(dom.modalRoot);
    dom.modalRoot.hidden = true;
    modalOpen = false;
}

dom.modalRoot.addEventListener('mousedown', (event) => {
    if (event.target === dom.modalRoot) closeModal();
});

function closeIcon() {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('aria-hidden', 'true');

    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', 'M18 6L6 18M6 6l12 12');
    svg.append(path);

    return svg;
}

/* ── Panel shell ──────────────────────────────────────────────────────────── */

function setMeta(chips) {
    clear(dom.meta);

    for (const chip of chips) {
        if (!chip) continue;
        dom.meta.append(el('div', { className: 'meta-chip' }, [
            el('span', { className: 'meta-chip__label', text: chip.label }),
            el('span', { className: `meta-chip__value${chip.variant ? ` is-${chip.variant}` : ''}`, text: chip.value }),
        ]));
    }
}

function setTabs(tabs) {
    clear(dom.tabs);

    if (!tabs || tabs.length < 2) {
        dom.tabs.hidden = true;
        return;
    }

    dom.tabs.hidden = false;

    for (const tab of tabs) {
        dom.tabs.append(el('button', {
            className: `tab${state.tab === tab.id ? ' is-active' : ''}`,
            type: 'button',
            onClick: () => {
                state.tab = tab.id;
                render();
            },
        }, [tab.label]));
    }
}

function emptyState(message) {
    return el('div', { className: 'empty', text: message });
}

function openPanel(view, data, theme) {
    if (theme) state.theme = theme;

    state.view = view;
    state.data = data || {};
    state.tab = null;

    if (state.theme.logo) dom.logo.src = state.theme.logo;

    dom.panel.hidden = false;
    render();
}

function updatePanel(view, data) {
    if (state.view !== view) return;

    // Partial updates keep the current tab and only patch what changed.
    if (data && data.partial) {
        Object.assign(state.data, data);
        delete state.data.partial;
    } else {
        state.data = data || {};
    }

    render();
}

function closePanel() {
    closeModal();
    dom.panel.hidden = true;
    state.view = null;
    state.data = null;
    state.tab = null;
    state.busy = false;
}

/* ── Renderer dispatch ────────────────────────────────────────────────────── */

const views = {};

function render() {
    const renderer = views[state.view];
    if (!renderer) return;

    clear(dom.body);
    renderer(state.data);
}

/* ── View: boss menu ──────────────────────────────────────────────────────── */

views.boss = (data) => {
    const perms = data.permissions || {};
    const accounts = data.accounts || {};

    dom.title.textContent = data.job?.label || 'Company';
    dom.subtitle.textContent = `${(data.employees || []).length} employee(s) on the books`;

    setMeta([
        { label: 'Cash', value: `$${money(accounts.money)}`, variant: 'money' },
        accounts.black_money !== undefined
            ? { label: 'Black Money', value: `$${money(accounts.black_money)}`, variant: 'black' }
            : null,
    ]);

    const tabs = [{ id: 'employees', label: 'Employees' }];
    if (perms.salarychange) tabs.push({ id: 'salaries', label: 'Salaries' });
    if (perms.withdraw || perms.deposit) tabs.push({ id: 'treasury', label: 'Treasury' });
    tabs.push({ id: 'fleet', label: 'Fleet' });

    if (!state.tab || !tabs.some((tab) => tab.id === state.tab)) state.tab = tabs[0].id;
    setTabs(tabs);

    if (state.tab === 'employees') return renderEmployees(data, perms);
    if (state.tab === 'salaries')  return renderSalaries(data);
    if (state.tab === 'treasury')  return renderTreasury(data, perms);
    if (state.tab === 'fleet')     return renderFleet(perms);
};

function renderEmployees(data, perms) {
    const employees = data.employees || [];
    const nearby = data.nearby || [];

    const header = el('div', {
        className: 'card__actions',
        style: 'margin-bottom:16px',
    }, [
        el('button', {
            className: 'btn btn--ghost btn--sm',
            type: 'button',
            onClick: async () => { await post('boss:refresh'); },
        }, ['Refresh']),
        perms.hire
            ? el('button', {
                className: 'btn btn--sm',
                type: 'button',
                onClick: () => openHireModal(nearby),
            }, [`Hire nearby (${nearby.length})`])
            : null,
    ]);

    dom.body.append(header);

    if (!employees.length) {
        dom.body.append(emptyState('Nobody works here yet.'));
        return;
    }

    const list = el('div', { className: 'row-list' });

    for (const employee of employees) {
        list.append(el('div', { className: 'row' }, [
            el('img', { className: 'row__avatar', src: employee.image, alt: '' }),
            el('div', { className: 'row__info' }, [
                el('div', { className: 'row__name' }, [
                    el('span', { className: `dot${employee.online ? ' is-online' : ''}` }),
                    employee.name,
                ]),
                el('div', {
                    className: 'row__sub',
                    text: `${employee.gradeLabel} · grade ${employee.grade}`,
                }),
            ]),
            el('div', { className: 'row__actions' }, [
                perms.gradechange
                    ? el('button', {
                        className: 'btn btn--ghost btn--sm',
                        type: 'button',
                        onClick: () => openGradeModal(employee, data.grades || []),
                    }, ['Rank'])
                    : null,
                perms.givebonus
                    ? el('button', {
                        className: 'btn btn--success btn--sm',
                        type: 'button',
                        onClick: () => openBonusModal(employee, data.accounts?.money || 0),
                    }, ['Bonus'])
                    : null,
                perms.fire
                    ? el('button', {
                        className: 'btn btn--danger btn--sm',
                        type: 'button',
                        onClick: () => openFireModal(employee),
                    }, ['Fire'])
                    : null,
            ]),
        ]));
    }

    dom.body.append(list);
}

function openGradeModal(employee, grades) {
    openModal({
        title: `Change rank - ${employee.name}`,
        body: [
            el('p', { className: 'modal__note' }, [
                'Currently ', el('strong', { text: employee.gradeLabel }), ` (grade ${employee.grade}).`,
            ]),
            el('div', { className: 'option-list' }, grades.map((grade) => el('button', {
                className: 'option',
                type: 'button',
                onClick: async () => {
                    closeModal();
                    await post('boss:setGrade', { citizenid: employee.citizenid, grade: grade.level });
                },
            }, [
                el('span', { className: 'option__label', text: grade.label }),
                el('span', { className: 'option__meta', text: `grade ${grade.level} · $${money(grade.salary)}` }),
            ]))),
        ],
    });
}

function openBonusModal(employee, available) {
    const input = el('input', { type: 'number', min: '1', step: '1', placeholder: '1000' });

    openModal({
        title: `Pay a bonus - ${employee.name}`,
        body: [
            el('p', { className: 'modal__note' }, [
                'Paid from the company treasury. Available: ',
                el('strong', { text: `$${money(available)}` }), '.',
            ]),
            el('div', { className: 'field' }, [el('label', { text: 'Amount' }), input]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: 'Pay bonus',
                variant: 'success',
                onClick: async () => {
                    const amount = readAmount(input, { min: 1, max: available, label: 'amount' });
                    if (amount === null) return;
                    closeModal();
                    await post('boss:bonus', { citizenid: employee.citizenid, amount });
                },
            },
        ],
    });
}

function openFireModal(employee) {
    openModal({
        title: 'Confirm dismissal',
        body: [
            el('p', { className: 'modal__note' }, [
                'Remove ', el('strong', { text: employee.name }),
                ' from the company? They will be set to unemployed.',
            ]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: 'Fire',
                variant: 'danger',
                onClick: async () => {
                    closeModal();
                    await post('boss:fire', { citizenid: employee.citizenid });
                },
            },
        ],
    });
}

function openHireModal(nearby) {
    openModal({
        title: 'Hire somebody nearby',
        body: nearby.length
            ? [
                el('p', { className: 'modal__note', text: 'Only people standing close to you are listed.' }),
                el('div', { className: 'option-list' }, nearby.map((person) => el('button', {
                    className: 'option',
                    type: 'button',
                    onClick: async () => {
                        closeModal();
                        await post('boss:hire', { serverId: person.serverId });
                    },
                }, [
                    el('span', { className: 'option__label', text: person.name }),
                    el('span', { className: 'option__meta', text: `#${person.serverId}` }),
                ]))),
            ]
            : [el('p', { className: 'modal__note', text: 'Nobody is standing close enough to hire.' })],
    });
}

function renderSalaries(data) {
    const grades = data.grades || [];

    dom.body.append(el('p', {
        className: 'modal__note',
        text: `Maximum salary for this company: $${money(data.maxSalary)}.`,
    }));

    if (!grades.length) {
        dom.body.append(emptyState('This job has no grades registered in qbx_core.'));
        return;
    }

    const list = el('div', { className: 'row-list' });

    for (const grade of grades) {
        list.append(el('div', { className: 'row' }, [
            el('div', { className: 'row__info' }, [
                el('div', { className: 'row__name', text: grade.label }),
                el('div', { className: 'row__sub', text: `Grade ${grade.level}` }),
            ]),
            el('div', { className: 'row__actions' }, [
                el('span', { className: 'badge', text: `$${money(grade.salary)}` }),
                el('button', {
                    className: 'btn btn--ghost btn--sm',
                    type: 'button',
                    onClick: () => openSalaryModal(grade, data.maxSalary),
                }, ['Edit']),
            ]),
        ]));
    }

    dom.body.append(list);
}

function openSalaryModal(grade, maxSalary) {
    const input = el('input', { type: 'number', min: '0', step: '1', value: grade.salary });

    openModal({
        title: `Salary - ${grade.label}`,
        body: [
            el('div', { className: 'field' }, [
                el('label', { text: 'Amount per paycheck' }),
                input,
                el('div', { className: 'field__hint', text: `Maximum $${money(maxSalary)}.` }),
            ]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: 'Save',
                onClick: async () => {
                    const amount = readAmount(input, { min: 0, max: maxSalary, label: 'salary' });
                    if (amount === null) return;
                    closeModal();
                    await post('boss:setSalary', { grade: grade.level, amount });
                },
            },
        ],
    });
}

function renderTreasury(data, perms) {
    const accounts = data.accountList || [{ name: 'money', label: 'Cash' }];

    dom.body.append(el('p', {
        className: 'modal__note',
        text: 'Move money between your own pocket and the company treasury.',
    }));

    const grid = el('div', { className: 'grid grid--wide' });

    for (const account of accounts) {
        const balance = data.accounts?.[account.name] || 0;

        grid.append(el('div', { className: 'card' }, [
            el('div', { className: 'card__top' }, [
                el('div', { className: 'card__info' }, [
                    el('div', { className: 'card__name', text: account.label }),
                    el('div', { className: 'card__sub' }, [
                        el('span', { className: 'price', text: `$${money(balance)}` }),
                    ]),
                ]),
            ]),
            el('div', { className: 'card__actions' }, [
                perms.withdraw
                    ? el('button', {
                        className: 'btn btn--sm',
                        type: 'button',
                        onClick: () => openTransferModal('withdraw', account, balance),
                    }, ['Withdraw'])
                    : null,
                perms.deposit
                    ? el('button', {
                        className: 'btn btn--ghost btn--sm',
                        type: 'button',
                        onClick: () => openTransferModal('deposit', account, balance),
                    }, ['Deposit'])
                    : null,
            ]),
        ]));
    }

    dom.body.append(grid);
}

function openTransferModal(direction, account, balance) {
    const input = el('input', { type: 'number', min: '1', step: '1', placeholder: '1000' });
    const isWithdraw = direction === 'withdraw';

    openModal({
        title: `${isWithdraw ? 'Withdraw' : 'Deposit'} - ${account.label}`,
        body: [
            el('p', { className: 'modal__note' }, [
                isWithdraw ? 'Company balance: ' : 'Deposit into the company. Current balance: ',
                el('strong', { text: `$${money(balance)}` }), '.',
            ]),
            el('div', { className: 'field' }, [el('label', { text: 'Amount' }), input]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: isWithdraw ? 'Withdraw' : 'Deposit',
                variant: isWithdraw ? 'warning' : 'success',
                onClick: async () => {
                    const amount = readAmount(input, {
                        min: 1,
                        max: isWithdraw ? balance : Infinity,
                        label: 'amount',
                    });
                    if (amount === null) return;
                    closeModal();
                    await post('boss:transfer', { direction, account: account.name, amount });
                },
            },
        ],
    });
}

function renderFleet(perms) {
    dom.body.append(el('div', { className: 'card' }, [
        el('div', { className: 'card__top' }, [
            el('div', { className: 'card__info' }, [
                el('div', { className: 'card__name', text: 'Recall the fleet' }),
                el('div', {
                    className: 'card__sub',
                    text: 'Force every company vehicle back into the job garage.',
                }),
            ]),
        ]),
        el('div', { className: 'card__actions' }, [
            el('button', {
                className: 'btn btn--warning btn--sm',
                type: 'button',
                disabled: !perms.withdraw,
                onClick: () => openModal({
                    title: 'Recall every vehicle',
                    body: [el('p', {
                        className: 'modal__note',
                        text: 'Any company vehicle currently out on the streets will be deleted and returned to the garage. Anyone driving one will be left standing.',
                    })],
                    actions: [
                        { label: 'Cancel', variant: 'ghost', onClick: closeModal },
                        {
                            label: 'Recall all',
                            variant: 'warning',
                            onClick: async () => {
                                closeModal();
                                await post('boss:recallFleet');
                            },
                        },
                    ],
                }),
            }, ['Recall all']),
        ]),
    ]));

    if (!perms.withdraw) {
        dom.body.append(el('p', {
            className: 'field__hint',
            style: 'margin-top:10px',
            text: 'Your rank cannot manage the fleet.',
        }));
    }
}

/* ── View: shop ───────────────────────────────────────────────────────────── */

views.shop = (data) => {
    dom.title.textContent = data.label || 'Shop';
    dom.subtitle.textContent = data.public
        ? 'Open to the public'
        : 'Company shop - paid from the treasury';

    setMeta([{
        label: data.public ? 'Your cash' : 'Treasury',
        value: `$${money(data.balance)}`,
        variant: 'money',
    }]);
    setTabs(null);

    const items = data.items || [];
    if (!items.length) {
        dom.body.append(emptyState('This shop has no stock configured.'));
        return;
    }

    const grid = el('div', { className: 'grid' });

    for (const item of items) {
        grid.append(el('div', { className: 'card' }, [
            el('div', { className: 'card__top' }, [
                itemImage(item.image || item.name),
                el('div', { className: 'card__info' }, [
                    el('div', { className: 'card__name', text: item.label }),
                    el('div', { className: 'card__sub' }, [
                        item.price > 0
                            ? el('span', { className: 'price', text: `$${money(item.price)}` })
                            : el('span', { className: 'price price--free', text: 'Free' }),
                    ]),
                ]),
            ]),
            el('div', { className: 'card__actions' }, [
                el('button', {
                    className: 'btn btn--sm',
                    type: 'button',
                    onClick: () => openBuyModal(item, data.balance),
                }, ['Buy']),
            ]),
        ]));
    }

    dom.body.append(grid);
};

function openBuyModal(item, balance) {
    const isWeapon = /^weapon_/i.test(item.name);
    const maxAffordable = item.price > 0 ? Math.floor(balance / item.price) : 100;
    const max = isWeapon ? 1 : Math.max(1, Math.min(100, maxAffordable));

    const input = el('input', {
        type: 'number', min: '1', max: String(max), step: '1', value: '1',
    });

    const total = el('div', { className: 'field__hint', text: `Total: $${money(item.price)}` });
    input.addEventListener('input', () => {
        const amount = Math.max(0, Math.floor(Number(input.value) || 0));
        total.textContent = `Total: $${money(amount * item.price)}`;
    });

    openModal({
        title: `Buy ${item.label}`,
        body: [
            itemImage(item.image || item.name, 'modal__preview'),
            isWeapon
                ? el('p', { className: 'modal__note', text: 'Weapons are sold one at a time.' })
                : null,
            el('div', { className: 'field' }, [
                el('label', { text: 'Amount' }),
                input,
                item.price > 0 ? total : el('div', { className: 'field__hint', text: 'Free of charge.' }),
            ]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: 'Confirm',
                variant: 'success',
                onClick: async () => {
                    const amount = readAmount(input, { min: 1, max, label: 'amount' });
                    if (amount === null) return;
                    closeModal();
                    await post('shop:buy', { item: item.name, amount });
                },
            },
        ],
    });
}

/* ── View: crafting ───────────────────────────────────────────────────────── */

views.crafting = (data) => {
    dom.title.textContent = data.label || 'Workbench';
    dom.subtitle.textContent = 'Materials are taken when you start';
    setMeta([]);
    setTabs(null);

    const recipes = data.recipes || [];
    if (!recipes.length) {
        dom.body.append(emptyState('This workbench has no recipes configured.'));
        return;
    }

    const grid = el('div', { className: 'grid grid--wide' });

    for (const recipe of recipes) {
        const canCraft = recipe.requirements.every((req) => req.owned >= req.amount);

        grid.append(el('div', { className: 'card' }, [
            el('div', { className: 'card__top' }, [
                itemImage(recipe.image || recipe.name),
                el('div', { className: 'card__info' }, [
                    el('div', {
                        className: 'card__name',
                        text: recipe.amount > 1 ? `${recipe.label} x${recipe.amount}` : recipe.label,
                    }),
                    el('div', { className: 'card__sub' }, [
                        el('span', { text: `${recipe.seconds}s per batch` }),
                    ]),
                ]),
            ]),
            el('div', { className: 'reqs' }, recipe.requirements.map((req) => el('span', {
                className: `req ${req.owned >= req.amount ? 'is-ok' : 'is-missing'}`,
            }, [
                itemImage(req.image || req.name, ''),
                `${req.label} ${req.owned}/${req.amount}`,
            ]))),
            el('div', { className: 'card__actions' }, [
                el('button', {
                    className: 'btn btn--sm',
                    type: 'button',
                    disabled: !canCraft,
                    onClick: () => openCraftModal(recipe),
                }, [canCraft ? 'Craft' : 'Missing materials']),
            ]),
        ]));
    }

    dom.body.append(grid);
};

function openCraftModal(recipe) {
    const isWeapon = /^weapon_/i.test(recipe.name);

    // How many batches the materials actually allow.
    const possible = recipe.requirements.reduce(
        (lowest, req) => Math.min(lowest, Math.floor(req.owned / req.amount)),
        Infinity,
    );
    const max = isWeapon ? 1 : Math.max(1, Math.min(20, possible));

    const input = el('input', { type: 'number', min: '1', max: String(max), step: '1', value: '1' });
    const hint = el('div', { className: 'field__hint', text: `Takes ${recipe.seconds}s` });

    input.addEventListener('input', () => {
        const batches = Math.max(0, Math.floor(Number(input.value) || 0));
        hint.textContent = `Takes ${recipe.seconds * batches}s and produces ${recipe.amount * batches}`;
    });

    openModal({
        title: `Craft ${recipe.label}`,
        body: [
            itemImage(recipe.image || recipe.name, 'modal__preview'),
            el('p', { className: 'modal__note' }, [
                'You can make up to ', el('strong', { text: String(max) }),
                ' batch(es) with what you are carrying.',
            ]),
            el('div', { className: 'field' }, [
                el('label', { text: 'Batches' }),
                input,
                hint,
            ]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: 'Start',
                variant: 'success',
                onClick: async () => {
                    const amount = readAmount(input, { min: 1, max, label: 'amount' });
                    if (amount === null) return;
                    closeModal();
                    await post('crafting:craft', { item: recipe.name, amount });
                },
            },
        ],
    });
}

/* ── View: armory ─────────────────────────────────────────────────────────── */

views.armory = (data) => {
    dom.title.textContent = data.label || 'Armory';
    dom.subtitle.textContent = 'Sign weapons out and back in';
    setMeta([{ label: 'Treasury', value: `$${money(data.balance)}`, variant: 'money' }]);
    setTabs(null);

    const weapons = data.weapons || [];
    if (!weapons.length) {
        dom.body.append(emptyState('Your rank is not cleared for any weapon here.'));
        return;
    }

    const grid = el('div', { className: 'grid' });

    for (const weapon of weapons) {
        grid.append(el('div', { className: 'card' }, [
            el('div', { className: 'card__top' }, [
                itemImage(weapon.image || weapon.name),
                el('div', { className: 'card__info' }, [
                    el('div', { className: 'card__name', text: weapon.label }),
                    el('div', { className: 'card__sub' }, [
                        weapon.price > 0
                            ? el('span', { className: 'price', text: `$${money(weapon.price)}` })
                            : el('span', { className: 'price price--free', text: 'Free' }),
                        weapon.owned ? el('span', { className: 'badge badge--out', text: 'Signed out' }) : null,
                    ]),
                ]),
            ]),
            el('div', { className: 'card__actions' }, [
                el('button', {
                    className: `btn btn--sm${weapon.owned ? ' btn--danger' : ''}`,
                    type: 'button',
                    onClick: async () => { await post('armory:toggleWeapon', { weapon: weapon.name }); },
                }, [weapon.owned ? 'Return' : 'Take']),
                weapon.attachments?.length
                    ? el('button', {
                        className: 'btn btn--ghost btn--sm',
                        type: 'button',
                        onClick: () => openAttachmentModal(weapon),
                    }, ['Parts'])
                    : null,
            ]),
        ]));
    }

    dom.body.append(grid);
};

function openAttachmentModal(weapon) {
    openModal({
        title: `Attachments - ${weapon.label}`,
        wide: true,
        body: [
            el('p', {
                className: 'modal__note',
                text: 'Take a part, then equip the weapon and use the part from your inventory to fit it.',
            }),
            el('div', { className: 'option-list' }, weapon.attachments.map((attachment) => el('button', {
                className: 'option',
                type: 'button',
                onClick: async () => { await post('armory:takeAttachment', { item: attachment.name }); },
            }, [
                itemImage(attachment.image || attachment.name, ''),
                el('span', { className: 'option__label', text: attachment.label }),
                el('span', { className: 'option__meta', text: 'Take' }),
            ]))),
        ],
    });
}

/* ── View: job garage ─────────────────────────────────────────────────────── */

views.garage = (data) => {
    const vehicles = data.vehicles || [];
    const stored = vehicles.filter((vehicle) => vehicle.stored).length;

    dom.title.textContent = data.label || 'Job Garage';
    dom.subtitle.textContent = 'Company vehicles - sign one out, bring it back';
    setMeta([
        { label: 'In garage', value: `${stored}`, variant: 'money' },
        { label: 'Out', value: `${vehicles.length - stored}` },
    ]);
    setTabs(null);

    if (!vehicles.length) {
        dom.body.append(emptyState('The company does not own any vehicles yet.\nBuy one at the fleet dealer.'));
        return;
    }

    const grid = el('div', { className: 'grid grid--wide' });

    for (const vehicle of vehicles) {
        grid.append(el('div', { className: 'card' }, [
            el('div', { className: 'card__top' }, [
                remoteImage(vehicle.image),
                el('div', { className: 'card__info' }, [
                    el('div', { className: 'card__name', text: vehicle.label }),
                    el('div', { className: 'card__sub' }, [
                        el('span', { text: vehicle.plate }),
                        vehicle.stored
                            ? el('span', { className: 'badge badge--stored', text: 'In garage' })
                            : el('span', {
                                className: `badge ${vehicle.mine ? 'badge--mine' : 'badge--out'}`,
                                text: vehicle.mine ? 'You have it' : 'Out',
                            }),
                    ]),
                ]),
            ]),
            el('div', { className: 'card__actions' }, [
                vehicle.stored
                    ? el('button', {
                        className: 'btn btn--sm',
                        type: 'button',
                        onClick: async () => { await post('garage:take', { plate: vehicle.plate }); },
                    }, ['Take out'])
                    : el('button', {
                        className: 'btn btn--warning btn--sm',
                        type: 'button',
                        onClick: () => openRecoverModal(vehicle, data.recoveryFee),
                    }, ['Recover']),
            ]),
        ]));
    }

    dom.body.append(grid);
};

function openRecoverModal(vehicle, fee) {
    openModal({
        title: `Recover ${vehicle.label}`,
        body: [
            remoteImage(vehicle.image, 'modal__preview modal__preview--wide'),
            el('p', { className: 'modal__note' }, [
                'This vehicle is out on the streets. Recovering it deletes it wherever it is and puts it back in the garage',
                fee > 0 ? [' for ', el('strong', { text: `$${money(fee)}` }), '.'] : '.',
            ].flat()),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: fee > 0 ? `Pay $${money(fee)}` : 'Recover',
                variant: 'warning',
                onClick: async () => {
                    closeModal();
                    await post('garage:recover', { plate: vehicle.plate });
                },
            },
        ],
    });
}

/* ── View: fleet dealer ───────────────────────────────────────────────────── */

views.vehicleshop = (data) => {
    dom.title.textContent = data.label || 'Fleet Purchase';
    dom.subtitle.textContent = 'Bought with company money, delivered to the job garage';
    setMeta([{ label: 'Treasury', value: `$${money(data.balance)}`, variant: 'money' }]);
    setTabs(null);

    const vehicles = data.vehicles || [];
    if (!vehicles.length) {
        dom.body.append(emptyState('No vehicles are available at your rank.'));
        return;
    }

    const grid = el('div', { className: 'grid grid--wide' });

    for (const vehicle of vehicles) {
        const affordable = data.balance >= vehicle.price;

        grid.append(el('div', { className: 'card' }, [
            el('div', { className: 'card__top' }, [
                remoteImage(vehicle.image),
                el('div', { className: 'card__info' }, [
                    el('div', { className: 'card__name', text: vehicle.label }),
                    el('div', { className: 'card__sub' }, [
                        el('span', { className: 'price', text: `$${money(vehicle.price)}` }),
                        vehicle.class ? el('span', { text: vehicle.class }) : null,
                    ]),
                ]),
            ]),
            el('div', { className: 'card__actions' }, [
                el('button', {
                    className: 'btn btn--sm',
                    type: 'button',
                    disabled: !affordable,
                    onClick: () => openVehicleBuyModal(vehicle, data.balance),
                }, [affordable ? 'Buy' : 'Too expensive']),
            ]),
        ]));
    }

    dom.body.append(grid);
};

function openVehicleBuyModal(vehicle, balance) {
    openModal({
        title: `Buy ${vehicle.label}`,
        body: [
            remoteImage(vehicle.image, 'modal__preview modal__preview--wide'),
            el('p', { className: 'modal__note' }, [
                'Costs ', el('strong', { text: `$${money(vehicle.price)}` }),
                ' from the company treasury (', money(balance), ' available). ',
                'It will be waiting in the job garage.',
            ]),
        ],
        actions: [
            { label: 'Cancel', variant: 'ghost', onClick: closeModal },
            {
                label: 'Confirm purchase',
                variant: 'success',
                onClick: async () => {
                    closeModal();
                    await post('vehicleshop:buy', { model: vehicle.model });
                },
            },
        ],
    });
}

/* ── Turf HUD ─────────────────────────────────────────────────────────────── */

function formatTime(seconds) {
    const total = Math.max(0, Math.floor(seconds));
    const minutes = Math.floor(total / 60);
    const hours = Math.floor(minutes / 60);

    const pad = (value) => String(value).padStart(2, '0');
    return hours > 0
        ? `${pad(hours)}:${pad(minutes % 60)}:${pad(total % 60)}`
        : `${pad(minutes)}:${pad(total % 60)}`;
}

function renderTurf(payload) {
    if (!payload.show) {
        dom.turf.root.hidden = true;
        return;
    }

    dom.turf.root.hidden = false;
    dom.turf.label.textContent = payload.label || 'Turf War';
    dom.turf.timer.textContent = formatTime(payload.remaining);

    dom.turf.status.textContent = payload.contested
        ? 'Contested - clear the point'
        : 'Hold the point to score';
    dom.turf.status.classList.toggle('is-contested', !!payload.contested);

    clear(dom.turf.scores);

    const scores = payload.scores || [];
    if (!scores.length) {
        dom.turf.scores.append(el('li', {
            className: 'turf-score',
        }, [el('span', { className: 'turf-score__name', text: 'No points scored yet' })]));
        return;
    }

    for (const entry of scores.slice(0, 5)) {
        dom.turf.scores.append(el('li', {
            className: `turf-score${entry.mine ? ' is-mine' : ''}`,
        }, [
            el('span', { className: 'turf-score__name', text: entry.label }),
            el('span', { className: 'turf-score__points', text: String(entry.points) }),
        ]));
    }
}

/* ── Message bus ──────────────────────────────────────────────────────────── */

window.addEventListener('message', (event) => {
    const payload = event.data;
    if (!payload || typeof payload !== 'object') return;

    switch (payload.action) {
        case 'open':
            openPanel(payload.view, payload.data, payload.theme);
            break;
        case 'update':
            updatePanel(payload.view, payload.data);
            break;
        case 'close':
            closePanel();
            break;
        case 'turf':
            renderTurf(payload);
            break;
    }
});

/* ── Input ────────────────────────────────────────────────────────────────── */

dom.close.addEventListener('click', () => {
    closePanel();
    post('close');
});

document.addEventListener('keyup', (event) => {
    if (event.key !== 'Escape' && event.key !== 'Backspace') return;
    if (dom.panel.hidden) return;

    // Escape closes the modal first, the panel second.
    if (modalOpen) {
        closeModal();
        return;
    }

    closePanel();
    post('close');
});

// Swallow the browser context menu so a right click does not break immersion.
document.addEventListener('contextmenu', (event) => event.preventDefault());
