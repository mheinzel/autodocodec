{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Autodocodec.Yaml.DocumentSpec (spec) where

import Autodocodec
import Autodocodec.Usage
import Autodocodec.Yaml
import qualified Data.Aeson as JSON
import Data.Data
import Data.GenValidity
import Data.GenValidity.Aeson ()
import Data.GenValidity.Containers ()
import Data.GenValidity.Scientific ()
import Data.GenValidity.Text ()
import Data.GenValidity.Time ()
import Data.Int
import Data.List.NonEmpty (NonEmpty)
import Data.Map (Map)
import Data.Scientific
import Data.Set (Set)
import Data.Text (Text)
import qualified Data.Text.Lazy as LT
import Data.Time
import Data.Word
import Test.Syd
import Test.Syd.Validity.Utils
import Text.Colour

spec :: Spec
spec = do
  yamlSchemaSpec @NullUnit "null"
  yamlSchemaSpec @Bool "bool"
  yamlSchemaSpec @Ordering "ordering"
  yamlSchemaSpec @Char "char"
  yamlSchemaSpec @Text "text"
  yamlSchemaSpec @LT.Text "lazy-text"
  yamlSchemaSpec @String "string"
  yamlSchemaSpec @Scientific "scientific"
  yamlSchemaSpec @JSON.Object "object"
  yamlSchemaSpec @JSON.Value "value"
  yamlSchemaSpec @Int "int"
  yamlSchemaSpec @Int8 "int8"
  yamlSchemaSpec @Int16 "int16"
  yamlSchemaSpec @Int32 "int32"
  yamlSchemaSpec @Int64 "int64"
  yamlSchemaSpec @Word "word"
  yamlSchemaSpec @Word8 "word8"
  yamlSchemaSpec @Word16 "word16"
  yamlSchemaSpec @Word32 "word32"
  yamlSchemaSpec @Word64 "word64"
  yamlSchemaSpec @(Maybe Text) "maybe-text"
  yamlSchemaSpec @(Either Bool Text) "either-bool-text"
  yamlSchemaSpec @(Either (Either Bool Scientific) Text) "either-either-bool-scientific-text"
  yamlSchemaSpec @[Text] "list-text"
  yamlSchemaSpec @(NonEmpty Text) "nonempty-text"
  yamlSchemaSpec @(Set Text) "set-text"
  yamlSchemaSpec @(Map Text Int) "map-text-int"
  yamlSchemaSpec @Day "day"
  yamlSchemaSpec @LocalTime "local-time"
  yamlSchemaSpec @UTCTime "utc-time"
  yamlSchemaSpec @TimeOfDay "time-of-day"
  yamlSchemaSpec @ZonedTime "zoned-time"
  yamlSchemaSpec @DiffTime "difftime"
  yamlSchemaSpec @NominalDiffTime "nominal-difftime"
  yamlSchemaSpec @Fruit "fruit"
  yamlSchemaSpec @Example "example"
  yamlSchemaSpec @Recursive "recursive"
  yamlSchemaSpec @Via "via"
  yamlSchemaSpec @VeryComment "very-comment"

yamlSchemaSpec :: forall a. (Typeable a, GenValid a, HasCodec a) => FilePath -> Spec
yamlSchemaSpec filePath = do
  it ("outputs the same schema as before for " <> nameOf @a) $
    pureGoldenByteStringFile ("test_resources/yaml-schema/" <> filePath <> ".txt") (renderChunksBS With24BitColours $ schemaChunksViaCodec @a)
