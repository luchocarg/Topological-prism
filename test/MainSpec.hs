module MainSpec (tests) where

import Test.QuickCheck
import Data.Aeson (encode, decode)
import qualified Data.Map.Strict as Map
import Domain.Types
import Infrastructure.JsonDto
import Infrastructure.Mappers
import ContinuousMath.Decomposition
import Common.Generators (genConnectedGraph)


toIncomingDto :: ComputationalGraph -> IncomingGraphDto
toIncomingDto (ComputationalGraph adj) =
    let 
        allNodes = Map.keys adj
        allEdges = concat (Map.elems adj)
        
        nodeIds = map (\(NodeIdentifier i) -> i) allNodes
        
        edgeDtos = map (\e -> IncomingEdgeDto {
            incomingEdgeId = let (EdgeIdentifier i) = edgeIdentifier e in i,
            incomingEdgeFrom = let (NodeIdentifier i) = sourceNode e in i,
            incomingEdgeTo = let (NodeIdentifier i) = destinationNode e in i,
            incomingEdgeFlow = currentFlow e
        }) allEdges
    in
        IncomingGraphDto nodeIds edgeDtos


prop_pipelineStability :: ComputationalGraph -> Property
prop_pipelineStability graph = 
    let
        inputDto = toIncomingDto graph
        inputJson = encode inputDto
        
        decoded = decode inputJson :: Maybe IncomingGraphDto
    in
        case decoded of
            Nothing -> counterexample "Failed to decode generated JSON" False
            Just dto ->
                let 
                    domain = toComputationalGraph dto
                    result = decompose domain
                    outputDto = toOutgoingDto result
                    
                    isConservative = outgoingSimulationResultIsConservative outputDto
                in
                    counterexample "Pipeline produced unstable result" $
                    isConservative == isSystemConservative result

tests :: IO ()
tests = do
    putStrLn "\n[System.Integration] Verifying Full Pipeline..."
    quickCheck $ forAll genConnectedGraph prop_pipelineStability