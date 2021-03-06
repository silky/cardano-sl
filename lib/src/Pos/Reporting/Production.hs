-- | Definition of a 'Reporter IO' which uses log-warper to gather logs and
-- uses the HTTP backend to send them to some server(s).

module Pos.Reporting.Production
    ( ProductionReporterParams (..)
    , productionReporter
    ) where

import           Universum

import           Pos.Core (ProtocolMagic)
import           Pos.Infra.Diffusion.Types (Diffusion)
import           Pos.Infra.Reporting (Reporter (..))
import           Pos.Infra.Reporting.Http (reportNode)
import           Pos.Infra.Reporting.NodeInfo (extendWithNodeInfo)
import           Pos.Infra.Reporting.Wlog (LoggerConfig, withWlogTempFile)
import           Pos.Util.CompileInfo (CompileTimeInfo)
import           Pos.Util.Trace (Severity, Trace)

data ProductionReporterParams = ProductionReporterParams
    { prpServers         :: ![Text]
    , prpLoggerConfig    :: !LoggerConfig
    , prpProtocolMagic   :: !ProtocolMagic
    , prpCompileTimeInfo :: !CompileTimeInfo
    , prpTrace           :: !(Trace IO (Severity, Text))
    }

productionReporter
    :: ProductionReporterParams
    -> Diffusion IO -- ^ Used to get status info, not to do any network stuff.
    -> Reporter IO
productionReporter params diffusion = Reporter $ \rt -> withWlogTempFile logConfig $ \mfp -> do
    rt' <- extendWithNodeInfo diffusion rt
    reportNode logTrace protocolMagic compileTimeInfo servers mfp rt'
  where
    servers = prpServers params
    logConfig = prpLoggerConfig params
    protocolMagic = prpProtocolMagic params
    compileTimeInfo = prpCompileTimeInfo params
    logTrace = prpTrace params
