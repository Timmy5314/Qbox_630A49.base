import { importShared as rt, __tla as __tla_0 } from "./__federation_fn_import-TgB_5sXQ.js";
import { _ as X, a as ae } from "./inheritsLoose-G6YR9G09.js";
import { g as ot } from "./_commonjsHelpers-C932wzq6.js";
import { _ as H, h as Et } from "./hoist-non-react-statics.cjs-3wE6KoJ0.js";
let Nn, Bn, Pn, Tn, Dn, An, Ln, $n, Pe, On, Mn, Qe, Ee, Hn, gn, In, _n, Un;
let __tla = Promise.all([
  (() => {
    try {
      return __tla_0;
    } catch {
    }
  })()
]).then(async () => {
  var it = {
    exports: {}
  }, Ct = "SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED", bt = Ct, Rt = bt;
  function at() {
  }
  function st() {
  }
  st.resetWarningCache = at;
  var St = function() {
    function e(o, r, i, c, s, f) {
      if (f !== Rt) {
        var a = new Error("Calling PropTypes validators directly is not supported by the `prop-types` package. Use PropTypes.checkPropTypes() to call them. Read more at http://fb.me/use-check-prop-types");
        throw a.name = "Invariant Violation", a;
      }
    }
    e.isRequired = e;
    function t() {
      return e;
    }
    var n = {
      array: e,
      bigint: e,
      bool: e,
      func: e,
      number: e,
      object: e,
      string: e,
      symbol: e,
      any: e,
      arrayOf: t,
      element: e,
      elementType: e,
      instanceOf: t,
      node: e,
      objectOf: t,
      oneOf: t,
      oneOfType: t,
      shape: t,
      exact: t,
      checkPropTypes: st,
      resetWarningCache: at
    };
    return n.PropTypes = n, n;
  };
  it.exports = St();
  var Tt = it.exports;
  const Fe = ot(Tt);
  function se(e) {
    return e.charAt(0) === "/";
  }
  function Re(e, t) {
    for (var n = t, o = n + 1, r = e.length; o < r; n += 1, o += 1) e[n] = e[o];
    e.pop();
  }
  function At(e, t) {
    t === void 0 && (t = "");
    var n = e && e.split("/") || [], o = t && t.split("/") || [], r = e && se(e), i = t && se(t), c = r || i;
    if (e && se(e) ? o = n : n.length && (o.pop(), o = o.concat(n)), !o.length) return "/";
    var s;
    if (o.length) {
      var f = o[o.length - 1];
      s = f === "." || f === ".." || f === "";
    } else s = false;
    for (var a = 0, u = o.length; u >= 0; u--) {
      var l = o[u];
      l === "." ? Re(o, u) : l === ".." ? (Re(o, u), a++) : a && (Re(o, u), a--);
    }
    if (!c) for (; a--; a) o.unshift("..");
    c && o[0] !== "" && (!o[0] || !se(o[0])) && o.unshift("");
    var h = o.join("/");
    return s && h.substr(-1) !== "/" && (h += "/"), h;
  }
  function qe(e) {
    return e.valueOf ? e.valueOf() : Object.prototype.valueOf.call(e);
  }
  function ce(e, t) {
    if (e === t) return true;
    if (e == null || t == null) return false;
    if (Array.isArray(e)) return Array.isArray(t) && e.length === t.length && e.every(function(r, i) {
      return ce(r, t[i]);
    });
    if (typeof e == "object" || typeof t == "object") {
      var n = qe(e), o = qe(t);
      return n !== e || o !== t ? ce(n, o) : Object.keys(Object.assign({}, e, t)).every(function(r) {
        return ce(e[r], t[r]);
      });
    }
    return false;
  }
  var Lt = "Invariant failed";
  function k(e, t) {
    throw new Error(Lt);
  }
  function ie(e) {
    return e.charAt(0) === "/" ? e : "/" + e;
  }
  function Ke(e) {
    return e.charAt(0) === "/" ? e.substr(1) : e;
  }
  function $t(e, t) {
    return e.toLowerCase().indexOf(t.toLowerCase()) === 0 && "/?#".indexOf(e.charAt(t.length)) !== -1;
  }
  function ct(e, t) {
    return $t(e, t) ? e.substr(t.length) : e;
  }
  function ut(e) {
    return e.charAt(e.length - 1) === "/" ? e.slice(0, -1) : e;
  }
  function Ot(e) {
    var t = e || "/", n = "", o = "", r = t.indexOf("#");
    r !== -1 && (o = t.substr(r), t = t.substr(0, r));
    var i = t.indexOf("?");
    return i !== -1 && (n = t.substr(i), t = t.substr(0, i)), {
      pathname: t,
      search: n === "?" ? "" : n,
      hash: o === "#" ? "" : o
    };
  }
  function W(e) {
    var t = e.pathname, n = e.search, o = e.hash, r = t || "/";
    return n && n !== "?" && (r += n.charAt(0) === "?" ? n : "?" + n), o && o !== "#" && (r += o.charAt(0) === "#" ? o : "#" + o), r;
  }
  function N(e, t, n, o) {
    var r;
    typeof e == "string" ? (r = Ot(e), r.state = t) : (r = H({}, e), r.pathname === void 0 && (r.pathname = ""), r.search ? r.search.charAt(0) !== "?" && (r.search = "?" + r.search) : r.search = "", r.hash ? r.hash.charAt(0) !== "#" && (r.hash = "#" + r.hash) : r.hash = "", t !== void 0 && r.state === void 0 && (r.state = t));
    try {
      r.pathname = decodeURI(r.pathname);
    } catch (i) {
      throw i instanceof URIError ? new URIError('Pathname "' + r.pathname + '" could not be decoded. This is likely caused by an invalid percent-encoding.') : i;
    }
    return n && (r.key = n), o ? r.pathname ? r.pathname.charAt(0) !== "/" && (r.pathname = At(r.pathname, o.pathname)) : r.pathname = o.pathname : r.pathname || (r.pathname = "/"), r;
  }
  function Mt(e, t) {
    return e.pathname === t.pathname && e.search === t.search && e.hash === t.hash && e.key === t.key && ce(e.state, t.state);
  }
  function Me() {
    var e = null;
    function t(c) {
      return e = c, function() {
        e === c && (e = null);
      };
    }
    function n(c, s, f, a) {
      if (e != null) {
        var u = typeof e == "function" ? e(c, s) : e;
        typeof u == "string" ? typeof f == "function" ? f(u, a) : a(true) : a(u !== false);
      } else a(true);
    }
    var o = [];
    function r(c) {
      var s = true;
      function f() {
        s && c.apply(void 0, arguments);
      }
      return o.push(f), function() {
        s = false, o = o.filter(function(a) {
          return a !== f;
        });
      };
    }
    function i() {
      for (var c = arguments.length, s = new Array(c), f = 0; f < c; f++) s[f] = arguments[f];
      o.forEach(function(a) {
        return a.apply(void 0, s);
      });
    }
    return {
      setPrompt: t,
      confirmTransitionTo: n,
      appendListener: r,
      notifyListeners: i
    };
  }
  var ft = !!(typeof window < "u" && window.document && window.document.createElement);
  function lt(e, t) {
    t(window.confirm(e));
  }
  function Ut() {
    var e = window.navigator.userAgent;
    return (e.indexOf("Android 2.") !== -1 || e.indexOf("Android 4.0") !== -1) && e.indexOf("Mobile Safari") !== -1 && e.indexOf("Chrome") === -1 && e.indexOf("Windows Phone") === -1 ? false : window.history && "pushState" in window.history;
  }
  function Ht() {
    return window.navigator.userAgent.indexOf("Trident") === -1;
  }
  function It() {
    return window.navigator.userAgent.indexOf("Firefox") === -1;
  }
  function _t(e) {
    return e.state === void 0 && navigator.userAgent.indexOf("CriOS") === -1;
  }
  var ze = "popstate", Ge = "hashchange";
  function Ve() {
    try {
      return window.history.state || {};
    } catch {
      return {};
    }
  }
  function Nt(e) {
    e === void 0 && (e = {}), ft || k();
    var t = window.history, n = Ut(), o = !Ht(), r = e, i = r.forceRefresh, c = i === void 0 ? false : i, s = r.getUserConfirmation, f = s === void 0 ? lt : s, a = r.keyLength, u = a === void 0 ? 6 : a, l = e.basename ? ut(ie(e.basename)) : "";
    function h(d) {
      var p = d || {}, w = p.key, m = p.state, C = window.location, U = C.pathname, F = C.search, V = C.hash, z = U + F + V;
      return l && (z = ct(z, l)), N(z, m, w);
    }
    function v() {
      return Math.random().toString(36).substr(2, u);
    }
    var y = Me();
    function b(d) {
      H(K, d), K.length = t.length, y.notifyListeners(K.location, K.action);
    }
    function R(d) {
      _t(d) || B(h(d.state));
    }
    function T() {
      B(h(Ve()));
    }
    var M = false;
    function B(d) {
      if (M) M = false, b();
      else {
        var p = "POP";
        y.confirmTransitionTo(d, p, f, function(w) {
          w ? b({
            action: p,
            location: d
          }) : D(d);
        });
      }
    }
    function D(d) {
      var p = K.location, w = S.indexOf(p.key);
      w === -1 && (w = 0);
      var m = S.indexOf(d.key);
      m === -1 && (m = 0);
      var C = w - m;
      C && (M = true, A(C));
    }
    var I = h(Ve()), S = [
      I.key
    ];
    function g(d) {
      return l + W(d);
    }
    function x(d, p) {
      var w = "PUSH", m = N(d, p, v(), K.location);
      y.confirmTransitionTo(m, w, f, function(C) {
        if (C) {
          var U = g(m), F = m.key, V = m.state;
          if (n) if (t.pushState({
            key: F,
            state: V
          }, null, U), c) window.location.href = U;
          else {
            var z = S.indexOf(K.location.key), Z = S.slice(0, z + 1);
            Z.push(m.key), S = Z, b({
              action: w,
              location: m
            });
          }
          else window.location.href = U;
        }
      });
    }
    function O(d, p) {
      var w = "REPLACE", m = N(d, p, v(), K.location);
      y.confirmTransitionTo(m, w, f, function(C) {
        if (C) {
          var U = g(m), F = m.key, V = m.state;
          if (n) if (t.replaceState({
            key: F,
            state: V
          }, null, U), c) window.location.replace(U);
          else {
            var z = S.indexOf(K.location.key);
            z !== -1 && (S[z] = m.key), b({
              action: w,
              location: m
            });
          }
          else window.location.replace(U);
        }
      });
    }
    function A(d) {
      t.go(d);
    }
    function L() {
      A(-1);
    }
    function Y() {
      A(1);
    }
    var Q = 0;
    function j(d) {
      Q += d, Q === 1 && d === 1 ? (window.addEventListener(ze, R), o && window.addEventListener(Ge, T)) : Q === 0 && (window.removeEventListener(ze, R), o && window.removeEventListener(Ge, T));
    }
    var _ = false;
    function te(d) {
      d === void 0 && (d = false);
      var p = y.setPrompt(d);
      return _ || (j(1), _ = true), function() {
        return _ && (_ = false, j(-1)), p();
      };
    }
    function be(d) {
      var p = y.appendListener(d);
      return j(1), function() {
        j(-1), p();
      };
    }
    var K = {
      length: t.length,
      action: "POP",
      location: I,
      createHref: g,
      push: x,
      replace: O,
      go: A,
      goBack: L,
      goForward: Y,
      block: te,
      listen: be
    };
    return K;
  }
  var Je = "hashchange", Bt = {
    hashbang: {
      encodePath: function(t) {
        return t.charAt(0) === "!" ? t : "!/" + Ke(t);
      },
      decodePath: function(t) {
        return t.charAt(0) === "!" ? t.substr(1) : t;
      }
    },
    noslash: {
      encodePath: Ke,
      decodePath: ie
    },
    slash: {
      encodePath: ie,
      decodePath: ie
    }
  };
  function ht(e) {
    var t = e.indexOf("#");
    return t === -1 ? e : e.slice(0, t);
  }
  function oe() {
    var e = window.location.href, t = e.indexOf("#");
    return t === -1 ? "" : e.substring(t + 1);
  }
  function Dt(e) {
    window.location.hash = e;
  }
  function Se(e) {
    window.location.replace(ht(window.location.href) + "#" + e);
  }
  function Wt(e) {
    e === void 0 && (e = {}), ft || k();
    var t = window.history;
    It();
    var n = e, o = n.getUserConfirmation, r = o === void 0 ? lt : o, i = n.hashType, c = i === void 0 ? "slash" : i, s = e.basename ? ut(ie(e.basename)) : "", f = Bt[c], a = f.encodePath, u = f.decodePath;
    function l() {
      var p = u(oe());
      return s && (p = ct(p, s)), N(p);
    }
    var h = Me();
    function v(p) {
      H(d, p), d.length = t.length, h.notifyListeners(d.location, d.action);
    }
    var y = false, b = null;
    function R(p, w) {
      return p.pathname === w.pathname && p.search === w.search && p.hash === w.hash;
    }
    function T() {
      var p = oe(), w = a(p);
      if (p !== w) Se(w);
      else {
        var m = l(), C = d.location;
        if (!y && R(C, m) || b === W(m)) return;
        b = null, M(m);
      }
    }
    function M(p) {
      if (y) y = false, v();
      else {
        var w = "POP";
        h.confirmTransitionTo(p, w, r, function(m) {
          m ? v({
            action: w,
            location: p
          }) : B(p);
        });
      }
    }
    function B(p) {
      var w = d.location, m = g.lastIndexOf(W(w));
      m === -1 && (m = 0);
      var C = g.lastIndexOf(W(p));
      C === -1 && (C = 0);
      var U = m - C;
      U && (y = true, L(U));
    }
    var D = oe(), I = a(D);
    D !== I && Se(I);
    var S = l(), g = [
      W(S)
    ];
    function x(p) {
      var w = document.querySelector("base"), m = "";
      return w && w.getAttribute("href") && (m = ht(window.location.href)), m + "#" + a(s + W(p));
    }
    function O(p, w) {
      var m = "PUSH", C = N(p, void 0, void 0, d.location);
      h.confirmTransitionTo(C, m, r, function(U) {
        if (U) {
          var F = W(C), V = a(s + F), z = oe() !== V;
          if (z) {
            b = F, Dt(V);
            var Z = g.lastIndexOf(W(d.location)), je = g.slice(0, Z + 1);
            je.push(F), g = je, v({
              action: m,
              location: C
            });
          } else v();
        }
      });
    }
    function A(p, w) {
      var m = "REPLACE", C = N(p, void 0, void 0, d.location);
      h.confirmTransitionTo(C, m, r, function(U) {
        if (U) {
          var F = W(C), V = a(s + F), z = oe() !== V;
          z && (b = F, Se(V));
          var Z = g.indexOf(W(d.location));
          Z !== -1 && (g[Z] = F), v({
            action: m,
            location: C
          });
        }
      });
    }
    function L(p) {
      t.go(p);
    }
    function Y() {
      L(-1);
    }
    function Q() {
      L(1);
    }
    var j = 0;
    function _(p) {
      j += p, j === 1 && p === 1 ? window.addEventListener(Je, T) : j === 0 && window.removeEventListener(Je, T);
    }
    var te = false;
    function be(p) {
      p === void 0 && (p = false);
      var w = h.setPrompt(p);
      return te || (_(1), te = true), function() {
        return te && (te = false, _(-1)), w();
      };
    }
    function K(p) {
      var w = h.appendListener(p);
      return _(1), function() {
        _(-1), w();
      };
    }
    var d = {
      length: t.length,
      action: "POP",
      location: S,
      createHref: x,
      push: O,
      replace: A,
      go: L,
      goBack: Y,
      goForward: Q,
      block: be,
      listen: K
    };
    return d;
  }
  function Xe(e, t, n) {
    return Math.min(Math.max(e, t), n);
  }
  function jt(e) {
    e === void 0 && (e = {});
    var t = e, n = t.getUserConfirmation, o = t.initialEntries, r = o === void 0 ? [
      "/"
    ] : o, i = t.initialIndex, c = i === void 0 ? 0 : i, s = t.keyLength, f = s === void 0 ? 6 : s, a = Me();
    function u(x) {
      H(g, x), g.length = g.entries.length, a.notifyListeners(g.location, g.action);
    }
    function l() {
      return Math.random().toString(36).substr(2, f);
    }
    var h = Xe(c, 0, r.length - 1), v = r.map(function(x) {
      return typeof x == "string" ? N(x, void 0, l()) : N(x, void 0, x.key || l());
    }), y = W;
    function b(x, O) {
      var A = "PUSH", L = N(x, O, l(), g.location);
      a.confirmTransitionTo(L, A, n, function(Y) {
        if (Y) {
          var Q = g.index, j = Q + 1, _ = g.entries.slice(0);
          _.length > j ? _.splice(j, _.length - j, L) : _.push(L), u({
            action: A,
            location: L,
            index: j,
            entries: _
          });
        }
      });
    }
    function R(x, O) {
      var A = "REPLACE", L = N(x, O, l(), g.location);
      a.confirmTransitionTo(L, A, n, function(Y) {
        Y && (g.entries[g.index] = L, u({
          action: A,
          location: L
        }));
      });
    }
    function T(x) {
      var O = Xe(g.index + x, 0, g.entries.length - 1), A = "POP", L = g.entries[O];
      a.confirmTransitionTo(L, A, n, function(Y) {
        Y ? u({
          action: A,
          location: L,
          index: O
        }) : u();
      });
    }
    function M() {
      T(-1);
    }
    function B() {
      T(1);
    }
    function D(x) {
      var O = g.index + x;
      return O >= 0 && O < g.entries.length;
    }
    function I(x) {
      return x === void 0 && (x = false), a.setPrompt(x);
    }
    function S(x) {
      return a.appendListener(x);
    }
    var g = {
      length: v.length,
      action: "POP",
      location: v[h],
      index: h,
      entries: v,
      createHref: y,
      push: b,
      replace: R,
      go: T,
      goBack: M,
      goForward: B,
      canGo: D,
      block: I,
      listen: S
    };
    return g;
  }
  var re = {
    exports: {}
  }, Ft = Array.isArray || function(e) {
    return Object.prototype.toString.call(e) == "[object Array]";
  }, ue = Ft;
  re.exports = dt;
  re.exports.parse = Ue;
  re.exports.compile = zt;
  re.exports.tokensToFunction = pt;
  re.exports.tokensToRegExp = vt;
  var qt = new RegExp([
    "(\\\\.)",
    "([\\/.])?(?:(?:\\:(\\w+)(?:\\(((?:\\\\.|[^\\\\()])+)\\))?|\\(((?:\\\\.|[^\\\\()])+)\\))([+*?])?|(\\*))"
  ].join("|"), "g");
  function Ue(e, t) {
    for (var n = [], o = 0, r = 0, i = "", c = t && t.delimiter || "/", s; (s = qt.exec(e)) != null; ) {
      var f = s[0], a = s[1], u = s.index;
      if (i += e.slice(r, u), r = u + f.length, a) {
        i += a[1];
        continue;
      }
      var l = e[r], h = s[2], v = s[3], y = s[4], b = s[5], R = s[6], T = s[7];
      i && (n.push(i), i = "");
      var M = h != null && l != null && l !== h, B = R === "+" || R === "*", D = R === "?" || R === "*", I = h || c, S = y || b, g = h || (typeof n[n.length - 1] == "string" ? n[n.length - 1] : "");
      n.push({
        name: v || o++,
        prefix: h || "",
        delimiter: I,
        optional: D,
        repeat: B,
        partial: M,
        asterisk: !!T,
        pattern: S ? Jt(S) : T ? ".*" : Kt(I, g)
      });
    }
    return r < e.length && (i += e.substr(r)), i && n.push(i), n;
  }
  function Kt(e, t) {
    return !t || t.indexOf(e) > -1 ? "[^" + ee(e) + "]+?" : ee(t) + "|(?:(?!" + ee(t) + ")[^" + ee(e) + "])+?";
  }
  function zt(e, t) {
    return pt(Ue(e, t), t);
  }
  function Gt(e) {
    return encodeURI(e).replace(/[\/?#]/g, function(t) {
      return "%" + t.charCodeAt(0).toString(16).toUpperCase();
    });
  }
  function Vt(e) {
    return encodeURI(e).replace(/[?#]/g, function(t) {
      return "%" + t.charCodeAt(0).toString(16).toUpperCase();
    });
  }
  function pt(e, t) {
    for (var n = new Array(e.length), o = 0; o < e.length; o++) typeof e[o] == "object" && (n[o] = new RegExp("^(?:" + e[o].pattern + ")$", Ie(t)));
    return function(r, i) {
      for (var c = "", s = r || {}, f = i || {}, a = f.pretty ? Gt : encodeURIComponent, u = 0; u < e.length; u++) {
        var l = e[u];
        if (typeof l == "string") {
          c += l;
          continue;
        }
        var h = s[l.name], v;
        if (h == null) if (l.optional) {
          l.partial && (c += l.prefix);
          continue;
        } else throw new TypeError('Expected "' + l.name + '" to be defined');
        if (ue(h)) {
          if (!l.repeat) throw new TypeError('Expected "' + l.name + '" to not repeat, but received `' + JSON.stringify(h) + "`");
          if (h.length === 0) {
            if (l.optional) continue;
            throw new TypeError('Expected "' + l.name + '" to not be empty');
          }
          for (var y = 0; y < h.length; y++) {
            if (v = a(h[y]), !n[u].test(v)) throw new TypeError('Expected all "' + l.name + '" to match "' + l.pattern + '", but received `' + JSON.stringify(v) + "`");
            c += (y === 0 ? l.prefix : l.delimiter) + v;
          }
          continue;
        }
        if (v = l.asterisk ? Vt(h) : a(h), !n[u].test(v)) throw new TypeError('Expected "' + l.name + '" to match "' + l.pattern + '", but received "' + v + '"');
        c += l.prefix + v;
      }
      return c;
    };
  }
  function ee(e) {
    return e.replace(/([.+*?=^!:${}()[\]|\/\\])/g, "\\$1");
  }
  function Jt(e) {
    return e.replace(/([=!:$\/()])/g, "\\$1");
  }
  function He(e, t) {
    return e.keys = t, e;
  }
  function Ie(e) {
    return e && e.sensitive ? "" : "i";
  }
  function Xt(e, t) {
    var n = e.source.match(/\((?!\?)/g);
    if (n) for (var o = 0; o < n.length; o++) t.push({
      name: o,
      prefix: null,
      delimiter: null,
      optional: false,
      repeat: false,
      partial: false,
      asterisk: false,
      pattern: null
    });
    return He(e, t);
  }
  function kt(e, t, n) {
    for (var o = [], r = 0; r < e.length; r++) o.push(dt(e[r], t, n).source);
    var i = new RegExp("(?:" + o.join("|") + ")", Ie(n));
    return He(i, t);
  }
  function Yt(e, t, n) {
    return vt(Ue(e, n), t, n);
  }
  function vt(e, t, n) {
    ue(t) || (n = t || n, t = []), n = n || {};
    for (var o = n.strict, r = n.end !== false, i = "", c = 0; c < e.length; c++) {
      var s = e[c];
      if (typeof s == "string") i += ee(s);
      else {
        var f = ee(s.prefix), a = "(?:" + s.pattern + ")";
        t.push(s), s.repeat && (a += "(?:" + f + a + ")*"), s.optional ? s.partial ? a = f + "(" + a + ")?" : a = "(?:" + f + "(" + a + "))?" : a = f + "(" + a + ")", i += a;
      }
    }
    var u = ee(n.delimiter || "/"), l = i.slice(-u.length) === u;
    return o || (i = (l ? i.slice(0, -u.length) : i) + "(?:" + u + "(?=$))?"), r ? i += "$" : i += o && l ? "" : "(?=" + u + "|$)", He(new RegExp("^" + i, Ie(n)), t);
  }
  function dt(e, t, n) {
    return ue(t) || (n = t || n, t = []), n = n || {}, e instanceof RegExp ? Xt(e, t) : ue(e) ? kt(e, t, n) : Yt(e, t, n);
  }
  var Qt = re.exports;
  const mt = ot(Qt);
  var E = {};
  var $ = typeof Symbol == "function" && Symbol.for, _e = $ ? Symbol.for("react.element") : 60103, Ne = $ ? Symbol.for("react.portal") : 60106, le = $ ? Symbol.for("react.fragment") : 60107, he = $ ? Symbol.for("react.strict_mode") : 60108, pe = $ ? Symbol.for("react.profiler") : 60114, ve = $ ? Symbol.for("react.provider") : 60109, de = $ ? Symbol.for("react.context") : 60110, Be = $ ? Symbol.for("react.async_mode") : 60111, me = $ ? Symbol.for("react.concurrent_mode") : 60111, ye = $ ? Symbol.for("react.forward_ref") : 60112, ge = $ ? Symbol.for("react.suspense") : 60113, Zt = $ ? Symbol.for("react.suspense_list") : 60120, we = $ ? Symbol.for("react.memo") : 60115, xe = $ ? Symbol.for("react.lazy") : 60116, en = $ ? Symbol.for("react.block") : 60121, tn = $ ? Symbol.for("react.fundamental") : 60117, nn = $ ? Symbol.for("react.responder") : 60118, rn = $ ? Symbol.for("react.scope") : 60119;
  function q(e) {
    if (typeof e == "object" && e !== null) {
      var t = e.$$typeof;
      switch (t) {
        case _e:
          switch (e = e.type, e) {
            case Be:
            case me:
            case le:
            case pe:
            case he:
            case ge:
              return e;
            default:
              switch (e = e && e.$$typeof, e) {
                case de:
                case ye:
                case xe:
                case we:
                case ve:
                  return e;
                default:
                  return t;
              }
          }
        case Ne:
          return t;
      }
    }
  }
  function yt(e) {
    return q(e) === me;
  }
  E.AsyncMode = Be;
  E.ConcurrentMode = me;
  E.ContextConsumer = de;
  E.ContextProvider = ve;
  E.Element = _e;
  E.ForwardRef = ye;
  E.Fragment = le;
  E.Lazy = xe;
  E.Memo = we;
  E.Portal = Ne;
  E.Profiler = pe;
  E.StrictMode = he;
  E.Suspense = ge;
  E.isAsyncMode = function(e) {
    return yt(e) || q(e) === Be;
  };
  E.isConcurrentMode = yt;
  E.isContextConsumer = function(e) {
    return q(e) === de;
  };
  E.isContextProvider = function(e) {
    return q(e) === ve;
  };
  E.isElement = function(e) {
    return typeof e == "object" && e !== null && e.$$typeof === _e;
  };
  E.isForwardRef = function(e) {
    return q(e) === ye;
  };
  E.isFragment = function(e) {
    return q(e) === le;
  };
  E.isLazy = function(e) {
    return q(e) === xe;
  };
  E.isMemo = function(e) {
    return q(e) === we;
  };
  E.isPortal = function(e) {
    return q(e) === Ne;
  };
  E.isProfiler = function(e) {
    return q(e) === pe;
  };
  E.isStrictMode = function(e) {
    return q(e) === he;
  };
  E.isSuspense = function(e) {
    return q(e) === ge;
  };
  E.isValidElementType = function(e) {
    return typeof e == "string" || typeof e == "function" || e === le || e === me || e === pe || e === he || e === ge || e === Zt || typeof e == "object" && e !== null && (e.$$typeof === xe || e.$$typeof === we || e.$$typeof === ve || e.$$typeof === de || e.$$typeof === ye || e.$$typeof === tn || e.$$typeof === nn || e.$$typeof === rn || e.$$typeof === en);
  };
  E.typeOf = q;
  const P = await rt("react");
  var Te = 1073741823, ke = typeof globalThis < "u" ? globalThis : typeof window < "u" ? window : typeof global < "u" ? global : {};
  function on() {
    var e = "__global_unique_id__";
    return ke[e] = (ke[e] || 0) + 1;
  }
  function an(e, t) {
    return e === t ? e !== 0 || 1 / e === 1 / t : e !== e && t !== t;
  }
  function sn(e) {
    var t = [];
    return {
      on: function(o) {
        t.push(o);
      },
      off: function(o) {
        t = t.filter(function(r) {
          return r !== o;
        });
      },
      get: function() {
        return e;
      },
      set: function(o, r) {
        e = o, t.forEach(function(i) {
          return i(e, r);
        });
      }
    };
  }
  function cn(e) {
    return Array.isArray(e) ? e[0] : e;
  }
  function un(e, t) {
    var n, o, r = "__create-react-context-" + on() + "__", i = function(s) {
      X(f, s);
      function f() {
        for (var u, l = arguments.length, h = new Array(l), v = 0; v < l; v++) h[v] = arguments[v];
        return u = s.call.apply(s, [
          this
        ].concat(h)) || this, u.emitter = sn(u.props.value), u;
      }
      var a = f.prototype;
      return a.getChildContext = function() {
        var l;
        return l = {}, l[r] = this.emitter, l;
      }, a.componentWillReceiveProps = function(l) {
        if (this.props.value !== l.value) {
          var h = this.props.value, v = l.value, y;
          an(h, v) ? y = 0 : (y = typeof t == "function" ? t(h, v) : Te, y |= 0, y !== 0 && this.emitter.set(l.value, y));
        }
      }, a.render = function() {
        return this.props.children;
      }, f;
    }(P.Component);
    i.childContextTypes = (n = {}, n[r] = Fe.object.isRequired, n);
    var c = function(s) {
      X(f, s);
      function f() {
        for (var u, l = arguments.length, h = new Array(l), v = 0; v < l; v++) h[v] = arguments[v];
        return u = s.call.apply(s, [
          this
        ].concat(h)) || this, u.observedBits = void 0, u.state = {
          value: u.getValue()
        }, u.onUpdate = function(y, b) {
          var R = u.observedBits | 0;
          R & b && u.setState({
            value: u.getValue()
          });
        }, u;
      }
      var a = f.prototype;
      return a.componentWillReceiveProps = function(l) {
        var h = l.observedBits;
        this.observedBits = h ?? Te;
      }, a.componentDidMount = function() {
        this.context[r] && this.context[r].on(this.onUpdate);
        var l = this.props.observedBits;
        this.observedBits = l ?? Te;
      }, a.componentWillUnmount = function() {
        this.context[r] && this.context[r].off(this.onUpdate);
      }, a.getValue = function() {
        return this.context[r] ? this.context[r].get() : e;
      }, a.render = function() {
        return cn(this.props.children)(this.state.value);
      }, f;
    }(P.Component);
    return c.contextTypes = (o = {}, o[r] = Fe.object, o), {
      Provider: i,
      Consumer: c
    };
  }
  let fn, gt, wt, G, xt;
  fn = P.createContext || un;
  gt = function(t) {
    var n = fn();
    return n.displayName = t, n;
  };
  wt = gt("Router-History");
  G = gt("Router");
  Pe = function(e) {
    X(t, e), t.computeRootMatch = function(r) {
      return {
        path: "/",
        url: "/",
        params: {},
        isExact: r === "/"
      };
    };
    function t(o) {
      var r;
      return r = e.call(this, o) || this, r.state = {
        location: o.history.location
      }, r._isMounted = false, r._pendingLocation = null, o.staticContext || (r.unlisten = o.history.listen(function(i) {
        r._pendingLocation = i;
      })), r;
    }
    var n = t.prototype;
    return n.componentDidMount = function() {
      var r = this;
      this._isMounted = true, this.unlisten && this.unlisten(), this.props.staticContext || (this.unlisten = this.props.history.listen(function(i) {
        r._isMounted && r.setState({
          location: i
        });
      })), this._pendingLocation && this.setState({
        location: this._pendingLocation
      });
    }, n.componentWillUnmount = function() {
      this.unlisten && (this.unlisten(), this._isMounted = false, this._pendingLocation = null);
    }, n.render = function() {
      return P.createElement(G.Provider, {
        value: {
          history: this.props.history,
          location: this.state.location,
          match: t.computeRootMatch(this.state.location.pathname),
          staticContext: this.props.staticContext
        }
      }, P.createElement(wt.Provider, {
        children: this.props.children || null,
        value: this.props.history
      }));
    }, t;
  }(P.Component);
  Tn = function(e) {
    X(t, e);
    function t() {
      for (var o, r = arguments.length, i = new Array(r), c = 0; c < r; c++) i[c] = arguments[c];
      return o = e.call.apply(e, [
        this
      ].concat(i)) || this, o.history = jt(o.props), o;
    }
    var n = t.prototype;
    return n.render = function() {
      return P.createElement(Pe, {
        history: this.history,
        children: this.props.children
      });
    }, t;
  }(P.Component);
  xt = function(e) {
    X(t, e);
    function t() {
      return e.apply(this, arguments) || this;
    }
    var n = t.prototype;
    return n.componentDidMount = function() {
      this.props.onMount && this.props.onMount.call(this, this);
    }, n.componentDidUpdate = function(r) {
      this.props.onUpdate && this.props.onUpdate.call(this, this, r);
    }, n.componentWillUnmount = function() {
      this.props.onUnmount && this.props.onUnmount.call(this, this);
    }, n.render = function() {
      return null;
    }, t;
  }(P.Component);
  An = function(e) {
    var t = e.message, n = e.when, o = n === void 0 ? true : n;
    return P.createElement(G.Consumer, null, function(r) {
      if (r || k(), !o || r.staticContext) return null;
      var i = r.history.block;
      return P.createElement(xt, {
        onMount: function(s) {
          s.release = i(t);
        },
        onUpdate: function(s, f) {
          f.message !== t && (s.release(), s.release = i(t));
        },
        onUnmount: function(s) {
          s.release();
        },
        message: t
      });
    });
  };
  var Ae = {}, ln = 1e4, Ye = 0;
  function hn(e) {
    if (Ae[e]) return Ae[e];
    var t = mt.compile(e);
    return Ye < ln && (Ae[e] = t, Ye++), t;
  }
  Qe = function(e, t) {
    return e === void 0 && (e = "/"), t === void 0 && (t = {}), e === "/" ? e : hn(e)(t, {
      pretty: true
    });
  };
  Ln = function(e) {
    var t = e.computedMatch, n = e.to, o = e.push, r = o === void 0 ? false : o;
    return P.createElement(G.Consumer, null, function(i) {
      i || k();
      var c = i.history, s = i.staticContext, f = r ? c.push : c.replace, a = N(t ? typeof n == "string" ? Qe(n, t.params) : H({}, n, {
        pathname: Qe(n.pathname, t.params)
      }) : n);
      return s ? (f(a), null) : P.createElement(xt, {
        onMount: function() {
          f(a);
        },
        onUpdate: function(l, h) {
          var v = N(h.to);
          Mt(v, H({}, a, {
            key: v.key
          })) || f(a);
        },
        to: n
      });
    });
  };
  var Ze = {}, pn = 1e4, et = 0;
  function vn(e, t) {
    var n = "" + t.end + t.strict + t.sensitive, o = Ze[n] || (Ze[n] = {});
    if (o[e]) return o[e];
    var r = [], i = mt(e, r, t), c = {
      regexp: i,
      keys: r
    };
    return et < pn && (o[e] = c, et++), c;
  }
  Ee = function(e, t) {
    t === void 0 && (t = {}), (typeof t == "string" || Array.isArray(t)) && (t = {
      path: t
    });
    var n = t, o = n.path, r = n.exact, i = r === void 0 ? false : r, c = n.strict, s = c === void 0 ? false : c, f = n.sensitive, a = f === void 0 ? false : f, u = [].concat(o);
    return u.reduce(function(l, h) {
      if (!h && h !== "") return null;
      if (l) return l;
      var v = vn(h, {
        end: i,
        strict: s,
        sensitive: a
      }), y = v.regexp, b = v.keys, R = y.exec(e);
      if (!R) return null;
      var T = R[0], M = R.slice(1), B = e === T;
      return i && !B ? null : {
        path: h,
        url: h === "/" && T === "" ? "/" : T,
        isExact: B,
        params: b.reduce(function(D, I, S) {
          return D[I.name] = M[S], D;
        }, {})
      };
    }, null);
  };
  function dn(e) {
    return P.Children.count(e) === 0;
  }
  $n = function(e) {
    X(t, e);
    function t() {
      return e.apply(this, arguments) || this;
    }
    var n = t.prototype;
    return n.render = function() {
      var r = this;
      return P.createElement(G.Consumer, null, function(i) {
        i || k();
        var c = r.props.location || i.location, s = r.props.computedMatch ? r.props.computedMatch : r.props.path ? Ee(c.pathname, r.props) : i.match, f = H({}, i, {
          location: c,
          match: s
        }), a = r.props, u = a.children, l = a.component, h = a.render;
        return Array.isArray(u) && dn(u) && (u = null), P.createElement(G.Provider, {
          value: f
        }, f.match ? u ? typeof u == "function" ? u(f) : u : l ? P.createElement(l, f) : h ? h(f) : null : typeof u == "function" ? u(f) : null);
      });
    }, t;
  }(P.Component);
  function De(e) {
    return e.charAt(0) === "/" ? e : "/" + e;
  }
  function mn(e, t) {
    return e ? H({}, t, {
      pathname: De(e) + t.pathname
    }) : t;
  }
  function yn(e, t) {
    if (!e) return t;
    var n = De(e);
    return t.pathname.indexOf(n) !== 0 ? t : H({}, t, {
      pathname: t.pathname.substr(n.length)
    });
  }
  function tt(e) {
    return typeof e == "string" ? e : W(e);
  }
  function Le(e) {
    return function() {
      k();
    };
  }
  function nt() {
  }
  On = function(e) {
    X(t, e);
    function t() {
      for (var o, r = arguments.length, i = new Array(r), c = 0; c < r; c++) i[c] = arguments[c];
      return o = e.call.apply(e, [
        this
      ].concat(i)) || this, o.handlePush = function(s) {
        return o.navigateTo(s, "PUSH");
      }, o.handleReplace = function(s) {
        return o.navigateTo(s, "REPLACE");
      }, o.handleListen = function() {
        return nt;
      }, o.handleBlock = function() {
        return nt;
      }, o;
    }
    var n = t.prototype;
    return n.navigateTo = function(r, i) {
      var c = this.props, s = c.basename, f = s === void 0 ? "" : s, a = c.context, u = a === void 0 ? {} : a;
      u.action = i, u.location = mn(f, N(r)), u.url = tt(u.location);
    }, n.render = function() {
      var r = this.props, i = r.basename, c = i === void 0 ? "" : i, s = r.context, f = s === void 0 ? {} : s, a = r.location, u = a === void 0 ? "/" : a, l = ae(r, [
        "basename",
        "context",
        "location"
      ]), h = {
        createHref: function(y) {
          return De(c + tt(y));
        },
        action: "POP",
        location: yn(c, N(u)),
        push: this.handlePush,
        replace: this.handleReplace,
        go: Le(),
        goBack: Le(),
        goForward: Le(),
        listen: this.handleListen,
        block: this.handleBlock
      };
      return P.createElement(Pe, H({}, l, {
        history: h,
        staticContext: f
      }));
    }, t;
  }(P.Component);
  Mn = function(e) {
    X(t, e);
    function t() {
      return e.apply(this, arguments) || this;
    }
    var n = t.prototype;
    return n.render = function() {
      var r = this;
      return P.createElement(G.Consumer, null, function(i) {
        i || k();
        var c = r.props.location || i.location, s, f;
        return P.Children.forEach(r.props.children, function(a) {
          if (f == null && P.isValidElement(a)) {
            s = a;
            var u = a.props.path || a.props.from;
            f = u ? Ee(c.pathname, H({}, a.props, {
              path: u
            })) : i.match;
          }
        }), f ? P.cloneElement(s, {
          location: c,
          computedMatch: f
        }) : null;
      });
    }, t;
  }(P.Component);
  Un = function(e) {
    var t = "withRouter(" + (e.displayName || e.name) + ")", n = function(r) {
      var i = r.wrappedComponentRef, c = ae(r, [
        "wrappedComponentRef"
      ]);
      return P.createElement(G.Consumer, null, function(s) {
        return s || k(), P.createElement(e, H({}, c, s, {
          ref: i
        }));
      });
    };
    return n.displayName = t, n.WrappedComponent = e, Et(n, e);
  };
  var Ce = P.useContext;
  Hn = function() {
    return Ce(wt);
  };
  gn = function() {
    return Ce(G).location;
  };
  In = function() {
    var e = Ce(G).match;
    return e ? e.params : {};
  };
  _n = function(e) {
    var t = gn(), n = Ce(G).match;
    return e ? Ee(t.pathname, e) : n;
  };
  const J = await rt("react");
  let $e, Oe, We, ne;
  Nn = function(e) {
    X(t, e);
    function t() {
      for (var o, r = arguments.length, i = new Array(r), c = 0; c < r; c++) i[c] = arguments[c];
      return o = e.call.apply(e, [
        this
      ].concat(i)) || this, o.history = Nt(o.props), o;
    }
    var n = t.prototype;
    return n.render = function() {
      return J.createElement(Pe, {
        history: this.history,
        children: this.props.children
      });
    }, t;
  }(J.Component);
  Bn = function(e) {
    X(t, e);
    function t() {
      for (var o, r = arguments.length, i = new Array(r), c = 0; c < r; c++) i[c] = arguments[c];
      return o = e.call.apply(e, [
        this
      ].concat(i)) || this, o.history = Wt(o.props), o;
    }
    var n = t.prototype;
    return n.render = function() {
      return J.createElement(Pe, {
        history: this.history,
        children: this.props.children
      });
    }, t;
  }(J.Component);
  $e = function(t, n) {
    return typeof t == "function" ? t(n) : t;
  };
  Oe = function(t, n) {
    return typeof t == "string" ? N(t, null, null, n) : t;
  };
  We = function(t) {
    return t;
  };
  ne = J.forwardRef;
  typeof ne > "u" && (ne = We);
  function wn(e) {
    return !!(e.metaKey || e.altKey || e.ctrlKey || e.shiftKey);
  }
  let xn, Pt, fe;
  xn = ne(function(e, t) {
    var n = e.innerRef, o = e.navigate, r = e.onClick, i = ae(e, [
      "innerRef",
      "navigate",
      "onClick"
    ]), c = i.target, s = H({}, i, {
      onClick: function(a) {
        try {
          r && r(a);
        } catch (u) {
          throw a.preventDefault(), u;
        }
        !a.defaultPrevented && a.button === 0 && (!c || c === "_self") && !wn(a) && (a.preventDefault(), o());
      }
    });
    return We !== ne ? s.ref = t || n : s.ref = n, J.createElement("a", s);
  });
  Pn = ne(function(e, t) {
    var n = e.component, o = n === void 0 ? xn : n, r = e.replace, i = e.to, c = e.innerRef, s = ae(e, [
      "component",
      "replace",
      "to",
      "innerRef"
    ]);
    return J.createElement(G.Consumer, null, function(f) {
      f || k();
      var a = f.history, u = Oe($e(i, f.location), f.location), l = u ? a.createHref(u) : "", h = H({}, s, {
        href: l,
        navigate: function() {
          var y = $e(i, f.location), b = W(f.location) === W(Oe(y)), R = r || b ? a.replace : a.push;
          R(y);
        }
      });
      return We !== ne ? h.ref = t || c : h.innerRef = c, J.createElement(o, h);
    });
  });
  Pt = function(t) {
    return t;
  };
  fe = J.forwardRef;
  typeof fe > "u" && (fe = Pt);
  function En() {
    for (var e = arguments.length, t = new Array(e), n = 0; n < e; n++) t[n] = arguments[n];
    return t.filter(function(o) {
      return o;
    }).join(" ");
  }
  Dn = fe(function(e, t) {
    var n = e["aria-current"], o = n === void 0 ? "page" : n, r = e.activeClassName, i = r === void 0 ? "active" : r, c = e.activeStyle, s = e.className, f = e.exact, a = e.isActive, u = e.location, l = e.sensitive, h = e.strict, v = e.style, y = e.to, b = e.innerRef, R = ae(e, [
      "aria-current",
      "activeClassName",
      "activeStyle",
      "className",
      "exact",
      "isActive",
      "location",
      "sensitive",
      "strict",
      "style",
      "to",
      "innerRef"
    ]);
    return J.createElement(G.Consumer, null, function(T) {
      T || k();
      var M = u || T.location, B = Oe($e(y, M), M), D = B.pathname, I = D && D.replace(/([.+*?=^!:${}()[\]|/\\])/g, "\\$1"), S = I ? Ee(M.pathname, {
        path: I,
        exact: f,
        sensitive: l,
        strict: h
      }) : null, g = !!(a ? a(S, M) : S), x = typeof s == "function" ? s(g) : s, O = typeof v == "function" ? v(g) : v;
      g && (x = En(x, i), O = H({}, O, c));
      var A = H({
        "aria-current": g && o || null,
        className: x,
        style: O,
        to: B
      }, R);
      return Pt !== fe ? A.ref = t || b : A.innerRef = b, J.createElement(Pn, A);
    });
  });
});
export {
  Nn as BrowserRouter,
  Bn as HashRouter,
  Pn as Link,
  Tn as MemoryRouter,
  Dn as NavLink,
  An as Prompt,
  Ln as Redirect,
  $n as Route,
  Pe as Router,
  On as StaticRouter,
  Mn as Switch,
  __tla,
  Qe as generatePath,
  Ee as matchPath,
  Hn as useHistory,
  gn as useLocation,
  In as useParams,
  _n as useRouteMatch,
  Un as withRouter
};
