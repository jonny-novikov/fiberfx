/*
  Mercury Svelte Runtime Compiler
  --------------------------------
  Compiles .svelte / .svelte.js source files in the browser (no build step)
  using the official Svelte 5 compiler, wires cross-component imports through
  blob-URL ES modules, and mounts the result into a real DOM node.

  All `svelte` + `svelte/internal/*` specifiers are rewritten to a single
  pinned esm.sh version so every compiled module — and the public `mount`
  helper — share one reactivity runtime instance.
*/

// Pin to a concrete version. A floating range (e.g. "5") makes esm.sh resolve
// each `svelte/internal/*` subpath independently, and some (disclose-version)
// fail to serve under the bare range. A concrete version keeps every subpath
// — compiler, runtime and the per-component internal imports — on one build.
const SVELTE_VERSION = "5.56.3";
const esm = (spec) =>
  "https://esm.sh/" + spec.replace(/^svelte/, "svelte@" + SVELTE_VERSION);

let _compiler = null;
function compiler() {
  return (_compiler ??= import("https://esm.sh/svelte@" + SVELTE_VERSION + "/compiler"));
}

let _runtime = null;
export function runtime() {
  return (_runtime ??= import("https://esm.sh/svelte@" + SVELTE_VERSION));
}

/* ---- path helpers --------------------------------------------------- */
function dirOf(p) {
  const i = p.lastIndexOf("/");
  return i === -1 ? "" : p.slice(0, i);
}
function normalize(path) {
  const out = [];
  for (const part of path.split("/")) {
    if (part === "" || part === ".") continue;
    if (part === "..") out.pop();
    else out.push(part);
  }
  return out.join("/");
}
function resolveRel(importer, spec) {
  return normalize(dirOf(importer) + "/" + spec);
}

/* ---- import rewriting ----------------------------------------------- */
const IMPORT_RE = /(from|import|export)(\s*(?:\(\s*)?)(["'])([^"']+)\3/g;

async function rewrite(code, importer) {
  const specs = new Set();
  let m;
  IMPORT_RE.lastIndex = 0;
  while ((m = IMPORT_RE.exec(code))) specs.add(m[4]);

  const map = new Map();
  for (const spec of specs) {
    if (spec === "svelte" || spec.startsWith("svelte/")) {
      map.set(spec, esm(spec));
    } else if (spec.startsWith("./") || spec.startsWith("../")) {
      map.set(spec, await buildModule(resolveRel(importer, spec)));
    }
  }
  IMPORT_RE.lastIndex = 0;
  return code.replace(IMPORT_RE, (full, kw, mid, q, spec) => {
    const url = map.get(spec);
    return url ? `${kw}${mid}${q}${url}${q}` : full;
  });
}

/* ---- module build (memoised) ---------------------------------------- */
const cache = new Map(); // path -> Promise<blobURL>

function buildModule(path) {
  if (cache.has(path)) return cache.get(path);
  const job = (async () => {
    const res = await fetch(path);
    if (!res.ok) throw new Error(`Cannot fetch ${path} (${res.status})`);
    const src = await res.text();
    const { compile, compileModule } = await compiler();

    let code;
    if (path.endsWith(".svelte")) {
      code = compile(src, {
        filename: path,
        generate: "client",
        css: "injected",
        dev: false,
      }).js.code;
    } else if (/\.svelte\.(js|ts)$/.test(path)) {
      code = compileModule(src, { filename: path, generate: "client" }).js.code;
    } else {
      code = src;
    }

    code = await rewrite(code, path);
    const blob = new Blob([code], { type: "text/javascript" });
    return URL.createObjectURL(blob);
  })();
  cache.set(path, job);
  return job;
}

/* ---- public API ----------------------------------------------------- */
export async function load(path) {
  const url = await buildModule(path);
  return import(/* @vite-ignore */ url);
}

export async function mountComponent(path, target, props = {}) {
  const [mod, { mount }] = await Promise.all([load(path), runtime()]);
  if (!mod.default) throw new Error(`${path} has no default export`);
  return mount(mod.default, { target, props });
}

export async function unmountComponent(instance) {
  if (!instance) return;
  const { unmount } = await runtime();
  try {
    unmount(instance);
  } catch (_) {}
}

/* Warm the compiler + runtime so first mount is snappy. */
export function warm() {
  compiler();
  runtime();
}
