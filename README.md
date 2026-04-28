# Hodge-Decomposition Engine

A high-performance Discrete Vector Calculus engine built in Haskell, designed to analyze flow fields on arbitrary graphs through the lens of the **Helmholtz-Hodge Theorem**.

This repository contains the **core mathematical engine** compiled to WebAssembly (WASM), intended to be consumed by external frontend applications.

---

## What does this engine do?

In any network system movement is often a mix of different behaviors. This engine isolates those behaviors by partitioning a total flow field ($F$) into three orthogonal layers:

1.  **Gradient Flow ($\nabla \Phi$):** The "source-to-sink" component. It represents flow driven by potential differences, such as pressure gradients or voltage drops.
2.  **Rotational Flow ($\nabla \times A$):** The "vortex" component. It identifies pure circulation, loops, and feedback cycles within the graph.
3.  **Harmonic Flow:** The "topological" component. This represents flows that are both irrotational and incompressible, typically arising from the global structure of the network.

## Interoperability (JSON API)

The engine communicates using optimized JSON structures via FFI.

### Input Sample
```json
{
  "incomingGraphNodes": [1, 2, 3],
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

### Output Sample
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
    },
    {
      "outgoingNodeResultDivergence": 0,
      "outgoingNodeResultId": 3,
      "outgoingNodeResultPotential": 0
    }
  ]
}
```

---

## Project Structure

The implementation follows **Domain-Driven Design (DDD)**:

* **`src/Domain`**: Pure types and core entities.
* **`src/ContinuousMath`**: Implementation of vector calculus operators.
* **`src/DiscreteMath`**: Graph-theory algorithms.
* **`src/Infrastructure`**: Data handling and serialization.
