module G2.Internals.Execution.Support
    ( ExecState(..)
    , fromState
    , toState

    , Symbol(..)
    , Stack
    , Frame(..)
    , Scope
    , EnvObj(..)
    , Code(..)
    , ExecCond(..)

    , pushStack
    , popStack

    , lookupScope
    , vlookupScope
    , insertEnvObj
    , insertEnvObjs
    ) where

import G2.Internals.Language

import qualified Data.Map as M

-- | The execution state that we keep track of is different than the regular
-- G2 state. This is beacuse for execution we need more complicated data
-- structures to make things more run smoothly in the rule reductions. However
-- there are `fromState` and `toState` functions provided to extract and inject
-- back the original values from `State`.
data ExecState = ExecState { exec_stack :: Stack
                           , exec_scope :: Scope
                           , exec_code :: Code
                           , exec_names :: NameGen
                           , exec_paths :: [ExecCond]
                           } deriving (Show, Eq, Read)

-- | `State` to `ExecState`.
fromState :: State -> ExecState
fromState = undefined

-- | `ExecState` to `State`.
toState :: State -> ExecState -> State
toState = undefined

-- | Symbolic values have an `Id` for their name, as well as an optional
-- scoping context to denote what they are derived from.
data Symbol = Symbol Id (Maybe (Expr, Scope)) deriving (Show, Eq, Read)

-- | The reason hy Haskell does not enable stack traces by default is because
-- the notion of a function call stack does not really exist in Haskell. The
-- stack is a combination of update pointers, application frames, and other
-- stuff!
newtype Stack = Stack [Frame] deriving (Show, Eq, Read)

-- | These are stack frames.
-- * Case frames contain an `Id` for which to bind the inspection expression,
--     a list of `Alt`, and a `Scope` in which this `CaseFrame` happened.
--     `CaseFrame`s are generated as a result of evaluating `Case` expressions.
-- * Application frames contain a single expression and its `Scope`. These are
--     generated by `App` expressions.
-- * Update frames contain the `Name` on which to inject a new thing into the
--     expression environment after the current expression is done evaluating.
data Frame = CaseFrame Id [Alt] Scope
           | ApplyFrame Expr Scope
           | UpdateFrame Name
           deriving (Show, Eq, Read)

-- | From a user perspective, `Scope`s are mappings from `Name` to `EnvObj`s.
-- however, because redirection pointers are included, this complicates things.
-- Instead, we use the `Either` type to separate redirection and actual objects,
-- so by using the supplied lookup functions, the user should never be returned
-- a redirection pointer from `Scope` lookups.
newtype Scope = Scope (M.Map Name (Either Name EnvObj))
             deriving (Show, Eq, Read)

-- | Environment objects can either by some expression object, or a symbolic
-- object that has been computed before. Lastly, they can be BLACKHOLEs that
-- Simon Peyton Jones claims to stop certain types of bad evaluations.
data EnvObj = ExprObj Expr
            | SymObj Symbol
            | BLACKHOLE
            deriving (Show, Eq, Read)

-- | `Code` is the current expression we have. We are either evaluating it, or
-- it is in some terminal form that is simply returned. Technically we do not
-- need to make this distinction and can simply call a `isTerm` function or
-- equivalent to check, but this makes clearer distinctions for writing the
-- evaluation code.
data Code = Evaluate Expr
          | Return Expr
          deriving (Show, Eq, Read)

-- | The current logical conditions up to our current path of execution.
-- Here the `ExecAltCond` denotes conditions from matching on data constructors
-- in `Case` statements, while `ExecExtCond` is from external conditions. These
-- are similar to their `State` counterparts, but are now augmented with a
-- `Scope` to allow for further reduction later on / accurate referencing with
-- respect to their environment at the time of creation.
data ExecCond = ExecAltCond AltMatch Expr Bool Scope
              | ExecExtCond Expr Bool Scope
              deriving (Show, Eq, Read)

-- | Push a `Frame` onto the `Stack`.
pushStack :: Frame -> Stack -> Stack
pushStack frame (Stack frames) = Stack (frame : frames)

-- | Pop a `Frame` from the `Stack`, should it exist.
popStack :: Stack -> Maybe (Frame, Stack)
popStack (Stack []) = Nothing
popStack (Stack (frame:frames)) = Just (frame, Stack frames)

-- | Lookup an `EnvObj` in the `Scope` by `Name`.
lookupScope :: Name -> Scope -> Maybe EnvObj
lookupScope name (Scope smap) = case M.lookup name smap of
    Just (Left redir) -> lookupScope redir (Scope smap)
    Just (Right eobj) -> Just eobj
    Nothing -> Nothing

-- | Lookup an `EnvObj` in the `Scope` by `Id`.
vlookupScope :: Id -> Scope -> Maybe EnvObj
vlookupScope var scope = lookupScope (idName var) scope

-- | Insert an `EnvObj` into the `Scope`.
insertEnvObj :: (Name, EnvObj) -> Scope -> Scope
insertEnvObj (k, v) (Scope smap) = Scope (M.insert k (Right v) smap)

-- | Insert multiple `EnvObj`s into the `Scope`.
insertEnvObjs :: [(Name, EnvObj)] -> Scope -> Scope
insertEnvObjs kvs scope = foldr insertEnvObj scope kvs

