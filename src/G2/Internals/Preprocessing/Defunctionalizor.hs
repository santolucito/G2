module G2.Internals.Preprocessing.Defunctionalizor (defunctionalize) where

import Data.List
import qualified Data.Map as M
import Data.Maybe

import G2.Internals.Core.Language
import G2.Internals.Core.Utils

import G2.Internals.Core.CoreManipulator

import qualified Debug.Trace as T

{-Defunctionalizor

We need to eliminate higher order functions to
enable a translation to SMT formulas.

This can be done via Defunctionalization, described by Reynolds in
http://cs.au.dk/~hosc/local/HOSC-11-4-pp363-397.pdf

In short, each call to a higher order functions (a -> b) -> c is identified.
For each a, b pair, a new datatype A_B, and fresh function,
apply_a_b :: A_B -> a -> b, is created.
-}

type FuncName = Name
type ApplyTypeName = Name

defunctionalize :: State -> State
defunctionalize s =
    case leadingHigherOrderTypes s of
            (t:_) -> defunctionalize . useApplyType s $ t
            otherwise -> s

-- Given a state and a leading higher order function type
-- adjusts the state to use apply types instead.
-- This involves:
--   (1) Creating the apply datatype, and an apply constructor for each function of that type
--   (2) Create an apply function
--   (3) Adjust all relevant higher order functions
useApplyType :: State -> Type -> State
useApplyType s (t@(TyFun _ _)) =
    let
        funcs = passedToHigherOrder (expr_env s) t

        --apply data type
        applyTypeName = freshSeededName "ApplyType" s
        args = argList t
        applyConsNames = freshSeededNameList (take (length funcs) . repeat $ "apply") s
        applyTypeAlg = TyAlg applyTypeName (map (\n -> DataCon n (-1) (TyConApp applyTypeName []) []) applyConsNames)
        applyTypeCon = TyConApp applyTypeName []

        namesToFuncs = zip applyConsNames funcs 
        funcsToNames = map (\(a, b) -> (b, a)) namesToFuncs

        --function
        applyFuncName = freshSeededName "applyFunc" s
        applyFunc = createApplyFunc args applyTypeName namesToFuncs s
        applyFuncType = TyFun applyTypeCon t

        --adjustment
        higherNameExpr = higherOrderOfTypeFuncNames (expr_env s) t
        higherNameExprArgs = map (\(n, e) -> (n, e, higherOrderArgs e)) higherNameExpr

        funcsInSLT = funcsInSymLink t (sym_links s)

        newCurr_expr = foldr (\n -> exprReplace (Var n t) (Var n applyTypeCon)) (curr_expr s) funcsInSLT

        newFuncs_interps = M.fromList . catMaybes . map (\(a, n) -> 
                                                case n of
                                                    Var n t -> Just (a, (n, StdInterp))
                                                    otherwise -> Nothing) $ namesToFuncs

        s' = foldr (\(n, e, a) -> updateArgRefs n t applyTypeCon applyFuncName e a) s higherNameExprArgs

        s'' = modify (applyTypeReplace t applyTypeCon) (s' {curr_expr = newCurr_expr})

    in
    s'' { expr_env = M.insert applyFuncName applyFunc (expr_env s'')
        , type_env = M.insert applyTypeName applyTypeAlg (type_env s'')
        , sym_links = adjustSymLinks t applyTypeCon (sym_links s'')
        , func_interps = M.union newFuncs_interps (func_interps s'')
    }
    where
        argList :: Type -> [Type]
        argList (TyFun t t') = t:argList t'
        argList t = [t]

        updateArgRefs :: FuncName -> Type -> Type -> FuncName -> Expr -> [(FuncName, Type)] -> State -> State
        updateArgRefs n t t' fn e ns s =
            let
                e' = updateArgRefs' t t' fn e ns
            in
            s {expr_env = M.insert n e' (expr_env s)}

        updateArgRefs' :: Type -> Type -> FuncName -> Expr -> [(FuncName, Type)] -> Expr
        updateArgRefs' _ _ _ e [] = e
        updateArgRefs' t at fn e ((n, t'):ns) =
            let
                funcType = TyFun at t

                e' = fstAppReplace funcType fn n t' e
                e'' = sndAppReplace n t' at e'
            in
            if t == t' then updateArgRefs' t at fn e'' ns else updateArgRefs' t at fn e ns

        -- This adjusts for when the function with the given name is in the first position in an app
        -- This means that the function is being called
        -- We change the call to the function, to a call to the apply function, and pass in the correct constructor
        fstAppReplace :: Type -> FuncName -> FuncName -> Type -> Expr -> Expr
        fstAppReplace tn fn n t (Lam n' e t') = Lam n' (fstAppReplace tn fn n t e) t'
        fstAppReplace tn fn n t (Let ne e) =
            Let (map (\(n, e') -> (n, fstAppReplace tn fn n t e')) ne) (fstAppReplace tn fn n t e)
        fstAppReplace tn fn n t (App e e') =
            if e == Var n t then
                App (fstAppReplace tn fn n t (App (Var fn tn) e)) (fstAppReplace tn fn n t e')
            else
                App (fstAppReplace tn fn n t e) (fstAppReplace tn fn n t e')
        fstAppReplace tn fn n t (Case e ae t') =
            Case (fstAppReplace tn fn n t e) (map (\(a, e) -> (a, fstAppReplace tn fn n t e)) ae) t'
        fstAppReplace _ _ _ _ e = e

        -- This adjusts for when the function with the given name is in the second position in an app
        -- This means that the function is being passed
        -- It simply swaps the type of the function, from a function type to an applytype
        sndAppReplace :: FuncName -> Type -> Type -> Expr -> Expr
        sndAppReplace n t at (Lam n' e t') = Lam n' (sndAppReplace n t at e) t'
        sndAppReplace n t at (Let ne e) =
            Let (map (\(n, e') -> (n, sndAppReplace n t at e')) ne) (sndAppReplace n t at e)
        sndAppReplace n t at a@(App e e') =
            if e' == Var n t then
                App (sndAppReplace n t at e) (sndAppReplace n t at (Var n at))
            else
                App (sndAppReplace n t at e) (sndAppReplace n t at e')
        sndAppReplace n t at (Case e ae t') =
            Case (sndAppReplace n t at e) (map (\(a, e) -> (a, sndAppReplace n t at e)) ae) t'
        sndAppReplace _ _ _ e = e

        -- Gets the names of all functions in the symbolic link table, that are of the given type
        funcsInSymLink :: Type -> SymLinkTable -> [FuncName]
        funcsInSymLink t = M.keys . M.filter (\(_, t', _) -> t == t')

        -- In the symbolic link table, changes all Types rt to Type at
        adjustSymLinks :: Type -> Type -> SymLinkTable -> SymLinkTable
        adjustSymLinks rt at = M.map (\(n, t, i) -> (n, if t == rt then at else t, i))

useApplyType _ t = error ("Non-TyFun type " ++ show t ++ " given to createApplyType.")

--Creates the apply function
createApplyFunc :: [Type] -> ApplyTypeName -> [(Name, Expr)] -> State -> Expr
createApplyFunc ts applyTypeName namesToFuncs s =
    let
        ret_type = head . reverse $ ts

        new_names = freshSeededNameList (repeat "apply_match") s
        apply_arg = freshSeededName "apply_" s
        args = freshSeededNameList (replicate (length ts - 1) "i") s
        args_vars = map (\(a, t) -> Var a t) (zip args ts)

        case_expr = Var apply_arg (TyConApp applyTypeName [])
        case_matches = map (\((n, e), new) ->
                        (Alt ((DataCon n (-1) (TyConApp applyTypeName []) []), [new])
                            , foldr (\i' e' -> App e' i') e args_vars))
                        (zip namesToFuncs new_names)
        case_final = Case case_expr case_matches ret_type

        arg_lams = foldr (\(a, t) e -> Lam a e (TyFun t (exprType e))) case_final (zip args ts)
    in
    Lam apply_arg arg_lams (TyFun (TyConApp applyTypeName []) (exprType arg_lams))

-- In e, replaces all eOld with eNew
exprReplace :: Expr -> Expr -> Expr -> Expr
exprReplace eOld eNew e = if e == eOld then exprReplace' eOld eNew eNew else exprReplace' eOld eNew e
    where
        exprReplace' :: Expr -> Expr -> Expr -> Expr
        exprReplace' eOld eNew (Lam n e t) = Lam n (exprReplace eOld eNew e) t
        exprReplace' eOld eNew (Let ne e) =
            Let (map (\(n, e') -> (n, exprReplace eOld eNew e')) ne) (exprReplace eOld eNew e)
        exprReplace' eOld eNew (App e e') = App (exprReplace eOld eNew e) (exprReplace eOld eNew e')
        exprReplace' eOld eNew (Case e ae t) =
            Case (exprReplace eOld eNew e) (map (\(a, e) -> (a, exprReplace eOld eNew e)) ae) t
        exprReplace' _ _ e = e

-- Given a TyFun type, an apply type, and a type, replaces all of the TyFun types with the apply type
applyTypeReplace :: Type -> Type -> Type -> Type
applyTypeReplace tOld tNew t@(TyFun t'@(TyFun _ _) t'') =
    if t' == tOld then
        applyTypeReplace tOld tNew (TyFun tNew t'')
    else
        TyFun (applyTypeReplace tOld tNew t') (applyTypeReplace tOld tNew t'')
applyTypeReplace tOld tNew (TyApp t t') = TyApp (applyTypeReplace tOld tNew t) (applyTypeReplace tOld tNew t')
applyTypeReplace tOld tNew (TyConApp n ts) = TyConApp n (map (applyTypeReplace tOld tNew) ts)
applyTypeReplace tOld tNew (TyForAll n t) = TyForAll n (applyTypeReplace tOld tNew t)
applyTypeReplace _ _ t = t

-- Get all function types that are passed into any function
leadingHigherOrderTypes :: State -> [Type]
leadingHigherOrderTypes s =
    let
        higherTEenv = higherOrderTypesTEnv . type_env $ s
        higherEEnv = map exprType . higherOrderFuncsEEnv . expr_env $ s
    in
    nub . concatMap leading $ higherTEenv ++ higherEEnv
    where
        leading :: Type -> [Type]
        leading (TyFun t@(TyFun _ _) t') = t:(leading t ++ leading t')
        leading (TyFun t t') = leading t ++ leading t'
        leading (TyApp t t') = leading t ++ leading t'
        leading (TyConApp _ ts) = concatMap leading ts
        leading (TyAlg _ dc) = concatMap (\(DataCon _ _ t ts) -> leading t ++ concatMap leading ts) dc
        leading (TyForAll _ t) = leading t

-- Given a function type t, gets a list of:
-- (1) all functions of type t from the expression environment
-- (2) all expresions of type t that are passed into a higher order function,
--     somewhere in the expression environment
passedToHigherOrder :: EEnv -> Type -> [Expr]
passedToHigherOrder eenv t =
    let
        funcs = map (\n -> Var n t) (functionNamesOfType eenv t)
        part_lams = concatMap (\e -> higherOrderArg e (exprType e)) (M.elems eenv)
    in
    nub (funcs ++ part_lams)
    where
        higherOrderArg :: Expr -> Type -> [Expr]
        higherOrderArg (App f a) (TyFun t@(TyFun _ _) t') = f:(higherOrderArg f t ++ higherOrderArg a t')
        higherOrderArg (App _ a) (TyFun _ t) = higherOrderArg a t
        higherOrderArg _ _ = []

-- Given an expression environment, gets the names and expressions of all higher order functions
-- that accept the given type
higherOrderOfTypeFuncNames :: EEnv -> Type -> [(FuncName, Expr)]
higherOrderOfTypeFuncNames eenv t =
    nub . filter (\(n, e) -> t `elem` functionsAccepted e) . M.toList $ eenv
    where
        -- Returns a list of all function types that must be passed to the given function
        functionsAccepted :: Expr -> [Type]
        functionsAccepted = functionsAccepted' . exprType
            where
                functionsAccepted' (TyFun t@(TyFun _ _) t') = t:functionsAccepted' t'
                functionsAccepted' (TyApp t t') = functionsAccepted' t ++ functionsAccepted' t'
                functionsAccepted' (TyConApp _ ts) = concatMap functionsAccepted' ts
                functionsAccepted' (TyForAll _ t) = functionsAccepted' t
                functionsAccepted' _ = []

-- Given a higher order function, returns the names and types of all higher order arguments
higherOrderArgs :: Expr -> [(FuncName, Type)]
higherOrderArgs (Lam n e (TyFun t@(TyFun _ _) _)) = (n, t):higherOrderArgs e
higherOrderArgs (Lam _ e _) = higherOrderArgs e
higherOrderArgs _ = []

-- Returns all function names of the given type
functionNamesOfType :: EEnv -> Type -> [FuncName]
functionNamesOfType eenv t =
    map fst . filter (\(_, e') -> exprType e' == t) . M.assocs $ eenv

-- Get higher order functions from the expression environment
higherOrderFuncsEEnv :: EEnv -> [Expr]
higherOrderFuncsEEnv = filter (higherOrderFunc) . M.elems

-- Get higher order types from the type environment
higherOrderTypesTEnv :: TEnv -> [Type]
higherOrderTypesTEnv = filter (higherOrderFuncType) . M.elems

-- Returns whether the expr is a higher order function
higherOrderFunc :: Expr -> Bool
higherOrderFunc e = higherOrderFuncType . exprType $ e

-- Returns whether the type is for a higher order function
higherOrderFuncType :: Type -> Bool
higherOrderFuncType (TyFun (TyFun _ _) _) = True
higherOrderFuncType (TyFun t t') = higherOrderFuncType t || higherOrderFuncType t'
higherOrderFuncType (TyApp t t') = higherOrderFuncType t || higherOrderFuncType t'
higherOrderFuncType _ = False