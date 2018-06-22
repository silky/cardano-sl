{-# LANGUAGE DataKinds  #-}
{-# LANGUAGE Rank2Types #-}

-- | Protocol/versioning related communication helpers.

module Pos.Infra.Communication.Listener
       ( listenerConv
       ) where

import qualified Node as N
import           Node.Message.Class (Serializable, Serializable')
import           Universum

import qualified Network.Broadcast.OutboundQueue as OQ
import           Pos.Infra.Communication.Protocol (ConversationActions, HandlerSpec (..), ListenerSpec (..),
                     Message, NodeId, OutSpecs, VerInfo (..), PackingType, checkProtocolMagic,
                     checkingInSpecs, messageCode)
import           Pos.Infra.Network.Types (Bucket)
import           Pos.Util.Trace (Trace, Severity)

-- TODO automatically provide a 'recvLimited' here by using the
-- 'MessageLimited'?
listenerConv
    :: forall snd attr rcv' rcv pack .
       ( Message snd
       , Message rcv
       )
    => Trace IO (Severity, Text)
    -> Serializable' PackingType IO snd
    -> Serializable attr PackingType IO rcv' rcv
    -> OQ.OutboundQ pack NodeId Bucket
    -> (VerInfo -> NodeId -> ConversationActions snd rcv -> IO ())
    -> (ListenerSpec, OutSpecs)
listenerConv logTrace sndS rcvS oq h = (lspec, mempty)
  where
    spec = (rcvMsgCode, ConvHandler sndMsgCode)
    lspec =
      flip ListenerSpec spec $ \ourVerInfo ->
          N.Listener sndS rcvS $ \peerVerInfo' nNodeId conv -> checkProtocolMagic ourVerInfo peerVerInfo' $ do
              OQ.clearFailureOf oq nNodeId
              checkingInSpecs logTrace ourVerInfo peerVerInfo' spec nNodeId $
                  h ourVerInfo nNodeId conv

    sndProxy :: Proxy snd
    sndProxy = Proxy
    rcvProxy :: Proxy rcv
    rcvProxy = Proxy

    sndMsgCode = messageCode sndProxy
    rcvMsgCode = messageCode rcvProxy