#!/usr/bin/env python3
"""Step 10 (MANDATORY) — generate the bootstrap developer-environment report.

Reads $BENCH_HOME/.bcs-env, probes every tool, inspects the fiberfx checkout,
the fetched deps and the compiled umbrella, embeds the boot-smoke output, and
writes a single Markdown report. Run last in the bootstrap; the file it writes
is the deliverable that gets attached.

    report.py [--out PATH] [--smoke FILE]

--out    where to write the report  (default: $BENCH_HOME/bootstrap-report.md)
--smoke  a boot-smoke log to embed   (default: $BENCH_HOME/smoke.log)
"""
import os, re, shutil, subprocess, sys, datetime, argparse

def env(name, default=""):
    return os.environ.get(name, default)

def load_bcs_env():
    path = os.path.join(env("BENCH_HOME", os.path.expanduser("~/.bcs-bench")), ".bcs-env")
    if os.path.isfile(path):
        for line in open(path):
            m = re.match(r'\s*export\s+([A-Z0-9_]+)="?(.*?)"?\s*$', line)
            if m:
                os.environ.setdefault(m.group(1), m.group(2).replace("$GOROOT", env("GOROOT", "/usr/local/go")))

def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=30).stdout.strip()
    except Exception:
        return ""

def ver_at_least(found, minimum):
    def parts(s): return [int(x) for x in re.findall(r"\d+", s)[:3]]
    try:
        return parts(found) >= parts(minimum)
    except Exception:
        return False

def probe():
    otp = run(["erl", "-eval", "io:format('~s',[erlang:system_info(otp_release)]),halt()", "-noshell"])
    rows = [
        ("gcc",           run(["gcc", "-dumpfullversion"]),                          "any",                            None),
        ("python3",       run(["python3", "--version"]).replace("Python", "").strip(), "3.x",                          None),
        ("go",            run(["go", "version"]).replace("go version go", "").split()[0] if run(["go", "version"]) else "", env("GO_VERSION", "1.25") + ".x", env("GO_VERSION", "1.25")),
        ("node",          run(["node", "--version"]).lstrip("v"),                     ">=" + env("NODE_MIN", "22"),     env("NODE_MIN", "22")),
        ("corepack",      run(["corepack", "--version"]),                             "any",                            None),
        ("pnpm",          run(["pnpm", "--version"]),                                 "any",                            None),
        ("elixir",        (re.search(r"Elixir (\d+\.\d+\.\d+)", run(["elixir", "--version"])) or [None, ""])[1] if run(["elixir", "--version"]) else "", ">=" + env("ELIXIR_MIN", "1.15") + " (pin " + env("ELIXIR_PIN", "1.18.4") + ")", env("ELIXIR_MIN", "1.15")),
        ("erlang/otp",    otp,                                                        ">=" + env("OTP_MIN", "25"),      env("OTP_MIN", "25")),
        ("rebar3",        run(["rebar3", "version"]).replace("rebar ", "").split(" on")[0] if run(["rebar3", "version"]) else "", "any", None),
        ("valkey-server", run(["valkey-server", "--version"]).split("v=")[-1].split()[0] if "v=" in run(["valkey-server", "--version"]) else "", ">=" + env("VALKEY_MIN", "8") + " (prefer " + env("VALKEY_PREFERRED", "9") + ".x)", env("VALKEY_MIN", "8")),
        ("valkey-cli",    run(["valkey-cli", "--version"]).split()[1] if run(["valkey-cli", "--version"]) else "", "any", None),
        ("git",           run(["git", "--version"]).replace("git version", "").strip(), "any",                          None),
        ("postgres",      (run(["psql", "--version"]).split()[-1].rstrip(")") if run(["psql", "--version"]) else ""), "any",        None),
    ]
    out = []
    for name, found, expect, minimum in rows:
        if not found:
            status = "MISSING"
        elif minimum and not ver_at_least(found, minimum):
            status = "FAIL"
        else:
            status = "ok"
        out.append((name, found or "-", expect, status))
    return out

def repo_facts():
    root = env("REPO_ROOT")
    umb = env("UMBRELLA", os.path.join(root, "echo"))
    facts = {"root": root, "umbrella": umb, "branch": "", "head": "", "apps": [], "deps": 0, "compiled": []}
    if os.path.isdir(os.path.join(root, ".git")):
        facts["branch"] = run(["git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD"])
        facts["head"] = run(["git", "-C", root, "rev-parse", "--short", "HEAD"])
    apps_dir = os.path.join(umb, "apps")
    if os.path.isdir(apps_dir):
        facts["apps"] = sorted(d for d in os.listdir(apps_dir) if os.path.isdir(os.path.join(apps_dir, d)))
    deps_dir = os.path.join(umb, "deps")
    if os.path.isdir(deps_dir):
        facts["deps"] = len([d for d in os.listdir(deps_dir) if os.path.isdir(os.path.join(deps_dir, d))])
    build = os.path.join(umb, "_build", "dev", "lib")
    if os.path.isdir(build):
        facts["compiled"] = sorted(d for d in os.listdir(build)
                                   if os.path.isdir(os.path.join(build, d, "ebin")))
    return facts

def resolutions():
    notes = []
    exv = (re.search(r"Elixir (\d+\.\d+\.\d+)", run(["elixir", "--version"])) or [None, ""])[1]
    pin = env("ELIXIR_PIN", "1.18.4"); mn = env("ELIXIR_MIN", "1.15")
    if exv:
        if ver_at_least(exv, pin):
            notes.append(f"Elixir {exv} satisfies the pin ({pin}).")
        elif ver_at_least(exv, mn):
            notes.append(f"Elixir {exv} meets the {mn} floor (postgrex 0.22 needs >= 1.15).")
        else:
            notes.append(f"Elixir {exv} is BELOW the {mn} floor — postgrex 0.22 will not compile; install the pinned {pin}.")
    for d in sorted(os.listdir("/opt")) if os.path.isdir("/opt") else []:
        if d.startswith("elixir-"):
            notes.append(f"Pinned Elixir installed precompiled at /opt/{d} (runs on the existing OTP; no OTP rebuild).")
    mr = env("MIX_REBAR3")
    if mr:
        notes.append(f"rebar3 wired via MIX_REBAR3={mr} (Erlang deps: telemetry, yamerl).")
    if os.path.isdir(os.path.join(env("BENCH_HOME", ""), "hexmirror")):
        notes.append("Hex offline mirror was used (egress proxy reset Erlang's client to repo.hex.pm; curl-fetched bytes served locally).")
    return notes

def smoke_lines(path):
    if path and os.path.isfile(path):
        return [l.rstrip() for l in open(path) if l.startswith(">>")]
    return []

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out")
    ap.add_argument("--smoke")
    ap.add_argument("--e2e")
    a = ap.parse_args()
    load_bcs_env()
    out = a.out or os.path.join(env("BENCH_HOME", os.path.expanduser("~/.bcs-bench")), "bootstrap-report.md")
    smoke = a.smoke or os.path.join(env("BENCH_HOME", os.path.expanduser("~/.bcs-bench")), "smoke.log")
    e2e = a.e2e or os.path.join(env("BENCH_HOME", os.path.expanduser("~/.bcs-bench")), "e2e.log")

    tools = probe()
    facts = repo_facts()
    smk = smoke_lines(smoke)
    e2e_lines = smoke_lines(e2e)
    vk_alloc = ""
    vk_info = run(["valkey-cli", "-p", "6390", "INFO", "memory"])
    m = re.search(r"mem_allocator:([^\r\n]+)", vk_info)
    if m:
        vk_alloc = m.group(1).strip()
    vk_ver = ""
    vs = run(["valkey-server", "--version"])
    mv = re.search(r"v=([0-9.]+)", vs)
    if mv:
        vk_ver = mv.group(1)

    required = {"gcc", "python3", "go", "node", "pnpm", "elixir", "erlang/otp", "valkey-server", "postgres", "git"}
    tool_ok = all(s == "ok" for n, f, e, s in tools if n in required)
    result = "PASS" if (tool_ok and facts["deps"] > 0 and facts["compiled"]) else "INCOMPLETE"

    host = run(["uname", "-sr"])
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    L = []
    L.append("# Bootstrap Report — codemojex / fiberfx@echo_mq")
    L.append("")
    L.append(f"Generated **{ts}** · host `{host}` · result **{result}**")
    L.append("")
    L.append("## Toolchain")
    L.append("")
    L.append("| tool | found | expected | status |")
    L.append("|------|-------|----------|--------|")
    for n, f, e, s in tools:
        L.append(f"| {n} | `{f}` | {e} | {s} |")
    L.append("")
    L.append("## Repository")
    L.append("")
    L.append(f"- Path: `{facts['root']}`")
    L.append(f"- Branch / HEAD: `{facts['branch'] or '?'}` / `{facts['head'] or '?'}`")
    L.append(f"- Umbrella: `{facts['umbrella']}`")
    if facts["apps"]:
        L.append(f"- Apps ({len(facts['apps'])}): {', '.join('`'+x+'`' for x in facts['apps'])}")
    L.append("")
    L.append("## Dependencies & compile")
    L.append("")
    L.append(f"- `mix deps.get`: **{facts['deps']}** packages under `deps/`")
    L.append(f"- `mix compile`: **{len(facts['compiled'])}** built libs in `_build/dev/lib`")
    if facts["compiled"]:
        umbrella_apps = [a for a in facts["compiled"] if a in set(facts["apps"])]
        if umbrella_apps:
            L.append(f"- Umbrella apps compiled: {', '.join('`'+x+'`' for x in umbrella_apps)}")
    L.append("")
    L.append("## Boot smoke (no Postgres / Valkey)")
    L.append("")
    if smk:
        L.append("```text")
        L.extend(smk)
        L.append("```")
    else:
        L.append("_(no smoke log found — run boot_smoke.sh)_")
    L.append("")
    L.append("## Services")
    L.append("")
    L.append(f"- **Valkey** {vk_ver or '?'} built from source on `:6390`" + (f" · allocator `{vk_alloc}`" if vk_alloc else ""))
    L.append("- **PostgreSQL** on `:5432` (dev role `postgres`/`postgres`, db `codemojex_dev`)")
    L.append("")
    L.append("## Boot e2e (live Postgres + Valkey)")
    L.append("")
    if e2e_lines:
        L.append("```text")
        L.extend(e2e_lines)
        L.append("```")
    else:
        L.append("_(no e2e log found — run e2e.sh)_")
    L.append("")
    L.append("## Notes & resolutions")
    L.append("")
    notes = resolutions()
    if notes:
        for n in notes:
            L.append(f"- {n}")
    else:
        L.append("- (none)")
    L.append("")
    L.append(f"## Result: {result}")
    L.append("")
    if result != "PASS":
        L.append("One or more required rows are FAIL/MISSING, or deps/compile are absent. See the table above.")

    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    open(out, "w").write("\n".join(L) + "\n")
    print(f"wrote {out}  (result: {result})")

if __name__ == "__main__":
    main()
