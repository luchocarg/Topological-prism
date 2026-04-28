module ContinuousMath.StokesSpec (tests) where

import Test.QuickCheck
import qualified Data.Map.Strict as Map
import Domain.Types
import Common.Generators (genConnectedGraph)
import ContinuousMath.Stokes (calculateRotationalFlow)
import ContinuousMath.Gauss (calculateDivergences)
import ContinuousMath.Potential (solvePotentials)


prop_isSolenoidal :: ComputationalGraph -> Property
prop_isSolenoidal graph@(ComputationalGraph adjMap) =
    let
        allEdges = concat (Map.elems adjMap)
        
        divMap = calculateDivergences graph

        potMap = solvePotentials graph divMap
        
        rotMap = calculateRotationalFlow allEdges potMap
        
        mkRotEdge e = e { currentFlow = Map.findWithDefault 0.0 (edgeIdentifier e) rotMap }
        rotEdges = map mkRotEdge allEdges
        
        allNodes = Map.keys adjMap
        rotAdj = Map.fromListWith (++) $
                 [ (n, []) | n <- allNodes ] ++
                 [ (sourceNode e, [e]) | e <- rotEdges ]
        
        rotGraph = ComputationalGraph rotAdj
        
        rotDivs = calculateDivergences rotGraph
        epsilon = 1e-9
    in
        counterexample ("Rotational field is not solenoidal. Divs: " ++ show rotDivs) $
        all (\d -> abs d < epsilon) (Map.elems rotDivs)

tests :: IO ()
tests = do
    putStrLn "\n[ContinuousMath.Stokes] Verifying Laws..."
    
    --Div(F_rot) == 0
    putStrLn "Solenoidal Property"
    quickCheck $ forAll genConnectedGraph prop_isSolenoidal