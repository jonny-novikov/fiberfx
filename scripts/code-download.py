#!/usr/bin/env python3
"""code-download.py — Windows-friendly Python port of code-download.sh.

Mirrors Claude Code distributives (latest/stable channels x darwin-x64 /
linux-x64 / win32-x64 platforms) into $DOWNLOAD_FOLDER. Pure standard library
(urllib) so it runs anywhere Python 3.8+ is installed, Windows included.
chmod +x is applied only on POSIX — on Windows executability is by extension,
so it is skipped there.

Config is read from a `.env` sitting next to this script:
  DOWNLOAD_URL     base release URL (.../claude-code-releases)
  DOWNLOAD_FOLDER  output dir (relative paths resolve next to this script)
  DOWNLOAD_BINARY  binary basename (e.g. `claude`)

With no flags it mirrors every channel x platform; flags narrow the set:
  --latest --stable                      pick channel(s)   (default: all)
  --darwin-x64 --linux-x64 --win32-x64   pick platform(s)  (default: all)
  --dry-run                              HEAD-check only, download nothing
  -h, --help                             usage

Re-runs are idempotent: a binary whose local size already matches the remote
Content-Length is skipped.
"""

import argparse
import os
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
IS_WINDOWS = os.name == "nt"


def _ssl_context() -> ssl.SSLContext:
    """Verifying TLS context that works across platforms.

    Uses the OS trust store by default (the usual Windows case). If that store
    comes up empty — common on freshly installed python.org builds — it falls
    back to the `certifi` CA bundle when present. Verification stays ON.
    """
    ctx = ssl.create_default_context()
    if not ctx.get_ca_certs():
        try:
            import certifi  # optional; only needed when the OS store is empty
            ctx.load_verify_locations(certifi.where())
        except Exception:
            pass
    return ctx


SSL_CTX = _ssl_context()

ALL_CHANNELS = ["latest", "stable"]
ALL_PLATFORMS = ["darwin-x64", "linux-x64", "win32-x64"]
# argparse turns --darwin-x64 into the attribute darwin_x64, etc.
PLATFORM_ATTR = {p: p.replace("-", "_") for p in ALL_PLATFORMS}


def load_env(env_file: Path) -> dict:
    if not env_file.is_file():
        sys.exit(f"error: {env_file} not found")
    env = {}
    for raw in env_file.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, val = line.split("=", 1)
        key, val = key.strip(), val.strip()
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        env[key] = val
    return env


def parse_args(argv):
    p = argparse.ArgumentParser(
        prog="code-download.py",
        description=(
            "Mirror Claude Code distributives into $DOWNLOAD_FOLDER (config from "
            ".env next to this script). With no channel/platform flags it mirrors "
            "every combination; each flag narrows the selection."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "examples:\n"
            "  python code-download.py                         # everything\n"
            "  python code-download.py --stable                # stable channel, all platforms\n"
            "  python code-download.py --latest --darwin-x64   # only latest/darwin-x64"
        ),
    )
    p.add_argument("--latest", action="store_true", help="mirror the 'latest' channel")
    p.add_argument("--stable", action="store_true", help="mirror the 'stable' channel")
    p.add_argument("--darwin-x64", action="store_true", help="macOS x64 binary (chmod +x on POSIX)")
    p.add_argument("--linux-x64", action="store_true", help="Linux x64 binary (chmod +x on POSIX)")
    p.add_argument("--win32-x64", action="store_true", help="Windows x64 binary (.exe)")
    p.add_argument("--dry-run", action="store_true", help="HEAD-check the URLs and report; download nothing")
    args = p.parse_args(argv)

    sel_channels = [c for c in ALL_CHANNELS if getattr(args, c)]
    sel_platforms = [p_ for p_ in ALL_PLATFORMS if getattr(args, PLATFORM_ATTR[p_])]
    return sel_channels, sel_platforms, args.dry_run


def http_get_text(url: str) -> str:
    with urllib.request.urlopen(url, timeout=60, context=SSL_CTX) as resp:
        return resp.read().decode("utf-8")


def remote_size(url: str):
    req = urllib.request.Request(url, method="HEAD")
    with urllib.request.urlopen(req, timeout=60, context=SSL_CTX) as resp:
        cl = resp.headers.get("Content-Length")
        return int(cl) if cl is not None else None


def download(url: str, dest: Path) -> None:
    # Stream to a temp file in 1 MiB chunks (never buffer ~234 MB in memory),
    # then atomically rename into place.
    tmp = dest.parent / (dest.name + ".part")
    with urllib.request.urlopen(url, timeout=300, context=SSL_CTX) as resp, open(tmp, "wb") as out:
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            out.write(chunk)
    tmp.replace(dest)


def rel(p: Path) -> str:
    try:
        return str(p.relative_to(SCRIPT_DIR))
    except ValueError:
        return str(p)


def main() -> int:
    sel_channels, sel_platforms, dry_run = parse_args(sys.argv[1:])

    env = load_env(SCRIPT_DIR / ".env")
    for key in ("DOWNLOAD_URL", "DOWNLOAD_FOLDER", "DOWNLOAD_BINARY"):
        if not env.get(key):
            sys.exit(f"error: {key} must be set in .env")

    base_url = env["DOWNLOAD_URL"].rstrip("/")
    binary = env["DOWNLOAD_BINARY"]
    folder = env["DOWNLOAD_FOLDER"]
    out_root = Path(folder) if os.path.isabs(folder) else SCRIPT_DIR / folder

    # platform -> (filename, make_executable)  (win32 => .exe suffix + no chmod)
    platforms = []
    for plat in ALL_PLATFORMS:
        exe = plat.startswith("win32")
        platforms.append((plat, f"{binary}.exe" if exe else binary, not exe))

    failures = 0

    for channel in ALL_CHANNELS:
        if sel_channels and channel not in sel_channels:
            continue
        print(f"==> channel: {channel}")

        try:
            version = "".join(http_get_text(f"{base_url}/{channel}").split())
        except (urllib.error.URLError, OSError) as exc:
            print(f"    ! could not resolve a version from {base_url}/{channel} ({exc})", file=sys.stderr)
            failures += 1
            continue
        if not version:
            print(f"    ! empty version returned for channel '{channel}'", file=sys.stderr)
            failures += 1
            continue
        print(f"    version: {version}")

        for plat, filename, exec_bit in platforms:
            if sel_platforms and plat not in sel_platforms:
                continue

            url = f"{base_url}/{version}/{plat}/{filename}"
            dest = out_root / channel / version / plat / filename

            try:
                rsize = remote_size(url)
            except (urllib.error.URLError, OSError):
                print(f"    ! unreachable: {url}", file=sys.stderr)
                failures += 1
                continue
            if rsize is None:
                print(f"    ! unreachable: {url}", file=sys.stderr)
                failures += 1
                continue

            if dry_run:
                print(f"    ~ would fetch {plat}/{filename} ({rsize} bytes) -> {rel(dest)}")
                continue

            if dest.is_file() and dest.stat().st_size == rsize:
                print(f"    = {plat}/{filename} (already complete, skipping)")
                continue

            try:
                dest.parent.mkdir(parents=True, exist_ok=True)
                download(url, dest)
                if exec_bit and not IS_WINDOWS:
                    os.chmod(dest, 0o755)
                print(f"    ✓ {plat}/{filename} -> {rel(dest)}")
            except (urllib.error.URLError, OSError) as exc:
                print(f"    ! download failed: {url} ({exc})", file=sys.stderr)
                try:
                    dest.unlink()
                except OSError:
                    pass
                failures += 1

    print()
    if failures:
        print(f"done with {failures} failure(s)", file=sys.stderr)
        return 1
    print(f"done — mirror up to date under {rel(out_root)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
