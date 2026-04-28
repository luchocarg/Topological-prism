{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StrictData #-}

module Main where

import Foreign.C.String (CString, newCString, peekCString)
import Foreign.Marshal.Alloc (free)
import qualified Data.ByteString.Lazy.Char8 as BS
import Data.Aeson (decode, encode, eitherDecode)

import qualified Infrastructure.JsonDto as Dto
import qualified Infrastructure.Mappers as Mapper
import qualified ContinuousMath.Decomposition as Logic

-- | Exported function to run the Hodge Decomposition.
-- Expects a JSON string pointer (IncomingGraphDto).
-- Returns a JSON string pointer (OutgoingSimulationResultDto).
foreign export ccall "run_decomposition" run_decomposition :: CString -> IO CString

-- | Helper to free memory allocated by newCString.
foreign export ccall "free_haskell_string" free_haskell_string :: CString -> IO ()

run_decomposition :: CString -> IO CString
run_decomposition inputPtr = do
    jsonStr <- peekCString inputPtr
    let inputData = BS.pack jsonStr
    
    let outputData = case eitherDecode inputData :: Either String Dto.IncomingGraphDto of
            Left err -> 
                BS.pack $ "{\"error\": \"failed to decode JSON. Error: " ++ err ++ "\"}"
            
            Right incomingDto -> 
                let domainGraph = Mapper.toComputationalGraph incomingDto
                    simulationResult = Logic.decompose domainGraph
                    outgoingDto = Mapper.toOutgoingDto simulationResult
                in encode outgoingDto

    newCString (BS.unpack outputData)

free_haskell_string :: CString -> IO ()
free_haskell_string = free

main :: IO ()
main = return ()

