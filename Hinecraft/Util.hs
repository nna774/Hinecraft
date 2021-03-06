{-# LANGUAGE BangPatterns #-}
--
-- Copyright : (c) T.Mishima 2014
-- License : Apache-2.0
--
module Hinecraft.Util where
import Data.List as List
import System.Directory
--import Debug.Trace as Dbg

bounded' :: (Ord a) => a -> a -> a -> a
bounded' u l  = min u . max l

round' :: (RealFrac a, Integral b) => a -> b
round' x | 0 > x     = -(round $ abs x)
         | otherwise = round x 

vecSize :: (Num a, Floating a) => (a,a,a) -> a 
vecSize (x,y,z) = sqrt $ x * x + y * y + z * z

(.-.) ::(Num a, Floating a) => (a,a,a) -> (a,a,a) -> (a,a,a)
(.-.) (a1,a2,a3) (b1,b2,b3) = (a1 - b1, a2 - b2, a3 - b3)
(.+.) ::(Num a, Floating a) => (a,a,a) -> (a,a,a) -> (a,a,a)
(.+.) (a1,a2,a3) (b1,b2,b3) = (a1 + b1, a2 + b2, a3 + b3)
(...) ::(Num a, Floating a) => (a,a,a) -> (a,a,a) -> a
(...) (a1,a2,a3) (b1,b2,b3) = a1 * b1 + a2 * b2 + a3 * b3
(.*.) ::(Num a, Floating a) => (a,a,a) -> (a,a,a) -> (a,a,a)
(.*.) (a1,a2,a3) (b1,b2,b3) = (a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1)
(..*.) ::(Num a, Floating a) => (a,a,a) -> a -> (a,a,a)
(..*.) (a1,a2,a3) x = (a1 * x, a2 * x, a3 * x)

-- 
-- 面・線　衝突判定
--
type Pos a = (a,a,a)
type Vec a = (a,a,a)
tomasMollerRaw::(Show a,Ord a,Floating a)
              => Pos a -> Vec a -> Pos a -> Pos a -> Pos a -> Maybe a 
tomasMollerRaw orig dir v0 v1 v2
  | det > 0.001 = if (u < 0 || u > det) || (v < 0 || (u + v) > det) 
      then {- Dbg.trace (unwords ["t1:", show (u < 0 || u > det)
                                 , show u, show det
                                 , show (v < 0 || (u + v) > det)
                                 , show v, show (u+v), show dir ]) $-}
           Nothing 
      else {- Dbg.trace (unwords ["OK t= ",show t]) $ -}
           Just t
--  | det < -0.001 = if (u > 0 || u < det) || (v >0 || (u + v) < det)
--    then {-Dbg.trace ("t2:" ++ show (u,det,v))-} Nothing
--    else Just t 
  | otherwise = {- Dbg.trace ("t3:" ++ show det) $-} Nothing
  where
    !e1 = v1 .-. v0
    !e2 = v2 .-. v0
    !pvec = dir .*. e2
    !det = e1 ... pvec
    !tvec = orig .-. v0
    !u = tvec ... pvec
    !qvec = tvec .*. e1
    !v = dir ... qvec
    !t = (e2 ... qvec) / det

-- ラインプロット
linePlot :: (Integral a) => (a,a,a) -> (a,a,a) -> [(a,a,a)]
linePlot o@(iox,ioy,ioz) p@(ipx,ipy,ipz) = List.nub $ (o : plot) ++ [p]
  where
    !(ox,oy,oz) = (fromIntegral iox,fromIntegral ioy,fromIntegral ioz)
    !(px,py,pz) = (fromIntegral ipx,fromIntegral ipy,fromIntegral ipz)
    !l = sqrt $ (px - ox) ^ (2::Integer)
              + (py - oy) ^ (2::Integer)
              + (pz - oz) ^ (2::Integer)
    !dx = (px - ox) / l
    !dy = (py - oy) / l
    !dz = (pz - oz) / l
    !plot = map (\ dl ->
             ( round' (dx * dl + ox)
             , round' (dy * dl + oy)
             , round' (dz * dl + oz)
             )) $ take (floor l) ([1.0,2.0..]::[Double])

-- 面プロット
surfacePlot :: (Integral a) => (a,a,a) -> (a,a,a) -> (a,a,a) -> [(a,a,a)]
surfacePlot o@(iox,ioy,ioz) p1@(ip1x,ip1y,ip1z) p2@(ip2x,ip2y,ip2z) =
            List.nub suf
  where
    !p3 = ( ip1x + ip2x - iox
          , ip1y + ip2y - ioy
          , ip1z + ip2z - ioz)
    !pline1 = linePlot o  p2
    !pline2 = linePlot p1 p3
    !suf = concatMap (uncurry linePlot) $ zip pline1 pline2

createDirWithChk :: FilePath -> IO Bool
createDirWithChk path = do
  f <- doesDirectoryExist path
  if f 
    then return False
    else createDirectory path >> return True

