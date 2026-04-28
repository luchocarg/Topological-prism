{-# LANGUAGE StrictData #-}

module ContinuousMath.Potential (
    solvePotentials
) where

import qualified Data.Map.Strict as Map
import qualified Domain.Types as Dom

-- Poisson, Laplacian(Phi) = Divergence(F)

-- iterative Jacobi for Relaxation
solvePotentials :: Dom.ComputationalGraph 
                -> Map.Map Dom.NodeIdentifier Dom.FlowAmount
                -> Map.Map Dom.NodeIdentifier Dom.PotentialValue
solvePotentials (Dom.ComputationalGraph adjMap) divMap = 
    let 
        nodes = Map.keys adjMap
        initialPotentials = Map.fromList [ (n, 0.0) | n <- nodes ]
        
        neighborMap = buildNeighborMap adjMap
        
        -- Works for 1000
        iterations = 2000
    in
        foldl (\pots _ -> relaxPoisson pots neighborMap divMap) initialPotentials [1..iterations]

-- Phi(u) = (Divergence(u) + Sum(Phi(neighbors))) / Degree(u)
relaxPoisson :: Map.Map Dom.NodeIdentifier Double
             -> Map.Map Dom.NodeIdentifier [Dom.NodeIdentifier]
             -> Map.Map Dom.NodeIdentifier Double
             -> Map.Map Dom.NodeIdentifier Double
relaxPoisson currentPots neighborsMap divergences =
    let 
        fixedNode = fst (Map.findMin currentPots)
    in
    Map.mapWithKey (\u _ -> 
        if u == fixedNode then 0.0 else
        let 
            divVal = Map.findWithDefault 0.0 u divergences
            neighbors = Map.findWithDefault [] u neighborsMap
            deg = fromIntegral (length neighbors)
            
            sumNeighborPots = sum [ Map.findWithDefault 0.0 n currentPots | n <- neighbors ]
        in 
            if deg == 0 then 0.0 
            else (divVal + sumNeighborPots) / deg
    ) currentPots

buildNeighborMap :: Map.Map Dom.NodeIdentifier [Dom.InternalEdge] 
                 -> Map.Map Dom.NodeIdentifier [Dom.NodeIdentifier]
buildNeighborMap adjMap = 
    Map.foldlWithKey' addEdges Map.empty adjMap
  where
    addEdges acc u edges = 
        foldl (\innerAcc edge -> 
            let v = Dom.destinationNode edge
                a1 = Map.insertWith (++) u [v] innerAcc
                a2 = Map.insertWith (++) v [u] a1
            in a2
        ) acc edges