# Architecture

The codebase uses a layered organization inspired by domain-driven design. Domain types are separated from JSON transport, and mathematical operations are grouped independently from graph-topology utilities.

The architecture is small enough that its most important property is the actual production data flow.

## Production pipeline

```mermaid
flowchart LR
    A[JSON input] --> B[Main.run_decomposition]
    B --> C[IncomingGraphDto]
    C --> D[Infrastructure.Mappers]
    D --> E[ComputationalGraph]
    E --> F[Gauss: divergence]
    F --> G[Potential: Jacobi solve]
    G --> H[Stokes: residual]
    H --> I[SimulationResult]
    I --> J[Outgoing DTO]
    J --> K[JSON output]
```

`DiscreteMath.DecomposeGraph`, `DiscreteMath.TreePath`, and `Infrastructure.TextParser` are not called by this WASM production path.

## Layer responsibilities

| Area | Modules | Responsibility | Current boundary |
| --- | --- | --- | --- |
| Domain | `Domain.Types` | Node IDs, edge IDs, graphs, and result types. | Types do not enforce every graph invariant. |
| Mathematical pipeline | `ContinuousMath.Gauss`, `Potential`, `Stokes`, `Decomposition` | Divergence, potential approximation, gradient, residual, and result assembly. | Used by production. |
| Graph utilities | `DiscreteMath.DecomposeGraph`, `TreePath` | Spanning-forest classification and undirected path lookup. | Tested but not used by production decomposition. |
| Infrastructure | `Infrastructure.JsonDto`, `Mappers`, `TextParser` | JSON DTOs, mapping, and a separate text syntax. | JSON mapper is used; text parser is not used by WASM. |
| Entry point | `Main` | FFI export, JSON decode/encode, and memory-return boundary. | Production WASM boundary. |

## Domain model

### Identifiers

`NodeIdentifier` and `EdgeIdentifier` are integer-backed newtypes. They improve internal type separation but do not validate uniqueness or range.

### Edge

`InternalEdge` stores:

- `edgeIdentifier`
- `sourceNode`
- `destinationNode`
- `currentFlow`

The source is also represented by the adjacency-map key. `Infrastructure.Mappers` is responsible for keeping those two representations consistent.

### Graph

`ComputationalGraph` is an adjacency map:

```haskell
Map NodeIdentifier [InternalEdge]
```

The map stores outgoing edges under their source node. Empty edge lists preserve isolated nodes supplied by the JSON node array.

### Results

`SimulationResult` contains:

- one `CalculatedNodeResult` per represented node;
- one `CalculatedEdgeResult` per stored edge; and
- `isSystemConservative`.

The edge result has only gradient and residual fields. There is no separate harmonic result type.

## Mathematical pipeline

### 1. Divergence

`ContinuousMath.Gauss.calculateDivergences` initializes represented nodes to zero and folds over every edge. It adds the flow to the source and subtracts it from the target.

### 2. Potential

`ContinuousMath.Potential.solvePotentials`:

- symmetrizes edge topology into a neighbor map;
- initializes potentials to zero;
- fixes the smallest node ID to zero; and
- performs 2000 Jacobi updates.

The iteration count is hard-coded. There is no convergence result type.

### 3. Residual

`ContinuousMath.Stokes.calculateRotationalFlow` calculates, for every edge:

```text
currentFlow - (potential(source) - potential(target))
```

Despite the historical module name, this function does not enumerate cycles or evaluate a face-based Stokes operator.

### 4. Assembly

`ContinuousMath.Decomposition.decompose` joins the divergence, potential, gradient, and residual values into domain result records. It classifies the system as conservative when every edge residual has absolute value below `1e-7`.

## JSON boundary

`Infrastructure.JsonDto` defines the wire field names with manual Aeson instances.

Input DTOs support both `FromJSON` and `ToJSON`. Output DTOs support `ToJSON`. The error object emitted by `Main` is built manually as a JSON string and is not represented by a common response DTO.

`Infrastructure.Mappers.toComputationalGraph` creates an empty adjacency entry for each supplied node and then inserts every edge under its source. It does not perform full semantic validation.

## FFI boundary

`Main.run_decomposition`:

1. reads a `CString`;
2. decodes `IncomingGraphDto`;
3. maps it to `ComputationalGraph`;
4. calls `decompose`;
5. maps the result to an output DTO;
6. encodes JSON; and
7. returns a newly allocated `CString`.

`Main.free_haskell_string` releases the returned allocation.

See [wasm-api.md](wasm-api.md).

## Graph utilities outside production

### `DiscreteMath.DecomposeGraph`

Builds symmetric adjacency and uses breadth-first search to classify stored edge IDs into:

- spanning-forest edges; and
- non-tree edges.

Its output does not currently feed the gradient or residual calculation.

### `DiscreteMath.TreePath`

Finds an undirected path through a supplied tree edge list. Returned edges keep their stored orientation, so callers must infer traversal direction.

### `Infrastructure.TextParser`

Parses repeated expressions of the form:

```text
integer -> integer : number
```

It returns edge tuples and is tested independently. The WASM entry point accepts JSON and does not call this parser.

## Configuration and generated files

`package.yaml` is the intended source of truth for hpack. `Engine.cabal` is generated and should be reviewed after regeneration.

WASM export configuration is duplicated between package configuration and the GitHub Actions workflow. Changes to exported functions must keep these locations synchronized.

`cabal.project` currently uses broad `allow-newer` settings and an Aeson constraint. Reproducible releases should record the package index state or dependency plan used for the build.

## Historical terminology

Several names express the intended physical interpretation more strongly than the current implementation supports:

| Name | Current operation | Documentation guidance |
| --- | --- | --- |
| `ContinuousMath` | Discrete graph operators inspired by continuous vector calculus. | Explain the historical grouping. |
| `Stokes` | Subtract potential gradient from edge flow. | State that no face-based curl is calculated. |
| `rotationalComponent` | Residual after gradient subtraction. | Use “residual” in prose. |
| “DDD” | Layered separation of domain and infrastructure. | Say “inspired by domain-driven design.” |

Renaming is not required immediately. Accurate module comments can preserve compatibility while removing ambiguity.

## Extension points

The current architecture can be extended without moving most modules:

- add graph validation before `toComputationalGraph` or immediately after decoding;
- replace the hard-coded Jacobi loop with a solver configuration and convergence result;
- return numerical residual metrics in `SimulationResult`;
- integrate `DiscreteMath` only if a cycle-basis algorithm becomes part of production;
- add face types and a second boundary operator if a full three-term decomposition is required; and
- add a native CLI as a separate executable rather than overloading the WASM entry point.
