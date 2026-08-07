import { importShared as he, __tla as __tla_0 } from "./__federation_fn_import-D1HzgxBz.js";
import { s as G, j as de, __tla as __tla_1 } from "./App-DAtEXRTP.js";
Promise.all([
  (() => {
    try {
      return __tla_0;
    } catch {
    }
  })(),
  (() => {
    try {
      return __tla_1;
    } catch {
    }
  })()
]).then(async () => {
  const p = (r) => typeof r == "string", A = () => {
    let r, e;
    const t = new Promise((s, i) => {
      r = s, e = i;
    });
    return t.resolve = r, t.reject = e, t;
  }, _ = (r) => r == null ? "" : "" + r, me = (r, e, t) => {
    r.forEach((s) => {
      e[s] && (t[s] = e[s]);
    });
  }, ve = /###/g, ee = (r) => r && r.indexOf("###") > -1 ? r.replace(ve, ".") : r, te = (r) => !r || p(r), D = (r, e, t) => {
    const s = p(e) ? e.split(".") : e;
    let i = 0;
    for (; i < s.length - 1; ) {
      if (te(r)) return {};
      const n = ee(s[i]);
      !r[n] && t && (r[n] = new t()), Object.prototype.hasOwnProperty.call(r, n) ? r = r[n] : r = {}, ++i;
    }
    return te(r) ? {} : {
      obj: r,
      k: ee(s[i])
    };
  }, se = (r, e, t) => {
    const { obj: s, k: i } = D(r, e, Object);
    if (s !== void 0 || e.length === 1) {
      s[i] = t;
      return;
    }
    let n = e[e.length - 1], a = e.slice(0, e.length - 1), o = D(r, a, Object);
    for (; o.obj === void 0 && a.length; ) n = `${a[a.length - 1]}.${n}`, a = a.slice(0, a.length - 1), o = D(r, a, Object), o && o.obj && typeof o.obj[`${o.k}.${n}`] < "u" && (o.obj = void 0);
    o.obj[`${o.k}.${n}`] = t;
  }, xe = (r, e, t, s) => {
    const { obj: i, k: n } = D(r, e, Object);
    i[n] = i[n] || [], i[n].push(t);
  }, M = (r, e) => {
    const { obj: t, k: s } = D(r, e);
    if (t) return t[s];
  }, be = (r, e, t) => {
    const s = M(r, t);
    return s !== void 0 ? s : M(e, t);
  }, ge = (r, e, t) => {
    for (const s in e) s !== "__proto__" && s !== "constructor" && (s in r ? p(r[s]) || r[s] instanceof String || p(e[s]) || e[s] instanceof String ? t && (r[s] = e[s]) : ge(r[s], e[s], t) : r[s] = e[s]);
    return r;
  }, P = (r) => r.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
  var ye = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
    "/": "&#x2F;"
  };
  const Se = (r) => p(r) ? r.replace(/[&<>"'\/]/g, (e) => ye[e]) : r;
  class Le {
    constructor(e) {
      this.capacity = e, this.regExpMap = /* @__PURE__ */ new Map(), this.regExpQueue = [];
    }
    getRegExp(e) {
      const t = this.regExpMap.get(e);
      if (t !== void 0) return t;
      const s = new RegExp(e);
      return this.regExpQueue.length === this.capacity && this.regExpMap.delete(this.regExpQueue.shift()), this.regExpMap.set(e, s), this.regExpQueue.push(e), s;
    }
  }
  const Oe = [
    " ",
    ",",
    "?",
    "!",
    ";"
  ], we = new Le(20), Ce = (r, e, t) => {
    e = e || "", t = t || "";
    const s = Oe.filter((a) => e.indexOf(a) < 0 && t.indexOf(a) < 0);
    if (s.length === 0) return true;
    const i = we.getRegExp(`(${s.map((a) => a === "?" ? "\\?" : a).join("|")})`);
    let n = !i.test(r);
    if (!n) {
      const a = r.indexOf(t);
      a > 0 && !i.test(r.substring(0, a)) && (n = true);
    }
    return n;
  }, Y = function(r, e) {
    let t = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : ".";
    if (!r) return;
    if (r[e]) return r[e];
    const s = e.split(t);
    let i = r;
    for (let n = 0; n < s.length; ) {
      if (!i || typeof i != "object") return;
      let a, o = "";
      for (let l = n; l < s.length; ++l) if (l !== n && (o += t), o += s[l], a = i[o], a !== void 0) {
        if ([
          "string",
          "number",
          "boolean"
        ].indexOf(typeof a) > -1 && l < s.length - 1) continue;
        n += l - n + 1;
        break;
      }
      i = a;
    }
    return i;
  }, z = (r) => r && r.replace("_", "-"), Re = {
    type: "logger",
    log(r) {
      this.output("log", r);
    },
    warn(r) {
      this.output("warn", r);
    },
    error(r) {
      this.output("error", r);
    },
    output(r, e) {
      console && console[r] && console[r].apply(console, e);
    }
  };
  class H {
    constructor(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      this.init(e, t);
    }
    init(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      this.prefix = t.prefix || "i18next:", this.logger = e || Re, this.options = t, this.debug = t.debug;
    }
    log() {
      for (var e = arguments.length, t = new Array(e), s = 0; s < e; s++) t[s] = arguments[s];
      return this.forward(t, "log", "", true);
    }
    warn() {
      for (var e = arguments.length, t = new Array(e), s = 0; s < e; s++) t[s] = arguments[s];
      return this.forward(t, "warn", "", true);
    }
    error() {
      for (var e = arguments.length, t = new Array(e), s = 0; s < e; s++) t[s] = arguments[s];
      return this.forward(t, "error", "");
    }
    deprecate() {
      for (var e = arguments.length, t = new Array(e), s = 0; s < e; s++) t[s] = arguments[s];
      return this.forward(t, "warn", "WARNING DEPRECATED: ", true);
    }
    forward(e, t, s, i) {
      return i && !this.debug ? null : (p(e[0]) && (e[0] = `${s}${this.prefix} ${e[0]}`), this.logger[t](e));
    }
    create(e) {
      return new H(this.logger, {
        prefix: `${this.prefix}:${e}:`,
        ...this.options
      });
    }
    clone(e) {
      return e = e || this.options, e.prefix = e.prefix || this.prefix, new H(this.logger, e);
    }
  }
  var R = new H();
  class B {
    constructor() {
      this.observers = {};
    }
    on(e, t) {
      return e.split(" ").forEach((s) => {
        this.observers[s] || (this.observers[s] = /* @__PURE__ */ new Map());
        const i = this.observers[s].get(t) || 0;
        this.observers[s].set(t, i + 1);
      }), this;
    }
    off(e, t) {
      if (this.observers[e]) {
        if (!t) {
          delete this.observers[e];
          return;
        }
        this.observers[e].delete(t);
      }
    }
    emit(e) {
      for (var t = arguments.length, s = new Array(t > 1 ? t - 1 : 0), i = 1; i < t; i++) s[i - 1] = arguments[i];
      this.observers[e] && Array.from(this.observers[e].entries()).forEach((a) => {
        let [o, l] = a;
        for (let h = 0; h < l; h++) o(...s);
      }), this.observers["*"] && Array.from(this.observers["*"].entries()).forEach((a) => {
        let [o, l] = a;
        for (let h = 0; h < l; h++) o.apply(o, [
          e,
          ...s
        ]);
      });
    }
  }
  class ie extends B {
    constructor(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {
        ns: [
          "translation"
        ],
        defaultNS: "translation"
      };
      super(), this.data = e || {}, this.options = t, this.options.keySeparator === void 0 && (this.options.keySeparator = "."), this.options.ignoreJSONStructure === void 0 && (this.options.ignoreJSONStructure = true);
    }
    addNamespaces(e) {
      this.options.ns.indexOf(e) < 0 && this.options.ns.push(e);
    }
    removeNamespaces(e) {
      const t = this.options.ns.indexOf(e);
      t > -1 && this.options.ns.splice(t, 1);
    }
    getResource(e, t, s) {
      let i = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : {};
      const n = i.keySeparator !== void 0 ? i.keySeparator : this.options.keySeparator, a = i.ignoreJSONStructure !== void 0 ? i.ignoreJSONStructure : this.options.ignoreJSONStructure;
      let o;
      e.indexOf(".") > -1 ? o = e.split(".") : (o = [
        e,
        t
      ], s && (Array.isArray(s) ? o.push(...s) : p(s) && n ? o.push(...s.split(n)) : o.push(s)));
      const l = M(this.data, o);
      return !l && !t && !s && e.indexOf(".") > -1 && (e = o[0], t = o[1], s = o.slice(2).join(".")), l || !a || !p(s) ? l : Y(this.data && this.data[e] && this.data[e][t], s, n);
    }
    addResource(e, t, s, i) {
      let n = arguments.length > 4 && arguments[4] !== void 0 ? arguments[4] : {
        silent: false
      };
      const a = n.keySeparator !== void 0 ? n.keySeparator : this.options.keySeparator;
      let o = [
        e,
        t
      ];
      s && (o = o.concat(a ? s.split(a) : s)), e.indexOf(".") > -1 && (o = e.split("."), i = t, t = o[1]), this.addNamespaces(t), se(this.data, o, i), n.silent || this.emit("added", e, t, s, i);
    }
    addResources(e, t, s) {
      let i = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : {
        silent: false
      };
      for (const n in s) (p(s[n]) || Array.isArray(s[n])) && this.addResource(e, t, n, s[n], {
        silent: true
      });
      i.silent || this.emit("added", e, t, s);
    }
    addResourceBundle(e, t, s, i, n) {
      let a = arguments.length > 5 && arguments[5] !== void 0 ? arguments[5] : {
        silent: false,
        skipCopy: false
      }, o = [
        e,
        t
      ];
      e.indexOf(".") > -1 && (o = e.split("."), i = s, s = t, t = o[1]), this.addNamespaces(t);
      let l = M(this.data, o) || {};
      a.skipCopy || (s = JSON.parse(JSON.stringify(s))), i ? ge(l, s, n) : l = {
        ...l,
        ...s
      }, se(this.data, o, l), a.silent || this.emit("added", e, t, s);
    }
    removeResourceBundle(e, t) {
      this.hasResourceBundle(e, t) && delete this.data[e][t], this.removeNamespaces(t), this.emit("removed", e, t);
    }
    hasResourceBundle(e, t) {
      return this.getResource(e, t) !== void 0;
    }
    getResourceBundle(e, t) {
      return t || (t = this.options.defaultNS), this.options.compatibilityAPI === "v1" ? {
        ...this.getResource(e, t)
      } : this.getResource(e, t);
    }
    getDataByLanguage(e) {
      return this.data[e];
    }
    hasLanguageSomeTranslations(e) {
      const t = this.getDataByLanguage(e);
      return !!(t && Object.keys(t) || []).find((i) => t[i] && Object.keys(t[i]).length > 0);
    }
    toJSON() {
      return this.data;
    }
  }
  var fe = {
    processors: {},
    addPostProcessor(r) {
      this.processors[r.name] = r;
    },
    handle(r, e, t, s, i) {
      return r.forEach((n) => {
        this.processors[n] && (e = this.processors[n].process(e, t, s, i));
      }), e;
    }
  };
  const re = {};
  class J extends B {
    constructor(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      super(), me([
        "resourceStore",
        "languageUtils",
        "pluralResolver",
        "interpolator",
        "backendConnector",
        "i18nFormat",
        "utils"
      ], e, this), this.options = t, this.options.keySeparator === void 0 && (this.options.keySeparator = "."), this.logger = R.create("translator");
    }
    changeLanguage(e) {
      e && (this.language = e);
    }
    exists(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {
        interpolation: {}
      };
      if (e == null) return false;
      const s = this.resolve(e, t);
      return s && s.res !== void 0;
    }
    extractFromKey(e, t) {
      let s = t.nsSeparator !== void 0 ? t.nsSeparator : this.options.nsSeparator;
      s === void 0 && (s = ":");
      const i = t.keySeparator !== void 0 ? t.keySeparator : this.options.keySeparator;
      let n = t.ns || this.options.defaultNS || [];
      const a = s && e.indexOf(s) > -1, o = !this.options.userDefinedKeySeparator && !t.keySeparator && !this.options.userDefinedNsSeparator && !t.nsSeparator && !Ce(e, s, i);
      if (a && !o) {
        const l = e.match(this.interpolator.nestingRegexp);
        if (l && l.length > 0) return {
          key: e,
          namespaces: p(n) ? [
            n
          ] : n
        };
        const h = e.split(s);
        (s !== i || s === i && this.options.ns.indexOf(h[0]) > -1) && (n = h.shift()), e = h.join(i);
      }
      return {
        key: e,
        namespaces: p(n) ? [
          n
        ] : n
      };
    }
    translate(e, t, s) {
      if (typeof t != "object" && this.options.overloadTranslationOptionHandler && (t = this.options.overloadTranslationOptionHandler(arguments)), typeof t == "object" && (t = {
        ...t
      }), t || (t = {}), e == null) return "";
      Array.isArray(e) || (e = [
        String(e)
      ]);
      const i = t.returnDetails !== void 0 ? t.returnDetails : this.options.returnDetails, n = t.keySeparator !== void 0 ? t.keySeparator : this.options.keySeparator, { key: a, namespaces: o } = this.extractFromKey(e[e.length - 1], t), l = o[o.length - 1], h = t.lng || this.language, g = t.appendNamespaceToCIMode || this.options.appendNamespaceToCIMode;
      if (h && h.toLowerCase() === "cimode") {
        if (g) {
          const x = t.nsSeparator || this.options.nsSeparator;
          return i ? {
            res: `${l}${x}${a}`,
            usedKey: a,
            exactUsedKey: a,
            usedLng: h,
            usedNS: l,
            usedParams: this.getUsedParamsDetails(t)
          } : `${l}${x}${a}`;
        }
        return i ? {
          res: a,
          usedKey: a,
          exactUsedKey: a,
          usedLng: h,
          usedNS: l,
          usedParams: this.getUsedParamsDetails(t)
        } : a;
      }
      const f = this.resolve(e, t);
      let u = f && f.res;
      const c = f && f.usedKey || a, d = f && f.exactUsedKey || a, v = Object.prototype.toString.apply(u), m = [
        "[object Number]",
        "[object Function]",
        "[object RegExp]"
      ], L = t.joinArrays !== void 0 ? t.joinArrays : this.options.joinArrays, b = !this.i18nFormat || this.i18nFormat.handleAsObject, k = !p(u) && typeof u != "boolean" && typeof u != "number";
      if (b && u && k && m.indexOf(v) < 0 && !(p(L) && Array.isArray(u))) {
        if (!t.returnObjects && !this.options.returnObjects) {
          this.options.returnedObjectHandler || this.logger.warn("accessing an object - but returnObjects options is not enabled!");
          const x = this.options.returnedObjectHandler ? this.options.returnedObjectHandler(c, u, {
            ...t,
            ns: o
          }) : `key '${a} (${this.language})' returned an object instead of string.`;
          return i ? (f.res = x, f.usedParams = this.getUsedParamsDetails(t), f) : x;
        }
        if (n) {
          const x = Array.isArray(u), O = x ? [] : {}, C = x ? d : c;
          for (const y in u) if (Object.prototype.hasOwnProperty.call(u, y)) {
            const T = `${C}${n}${y}`;
            O[y] = this.translate(T, {
              ...t,
              joinArrays: false,
              ns: o
            }), O[y] === T && (O[y] = u[y]);
          }
          u = O;
        }
      } else if (b && p(L) && Array.isArray(u)) u = u.join(L), u && (u = this.extendTranslation(u, e, t, s));
      else {
        let x = false, O = false;
        const C = t.count !== void 0 && !p(t.count), y = J.hasDefaultValue(t), T = C ? this.pluralResolver.getSuffix(h, t.count, t) : "", ce = t.ordinal && C ? this.pluralResolver.getSuffix(h, t.count, {
          ordinal: false
        }) : "", Z = C && !t.ordinal && t.count === 0 && this.pluralResolver.shouldUseIntlApi(), E = Z && t[`defaultValue${this.options.pluralSeparator}zero`] || t[`defaultValue${T}`] || t[`defaultValue${ce}`] || t.defaultValue;
        !this.isValidLookup(u) && y && (x = true, u = E), this.isValidLookup(u) || (O = true, u = a);
        const pe = (t.missingKeyNoValueFallbackToKey || this.options.missingKeyNoValueFallbackToKey) && O ? void 0 : u, F = y && E !== u && this.options.updateMissing;
        if (O || x || F) {
          if (this.logger.log(F ? "updateKey" : "missingKey", h, l, a, F ? E : u), n) {
            const w = this.resolve(a, {
              ...t,
              keySeparator: false
            });
            w && w.res && this.logger.warn("Seems the loaded translations were in flat JSON format instead of nested. Either set keySeparator: false on init or make sure your translations are published in nested format.");
          }
          let j = [];
          const K = this.languageUtils.getFallbackCodes(this.options.fallbackLng, t.lng || this.language);
          if (this.options.saveMissingTo === "fallback" && K && K[0]) for (let w = 0; w < K.length; w++) j.push(K[w]);
          else this.options.saveMissingTo === "all" ? j = this.languageUtils.toResolveHierarchy(t.lng || this.language) : j.push(t.lng || this.language);
          const X = (w, N, I) => {
            const q = y && I !== u ? I : pe;
            this.options.missingKeyHandler ? this.options.missingKeyHandler(w, l, N, q, F, t) : this.backendConnector && this.backendConnector.saveMissing && this.backendConnector.saveMissing(w, l, N, q, F, t), this.emit("missingKey", w, l, N, u);
          };
          this.options.saveMissing && (this.options.saveMissingPlurals && C ? j.forEach((w) => {
            const N = this.pluralResolver.getSuffixes(w, t);
            Z && t[`defaultValue${this.options.pluralSeparator}zero`] && N.indexOf(`${this.options.pluralSeparator}zero`) < 0 && N.push(`${this.options.pluralSeparator}zero`), N.forEach((I) => {
              X([
                w
              ], a + I, t[`defaultValue${I}`] || E);
            });
          }) : X(j, a, E));
        }
        u = this.extendTranslation(u, e, t, f, s), O && u === a && this.options.appendNamespaceToMissingKey && (u = `${l}:${a}`), (O || x) && this.options.parseMissingKeyHandler && (this.options.compatibilityAPI !== "v1" ? u = this.options.parseMissingKeyHandler(this.options.appendNamespaceToMissingKey ? `${l}:${a}` : a, x ? u : void 0) : u = this.options.parseMissingKeyHandler(u));
      }
      return i ? (f.res = u, f.usedParams = this.getUsedParamsDetails(t), f) : u;
    }
    extendTranslation(e, t, s, i, n) {
      var a = this;
      if (this.i18nFormat && this.i18nFormat.parse) e = this.i18nFormat.parse(e, {
        ...this.options.interpolation.defaultVariables,
        ...s
      }, s.lng || this.language || i.usedLng, i.usedNS, i.usedKey, {
        resolved: i
      });
      else if (!s.skipInterpolation) {
        s.interpolation && this.interpolator.init({
          ...s,
          interpolation: {
            ...this.options.interpolation,
            ...s.interpolation
          }
        });
        const h = p(e) && (s && s.interpolation && s.interpolation.skipOnVariables !== void 0 ? s.interpolation.skipOnVariables : this.options.interpolation.skipOnVariables);
        let g;
        if (h) {
          const u = e.match(this.interpolator.nestingRegexp);
          g = u && u.length;
        }
        let f = s.replace && !p(s.replace) ? s.replace : s;
        if (this.options.interpolation.defaultVariables && (f = {
          ...this.options.interpolation.defaultVariables,
          ...f
        }), e = this.interpolator.interpolate(e, f, s.lng || this.language || i.usedLng, s), h) {
          const u = e.match(this.interpolator.nestingRegexp), c = u && u.length;
          g < c && (s.nest = false);
        }
        !s.lng && this.options.compatibilityAPI !== "v1" && i && i.res && (s.lng = this.language || i.usedLng), s.nest !== false && (e = this.interpolator.nest(e, function() {
          for (var u = arguments.length, c = new Array(u), d = 0; d < u; d++) c[d] = arguments[d];
          return n && n[0] === c[0] && !s.context ? (a.logger.warn(`It seems you are nesting recursively key: ${c[0]} in key: ${t[0]}`), null) : a.translate(...c, t);
        }, s)), s.interpolation && this.interpolator.reset();
      }
      const o = s.postProcess || this.options.postProcess, l = p(o) ? [
        o
      ] : o;
      return e != null && l && l.length && s.applyPostProcessor !== false && (e = fe.handle(l, e, t, this.options && this.options.postProcessPassResolved ? {
        i18nResolved: {
          ...i,
          usedParams: this.getUsedParamsDetails(s)
        },
        ...s
      } : s, this)), e;
    }
    resolve(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {}, s, i, n, a, o;
      return p(e) && (e = [
        e
      ]), e.forEach((l) => {
        if (this.isValidLookup(s)) return;
        const h = this.extractFromKey(l, t), g = h.key;
        i = g;
        let f = h.namespaces;
        this.options.fallbackNS && (f = f.concat(this.options.fallbackNS));
        const u = t.count !== void 0 && !p(t.count), c = u && !t.ordinal && t.count === 0 && this.pluralResolver.shouldUseIntlApi(), d = t.context !== void 0 && (p(t.context) || typeof t.context == "number") && t.context !== "", v = t.lngs ? t.lngs : this.languageUtils.toResolveHierarchy(t.lng || this.language, t.fallbackLng);
        f.forEach((m) => {
          this.isValidLookup(s) || (o = m, !re[`${v[0]}-${m}`] && this.utils && this.utils.hasLoadedNamespace && !this.utils.hasLoadedNamespace(o) && (re[`${v[0]}-${m}`] = true, this.logger.warn(`key "${i}" for languages "${v.join(", ")}" won't get resolved as namespace "${o}" was not yet loaded`, "This means something IS WRONG in your setup. You access the t function before i18next.init / i18next.loadNamespace / i18next.changeLanguage was done. Wait for the callback or Promise to resolve before accessing it!!!")), v.forEach((L) => {
            if (this.isValidLookup(s)) return;
            a = L;
            const b = [
              g
            ];
            if (this.i18nFormat && this.i18nFormat.addLookupKeys) this.i18nFormat.addLookupKeys(b, g, L, m, t);
            else {
              let x;
              u && (x = this.pluralResolver.getSuffix(L, t.count, t));
              const O = `${this.options.pluralSeparator}zero`, C = `${this.options.pluralSeparator}ordinal${this.options.pluralSeparator}`;
              if (u && (b.push(g + x), t.ordinal && x.indexOf(C) === 0 && b.push(g + x.replace(C, this.options.pluralSeparator)), c && b.push(g + O)), d) {
                const y = `${g}${this.options.contextSeparator}${t.context}`;
                b.push(y), u && (b.push(y + x), t.ordinal && x.indexOf(C) === 0 && b.push(y + x.replace(C, this.options.pluralSeparator)), c && b.push(y + O));
              }
            }
            let k;
            for (; k = b.pop(); ) this.isValidLookup(s) || (n = k, s = this.getResource(L, m, k, t));
          }));
        });
      }), {
        res: s,
        usedKey: i,
        exactUsedKey: n,
        usedLng: a,
        usedNS: o
      };
    }
    isValidLookup(e) {
      return e !== void 0 && !(!this.options.returnNull && e === null) && !(!this.options.returnEmptyString && e === "");
    }
    getResource(e, t, s) {
      let i = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : {};
      return this.i18nFormat && this.i18nFormat.getResource ? this.i18nFormat.getResource(e, t, s, i) : this.resourceStore.getResource(e, t, s, i);
    }
    getUsedParamsDetails() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
      const t = [
        "defaultValue",
        "ordinal",
        "context",
        "replace",
        "lng",
        "lngs",
        "fallbackLng",
        "ns",
        "keySeparator",
        "nsSeparator",
        "returnObjects",
        "returnDetails",
        "joinArrays",
        "postProcess",
        "interpolation"
      ], s = e.replace && !p(e.replace);
      let i = s ? e.replace : e;
      if (s && typeof e.count < "u" && (i.count = e.count), this.options.interpolation.defaultVariables && (i = {
        ...this.options.interpolation.defaultVariables,
        ...i
      }), !s) {
        i = {
          ...i
        };
        for (const n of t) delete i[n];
      }
      return i;
    }
    static hasDefaultValue(e) {
      const t = "defaultValue";
      for (const s in e) if (Object.prototype.hasOwnProperty.call(e, s) && t === s.substring(0, t.length) && e[s] !== void 0) return true;
      return false;
    }
  }
  const W = (r) => r.charAt(0).toUpperCase() + r.slice(1);
  class ne {
    constructor(e) {
      this.options = e, this.supportedLngs = this.options.supportedLngs || false, this.logger = R.create("languageUtils");
    }
    getScriptPartFromCode(e) {
      if (e = z(e), !e || e.indexOf("-") < 0) return null;
      const t = e.split("-");
      return t.length === 2 || (t.pop(), t[t.length - 1].toLowerCase() === "x") ? null : this.formatLanguageCode(t.join("-"));
    }
    getLanguagePartFromCode(e) {
      if (e = z(e), !e || e.indexOf("-") < 0) return e;
      const t = e.split("-");
      return this.formatLanguageCode(t[0]);
    }
    formatLanguageCode(e) {
      if (p(e) && e.indexOf("-") > -1) {
        if (typeof Intl < "u" && typeof Intl.getCanonicalLocales < "u") try {
          let i = Intl.getCanonicalLocales(e)[0];
          if (i && this.options.lowerCaseLng && (i = i.toLowerCase()), i) return i;
        } catch {
        }
        const t = [
          "hans",
          "hant",
          "latn",
          "cyrl",
          "cans",
          "mong",
          "arab"
        ];
        let s = e.split("-");
        return this.options.lowerCaseLng ? s = s.map((i) => i.toLowerCase()) : s.length === 2 ? (s[0] = s[0].toLowerCase(), s[1] = s[1].toUpperCase(), t.indexOf(s[1].toLowerCase()) > -1 && (s[1] = W(s[1].toLowerCase()))) : s.length === 3 && (s[0] = s[0].toLowerCase(), s[1].length === 2 && (s[1] = s[1].toUpperCase()), s[0] !== "sgn" && s[2].length === 2 && (s[2] = s[2].toUpperCase()), t.indexOf(s[1].toLowerCase()) > -1 && (s[1] = W(s[1].toLowerCase())), t.indexOf(s[2].toLowerCase()) > -1 && (s[2] = W(s[2].toLowerCase()))), s.join("-");
      }
      return this.options.cleanCode || this.options.lowerCaseLng ? e.toLowerCase() : e;
    }
    isSupportedCode(e) {
      return (this.options.load === "languageOnly" || this.options.nonExplicitSupportedLngs) && (e = this.getLanguagePartFromCode(e)), !this.supportedLngs || !this.supportedLngs.length || this.supportedLngs.indexOf(e) > -1;
    }
    getBestMatchFromCodes(e) {
      if (!e) return null;
      let t;
      return e.forEach((s) => {
        if (t) return;
        const i = this.formatLanguageCode(s);
        (!this.options.supportedLngs || this.isSupportedCode(i)) && (t = i);
      }), !t && this.options.supportedLngs && e.forEach((s) => {
        if (t) return;
        const i = this.getLanguagePartFromCode(s);
        if (this.isSupportedCode(i)) return t = i;
        t = this.options.supportedLngs.find((n) => {
          if (n === i) return n;
          if (!(n.indexOf("-") < 0 && i.indexOf("-") < 0) && (n.indexOf("-") > 0 && i.indexOf("-") < 0 && n.substring(0, n.indexOf("-")) === i || n.indexOf(i) === 0 && i.length > 1)) return n;
        });
      }), t || (t = this.getFallbackCodes(this.options.fallbackLng)[0]), t;
    }
    getFallbackCodes(e, t) {
      if (!e) return [];
      if (typeof e == "function" && (e = e(t)), p(e) && (e = [
        e
      ]), Array.isArray(e)) return e;
      if (!t) return e.default || [];
      let s = e[t];
      return s || (s = e[this.getScriptPartFromCode(t)]), s || (s = e[this.formatLanguageCode(t)]), s || (s = e[this.getLanguagePartFromCode(t)]), s || (s = e.default), s || [];
    }
    toResolveHierarchy(e, t) {
      const s = this.getFallbackCodes(t || this.options.fallbackLng || [], e), i = [], n = (a) => {
        a && (this.isSupportedCode(a) ? i.push(a) : this.logger.warn(`rejecting language code not found in supportedLngs: ${a}`));
      };
      return p(e) && (e.indexOf("-") > -1 || e.indexOf("_") > -1) ? (this.options.load !== "languageOnly" && n(this.formatLanguageCode(e)), this.options.load !== "languageOnly" && this.options.load !== "currentOnly" && n(this.getScriptPartFromCode(e)), this.options.load !== "currentOnly" && n(this.getLanguagePartFromCode(e))) : p(e) && n(this.formatLanguageCode(e)), s.forEach((a) => {
        i.indexOf(a) < 0 && n(this.formatLanguageCode(a));
      }), i;
    }
  }
  let Ne = [
    {
      lngs: [
        "ach",
        "ak",
        "am",
        "arn",
        "br",
        "fil",
        "gun",
        "ln",
        "mfe",
        "mg",
        "mi",
        "oc",
        "pt",
        "pt-BR",
        "tg",
        "tl",
        "ti",
        "tr",
        "uz",
        "wa"
      ],
      nr: [
        1,
        2
      ],
      fc: 1
    },
    {
      lngs: [
        "af",
        "an",
        "ast",
        "az",
        "bg",
        "bn",
        "ca",
        "da",
        "de",
        "dev",
        "el",
        "en",
        "eo",
        "es",
        "et",
        "eu",
        "fi",
        "fo",
        "fur",
        "fy",
        "gl",
        "gu",
        "ha",
        "hi",
        "hu",
        "hy",
        "ia",
        "it",
        "kk",
        "kn",
        "ku",
        "lb",
        "mai",
        "ml",
        "mn",
        "mr",
        "nah",
        "nap",
        "nb",
        "ne",
        "nl",
        "nn",
        "no",
        "nso",
        "pa",
        "pap",
        "pms",
        "ps",
        "pt-PT",
        "rm",
        "sco",
        "se",
        "si",
        "so",
        "son",
        "sq",
        "sv",
        "sw",
        "ta",
        "te",
        "tk",
        "ur",
        "yo"
      ],
      nr: [
        1,
        2
      ],
      fc: 2
    },
    {
      lngs: [
        "ay",
        "bo",
        "cgg",
        "fa",
        "ht",
        "id",
        "ja",
        "jbo",
        "ka",
        "km",
        "ko",
        "ky",
        "lo",
        "ms",
        "sah",
        "su",
        "th",
        "tt",
        "ug",
        "vi",
        "wo",
        "zh"
      ],
      nr: [
        1
      ],
      fc: 3
    },
    {
      lngs: [
        "be",
        "bs",
        "cnr",
        "dz",
        "hr",
        "ru",
        "sr",
        "uk"
      ],
      nr: [
        1,
        2,
        5
      ],
      fc: 4
    },
    {
      lngs: [
        "ar"
      ],
      nr: [
        0,
        1,
        2,
        3,
        11,
        100
      ],
      fc: 5
    },
    {
      lngs: [
        "cs",
        "sk"
      ],
      nr: [
        1,
        2,
        5
      ],
      fc: 6
    },
    {
      lngs: [
        "csb",
        "pl"
      ],
      nr: [
        1,
        2,
        5
      ],
      fc: 7
    },
    {
      lngs: [
        "cy"
      ],
      nr: [
        1,
        2,
        3,
        8
      ],
      fc: 8
    },
    {
      lngs: [
        "fr"
      ],
      nr: [
        1,
        2
      ],
      fc: 9
    },
    {
      lngs: [
        "ga"
      ],
      nr: [
        1,
        2,
        3,
        7,
        11
      ],
      fc: 10
    },
    {
      lngs: [
        "gd"
      ],
      nr: [
        1,
        2,
        3,
        20
      ],
      fc: 11
    },
    {
      lngs: [
        "is"
      ],
      nr: [
        1,
        2
      ],
      fc: 12
    },
    {
      lngs: [
        "jv"
      ],
      nr: [
        0,
        1
      ],
      fc: 13
    },
    {
      lngs: [
        "kw"
      ],
      nr: [
        1,
        2,
        3,
        4
      ],
      fc: 14
    },
    {
      lngs: [
        "lt"
      ],
      nr: [
        1,
        2,
        10
      ],
      fc: 15
    },
    {
      lngs: [
        "lv"
      ],
      nr: [
        1,
        2,
        0
      ],
      fc: 16
    },
    {
      lngs: [
        "mk"
      ],
      nr: [
        1,
        2
      ],
      fc: 17
    },
    {
      lngs: [
        "mnk"
      ],
      nr: [
        0,
        1,
        2
      ],
      fc: 18
    },
    {
      lngs: [
        "mt"
      ],
      nr: [
        1,
        2,
        11,
        20
      ],
      fc: 19
    },
    {
      lngs: [
        "or"
      ],
      nr: [
        2,
        1
      ],
      fc: 2
    },
    {
      lngs: [
        "ro"
      ],
      nr: [
        1,
        2,
        20
      ],
      fc: 20
    },
    {
      lngs: [
        "sl"
      ],
      nr: [
        5,
        1,
        2,
        3
      ],
      fc: 21
    },
    {
      lngs: [
        "he",
        "iw"
      ],
      nr: [
        1,
        2,
        20,
        21
      ],
      fc: 22
    }
  ], Pe = {
    1: (r) => +(r > 1),
    2: (r) => +(r != 1),
    3: (r) => 0,
    4: (r) => r % 10 == 1 && r % 100 != 11 ? 0 : r % 10 >= 2 && r % 10 <= 4 && (r % 100 < 10 || r % 100 >= 20) ? 1 : 2,
    5: (r) => r == 0 ? 0 : r == 1 ? 1 : r == 2 ? 2 : r % 100 >= 3 && r % 100 <= 10 ? 3 : r % 100 >= 11 ? 4 : 5,
    6: (r) => r == 1 ? 0 : r >= 2 && r <= 4 ? 1 : 2,
    7: (r) => r == 1 ? 0 : r % 10 >= 2 && r % 10 <= 4 && (r % 100 < 10 || r % 100 >= 20) ? 1 : 2,
    8: (r) => r == 1 ? 0 : r == 2 ? 1 : r != 8 && r != 11 ? 2 : 3,
    9: (r) => +(r >= 2),
    10: (r) => r == 1 ? 0 : r == 2 ? 1 : r < 7 ? 2 : r < 11 ? 3 : 4,
    11: (r) => r == 1 || r == 11 ? 0 : r == 2 || r == 12 ? 1 : r > 2 && r < 20 ? 2 : 3,
    12: (r) => +(r % 10 != 1 || r % 100 == 11),
    13: (r) => +(r !== 0),
    14: (r) => r == 1 ? 0 : r == 2 ? 1 : r == 3 ? 2 : 3,
    15: (r) => r % 10 == 1 && r % 100 != 11 ? 0 : r % 10 >= 2 && (r % 100 < 10 || r % 100 >= 20) ? 1 : 2,
    16: (r) => r % 10 == 1 && r % 100 != 11 ? 0 : r !== 0 ? 1 : 2,
    17: (r) => r == 1 || r % 10 == 1 && r % 100 != 11 ? 0 : 1,
    18: (r) => r == 0 ? 0 : r == 1 ? 1 : 2,
    19: (r) => r == 1 ? 0 : r == 0 || r % 100 > 1 && r % 100 < 11 ? 1 : r % 100 > 10 && r % 100 < 20 ? 2 : 3,
    20: (r) => r == 1 ? 0 : r == 0 || r % 100 > 0 && r % 100 < 20 ? 1 : 2,
    21: (r) => r % 100 == 1 ? 1 : r % 100 == 2 ? 2 : r % 100 == 3 || r % 100 == 4 ? 3 : 0,
    22: (r) => r == 1 ? 0 : r == 2 ? 1 : (r < 0 || r > 10) && r % 10 == 0 ? 2 : 3
  };
  const $e = [
    "v1",
    "v2",
    "v3"
  ], ke = [
    "v4"
  ], ae = {
    zero: 0,
    one: 1,
    two: 2,
    few: 3,
    many: 4,
    other: 5
  }, Ee = () => {
    const r = {};
    return Ne.forEach((e) => {
      e.lngs.forEach((t) => {
        r[t] = {
          numbers: e.nr,
          plurals: Pe[e.fc]
        };
      });
    }), r;
  };
  class Fe {
    constructor(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      this.languageUtils = e, this.options = t, this.logger = R.create("pluralResolver"), (!this.options.compatibilityJSON || ke.includes(this.options.compatibilityJSON)) && (typeof Intl > "u" || !Intl.PluralRules) && (this.options.compatibilityJSON = "v3", this.logger.error("Your environment seems not to be Intl API compatible, use an Intl.PluralRules polyfill. Will fallback to the compatibilityJSON v3 format handling.")), this.rules = Ee(), this.pluralRulesCache = {};
    }
    addRule(e, t) {
      this.rules[e] = t;
    }
    clearCache() {
      this.pluralRulesCache = {};
    }
    getRule(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      if (this.shouldUseIntlApi()) {
        const s = z(e === "dev" ? "en" : e), i = t.ordinal ? "ordinal" : "cardinal", n = JSON.stringify({
          cleanedCode: s,
          type: i
        });
        if (n in this.pluralRulesCache) return this.pluralRulesCache[n];
        let a;
        try {
          a = new Intl.PluralRules(s, {
            type: i
          });
        } catch {
          if (!e.match(/-|_/)) return;
          const l = this.languageUtils.getLanguagePartFromCode(e);
          a = this.getRule(l, t);
        }
        return this.pluralRulesCache[n] = a, a;
      }
      return this.rules[e] || this.rules[this.languageUtils.getLanguagePartFromCode(e)];
    }
    needsPlural(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      const s = this.getRule(e, t);
      return this.shouldUseIntlApi() ? s && s.resolvedOptions().pluralCategories.length > 1 : s && s.numbers.length > 1;
    }
    getPluralFormsOfKey(e, t) {
      let s = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {};
      return this.getSuffixes(e, s).map((i) => `${t}${i}`);
    }
    getSuffixes(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      const s = this.getRule(e, t);
      return s ? this.shouldUseIntlApi() ? s.resolvedOptions().pluralCategories.sort((i, n) => ae[i] - ae[n]).map((i) => `${this.options.prepend}${t.ordinal ? `ordinal${this.options.prepend}` : ""}${i}`) : s.numbers.map((i) => this.getSuffix(e, i, t)) : [];
    }
    getSuffix(e, t) {
      let s = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {};
      const i = this.getRule(e, s);
      return i ? this.shouldUseIntlApi() ? `${this.options.prepend}${s.ordinal ? `ordinal${this.options.prepend}` : ""}${i.select(t)}` : this.getSuffixRetroCompatible(i, t) : (this.logger.warn(`no plural rule found for: ${e}`), "");
    }
    getSuffixRetroCompatible(e, t) {
      const s = e.noAbs ? e.plurals(t) : e.plurals(Math.abs(t));
      let i = e.numbers[s];
      this.options.simplifyPluralSuffix && e.numbers.length === 2 && e.numbers[0] === 1 && (i === 2 ? i = "plural" : i === 1 && (i = ""));
      const n = () => this.options.prepend && i.toString() ? this.options.prepend + i.toString() : i.toString();
      return this.options.compatibilityJSON === "v1" ? i === 1 ? "" : typeof i == "number" ? `_plural_${i.toString()}` : n() : this.options.compatibilityJSON === "v2" || this.options.simplifyPluralSuffix && e.numbers.length === 2 && e.numbers[0] === 1 ? n() : this.options.prepend && s.toString() ? this.options.prepend + s.toString() : s.toString();
    }
    shouldUseIntlApi() {
      return !$e.includes(this.options.compatibilityJSON);
    }
  }
  const oe = function(r, e, t) {
    let s = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : ".", i = arguments.length > 4 && arguments[4] !== void 0 ? arguments[4] : true, n = be(r, e, t);
    return !n && i && p(t) && (n = Y(r, t, s), n === void 0 && (n = Y(e, t, s))), n;
  }, Q = (r) => r.replace(/\$/g, "$$$$");
  class je {
    constructor() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
      this.logger = R.create("interpolator"), this.options = e, this.format = e.interpolation && e.interpolation.format || ((t) => t), this.init(e);
    }
    init() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
      e.interpolation || (e.interpolation = {
        escapeValue: true
      });
      const { escape: t, escapeValue: s, useRawValueToEscape: i, prefix: n, prefixEscaped: a, suffix: o, suffixEscaped: l, formatSeparator: h, unescapeSuffix: g, unescapePrefix: f, nestingPrefix: u, nestingPrefixEscaped: c, nestingSuffix: d, nestingSuffixEscaped: v, nestingOptionsSeparator: m, maxReplaces: L, alwaysFormat: b } = e.interpolation;
      this.escape = t !== void 0 ? t : Se, this.escapeValue = s !== void 0 ? s : true, this.useRawValueToEscape = i !== void 0 ? i : false, this.prefix = n ? P(n) : a || "{{", this.suffix = o ? P(o) : l || "}}", this.formatSeparator = h || ",", this.unescapePrefix = g ? "" : f || "-", this.unescapeSuffix = this.unescapePrefix ? "" : g || "", this.nestingPrefix = u ? P(u) : c || P("$t("), this.nestingSuffix = d ? P(d) : v || P(")"), this.nestingOptionsSeparator = m || ",", this.maxReplaces = L || 1e3, this.alwaysFormat = b !== void 0 ? b : false, this.resetRegExp();
    }
    reset() {
      this.options && this.init(this.options);
    }
    resetRegExp() {
      const e = (t, s) => t && t.source === s ? (t.lastIndex = 0, t) : new RegExp(s, "g");
      this.regexp = e(this.regexp, `${this.prefix}(.+?)${this.suffix}`), this.regexpUnescape = e(this.regexpUnescape, `${this.prefix}${this.unescapePrefix}(.+?)${this.unescapeSuffix}${this.suffix}`), this.nestingRegexp = e(this.nestingRegexp, `${this.nestingPrefix}(.+?)${this.nestingSuffix}`);
    }
    interpolate(e, t, s, i) {
      let n, a, o;
      const l = this.options && this.options.interpolation && this.options.interpolation.defaultVariables || {}, h = (c) => {
        if (c.indexOf(this.formatSeparator) < 0) {
          const L = oe(t, l, c, this.options.keySeparator, this.options.ignoreJSONStructure);
          return this.alwaysFormat ? this.format(L, void 0, s, {
            ...i,
            ...t,
            interpolationkey: c
          }) : L;
        }
        const d = c.split(this.formatSeparator), v = d.shift().trim(), m = d.join(this.formatSeparator).trim();
        return this.format(oe(t, l, v, this.options.keySeparator, this.options.ignoreJSONStructure), m, s, {
          ...i,
          ...t,
          interpolationkey: v
        });
      };
      this.resetRegExp();
      const g = i && i.missingInterpolationHandler || this.options.missingInterpolationHandler, f = i && i.interpolation && i.interpolation.skipOnVariables !== void 0 ? i.interpolation.skipOnVariables : this.options.interpolation.skipOnVariables;
      return [
        {
          regex: this.regexpUnescape,
          safeValue: (c) => Q(c)
        },
        {
          regex: this.regexp,
          safeValue: (c) => this.escapeValue ? Q(this.escape(c)) : Q(c)
        }
      ].forEach((c) => {
        for (o = 0; n = c.regex.exec(e); ) {
          const d = n[1].trim();
          if (a = h(d), a === void 0) if (typeof g == "function") {
            const m = g(e, n, i);
            a = p(m) ? m : "";
          } else if (i && Object.prototype.hasOwnProperty.call(i, d)) a = "";
          else if (f) {
            a = n[0];
            continue;
          } else this.logger.warn(`missed to pass in variable ${d} for interpolating ${e}`), a = "";
          else !p(a) && !this.useRawValueToEscape && (a = _(a));
          const v = c.safeValue(a);
          if (e = e.replace(n[0], v), f ? (c.regex.lastIndex += a.length, c.regex.lastIndex -= n[0].length) : c.regex.lastIndex = 0, o++, o >= this.maxReplaces) break;
        }
      }), e;
    }
    nest(e, t) {
      let s = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {}, i, n, a;
      const o = (l, h) => {
        const g = this.nestingOptionsSeparator;
        if (l.indexOf(g) < 0) return l;
        const f = l.split(new RegExp(`${g}[ ]*{`));
        let u = `{${f[1]}`;
        l = f[0], u = this.interpolate(u, a);
        const c = u.match(/'/g), d = u.match(/"/g);
        (c && c.length % 2 === 0 && !d || d.length % 2 !== 0) && (u = u.replace(/'/g, '"'));
        try {
          a = JSON.parse(u), h && (a = {
            ...h,
            ...a
          });
        } catch (v) {
          return this.logger.warn(`failed parsing options string in nesting for key ${l}`, v), `${l}${g}${u}`;
        }
        return a.defaultValue && a.defaultValue.indexOf(this.prefix) > -1 && delete a.defaultValue, l;
      };
      for (; i = this.nestingRegexp.exec(e); ) {
        let l = [];
        a = {
          ...s
        }, a = a.replace && !p(a.replace) ? a.replace : a, a.applyPostProcessor = false, delete a.defaultValue;
        let h = false;
        if (i[0].indexOf(this.formatSeparator) !== -1 && !/{.*}/.test(i[1])) {
          const g = i[1].split(this.formatSeparator).map((f) => f.trim());
          i[1] = g.shift(), l = g, h = true;
        }
        if (n = t(o.call(this, i[1].trim(), a), a), n && i[0] === e && !p(n)) return n;
        p(n) || (n = _(n)), n || (this.logger.warn(`missed to resolve ${i[1]} for nesting ${e}`), n = ""), h && (n = l.reduce((g, f) => this.format(g, f, s.lng, {
          ...s,
          interpolationkey: i[1].trim()
        }), n.trim())), e = e.replace(i[0], n), this.regexp.lastIndex = 0;
      }
      return e;
    }
  }
  const Ie = (r) => {
    let e = r.toLowerCase().trim();
    const t = {};
    if (r.indexOf("(") > -1) {
      const s = r.split("(");
      e = s[0].toLowerCase().trim();
      const i = s[1].substring(0, s[1].length - 1);
      e === "currency" && i.indexOf(":") < 0 ? t.currency || (t.currency = i.trim()) : e === "relativetime" && i.indexOf(":") < 0 ? t.range || (t.range = i.trim()) : i.split(";").forEach((a) => {
        if (a) {
          const [o, ...l] = a.split(":"), h = l.join(":").trim().replace(/^'+|'+$/g, ""), g = o.trim();
          t[g] || (t[g] = h), h === "false" && (t[g] = false), h === "true" && (t[g] = true), isNaN(h) || (t[g] = parseInt(h, 10));
        }
      });
    }
    return {
      formatName: e,
      formatOptions: t
    };
  }, $ = (r) => {
    const e = {};
    return (t, s, i) => {
      let n = i;
      i && i.interpolationkey && i.formatParams && i.formatParams[i.interpolationkey] && i[i.interpolationkey] && (n = {
        ...n,
        [i.interpolationkey]: void 0
      });
      const a = s + JSON.stringify(n);
      let o = e[a];
      return o || (o = r(z(s), i), e[a] = o), o(t);
    };
  };
  class Ae {
    constructor() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {};
      this.logger = R.create("formatter"), this.options = e, this.formats = {
        number: $((t, s) => {
          const i = new Intl.NumberFormat(t, {
            ...s
          });
          return (n) => i.format(n);
        }),
        currency: $((t, s) => {
          const i = new Intl.NumberFormat(t, {
            ...s,
            style: "currency"
          });
          return (n) => i.format(n);
        }),
        datetime: $((t, s) => {
          const i = new Intl.DateTimeFormat(t, {
            ...s
          });
          return (n) => i.format(n);
        }),
        relativetime: $((t, s) => {
          const i = new Intl.RelativeTimeFormat(t, {
            ...s
          });
          return (n) => i.format(n, s.range || "day");
        }),
        list: $((t, s) => {
          const i = new Intl.ListFormat(t, {
            ...s
          });
          return (n) => i.format(n);
        })
      }, this.init(e);
    }
    init(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {
        interpolation: {}
      };
      this.formatSeparator = t.interpolation.formatSeparator || ",";
    }
    add(e, t) {
      this.formats[e.toLowerCase().trim()] = t;
    }
    addCached(e, t) {
      this.formats[e.toLowerCase().trim()] = $(t);
    }
    format(e, t, s) {
      let i = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : {};
      const n = t.split(this.formatSeparator);
      if (n.length > 1 && n[0].indexOf("(") > 1 && n[0].indexOf(")") < 0 && n.find((o) => o.indexOf(")") > -1)) {
        const o = n.findIndex((l) => l.indexOf(")") > -1);
        n[0] = [
          n[0],
          ...n.splice(1, o)
        ].join(this.formatSeparator);
      }
      return n.reduce((o, l) => {
        const { formatName: h, formatOptions: g } = Ie(l);
        if (this.formats[h]) {
          let f = o;
          try {
            const u = i && i.formatParams && i.formatParams[i.interpolationkey] || {}, c = u.locale || u.lng || i.locale || i.lng || s;
            f = this.formats[h](o, c, {
              ...g,
              ...i,
              ...u
            });
          } catch (u) {
            this.logger.warn(u);
          }
          return f;
        } else this.logger.warn(`there was no format function for ${h}`);
        return o;
      }, e);
    }
  }
  const De = (r, e) => {
    r.pending[e] !== void 0 && (delete r.pending[e], r.pendingCount--);
  };
  class Ve extends B {
    constructor(e, t, s) {
      let i = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : {};
      super(), this.backend = e, this.store = t, this.services = s, this.languageUtils = s.languageUtils, this.options = i, this.logger = R.create("backendConnector"), this.waitingReads = [], this.maxParallelReads = i.maxParallelReads || 10, this.readingCalls = 0, this.maxRetries = i.maxRetries >= 0 ? i.maxRetries : 5, this.retryTimeout = i.retryTimeout >= 1 ? i.retryTimeout : 350, this.state = {}, this.queue = [], this.backend && this.backend.init && this.backend.init(s, i.backend, i);
    }
    queueLoad(e, t, s, i) {
      const n = {}, a = {}, o = {}, l = {};
      return e.forEach((h) => {
        let g = true;
        t.forEach((f) => {
          const u = `${h}|${f}`;
          !s.reload && this.store.hasResourceBundle(h, f) ? this.state[u] = 2 : this.state[u] < 0 || (this.state[u] === 1 ? a[u] === void 0 && (a[u] = true) : (this.state[u] = 1, g = false, a[u] === void 0 && (a[u] = true), n[u] === void 0 && (n[u] = true), l[f] === void 0 && (l[f] = true)));
        }), g || (o[h] = true);
      }), (Object.keys(n).length || Object.keys(a).length) && this.queue.push({
        pending: a,
        pendingCount: Object.keys(a).length,
        loaded: {},
        errors: [],
        callback: i
      }), {
        toLoad: Object.keys(n),
        pending: Object.keys(a),
        toLoadLanguages: Object.keys(o),
        toLoadNamespaces: Object.keys(l)
      };
    }
    loaded(e, t, s) {
      const i = e.split("|"), n = i[0], a = i[1];
      t && this.emit("failedLoading", n, a, t), !t && s && this.store.addResourceBundle(n, a, s, void 0, void 0, {
        skipCopy: true
      }), this.state[e] = t ? -1 : 2, t && s && (this.state[e] = 0);
      const o = {};
      this.queue.forEach((l) => {
        xe(l.loaded, [
          n
        ], a), De(l, e), t && l.errors.push(t), l.pendingCount === 0 && !l.done && (Object.keys(l.loaded).forEach((h) => {
          o[h] || (o[h] = {});
          const g = l.loaded[h];
          g.length && g.forEach((f) => {
            o[h][f] === void 0 && (o[h][f] = true);
          });
        }), l.done = true, l.errors.length ? l.callback(l.errors) : l.callback());
      }), this.emit("loaded", o), this.queue = this.queue.filter((l) => !l.done);
    }
    read(e, t, s) {
      let i = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : 0, n = arguments.length > 4 && arguments[4] !== void 0 ? arguments[4] : this.retryTimeout, a = arguments.length > 5 ? arguments[5] : void 0;
      if (!e.length) return a(null, {});
      if (this.readingCalls >= this.maxParallelReads) {
        this.waitingReads.push({
          lng: e,
          ns: t,
          fcName: s,
          tried: i,
          wait: n,
          callback: a
        });
        return;
      }
      this.readingCalls++;
      const o = (h, g) => {
        if (this.readingCalls--, this.waitingReads.length > 0) {
          const f = this.waitingReads.shift();
          this.read(f.lng, f.ns, f.fcName, f.tried, f.wait, f.callback);
        }
        if (h && g && i < this.maxRetries) {
          setTimeout(() => {
            this.read.call(this, e, t, s, i + 1, n * 2, a);
          }, n);
          return;
        }
        a(h, g);
      }, l = this.backend[s].bind(this.backend);
      if (l.length === 2) {
        try {
          const h = l(e, t);
          h && typeof h.then == "function" ? h.then((g) => o(null, g)).catch(o) : o(null, h);
        } catch (h) {
          o(h);
        }
        return;
      }
      return l(e, t, o);
    }
    prepareLoading(e, t) {
      let s = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {}, i = arguments.length > 3 ? arguments[3] : void 0;
      if (!this.backend) return this.logger.warn("No backend was added via i18next.use. Will not load resources."), i && i();
      p(e) && (e = this.languageUtils.toResolveHierarchy(e)), p(t) && (t = [
        t
      ]);
      const n = this.queueLoad(e, t, s, i);
      if (!n.toLoad.length) return n.pending.length || i(), null;
      n.toLoad.forEach((a) => {
        this.loadOne(a);
      });
    }
    load(e, t, s) {
      this.prepareLoading(e, t, {}, s);
    }
    reload(e, t, s) {
      this.prepareLoading(e, t, {
        reload: true
      }, s);
    }
    loadOne(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : "";
      const s = e.split("|"), i = s[0], n = s[1];
      this.read(i, n, "read", void 0, void 0, (a, o) => {
        a && this.logger.warn(`${t}loading namespace ${n} for language ${i} failed`, a), !a && o && this.logger.log(`${t}loaded namespace ${n} for language ${i}`, o), this.loaded(e, a, o);
      });
    }
    saveMissing(e, t, s, i, n) {
      let a = arguments.length > 5 && arguments[5] !== void 0 ? arguments[5] : {}, o = arguments.length > 6 && arguments[6] !== void 0 ? arguments[6] : () => {
      };
      if (this.services.utils && this.services.utils.hasLoadedNamespace && !this.services.utils.hasLoadedNamespace(t)) {
        this.logger.warn(`did not save key "${s}" as the namespace "${t}" was not yet loaded`, "This means something IS WRONG in your setup. You access the t function before i18next.init / i18next.loadNamespace / i18next.changeLanguage was done. Wait for the callback or Promise to resolve before accessing it!!!");
        return;
      }
      if (!(s == null || s === "")) {
        if (this.backend && this.backend.create) {
          const l = {
            ...a,
            isUpdate: n
          }, h = this.backend.create.bind(this.backend);
          if (h.length < 6) try {
            let g;
            h.length === 5 ? g = h(e, t, s, i, l) : g = h(e, t, s, i), g && typeof g.then == "function" ? g.then((f) => o(null, f)).catch(o) : o(null, g);
          } catch (g) {
            o(g);
          }
          else h(e, t, s, i, o, l);
        }
        !e || !e[0] || this.store.addResource(e[0], t, s, i);
      }
    }
  }
  const le = () => ({
    debug: false,
    initImmediate: true,
    ns: [
      "translation"
    ],
    defaultNS: [
      "translation"
    ],
    fallbackLng: [
      "dev"
    ],
    fallbackNS: false,
    supportedLngs: false,
    nonExplicitSupportedLngs: false,
    load: "all",
    preload: false,
    simplifyPluralSuffix: true,
    keySeparator: ".",
    nsSeparator: ":",
    pluralSeparator: "_",
    contextSeparator: "_",
    partialBundledLanguages: false,
    saveMissing: false,
    updateMissing: false,
    saveMissingTo: "fallback",
    saveMissingPlurals: true,
    missingKeyHandler: false,
    missingInterpolationHandler: false,
    postProcess: false,
    postProcessPassResolved: false,
    returnNull: false,
    returnEmptyString: true,
    returnObjects: false,
    joinArrays: false,
    returnedObjectHandler: false,
    parseMissingKeyHandler: false,
    appendNamespaceToMissingKey: false,
    appendNamespaceToCIMode: false,
    overloadTranslationOptionHandler: (r) => {
      let e = {};
      if (typeof r[1] == "object" && (e = r[1]), p(r[1]) && (e.defaultValue = r[1]), p(r[2]) && (e.tDescription = r[2]), typeof r[2] == "object" || typeof r[3] == "object") {
        const t = r[3] || r[2];
        Object.keys(t).forEach((s) => {
          e[s] = t[s];
        });
      }
      return e;
    },
    interpolation: {
      escapeValue: true,
      format: (r) => r,
      prefix: "{{",
      suffix: "}}",
      formatSeparator: ",",
      unescapePrefix: "-",
      nestingPrefix: "$t(",
      nestingSuffix: ")",
      nestingOptionsSeparator: ",",
      maxReplaces: 1e3,
      skipOnVariables: true
    }
  }), ue = (r) => (p(r.ns) && (r.ns = [
    r.ns
  ]), p(r.fallbackLng) && (r.fallbackLng = [
    r.fallbackLng
  ]), p(r.fallbackNS) && (r.fallbackNS = [
    r.fallbackNS
  ]), r.supportedLngs && r.supportedLngs.indexOf("cimode") < 0 && (r.supportedLngs = r.supportedLngs.concat([
    "cimode"
  ])), r), U = () => {
  }, Te = (r) => {
    Object.getOwnPropertyNames(Object.getPrototypeOf(r)).forEach((t) => {
      typeof r[t] == "function" && (r[t] = r[t].bind(r));
    });
  };
  class V extends B {
    constructor() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {}, t = arguments.length > 1 ? arguments[1] : void 0;
      if (super(), this.options = ue(e), this.services = {}, this.logger = R, this.modules = {
        external: []
      }, Te(this), t && !this.isInitialized && !e.isClone) {
        if (!this.options.initImmediate) return this.init(e, t), this;
        setTimeout(() => {
          this.init(e, t);
        }, 0);
      }
    }
    init() {
      var e = this;
      let t = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {}, s = arguments.length > 1 ? arguments[1] : void 0;
      this.isInitializing = true, typeof t == "function" && (s = t, t = {}), !t.defaultNS && t.defaultNS !== false && t.ns && (p(t.ns) ? t.defaultNS = t.ns : t.ns.indexOf("translation") < 0 && (t.defaultNS = t.ns[0]));
      const i = le();
      this.options = {
        ...i,
        ...this.options,
        ...ue(t)
      }, this.options.compatibilityAPI !== "v1" && (this.options.interpolation = {
        ...i.interpolation,
        ...this.options.interpolation
      }), t.keySeparator !== void 0 && (this.options.userDefinedKeySeparator = t.keySeparator), t.nsSeparator !== void 0 && (this.options.userDefinedNsSeparator = t.nsSeparator);
      const n = (g) => g ? typeof g == "function" ? new g() : g : null;
      if (!this.options.isClone) {
        this.modules.logger ? R.init(n(this.modules.logger), this.options) : R.init(null, this.options);
        let g;
        this.modules.formatter ? g = this.modules.formatter : typeof Intl < "u" && (g = Ae);
        const f = new ne(this.options);
        this.store = new ie(this.options.resources, this.options);
        const u = this.services;
        u.logger = R, u.resourceStore = this.store, u.languageUtils = f, u.pluralResolver = new Fe(f, {
          prepend: this.options.pluralSeparator,
          compatibilityJSON: this.options.compatibilityJSON,
          simplifyPluralSuffix: this.options.simplifyPluralSuffix
        }), g && (!this.options.interpolation.format || this.options.interpolation.format === i.interpolation.format) && (u.formatter = n(g), u.formatter.init(u, this.options), this.options.interpolation.format = u.formatter.format.bind(u.formatter)), u.interpolator = new je(this.options), u.utils = {
          hasLoadedNamespace: this.hasLoadedNamespace.bind(this)
        }, u.backendConnector = new Ve(n(this.modules.backend), u.resourceStore, u, this.options), u.backendConnector.on("*", function(c) {
          for (var d = arguments.length, v = new Array(d > 1 ? d - 1 : 0), m = 1; m < d; m++) v[m - 1] = arguments[m];
          e.emit(c, ...v);
        }), this.modules.languageDetector && (u.languageDetector = n(this.modules.languageDetector), u.languageDetector.init && u.languageDetector.init(u, this.options.detection, this.options)), this.modules.i18nFormat && (u.i18nFormat = n(this.modules.i18nFormat), u.i18nFormat.init && u.i18nFormat.init(this)), this.translator = new J(this.services, this.options), this.translator.on("*", function(c) {
          for (var d = arguments.length, v = new Array(d > 1 ? d - 1 : 0), m = 1; m < d; m++) v[m - 1] = arguments[m];
          e.emit(c, ...v);
        }), this.modules.external.forEach((c) => {
          c.init && c.init(this);
        });
      }
      if (this.format = this.options.interpolation.format, s || (s = U), this.options.fallbackLng && !this.services.languageDetector && !this.options.lng) {
        const g = this.services.languageUtils.getFallbackCodes(this.options.fallbackLng);
        g.length > 0 && g[0] !== "dev" && (this.options.lng = g[0]);
      }
      !this.services.languageDetector && !this.options.lng && this.logger.warn("init: no languageDetector is used and no lng is defined"), [
        "getResource",
        "hasResourceBundle",
        "getResourceBundle",
        "getDataByLanguage"
      ].forEach((g) => {
        this[g] = function() {
          return e.store[g](...arguments);
        };
      }), [
        "addResource",
        "addResources",
        "addResourceBundle",
        "removeResourceBundle"
      ].forEach((g) => {
        this[g] = function() {
          return e.store[g](...arguments), e;
        };
      });
      const l = A(), h = () => {
        const g = (f, u) => {
          this.isInitializing = false, this.isInitialized && !this.initializedStoreOnce && this.logger.warn("init: i18next is already initialized. You should call init just once!"), this.isInitialized = true, this.options.isClone || this.logger.log("initialized", this.options), this.emit("initialized", this.options), l.resolve(u), s(f, u);
        };
        if (this.languages && this.options.compatibilityAPI !== "v1" && !this.isInitialized) return g(null, this.t.bind(this));
        this.changeLanguage(this.options.lng, g);
      };
      return this.options.resources || !this.options.initImmediate ? h() : setTimeout(h, 0), l;
    }
    loadResources(e) {
      let s = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : U;
      const i = p(e) ? e : this.language;
      if (typeof e == "function" && (s = e), !this.options.resources || this.options.partialBundledLanguages) {
        if (i && i.toLowerCase() === "cimode" && (!this.options.preload || this.options.preload.length === 0)) return s();
        const n = [], a = (o) => {
          if (!o || o === "cimode") return;
          this.services.languageUtils.toResolveHierarchy(o).forEach((h) => {
            h !== "cimode" && n.indexOf(h) < 0 && n.push(h);
          });
        };
        i ? a(i) : this.services.languageUtils.getFallbackCodes(this.options.fallbackLng).forEach((l) => a(l)), this.options.preload && this.options.preload.forEach((o) => a(o)), this.services.backendConnector.load(n, this.options.ns, (o) => {
          !o && !this.resolvedLanguage && this.language && this.setResolvedLanguage(this.language), s(o);
        });
      } else s(null);
    }
    reloadResources(e, t, s) {
      const i = A();
      return typeof e == "function" && (s = e, e = void 0), typeof t == "function" && (s = t, t = void 0), e || (e = this.languages), t || (t = this.options.ns), s || (s = U), this.services.backendConnector.reload(e, t, (n) => {
        i.resolve(), s(n);
      }), i;
    }
    use(e) {
      if (!e) throw new Error("You are passing an undefined module! Please check the object you are passing to i18next.use()");
      if (!e.type) throw new Error("You are passing a wrong module! Please check the object you are passing to i18next.use()");
      return e.type === "backend" && (this.modules.backend = e), (e.type === "logger" || e.log && e.warn && e.error) && (this.modules.logger = e), e.type === "languageDetector" && (this.modules.languageDetector = e), e.type === "i18nFormat" && (this.modules.i18nFormat = e), e.type === "postProcessor" && fe.addPostProcessor(e), e.type === "formatter" && (this.modules.formatter = e), e.type === "3rdParty" && this.modules.external.push(e), this;
    }
    setResolvedLanguage(e) {
      if (!(!e || !this.languages) && !([
        "cimode",
        "dev"
      ].indexOf(e) > -1)) for (let t = 0; t < this.languages.length; t++) {
        const s = this.languages[t];
        if (!([
          "cimode",
          "dev"
        ].indexOf(s) > -1) && this.store.hasLanguageSomeTranslations(s)) {
          this.resolvedLanguage = s;
          break;
        }
      }
    }
    changeLanguage(e, t) {
      var s = this;
      this.isLanguageChangingTo = e;
      const i = A();
      this.emit("languageChanging", e);
      const n = (l) => {
        this.language = l, this.languages = this.services.languageUtils.toResolveHierarchy(l), this.resolvedLanguage = void 0, this.setResolvedLanguage(l);
      }, a = (l, h) => {
        h ? (n(h), this.translator.changeLanguage(h), this.isLanguageChangingTo = void 0, this.emit("languageChanged", h), this.logger.log("languageChanged", h)) : this.isLanguageChangingTo = void 0, i.resolve(function() {
          return s.t(...arguments);
        }), t && t(l, function() {
          return s.t(...arguments);
        });
      }, o = (l) => {
        !e && !l && this.services.languageDetector && (l = []);
        const h = p(l) ? l : this.services.languageUtils.getBestMatchFromCodes(l);
        h && (this.language || n(h), this.translator.language || this.translator.changeLanguage(h), this.services.languageDetector && this.services.languageDetector.cacheUserLanguage && this.services.languageDetector.cacheUserLanguage(h)), this.loadResources(h, (g) => {
          a(g, h);
        });
      };
      return !e && this.services.languageDetector && !this.services.languageDetector.async ? o(this.services.languageDetector.detect()) : !e && this.services.languageDetector && this.services.languageDetector.async ? this.services.languageDetector.detect.length === 0 ? this.services.languageDetector.detect().then(o) : this.services.languageDetector.detect(o) : o(e), i;
    }
    getFixedT(e, t, s) {
      var i = this;
      const n = function(a, o) {
        let l;
        if (typeof o != "object") {
          for (var h = arguments.length, g = new Array(h > 2 ? h - 2 : 0), f = 2; f < h; f++) g[f - 2] = arguments[f];
          l = i.options.overloadTranslationOptionHandler([
            a,
            o
          ].concat(g));
        } else l = {
          ...o
        };
        l.lng = l.lng || n.lng, l.lngs = l.lngs || n.lngs, l.ns = l.ns || n.ns, l.keyPrefix !== "" && (l.keyPrefix = l.keyPrefix || s || n.keyPrefix);
        const u = i.options.keySeparator || ".";
        let c;
        return l.keyPrefix && Array.isArray(a) ? c = a.map((d) => `${l.keyPrefix}${u}${d}`) : c = l.keyPrefix ? `${l.keyPrefix}${u}${a}` : a, i.t(c, l);
      };
      return p(e) ? n.lng = e : n.lngs = e, n.ns = t, n.keyPrefix = s, n;
    }
    t() {
      return this.translator && this.translator.translate(...arguments);
    }
    exists() {
      return this.translator && this.translator.exists(...arguments);
    }
    setDefaultNamespace(e) {
      this.options.defaultNS = e;
    }
    hasLoadedNamespace(e) {
      let t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : {};
      if (!this.isInitialized) return this.logger.warn("hasLoadedNamespace: i18next was not initialized", this.languages), false;
      if (!this.languages || !this.languages.length) return this.logger.warn("hasLoadedNamespace: i18n.languages were undefined or empty", this.languages), false;
      const s = t.lng || this.resolvedLanguage || this.languages[0], i = this.options ? this.options.fallbackLng : false, n = this.languages[this.languages.length - 1];
      if (s.toLowerCase() === "cimode") return true;
      const a = (o, l) => {
        const h = this.services.backendConnector.state[`${o}|${l}`];
        return h === -1 || h === 0 || h === 2;
      };
      if (t.precheck) {
        const o = t.precheck(this, a);
        if (o !== void 0) return o;
      }
      return !!(this.hasResourceBundle(s, e) || !this.services.backendConnector.backend || this.options.resources && !this.options.partialBundledLanguages || a(s, e) && (!i || a(n, e)));
    }
    loadNamespaces(e, t) {
      const s = A();
      return this.options.ns ? (p(e) && (e = [
        e
      ]), e.forEach((i) => {
        this.options.ns.indexOf(i) < 0 && this.options.ns.push(i);
      }), this.loadResources((i) => {
        s.resolve(), t && t(i);
      }), s) : (t && t(), Promise.resolve());
    }
    loadLanguages(e, t) {
      const s = A();
      p(e) && (e = [
        e
      ]);
      const i = this.options.preload || [], n = e.filter((a) => i.indexOf(a) < 0 && this.services.languageUtils.isSupportedCode(a));
      return n.length ? (this.options.preload = i.concat(n), this.loadResources((a) => {
        s.resolve(), t && t(a);
      }), s) : (t && t(), Promise.resolve());
    }
    dir(e) {
      if (e || (e = this.resolvedLanguage || (this.languages && this.languages.length > 0 ? this.languages[0] : this.language)), !e) return "rtl";
      const t = [
        "ar",
        "shu",
        "sqr",
        "ssh",
        "xaa",
        "yhd",
        "yud",
        "aao",
        "abh",
        "abv",
        "acm",
        "acq",
        "acw",
        "acx",
        "acy",
        "adf",
        "ads",
        "aeb",
        "aec",
        "afb",
        "ajp",
        "apc",
        "apd",
        "arb",
        "arq",
        "ars",
        "ary",
        "arz",
        "auz",
        "avl",
        "ayh",
        "ayl",
        "ayn",
        "ayp",
        "bbz",
        "pga",
        "he",
        "iw",
        "ps",
        "pbt",
        "pbu",
        "pst",
        "prp",
        "prd",
        "ug",
        "ur",
        "ydd",
        "yds",
        "yih",
        "ji",
        "yi",
        "hbo",
        "men",
        "xmn",
        "fa",
        "jpr",
        "peo",
        "pes",
        "prs",
        "dv",
        "sam",
        "ckb"
      ], s = this.services && this.services.languageUtils || new ne(le());
      return t.indexOf(s.getLanguagePartFromCode(e)) > -1 || e.toLowerCase().indexOf("-arab") > 1 ? "rtl" : "ltr";
    }
    static createInstance() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {}, t = arguments.length > 1 ? arguments[1] : void 0;
      return new V(e, t);
    }
    cloneInstance() {
      let e = arguments.length > 0 && arguments[0] !== void 0 ? arguments[0] : {}, t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : U;
      const s = e.forkResourceStore;
      s && delete e.forkResourceStore;
      const i = {
        ...this.options,
        ...e,
        isClone: true
      }, n = new V(i);
      return (e.debug !== void 0 || e.prefix !== void 0) && (n.logger = n.logger.clone(e)), [
        "store",
        "services",
        "language"
      ].forEach((o) => {
        n[o] = this[o];
      }), n.services = {
        ...this.services
      }, n.services.utils = {
        hasLoadedNamespace: n.hasLoadedNamespace.bind(n)
      }, s && (n.store = new ie(this.store.data, i), n.services.resourceStore = n.store), n.translator = new J(n.services, i), n.translator.on("*", function(o) {
        for (var l = arguments.length, h = new Array(l > 1 ? l - 1 : 0), g = 1; g < l; g++) h[g - 1] = arguments[g];
        n.emit(o, ...h);
      }), n.init(i, t), n.translator.options = i, n.translator.backendConnector.services.utils = {
        hasLoadedNamespace: n.hasLoadedNamespace.bind(n)
      }, n;
    }
    toJSON() {
      return {
        options: this.options,
        store: this.store,
        language: this.language,
        languages: this.languages,
        resolvedLanguage: this.resolvedLanguage
      };
    }
  }
  const S = V.createInstance();
  S.createInstance = V.createInstance;
  S.createInstance;
  S.dir;
  S.init;
  S.loadResources;
  S.reloadResources;
  S.use;
  S.changeLanguage;
  S.getFixedT;
  S.t;
  S.exists;
  S.setDefaultNamespace;
  S.hasLoadedNamespace;
  S.loadNamespaces;
  S.loadLanguages;
  const Ke = await he("react-dom"), { BrowserRouter: Je } = await he("react-router-dom");
  G.div`
  position: relative;
  width: 500px;
  height: 1000px;
`;
  G.div`
  background: url(${({ src: r }) => r});
  position: absolute;
  z-index: 100;
  width: 500px;
  height: 1000px;
  pointer-events: none;
`;
  G.div`
  z-index: 2;
  position: absolute;
  bottom: 100px;
  left: 50px;
  right: 50px;
  top: 100px;
  display: flex;
  flex-direction: column;
  background-position: center;
  background-size: cover;
  background-repeat: no-repeat;
  border-radius: 20px;
`;
  const Ue = () => null;
  Ke.render(de.jsx(Ue, {}), document.getElementById("root"));
});
