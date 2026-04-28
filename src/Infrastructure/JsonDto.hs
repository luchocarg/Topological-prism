{-# LANGUAGE OverloadedStrings #-}

module Infrastructure.JsonDto where

import Data.Aeson
import Control.Applicative ((<|>))

-- INPUT DTOs

data IncomingEdgeDto = IncomingEdgeDto {
    incomingEdgeId :: Int,
    incomingEdgeFrom :: Int,
    incomingEdgeTo :: Int,
    incomingEdgeFlow :: Double
} deriving (Show)

instance FromJSON IncomingEdgeDto where
    parseJSON (Object v) = IncomingEdgeDto
        <$> v .: "incomingEdgeId"
        <*> v .: "incomingEdgeFrom"
        <*> v .: "incomingEdgeTo"
        <*> v .: "incomingEdgeFlow"
    parseJSON _ = fail "Expected an object for IncomingEdgeDto"

instance ToJSON IncomingEdgeDto where
    toJSON (IncomingEdgeDto i f t w) =
        object [ "incomingEdgeId" .= i
               , "incomingEdgeFrom" .= f
               , "incomingEdgeTo" .= t
               , "incomingEdgeFlow" .= w
               ]

data IncomingGraphDto = IncomingGraphDto {
    incomingGraphNodes :: [Int],
    incomingGraphEdges :: [IncomingEdgeDto]
} deriving (Show)

instance FromJSON IncomingGraphDto where
    parseJSON (Object v) = IncomingGraphDto
        <$> v .: "incomingGraphNodes"
        <*> v .: "incomingGraphEdges"
    parseJSON _ = fail "Expected an object for IncomingGraphDto"

instance ToJSON IncomingGraphDto where
    toJSON (IncomingGraphDto n e) =
        object [ "incomingGraphNodes" .= n
               , "incomingGraphEdges" .= e
               ]

-- OUTPUT DTOs

data OutgoingEdgeResultDto = OutgoingEdgeResultDto {
    outgoingEdgeResultId :: Int,
    outgoingEdgeResultSource :: Int,
    outgoingEdgeResultTarget :: Int,
    outgoingEdgeResultGradient :: Double,
    outgoingEdgeResultRotational :: Double
} deriving (Show)

instance ToJSON OutgoingEdgeResultDto where
    toJSON (OutgoingEdgeResultDto i s t g r) =
        object [ "outgoingEdgeResultId" .= i
               , "outgoingEdgeResultSource" .= s
               , "outgoingEdgeResultTarget" .= t
               , "outgoingEdgeResultGradient" .= g
               , "outgoingEdgeResultRotational" .= r
               ]

data OutgoingNodeResultDto = OutgoingNodeResultDto {
    outgoingNodeResultId :: Int,
    outgoingNodeResultDivergence :: Double,
    outgoingNodeResultPotential :: Double
} deriving (Show)

instance ToJSON OutgoingNodeResultDto where
    toJSON (OutgoingNodeResultDto i d p) =
        object [ "outgoingNodeResultId" .= i
               , "outgoingNodeResultDivergence" .= d
               , "outgoingNodeResultPotential" .= p
               ]

data OutgoingSimulationResultDto = OutgoingSimulationResultDto {
    outgoingSimulationResultNodes :: [OutgoingNodeResultDto],
    outgoingSimulationResultEdges :: [OutgoingEdgeResultDto],
    outgoingSimulationResultIsConservative :: Bool
} deriving (Show)

instance ToJSON OutgoingSimulationResultDto where
    toJSON (OutgoingSimulationResultDto n e c) =
        object [ "outgoingSimulationResultNodes" .= n
               , "outgoingSimulationResultEdges" .= e
               , "outgoingSimulationResultIsConservative" .= c
               ] 