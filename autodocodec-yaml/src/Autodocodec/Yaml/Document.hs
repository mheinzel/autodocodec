{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Autodocodec.Yaml.Document where

import Autodocodec
import Autodocodec.Aeson
import Text.Colour

schemaChunksViaCodec :: forall a. HasCodec a => [Chunk]
schemaChunksViaCodec = schemaChunksVia (codec @a)

schemaChunksVia :: Codec input output -> [Chunk]
schemaChunksVia = jsonSchemaChunks . jsonSchemaVia

jsonSchemaChunks :: JSONSchema -> [Chunk]
jsonSchemaChunks = concatMap (\l -> l ++ ["\n"]) . go
  where
    indent :: [[Chunk]] -> [[Chunk]]
    indent = map ("  " :)

    addInFrontOfFirstInList :: [Chunk] -> [[Chunk]] -> [[Chunk]]
    addInFrontOfFirstInList cs = \case
      [] -> [cs] -- Shouldn't happen, but fine if it doesn't
      (l : ls) -> (cs ++ l) : indent ls

    go :: JSONSchema -> [[Chunk]]
    go = \case
      AnySchema -> [[fore yellow "<any>"]]
      NullSchema -> [[fore yellow "null"]]
      BoolSchema -> [[fore yellow "<boolean>"]]
      StringSchema -> [[fore yellow "<string>"]]
      NumberSchema -> [[fore yellow "<number>"]]
      ArraySchema s ->
        let addListMarker = addInFrontOfFirstInList ["- "]
         in addListMarker $ go s -- TODO add the dash
      ObjectSchema s -> goObject s
      ChoiceSchema s -> concatMap go s -- TODO add the list
    goObject :: JSONObjectSchema -> [[Chunk]]
    goObject = \case
      AnyObjectSchema -> [["<object>"]]
      KeySchema k ss -> addInFrontOfFirstInList [fore white $ chunk k, ":", " "] ([fore red "# required"] : go ss)
      BothObjectSchema os1 os2 -> goObject os1 ++ goObject os2
