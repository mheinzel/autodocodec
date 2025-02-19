{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Autodocodec.Yaml.Document where

import Autodocodec
import Autodocodec.Schema
import Data.ByteString (ByteString)
import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.Map as M
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Encoding.Error as TE
import Data.Yaml as Yaml
import Text.Colour

-- | Render a human-readable schema for a type's 'codec', in colour.
renderColouredSchemaViaCodec :: forall a. HasCodec a => ByteString
renderColouredSchemaViaCodec = renderColouredSchemaVia (codec @a)

-- | Render a human-readable schema for a given codec, in colour.
renderColouredSchemaVia :: ValueCodec input output -> ByteString
renderColouredSchemaVia = renderChunksBS With24BitColours . schemaChunksVia

-- | Render a human-readable schema for a type's 'codec', without colour.
renderPlainSchemaViaCodec :: forall a. HasCodec a => ByteString
renderPlainSchemaViaCodec = renderPlainSchemaVia (codec @a)

-- | Render a human-readable schema for a given codec, without colour.
renderPlainSchemaVia :: ValueCodec input output -> ByteString
renderPlainSchemaVia = renderChunksBS WithoutColours . schemaChunksVia

-- | Produce potentially-coloured 'Chunk's for a human-readable schema for a type's 'codec'.
schemaChunksViaCodec :: forall a. HasCodec a => [Chunk]
schemaChunksViaCodec = schemaChunksVia (codec @a)

-- | Produce potentially-coloured 'Chunk's for a human-readable schema for a given codec.
schemaChunksVia :: ValueCodec input output -> [Chunk]
schemaChunksVia = jsonSchemaChunks . jsonSchemaVia

-- | Render a 'JSONSchema' as 'Chunk's
jsonSchemaChunks :: JSONSchema -> [Chunk]
jsonSchemaChunks = concatMap (\l -> l ++ ["\n"]) . go
  where
    indent :: [[Chunk]] -> [[Chunk]]
    indent = map ("  " :)

    addInFrontOfFirstInList :: [Chunk] -> [[Chunk]] -> [[Chunk]]
    addInFrontOfFirstInList cs = \case
      [] -> [cs] -- Shouldn't happen, but fine if it doesn't
      (l : ls) -> (cs ++ l) : indent ls

    jsonValueChunk :: Yaml.Value -> Chunk
    jsonValueChunk v = chunk $ T.strip $ TE.decodeUtf8With TE.lenientDecode (Yaml.encode v)

    docToLines :: Text -> [[Chunk]]
    docToLines doc = map (\line -> [chunk "# ", chunk line]) (T.lines doc)

    go :: JSONSchema -> [[Chunk]]
    go = \case
      AnySchema -> [[fore yellow "<any>"]]
      NullSchema -> [[fore yellow "null"]]
      BoolSchema -> [[fore yellow "<boolean>"]]
      StringSchema -> [[fore yellow "<string>"]]
      NumberSchema -> [[fore yellow "<number>"]]
      ArraySchema s ->
        let addListMarker = addInFrontOfFirstInList ["- "]
         in addListMarker $ go s
      MapSchema s ->
        addInFrontOfFirstInList [fore white "<key>", ": "] $ [] : go s
      ObjectSchema s ->
        let requirementComment = \case
              Required -> fore red "required"
              Optional _ -> fore blue "optional"
            mDefaultValue = \case
              Required -> Nothing
              Optional mdv -> mdv
            keySchemaFor k (kr, ks, mdoc) =
              let keySchemaChunks = go ks
                  defaultValueLine = case mDefaultValue kr of
                    Nothing -> []
                    Just defaultValue -> [[chunk "# default: ", fore magenta $ jsonValueChunk defaultValue]]
                  prefixLines = ["# ", requirementComment kr] : defaultValueLine ++ maybe [] docToLines mdoc
               in addInFrontOfFirstInList [fore white $ chunk k, ": "] (prefixLines ++ keySchemaChunks)
         in if null s
              then [["<object>"]]
              else concatMap (uncurry keySchemaFor) s
      ValueSchema v -> [[jsonValueChunk v]]
      ChoiceSchema s ->
        let addListAround = \case
              s_ :| [] -> addInFrontOfFirstInList ["[ "] (go s_) ++ [["]"]]
              (s_ :| rest) ->
                let chunks = go s_
                    restChunks = map go rest
                 in concat $
                      addInFrontOfFirstInList ["[ "] chunks :
                      map (addInFrontOfFirstInList [", "]) restChunks
                        ++ [[["]"]]]
         in addListAround s
      CommentSchema comment s -> docToLines comment ++ go s
      RefSchema name -> [[fore cyan $ chunk $ "ref: " <> name]]
      WithDefSchema defs (RefSchema _) -> concatMap (\(name, s') -> [fore cyan $ chunk $ "def: " <> name] : go s') (M.toList defs)
      WithDefSchema defs s -> concatMap (\(name, s') -> [fore cyan $ chunk $ "def: " <> name] : go s') (M.toList defs) ++ go s
