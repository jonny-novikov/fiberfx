// bench.ts — contract vectors, the order theorem, perf rows, and the
// Fastify gate demonstrated through inject. Run:
//   node --experimental-strip-types bench.ts
import {
  encode, decode, parse, hash32, unixMs, literal, isBrandedId, inNamespace,
  makeMinter, unwrap,
} from './branded_id.ts';
import { build } from './server.ts';

const assert = (cond: boolean, msg: string) => {
  if (!cond) { console.error(`FAIL: ${msg}`); process.exit(1); }
};

// -------------------------------------------------------- contract vectors
const REF = 274557032793636864n;
assert(unwrap(encode('USR', REF)) === 'USR0KHTOWnGLuC', 'encode vector');
const p = unwrap(parse('USR0NgWEfAEJfs'));
assert(p.ns === 'USR' && p.snow === 320636799581945856n, 'parse vector');
assert(unixMs(320636799581945856n) === 1780512970164, 'unix_ms vector');
assert(hash32(REF) === 234878118, 'hash32 vector');
console.log('contract vectors                : 4/4');

// ------------------------------------------------------------ reject table
const rejects: Array<[string, string]> = [
  ['USRzzzzzzzzzzz', 'range'],
  ['usr0KHTOWnGLuC', 'namespace'],
  ['USR0KHTOWnGLu', 'length'],
  ['USR0KHTOWnGL!C', 'charset'],
];
for (const [bad, want] of rejects) {
  const r = parse(bad);
  assert(!r.ok && r.error === want, `reject ${bad} as ${want}`);
}
console.log('reject table                    : 4/4');

// --------------------------------------------------- order theorem (in TS)
const mint = makeMinter(7);
const snows = Array.from({ length: 2000 }, () => mint());
const ids = snows.map((s) => unwrap(encode('EVT', s)));
const byString = [...ids].sort();
const bySnow = [...ids].sort((a, b) => {
  const x = unwrap(decode(a)); const y = unwrap(decode(b));
  return x < y ? -1 : x > y ? 1 : 0;
});
assert(byString.every((v, i) => v === bySnow[i]), 'order theorem');
console.log('order theorem (string==numeric) : true over 2000 minted ids');

// ------------------------------------------------- functional guard narrow
const mixed: unknown[] = [ids[0], 'CRS0KHTOWnGLuC', 'nope', 42, ids[1]];
const evts = mixed.filter(inNamespace('EVT')); // : BrandedId<'EVT'>[]
assert(evts.length === 2, 'curried guard narrows in filter');
console.log('inNamespace filter narrowing    : 2 of 5');

// --------------------------------------------------------------- perf rows
const bestOf5 = (n: number, f: () => void): number => {
  let best = Infinity;
  for (let r = 0; r < 5; r++) {
    const t0 = process.hrtime.bigint();
    f();
    const ns = Number(process.hrtime.bigint() - t0) / n;
    if (ns < best) best = ns;
  }
  return Math.round(best * 10) / 10;
};
const N = 100_000;
const id = ids[0];
console.log(`encode                          : ${bestOf5(N, () => { for (let i = 0; i < N; i++) encode('EVT', snows[i % 2000]); })} ns/op`);
console.log(`decode                          : ${bestOf5(N, () => { for (let i = 0; i < N; i++) decode(id); })} ns/op`);
console.log(`hash32                          : ${bestOf5(N, () => { for (let i = 0; i < N; i++) hash32(REF + BigInt(i)); })} ns/op`);
console.log(`isBrandedId                     : ${bestOf5(N, () => { for (let i = 0; i < N; i++) isBrandedId(id); })} ns/op`);

// ------------------------------------------------------- the gate, as HTTP
const app = build();
const r200 = await app.inject({ url: '/courses/CRS0KHTOWnGLuC' });
assert(r200.statusCode === 200 && r200.json().mintedAtMs === 1769526697641, 'valid -> 200 + minted instant');
const r400 = await app.inject({ url: '/courses/CRS0KHTOWnGL!C' });
assert(r400.statusCode === 400, 'malformed -> 400 in schema layer');
const rNs = await app.inject({ url: '/courses/USR0KHTOWnGLuC' });
assert(rNs.statusCode === 400, 'wrong namespace -> 400 before handler');
const r404 = await app.inject({ url: `/courses/${unwrap(encode('CRS', REF + 1n))}` });
assert(r404.statusCode === 404, 'valid-but-absent -> 404 from handler');
console.log('inject: valid/malformed/ns/miss : 200 / 400 / 400 / 404');

const M = 5000;
const t0 = process.hrtime.bigint();
for (let i = 0; i < M; i++) await app.inject({ url: '/courses/CRS0KHTOWnGLuC' });
const us = Number(process.hrtime.bigint() - t0) / 1000 / M;
console.log(`inject roundtrip (valid route)  : ${Math.round(us)} us/req (${Math.round(1e6 / us)} req/s single worker)`);
await app.close();
