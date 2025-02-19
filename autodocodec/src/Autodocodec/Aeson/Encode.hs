{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures -fno-warn-orphans #-}

module Autodocodec.Aeson.Encode where

import Autodocodec.Class
import Autodocodec.Codec
import Autodocodec.DerivingVia
import Data.Aeson (toJSON)
import qualified Data.Aeson as JSON
import qualified Data.Aeson.Encoding as JSON
import Data.HashMap.Strict (HashMap)
import Data.Map (Map)
import Data.Scientific
import Data.Text (Text)
import Data.Vector (Vector)
import qualified Data.Vector as V

-- | Encode a value using its JSON codec.
toJSONViaCodec :: HasCodec a => a -> JSON.Value
toJSONViaCodec = toJSONVia codec

-- | Encode a value using a codec for it.
toJSONVia :: ValueCodec a void -> a -> JSON.Value
toJSONVia = flip go
  where
    -- We use type-annotations here for readability of type information that is
    -- gathered to case-matching on GADTs, they aren't strictly necessary.
    go :: a -> ValueCodec a void -> JSON.Value
    go a = \case
      NullCodec -> JSON.Null
      BoolCodec _ -> toJSON (a :: Bool)
      StringCodec _ -> toJSON (a :: Text)
      NumberCodec _ -> toJSON (a :: Scientific)
      ArrayOfCodec _ c -> toJSON (fmap (`go` c) (a :: Vector _))
      ObjectOfCodec _ oc -> JSON.Object (goObject a oc)
      HashMapCodec c -> JSON.liftToJSON (`go` c) (`go` listCodec c) (a :: HashMap _ _)
      MapCodec c -> JSON.liftToJSON (`go` c) (`go` listCodec c) (a :: Map _ _)
      ValueCodec -> (a :: JSON.Value)
      EqCodec value c -> go value c
      BimapCodec _ g c -> go (g a) c
      EitherCodec c1 c2 -> case (a :: Either _ _) of
        Left a1 -> go a1 c1
        Right a2 -> go a2 c2
      CommentCodec _ c -> go a c
      ReferenceCodec _ c -> go a c

    goObject :: a -> ObjectCodec a void -> JSON.Object
    goObject a = \case
      RequiredKeyCodec k c _ -> k JSON..= go a c
      OptionalKeyCodec k c _ -> case (a :: Maybe _) of
        Nothing -> mempty
        Just b -> k JSON..= go b c
      OptionalKeyWithDefaultCodec k c _ mdoc -> goObject (Just a) (OptionalKeyCodec k c mdoc)
      OptionalKeyWithOmittedDefaultCodec k c defaultValue mdoc ->
        if a == defaultValue
          then mempty
          else goObject a (OptionalKeyWithDefaultCodec k c defaultValue mdoc)
      BimapCodec _ g c -> goObject (g a) c
      PureCodec _ -> mempty
      ApCodec oc1 oc2 -> goObject a oc1 <> goObject a oc2

toEncodingViaCodec :: HasCodec a => a -> JSON.Encoding
toEncodingViaCodec = toEncodingVia codec

toEncodingVia :: ValueCodec a void -> a -> JSON.Encoding
toEncodingVia = flip go
  where
    go :: a -> ValueCodec a void -> JSON.Encoding
    go a = \case
      NullCodec -> JSON.null_
      BoolCodec _ -> JSON.bool (a :: Bool)
      StringCodec _ -> JSON.text (a :: Text)
      NumberCodec _ -> JSON.scientific (a :: Scientific)
      ArrayOfCodec _ c -> JSON.list (`go` c) (V.toList (a :: Vector _))
      ObjectOfCodec _ oc -> JSON.pairs (goObject a oc)
      HashMapCodec c -> JSON.liftToEncoding (`go` c) (`go` listCodec c) (a :: HashMap _ _)
      MapCodec c -> JSON.liftToEncoding (`go` c) (`go` listCodec c) (a :: Map _ _)
      ValueCodec -> JSON.value (a :: JSON.Value)
      EqCodec value c -> go value c
      BimapCodec _ g c -> go (g a) c
      EitherCodec c1 c2 -> case (a :: Either _ _) of
        Left a1 -> go a1 c1
        Right a2 -> go a2 c2
      CommentCodec _ c -> go a c
      ReferenceCodec _ c -> go a c
    goObject :: a -> ObjectCodec a void -> JSON.Series
    goObject a = \case
      RequiredKeyCodec k c _ -> JSON.pair k (go a c)
      OptionalKeyCodec k c _ -> case (a :: Maybe _) of
        Nothing -> mempty :: JSON.Series
        Just b -> JSON.pair k (go b c)
      OptionalKeyWithDefaultCodec k c _ mdoc -> goObject (Just a) (OptionalKeyCodec k c mdoc)
      OptionalKeyWithOmittedDefaultCodec k c defaultValue mdoc ->
        if a == defaultValue
          then mempty
          else goObject a (OptionalKeyWithDefaultCodec k c defaultValue mdoc)
      PureCodec _ -> mempty :: JSON.Series
      BimapCodec _ g c -> goObject (g a) c
      ApCodec oc1 oc2 -> goObject a oc1 <> goObject a oc2

instance HasCodec a => JSON.ToJSON (Autodocodec a) where
  toJSON = toJSONViaCodec . unAutodocodec
  toEncoding = toEncodingViaCodec . unAutodocodec
