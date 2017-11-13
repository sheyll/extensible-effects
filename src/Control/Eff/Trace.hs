{-# OPTIONS_GHC -Werror #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs, DataKinds #-}
{-# LANGUAGE Safe #-}
-- | A Trace effect for debugging
module Control.Eff.Trace( Trace (..)
                        , trace
                        , runTrace
                        ) where

import Control.Eff1
import Data.OpenUnion51

-- | Trace effect for debugging
data Trace v where
  Trace :: String -> Trace ()

-- | Print a string as a trace.
trace :: Member Trace r => String -> Eff r ()
trace = send . Trace

-- | Run a computation producing Traces.
-- The handler for IO request: a terminal handler
runTrace :: Eff '[Trace] w -> IO w
runTrace (Val x) = return x
runTrace (E u q) = case decomp u of
     Right (Trace s) -> putStrLn s >> runTrace (qApp q ())
     -- Nothing more can occur
     Left _ -> error "runTrace: the impossible happened!"
