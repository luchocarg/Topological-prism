{-# LANGUAGE StrictData #-}

module ContinuousMath.Gauss (
    calculateDivergences,
    calculateTotalSystemDivergence
) where

import qualified Data.Map.Strict as Map
import qualified Domain.Types as Dom
import Data.List (foldl')

calculateDivergences :: Dom.ComputationalGraph -> Map.Map Dom.NodeIdentifier Dom.FlowAmount
calculateDivergences (Dom.ComputationalGraph adjMap) = 
    let 
        initialMap = Map.map (const 0.0) adjMap
        
        allEdges = concat (Map.elems adjMap)
    in 
        foldl' processEdge initialMap allEdges

-- Updates the divergence map with the flow of an edge
processEdge :: Map.Map Dom.NodeIdentifier Dom.FlowAmount 
            -> Dom.InternalEdge 
            -> Map.Map Dom.NodeIdentifier Dom.FlowAmount
processEdge accMap edge =
    let 
        u = Dom.sourceNode edge
        v = Dom.destinationNode edge
        f = Dom.currentFlow edge
        
        -- increases positive divergence
        acc1 = Map.insertWith (+) u f accMap
        
        -- increases negative divergence
        acc2 = Map.insertWith (+) v (-f) acc1
    in 
        acc2

calculateTotalSystemDivergence :: Dom.ComputationalGraph -> Dom.FlowAmount
calculateTotalSystemDivergence graph = 
    sum (Map.elems (calculateDivergences graph))