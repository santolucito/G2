-- | Reduction Rules for ExecStack Execution Semantics
module G2.Internals.Execution.Rules
  ( stackReduce
  ) where

import G2.Internals.Language

import G2.Internals.Execution.Support

data Rule = RuleEvalVal
          | RuleEvalVar | RuleEvalUnInt
          | RuleEvalApp
          | RuleEvalLet
          | RuleEvalCaseData | RuleEvalCaseLit | RuleEvalCaseDefault
                             | RuleCaseSym | RuleEvalCaseNonVal

          | RuleReturnUpdateVar | RuleReturnUpdateNonVar
          | RuleReturnCase
          | RuleReturnApplyLam | RuleReturnApplyData
                                  | RuleReturnApplySym

          | RuleIdentity

          | RuleError
           deriving (Show, Eq, Read)

-- | Unravels the application spine.
unApp :: Expr -> [Expr]
unApp (App f a) = unApp f ++ [a]
unApp expr = [expr]

-- | If something is in "value form", then it is essentially ready to be
-- returned and popped off the heap. This will be the SSTG equivalent of having
-- Return vs Evaluate for the ExecCode of the `State`.
--
-- So in this context, the following are considered NOT-value forms:
--   `Var`, only if a lookup still available in the expression environment.
--   `App`, which involves pushing the RHS onto the `ExecStack`.
--   `Let`, which involves binding the binds into the eenv
--   `Case`, which involves pattern decomposition and stuff.
isValueForm :: Expr -> ExecExprEnv -> Bool
isValueForm (Var (Id name _)) eenv = case lookupExecExprEnv name eenv of
    Just (ExprObj _) -> False
    _ -> True
isValueForm (App f a) _ = case unApp (App f a) of
  (Data _:_) -> True
  _ -> False
isValueForm (Let _ _) _ = False
isValueForm (Case _ _ _) _ = False
isValueForm _ _ = True

-- | Convert bind objects of `(Id, Expr)` pairs into `[(Name, EnvObj)]`s.
bindsToEnvObjs :: [(Id, Expr)] -> [(Name, EnvObj)]
bindsToEnvObjs kvs = map (\(k, v) -> (idName k, ExprObj v)) kvs

-- | Inject binds into the eenv.
liftBinds :: [(Id, Expr)] -> ExecExprEnv -> ExecExprEnv
liftBinds kvs eenv = insertEnvObjs (bindsToEnvObjs kvs) eenv

-- | DEFAULT `Alt`s.
defaultAlts :: [Alt] -> [Alt]
defaultAlts alts = [a | a @ (Alt Default _) <- alts]

-- | Non-DEFAULT `Alt`s.
nonDefaultAlts :: [Alt] -> [Alt]
nonDefaultAlts alts = [a | a @ (Alt acon _) <- alts, acon /= Default]

-- | Match data constructor based `Alt`s.
matchDataAlts :: DataCon -> [Alt] -> [Alt]
matchDataAlts dc alts = [a | a @ (Alt (DataAlt adc _) _) <- alts , dc == adc]

-- | Match literal constructor based `Alt`s.
matchLitAlts :: Lit -> [Alt] -> [Alt]
matchLitAlts lit alts = [a | a @ (Alt (LitAlt alit) _) <- alts, lit == alit]

-- | Negate an `ExecCond`.
negateExecCond :: ExecCond -> ExecCond
negateExecCond (ExecAltCond a e b v) = ExecAltCond a e (not b) v
negateExecCond (ExecExtCond e b v) = ExecExtCond e (not b) v

-- | Lift `ExecCond`s to a `ExecState` level.
liftSymAlt :: ExecState -> Id -> Symbol -> Expr -> [ExecCond] -> ExecState
liftSymAlt state cvar sym aexpr conds = state'
  where
    eenv = exec_eenv state
    state' = state { exec_eenv = insertEnvObj (idName cvar) (SymObj sym) eenv
                   , exec_code = Evaluate aexpr
                   , exec_paths = conds ++ exec_paths state }

-- | Funciton for performing rule reductions based on stack based evaluation
-- semantics with heap memoization.
stackReduce :: ExecState -> (Rule, [ExecState])
stackReduce state @ ExecState { exec_stack = stack
                              , exec_eenv = eenv
                              , exec_code = code
                              , exec_names = confs
                              , exec_paths = paths }


-- The semantics differ a bit from SSTG a bit, namely in what is and is not
-- returned from the heap. In SSTG, you return either literals or pointers.
-- The distinction is less clear here. For now :)

  -- Our current thing is a value form, which means we can return it.
  | Evaluate expr <- code
  , isValueForm expr eenv =
    ( RuleEvalVal
    , [state { exec_code = Return expr }])

  -- If our variable points to something on the heap, we first push the current
  -- name of the variable onto the stack and evaluate the expression that it
  -- points to. After the latter is done evaluating, we pop the stack to add
  -- a redirection pointer into the heap.
  | Evaluate (Var var) <- code
  , Just (ExprObj expr) <- lookupExecExprEnv (idName var) eenv =
    let frame = UpdateFrame (idName var)
    in ( RuleEvalVar
       , [state { exec_stack = pushExecStack frame stack
                , exec_code = Evaluate expr }])

  -- If we encounter a vairable that is in eenv, we treated it as a symbolic
  -- object and subject it to uninterpreted evaluation later on. This is done
  -- by injecting it into the heap and then evaluating the same expression
  -- again. This is the essense of memoization / single-evaluation in laziness.
  | Evaluate (Var var) <- code
  , Nothing <- lookupExecExprEnv (idName var) eenv =
    let (sname, re) = freshSeededName (idName var) confs
        svar = Id sname (typeOf var)
        -- Nothing denotes that this is a "base" symbolic value that is not
        -- dependent on any other expressions.
        sym = Symbol svar Nothing
    in ( RuleEvalUnInt
       , [state { exec_eenv = insertEnvObj (idName var) (SymObj sym) eenv
                , exec_code = Evaluate (Var var)
                , exec_names = re}])

  -- Push application RHS onto the stack. This is essentially the same as the
  -- original STG rules, but we pretend that every function is (appropriately)
  -- single argument. However one problem is that eenv sharing has a redundant
  -- representation because long `App` chains will all share the same eenv.
  -- However given actual lazy evaluations within Haskell, all the `ExecExprEnv`s at
  -- each frame would really be stored in a single location on the actuall
  -- Haskell heap during execution.
  | Evaluate (App fexpr aexpr) <- code =
    let frame = ApplyFrame aexpr
    in ( RuleEvalApp
       , [state { exec_stack = pushExecStack frame stack
                , exec_code = Evaluate fexpr }])

  -- Lift all the let bindings into the environment and continue with eenv and
  -- continue with evaluation of the let expression.
  | Evaluate (Let binds expr) <- code =
    ( RuleEvalLet
    , [state { exec_eenv = liftBinds binds eenv
             , exec_code = Evaluate expr }])

  -- | If we are pointing to a symbolic value in the environment, handle it
  -- appropriately by branching on every `Alt`.
  | Evaluate (Case (Var var) cvar alts) <- code
  , Just (SymObj sym) <- lookupExecExprEnv (idName var) eenv
  , (ndefs, defs) <- (nonDefaultAlts alts, defaultAlts alts)
  , length (ndefs ++ defs) > 0 =
    let poss = map (\(Alt a e) -> (ExecAltCond a (Var var) True eenv, e)) ndefs
        ndef_sts = map (\(c, e) -> liftSymAlt state cvar sym e [c]) poss
        -- Now make the negatives
        negs = map (\(c, _) -> negateExecCond c) poss
        def_sts = map (\(Alt _ e) -> liftSymAlt state cvar sym e negs) defs
    in (RuleCaseSym, ndef_sts ++ def_sts)

  -- | Is the current expression able to match with a literal based `Alt`? If
  -- so, we do the cvar binding, and proceed with evaluation of the body.
  | Evaluate (Case (Lit lit) cvar alts) <- code
  , (Alt (LitAlt _) expr):_ <- matchLitAlts lit alts =
    let binds = [(cvar, Lit lit)]
        cond = ExecAltCond (LitAlt lit) (Lit lit) True eenv
    in ( RuleEvalCaseLit
       , [state { exec_eenv = liftBinds binds eenv
                , exec_code = Evaluate expr
                , exec_paths = cond : paths }])

  -- Is the current expression able to match a data consturctor based `Alt`? If
  -- so, then we bind all the parameters to the appropriate arguments and
  -- proceed with the evaluation of the `Alt`'s expression. We also make sure
  -- to perform the cvar binding.
  | Evaluate (Case mexpr cvar alts) <- code
  , (Data dcon):args <- unApp mexpr
  , (Alt (DataAlt _ params) expr):_ <- matchDataAlts dcon alts
  , length params == length args =
    let binds = (cvar, mexpr) : zip params args
        cond = ExecAltCond (DataAlt dcon params) mexpr True eenv
    in ( RuleEvalCaseData
       , [state { exec_eenv = liftBinds binds eenv
                , exec_code = Evaluate expr
                , exec_paths = cond : paths}])

  -- | We are not able to match any of the stuff, and hit a DEFAULT instead? If
  -- so, we just perform the cvar binding and proceed with the alt expression.
  | Evaluate (Case mexpr cvar alts) <- code
  , (Alt _ expr):_ <- defaultAlts alts =
    let binds = [(cvar, mexpr)]
        cond = ExecAltCond Default mexpr True eenv
    in ( RuleEvalCaseDefault
       , [state { exec_eenv = liftBinds binds eenv
                , exec_code = Evaluate expr
                , exec_paths = cond : paths }])

  -- Case evaluation also uses the stack in graph reduction based evaluation
  -- semantics. The case's binding variable and alts are pushed onto the stack
  -- as a `CaseFrame` along with their appropriate `ExecExprEnv`. However this
  -- is only done when the matching expression is NOT in value form. Value
  -- forms should be handled by other RuleEvalCase* rules.
  | Evaluate (Case mexpr cvar alts) <- code
  , not (isValueForm mexpr eenv) =
    let frame = CaseFrame cvar alts eenv
    in ( RuleEvalCaseNonVal
       , [state { exec_stack = pushExecStack frame stack
                , exec_code = Evaluate mexpr }])

  -- Return forms the `ExecCode`.

  -- We are returning something and the first thing that we have on the stack
  -- is an `UpdateFrame`, this means that we add a redirection pointer to the
  -- `ExecExprEnv`, and continue with execution. This is the equivalent of
  -- performing memoization on values that we have seen.
  | Just (UpdateFrame frm_name, stack') <- popExecStack stack
  , Return (Var (Id name ty)) <- code =
  ( RuleReturnUpdateVar
  , [state { exec_stack = stack'
           , exec_eenv = insertRedirect frm_name name eenv
           , exec_code = Return (Var (Id name ty)) }])

  -- If the variable we are returning does not have a `Var` in it at the
  -- immediate top level, then we have to insert it into the `ExecExprEnv`
  -- directly.
  | Just (UpdateFrame frm_name, stack') <- popExecStack stack
  , Return expr <- code =
  ( RuleReturnUpdateNonVar
  , [state { exec_stack = stack'
           , exec_eenv = insertEnvObj frm_name (ExprObj expr) eenv
           , exec_code = Return expr }])

  -- In the event that we are returning and we have a `CaseFrame` waiting for
  -- us at the top of the stack, we would simply inject it into the case
  -- expression. We do a lot of assumptions here about the form of expressions!
  | Just (CaseFrame cvar alts frm_eenv, stack') <- popExecStack stack
  , Return expr <- code =
  ( RuleReturnCase
  , [state { exec_stack = stack'
           , exec_eenv = frm_eenv
           , exec_code = Evaluate (Case expr cvar alts) }])

  -- When we have an `ApplyFrame` on the top of the stack, things might get a
  -- bit tricky, since we need to make sure that the thing we end up returning
  -- is appropriately a value. In the case of `Lam`, we need to perform
  -- application, and then go into the expression body.
  | Just (ApplyFrame aexpr, stack') <- popExecStack stack
  , Return (Lam b lexpr) <- code =
  let binds = [(b, aexpr)]
  in ( RuleReturnApplyLam
     , [state { exec_stack = stack'
              , exec_eenv = liftBinds binds eenv
              , exec_code = Evaluate lexpr }])

  -- When we have an `DataCon` application chain, we need to tack on the
  -- expression in the `ApplyFrame` at the end.
  | Just (ApplyFrame aexpr, stack') <- popExecStack stack
  , Return dexpr <- code
  , (Data _):_ <- unApp dexpr =
  ( RuleReturnApplyData
  , [state { exec_stack = stack'
           , exec_eenv = eenv
           , exec_code = Return (App dexpr aexpr) }])

  -- When we have an symbolic variable pointer, the best we can do is make
  -- another variable and insert it into the `ExecExprEnv`. This is the last
  -- condition that we can reasonably handle without creating excessively long
  -- `App` spines, which is only okay for `Data` expressions.
  | Just (ApplyFrame aexpr, stack') <- popExecStack stack
  , Return (Var (Id name _)) <- code
  , Just (SymObj (Symbol sid _)) <- lookupExecExprEnv name eenv =
  let (sname, confs') = freshSeededName (idName sid) confs
      sres = Id sname (TyApp (typeOf sid) (typeOf aexpr))
      sym_app = Symbol sres (Just (App (Var sid) aexpr, eenv))
  in ( RuleReturnApplySym
     , [state { exec_stack = stack'
              , exec_eenv = insertEnvObj sname (SymObj sym_app) eenv
              , exec_code = Return (Var sres)
              , exec_names = confs' }])

  | otherwise = (RuleError, [])
