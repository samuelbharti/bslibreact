// The browser-side readout for port_peek() (pkg-r) and bslib_react.port.peek()
// (pkg-py). This is the single source for both: `make update-port-js` copies
// this exact file from pkg-r/inst/port/peek-readout.js into
// pkg-py/src/bslib_react/port/peek-readout.js, so the two languages' peek
// functions read the running page the same way and their output can be
// compared line for line. Edit this file, never a per-language copy of it.
//
// The placeholder __SELECTOR_LIST_JSON__ below is replaced, by whichever
// language is driving the browser, with a JSON-encoded array of CSS
// selector strings (the caller's --select/select= list, or "[]" for none)
// before this script is handed to the page's own JS engine (R:
// chromote's $Runtime$evaluate(); Python: playwright's page.evaluate()).
// It is not a printf-style "%s": do a plain text substitution of the
// whole token, since the selector list itself is already valid JSON (and
// therefore already valid JS array syntax) once substituted in.
(function () {
  var S = window.Shiny;
  var rel = function (u) {
    try {
      var a = new URL(u, location.href);
      return a.origin === location.origin ? a.pathname.replace(/^\//, "") : u;
    } catch (e) {
      return u;
    }
  };
  var attrs = function (el) {
    var o = {};
    if (!el) return o;
    for (var i = 0; i < el.attributes.length; i++) {
      o[el.attributes[i].name] = el.attributes[i].value;
    }
    return o;
  };
  var sels = __SELECTOR_LIST_JSON__;
  var picked = sels.map(function (sel) {
    var el = document.querySelector(sel);
    if (!el) return { sel: sel, missing: true };
    var cs = getComputedStyle(el);
    var r = el.getBoundingClientRect();
    return {
      sel: sel,
      tag: el.tagName.toLowerCase(),
      id: el.id,
      cls:
        el.className && el.className.baseVal !== undefined
          ? el.className.baseVal
          : el.className,
      box: [r.x, r.y, r.width, r.height].map(Math.round),
      text: (el.textContent || "").trim().slice(0, 80),
      style: {
        color: cs.color,
        background: cs.backgroundColor,
        font: cs.fontFamily.split(",")[0],
        size: cs.fontSize,
        weight: cs.fontWeight,
        display: cs.display,
        height: cs.height,
        width: cs.width,
        padding: cs.padding,
        margin: cs.margin,
        border: cs.border,
        radius: cs.borderRadius,
        overflow: cs.overflow,
      },
    };
  });
  return JSON.stringify({
    title: document.title,
    shiny: !!S,
    connected: !!(S && S.shinyapp && S.shinyapp.isConnected && S.shinyapp.isConnected()),
    busy: document.documentElement.classList.contains("shiny-busy"),
    boundInputs: document.querySelectorAll(".shiny-bound-input").length,
    boundOutputs: document.querySelectorAll(".shiny-bound-output").length,
    outputErrors: Array.prototype.map.call(
      document.querySelectorAll(".shiny-output-error"),
      function (e) {
        return (e.id || "?") + ": " + (e.textContent || "").trim().slice(0, 120);
      }
    ),
    html: attrs(document.documentElement),
    body: attrs(document.body),
    stylesheets: Array.prototype.map.call(document.styleSheets, function (s) {
      return s.href
        ? rel(s.href)
        : "(inline) " + ((s.ownerNode && s.ownerNode.textContent) || "").trim().slice(0, 60);
    }),
    picked: picked,
  });
})();
