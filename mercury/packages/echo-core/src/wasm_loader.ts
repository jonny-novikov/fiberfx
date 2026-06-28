// wasm_loader.ts — raw loader for the contract core compiled to wasm32.
// No wasm-bindgen: the core is no_std with C-ABI exports, so the boundary is
// hand-rolled — ids cross by byte-copy into a static scratch buffer, integers
// cross natively (Node maps wasm i64 to BigInt in both directions).
import { readFileSync } from 'node:fs';

export type WasmCodec = {
  readonly hash32: (snow: bigint) => number;
  readonly decode: (id: string) => bigint;
};

type WasmExports = {
  readonly memory: WebAssembly.Memory;
  readonly scratch_ptr: () => number;
  readonly branded_hash32: (snow: bigint) => number;
  readonly branded_decode: (idPtr: number, len: number, nsPtr: number, snowPtr: number) => void;
};

export const loadWasm = async (path: string): Promise<WasmCodec> => {
  const { instance } = await WebAssembly.instantiate(readFileSync(path));
  const ex = instance.exports as unknown as WasmExports;
  const scratch = ex.scratch_ptr();
  const bytes = new Uint8Array(ex.memory.buffer);
  const view = new DataView(ex.memory.buffer);
  return {
    hash32: (snow: bigint): number => ex.branded_hash32(snow) >>> 0,
    decode: (id: string): bigint => {
      for (let i = 0; i < 14; i++) bytes[scratch + i] = id.charCodeAt(i);
      ex.branded_decode(scratch, 14, scratch + 16, scratch + 24);
      return view.getBigUint64(scratch + 24, true);
    },
  };
};
