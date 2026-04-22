local _, NS = ...

local CreateFrame = CreateFrame

---@class PVPQueueTime
---@field ADDON_LOADED function
---@field PLAYER_LOGIN function
---@field PLAYER_ENTERING_WORLD function
---@field SlashCommands function
---@field frame Frame

---@type PVPQueueTime
---@diagnostic disable-next-line: missing-fields
local PVPQueueTime = {}
NS.PVPQueueTime = PVPQueueTime

local PVPQueueTimeFrame = CreateFrame("Frame", "PVPQueueTimeEventFrame")
PVPQueueTimeFrame:SetScript("OnEvent", function(_, event, ...)
  if PVPQueueTime[event] then
    PVPQueueTime[event](PVPQueueTime, ...)
  end
end)
NS.PVPQueueTime.frame = PVPQueueTimeFrame

NS.DefaultDatabase = {
  lock = false,
  textAlignment = "CENTER",
  showBackground = false,
  backgroundColor = {
    r = 0,
    g = 0,
    b = 0,
    a = 0.6,
  },
  textSize = 32,
  font = "Friz Quadrata TT",
  textColor = {
    r = 1,
    g = 1,
    b = 1,
    a = 1,
  },
  textShadow = false,
  shadowColor = {
    r = 0,
    g = 0,
    b = 0,
    a = 0.95,
  },
  textOutline = "",
  lineSpacing = 2,
  abbreviateAverage = true,
  showSecondsWaitTime = true,
  showSecondsInQueue = true,
  showMultiple = false,
  hideInInstance = true,
  position = {
    "CENTER",
    "CENTER",
    0,
    300,
  },
}
