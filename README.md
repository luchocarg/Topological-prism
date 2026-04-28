# Hodge-Decomposition Engine (WASM Core)

High-performance Discrete Vector Calculus engine in Haskell.

## Build
```bash
wasm32-wasi-ghc src/Main.hs -o Engine.wasm -no-hs-main -optl-Wl,--export=run_decomposition -optl-Wl,--export=free_haskell_string -optl-Wl,--export=hs_init -optl-Wl,--export=malloc -optl-Wl,--export=free
```

## Exports
- `run_decomposition(CString) -> CString`: Main logic.
- `free_haskell_string(CString) -> void`: Memory management.

## CI/CD
GitHub Actions automatically tests and compiles the WASM binary on push. Artifacts are available in the Actions tab.