#!/usr/bin/env python3
"""Step 8 — verify the bench in one table: each tool, the version found, the line
expected, and pass/fail. Exits nonzero if any required tool is missing or under its
floor. Reads $BENCH_HOME/.bcs-env for REPO_ROOT/UMBRELLA and the expectations."""
import os, re, shutil, subprocess, sys

def env(k, d=""): return os.environ.get(k, d)

# load .bcs-env (best-effort) so this runs standalone too
envfile = os.path.join(env("BENCH_HOME", os.path.expanduser("~/.bcs-bench")), ".bcs-env")
if os.path.exists(envfile):
    for line in open(envfile):
        m = re.match(r'\s*export\s+(\w+)="?([^"]*)"?', line)
        if m and not os.environ.get(m.group(1)):
            os.environ[m.group(1)] = os.path.expandvars(m.group(2))

REPO_ROOT = env("REPO_ROOT", os.path.expanduser("~/src/fiberfx"))
UMBRELLA  = env("UMBRELLA", os.path.join(REPO_ROOT, "echo"))
GOLINE    = env("GO_VERSION", "1.25")
NODE_MIN  = int(env("NODE_MIN", "22"))
VK_MIN    = int(env("VALKEY_MIN", "8"))

def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=20).stdout.strip() \
            or subprocess.run(cmd, capture_output=True, text=True, timeout=20).stderr.strip()
    except Exception:
        return ""

def find_ver(cmd, pat):
    out = run(cmd)
    m = re.search(pat, out)
    return m.group(1) if m else ""

rows, ok = [], True
def check(name, ver, expect, good, required=True):
    global ok
    status = "ok" if good else ("MISSING" if not ver else "FAIL")
    if required and not good: ok = False
    rows.append((name, ver or "-", expect, status))

gcc = find_ver(["gcc","--version"], r'(\d+\.\d+\.\d+)')
check("gcc", gcc, "any", bool(gcc))

py = find_ver(["python3","--version"], r'(\d+\.\d+\.\d+)')
check("python3", py, "3.x", py.startswith("3."))

go = find_ver([os.path.join(env("GOROOT","/usr/local/go"),"bin","go"),"version"], r'go(\d+\.\d+(?:\.\d+)?)') \
     or find_ver(["go","version"], r'go(\d+\.\d+(?:\.\d+)?)')
check("go", go, f"{GOLINE}.x", go.startswith(GOLINE))

node = find_ver(["node","-v"], r'v(\d+\.\d+\.\d+)')
check("node", node, f">={NODE_MIN}", bool(node) and int(node.split('.')[0]) >= NODE_MIN)

pnpm = find_ver(["pnpm","-v"], r'(\d+\.\d+\.\d+)')
check("pnpm", pnpm, "any", bool(pnpm))

elixir = find_ver(["elixir","--version"], r'Elixir (\d+\.\d+\.\d+)')
check("elixir", elixir, "1.x", bool(elixir))

erl = find_ver(["erl","-eval","io:format(\"~s\",[erlang:system_info(otp_release)]), halt().","-noshell"], r'(\d+)')
check("erlang/otp", erl, "any", bool(erl))

vk = find_ver(["valkey-server","--version"], r'v=(\d+\.\d+\.\d+)')
check("valkey-server", vk, f">={VK_MIN} (9.1)", bool(vk) and int(vk.split('.')[0]) >= VK_MIN)

cli = find_ver(["valkey-cli","--version"], r'(\d+\.\d+\.\d+)') or find_ver(["redis-cli","--version"], r'(\d+\.\d+\.\d+)')
check("valkey-cli", cli, "any", bool(cli))

git = find_ver(["git","--version"], r'(\d+\.\d+\.\d+)')
check("git", git, "any", bool(git))

# repo + deps
has_umbrella = os.path.isfile(os.path.join(UMBRELLA, "mix.exs"))
check("repo (echo/mix.exs)", "present" if has_umbrella else "", REPO_ROOT, has_umbrella)
deps_n = len(os.listdir(os.path.join(UMBRELLA, "deps"))) if os.path.isdir(os.path.join(UMBRELLA, "deps")) else 0
check("umbrella deps", str(deps_n) if deps_n else "", ">0", deps_n > 0)

w = max(len(r[0]) for r in rows)
print("\n== verify ==")
print(f"   {'tool'.ljust(w)}  {'found'.ljust(14)}  {'expect'.ljust(12)}  status")
print(f"   {'-'*w}  {'-'*14}  {'-'*12}  ------")
for n, v, e, s in rows:
    print(f"   {n.ljust(w)}  {v.ljust(14)}  {e.ljust(12)}  {s}")
print("\n   RESULT:", "PASS" if ok else "INCOMPLETE (see FAIL/MISSING above)")
sys.exit(0 if ok else 1)
