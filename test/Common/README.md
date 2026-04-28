# Stochastic Input Validity

## 1. Process Definition

Let $\Psi$ be the generative function parameterized by the configuration vector $\theta = (N_{range}, \rho, \Phi)$, where:

* **$N_{range} \in \mathbb{N}^2$**: Node count lower and upper bounds.
* **$\rho \in [0, 1]$**: Edge density factor.
* **$\Phi \subseteq \mathbb{R}$**: Domain of valid flow values.

The process produces a **Weighted Directed Graph** $G \sim \Psi(\theta)$ defined as the tuple $G = (V, E, f)$.

### Structural Components

1. **Topology ($V, E$):** The edge set is constructed as the disjoint union of a spanning structure ($E_{skeleton}$) and stochastic noise ($E_{noise}$).

$$E = E_{skeleton} \cup E_{noise}$$


2. **Flow Field ($f$):** A mapping that assigns a scalar value to every edge from the domain $\Phi$.

$$f: E \to \Phi$$



---

## 2. Validity Axioms

Every realization $G$ produced by the generator must satisfy the following formal axioms, verified via property-based testing prior to physics simulation.

### Axiom I: Non-Triviality

The manifold must possess sufficient dimension to define potential differences.


$$|V| \ge 2$$

### Axiom II: Referential Integrity

All edges must connect vertices that strictly exist within the domain $V$.


$$\forall (u, v) \in E \implies u \in V \land v \in V$$

### Axiom III: Weak Connectivity

While flow is directed, the underlying topological manifold must be a single connected component.


$$\kappa(G_{undirected}) = 1$$

### Axiom IV: Topological Simplicity

The graph must be **Simple** to ensure well-defined divergence. This prohibits both self-loops and multi-edges.


$$\forall (u, v) \in E \implies u \neq v \land \text{count}(u, v) = 1$$

### Axiom V: Identity Uniqueness

Every edge entity must possess a globally unique identifier for linear algebra operations.


$$id(e_i) = id(e_j) \iff i = j$$

---

## 3. Implementation Mapping

| Theoretical Axiom | QuickCheck Property | Specification File |
| --- | --- | --- |
| **Axiom I** | `prop_nonTrivial` | `GeneratorsSpec.hs` |
| **Axiom II** | `prop_edgesAreValid` | `GeneratorsSpec.hs` |
| **Axiom III** | `prop_isConnected` | `GeneratorsSpec.hs` |
| **Axiom IV** | `prop_noSelfLoops` | `GeneratorsSpec.hs` |
| **Axiom IV** | `prop_noMultiEdges` | `GeneratorsSpec.hs` |
| **Axiom V** | `prop_uniqueEdgeIds` | `GeneratorsSpec.hs` |

Would you like me to generate the English Markdown blocks for the **Physics** and **Topology** modules following this same technical structure?