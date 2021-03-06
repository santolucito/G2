{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts #-}

module G2.Internals.Language.Stack
    ( Stack
    , empty
    , push
    , pop
    , toList) where

import G2.Internals.Language.AST
import G2.Internals.Language.Naming
import G2.Internals.Language.Syntax

newtype Stack a = Stack [a] deriving (Show, Eq, Read)

empty :: Stack a
empty = Stack []

-- | Push a `Frame` onto the `Stack`.
push :: a -> Stack a -> Stack a
push x (Stack xs) = Stack (x : xs)

-- | Pop a `Frame` from the `Stack`, should it exist.
pop :: Stack a -> Maybe (a, Stack a)
pop (Stack []) = Nothing
pop (Stack (x:xs)) = Just (x, Stack xs)

-- | Convert an `Stack` to a list.
toList :: Stack a -> [a]
toList (Stack xs) = xs

instance {-# OVERLAPPING #-} ASTContainer a Expr => ASTContainer (Stack a) Expr where
    containedASTs (Stack s) = containedASTs s
    modifyContainedASTs f (Stack s) = Stack $ modifyContainedASTs f s

instance {-# OVERLAPPING #-} ASTContainer a Type => ASTContainer (Stack a) Type where
    containedASTs (Stack s) = containedASTs s
    modifyContainedASTs f (Stack s) = Stack $ modifyContainedASTs f s

instance {-# OVERLAPPING #-} Named a => Named (Stack a) where
    names (Stack s) = names s

    rename old new (Stack s) = Stack $ rename old new s