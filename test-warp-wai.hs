{-# LANGUAGE OverloadedStrings #-}

import Control.Concurrent
import Control.Monad

import Common

main :: IO ()
main = do
    void . forkIO $ runHttpsClient httpsPort
    putStrLn "HTTPS client thread started."
    runHttpServer httpPort
