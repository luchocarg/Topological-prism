module ContinuousMath.PotentialSpec (tests) where

import Test.QuickCheck
import qualified Data.Map.Strict as Map
import Domain.Types
import Common.Generators (genConnectedGraph)
import ContinuousMath.Decomposition (decompose)


prop_gradientConsistency :: ComputationalGraph -> Property
prop_gradientConsistency graph@(ComputationalGraph adjMap) =
    let
        simResult = decompose graph
        
        nodeResMap = Map.fromList [ (resultNodeIdentifier n, potentialValue n) | n <- nodeResults simResult ]
        edgeResMap = Map.fromList [ (resultEdgeIdentifier e, e) | e <- edgeResults simResult ]
        
        epsilon = 1e-9
        
        checkEdge :: InternalEdge -> Bool
        checkEdge edge =
            let
                u = sourceNode edge
                v = destinationNode edge
                eid = edgeIdentifier edge
                
                phi_u = Map.findWithDefault 0.0 u nodeResMap
                phi_v = Map.findWithDefault 0.0 v nodeResMap
                
                res = Map.lookup eid edgeResMap
            in case res of
                Nothing -> False 
                Just r ->
                    let 
                        gradFlow = gradientComponent r
                        potDiff = phi_u - phi_v 
                    in 
                        abs (potDiff - gradFlow) < epsilon

        allEdges = concat (Map.elems adjMap)
    in
        counterexample "Potential difference matches Gradient Flow" $
        all checkEdge allEdges

tests :: IO ()
tests = do
    putStrLn "\n[ContinuousMath.Potential] Verifying Laws..."
    
    -- Phi_u - Phi_v = F_grad
    putStrLn "Gradient Consistency"
    quickCheck $ forAll genConnectedGraph prop_gradientConsistency