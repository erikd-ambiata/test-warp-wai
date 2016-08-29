{-# LANGUAGE OverloadedStrings #-}

import Control.Concurrent
import Control.Monad

import Common

main :: IO ()
main = do
    void . forkIO $ runHttpsClient httpsPort
    putStrLn "HTTPS client thread started."
    -- Let the HTTPS client run for a while before starting the HTTP server.
    threadDelay (15 * 1000 * 1000)
    void . forkIO $ runHttpServer httpPort
    forever $ threadDelay (1000 * 1000)
