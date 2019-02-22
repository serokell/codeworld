{-# LANGUAGE RebindableSyntax #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE PackageImports #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

{-
  Copyright 2019 The CodeWorld Authors. All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-}
module Internal.Color where

import qualified "codeworld-api" CodeWorld as CW
import Internal.Num
import Internal.Truth
import qualified "base" Prelude as P
import "base" Prelude ((.))

newtype Color = Color { toCWColor :: CW.Color } deriving (P.Eq)
type Colour = Color

{-# RULES
"equality/color" forall (x :: Color) . (==) x = (P.==) x
 #-}

pattern RGBA :: (Number, Number, Number, Number) -> Color
pattern RGBA components <- (toRGBA -> components)
  where RGBA components
          = let (r, g, b, a) = components
            in Color (CW.RGBA (toDouble r) (toDouble g)
                              (toDouble b) (toDouble a))

-- Utility function for RGB pattern synonym.
toRGBA :: Color -> (Number, Number, Number, Number)
toRGBA (Color (CW.RGBA r g b a)) =
    (fromDouble r, fromDouble g, fromDouble b, fromDouble a)

pattern RGB :: (Number, Number, Number) -> Color
pattern RGB components <- (toRGB -> P.Just components)
  where RGB components
          = let (r, g, b) = components
            in Color (CW.RGBA (toDouble r) (toDouble g)
                              (toDouble b) (toDouble 1))

-- Utility function for RGB pattern synonym.
toRGB :: Color -> P.Maybe (Number, Number, Number)
toRGB (Color (CW.RGBA r g b (fromDouble -> 1))) =
    P.Just (fromDouble r, fromDouble g, fromDouble b)
toRGB _ = P.Nothing

pattern HSL :: (Number, Number, Number) -> Color
pattern HSL components <- (toHSL -> P.Just components)
  where HSL components = fromHSL components

-- Utility functions for HSL pattern synonym.
toHSL :: Color -> P.Maybe (Number, Number, Number)
toHSL c@(RGBA (_, _, _, 1)) = P.Just (hue c, saturation c, luminosity c)
toHSL _ = P.Nothing

fromHSL :: (Number, Number, Number) -> Color
fromHSL (h, s, l) =
    Color (CW.HSL (toDouble (pi * h / 180)) (toDouble s) (toDouble l))

mixed :: [Color] -> Color
mixed = Color . CW.mixed . P.map toCWColor

lighter :: (Color, Number) -> Color
lighter (c, d) = Color (CW.lighter (toDouble d) (toCWColor c))

light :: Color -> Color
light = Color . CW.light . toCWColor

darker :: (Color, Number) -> Color
darker (c, d) = Color (CW.darker (toDouble d) (toCWColor c))

dark :: Color -> Color
dark = Color . CW.dark . toCWColor

brighter :: (Color, Number) -> Color
brighter (c, d) = Color (CW.brighter (toDouble d) (toCWColor c))

bright :: Color -> Color
bright = Color . CW.bright . toCWColor

duller :: (Color, Number) -> Color
duller (c, d) = Color (CW.duller (toDouble d) (toCWColor c))

dull :: Color -> Color
dull = Color . CW.dull . toCWColor

translucent :: Color -> Color
translucent = Color . CW.translucent . toCWColor

assortedColors :: [Color]
assortedColors = P.map Color CW.assortedColors

hue, saturation, luminosity, alpha :: Color -> Number
hue = (180 *) . (/ pi) . fromDouble . CW.hue . toCWColor

saturation = fromDouble . CW.saturation . toCWColor

luminosity = fromDouble . CW.luminosity . toCWColor

alpha = fromDouble . CW.alpha . toCWColor

-- New style colors

pattern White :: Color
pattern White  = Color CW.White

pattern Black :: Color
pattern Black  = Color CW.Black

pattern Gray :: Color
pattern Gray   = Color CW.Gray

pattern Grey :: Color
pattern Grey   = Color CW.Grey

pattern Red :: Color
pattern Red    = Color CW.Red

pattern Orange :: Color
pattern Orange = Color CW.Orange

pattern Yellow :: Color
pattern Yellow = Color CW.Yellow

pattern Green :: Color
pattern Green  = Color CW.Green

pattern Blue :: Color
pattern Blue   = Color CW.Blue

pattern Purple :: Color
pattern Purple = Color CW.Purple

pattern Pink :: Color
pattern Pink   = Color CW.Pink

pattern Brown :: Color
pattern Brown  = Color CW.Brown

-- Old style colors

white, black, red, green, blue, cyan, magenta, yellow :: Color
orange, rose, chartreuse, aquamarine, violet, azure :: Color
gray, grey :: Color

white = White
black = Black
red = Red
yellow = Yellow
green = Green
blue = Blue
orange = Orange
brown = Brown
purple = Purple
pink = Pink
gray = Gray
grey = Grey

cyan = Color CW.cyan
magenta = Color CW.magenta
chartreuse = Color CW.chartreuse
aquamarine = Color CW.aquamarine
azure = Color CW.azure
violet = Color CW.violet
rose = Color CW.rose

{-# WARNING White      [ "Please use white (lower case) instead of White."
                       , "The value White may be removed July 2019." ] #-}
{-# WARNING Black      [ "Please use black (lower case) instead of Black."
                       , "The value Black may be removed July 2019." ] #-}
{-# WARNING Red        [ "Please use red (lower case) instead of Red."
                       , "The value Red may be removed July 2019." ] #-}
{-# WARNING Green      [ "Please use green (lower case) instead of Green."
                       , "The value Green may be removed July 2019." ] #-}
{-# WARNING Blue       [ "Please use blue (lower case) instead of Blue."
                       , "The value Blue may be removed July 2019." ] #-}
{-# WARNING Yellow     [ "Please use yellow (lower case) instead of Yellow."
                       , "The value Yellow may be removed July 2019." ] #-}
{-# WARNING Orange     [ "Please use orange (lower case) instead of Orange."
                       , "The value Orange may be removed July 2019." ] #-}
{-# WARNING Brown      [ "Please use brown (lower case) instead of Brown."
                       , "The value Brown may be removed July 2019." ] #-}
{-# WARNING Purple     [ "Please use purple (lower case) instead of Purple."
                       , "The value Purple may be removed July 2019." ] #-}
{-# WARNING Pink       [ "Please use pink (lower case) instead of Pink."
                       , "The value Pink may be removed July 2019." ] #-}
{-# WARNING Gray       [ "Please use gray (lower case) instead of Gray."
                       , "The value Gray may be removed July 2019." ] #-}
{-# WARNING Grey       [ "Please use grey (lower case) instead of Gray."
                       , "The value Grey may be removed July 2019." ] #-}

{-# WARNING magenta    [ "Please use RGB(...) instead of magenta."
                       , "The variable magenta may be removed July 2020." ] #-}
{-# WARNING cyan       [ "Please use RGB(...) instead of cyan."
                       , "The variable cyan may be removed July 2020." ] #-}
{-# WARNING chartreuse [ "Please use RGB(...) instead of chartreuse."
                       , "The variable chartreuse may be removed July 2020." ] #-}
{-# WARNING aquamarine [ "Please use RGB(...) instead of aquamarine."
                       , "The variable aquamarine may be removed July 2020." ] #-}
{-# WARNING azure      [ "Please use RGB(...) instead of azure."
                       , "The variable azure may be removed July 2020." ] #-}
{-# WARNING rose       [ "Please use RGB(...) instead of rose."
                       , "The variable rose may be removed July 2020." ] #-}
{-# WARNING violet     [ "Please use Purple instead of violet."
                       , "The variable violet may be removed July 2020." ] #-}
