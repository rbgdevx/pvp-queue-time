local _, NS = ...

local After = C_Timer.After

---@type PVPQueueTime
local PVPQueueTime = NS.PVPQueueTime
local PVPQueueTimeFrame = NS.PVPQueueTime.frame

local Interface = NS.Interface

function PVPQueueTime:PLAYER_ENTERING_WORLD()
  Interface:RestorePosition()
  After(2, function()
    Interface:CheckQueueStatus()
  end)
end

function PVPQueueTime:PLAYER_LOGIN()
  PVPQueueTimeFrame:UnregisterEvent("PLAYER_LOGIN")
  PVPQueueTimeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  PVPQueueTimeFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
end
PVPQueueTimeFrame:RegisterEvent("PLAYER_LOGIN")

function PVPQueueTime:UPDATE_BATTLEFIELD_STATUS()
  Interface:CheckQueueStatus()
  After(2, function()
    Interface:CheckQueueStatus()
  end)
end
