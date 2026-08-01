# Mathematical Model

This document describes the calculation implemented by the current engine. It distinguishes the exact graph-theoretic projection from the fixed-iteration numerical approximation used in the code.

## Scope

The engine accepts a signed scalar flow on oriented graph edges. It computes a node potential and splits the edge flow into two terms:

```text
total flow = gradient component + residual component
```

The current implementation does not define graph faces, a face-based curl operator, or a separate harmonic component.

## Graph and orientation

Let `G = (V, E)` be a graph with `n = |V|` nodes and `m = |E|` stored edges. Every edge has:

- a unique edge identifier;
- a source node;
- a target node; and
- a signed scalar flow.

The stored orientation defines the sign convention. A positive flow on `u -> v` travels from `u` to `v`. A negative value represents effective movement in the opposite direction.

Topology is treated as undirected when the potential solver builds its neighbor map. The stored direction remains relevant to divergence and to the sign of the reported edge components.

## Incidence matrix

Define the incidence matrix `B ∈ R^(n×m)` using the convention

```text
B[w,e] = +1  if w is the source of edge e
B[w,e] = -1  if w is the target of edge e
B[w,e] =  0  otherwise
```

This sign convention matches `ContinuousMath.Gauss`.

## Divergence

For an edge-flow vector `f ∈ R^m`, node divergence is

```text
rho = B f
```

Equivalently, for an edge `u -> v` carrying flow `x`:

- add `x` to the divergence at `u`; and
- subtract `x` from the divergence at `v`.

Positive divergence means net outgoing flow. Negative divergence means net incoming flow.

For every well-formed finite graph, the sum of all divergences is zero up to floating-point arithmetic because every edge contributes once with each sign:

```text
sum_v rho[v] = 0
```

This global cancellation is an algebraic property of the divergence definition. It is not, by itself, evidence that the Poisson solver has converged.

## Graph Laplacian and potential

The unweighted graph Laplacian is

```text
L = B B^T
```

The engine seeks a node potential `phi ∈ R^n` satisfying

```text
L phi = rho
```

The implementation approximates this equation with Jacobi relaxation. For a non-reference node `u`, the update is

```text
phi[u] = (rho[u] + sum(phi[v] for v adjacent to u)) / degree(u)
```

The neighbor relation is constructed by symmetrizing each stored edge. Repeated stored edges therefore contribute repeated neighbor entries and affect the effective unweighted multigraph Laplacian.

## Gauge fixing

Potential is defined only up to an additive constant:

```text
phi and phi + c produce the same edge differences
```

The implementation removes this ambiguity by fixing the node with the smallest identifier to potential zero during every Jacobi iteration.

This value is a gauge choice, not an absolute physical measurement. Consumers should compare potential differences rather than interpret zero as a universal reference.

For disconnected graphs, one independent gauge is normally required for each connected component. The current implementation fixes only the globally smallest node, so disconnected-graph behavior is not part of the stable numerical contract.

## Gradient component

For an oriented edge `e = (u, v)`, the reported gradient component is

```text
gradient[e] = phi[u] - phi[v]
```

In matrix notation:

```text
gradient = B^T phi
```

The name `gradient` follows the engine's sign convention. With an alternative convention for the discrete gradient, the same quantity may be written as a negative gradient. API documentation should always state the explicit edge formula instead of relying on terminology alone.

## Residual component

The field currently named `rotationalComponent` is calculated as

```text
residual[e] = totalFlow[e] - gradient[e]
```

or

```text
residual = f - B^T phi
```

Therefore reconstruction holds up to floating-point arithmetic:

```text
f = gradient + residual
```

This equality holds by construction and does not depend on Poisson convergence.

## Divergence-free property

If the Poisson equation is solved exactly,

```text
B residual
  = B f - B B^T phi
  = rho - L phi
  = 0
```

The residual is then divergence-free.

With the current fixed-iteration solver, the divergence-free property is approximate. A useful diagnostic would be

```text
poissonResidual  = ||L phi - rho||
residualDivergence = ||B residual||
```

The engine does not currently return either metric.

## Orthogonality

Under the standard Euclidean inner product on edge flows, the image of `B^T` is orthogonal to the kernel of `B`:

```text
im(B^T) perpendicular to ker(B)
```

If `phi` solves the Poisson equation exactly, the gradient lies in `im(B^T)` and the residual lies in `ker(B)`. The two components are therefore orthogonal:

```text
<gradient, residual> = 0
```

For the implemented approximation, this inner product should be expected to be small rather than identically zero. The current test suite does not directly test this inner product.

## Two terms versus a full Hodge decomposition

A richer edge-flow Hodge decomposition on a cell or simplicial complex may be written as

```text
f = B1^T phi + B2 psi + h
```

where:

- `B1^T phi` is the gradient or exact component;
- `B2 psi` is a coexact or curl component associated with faces; and
- `h` is harmonic.

The current project defines nodes and edges but no faces and no `B2` operator. It consequently cannot separate a face-based rotational term from a harmonic term. Its residual may contain all divergence-free cycle and topological modes available in the graph.

For this reason:

- use **gradient component** for `B^T phi`;
- use **residual** or **divergence-free residual** for `f - B^T phi`; and
- treat the JSON name `Rotational` as a historical compatibility name.

## Conservative classification

`isSystemConservative` is calculated by checking every edge independently:

```text
abs(residual[e]) < 1e-7
```

The result is true only when all edges pass that threshold. This is not a norm of the complete residual vector and is separate from the `1e-9` tolerances used in several tests.

## Numerical approximation

The current implementation:

- starts every potential at zero;
- fixes the smallest node identifier at zero;
- performs exactly 2000 Jacobi iterations;
- uses no convergence test;
- exposes no tolerance parameter;
- exposes no iteration-count parameter; and
- returns no residual metric.

Jacobi convergence depends on graph structure and the linear system. Documentation should therefore describe the result as an approximation rather than an exact solve for arbitrary input.

## Analytic examples

### Single directed edge

For one edge `1 -> 2` with flow `10.5`:

```text
rho[1] =  10.5
rho[2] = -10.5
```

With `phi[1] = 0`, the solution is `phi[2] = -10.5`. Thus:

```text
gradient = 10.5
residual = 0
```

### Three-edge circulation

Consider the cycle

```text
1 -> 2 : 4
2 -> 3 : 4
3 -> 1 : 4
```

Every node has zero divergence. With the zero gauge and zero initial state, all potentials remain zero:

```text
gradient = 0 on every edge
residual = 4 on every edge
```

This is the simplest example of a nonzero divergence-free residual.

## Input assumptions relevant to the model

The mathematical description assumes:

- at least one node;
- unique node identifiers;
- globally unique edge identifiers;
- every endpoint belongs to the node set;
- finite numeric flows; and
- a graph structure for which the chosen numerical method is meaningful.

The current JSON boundary does not enforce all of these assumptions. See [json-api.md](json-api.md) and [limitations.md](limitations.md).