module DiscreteMath.DecomposeGraphSpec (tests) where

import Test.QuickCheck
import qualified Data.Set as Set
import qualified Data.Map.Strict as Map
import Domain.Types
import Common.Generators (genConnectedGraph, genGraphWithConfig, defaultGenConfig)
import DiscreteMath.DecomposeGraph (decomposeGraph)

prop_partitionConservation :: ComputationalGraph -> Property
prop_partitionConservation g@(ComputationalGraph m) =
    let 
        (treeEdges, cycleEdges) = decomposeGraph g
        
        originalCount = length $ concat (Map.elems m)
        decomposedCount = length treeEdges + length cycleEdges
    in 
        counterexample ("Mass loss: Input " ++ show originalCount ++ " /= Output " ++ show decomposedCount) $
            originalCount == decomposedCount

prop_disjointSets :: ComputationalGraph -> Property
prop_disjointSets g =
    let 
        (treeEdges, cycleEdges) = decomposeGraph g
        
        treeIds = Set.fromList $ map edgeIdentifier treeEdges
        cycleIds = Set.fromList $ map edgeIdentifier cycleEdges
        
        intersection = Set.intersection treeIds cycleIds
    in 
        counterexample ("Ambiguous classification. Shared IDs: " ++ show intersection) $
            Set.null intersection

prop_isSpanningTree :: ComputationalGraph -> Property
prop_isSpanningTree g@(ComputationalGraph m) =
    let 
        (treeEdges, _) = decomposeGraph g
        nodeCount = Map.size m
    in 
        counterexample ("Tree size invalid. Expected V-1 (" ++ show (nodeCount - 1) ++ "), got " ++ show (length treeEdges)) $
            if nodeCount > 0 
                then length treeEdges == nodeCount - 1
                else null treeEdges

tests :: IO ()
tests = do
    putStrLn "\n[DiscreteMath.Decompose] Verifying Logic..."
    
    putStrLn "Conservation of Mass"
    quickCheck $ forAll (genGraphWithConfig defaultGenConfig) prop_partitionConservation
    
    putStrLn "Orthogonality"
    quickCheck $ forAll (genGraphWithConfig defaultGenConfig) prop_disjointSets
    
    putStrLn "Spanning Tree Property"
    quickCheck $ forAll genConnectedGraph prop_isSpanningTree