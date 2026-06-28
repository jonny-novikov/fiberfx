// @echo/core — the branded-id contract, TypeScript-first.
//
// A dependency-free package: the pure branded-id codec (parse/encode/decode,
// the nominal `BrandedId` type, minting and the order/time helpers). The raw
// wasm loader ships in the package but stays off the default surface — import
// `@echo/core/src/wasm_loader.js` directly where the Rust-backed codec is
// wanted, so consumers don't pull host (WebAssembly) lib types they don't use.
export * from "./branded_id.js";
