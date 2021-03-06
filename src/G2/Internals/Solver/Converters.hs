{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Converters
-- This contains functions to switch from
-- (1) A State/Exprs/Types to SMTHeaders/SMTASTs/Sorts
-- (2) SMTHeaders/SMTASTs/Sorts to some SMT solver interface
-- (3) SMTASTs/Sorts to Exprs/Types
module G2.Internals.Solver.Converters
    ( toSMTHeaders
    , toSMTHeadersWithSMTSorts
    , toSolver
    , exprToSMT --WOULD BE NICE NOT TO EXPORT THIS
    , typeToSMT --WOULD BE NICE NOT TO EXPORT THIS
    , toSolverAST --WOULD BE NICE NOT TO EXPORT THIS
    , pcVars
    , smtastToExpr
    , modelAsExpr ) where

import Data.List
import qualified Data.Map as M
import Data.Maybe
import qualified Data.Text as T

-- import G2.Internals.Translation.HaskellPrelude
import G2.Internals.Language.Naming
import qualified G2.Internals.Language.PathConds as PC
import G2.Internals.Language.Support hiding (Model)
import G2.Internals.Language.Syntax hiding (Assert)
import G2.Internals.Solver.Language

-- | toSMTHeaders
-- Here we convert from a State, to an SMTHeader.  This SMTHeader can later
-- be given to an SMT solver by using toSolver.
-- To determine the input that can be fed to a state to get the curr_expr,
-- we need only consider the types and path constraints of that state.
-- We can also pass in some other Expr Container to instantiate names from, which is
-- important if you wish to later be able to scrape variables from those Expr's
toSMTHeaders :: State -> [SMTHeader]
toSMTHeaders s  = 
    let
        pc = PC.toList $ path_conds s
    in
    nub (pcVarDecls pc)
    ++
    (pathConsToSMTHeaders pc)

toSMTHeadersWithSMTSorts :: State -> [SMTHeader]
toSMTHeadersWithSMTSorts s =
    (typesToSMTSorts $ type_env s)
    ++
    toSMTHeaders s

pathConsToSMTHeaders :: [PathCond] -> [SMTHeader]
pathConsToSMTHeaders = map Assert . mapMaybe pathConsToSMT


pathConsToSMT :: PathCond -> Maybe SMTAST
pathConsToSMT (AltCond a e b) =
    let
        exprSMT = exprToSMT e
        altSMT = altToSMT a
    in
    Just $ if b then exprSMT := altSMT else (:!) (exprSMT := altSMT) 
pathConsToSMT (ExtCond e b) =
    let
        exprSMT = exprToSMT e
    in
    Just $ if b then exprSMT else (:!) exprSMT
pathConsToSMT (ConsCond (DataCon (Name "True" _ _) _ _) e b) =
    let
        exprSMT = exprToSMT e
    in
    Just $ if b then exprSMT else (:!) exprSMT
pathConsToSMT (ConsCond (DataCon (Name "False" _ _) _ _) e b) =
    let
        exprSMT = exprToSMT e
    in
    Just $ if b then  (:!) $ exprSMT else exprSMT
pathConsToSMT (ConsCond (DataCon n _ _) e b) =
    let
        exprSMT = exprToSMT e
    in
    Just $ if b then Tester n exprSMT else (:!) $ Tester n exprSMT
pathConsToSMT (PCExists _) = Nothing

exprToSMT :: Expr -> SMTAST
exprToSMT (Var (Id n t)) = V (nameToStr n) (typeToSMT t)
exprToSMT (Lit c) =
    case c of
        LitInt i -> VInt i
        LitFloat f -> VFloat f
        LitDouble d -> VDouble d
        err -> error $ "exprToSMT: invalid Expr: " ++ show err
exprToSMT (Data (DataCon (Name n _ _) (TyConApp (Name "Bool" _ _) _) _)) =
    case n of
        "True" -> VBool True
        "False" -> VBool False
        _ -> error "Invalid bool in exprToSMT"
exprToSMT (Data (DataCon n t _)) = V (nameToStr n) (typeToSMT t)
exprToSMT a@(App _ _) =
    let
        f = getFunc a
        args = getArgs a
    in
    funcToSMT f args
    where
        getFunc :: Expr -> Expr
        getFunc v@(Var _) = v
        getFunc p@(Prim _ _) = p
        getFunc (App a' _) = getFunc a'
        getFunc d@(Data _) = d 
        getFunc err = error $ "getFunc: invalid Expr: " ++ show err

        getArgs :: Expr -> [Expr]
        getArgs (App a1 a2) = getArgs a1 ++ [a2]
        getArgs _ = []
exprToSMT e = error $ "exprToSMT: unhandled Expr: " ++ show e

-- | funcToSMT
-- We split based on whether the passed Expr is a function or known data constructor, or an unknown data constructor
funcToSMT :: Expr -> [Expr] -> SMTAST
funcToSMT (Var (Id n t)) es = Cons (nameToStr n) (map exprToSMT es) (typeToSMT t) -- TODO : DO WE NEED THIS???
funcToSMT (Prim p _) [a] = funcToSMT1Prim p a
funcToSMT (Prim p _) [a1, a2] = funcToSMT2Prim p a1 a2
funcToSMT (Data (DataCon n t _)) es = Cons (nameToStr n) (map exprToSMT es) (typeToSMT t)
funcToSMT e l = error ("Unrecognized " ++ show e ++ " with args " ++ show l ++ " in funcToSMT")

funcToSMT1Prim :: Primitive -> Expr -> SMTAST
funcToSMT1Prim Negate a = Neg (exprToSMT a)
funcToSMT1Prim Not e = (:!) (exprToSMT e)
funcToSMT1Prim IntToReal e = ItoR (exprToSMT e)
funcToSMT1Prim err _ = error $ "funcToSMT1Prim: invalid Primitive " ++ show err

funcToSMT2Prim :: Primitive -> Expr -> Expr -> SMTAST
funcToSMT2Prim And a1 a2 = exprToSMT a1 :&& exprToSMT a2
funcToSMT2Prim Or a1 a2 = exprToSMT a1 :|| exprToSMT a2
funcToSMT2Prim Implies a1 a2 = exprToSMT a1 :=> exprToSMT a2
funcToSMT2Prim Iff a1 a2 = exprToSMT a1 :<=> exprToSMT a2
funcToSMT2Prim Ge a1 a2 = exprToSMT a1 :>= exprToSMT a2
funcToSMT2Prim Gt a1 a2 = exprToSMT a1 :> exprToSMT a2
funcToSMT2Prim Eq a1 a2 = exprToSMT a1 := exprToSMT a2
funcToSMT2Prim Neq a1 a2 = exprToSMT a1 :/= exprToSMT a2
funcToSMT2Prim Lt a1 a2 = exprToSMT a1 :< exprToSMT a2
funcToSMT2Prim Le a1 a2 = exprToSMT a1 :<= exprToSMT a2
funcToSMT2Prim Plus a1 a2 = exprToSMT a1 :+ exprToSMT a2
funcToSMT2Prim Minus a1 a2 = exprToSMT a1 :- exprToSMT a2
funcToSMT2Prim Mult a1 a2 = exprToSMT a1 :* exprToSMT a2
funcToSMT2Prim Div a1 a2 = exprToSMT a1 :/ exprToSMT a2
funcToSMT2Prim Mod a1 a2 = exprToSMT a1 `Modulo` exprToSMT a2
funcToSMT2Prim op lhs rhs = error $ "funcToSMT2Prim: invalid case with (op, lhs, rhs): " ++ show (op, lhs, rhs)

altToSMT :: AltMatch -> SMTAST
altToSMT (LitAlt (LitInt i)) = VInt i
altToSMT (LitAlt (LitFloat f)) = VFloat f
altToSMT (LitAlt (LitDouble d)) = VDouble d
altToSMT (DataAlt (DataCon (Name "True" _ _) _ _) _) = VBool True
altToSMT (DataAlt (DataCon (Name "False" _ _) _ _) _) = VBool False
altToSMT (DataAlt (DataCon n t ts) ns) =
    Cons (nameToStr n) (map f $ zip ns ts) (typeToSMT t)
    where
        f :: (Id, Type) -> SMTAST
        f (n', t') = V (nameToStr . idName $ n') (typeToSMT t')
altToSMT am = error $ "Unhandled " ++ show am

createVarDecls :: [(Name, Sort)] -> [SMTHeader]
createVarDecls [] = []
createVarDecls ((n,s):xs) = VarDecl (nameToStr n) s:createVarDecls xs

pcVarDecls :: [PathCond] -> [SMTHeader]
pcVarDecls = createVarDecls . pcVars

pcVars :: [PathCond] -> [(Name, Sort)]
pcVars [] = []
pcVars (PCExists i:xs) = idToNameSort i : pcVars xs
pcVars (AltCond am e _:xs) = amVars am ++ vars e ++ pcVars xs
pcVars (p:xs)= vars p ++ pcVars xs

amVars :: AltMatch -> [(Name, Sort)]
amVars (DataAlt _ i) = map idToNameSort i
amVars _ = []

vars :: (ASTContainer m Expr) => m -> [(Name, Sort)]
vars = evalASTs vars'
    where
        vars' :: Expr -> [(Name, Sort)]
        vars' (Var i) = [idToNameSort i]
        vars' _ = []

idToNameSort :: Id -> (Name, Sort)
idToNameSort (Id n t) = (n, typeToSMT t)

typeToSMT :: Type -> Sort
typeToSMT (TyVar (Id n _)) = Sort (nameToStr n) []
typeToSMT (TyFun TyLitInt _) = SortInt -- TODO: Remove this
typeToSMT (TyFun TyLitDouble _) = SortDouble -- TODO: Remove this
typeToSMT (TyFun TyLitFloat _) = SortFloat -- TODO: Remove this
typeToSMT TyLitInt = SortInt
typeToSMT TyLitDouble = SortDouble
typeToSMT TyLitFloat = SortFloat
-- typeToSMT (TyConApp (Name "Int" _ _) _) = SortInt
-- typeToSMT (TyConApp (Name "Float" _ _) _) = SortFloat
-- typeToSMT (TyConApp (Name "Double" _ _) _) = SortDouble
typeToSMT (TyConApp (Name "Bool" _ _) _) = SortBool
typeToSMT (TyConApp n ts) = Sort (nameToStr n) (map typeToSMT ts)
typeToSMT (TyForAll (AnonTyBndr _) t) = typeToSMT t
typeToSMT t = error $ "Unsupported type in typeToSMT: " ++ show t

typesToSMTSorts :: TypeEnv -> [SMTHeader]
typesToSMTSorts tenv =
    [SortDecl . map typeToSortDecl $ M.toList tenv]
        where
            typeToSortDecl :: (Name, AlgDataTy) -> (SMTName, [SMTName], [DC])
            typeToSortDecl (n, DataTyCon ns dcs) = (nameToStr n, map nameToStr ns, map dataConToDC dcs)

            dataConToDC :: DataCon -> DC
            dataConToDC (DataCon n _ ts) =
                DC (nameToStr n) $ map typeToSMT ts

-- | toSolver
toSolver :: SMTConverter ast out io -> [SMTHeader] -> out
toSolver con [] = empty con
toSolver con (Assert ast:xs) = 
    merge con (assert con $ toSolverAST con ast) (toSolver con xs)
toSolver con (VarDecl n s:xs) = merge con (toSolverVarDecl con n s) (toSolver con xs)
toSolver con (SortDecl ns:xs) = merge con (toSolverSortDecl con ns) (toSolver con xs)

-- | toSolverAST
toSolverAST :: SMTConverter ast out io -> SMTAST -> ast
toSolverAST con (x :>= y) = (.>=) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :> y) = (.>) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x := y) = (.=) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :/= y) = (./=) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :< y) = (.<) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :<= y) = (.<=) con (toSolverAST con x) (toSolverAST con y)

toSolverAST con (x :&& y) = (.&&) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :|| y) =  (.||) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con ((:!) x) = (.!) con $ toSolverAST con x
toSolverAST con (x :=> y) = (.=>) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :<=> y) = (.<=>) con (toSolverAST con x) (toSolverAST con y)

toSolverAST con (x :+ y) = (.+) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :- y) = (.-) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :* y) = (.*) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x :/ y) = (./) con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (x `Modulo` y) = smtModulo con (toSolverAST con x) (toSolverAST con y)
toSolverAST con (Neg x) = neg con $ toSolverAST con x
toSolverAST con (ItoR x) = itor con $ toSolverAST con x

toSolverAST con (Tester n e) = tester con (nameToStr n) (toSolverAST con e)

toSolverAST con (Ite x y z) =
    ite con (toSolverAST con x) (toSolverAST con y) (toSolverAST con z)

toSolverAST con (VInt i) = int con i
toSolverAST con (VFloat f) = float con f
toSolverAST con (VDouble i) = double con i
toSolverAST con (VBool b) = bool con b
toSolverAST con (Cons n asts s) =
    let
        asts' = map (toSolverAST con) asts
    in
    cons con n asts' s

toSolverAST con (V n s) = varName con n s
toSolverAST _ ast = error $ "toSolverAST: invalid SMTAST: " ++ show ast

-- | toSolverSortDecl
toSolverSortDecl :: SMTConverter ast out io -> [(SMTName, [SMTName],  [DC])] -> out
toSolverSortDecl = sortDecl

-- | toSolverVarDecl
toSolverVarDecl :: SMTConverter ast out io -> SMTName -> Sort -> out
toSolverVarDecl con n s = varDecl con n (sortName con s)

-- | smtastToExpr
smtastToExpr :: SMTAST -> Expr
smtastToExpr (VInt i) = (Lit $ LitInt i)
smtastToExpr (VFloat f) = (Lit $ LitFloat f)
smtastToExpr (VDouble d) = (Lit $ LitDouble d)
smtastToExpr (VBool b) =
    Data (DataCon (Name (T.pack $ show b) Nothing 0) (TyConApp (Name "Bool" Nothing 0) []) [])
smtastToExpr (Cons n smts s) =
    foldl (\v a -> App v (smtastToExpr a)) (Data (DataCon (strToName n) (sortToType s) [])) smts
smtastToExpr (V n s) = Var $ Id (strToName n) (sortToType s)
smtastToExpr _ = error "Conversion of this SMTAST to an Expr not supported."

sortToType :: Sort -> Type
sortToType (SortInt) = TyLitInt
sortToType (SortFloat) = TyLitFloat
sortToType (SortDouble) = TyLitDouble
sortToType (SortBool) = TyConApp (Name "Bool" Nothing 0) []
sortToType (Sort n xs) = TyConApp (strToName n) (map sortToType xs)

modelAsExpr :: Model -> ExprModel
modelAsExpr = M.mapKeys strToName . M.map smtastToExpr
