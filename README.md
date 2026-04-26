# Hodge-Decomposition Engine

A high-performance Discrete Vector Calculus engine built in Haskell, designed to analyze flow fields on arbitrary graphs through the lens of the **Helmholtz-Hodge Theorem**.

This engine decomposes complex network flows into their fundamental physical components: **gradient** (potential-driven), **rotational** (circulatory), and **harmonic** (topological) flows.

---

## What does this engine do?

In any network system movement is often a mix of different behaviors. This engine isolates those behaviors by partitioning a total flow field ($F$) into three orthogonal layers:

1.  **Gradient Flow ($\nabla \Phi$):** The "source-to-sink" component. It represents flow driven by potential differences, such as pressure gradients or voltage drops.
2.  **Rotational Flow ($\nabla \times A$):** The "vortex" component. It identifies pure circulation, loops, and feedback cycles within the graph.
3.  **Harmonic Flow:** The "topological" component. This represents flows that are both irrotational and incompressible, typically arising from the global structure of the network.



---

## Project Structure

The implementation follows **Domain-Driven Design (DDD)** to ensure mathematical rigor and separation of concerns:

* **`Domain`**: Pure types and core entities. Logic-heavy with zero external dependencies.
* **`ContinuousMath`**: Implementation of vector calculus operators (Divergence, Gradient, Laplacian).
* **`DiscreteMath`**: Graph-theory algorithms, including cycle detection and pathfinding.
* **`Infrastructure`**: Data handling, DTO mapping, and serialization.
* **`FFI / WASM`**: High-performance interoperability layer for Web and Node.js environments.

---

## Getting Started

### Prerequisites
* **GHC 9.x+**
* **Cabal 3.x+**

### Build and Test
The engine uses **QuickCheck** for property-based testing to verify that mathematical axioms hold true across all graph topologies.

```bash
# Build the project
cabal build

# Run verification tests
cabal test
```

### WebAssembly Support
Optimized for the GHC WASM backend:
```bash
ghc-wasm-fallback Main.hs -o Engine.wasm
```

---

## Interoperability (JSON API)

The engine exposes a C-Call interface for FFI. It communicates using optimized JSON structures.

**Input Sample:**
```json
{
  "nodes": [1, 2, 3],
  "edges": [
    {"id": 1, "from": 1, "to": 2, "flow": 10.5},
    {"id": 2, "from": 2, "to": 3, "flow": -5.0}
  ]
}
```

**Output Sample:**
```json
{
  "nodes": [{"id": 1, "divergence": 10.5, "potential": 0.0}],
  "edges": [{"id": 1, "gradient": 8.2, "rotational": 2.3}],
  "is_conservative": false
}
```

---

## Documentation

For deep dives into specific modules, refer to the internal READMEs:
* [**Stochastic Generators**](./Engine/test/Common/README.md): Graph generation strategies.
* [**Continuous Operators**](./Engine/test/ContinuousMath/README.md): Proofs of Helmholtz-Hodge invariants.
* [**Discrete Algorithms**](./Engine/test/DiscreteMath/README.md): Partitioning and manifold logic.