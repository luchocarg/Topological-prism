# Testing Strategy

The project uses QuickCheck-style property testing plus a small number of deterministic parser checks. This document records what the current tests establish and where their guarantees stop.

## Running the suite

```sh
cabal test Engine-test
```

The test executable is `test/Spec.hs`. It runs suites for infrastructure, generators, graph utilities, mathematical operations, and the end-to-end domain/DTO pipeline.

## Generated graph distribution

`Common.Generators.defaultGenConfig` currently uses:

| Parameter | Value |
| --- | --- |
| Minimum nodes | 2 |
| Maximum nodes | 20 |
| Density | 0.3 |
| Flow range | `[-100, 100]` |

Generation proceeds by:

1. choosing a node count;
2. shuffling nodes and creating a linear spanning tree;
3. adding directed noise edges;
4. assigning random flow values; and
5. building the domain adjacency map.

The generator always creates a weakly connected graph. Tests using only this generator do not establish behavior for disconnected input received through JSON.

The no-multi-edge property rejects duplicate ordered pairs `(u, v)`. It does not reject an antiparallel pair `(u, v)` and `(v, u)`, which becomes repeated adjacency in the symmetrized topology.

## Current property catalog

| Property | What it checks | What it does not independently prove |
| --- | --- | --- |
| `prop_nonTrivial` | Generated graphs have at least two nodes. | That the public API rejects smaller graphs. |
| `prop_edgesAreValid` | Generated destinations belong to the node set. | That external JSON is validated. |
| `prop_isConnected` | Generated topology is weakly connected. | Solver behavior on disconnected graphs. |
| `prop_uniqueEdgeIds` | Generated edge IDs are unique. | Rejection of duplicate external IDs. |
| `prop_noSelfLoops` | Generated graphs contain no self-loops. | Defined behavior when the API receives one. |
| `prop_noMultiEdges` | Generated graphs contain no duplicate ordered pair. | Absence of antiparallel edges in undirected topology. |
| `prop_partitionConservation` | Every edge is returned by tree/cycle classification. | Correct physical decomposition. |
| `prop_disjointSets` | Tree and non-tree ID sets do not overlap. | Orthogonality of flow components. |
| `prop_isSpanningTree` | Connected generated graphs produce `|V|-1` tree edges. | Connectivity and acyclicity as separate assertions. |
| `prop_pathExistence` | A path is found between generated node pairs. | Path uniqueness or behavior on invalid forests. |
| `prop_pathContinuity` | Consecutive returned edges form a traversable chain. | Preservation of a requested orientation. |
| `prop_conservationOfMass` | Global divergence sums to approximately zero. | Local conservation or Poisson convergence. |
| `prop_isSolenoidal` | Residual divergence is below tolerance on generated graphs. | A general convergence bound for arbitrary graph sizes. |
| `prop_gradientConsistency` | Stored gradient equals the stored potential difference. | That the potential solves the Poisson equation. |
| `prop_reversibility` | Gradient plus residual reconstructs each original flow. | Solver accuracy; the identity holds by construction. |
| `prop_mapperRoundtrip` | Current comparator preserves nodes and edge IDs. | Full preservation of endpoint and flow fields. |
| `prop_sourceNodeIntegrity` | Mapper source fields agree with adjacency keys. | Endpoint validity for undeclared targets. |
| `prop_tupleMapperTopology` | Tuple conversion preserves topology and flow under its comparator. | Preservation of original edge IDs, which are regenerated. |
| `prop_parseValidString` | A representative text graph parses. | Complete grammar coverage. |
| `prop_parseWhitespace` | Extra whitespace is accepted. | All numeric formatting cases. |
| `prop_parseInvalidInput` | One invalid phrase is rejected. | Quality or stability of parser error messages. |
| `prop_pipelineStability` | Output DTO conservative flag equals the domain result flag. | Numerical stability or full FFI behavior. |

## Numerical tolerances

Several tests use `1e-9`, while production `isSystemConservative` uses `1e-7`.

These values serve different purposes but are not currently justified in documentation:

- `1e-9` is used for reconstruction, divergence, and potential consistency tests.
- `1e-7` classifies the production result as conservative.

Future changes should state whether tolerances are:

- absolute or relative;
- per node, per edge, or global;
- scale-dependent; and
- expected to remain stable across graph sizes and flow magnitudes.

## Properties that are identities by construction

Two useful smoke checks should not be presented as independent solver validation:

### Reconstruction

`rotational = total - gradient`, so

```text
gradient + rotational = total
```

is expected even if the potential is inaccurate.

### Gradient consistency

`decompose` calculates the edge gradient directly from the same potentials returned in node results. Checking the stored gradient against those potential differences confirms result assembly but not the Poisson equation.

These tests remain useful because they detect mapping and refactoring errors. Their names and documentation should reflect that scope.

## Stronger numerical checks

The following additions would support the mathematical claims more directly.

### Poisson residual

```text
||L phi - divergence||_infinity < epsilon
```

This tests the actual equation solved by Jacobi.

### Residual divergence

```text
||B residual||_infinity < epsilon
```

The current `prop_isSolenoidal` approximates this check. It should report graph size, maximum residual, and seed on failure.

### Orthogonality

```text
abs(dot(gradient, residual)) < epsilon
```

A relative version is preferable when flow scale varies:

```text
abs(dot(g, r)) / max(1, norm(g) * norm(r)) < epsilon
```

### Gauge invariance

Adding a constant to every potential should not change edge gradients.

### Complete mapper equivalence

Compare, for every edge:

- ID;
- source;
- target; and
- flow.

The current roundtrip comparator checks only nodes and edge-ID lists per source.

### Complete spanning-tree property

Test all of:

- `|E_tree| = |V| - 1` for connected inputs;
- every node is reachable;
- no cycle exists; and
- every original edge ID is classified exactly once.

## Deterministic analytic examples

Random generation should be complemented with small fixed graphs:

1. One directed edge with a pure gradient solution.
2. A directed cycle with zero divergence and nonzero residual.
3. A mixed source/sink plus circulation example.
4. A graph with negative flows.
5. A graph with two connected components, documenting current behavior.
6. Invalid empty input.
7. Duplicate node and edge IDs.
8. An edge that references an undeclared target.

Analytic examples make sign errors and gauge misunderstandings easier to diagnose than a large generated counterexample.

## Invalid-input testing

The current generators produce valid graphs, so they cannot verify API rejection behavior. Add a separate set of intentionally invalid DTO generators if semantic validation is introduced.

Each invalid case should assert a stable error code rather than matching a complete human-readable string.

## FFI and WASM integration tests

The current integration test stays inside Haskell domain and DTO functions. It does not allocate WASM memory or call the exported ABI.

A release integration test should:

1. instantiate the built `Engine.wasm`;
2. initialize the Haskell runtime;
3. allocate and copy JSON input;
4. call `run_decomposition`;
5. decode the returned JSON;
6. free the output string;
7. repeat the call to detect lifecycle problems; and
8. exercise malformed input.

See [wasm-api.md](wasm-api.md).

## Documenting a property

Use this template in test documentation:

```markdown
### prop_example

- Generator: connected graphs with 2-20 nodes and flows in [-100, 100].
- Assertion: the infinity norm of the Poisson residual is below 1e-9.
- Tolerance: absolute; chosen for the current flow range and graph size.
- Proves: the configured solver reaches the stated residual on generated data.
- Does not prove: convergence for arbitrary graph sizes or scales.
```

## CI guidance

The native tests should run on pull requests and pushes to the main branch, not only before a manually triggered WASM release. A release workflow may still depend on the successful test job.

For reproducibility, failed QuickCheck output should retain the random seed and minimized counterexample.