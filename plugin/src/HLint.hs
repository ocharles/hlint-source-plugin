{-# language RecordWildCards #-}

module HLint ( plugin ) where

-- base
import Control.Monad.IO.Class ( liftIO )
import Data.Maybe ( maybeToList )

-- ghc
import qualified Bag
import qualified DynFlags
import qualified ErrUtils
import qualified FastString
import qualified GhcMonad
import qualified HscTypes
import qualified Outputable
import qualified Plugins
import qualified SrcLoc

-- haskell-src-exts
import qualified Language.Haskell.Exts.SrcLoc as HSE

-- hlint
import qualified Language.Haskell.HLint3 as HLint


plugin :: Plugins.Plugin
plugin =
  Plugins.defaultPlugin
    { Plugins.parsedResultAction =
        \_cliArgs modSummary parsedModule ->
          parsedModule <$ hlintPlugin modSummary
    }


hlintPlugin :: HscTypes.ModSummary -> HscTypes.Hsc ()
hlintPlugin modSummary = do
  dynFlags <-
    DynFlags.getDynFlags

  ideas <-
    liftIO ( HLint.hlint [ "--quiet", HscTypes.ms_hspp_file modSummary ] )

  liftIO
    ( HscTypes.printOrThrowWarnings
        dynFlags
        ( Bag.listToBag ( map ( ideaToErrMsg dynFlags ) ideas ) )
    )

  where

    ideaToErrMsg dynFlags idea =
      let
        errDoc =
          ErrUtils.errDoc
            [ Outputable.text ( HLint.ideaHint idea ) ]
            ( case HLint.ideaTo idea of
                Just to ->
                  [ Outputable.hang
                      ( Outputable.text "Why not:" )
                      4
                      ( Outputable.vcat ( map Outputable.text ( lines to ) ) )
                  ]

                _ ->
                  []
            )
            ( map ( Outputable.text . show ) ( HLint.ideaNote idea ) )

      in
      ( case HLint.ideaSeverity idea of
          HLint.Error ->
            ErrUtils.mkPlainErrMsg

          _ ->
            ErrUtils.mkPlainWarnMsg
      )
        dynFlags
        ( let
            HSE.SrcSpan{..} =
              HLint.ideaSpan idea

            fileName =
              FastString.fsLit srcSpanFilename

          in
          SrcLoc.mkSrcSpan
            ( SrcLoc.mkSrcLoc fileName srcSpanStartLine srcSpanStartColumn )
            ( SrcLoc.mkSrcLoc fileName srcSpanEndLine srcSpanEndColumn )
        )
        ( ErrUtils.formatErrDoc dynFlags errDoc )
