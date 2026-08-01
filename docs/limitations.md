# Known Limitations

This document describes limitations of the current `0.1.0.0` implementation. It is part of the user contract: callers should review it before treating the engine as production-ready or as a complete Helmholtz-Hodge implementation.

## Stability

The project is experimental.

- JSON field names may change during the `0.x` series.
- Numerical behavior is not covered by a stable tolerance guarantee.
- WASM initialization and host integration do not yet have a canonical wrapper.
- There is no documented compatibility matrix across GHC WASM versions.

## Mathematical scope

### Two terms, not three

The engine returns:

```text
flow = gradient + residual
```

It does not return separate gradient, curl, and harmonic terms.

### No graph faces

The domain model contains nodes and edges but no faces or higher-dimensional cells. There is no second boundary operator and no face-based discrete curl.

### Historical `rotational` name

`rotationalComponent` is calculated as `total - gradient`. If the Poisson solve is sufficiently accurate, this residual is approximately divergence-free. It is not independently computed from cycles or faces and may combine modes that a richer Hodge decomposition would separate.

### Unweighted topology

Edge flow values are data being decomposed; they are not conductance, length, area, or Laplacian weights. The potential solver uses degree counts in a symmetrized unweighted topology.

### No explicit residual metrics

The engine does not return:

- `||L phi - divergence||`;
- `||B residual||`;
- `dot(gradient, residual)`; or
- iteration/convergence status.

Consumers cannot determine solver accuracy from `isSystemConservative` alone.

## Numerical solver

### Fixed iteration count

The Jacobi solver always runs 2000 iterations. There is no early stopping, maximum residual target, or caller-provided configuration.

### Convergence is not guaranteed for arbitrary input

Jacobi behavior depends on the matrix and graph structure. The current test generator covers connected graphs of limited size and flow range; it does not establish a general convergence theorem or bound.

### Absolute gauge

The node with the smallest identifier is fixed to potential zero. Absolute potential values therefore depend on identifier choice, while edge differences do not.

### Disconnected graphs

Only one global node is fixed. A disconnected graph normally has an independent additive degree of freedom per component. Decoding accepts disconnected graphs, but their convergence and gauge behavior are not part of the stable contract.

### Floating-point scale

All flows and potentials use `Double`. Tolerances are absolute. Very large or very small flow magnitudes may require scale-aware error criteria that are not currently implemented.

## Input validation

The JSON decoder validates syntax, required field names, and field types. It does not provide complete semantic validation.

### Empty graph

An empty node map reaches `Map.findMin` in the potential solver and can cause a runtime failure rather than a JSON error. Treat an empty node list as invalid.

### Duplicate node IDs

The adjacency map collapses duplicate node identifiers. The API does not report the duplication.

### Duplicate edge IDs

Residual values are stored in a map keyed by edge ID. Duplicate IDs can overwrite one another and cause incorrect association between edges and residuals. Callers must enforce global uniqueness.

### Unknown endpoints

The mapper does not reject an edge whose target is absent from `incomingGraphNodes`. Divergence may contain an entry for that target while potentials and output nodes are derived from a different node set.

An undeclared source may be inserted into the adjacency map by edge insertion, producing another inconsistent interpretation.

### Non-finite numbers

The stable handling of NaN and infinities is not documented. Callers should allow only finite JSON numbers.

### Self-loops

Self-loops are not rejected by the JSON boundary. Their divergence contribution cancels at the same node and their potential difference is zero, leaving their full flow in the residual. This behavior has not been declared a supported physical model.

### Parallel and antiparallel edges

Distinct edge IDs allow multiple stored edges between the same nodes. Symmetrization includes each stored edge in the neighbor list, so they act as repeated unweighted connections. This may be appropriate for a multigraph but is not explicitly configurable.

## JSON response model

### Error response is structurally separate

Decode failures return:

```json
{ "error": "failed to decode JSON. Error: ..." }
```

Success responses use a different DTO. There is no shared `ok` discriminant or machine-readable error code.

### Decoder messages are not JSON-escaped

The error payload is assembled by concatenating the Aeson decoder message into a quoted JSON string. If that message contains quotes, backslashes, or other characters requiring escaping, the returned text may not be valid JSON. A consumer can therefore encounter a JSON parse failure while handling an input decode failure.

The implementation should eventually represent errors as a typed value and call Aeson `encode` for both success and failure responses.

### Runtime failures are not caught

Only JSON decode errors are converted into the error object. Semantic failures and exceptions can escape the function or trap the WASM instance.

### Array ordering is not stable

Current ordering derives from internal maps and list construction. Consumers should use IDs rather than array indexes.

### Conservative flag is narrow

`isSystemConservative` is true when every edge residual is below `1e-7` in absolute value. It does not measure:

- total residual energy;
- Poisson error;
- divergence of the residual; or
- relative error with respect to input scale.

## WASM and FFI

### No canonical host wrapper

The repository exports low-level pointer functions but does not include a tested JavaScript or TypeScript package that manages runtime initialization and memory.

### Toolchain-dependent initialization

Correct Haskell RTS initialization depends on the GHC WASM toolchain and host loader. The workflow alone does not define a portable consumer API.

### String encoding is not specified

The code crosses `CString`, Haskell `String`, and `ByteString.Char8`. The input schema currently contains numeric graph data and ASCII keys, but arbitrary Unicode behavior is not guaranteed.

### Reentrancy is unspecified

The repository does not claim that overlapping calls on one WASM instance are safe. Serialize calls until reentrancy is tested.

### Memory leaks depend on the host

Every returned output pointer must be released with `free_haskell_string`. A host that forgets this call leaks linear memory.

## Native executable

`main` currently returns immediately. There is no native CLI despite the presence of a text parser. `cabal run Engine` does not process graph input.

## Architecture

### `DiscreteMath` is not in the production decomposition

The spanning-tree and path modules are tested separately but are not called by `ContinuousMath.Decomposition.decompose`. Documentation must not imply that tree/cycle classification produces current API components.

### Text parser is not in the WASM pipeline

`Infrastructure.TextParser` parses a small textual edge language. The exported entry point accepts JSON and never calls it.

### Generated configuration can drift

`Engine.cabal` is generated from `package.yaml`, while WASM flags are also stated in the workflow. These sources can become inconsistent if changes are not regenerated and reviewed together.

## Testing limitations

### Valid generators do not test rejection

The main graph generator creates valid, connected inputs. It cannot show that invalid JSON graphs are rejected safely.

### Some properties hold by construction

Reconstruction and gradient consistency confirm assembly but do not independently validate the potential solver.

### Roundtrip comparison is partial

The current graph equivalence helper used by the mapper roundtrip test compares node sets and edge IDs per source, not every destination and flow value.

### Integration test does not invoke WASM

`MainSpec` exercises DTO and domain functions inside Haskell. It does not test linear memory, runtime initialization, exported symbols, or output deallocation.

See [testing.md](testing.md).

## Performance

The repository contains no benchmark suite and no published measurements. Avoid describing the engine as high-performance until benchmarks record:

- graph size and density;
- iteration count;
- native and WASM toolchains;
- optimization flags;
- host platform; and
- timing and memory methodology.

## Licensing and citation

The reviewed snapshot does not include a license or citation file. Until a license is chosen, third-party reuse rights are unclear. Do not infer a license from repository visibility.

## Recommended caller mitigations

Until the limitations are addressed, callers should:

1. validate all identifiers and endpoints;
2. reject empty and disconnected graphs unless explicitly tested;
3. require finite flows;
4. use IDs rather than response order;
5. treat the rotational field as a residual;
6. record the engine version with results;
7. serialize calls per WASM instance;
8. always free returned strings; and
9. perform independent numerical checks when results are used for research conclusions.