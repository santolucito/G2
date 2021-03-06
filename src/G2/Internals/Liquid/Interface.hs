{-# LANGUAGE FlexibleContexts #-}

module G2.Internals.Liquid.Interface where

import G2.Internals.Config.Config

import G2.Internals.Translation
import G2.Internals.Interface
import G2.Internals.Language as Lang
import G2.Internals.Execution
import G2.Internals.Liquid.Conversion
import G2.Internals.Liquid.Measures
import G2.Internals.Liquid.ElimPartialApp
import G2.Internals.Liquid.SimplifyAsserts
import G2.Internals.Liquid.TCGen
import G2.Internals.Solver

import qualified Language.Haskell.Liquid.GHC.Interface as LHI
import Language.Haskell.Liquid.Types hiding (Config)
import qualified Language.Haskell.Liquid.Types.PrettyPrint as PPR
import Language.Haskell.Liquid.UX.CmdLine
import Language.Fixpoint.Types.PrettyPrint as FPP

import Data.Coerce
import qualified Data.Map as M
import qualified Data.Text as T
import qualified Data.Maybe as B

import qualified GHC as GHC
import Var

import G2.Internals.Language.KnownValues

-- | findCounterExamples
-- Given (several) LH sources, and a string specifying a function name,
-- attempt to find counterexamples to the functions liquid type
findCounterExamples :: FilePath -> FilePath -> FilePath -> T.Text -> [FilePath] -> [FilePath] -> Config -> IO [(State, [Rule], [Expr], Expr, Maybe (Name, [Expr], Expr))]
findCounterExamples proj primF fp entry libs lhlibs config = do
    ghcInfos <- getGHCInfos proj [fp] lhlibs
    tgt_trans <- translateLoaded proj fp primF libs False
    runLHCore entry tgt_trans ghcInfos config

runLHCore :: T.Text -> (Maybe T.Text, Program, [ProgramType], [(Name, Lang.Id, [Lang.Id])])
                    -> [GhcInfo]
                    -> Config
          -> IO [(State, [Rule], [Expr], Expr, Maybe (Name, [Expr], Expr))]
runLHCore entry (mb_modname, prog, tys, cls) ghcInfos config = do
    let specs = funcSpecs ghcInfos
    let lh_measures = measureSpecs ghcInfos
    let init_state = initState prog tys cls Nothing Nothing Nothing True entry mb_modname
    let cleaned_state = (markAndSweepPreserving (reqNames init_state) init_state) { type_env = type_env init_state }
    let no_part_state = elimPartialApp cleaned_state
    let (lh_state, tcv) = createLHTC no_part_state
    let lhtc_state = addLHTC lh_state tcv
    let measure_state = createMeasures lh_measures tcv lhtc_state
    let (merged_state, mkv) = mergeLHSpecState specs measure_state tcv
    let beta_red_state = simplifyAsserts mkv merged_state
    hpp <- getZ3ProcessHandles
    run smt2 hpp config beta_red_state


getGHCInfos :: FilePath -> [FilePath] -> [FilePath] -> IO [GhcInfo]
getGHCInfos proj fp lhlibs = do
    config <- getOpts []

    let config' = config {idirs = idirs config ++ [proj] ++ lhlibs
                         , files = files config ++ lhlibs
                         , ghcOptions = ["-v"]}
    return . fst =<< LHI.getGhcInfos Nothing config' fp
    
funcSpecs :: [GhcInfo] -> [(Var, LocSpecType)]
funcSpecs = concatMap (gsTySigs . spec)

measureSpecs :: [GhcInfo] -> [Measure SpecType GHC.DataCon]
measureSpecs = concatMap (gsMeasures . spec)

reqNames :: State -> [Name]
reqNames (State { expr_env = eenv
                , type_classes = tc
                , known_values = kv }) = 
    Lang.names [ mkGe eenv
               , mkGt eenv
               , mkEq eenv
               , mkNeq eenv
               , mkLt eenv
               , mkLe eenv
               , mkAnd eenv
               , mkOr eenv
               , mkNot eenv
               , mkPlus eenv
               , mkMinus eenv
               , mkMult eenv
               -- , mkDiv eenv
               -- , mkMod eenv
               , mkNegate eenv
               , mkImplies eenv
               , mkIff eenv
               , mkFromInteger eenv
               -- , mkToInteger eenv
               ]
    ++
    Lang.names (M.filterWithKey (\k _ -> k == eqTC kv || k == numTC kv || k == ordTC kv) (coerce tc :: M.Map Name Class))

pprint :: (Var, LocSpecType) -> IO ()
pprint (v, r) = do
    let i = mkIdUnsafe v

    let doc = PPR.rtypeDoc Full $ val r
    putStrLn $ show i
    putStrLn $ show doc
