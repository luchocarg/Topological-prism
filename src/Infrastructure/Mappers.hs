module Infrastructure.Mappers where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Domain.Types as Dom
import qualified Infrastructure.JsonDto as Dto

-- DTO -> Domain

toComputationalGraph :: Dto.IncomingGraphDto -> Dom.ComputationalGraph
toComputationalGraph dto = 
    let 
        edges = Dto.incomingGraphEdges dto
        
        insertEdge :: Dto.IncomingEdgeDto -> Map.Map Dom.NodeIdentifier [Dom.InternalEdge] -> Map.Map Dom.NodeIdentifier [Dom.InternalEdge]
        insertEdge edgeDto accumulatorMap =
            let 
                u = Dom.NodeIdentifier (Dto.incomingEdgeFrom edgeDto)
                v = Dom.NodeIdentifier (Dto.incomingEdgeTo edgeDto)
                edgeId = Dom.EdgeIdentifier (Dto.incomingEdgeId edgeDto)
                amount = Dto.incomingEdgeFlow edgeDto
                
                newInternalEdge = Dom.InternalEdge {
                    Dom.edgeIdentifier = edgeId,
                    Dom.sourceNode = u,
                    Dom.destinationNode = v,
                    Dom.currentFlow = amount
                }
            in 
                Map.insertWith (++) u [newInternalEdge] accumulatorMap

        initialMap = Map.fromList [ (Dom.NodeIdentifier n, []) | n <- Dto.incomingGraphNodes dto ]
        
        finalMap = foldr insertEdge initialMap edges
    in 
        Dom.ComputationalGraph finalMap

-- Domain -> DTO

toOutgoingDto :: Dom.SimulationResult -> Dto.OutgoingSimulationResultDto
toOutgoingDto domainResult = Dto.OutgoingSimulationResultDto {
    Dto.outgoingSimulationResultNodes = map toNodeDto (Dom.nodeResults domainResult),
    Dto.outgoingSimulationResultEdges = map toEdgeDto (Dom.edgeResults domainResult),
    Dto.outgoingSimulationResultIsConservative = Dom.isSystemConservative domainResult
}
  where
    toNodeDto :: Dom.CalculatedNodeResult -> Dto.OutgoingNodeResultDto
    toNodeDto nr = Dto.OutgoingNodeResultDto {
        Dto.outgoingNodeResultId = let (Dom.NodeIdentifier i) = Dom.resultNodeIdentifier nr in i,
        Dto.outgoingNodeResultDivergence = Dom.divergenceValue nr,
        Dto.outgoingNodeResultPotential = Dom.potentialValue nr
    }

    toEdgeDto :: Dom.CalculatedEdgeResult -> Dto.OutgoingEdgeResultDto
    toEdgeDto er = Dto.OutgoingEdgeResultDto {
        Dto.outgoingEdgeResultId = let (Dom.EdgeIdentifier i) = Dom.resultEdgeIdentifier er in i,
        
        Dto.outgoingEdgeResultSource = let (Dom.NodeIdentifier s) = Dom.resultSource er in s,
        Dto.outgoingEdgeResultTarget = let (Dom.NodeIdentifier t) = Dom.resultTarget er in t,
        
        Dto.outgoingEdgeResultGradient = Dom.gradientComponent er,
        Dto.outgoingEdgeResultRotational = Dom.rotationalComponent er
    }

fromTupleToGraph :: [(Int, Int, Double)] -> Dom.ComputationalGraph
fromTupleToGraph edges = 
    let 
        uniqueNodes = Set.toList $ foldr (\(u, v, _) acc -> Set.insert u (Set.insert v acc)) Set.empty edges
        
        initialMap = Map.fromList [ (Dom.NodeIdentifier n, []) | n <- uniqueNodes ]

        insertEdge :: (Int, (Int, Int, Double)) 
                   -> Map.Map Dom.NodeIdentifier [Dom.InternalEdge] 
                   -> Map.Map Dom.NodeIdentifier [Dom.InternalEdge]
        insertEdge (idx, (uInt, vInt, flow)) accumulatorMap =
            let 
                u = Dom.NodeIdentifier uInt
                v = Dom.NodeIdentifier vInt
                edgeId = Dom.EdgeIdentifier idx
                
                newInternalEdge = Dom.InternalEdge {
                    Dom.edgeIdentifier = edgeId,
                    Dom.sourceNode = u,
                    Dom.destinationNode = v,
                    Dom.currentFlow = flow
                }
            in 
                Map.insertWith (++) u [newInternalEdge] accumulatorMap

        edgesWithIds = zip [1..] edges
        finalMap = foldr insertEdge initialMap edgesWithIds
    in 
        Dom.ComputationalGraph finalMap