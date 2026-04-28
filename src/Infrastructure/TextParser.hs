module Infrastructure.TextParser (
    parseGraphText
) where

import Text.Parsec
import Text.Parsec.String (Parser)
import Text.Parsec.Language (emptyDef)
import qualified Text.Parsec.Token as Token

lexer :: Token.TokenParser ()
lexer = Token.makeTokenParser emptyDef

integer :: Parser Integer
integer = Token.integer lexer

symbol :: String -> Parser String
symbol = Token.symbol lexer

whiteSpace :: Parser ()
whiteSpace = Token.whiteSpace lexer

float :: Parser Double
float = try (Token.float lexer) <|> (fromIntegral <$> integer)

type EdgeDef = (Int, Int, Double)

edgeParser :: Parser EdgeDef
edgeParser = do
    u <- integer
    _ <- symbol "->"
    v <- integer
    _ <- symbol ":"
    f <- float
    return (fromIntegral u, fromIntegral v, f)

graphParser :: Parser [EdgeDef]
graphParser = do
    whiteSpace
    edges <- many edgeParser
    eof
    return edges

parseGraphText :: String -> Either ParseError [EdgeDef]
parseGraphText input = parse graphParser "" input