module ContinuousMath.DecompositionSpec (tests) where

import Test.QuickCheck
import qualified Data.Map.Strict as Map
import Domain.Types
import Common.Generators (genConnectedGraph)
import ContinuousMath.Decomposition (decompose)

--Helmholtz Reversibility.
prop_reversibility :: ComputationalGraph -> Property
prop_reversibility graph@(ComputationalGraph adjMap) =
    let
        simResult = decompose graph
        
        resultsMap = Map.fromList [ (resultEdgeIdentifier r, r) | r <- edgeResults simResult ]
        
        checkEdge :: InternalEdge -> Bool
        checkEdge edge =
            let
                eid = edgeIdentifier edge
                original = currentFlow edge
                epsilon = 1e-9
            in case Map.lookup eid resultsMap of
                Nothing -> False -- missing for edge
                Just res -> 
                    let reconstructed = gradientComponent res + rotationalComponent res
                    in abs (reconstructed - original) < epsilon
                    
        allEdges = concat (Map.elems adjMap)
    in
        counterexample "Helmholtz decomposition is irreversible" $
        all checkEdge allEdges

tests :: IO ()
tests = do
    putStrLn "\n[ContinuousMath.Decomposition] Verifying Laws..."
    
    putStrLn "Superposition"
    quickCheck $ forAll genConnectedGraph prop_reversibility