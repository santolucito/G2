module G2.Internals.Preprocessing.LetFloating (letFloat) where

import G2.Internals.Language
import qualified G2.Internals.Language.ExprEnv as E

import Data.Foldable
import Data.List
import Data.Monoid hiding (Alt)

import Debug.Trace

-- We lift all let bindings to functions into the expr env.
-- This is needed to allow for defunctionalization, as if a function is in a let
-- clause, rather than the expr env, it cannot be called by the apply function

-- letFloat :: State -> State
-- letFloat s =
--     let
--         lb = filter (hasFuncType . typeOf . fst) $ letBinds s
--     in
--     insertBinds lb $ elimBinds (map fst lb) s

-- insertBinds :: Binds -> State -> State
-- insertBinds b s = s {expr_env = foldr (\(Id n _, e) -> E.insert n e) (expr_env s) b}

-- letBinds :: (ASTContainer m Expr) => m -> Binds
-- letBinds = evalASTs letBinds'

-- letBinds' :: Expr -> Binds
-- letBinds' (Let b _) = b
-- letBinds' _ = []

-- -- Given a list of 
-- elimBinds :: (ASTContainer m Expr) => [Id] -> m -> m
-- elimBinds is = modifyASTs (elimBinds' is)

-- elimBinds' :: [Id] -> Expr -> Expr
-- elimBinds' is (Let b e) = Let (filter (\(i, e) -> i `notElem` is) b) e
-- elimBinds' _ e = e

-- -- Returns all Ids bound to functions by Let Expr's
-- funcLetBinds :: (ASTContainer m Expr) => m -> [Id]
-- funcLetBinds = evalASTs (funcLetBinds')

-- funcLetBinds' :: Expr -> [Id]
-- funcLetBinds' (Let b _) = filter (hasFuncType) $ map fst b
-- funcLetBinds' _ = []

letFloat :: State -> State
letFloat s@State { expr_env = eenv
                 , name_gen = ng} =
            let
                (eenv', ng') = letFloat' eenv ng
            in
            s { expr_env = eenv'
              , name_gen = ng' }

letFloat' :: E.ExprEnv -> NameGen -> (E.ExprEnv, NameGen)
letFloat' eenv ng =
    let
        hasLet = filter (hasHigherOrderLetBinds) . E.toExprList $ E.filterWithKey (\n _ -> E.isRoot n eenv) eenv
    in
    trace ("hasLet = " ++ show hasLet) $ letFloat'' hasLet eenv ng

letFloat'' :: [(Name, Expr)] -> E.ExprEnv -> NameGen -> (E.ExprEnv, NameGen)
letFloat'' [] eenv ng = (eenv, ng)
letFloat'' ((n,e):ne) eenv ng =
    let
        (e', eenv', ng') = liftLetBinds eenv ng e

        eenv'' = E.insert n e' eenv'
    in
    trace ("n = " ++ show n ++ "\n---") $ letFloat'' ne eenv'' ng'

liftLetBinds :: E.ExprEnv -> NameGen -> Expr -> (Expr, E.ExprEnv, NameGen)
liftLetBinds eenv ng (Let b e) =
    let
        (funcs, notFuncs) = partition (hasFuncType . fst) b
        (e', eenv', ng') = liftLetBinds' eenv ng funcs e

        (e'', eenv'', ng'') = liftLetBinds eenv' ng' e'
    in
    trace ("funcs = " ++ show funcs ++ "\n---\nnot funcs = " ++ show notFuncs ++ "\n---") $  (Let notFuncs e'', eenv'', ng'')
liftLetBinds eenv ng (App e1 e2) =
    let
        (e1', eenv', ng') = liftLetBinds eenv ng e1
        (e2', eenv'', ng'') = liftLetBinds eenv' ng' e2
    in
    (App e1' e2', eenv'', ng'')
liftLetBinds eenv ng (Lam i e) =
    let
        (e', eenv', ng') = liftLetBinds eenv ng e
    in
    (Lam i e', eenv', ng')
liftLetBinds eenv ng (Case e i a) =
    let
        (e', eenv', ng') = liftLetBinds eenv ng e
        (a', eenv'', ng'') = liftLetBindsAlts eenv' ng' a
    in
    (Case e' i a', eenv'', ng'')
liftLetBinds eenv ng (Assume e1 e2) =
    let
        (e1', eenv', ng') = liftLetBinds eenv ng e1
        (e2', eenv'', ng'') = liftLetBinds eenv' ng' e2
    in
    (Assume e1' e2', eenv'', ng'')
liftLetBinds eenv ng (Assert e1 e2) =
    let
        (e1', eenv', ng') = liftLetBinds eenv ng e1
        (e2', eenv'', ng'') = liftLetBinds eenv' ng' e2
    in
    (Assert e1' e2', eenv'', ng'')
liftLetBinds eenv ng e = (e, eenv, ng)

liftLetBindsAlts :: E.ExprEnv -> NameGen -> [Alt] -> ([Alt], E.ExprEnv, NameGen)
liftLetBindsAlts eenv ng [] = ([], eenv, ng)
liftLetBindsAlts eenv ng (Alt am e:as) =
    let
        (e', eenv', ng') = liftLetBinds eenv ng e
        (a', eenv'', ng'') = liftLetBindsAlts eenv' ng' as
    in
    (Alt am e':a', eenv'', ng'')

liftLetBinds' :: E.ExprEnv -> NameGen -> Binds -> Expr -> (Expr, E.ExprEnv, NameGen)
liftLetBinds' eenv ng [] e = (e, eenv, ng)
liftLetBinds' eenv ng ((Id n t, b):xs) e =
    let
        --Lift to ExprEnv
        (n', ng') = freshSeededName n ng
        (b', fv, ng'') = freeVarsToLams eenv ng' b
        eenv' = E.insert n' b' eenv

        --Replace Vars in function
        newCall = foldr App (Var (Id n' t)) (map Var fv)
        e' = replaceAST (Var (Id n t)) newCall e
    in
    liftLetBinds' eenv' ng'' xs e'

-- Adjusts the free variables of am expression to have new, lambda bound names
-- Returns this new expression, a list of the old ids in the order of their corresponding
-- lambdas, and a new namgen
freeVarsToLams :: E.ExprEnv -> NameGen -> Expr -> (Expr, [Id], NameGen)
freeVarsToLams eenv ng e =
    let
        fv = freeVars eenv e
        fvN = map idName fv
        fvT = map typeOf fv

        (fr, ng') = freshSeededNames fvN ng 
        
        frId = map (uncurry Id) (zip fr fvT)

        e' = foldr (uncurry rename) e (zip fvN fr)
        e'' = foldr (Lam) e' frId
    in
    (e'', fv, ng')    

--Returns the free (unbound by a Lambda, Let, or the Expr Env) variables of an expr
freeVars :: ASTContainer m Expr => E.ExprEnv -> m -> [Id]
freeVars eenv = evalASTsM (freeVars' eenv)

-- returns (bound variables, free variables)for use with evalASTsM
freeVars' :: E.ExprEnv -> [Id] -> Expr -> ([Id], [Id])
freeVars' _ _ (Let b _) = (map fst b, [])
freeVars' _ _ (Lam b _) = ([b], [])
freeVars' eenv bound (Var i) =
    if E.member (idName i) eenv || i `elem` bound then
        ([], [])
    else
        ([], [i])
freeVars' _ _ _ = ([], [])

--Replaces all instances of old with new in the AST
replaceAST :: (Eq e, AST e) => e -> e -> e -> e
replaceAST old new e = if e == old then new else modifyChildren (replaceAST old new) e

hasHigherOrderLetBinds :: (ASTContainer m Expr) => m -> Bool
hasHigherOrderLetBinds = getAny . evalASTs hasHigherOrderLetBinds'

hasHigherOrderLetBinds' :: Expr -> Any
hasHigherOrderLetBinds' (Let b _) = Any $ any (hasFuncType . fst) b
hasHigherOrderLetBinds' _ = Any False