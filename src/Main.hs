module Main where

import System.Environment

import HscTypes
import TyCon
import GHC

import G2.Core.Defunctionalizor
import G2.Core.Language
import G2.Core.Evaluator
import G2.Core.Utils

import G2.Haskell.Prelude
import G2.Haskell.Translator

import G2.SMT.Z3

import qualified G2.Sample.Prog1 as P1
import qualified G2.Sample.Prog2 as P2

import qualified Data.List as L
import qualified Data.Map  as M

main = do
    (filepath:entry:xs) <- getArgs
    raw_core <- mkRawCore filepath
    putStrLn "RAW CORE"
    putStrLn =<< outStr raw_core
    let (rt_env, re_env) = mkG2Core raw_core
    let t_env' = M.union rt_env (M.fromList prelude_t_decls)
    let e_env' = re_env  -- M.union re_env (M.fromList prelude_e_decls)
    let init_state = initState t_env' e_env' entry

    putStrLn "INIT STATE"
    putStrLn $ show init_state

    let higher = findPassedInFuncTypes init_state
    let passed = findPassedInFuncs init_state

    putStrLn "mkStateStr of INIT STATE"
    putStrLn $ mkStatesStr [init_state]

    putStrLn "HIGHER"
    print higher
    print passed

    putStrLn "+++++++++++++++++++++++++"


    let defun_init_state = defunctionalize init_state

    --putStrLn $ mkStateStr init_state
    
    putStrLn $ mkStatesStr [defun_init_state]

    putStrLn "======================="

    let (states, n) = runN [defun_init_state] 50
    putStrLn ("Number of execution states: " ++ (show (length states)))
    -- putStrLn $ mkStatesStr states

    putStrLn "Compiles!\n\n"
    
    mapM_ (\s@(_, _, _, pc) -> do
        putStrLn . mkPCStr $ pc
        putStrLn " => "
        printModel s) states

