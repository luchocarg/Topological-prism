module DiscreteMath.TreePathSpec (tests) where

import Test.QuickCheck
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Domain.Types
import Common.Generators (genConnectedGraph)
import DiscreteMath.DecomposeGraph (decomposeGraph)
import DiscreteMath.TreePath (findPathInTree)

prop_pathExistence :: ComputationalGraph -> Property
prop_pathExistence g@(ComputationalGraph m) = 
    forAll (genNodePair g) $ \(start, end) ->
        let 
            (treeEdges, _) = decomposeGraph g
            result = findPathInTree treeEdges start end
        in
            counterexample ("Path lookup failed for " ++ show start ++ " -> " ++ show end) $
                case result of
                    Nothing -> False -- fail
                    Just _  -> True  -- success

prop_pathContinuity :: ComputationalGraph -> Property
prop_pathContinuity g@(ComputationalGraph m) =
    forAll (genNodePair g) $ \(start, end) ->
        let 
            (treeEdges, _) = decomposeGraph g
            Just path = findPathInTree treeEdges start end
        in
            counterexample ("Broken path chain: " ++ show path) $
                isValidChain start end path

-- helpers

isValidChain :: NodeIdentifier -> NodeIdentifier -> [InternalEdge] -> Bool
isValidChain current target [] = current == target
isValidChain current target (edge:rest) =
    let 
        u = sourceNode edge
        v = destinationNode edge
    in
        if current == u then isValidChain v target rest       -- trav forw
        else if current == v then isValidChain u target rest  -- trav back
        else False -- gap

genNodePair :: ComputationalGraph -> Gen (NodeIdentifier, NodeIdentifier)
genNodePair (ComputationalGraph m) = do
    let nodes = Map.keys m
    u <- elements nodes
    v <- elements nodes
    return (u, v)


tests :: IO ()
tests = do
    putStrLn "\n[DiscreteMath.TreePath] Verifying Navigation..."
    
    putStrLn "  Universal Reachability"
    quickCheck $ forAll genConnectedGraph prop_pathExistence
    
    putStrLn "  Path Continuity"
    quickCheck $ forAll genConnectedGraph prop_pathContinuity