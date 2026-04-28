module Common.GeneratorsSpec (tests) where
import Test.QuickCheck
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Domain.Types
import Common.Generators (genConnectedGraph)

prop_nonTrivial :: ComputationalGraph -> Property
prop_nonTrivial (ComputationalGraph m) =
    counterexample ("Size violation: " ++ show (Map.size m) ++ " min 2 nodes required)") $
        Map.size m >= 2

prop_edgesAreValid :: ComputationalGraph -> Property
prop_edgesAreValid (ComputationalGraph m) =
    let 
        existingNodes = Map.keysSet m
        allEdges = concat (Map.elems m)
        destinations = map destinationNode allEdges
        
        dangling = filter (\d -> not (Set.member d existingNodes)) destinations
    in 
        counterexample ("Referential integrity failure. Invalid targets: " ++ show dangling) $
            null dangling

prop_isConnected :: ComputationalGraph -> Property
prop_isConnected g@(ComputationalGraph m) =
    let
        allNodes = Map.keysSet m
        root = fst $ Map.findMin m
        
        reachable = getReachableNodesUndirected root g
        
        missing = Set.difference allNodes reachable
    in
        counterexample ("Graph fragmentation. Unreachable nodes: " ++ show missing) $
            reachable == allNodes

prop_uniqueEdgeIds :: ComputationalGraph -> Property
prop_uniqueEdgeIds (ComputationalGraph m) =
    let 
        allEdges = concat (Map.elems m)
        ids = map edgeIdentifier allEdges
        uniqueIds = Set.fromList ids
    in
        counterexample "Duplicate Edge IDs detected" $
            length ids == Set.size uniqueIds

prop_noSelfLoops :: ComputationalGraph -> Property
prop_noSelfLoops (ComputationalGraph m) =
    let
        hasSelfLoop (u, edges) = any (\e -> destinationNode e == u) edges
        badNodes = filter hasSelfLoop (Map.toList m)
    in
        counterexample ("Self-loops detected at nodes: " ++ show (map fst badNodes)) $
            null badNodes


prop_noMultiEdges :: ComputationalGraph -> Property
prop_noMultiEdges (ComputationalGraph m) =
    let 
        allEdges = concat (Map.elems m)
        rawPairs = map (\e -> (sourceNode e, destinationNode e)) allEdges
        uniquePairs = Set.fromList rawPairs
    in
        counterexample ("Multi-edges detected, count: " ++ show (length rawPairs) ++ " Unique: " ++ show (Set.size uniquePairs)) $
            length rawPairs == Set.size uniquePairs


-- BFS

getReachableNodesUndirected :: NodeIdentifier -> ComputationalGraph -> Set.Set NodeIdentifier
getReachableNodesUndirected root graph = 
    bfs (Set.singleton root) [root] (toUndirectedAdjacency graph)
  where
    bfs visited [] _ = visited
    bfs visited (u:queue) adj =
        let 
            neighbors = Map.findWithDefault [] u adj
            newNodes = filter (\n -> not (Set.member n visited)) neighbors
        in 
            bfs (Set.union visited (Set.fromList newNodes)) (queue ++ newNodes) adj


toUndirectedAdjacency :: ComputationalGraph -> Map.Map NodeIdentifier [NodeIdentifier]
toUndirectedAdjacency (ComputationalGraph m) = 
    Map.foldlWithKey' addEdges Map.empty m
  where
    addEdges accMap u edges = 
        let 
            dests = map destinationNode edges
            acc1 = foldl (\acc v -> Map.insertWith (++) u [v] acc) accMap dests
            acc2 = foldl (\acc v -> Map.insertWith (++) v [u] acc) acc1 dests
        in acc2

-- Main

tests :: IO ()
tests = do
    putStrLn "\n[Common.Generators] Verifying Axioms..."
    
    putStrLn "  Minimum Size (>=2)"
    quickCheck $ forAll genConnectedGraph prop_nonTrivial
    
    putStrLn "  Referential Integrity"
    quickCheck $ forAll genConnectedGraph prop_edgesAreValid
    
    putStrLn "  Global Connectivity"
    quickCheckWith stdArgs { maxSuccess = 500 } $ forAll genConnectedGraph prop_isConnected

    putStrLn "  ID Uniqueness"
    quickCheck $ forAll genConnectedGraph prop_uniqueEdgeIds
    
    putStrLn "  Topological Simplicity"
    quickCheck $ forAll genConnectedGraph prop_noSelfLoops

    putStrLn "  Simple Graph"
    quickCheck $ forAll genConnectedGraph prop_noMultiEdges