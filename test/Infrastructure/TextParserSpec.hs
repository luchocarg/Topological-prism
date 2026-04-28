module Infrastructure.TextParserSpec (tests) where

import Test.QuickCheck
import Infrastructure.TextParser (parseGraphText)
import Data.Either (isRight, isLeft)


prop_parseValidString :: Bool
prop_parseValidString = 
    let input = "1 -> 2 : 10.0\n2 -> 3 : 5.5"
    in case parseGraphText input of
        Right edges -> length edges == 2
        Left _ -> False

prop_parseWhitespace :: Bool
prop_parseWhitespace = 
    let input = "  1   ->  2 :   20   "
    in case parseGraphText input of
        Right [(u, v, f)] -> u == 1 && v == 2 && f == 20.0
        _ -> False

prop_parseInvalidInput :: Bool
prop_parseInvalidInput = 
    let input = "That's not a graph"
    in isLeft (parseGraphText input)

tests :: IO ()
tests = do
    putStrLn "\n[Infrastructure.TextParser] Verifying Syntax..."
    
    putStrLn "  Basic Parsing"
    quickCheck prop_parseValidString
    
    putStrLn "  Whitespace Tolerance"
    quickCheck prop_parseWhitespace
    
    putStrLn "  Invalid Input Rejection"
    quickCheck prop_parseInvalidInput