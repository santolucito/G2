module GetNthErr where

import Prelude hiding (length)

data CList = Cons Int CList | Nil

getNth :: CList -> Int -> Int 
getNth (Cons x _)  0 = x 
getNth (Cons _ xs) n = getNth xs (n - 1)
getNth _      _ = error "Invalid index"

length :: CList -> Int
length (Cons _ xs) = 1 + length xs
length Nil = 0

getNthContract :: CList -> Int -> Int -> Bool
getNthContract xs i _ = 0 <= i && i < length xs

dotProd :: CList -> CList -> Int 
dotProd xs ys = loop 0 n 
  where 
    n             = length xs - 1
    loop acc i 
      | 0 <= i    = loop (acc + (getNth xs i * getNth ys i)) (i-1)
      | otherwise = acc 