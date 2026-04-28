module Infrastructure.MappersSpec (tests) where

import Test.QuickCheck
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.List (sort)

import Domain.Types
import Infrastructure.JsonDto
import Infrastructure.Mappers (toComputationalGraph, fromTupleToGraph)
import Common.Generators (genConnectedGraph)

prop_mapperRoundtrip :: ComputationalGraph -> Property
prop_mapperRoundtrip originalGraph =
    let 
        dto = mockIncomingDto originalGraph
        mappedGraph = toComputationalGraph dto
    in
        counterexample "Data Corruption: JSON Roundtrip altered the graph structure" $
            areGraphsEquivalent originalGraph mappedGraph

prop_sourceNodeIntegrity :: ComputationalGraph -> Property
prop_sourceNodeIntegrity g =
    let 
        dto = mockIncomingDto g
        (ComputationalGraph m) = toComputationalGraph dto
        checkNode (u, edges) = all (\e -> sourceNode e == u) edges
        validNodes = filter checkNode (Map.toList m)
    in
        counterexample "Schema Violation: Edge 'sourceNode' contradicts adjacency map key" $
            length validNodes == Map.size m

prop_tupleMapperTopology :: ComputationalGraph -> Property
prop_tupleMapperTopology originalGraph = 
    let
        tuples = toTuples originalGraph
        
        mappedGraph = fromTupleToGraph tuples
    in
        counterexample "Data Corruption: Tuple mapping altered topology or flow" $
            areGraphsTopologicallyEquivalent originalGraph mappedGraph

-- Helpers

toTuples :: ComputationalGraph -> [(Int, Int, Double)]
toTuples (ComputationalGraph m) = 
    let allEdges = concat (Map.elems m)
    in map (\e -> (toInt (sourceNode e), toInt (destinationNode e), currentFlow e)) allEdges
  where toInt (NodeIdentifier i) = i

areGraphsTopologicallyEquivalent :: ComputationalGraph -> ComputationalGraph -> Bool
areGraphsTopologicallyEquivalent (ComputationalGraph m1) (ComputationalGraph m2) =
    let 
        nodes1 = Map.keysSet m1
        nodes2 = Map.keysSet m2
        
        extractData e = (destinationNode e, currentFlow e)
        sortEdges = sort . map extractData
        
        edgesMatch = all (\n -> 
            let e1 = Map.findWithDefault [] n m1
                e2 = Map.findWithDefault [] n m2
            in sortEdges e1 == sortEdges e2
            ) (Set.toList nodes1)
            
    in nodes1 == nodes2 && edgesMatch

areGraphsEquivalent :: ComputationalGraph -> ComputationalGraph -> Bool
areGraphsEquivalent (ComputationalGraph m1) (ComputationalGraph m2) =
    let 
        nodes1 = Map.keysSet m1
        nodes2 = Map.keysSet m2
        sortEdges = sort . map edgeIdentifier
        edgesMatch = all (\n -> 
            let e1 = Map.findWithDefault [] n m1
                e2 = Map.findWithDefault [] n m2
            in sortEdges e1 == sortEdges e2
            ) (Set.toList nodes1)
    in nodes1 == nodes2 && edgesMatch

mockIncomingDto :: ComputationalGraph -> IncomingGraphDto
mockIncomingDto (ComputationalGraph m) =
    IncomingGraphDto {
        incomingGraphNodes = map (\(NodeIdentifier i) -> i) (Map.keys m),
        incomingGraphEdges = concatMap toDtoEdges (Map.toList m)
    }
  where
    toDtoEdges (u, edges) = map (toDtoEdge u) edges
    toDtoEdge (NodeIdentifier uId) edge = IncomingEdgeDto {
        incomingEdgeId = let (EdgeIdentifier i) = edgeIdentifier edge in i,
        incomingEdgeFrom = uId,
        incomingEdgeTo = let (NodeIdentifier i) = destinationNode edge in i,
        incomingEdgeFlow = currentFlow edge
    }

tests :: IO ()
tests = do
    putStrLn "\n[Infrastructure.Mappers] Verifying Boundary..."
    
    putStrLn "  Roundtrip Integrity (Domain -> DTO -> Domain)"
    quickCheck $ forAll genConnectedGraph prop_mapperRoundtrip
    
    putStrLn "  SourceNode Consistency"
    quickCheck $ forAll genConnectedGraph prop_sourceNodeIntegrity

    putStrLn "  Tuple Mapping Topology (Text -> Domain)"
    quickCheck $ forAll genConnectedGraph prop_tupleMapperTopology