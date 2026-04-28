# Continuous Topology

## 1. Vector Decomposition

Let $\mathcal{H}$ be the Helmholtz-Hodge decomposition operator acting on the scalar flow space $\mathcal{F}$. The operator solves the global Poisson equation to partition the total flow field $F$ into two orthogonal subspaces:

$$\mathcal{H}: F \to (F_{grad}, F_{rot})$$

### Components
1.  **Gradient Field ($F_{grad}$):**
    The conservative component derived from the scalar potential $\Phi$. This represents the "downhill" flow driven by topological elevation. It is irrotational by definition.
    $$F_{grad} = -\nabla \Phi \quad \text{s.t.} \quad \oint F_{grad} \cdot d\vec{l} = 0$$

2.  **Rotational Field ($F_{rot}$):**
    The solenoidal component that captures the residual vorticity of the system. This represents pure circulation. It is divergence-free by definition.
    $$F_{rot} = F_{total} - F_{grad} \quad \text{s.t.} \quad \nabla \cdot F_{rot} = 0$$

---

## 2. Physical Invariants

Every execution of the continuous engine must satisfy the following post-conditions, which guarantee the physical validity of the simulation under the Discrete Vector Calculus framework.

### Invariant I: Principle of Superposition
The decomposition must be a strict partition of the vector field. The sum of the orthogonal components must reconstruct the original raw flow with full fidelity ($\epsilon \approx 10^{-9}$).
$$F_{total} \equiv F_{grad} + F_{rot}$$

### Invariant II: Gradient Consistency
The gradient flow must be strictly **Path Independent**. The flow along any edge must exactly equal the potential difference between its source and destination nodes.
$$F_{grad}(u, v) = \Phi(u) - \Phi(v)$$

### Invariant III: Solenoidal Property
The rotational component must form closed loops (vortices) with no sources or sinks. The divergence of this field must be zero at every node in the domain.
$$\nabla \cdot F_{rot} = 0$$

### Invariant IV: Global Conservation of Mass
In a closed graph system, matter is neither created nor destroyed. The net divergence of the entire system must sum to zero (Gauss's Law).
$$\sum_{v \in V} (\nabla \cdot F)(v) = 0$$

---

## 3. The Poisson Solver ($\nabla^2$)

Since the graph topology is arbitrary, we cannot rely on geometric heuristics. We define the Potential Operator $\Phi$ as the solution to the **Discrete Poisson Equation**:

$$\nabla^2 \Phi = \rho$$

Where $\rho$ is the divergence map of the system ($\nabla \cdot F$). We utilize an **Iterative Jacobi Relaxation** method to solve this system, finding the scalar field $\Phi$ that minimizes the global energy of the gradient.

### The Stokes Residual
This analytical approach allows the application of the **Vector Subtraction Principle** to calculate the rotational field without complex cycle basis enumeration:

$$F_{rot} = F_{total} - \mathcal{G}(\Phi)$$

Where $\mathcal{G}$ is the discrete gradient operator.

---

## 4. Implementation Mapping

| Concept | Implementation | QuickCheck |
| :--- | :--- | :--- |
| **Invariant I** | `decompose` | `prop_reversibility` |
| **Invariant II** | `decompose` | `prop_gradientConsistency` |
| **Invariant III** | `calculateRotationalFlow` | `prop_isSolenoidal` |
| **Invariant IV** | `calculateTotalSystemDivergence` | `prop_conservationOfMass` |
| **Operator $\nabla^2$** | `solvePotentials` | `StokesSpec` |
| **Operator $\nabla \cdot F$** | `calculateDivergences` | `GaussSpec` |
