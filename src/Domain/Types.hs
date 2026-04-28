{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StrictData #-}

module Domain.Types where

import Data.Map.Strict (Map)

-- Unique ID for a node in the graph.
newtype NodeIdentifier = NodeIdentifier Int 
    deriving stock (Show, Eq, Ord)
    deriving newtype (Num, Integral, Real, Enum)

-- Unique ID for an edge in the graph.
newtype EdgeIdentifier = EdgeIdentifier Int 
    deriving stock (Show, Eq, Ord)
    deriving newtype (Num, Integral, Real, Enum)

-- Scalar amount of flow passing through an edge.
type FlowAmount = Double

-- Scalar potential value associated with a node.
type PotentialValue = Double

-- Internal representation of a directed edge with metadata.
data InternalEdge = InternalEdge {
    edgeIdentifier  :: EdgeIdentifier,   -- Unique ID for the edge
    sourceNode      :: NodeIdentifier,   -- Origin node of the flow
    destinationNode :: NodeIdentifier,   -- Target node of the flow
    currentFlow     :: FlowAmount        -- Raw flow magnitude
} deriving (Show, Eq)

-- A graph represented as an adjacency map of outgoing edges.
newtype ComputationalGraph = ComputationalGraph (Map NodeIdentifier [InternalEdge])
    deriving (Show, Eq)

-- The resulting physical components for a specific edge after decomposition.
data CalculatedEdgeResult = CalculatedEdgeResult {
    resultEdgeIdentifier :: EdgeIdentifier, -- ID of the processed edge
    resultSource         :: NodeIdentifier, -- Source node
    resultTarget         :: NodeIdentifier, -- Target node
    gradientComponent    :: FlowAmount,     -- Irrotational component
    rotationalComponent  :: FlowAmount      -- Solenoidal component
} deriving (Show, Eq)

-- The resulting physical state for a specific node after potential resolution.
data CalculatedNodeResult = CalculatedNodeResult {
    resultNodeIdentifier :: NodeIdentifier, -- ID of the node
    divergenceValue      :: FlowAmount,     -- Net flow divergence at this node
    potentialValue       :: PotentialValue  -- Scalar potential solved via Poisson
} deriving (Show, Eq)

-- Aggregated results of a full graph decomposition simulation.
data SimulationResult = SimulationResult {
    nodeResults          :: [CalculatedNodeResult], -- List of per-node results
    edgeResults          :: [CalculatedEdgeResult], -- List of per-edge results
    isSystemConservative :: Bool                    -- Flag indicating if rotational component is negligible
} deriving (Show, Eq)