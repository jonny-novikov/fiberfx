#!/usr/bin/env node
'use strict';

// code-download.js — Windows-friendly Node port of code-download.sh.
//
// Mirrors Claude Code distributives (latest/stable channels × darwin-x64 /
// linux-x64 / win32-x64 platforms) into $DOWNLOAD_FOLDER. Pure Node stdlib
// (no dependencies): `https` for transfers, `fs`/`path` for IO. `chmod +x` is
// applied only on POSIX — on Windows executability is by extension, so it is
// skipped there.
//
// Config is read from a `.env` sitting next to this script:
//   DOWNLOAD_URL     base release URL (…/claude-code-releases)
//   DOWNLOAD_FOLDER  output dir (relative paths resolve next to this script)
//   DOWNLOAD_BINARY  binary basename (e.g. `claude`)
//
// With no flags it mirrors every channel × platform; flags narrow the set:
//   --latest --stable                      pick channel(s)   (default: all)
//   --darwin-x64 --linux-x64 --win32-x64   pick platform(s)  (default: all)
//   --dry-run                              HEAD-check only, download nothing
//   -h, --help                             usage
//
// Re-runs are idempotent: a binary whose local size already matches the remote
// Content-Length is skipped.

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

const SCRIPT_DIR = __dirname;
const IS_WINDOWS = process.platform === 'win32';

const ALL_CHANNELS = ['latest', 'stable'];
const ALL_PLATFORMS = ['darwin-x64', 'linux-x64', 'win32-x64'];

function usage() {
  const me = path.basename(process.argv[1] || 'code-download.js');
  return [
    `Usage: node ${me} [CHANNELS] [PLATFORMS] [--dry-run]`,
    '',
    'Mirror Claude Code distributives into $DOWNLOAD_FOLDER (config from .env next',
    'to this script). With no channel/platform flags it mirrors every combination;',
    'each flag narrows the selection.',
    '',
    'Channels (repeatable; default: all):',
    "  --latest          mirror the 'latest' channel",
    "  --stable          mirror the 'stable' channel",
    '',
    'Platforms (repeatable; default: all):',
    '  --darwin-x64      macOS x64 binary   (chmod +x on POSIX)',
    '  --linux-x64       Linux x64 binary   (chmod +x on POSIX)',
    '  --win32-x64       Windows x64 binary (.exe)',
    '',
    'Other:',
    '  --dry-run         HEAD-check the URLs and report; download nothing',
    '  -h, --help        show this help',
    '',
    'Examples:',
    `  node ${me}                         # everything`,
    `  node ${me} --stable                # stable channel, all platforms`,
    `  node ${me} --latest --darwin-x64   # only latest/darwin-x64`,
  ].join('\n');
}

function parseArgs(argv) {
  const selChannels = [];
  const selPlatforms = [];
  let dryRun = false;
  for (const arg of argv) {
    switch (arg) {
      case '--latest':
      case '--stable':
        selChannels.push(arg.slice(2));
        break;
      case '--darwin-x64':
      case '--linux-x64':
      case '--win32-x64':
        selPlatforms.push(arg.slice(2));
        break;
      case '--dry-run':
        dryRun = true;
        break;
      case '-h':
      case '--help':
        process.stdout.write(usage() + '\n');
        process.exit(0);
        break; // unreachable
      default:
        process.stderr.write(`error: unknown argument: ${arg}\n`);
        process.stderr.write(usage() + '\n');
        process.exit(2);
    }
  }
  return { selChannels, selPlatforms, dryRun };
}

function loadEnv(envFile) {
  if (!fs.existsSync(envFile)) {
    process.stderr.write(`error: ${envFile} not found\n`);
    process.exit(1);
  }
  const env = {};
  for (let line of fs.readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    line = line.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq < 0) continue;
    const key = line.slice(0, eq).trim();
    let val = line.slice(eq + 1).trim();
    if (val.length >= 2 && val[0] === val[val.length - 1] && (val[0] === '"' || val[0] === "'")) {
      val = val.slice(1, -1);
    }
    env[key] = val;
  }
  return env;
}

// Minimal redirect-following request. method 'GET' or 'HEAD'.
// Resolves { status, headers, body } for HEAD/small GET, or streams to `dest`.
function request(url, { method = 'GET', dest = null, redirects = 5 } = {}) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('http:') ? http : https;
    const req = lib.request(url, { method }, (res) => {
      const status = res.statusCode || 0;

      if (status >= 300 && status < 400 && res.headers.location) {
        res.resume(); // drain so the socket frees
        if (redirects <= 0) { reject(new Error('too many redirects')); return; }
        const next = new URL(res.headers.location, url).toString();
        resolve(request(next, { method, dest, redirects: redirects - 1 }));
        return;
      }
      if (status < 200 || status >= 300) {
        res.resume();
        reject(new Error(`HTTP ${status}`));
        return;
      }

      if (method === 'HEAD' || !dest) {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => resolve({ status, headers: res.headers, body: Buffer.concat(chunks).toString('utf8') }));
        res.on('error', reject);
        return;
      }

      // Stream to a temp file, then atomically rename into place.
      const tmp = dest + '.part';
      const out = fs.createWriteStream(tmp);
      res.pipe(out);
      out.on('finish', () => out.close((err) => {
        if (err) { reject(err); return; }
        try { fs.renameSync(tmp, dest); resolve({ status, headers: res.headers }); }
        catch (e) { reject(e); }
      }));
      const fail = (e) => { try { fs.unlinkSync(tmp); } catch (_) {} reject(e); };
      out.on('error', fail);
      res.on('error', fail);
    });
    req.on('error', reject);
    req.end();
  });
}

function rel(p) {
  const r = path.relative(SCRIPT_DIR, p);
  return r || p;
}

async function main() {
  const { selChannels, selPlatforms, dryRun } = parseArgs(process.argv.slice(2));

  const env = loadEnv(path.join(SCRIPT_DIR, '.env'));
  for (const k of ['DOWNLOAD_URL', 'DOWNLOAD_FOLDER', 'DOWNLOAD_BINARY']) {
    if (!env[k]) { process.stderr.write(`error: ${k} must be set in .env\n`); process.exit(1); }
  }

  const baseUrl = env.DOWNLOAD_URL.replace(/\/+$/, '');
  const binary = env.DOWNLOAD_BINARY;
  const outRoot = path.isAbsolute(env.DOWNLOAD_FOLDER)
    ? env.DOWNLOAD_FOLDER
    : path.join(SCRIPT_DIR, env.DOWNLOAD_FOLDER);

  // platform -> { filename, exec }  (win32 => .exe suffix + no chmod)
  const platforms = ALL_PLATFORMS.map((p) => {
    const exe = p.startsWith('win32');
    return { platform: p, filename: exe ? `${binary}.exe` : binary, exec: !exe };
  });

  let failures = 0;

  for (const channel of ALL_CHANNELS) {
    if (selChannels.length && !selChannels.includes(channel)) continue;
    process.stdout.write(`==> channel: ${channel}\n`);

    let version;
    try {
      const r = await request(`${baseUrl}/${channel}`, { method: 'GET' });
      version = (r.body || '').replace(/\s+/g, '');
    } catch (e) {
      process.stderr.write(`    ! could not resolve a version from ${baseUrl}/${channel} (${e.message})\n`);
      failures++;
      continue;
    }
    if (!version) {
      process.stderr.write(`    ! empty version returned for channel '${channel}'\n`);
      failures++;
      continue;
    }
    process.stdout.write(`    version: ${version}\n`);

    for (const { platform, filename, exec } of platforms) {
      if (selPlatforms.length && !selPlatforms.includes(platform)) continue;

      const url = `${baseUrl}/${version}/${platform}/${filename}`;
      const dest = path.join(outRoot, channel, version, platform, filename);

      let rsize;
      try {
        const head = await request(url, { method: 'HEAD' });
        rsize = parseInt(head.headers['content-length'], 10);
      } catch (e) {
        process.stderr.write(`    ! unreachable: ${url}\n`);
        failures++;
        continue;
      }
      if (!Number.isFinite(rsize)) {
        process.stderr.write(`    ! unreachable: ${url}\n`);
        failures++;
        continue;
      }

      if (dryRun) {
        process.stdout.write(`    ~ would fetch ${platform}/${filename} (${rsize} bytes) -> ${rel(dest)}\n`);
        continue;
      }

      if (fs.existsSync(dest) && fs.statSync(dest).size === rsize) {
        process.stdout.write(`    = ${platform}/${filename} (already complete, skipping)\n`);
        continue;
      }

      try {
        fs.mkdirSync(path.dirname(dest), { recursive: true });
        await request(url, { method: 'GET', dest });
        if (exec && !IS_WINDOWS) fs.chmodSync(dest, 0o755);
        process.stdout.write(`    ✓ ${platform}/${filename} -> ${rel(dest)}\n`);
      } catch (e) {
        process.stderr.write(`    ! download failed: ${url} (${e.message})\n`);
        try { fs.unlinkSync(dest); } catch (_) {}
        failures++;
      }
    }
  }

  process.stdout.write('\n');
  if (failures > 0) {
    process.stderr.write(`done with ${failures} failure(s)\n`);
    process.exit(1);
  }
  process.stdout.write(`done — mirror up to date under ${rel(outRoot)}\n`);
}

main().catch((e) => {
  process.stderr.write(`fatal: ${e && e.stack ? e.stack : e}\n`);
  process.exit(1);
});
