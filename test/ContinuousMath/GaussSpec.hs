module ContinuousMath.GaussSpec (tests) where

import Test.QuickCheck
import qualified Data.Map.Strict as Map
import Domain.Types
import Common.Generators (genGraphWithConfig, defaultGenConfig)
import ContinuousMath.Gauss (calculateTotalSystemDivergence)


prop_conservationOfMass :: ComputationalGraph -> Property
prop_conservationOfMass graph =
    let 
        totalDiv = calculateTotalSystemDivergence graph
        epsilon = 1e-9
    in 
        counterexample ("System is leaking mass. Net Divergence: " ++ show totalDiv) $
        abs totalDiv < epsilon

tests :: IO ()
tests = do
    putStrLn "\n[ContinuousMath.Gauss] Verifying Laws..."
    
    putStrLn "Global Conservation of Mass"
    quickCheck $ forAll (genGraphWithConfig defaultGenConfig) prop_conservationOfMass