module DefuncTest where

import G2.Internals.Language
import TestUtils

a :: Expr -> Expr
a = App (Data $ DataCon (Name "A" (Just "Defunc1") 0) (TyConApp (Name "A" (Just "Defunc1") 0) []) [])

b :: Expr -> Expr
b = App (Data $ DataCon (Name "B" (Just "Defunc1") 0) (TyConApp (Name "A" (Just "Defunc1") 0) []) [])

add1 = Var (Id (Name "add1" (Just "Defunc1") 0) TyInt) 
multiply2 = Var (Id (Name "multiply2" (Just "Defunc1") 0) TyInt) 

defunc1Add1 [x, y] = x `eqIgT` a (add1) &&  y `eqIgT` b (Lit $ LitInt 3)

defunc1Multiply2 [x, y] = x `eqIgT` a (add1) && y `eqIgT` b (Lit $ LitInt 4)