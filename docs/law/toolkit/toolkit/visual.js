/**
 * visual.js — Visual regression (screenshot) testing for the page-validator toolkit.
 *
 * Captures PNG screenshots and compares them pixel-by-pixel against stored
 * baselines using pixelmatch. Reports the diff as TEXT (changed pixels, ratio,
 * dimensions) and writes baseline / current / diff PNGs to disk for OFFLINE
 * review. It never embeds images into output, so it consumes no image budget.
 *
 * Pure-JS deps (pixelmatch, pngjs) — no native build, fully offline after install.
 * Baselines live inside the project, so visual regression also runs offline.
 *
 * `VisualTester` extends `Validator`, so one object gives you both the DOM /
 * computed-style assertions AND screenshot regression.
 */
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const pixelmatch = require('pixelmatch');
const { Validator } = require('./validator');

class VisualTester extends Validator {
  constructor(opts = {}) {
    super(opts);
    // Where baselines / current / diff PNGs are stored (committed for offline runs).
    this.snapDir = opts.snapshotDir || process.env.SNAPSHOT_DIR || './__screenshots__';
    // Max allowed ratio of changed pixels (0.001 = 0.1% — absorbs anti-alias jitter).
    this.threshold = opts.threshold ?? 0.001;
    // Per-pixel colour sensitivity passed to pixelmatch (0..1, lower = stricter).
    this.pixelThreshold = opts.pixelThreshold ?? 0.1;
    // Refresh baselines instead of comparing (after an intentional UI change).
    this.updateBaselines = opts.updateBaselines || process.env.UPDATE_SNAPSHOTS === '1';
  }

  _dir(sub) {
    const d = path.join(this.snapDir, sub);
    fs.mkdirSync(d, { recursive: true });
    return d;
  }

  /**
   * Capture a screenshot and compare it to a stored baseline (visual regression).
   *
   * First run (or UPDATE_SNAPSHOTS=1): writes the baseline and passes.
   * Later runs: diffs current vs baseline, writes a diff PNG, passes if the
   * changed-pixel ratio is within threshold.
   *
   * @param {string} name              unique snapshot id (also the file name)
   * @param {object} [opts]
   * @param {string} [opts.selector]   element selector; omit for the page
   * @param {boolean}[opts.fullPage]   capture full scrollable page (default true when no selector)
   * @param {number} [opts.threshold]  override allowed changed-pixel ratio
   */
  async snapshot(name, opts = {}) {
    const file = name.replace(/[^a-z0-9_-]+/gi, '_') + '.png';
    const baselinePath = path.join(this._dir('baseline'), file);
    const currentPath = path.join(this._dir('current'), file);
    const diffPath = path.join(this._dir('diff'), file);
    const threshold = opts.threshold ?? this.threshold;

    // --- capture current ---
    const target = opts.selector ? this.page.locator(opts.selector).first() : this.page;
    const shotOpts = opts.selector ? {} : { fullPage: opts.fullPage !== false };
    const buf = await target.screenshot({ ...shotOpts, path: currentPath });

    // --- first run / explicit update → write baseline and pass ---
    if (this.updateBaselines || !fs.existsSync(baselinePath)) {
      fs.copyFileSync(currentPath, baselinePath);
      this.check(`snapshot "${name}" — baseline ${this.updateBaselines ? 'updated' : 'created'}`, true, file);
      return;
    }

    // --- compare against baseline ---
    const base = PNG.sync.read(fs.readFileSync(baselinePath));
    const curr = PNG.sync.read(buf);

    if (base.width !== curr.width || base.height !== curr.height) {
      this.check(`snapshot "${name}" — size matches baseline`, false,
        `baseline ${base.width}x${base.height} vs current ${curr.width}x${curr.height}`);
      return;
    }

    const { width, height } = base;
    const diff = new PNG({ width, height });
    const changed = pixelmatch(base.data, curr.data, diff.data, width, height,
      { threshold: this.pixelThreshold });
    fs.writeFileSync(diffPath, PNG.sync.write(diff));

    const total = width * height;
    const ratio = changed / total;
    const pct = (ratio * 100).toFixed(3);
    this.check(
      `snapshot "${name}" — diff ${pct}% ≤ ${(threshold * 100).toFixed(3)}%`,
      ratio <= threshold,
      `${changed}/${total} px changed (${pct}%) — diff: ${diffPath}`
    );
  }

  /**
   * Sanity check: a screenshot is NOT blank (catches white/black render failures,
   * missing fonts, un-mounted widgets). Samples ~5000 pixels and asserts variety.
   */
  async notBlank(name, opts = {}) {
    const target = opts.selector ? this.page.locator(opts.selector).first() : this.page;
    const buf = await target.screenshot(opts.selector ? {} : { fullPage: false });
    const png = PNG.sync.read(buf);
    const data = png.data;
    const first = [data[0], data[1], data[2]];
    const step = 4 * Math.max(1, Math.floor((png.width * png.height) / 5000));
    let differing = 0;
    for (let i = 0; i < data.length; i += step) {
      const d = Math.abs(data[i] - first[0]) + Math.abs(data[i + 1] - first[1]) + Math.abs(data[i + 2] - first[2]);
      if (d > 24) differing++;
    }
    this.check(`"${name}" — not blank`, differing > 5, `${differing} differing sampled px`);
  }
}

module.exports = { VisualTester };
