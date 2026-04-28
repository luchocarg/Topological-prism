module Main where

import qualified Common.GeneratorsSpec as GenSpec

import qualified DiscreteMath.DecomposeGraphSpec as DecomposeSpec
import qualified DiscreteMath.TreePathSpec as PathSpec

import qualified ContinuousMath.GaussSpec as GaussSpec
import qualified ContinuousMath.StokesSpec as StokesSpec
import qualified ContinuousMath.DecompositionSpec as DecompSpec
import qualified ContinuousMath.PotentialSpec as PotSpec

import qualified Infrastructure.TextParserSpec as TextParserSpec
import qualified Infrastructure.MappersSpec as MapSpec

import qualified MainSpec as IntegrationSpec

main :: IO ()
main = do
    putStrLn "\n----------------------------------------"
    
    TextParserSpec.tests
    MapSpec.tests

    putStrLn "\n----------------------------------------"

    GenSpec.tests

    putStrLn "\n----------------------------------------"

    DecomposeSpec.tests
    PathSpec.tests

    putStrLn "\n----------------------------------------"

    GaussSpec.tests
    StokesSpec.tests
    PotSpec.tests
    DecompSpec.tests

    putStrLn "\n----------------------------------------"

    IntegrationSpec.tests

    putStrLn "\n════════════════════════════════════════"
    putStrLn "\nAll right"