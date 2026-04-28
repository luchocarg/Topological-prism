{-# LANGUAGE StrictData #-}

module ContinuousMath.Stokes (
    calculateRotationalFlow
) where

import qualified Data.Map.Strict as Map
import qualified Domain.Types as Dom


calculateRotationalFlow :: [Dom.InternalEdge]
                        -> Map.Map Dom.NodeIdentifier Dom.PotentialValue
                        -> Map.Map Dom.EdgeIdentifier Dom.FlowAmount
calculateRotationalFlow allEdges potMap = 
    foldl calculateEdgeRes Map.empty allEdges
  where
    calculateEdgeRes acc edge =
        let 
            eid = Dom.edgeIdentifier edge
            u = Dom.sourceNode edge
            v = Dom.destinationNode edge
            totalF = Dom.currentFlow edge
            
            phi_u = Map.findWithDefault 0.0 u potMap
            phi_v = Map.findWithDefault 0.0 v potMap
            
            gradF = phi_u - phi_v
            
            rotF = totalF - gradF
        in
            Map.insert eid rotF acc