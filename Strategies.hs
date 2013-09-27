{-# OPTIONS_GHC -XNoMonomorphismRestriction #-}

module Strategies where

import Pattern
import Time
import Dirt
import Data.Ratio
import Control.Applicative

import Utils

stutter n t p = stack $ map (\i -> (t * (fromIntegral i)) ~> p) [0 .. (n-1)]

echo   = stutter 2
triple = stutter 3
quad   = stutter 4
double = echo

superimpose f p = stack [p, f p]

-- every 4 (smash 4 [1, 2, 3]) $ sound "[odx sn/2 [~ odx] sn/3, [~ hh]*4]"

smash n xs p = slowcat $ map (\n -> slow n p') xs
  where p' = striate n p

brak = every 2 (((1%4) <~) . (\x -> cat [x, silence]))

-- samples "jvbass [~ latibro] [jvbass [latibro jvbass]]" ((1%2) <~ slow 6 "[1 6 8 7 3]")

samples :: Applicative f => f String -> f Int -> f String
samples p p' = pick <$> p <*> p'

spread :: (a -> t -> Pattern b) -> [a] -> t -> Pattern b
spread f xs p = cat $ map (\x -> f x p) xs

slowspread :: (a -> t -> Pattern b) -> [a] -> t -> Pattern b
slowspread f xs p = slow (fromIntegral $ length $ xs) $ spread f xs p

spread' :: (a -> Pattern b -> Pattern c) -> Pattern a -> Pattern b -> Pattern c
spread' f timepat pat =
  Pattern $ \r -> concatMap (\(r', x) -> (arc (f x pat) r')) (rs r)
  where rs r = arc (filterOffsets timepat) r

{-
scrumple :: Time -> Pattern a -> Pattern a -> Pattern a
scrumple o p p' = p'' -- overlay p (o ~> p'')
  where p'' = Pattern $ \a -> concatMap 
                              (\((s,d), vs) -> map (\x -> ((s,d),
                                                           snd x
                                                          )
                                                   )
                                                   (arc p' (s,s))
                              ) (arc p a)
-}

whenmod :: Int -> Int -> (Pattern a -> Pattern a) -> Pattern a -> Pattern a
whenmod a b = Pattern.when ((\t -> (t `mod` a) >= b ))

--rev :: Pattern a -> Pattern a
--rev p = Pattern $ \a -> concatMap 
--                        (\a' -> mapFsts mirrorArc $ 
--                                (arc p (mirrorArc a')))
--                        (arcCycles a)

trunc :: Time -> Pattern a -> Pattern a
trunc t p = slow t $ Pattern $ \a -> concatMap f $ arcCycles a
  where f a = mapFsts (stretch . trunc') $ arc p (trunc' a)
        trunc' (s,e) = (min s ((sam s) + t), min e ((sam s) + t))
        stretch (s,e) = (sam s + ((s - sam s) / t), sam s + ((e - sam s) / t))

{-stripe :: Arc -> Pattern a -> Pattern a
stripe (stripeS, stripeE) p = slow t $ Pattern $ \a -> concatMap f $ arcCycles a
  where f a = mapFsts (stretch . stripe') $ arc p (stripe' a)
        trunc' (s,e) = (min s ((sam s) + t), min e ((sam s) + t))
        stretch (s,e) = (sam s + ((s - sam s) / t), sam s + ((e - sam s) / t))
-}
