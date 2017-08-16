module G2.Internals.Interface (initState) where

import G2.Internals.Language
import qualified G2.Internals.Language.SymLinks as Sym

import Data.List
import qualified Data.Map as M

initState :: Program -> [ProgramType] -> Maybe String -> Maybe String -> String -> State
initState prog prog_typ m_assume m_assert f =
    let
        ng = mkNameGen prog
        (ce, ng') = mkCurrExpr m_assume m_assert f ng . concat $ prog
    in
    State {
      expr_env = mkExprEnv . concat $ prog
    , type_env = mkTypeEnv prog_typ
    , curr_expr = ce
    , nameGen = ng'
    , path_conds = []
    , sym_links = Sym.empty
    , func_table = emptyFuncInterps
 }

mkExprEnv :: Binds -> ExprEnv
mkExprEnv = M.fromList . map (\(i, e) -> (idName i, e))

mkTypeEnv :: [ProgramType] -> TypeEnv
mkTypeEnv = M.fromList . map (\(n, ts, dcs) -> (n, AlgDataTy ts dcs))

args :: Type -> [Type]
args (TyFun t ts) = t:args ts  
args _ = []

mkCurrExpr :: Maybe String -> Maybe String -> String -> NameGen -> Binds -> (Expr, NameGen)
mkCurrExpr m_assume m_assert s ng b =
    case findFunc s b of
        Left (f, ex) -> 
            let
                typs = args . exprType $ ex
                (names, ng') = freshNames (length typs) ng
                ids = map (uncurry Id) $ zip names typs
                var_ids = reverse $ map Var ids
                
                var_ex = Var f
                app_ex = foldr (\vi e -> App e vi) var_ex var_ids
                lam_ex = foldr (\i e -> Lam i e) app_ex ids

                (name, ng'') = freshName ng'
                id_name = Id name (idType f)
                var_name = Var id_name

                assume_ex = mkAssumeAssert Assume m_assume var_ids var_name var_name b
                assert_ex = mkAssumeAssert Assert m_assert var_ids var_name assume_ex b

                
                let_ex = Let [(id_name, lam_ex)] assert_ex
            in
            (let_ex, ng'')
        Right s -> error s

mkAssumeAssert :: Primitive -> Maybe String -> [Expr] -> Expr -> Expr -> Binds -> Expr
mkAssumeAssert p (Just f) var_ids inter pre_ex b =
    case findFunc f b of
        Left (f, ex) -> 
            let
                app_ex = foldr (\vi e -> App e vi) (Var f) (pre_ex:var_ids)
                prim_app = App (Prim p) app_ex
            in
            App prim_app inter
        Right s -> error s

mkAssumeAssert _ Nothing _ e _ _ = e

findFunc :: String -> Binds -> Either (Id, Expr) String
findFunc s b = 
    let
        match = filter (\(Id (Name n _ _) _, _) -> n == s) b
    in
    case match of
        [fe] -> Left fe
        x:xs -> Right $ "Multiple functions with name " ++ s
        [] -> Right $ "No functions with name " ++ s

run = undefined

{-
run :: SMTConverter ast out io -> io -> Int -> State -> IO [([Expr], Expr)]
run con hhp n state = do
    let preproc_state = runPreprocessing state

    let states = runNDepth [preproc_state] n

    putStrLn ("\nNumber of execution states: " ++ (show (length states)))


    satModelOutputs con hhp states
-}
