module ContinuousMath.Decomposition (decompose) where

import qualified Data.Map.Strict as Map
import qualified Domain.Types as Dom
import qualified ContinuousMath.Gauss as Gauss
import qualified ContinuousMath.Potential as Potential
import qualified ContinuousMath.Stokes as Stokes

-- 1. Gauss
-- 2. Relaxation
-- 3. Derive the gradient component from potential differences
-- 4. Stokes
decompose :: Dom.ComputationalGraph -> Dom.SimulationResult
decompose graph@(Dom.ComputationalGraph adjMap) =
    let
        divMap = Gauss.calculateDivergences graph
        
        potMap = Potential.solvePotentials graph divMap
        
        allEdges = concat (Map.elems adjMap)
        rotMap = Stokes.calculateRotationalFlow allEdges potMap
        
        nodes = Map.keys adjMap
        nodeResults = map (\u -> 
            Dom.CalculatedNodeResult u 
                (Map.findWithDefault 0.0 u divMap)
                (Map.findWithDefault 0.0 u potMap)
            ) nodes
            
        edgeResults = map (\e ->
            let 
                eid = Dom.edgeIdentifier e
                u = Dom.sourceNode e
                v = Dom.destinationNode e
                phiU = Map.findWithDefault 0.0 u potMap
                phiV = Map.findWithDefault 0.0 v potMap
                grad = phiU - phiV
                rot = Map.findWithDefault 0.0 eid rotMap
            in Dom.CalculatedEdgeResult eid u v grad rot
            ) allEdges
            
        conservative = all (\r -> abs (Dom.rotationalComponent r) < 1e-7) edgeResults
    in
        Dom.SimulationResult nodeResults edgeResults conservative