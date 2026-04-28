# Discrete Topology Engine

## 1. Topological Decomposition ($\delta$)

Let $\delta$ be the deterministic decomposition operator acting on the valid graph space $\mathcal{G}$. The operator performs a global Breadth-First Search to partition the edge set $E$ into two orthogonal subspaces:

$$\delta: G \to (E_T, E_C)$$

### Components
1.  **Spanning Manifold ($E_T$):**
    The set of **Tree Edges** that constitutes the acyclic skeleton of the graph. For disconnected graphs, this forms a **Spanning Forest**. This defines the **Gradient Field**.
    $$E_T \subset E \quad \text{s.t.} \quad (V, E_T) \text{ is acyclic}$$

2.  **Cyclic Chords ($E_C$):**
    The set of **Back Edges** (or Cotree) that close loops. This defines the **Rotational Field**.
    $$E_C = E \setminus E_T$$

---

## 2. Decomposition Invariants

Every execution of the decomposition engine must satisfy the following post-conditions, which guarantee the physical validity of the simulation.

### Invariant I: Law of Conservation
The decomposition must be a strict partition of the original domain. No edge (and thus no flow mass) can be created or destroyed during the process.
$$|E| = |E_T| + |E_C|$$

### Invariant II: Orthogonality
The classification is mutually exclusive. An edge cannot simultaneously contribute to the gradient and rotational components.
$$E_T \cap E_C = \emptyset$$

### Invariant III: Maximal Coverage
The Spanning Manifold must cover the entire vertex domain $V$. If a node is unreachable via $E_T$, the potential field is undefined.
$$V(E_T) = V(G)$$

### Invariant IV: Structural Acyclicity
The manifold $E_T$ must be topologically trivial. It cannot contain any closed loops.
$$\oint_{\gamma} d\vec{l} \neq 0 \implies \gamma \nsubseteq E_T$$

---

## 3. Manifold Navigation ($\gamma$)

Since $(V, E_T)$ is a Spanning Tree, it guarantees the existence of a **unique geodesic path** between any pair of nodes. We define the navigation operator $\gamma$ as:

$$\gamma: (E_T, u, v) \to P_{u \to v}$$

Where the path $P_{u \to v}$ is an ordered sequence of edges from $E_T$ forming a continuous chain from $u$ to $v$.

### The Fundamental Cycle
This navigation is critical for the physical engine. For every cyclic chord $e_{chord} = (u, v) \in E_C$, the **Fundamental Cycle** $C_k$ is defined as the union of the chord and the return path through the tree:

$$C_k = \{e_{chord}\} \cup \gamma(E_T, v, u)$$

This structure allows the application of the **Discrete Stokes Theorem** to calculate the rotational field.

---

## 4. Implementation Mapping

| Concept | Implementation | QuickCheck |
| :--- | :--- | :--- |
| **Invariant I** | `decomposeGraph` | `prop_partitionConservation` |
| **Invariant II** | `decomposeGraph` | `prop_disjointSets` |
| **Invariants III & IV** | `decomposeGraph` | `prop_isSpanningTree` |
| **Operator $\gamma$** | `findPathInTree` | `prop_pathExistence` |
| **Path Continuity** | `findPathInTree` | `prop_pathContinuity` |