{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ParallelListComp #-}
{-# LANGUAGE PatternGuards #-}
{-# LANGUAGE RankNTypes #-}

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

module CodeWorld.Parameter
  {-# WARNING "This is an experimental API.  It can change at any time." #-}
  ( Parameter,
    parametricDrawingOf,
    parameterOf,
    paramConversion,
    constant,
    toggle,
    slider,
    random,
    timer,
    currentHour,
    currentMinute,
    currentSecond,
  )
where

import CodeWorld
import CodeWorld.Driver (runInspect)
import Data.Maybe (catMaybes)
import Data.Text (Text, pack)
import qualified Data.Text as T
import Data.Time.Clock
import Data.Time.LocalTime
import Numeric (showFFloatAlt)
import System.IO.Unsafe (unsafePerformIO)
import System.Random (newStdGen, randomR)

type Bounds = (Double, Double, Double, Double)

data Parameter where
  Parameter ::
    Text ->
    Double ->
    Maybe Picture ->
    Bounds ->
    (Event -> Parameter) ->
    Parameter

-- | A drawing that depends on parameters.  A parameter is a
parametricDrawingOf :: [Parameter] -> ([Double] -> Picture) -> IO ()
parametricDrawingOf initialParams mainPic =
  runInspect
    (layout (-7) 9.5 initialParams, True, 5)
    (const id)
    change
    picture
    rawPicture
  where
    layout _ _ [] = []
    layout x y (p : ps)
      | y > (-9.5) + h + 0.7 =
        framedParam x (y - 1.2) p : layout x (y - h - 1.2) ps
      | otherwise = layout (x + 6) 9.5 (p : ps)
      where
        h
          | Parameter _ _ Nothing _ _ <- p = 0
          | otherwise = 1
    change (KeyPress " ") (params, vis, _) = (params, not vis, 2)
    change event (params, vis, t) =
      (map (changeParam event) params, vis, changeTime event t)
    picture (params, False, t) =
      showHideBanner t
        & mainPic (map getParam params)
    picture (params, True, t) =
      showHideBanner t
        & pictures (catMaybes (map showParam params))
        & mainPic (map getParam params)
    rawPicture (params, _, _) = mainPic (map getParam params)
    changeParam event (Parameter _ _ _ _ handle) = handle event
    showParam (Parameter _ _ pic _ _) = pic
    getParam (Parameter _ val _ _ _) = val
    changeTime (TimePassing dt) t = max 0 (t - dt)
    changeTime _ t = t
    showHideBanner 0 = blank
    showHideBanner t =
      dilated 0.7 $
        colored (RGBA 0 0 0 t) (rectangle 10 2.5)
          & colored
            (RGBA 0 0 0 t)
            (translated 0 0.5 $ lettering "Press 'Space' to")
          & colored
            (RGBA 0 0 0 t)
            (translated 0 (-0.5) $ lettering "show/hide parameters.")
          & colored (RGBA 0.75 0.75 0.75 (min 0.8 t)) (solidRectangle 10 2.5)

parameterOf ::
  Text ->
  state ->
  (Event -> state -> state) ->
  (state -> Double) ->
  (state -> Maybe Picture) ->
  (state -> Bounds) ->
  Parameter
parameterOf name initial change value picture bounds =
  Parameter
    name
    (value initial)
    (picture initial)
    (bounds initial)
    (\e -> parameterOf name (change e initial) change value picture bounds)

paramConversion :: (Double -> Double) -> Parameter -> Parameter
paramConversion c (Parameter name val pic bounds handle) =
  Parameter name (c val) pic bounds (paramConversion c . handle)

framedParam :: Double -> Double -> Parameter -> Parameter
framedParam ix iy iparam =
  parameterOf
    (paramName iparam)
    (iparam, (ix, iy), True, Nothing)
    frameHandle
    frameValue
    framePicture
    frameBounds
  where
    frameHandle (PointerPress (px, py)) (param, (x, y), open, anchor)
      | onOpenButton = (param, (x, y), not open, anchor)
      | onTitleBar = (param, (x, y), open, Just (px, py))
      where
        onTitleBar = abs (px - x) < 2.5 && abs (py - y - 0.85) < 0.35
        onOpenButton = abs (px - x - 2.15) < 0.2 && abs (py - y - 0.85) < 0.2
    frameHandle (PointerRelease _) (param, loc, open, Just _) =
      (param, loc, open, Nothing)
    frameHandle (PointerMovement (px, py)) (param, (x, y), open, Just (ax, ay)) =
      (param, (x + px - ax, y + py - ay), open, Just (px, py))
    frameHandle event (Parameter _ _ _ _ handle, (x, y), True, anchor) =
      (handle (untranslate x y event), (x, y), True, anchor)
    frameHandle (TimePassing dt) (Parameter _ _ _ _ handle, loc, open, anchor) =
      (handle (TimePassing dt), loc, open, anchor)
    frameHandle _ other = other
    frameValue (Parameter _ v _ _ _, _, _, _) = v
    framePicture (Parameter n v picture _ _, (x, y), open, _) =
      Just
        $ translated x y
        $ translated 0 0.85 (titleBar n v open picture)
          & clientArea open picture
    frameBounds _ = (-10, -10, 20, 20)
    titleBar n v open (Just _) =
      rectangle 5 0.7
        & translated 2.15 0 (if open then collapseButton else expandButton)
        & translated (-0.35) 0 (clipped 4.3 0.7 (dilated 0.5 (lettering (titleText n v))))
        & colored titleColor (solidRectangle 5 0.7)
    titleBar n v _ Nothing =
      rectangle 5 0.7
        & clipped 5 0.7 (dilated 0.5 (lettering (titleText n v)))
        & colored titleColor (solidRectangle 5 0.7)
    titleText n v
      | T.length n > 10 = T.take 8 n <> "... = " <> formatVal v
      | otherwise = n <> " = " <> formatVal v
    collapseButton = rectangle 0.4 0.4 & solidPolygon [(-0.1, -0.1), (0.1, -0.1), (0, 0.1)]
    expandButton = rectangle 0.4 0.4 & solidPolygon [(-0.1, 0.1), (0.1, 0.1), (0, -0.1)]
    clientArea True (Just pic) =
      rectangle 5 1
        & clipped 5 1 pic
        & colored bgColor (solidRectangle 5 1)
    clientArea _ _ = blank
    untranslate x y (PointerPress (px, py)) = PointerPress (px - x, py - y)
    untranslate x y (PointerRelease (px, py)) = PointerRelease (px - x, py - y)
    untranslate x y (PointerMovement (px, py)) = PointerMovement (px - x, py - y)
    untranslate _ _ other = other
    paramName (Parameter n _ _ _ _) = n
    formatVal v = pack (showFFloatAlt (Just 2) v "")

constant :: Text -> Double -> Parameter
constant name n =
  parameterOf
    name
    n
    (const id)
    id
    (const Nothing)
    (const (0, 0, 0, 0))

toggle :: Text -> Parameter
toggle name =
  parameterOf
    name
    False
    change
    value
    picture
    (const (-2.5, -0.5, 5, 1))
  where
    change (PointerPress (px, py))
      | abs px < 4, abs py < 1 = not
    change _ = id
    value True = 1
    value False = 0
    picture True = Just $ dilated 0.5 $ lettering "\x2611"
    picture False = Just $ dilated 0.5 $ lettering "\x2610"

slider :: Text -> Parameter
slider name =
  parameterOf
    name
    (0.5, False)
    change
    fst
    picture
    (const (-2.5, 0.5, 5, 1))
  where
    change (PointerPress (px, py)) (_, _)
      | abs px < 2, abs py < 0.25 = (min 1 $ max 0 $ (px + 2) / 4, True)
    change (PointerRelease _) (v, _) = (v, False)
    change (PointerMovement (px, _)) (_, True) =
      (min 1 $ max 0 $ (px + 2) / 4, True)
    change _ state = state
    picture (v, _) =
      Just $
        translated (v * 4 - 2) 0 (solidRectangle 0.125 0.5)
          & solidRectangle 4 0.1

random :: Text -> Parameter
random name =
  parameterOf
    name
    (next (unsafePerformIO newStdGen))
    change
    fst
    (const $ Just $ dilated 0.5 $ lettering "\x21ba Regenerate")
    (const (-2.5, 0.5, 5, 1))
  where
    change (PointerPress (px, py))
      | abs px < 4, abs py < 1 = next . snd
    change _ = id
    next = randomR (0.0, 1.0)

timer :: Text -> Parameter
timer name =
  parameterOf
    name
    (0, 1)
    change
    fst
    picture
    (const (-2.5, 0.5, 5, 1))
  where
    change (TimePassing dt) (t, r) = (t + r * dt, r)
    change (PointerPress (px, py)) (t, r)
      | abs (px - 5 / 6) < 5 / 6, abs py < 0.75 = (t, 1 - r)
      | abs (px + 5 / 6) < 5 / 6, abs py < 0.75 = (0, 0)
    change _ state = state
    picture (_, 0) =
      Just $
        (translated (5 / 6) 0 $ dilated 0.5 $ lettering "\x23e9")
          & (translated (-5 / 6) 0 $ dilated 0.5 $ lettering "\x23ee")
    picture _ =
      Just $
        (translated (5 / 6) 0 $ dilated 0.5 $ lettering "\x23f8")
          & (translated (-5 / 6) 0 $ dilated 0.5 $ lettering "\x23ee")

currentHour :: Parameter
currentHour =
  parameterOf
    "hour"
    ()
    (const id)
    (const $ unsafePerformIO $ fromIntegral <$> todHour <$> getTimeOfDay)
    (const Nothing)
    (const (0, 0, 0, 0))

currentMinute :: Parameter
currentMinute =
  parameterOf
    "minute"
    ()
    (const id)
    (const $ unsafePerformIO $ fromIntegral <$> todMin <$> getTimeOfDay)
    (const Nothing)
    (const (0, 0, 0, 0))

currentSecond :: Parameter
currentSecond =
  parameterOf
    "second"
    ()
    (const id)
    (const $ unsafePerformIO $ realToFrac <$> todSec <$> getTimeOfDay)
    (const Nothing)
    (const (0, 0, 0, 0))

getTimeOfDay :: IO TimeOfDay
getTimeOfDay = do
  now <- getCurrentTime
  timezone <- getCurrentTimeZone
  return (localTimeOfDay (utcToLocalTime timezone now))

titleColor :: Color
titleColor = RGBA 0.7 0.7 0.7 0.9

bgColor :: Color
bgColor = RGBA 0.8 0.85 0.95 0.8
