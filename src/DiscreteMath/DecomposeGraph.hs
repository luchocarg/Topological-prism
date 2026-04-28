{-# LANGUAGE StrictData #-}

module DiscreteMath.DecomposeGraph 
    ( decomposeGraph
    , DecompositionResult
    ) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Sequence as Seq
import Data.Sequence (ViewL(..), (|>), viewl)
import Data.List (foldl')
import Domain.Types

type DecompositionResult = ([InternalEdge], [InternalEdge])

data GlobalState = GlobalState {
    globalVisited :: Set.Set NodeIdentifier,
    globalTree    :: [InternalEdge],
    globalCycle   :: [InternalEdge],
    processedIds  :: Set.Set EdgeIdentifier
}

decomposeGraph :: ComputationalGraph -> DecompositionResult
decomposeGraph (ComputationalGraph adjMap) = 
    let 
        symmetricAdj = buildSymmetricAdjacency adjMap
        allNodes = Map.keys adjMap
        
        initialGlobalState = GlobalState 
            { globalVisited = Set.empty
            , globalTree = []
            , globalCycle = []
            , processedIds = Set.empty
            }

        finalState = foldl' (processComponent symmetricAdj) initialGlobalState allNodes
    in 
        (globalTree finalState, globalCycle finalState)

processComponent :: Map.Map NodeIdentifier [(NodeIdentifier, InternalEdge)] 
                 -> GlobalState 
                 -> NodeIdentifier 
                 -> GlobalState
processComponent adj state startNode
    | Set.member startNode (globalVisited state) = state
    | otherwise = runBFS adj state (Seq.singleton startNode)

runBFS :: Map.Map NodeIdentifier [(NodeIdentifier, InternalEdge)] 
       -> GlobalState 
       -> Seq.Seq NodeIdentifier
       -> GlobalState
runBFS adj state queue =
    case viewl queue of
        EmptyL -> state
        
        u :< restQueue -> 
            let 
                neighbors = Map.findWithDefault [] u adj
                
                processNeighbor (currState, currQueue) (neighborNode, edge) =
                    let edgeId = edgeIdentifier edge
                    in
                    if Set.member edgeId (processedIds currState)
                    then (currState, currQueue)
                    else 
                        let newProcessed = Set.insert edgeId (processedIds currState)
                        in 
                        if Set.member neighborNode (globalVisited currState)
                        then 
                            ( currState { 
                                processedIds = newProcessed,
                                globalCycle = edge : globalCycle currState 
                              }
                            , currQueue
                            )
                        else 
                            ( currState { 
                                processedIds = newProcessed,
                                globalVisited = Set.insert neighborNode (globalVisited currState),
                                globalTree = edge : globalTree currState
                              }
                            , currQueue |> neighborNode
                            )

                (newState, nextQueue) = foldl' processNeighbor (state, restQueue) neighbors
            in 
                runBFS adj newState nextQueue

buildSymmetricAdjacency :: Map.Map NodeIdentifier [InternalEdge] -> Map.Map NodeIdentifier [(NodeIdentifier, InternalEdge)]
buildSymmetricAdjacency directedMap = 
    Map.foldlWithKey' addEdges Map.empty directedMap
  where
    addEdges acc srcNode edges = foldl' (addSingleEdge srcNode) acc edges
    
    addSingleEdge src acc edge = 
        let dst = destinationNode edge
            acc1 = Map.insertWith (++) src [(dst, edge)] acc
            acc2 = Map.insertWith (++) dst [(src, edge)] acc1
        in acc2