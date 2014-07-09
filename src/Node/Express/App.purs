module Node.Express.App
    ( AppM()
    , App()
    , listen, use
    , getProp, setProp
    , get, post, put, delete
    ) where

import Data.Foreign
import Data.Either
import Data.String.Regex
import Control.Monad.Eff
import Control.Monad.Eff.Class

import Node.Express.Types
import Node.Express.Internal.App
import Node.Express.Handler


data AppM a = AppM (Application -> ExpressM a)
type App = AppM Unit

instance functorAppM :: Functor AppM where
    (<$>) f (AppM h) = AppM \app -> liftM1 f $ h app

instance applyAppM :: Apply AppM where
    (<*>) (AppM f) (AppM h) = AppM \app -> do
        res <- h app
        trans <- f app
        return $ trans res

instance applicativeAppM :: Applicative AppM where
    pure x = AppM \_ -> return x

instance bindAppM :: Bind AppM where
    (>>=) (AppM h) f = AppM \app -> do
        res <- h app
        case f res of
             AppM g -> g app

instance monadAppM :: Monad AppM

instance monadEffAppM :: MonadEff AppM where
    liftEff act = AppM \_ -> liftEff act

listen :: forall e. App -> Number -> (Event -> Eff e Unit) -> ExpressM Unit
listen (AppM act) port cb = do
    app <- intlMkApplication
    act app
    intlAppListen app port cb

use :: (ExpressM Unit -> Handler) -> App
use middleware = AppM \app ->
    intlAppUse app (\req resp next -> withHandler (middleware next) req resp)

getProp :: forall a. (ReadForeign a) => String -> AppM (Either String a)
getProp name = AppM \app -> intlAppGetProp app name

setProp :: forall a. String -> a -> App
setProp name val = AppM \app -> intlAppSetProp app name val

get :: String -> Handler -> App
get route handler = AppM \app ->
    intlAppHttpGet app (regex route "") $ withHandler handler

post :: String -> Handler -> App
post route handler = AppM \app ->
    intlAppHttpPost app (regex route "") $ withHandler handler

put :: String -> Handler -> App
put route handler = AppM \app ->
    intlAppHttpPut app (regex route "") $ withHandler handler

delete :: String -> Handler -> App
delete route handler = AppM \app ->
    intlAppHttpDelete app (regex route "") $ withHandler handler

all :: String -> Handler -> App
all route handler = AppM \app ->
    intlAppHttpAll app (regex route "") $ withHandler handler
