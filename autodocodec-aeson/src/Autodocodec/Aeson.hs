{-# OPTIONS_GHC -fno-warn-dodgy-exports -fno-warn-duplicate-exports #-}

module Autodocodec.Aeson
  ( -- * Encoding
    encodeViaCodec,
    toJSONViaCodec,
    toJSONVia,
    toContextVia,

    -- * Decoding
    eitherDecodeViaCodec,
    parseJSONViaCodec,
    parseJSONVia,
    parseContextVia,

    -- * To makes sure we definitely export everything.
    module Autodocodec.Aeson.Decode,
    module Autodocodec.Aeson.DerivingVia,
    module Autodocodec.Aeson.Encode,
  )
where

import Autodocodec
import Autodocodec.Aeson.Decode
import Autodocodec.Aeson.DerivingVia ()
import Autodocodec.Aeson.Encode
import qualified Data.Aeson as Aeson (eitherDecode, encode)
import qualified Data.ByteString.Lazy as LB

-- | Encode a value as 'LB.ByteString' via its type's 'codec'.
encodeViaCodec :: HasCodec a => a -> LB.ByteString
encodeViaCodec = Aeson.encode . Autodocodec

-- | Parse a 'LB.ByteString' using a type's 'codec'.
eitherDecodeViaCodec :: HasCodec a => LB.ByteString -> Either String a
eitherDecodeViaCodec = fmap unAutodocodec . Aeson.eitherDecode
