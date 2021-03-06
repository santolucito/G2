module G2.Internals.Execution.Memory 
  ( markAndSweep
  , markAndSweepPreserving
  ) where

import G2.Internals.Language.Syntax
import G2.Internals.Language.Support
import G2.Internals.Language.Naming
import G2.Internals.Language.ExprEnv as E

import qualified Data.Set as S
import qualified Data.Map as M

markAndSweep :: State -> State
markAndSweep = markAndSweepPreserving []

markAndSweepPreserving :: [Name] -> State -> State
markAndSweepPreserving ns (state@State { expr_env = eenv
                                       , type_env = tenv
                                       , curr_expr = cexpr
                                       , path_conds = pc
                                       , type_classes = tc
                                       , input_ids = iids
                                       , deepseq_walkers = dsw
                                       , exec_stack = es
                                       , known_values = kv
                                       , cleaned_names = cn
                                       }) = -- error $ show $ length $ take 20 $ PC.toList path_conds
                               state'
  where
    state' = state { expr_env = eenv'
                   , type_env = tenv'
                   , deepseq_walkers = dsw'
                   , cleaned_names = cn'
                   }

    active = activeNames tenv eenv S.empty $ names cexpr ++
                                                   names es ++
                                                   names pc ++
                                                   names kv ++
                                                   names iids ++
                                                   ns

    isActive :: Name -> Bool
    isActive = (flip S.member) active

    eenv' = E.filterWithKey (\n _ -> isActive n) eenv
    tenv' = M.filterWithKey (\n _ -> isActive n) tenv

    dsw' = M.filterWithKey (\n _ -> isActive n) dsw

    cn' = M.empty

activeNames :: TypeEnv -> ExprEnv -> S.Set Name -> [Name] -> S.Set Name
activeNames _ _ explored [] = explored
activeNames tenv eenv explored (n:ns) =
    if S.member n explored
      then activeNames tenv eenv explored ns
      else activeNames tenv eenv explored' ns'
  where
    explored' = S.insert n explored
    tenv_hits = case M.lookup n tenv of
        Nothing -> []
        Just r -> names r
    eenv_hits = case E.lookup n eenv of
        Nothing -> []
        Just r -> names r
    ns' = ns ++ tenv_hits ++ eenv_hits

