// wasm_bench.ts — the wasm question, measured: the same two operations in
// pure TypeScript and through the wasm boundary, after parity is proven.
//   node --experimental-strip-types wasm_bench.ts
import { hash32, decode, unwrap } from './branded_id.ts';
import { loadWasm } from './wasm_loader.ts';

const wasm = await loadWasm('./branded.wasm');
const REF = 274557032793636864n;
const ID = 'USR0NgWEfAEJfs';

// parity first: both paths must agree with the contract vectors
if (wasm.hash32(REF) !== 234878118) throw new Error('wasm hash32 parity');
if (wasm.decode(ID) !== 320636799581945856n) throw new Error('wasm decode parity');
if (hash32(REF) !== wasm.hash32(REF)) throw new Error('cross parity hash32');
if (unwrap(decode(ID)) !== wasm.decode(ID)) throw new Error('cross parity decode');
console.log('parity (ts == wasm == vectors)  : 4/4');

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

console.log(`hash32 pure TS (BigInt fmix)    : ${bestOf5(N, () => { for (let i = 0; i < N; i++) hash32(REF + BigInt(i)); })} ns/op`);
console.log(`hash32 wasm (i64 crossing)      : ${bestOf5(N, () => { for (let i = 0; i < N; i++) wasm.hash32(REF + BigInt(i)); })} ns/op`);
console.log(`decode pure TS                  : ${bestOf5(N, () => { for (let i = 0; i < N; i++) decode(ID); })} ns/op`);
console.log(`decode wasm (string crossing)   : ${bestOf5(N, () => { for (let i = 0; i < N; i++) wasm.decode(ID); })} ns/op`);
