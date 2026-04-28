module DiscreteMath.TreePath 
    ( findPathInTree
    ) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Sequence as Seq
import Data.Sequence (ViewL(..), (|>), viewl)
import Data.List (foldl')
import Domain.Types

findPathInTree :: [InternalEdge] -> NodeIdentifier -> NodeIdentifier -> Maybe [InternalEdge]
findPathInTree treeEdges startNode endNode 
    | startNode == endNode = Just []
    | otherwise = 
        let 
            adj = buildSymmetricAdjacency treeEdges
            
            initialState = BFSState 
                { queue = Seq.singleton startNode
                , visited = Set.singleton startNode
                , parents = Map.empty 
                }
        in 
            runBFS adj endNode initialState


data BFSState = BFSState {
    queue   :: Seq.Seq NodeIdentifier,
    visited :: Set.Set NodeIdentifier,
    parents :: Map.Map NodeIdentifier (InternalEdge, NodeIdentifier)
}

runBFS :: Map.Map NodeIdentifier [InternalEdge] -> NodeIdentifier -> BFSState -> Maybe [InternalEdge]
runBFS adj target state =
    case viewl (queue state) of
        EmptyL -> Nothing
        
        u :< restQueue -> 
            if u == target 
            then Just (reconstructPath target (parents state))
            else 
                let 
                    neighbors = Map.findWithDefault [] u adj
                    
                    processNeighbor (st, newNodes) edge = 
                        let 
                            v = if sourceNode edge == u then destinationNode edge else sourceNode edge
                        in
                            if Set.member v (visited st)
                            then (st, newNodes)
                            else 
                                ( st { visited = Set.insert v (visited st)
                                     , parents = Map.insert v (edge, u) (parents st)
                                     }
                                , newNodes |> v
                                )
                    
                    (newState, nextNodes) = foldl' processNeighbor (state { queue = restQueue }, Seq.empty) neighbors
                in 
                    runBFS adj target (newState { queue = queue newState Seq.>< nextNodes })

reconstructPath :: NodeIdentifier -> Map.Map NodeIdentifier (InternalEdge, NodeIdentifier) -> [InternalEdge]
reconstructPath current parentsMap =
    case Map.lookup current parentsMap of
        Nothing -> []
        Just (edge, parent) -> reconstructPath parent parentsMap ++ [edge]

buildSymmetricAdjacency :: [InternalEdge] -> Map.Map NodeIdentifier [InternalEdge]
buildSymmetricAdjacency edges = 
    foldl' addEdge Map.empty edges
  where
    addEdge acc edge = 
        let u = sourceNode edge
            v = destinationNode edge
            acc1 = Map.insertWith (++) u [edge] acc
            acc2 = Map.insertWith (++) v [edge] acc1
        in acc2