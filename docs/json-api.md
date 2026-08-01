# JSON API

This document describes the JSON accepted and returned by `run_decomposition` in the current implementation.

> **Stability:** experimental. Field names and mathematical semantics are not yet covered by a stable-version guarantee.

## Transport

The FFI entry point accepts a pointer to a NUL-terminated JSON string and returns a pointer to a newly allocated NUL-terminated JSON string. Memory ownership is documented in [wasm-api.md](wasm-api.md).

This page describes the JSON payload after it has been copied into or out of WASM memory.

## Input object

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

### Graph fields

| Field | JSON type | Required | Meaning |
| --- | --- | --- | --- |
| `incomingGraphNodes` | array of integers | yes | Identifiers of nodes represented in the graph. |
| `incomingGraphEdges` | array of edge objects | yes | Oriented edges and their signed flows. |

### Edge fields

| Field | JSON type | Required | Meaning |
| --- | --- | --- | --- |
| `incomingEdgeId` | integer | yes | Global edge identifier. |
| `incomingEdgeFrom` | integer | yes | Source under the stored orientation. |
| `incomingEdgeTo` | integer | yes | Target under the stored orientation. |
| `incomingEdgeFlow` | number | yes | Signed scalar flow. |

## Required semantic invariants

The JSON decoder checks field presence and JSON types, but the current API boundary does not validate every graph invariant. Callers should enforce:

1. `incomingGraphNodes` is non-empty.
2. Node identifiers are unique.
3. Edge identifiers are globally unique.
4. Every `incomingEdgeFrom` belongs to `incomingGraphNodes`.
5. Every `incomingEdgeTo` belongs to `incomingGraphNodes`.
6. Flow values are finite.

Duplicate edge identifiers are especially unsafe because internal residual results are stored in a map keyed by edge identifier. A later value can replace an earlier value.

## Orientation and negative flows

For an edge stored as `u -> v`:

- a positive flow contributes positively to divergence at `u` and negatively at `v`;
- a negative flow represents effective movement from `v` to `u`; and
- the reported gradient is `potential(u) - potential(v)`.

See [mathematics.md](mathematics.md).

## Output object

A successful response contains node results, edge results, and a conservative classification:

```json
{
  "outgoingSimulationResultNodes": [],
  "outgoingSimulationResultEdges": [],
  "outgoingSimulationResultIsConservative": false
}
```

### Node result fields

| Field | JSON type | Meaning |
| --- | --- | --- |
| `outgoingNodeResultId` | integer | Original node identifier. |
| `outgoingNodeResultDivergence` | number | Outgoing flow minus incoming flow. |
| `outgoingNodeResultPotential` | number | Approximate node potential. Only differences are gauge-invariant. |

### Edge result fields

| Field | JSON type | Meaning |
| --- | --- | --- |
| `outgoingEdgeResultId` | integer | Original edge identifier. |
| `outgoingEdgeResultSource` | integer | Stored source node. |
| `outgoingEdgeResultTarget` | integer | Stored target node. |
| `outgoingEdgeResultGradient` | number | `potential(source) - potential(target)`. |
| `outgoingEdgeResultRotational` | number | `original flow - gradient`; currently a residual, not a separately computed harmonic term. |

### Simulation field

| Field | JSON type | Meaning |
| --- | --- | --- |
| `outgoingSimulationResultIsConservative` | boolean | True when the absolute residual on every edge is less than `1e-7`. |

The conservative flag uses a per-edge threshold. It is not a global vector norm and does not report Poisson convergence.

## Complete conservative example

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

## Complete circulation example

Input:

```json
{
  "incomingGraphNodes": [1, 2, 3],
  "incomingGraphEdges": [
    {
      "incomingEdgeId": 1,
      "incomingEdgeFrom": 1,
      "incomingEdgeTo": 2,
      "incomingEdgeFlow": 4
    },
    {
      "incomingEdgeId": 2,
      "incomingEdgeFrom": 2,
      "incomingEdgeTo": 3,
      "incomingEdgeFlow": 4
    },
    {
      "incomingEdgeId": 3,
      "incomingEdgeFrom": 3,
      "incomingEdgeTo": 1,
      "incomingEdgeFlow": 4
    }
  ]
}
```

The expected mathematical result is zero divergence and zero gradient on every edge, leaving a residual of `4` on every edge. The conservative flag is therefore false.

## Decode errors

Malformed JSON, absent required fields, or fields with incompatible JSON types are intended to return an object containing `error`:

```json
{
  "error": "failed to decode JSON. Error: ..."
}
```

Consumers must check for `error` before treating the response as `OutgoingSimulationResultDto`.

However, the implementation constructs this response by concatenating the decoder message into a JSON string without JSON escaping. Decoder messages can contain quotes, backslashes, or other characters that make the resulting payload invalid JSON. Host code must therefore be prepared for `JSON.parse` to fail on an error response.

The error response is not currently a tagged union with the success response. It has no stable machine-readable error code. A future implementation should encode a typed error DTO with Aeson rather than assembling JSON text manually.

## Failures not converted to JSON errors

The current entry point only converts Aeson decode failures into an error object. It does not catch every runtime or semantic failure. Examples include:

- an empty graph reaching the potential solver;
- inconsistent node references;
- duplicate identifiers causing ambiguous internal maps; and
- unexpected numerical behavior.

Validate input before invoking the engine and treat WASM traps or missing output as separate failure modes.

## Ordering

Consumers should identify nodes and edges by ID rather than array position. Current ordering follows internal map traversal and implementation details; it is not declared part of the API contract.

## Self-loops, parallel edges, and disconnected graphs

The decoder does not reject these structures. Their stable mathematical semantics have not been specified:

- **Self-loops:** accepted structurally, but their divergence cancels and their gradient is zero.
- **Parallel edges:** accepted when IDs differ; repeated neighbor entries affect the effective multigraph Laplacian.
- **Antiparallel edges:** accepted as distinct oriented edges.
- **Disconnected graphs:** accepted by decoding, but the current solver fixes only one global gauge.
- **Isolated nodes:** represented in output with zero divergence and usually zero potential, subject to solver behavior.
