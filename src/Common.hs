{-# LANGUAGE OverloadedStrings #-}

module Common where

import Control.Exception
import Control.Monad
import Data.ByteString.Lazy (ByteString)
import Data.Monoid ((<>))
import Network.Connection
import Network.HTTP.Types
import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Handler.WarpTLS

import qualified Data.ByteString.Lazy as LBS
import qualified Network.HTTP.Conduit as HC
import qualified Network.HTTP.Types as HT

-- We need a Manager that disables TLS certificate checking because we're running
-- against a self signed certificate. When this problem was first found, it was
-- querying server with a valid TLS certificate and certificate checking was
-- enabled
mgrSetttings :: HC.ManagerSettings
mgrSetttings = HC.mkManagerSettings (TLSSettingsSimple True False False) Nothing

httpPort, httpsPort :: Int
httpPort = 2000
httpsPort = 3000

-- -----------------------------------------------------------------------------
-- HTTP and HTTPS clients.

runHttpClient :: Int -> IO ()
runHttpClient portnum = do
    mgr <- HC.newManager mgrSetttings
    req <- parseRequest url
    forever $ do
        eresp <- wrappedHttpLbs req mgr
        case eresp of
          Left e -> handleHttpException "runHttpClient" e
          Right resp ->
            unless (HC.responseStatus resp == HT.status200 && LBS.length (HC.responseBody resp) == 28) $
                LBS.putStr $ HC.responseBody resp
  where
    url :: String
    url = "http://localhost:" <> show portnum <> "/http"

runHttpsClient :: Int -> IO ()
runHttpsClient portnum = do
    mgr <- HC.newManager mgrSetttings
    req <- parseRequest url
    forever $ do
        eresp <- wrappedHttpLbs req mgr
        case eresp of
          Left e -> handleHttpException "runHttpsClient" e
          Right resp ->
            unless (HC.responseStatus resp == HT.status200 && LBS.length (HC.responseBody resp) == 29) $
                LBS.putStr $ HC.responseBody resp
  where
    url :: String
    url = "https://localhost:" <> show portnum <> "/https"

handleHttpException :: String -> HC.HttpException -> IO ()
handleHttpException name (HC.HttpExceptionRequest _ e) = putStrLn $ name ++ " : " ++ show e
handleHttpException name e = putStrLn $ name ++ " : " ++ show e


wrappedHttpLbs :: HC.Request -> HC.Manager -> IO (Either HC.HttpException (HC.Response ByteString))
wrappedHttpLbs req mgr = try $ HC.httpLbs req mgr

parseRequest :: String -> IO HC.Request
parseRequest url = do
    req <- HC.parseRequest url
    pure $ req
        { HC.requestHeaders = (hConnection, "close") : HC.requestHeaders req
        -- , HC.checkStatus = \ _ _ _ -> Nothing
        }

-- -----------------------------------------------------------------------------
-- Super brain-dead HTTP and HTTPS servers.

runHttpServer :: Int -> IO ()
runHttpServer portnum = do
    let settings = setPort portnum $ setHost "*4" defaultSettings
    putStrLn $ "Warp server running on port " <> show portnum <> "."
    runSettings settings $ serverApp "HTTP"

runHttpsServer :: Int -> IO ()
runHttpsServer portnum = do
    let settings = setPort portnum $ setHost "*4" defaultSettings
        tlsSettings' = tlsSettings "certificate.pem" "key.pem"
    putStrLn $ "WarpTLS server running on port " <> show portnum <> "."
    runTLS tlsSettings' settings $ serverApp "HTTPS"

serverApp :: ByteString -> Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived
serverApp name _req respond =
    respond $ responseLBS status200 respHeaders respBody
  where
    respBody = name <> ": What's that function?\n"
    respHeaders =
            [ (HT.hContentType, "text/plain")
            -- Want `Transfer-encoding : chunked` so do not add a `hContentLength`
            -- field.
            -- , (HT.hContentLength, fromString . show $ BS.length text)
            ]
