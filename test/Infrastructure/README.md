# Data Integrity

## Architecture Definition

The Infrastructure Layer acts as the corruption-barrier between external JSON representations (DTOs) and the internal mathematical domain. The mapping strategy $\mu$ guarantees that the `ComputationalGraph` construction is strictly isomorphic to the incoming data schema.

$$\mu: \text{DTO}_{incoming} \leftrightarrow \text{Domain}_{internal}$$

### Transformations
1.  **Ingestion ($\mu_{in}$):** Reconstructs the graph topology from flat lists, enforcing strict typing on `NodeIdentifier` and `EdgeIdentifier`.
2.  **Enrichment:** Explicitly populates the `sourceNode` attribute derived from the adjacency context during the mapping phase.
3.  **Projection ($\mu_{out}$):** Serializes simulation results back to primitive types for JSON transport.

---

## Integrity Contracts

### Contract I: Isomorphism (Roundtrip)
The mapping process must be reversible without information loss. Serializing a domain graph and re-ingesting it must yield an equivalent structure.
$$G \equiv \mu_{in}(\mu_{out}(G))$$

### Contract II: Schema Consistency
Internal redundant fields must be strictly consistent with the adjacency map structure.
$$\forall e \in \text{AdjacencyMap}[u], \quad e.\text{source} = u$$

---

## 3. Implementation Mapping

| Contract | QuickCheck Property |
| :--- | :--- |
| **Isomorphism** | `prop_mapperRoundtrip` |
| **Schema Consistency** | `prop_sourceNodeIntegrity` |