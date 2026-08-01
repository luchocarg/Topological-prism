# Hodge-Decomposition Engine

Experimental Haskell and WebAssembly engine for decomposing oriented scalar flows on unweighted graphs.

The current implementation solves a graph Poisson equation for a node potential and decomposes every edge flow into:

1. a gradient component, `potential(source) - potential(target)`; and
2. a residual, `total flow - gradient component`, intended to be divergence-free up to numerical error.

> **Status:** experimental (`0.1.0.0`). The JSON API and numerical behavior may change during the `0.x` series.

## Mathematical scope

This release implements a two-term decomposition. It does **not** define graph faces, compute a face-based curl, or return a separate harmonic component. The JSON field named `outgoingEdgeResultRotational` contains the residual after subtracting the gradient component.

For an oriented graph with incidence matrix `B` and edge-flow vector `f`, the intended calculation is

```text
divergence = B f
L potential ≈ divergence, where L = B Bᵀ
gradient = Bᵀ potential
residual = f - gradient
```

See [docs/mathematics.md](docs/mathematics.md) for sign conventions, gauge fixing, numerical approximation, and the distinction between the current residual and a full three-term Hodge decomposition.

## Current status

| Capability | Status |
| --- | --- |
| Native Haskell library | Available |
| Property-based test suite | Available |
| WASI reactor build | Available through the GitHub Actions workflow |
| JSON transport | Available, but not yet declared stable |
| Semantic input validation | Incomplete |
| Separate harmonic component | Not implemented |
| Adaptive convergence criterion | Not implemented |
| Published benchmark suite | Not available |

## Requirements

The native CI configuration is tested with:

- GHC 9.4
- Cabal 3.10

The WebAssembly artifact is built with the GHC WASM toolchain as a WASI reactor.

## Build and test

```sh
cabal update
cabal build all
cabal test Engine-test
```

The native executable currently has an empty `main` and is not a command-line graph processor. The primary integration target is the exported WASM API.

`Engine.cabal` is generated from `package.yaml` with hpack. Contributors should treat `package.yaml` as the source of truth and regenerate the Cabal file after changing package configuration.

## JSON example

Input:

```json
{
  "incomingGraphNodes": [1, 2],
  "incomingGraphEdges": [
    {
      "incomingEdgeId": 1,
      "incomingEdgeFrom": 1,
      "incomingEdgeTo": 2,
      "incomingEdgeFlow": 10.5
    }
  ]
}
```

Representative output:

```json
{
  "outgoingSimulationResultEdges": [
    {
      "outgoingEdgeResultGradient": 10.5,
      "outgoingEdgeResultId": 1,
      "outgoingEdgeResultRotational": 0,
      "outgoingEdgeResultSource": 1,
      "outgoingEdgeResultTarget": 2
    }
  ],
  "outgoingSimulationResultIsConservative": true,
  "outgoingSimulationResultNodes": [
    {
      "outgoingNodeResultDivergence": 10.5,
      "outgoingNodeResultId": 1,
      "outgoingNodeResultPotential": 0
    },
    {
      "outgoingNodeResultDivergence": -10.5,
      "outgoingNodeResultId": 2,
      "outgoingNodeResultPotential": -10.5
    }
  ]
}
```

Edge orientation defines the sign convention. A positive flow travels from `incomingEdgeFrom` to `incomingEdgeTo`; a negative value represents effective flow in the opposite direction.

Callers should currently enforce these invariants before invoking the engine:

- the node list is non-empty;
- node identifiers are unique;
- edge identifiers are globally unique; and
- every edge endpoint occurs in `incomingGraphNodes`.

The implementation does not validate every invariant at the API boundary. Decode failures also use a manually constructed error string that is not guaranteed to remain valid JSON when the decoder message contains characters requiring escaping. See [docs/json-api.md](docs/json-api.md) and [docs/limitations.md](docs/limitations.md).

## WebAssembly ABI

The module is intended to export:

- `run_decomposition(inputPtr) -> outputPtr`
- `free_haskell_string(outputPtr)`
- runtime and allocation symbols required by the host integration

The input is a NUL-terminated JSON string in WASM linear memory. The returned string must be copied by the host and released exactly once with `free_haskell_string`.

Initialization and allocation details depend on the GHC/WASI host loader. See [docs/wasm-api.md](docs/wasm-api.md) before integrating the artifact.

## Numerical method

The graph topology is symmetrized when constructing the unweighted Laplacian. The node with the smallest identifier is fixed to potential zero. The current solver performs exactly 2000 Jacobi iterations and does not expose an adaptive stopping criterion or convergence residual.

`outgoingSimulationResultIsConservative` is true when the absolute residual on every edge is smaller than `1e-7`. This is a per-edge classification, not a global error norm.

## Architecture

- `src/Domain`: internal graph and result types.
- `src/ContinuousMath`: divergence, potential solve, gradient, and residual.
- `src/DiscreteMath`: spanning-forest and path utilities; not used by the current production decomposition pipeline.
- `src/Infrastructure`: JSON DTOs, mapping, and text parsing.
- `src/Main.hs`: FFI boundary and JSON pipeline.

See [docs/architecture.md](docs/architecture.md) for the complete data flow.

## Documentation

- [Mathematical model](docs/mathematics.md)
- [JSON API](docs/json-api.md)
- [WASM and FFI API](docs/wasm-api.md)
- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Known limitations](docs/limitations.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
