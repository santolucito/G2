module Defunc1 where

data A = A (Int -> Int)
       | B Int

f :: A -> A
f (A g) = B (g 2)
f x = x

h :: (Int -> Int) -> Int
h fg = fg 0

add1 :: Int -> Int
add1 x = x + 1

multiply2 :: Int -> Int
multiply2 x = x * 2