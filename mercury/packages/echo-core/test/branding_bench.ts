import { encode, unwrap } from './branded_id.ts';

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

const N = 200_000;
const base = 274557032793636864n;
let sink = 0;

const b = bestOf5(N, () => {
  for (let i = 0; i < N; i++) {
    const id = unwrap(encode('USR', base + BigInt(i & 0xfffff)));
    sink += id.length;
  }
});
console.log(`node branded ns/op=${b}`);

const d = bestOf5(N, () => {
  for (let i = 0; i < N; i++) {
    const s = (base + BigInt(i & 0xfffff)).toString();
    sink += s.length;
  }
});
console.log(`node decimal ns/op=${d}`);
if (sink === 0) console.log('sink');
