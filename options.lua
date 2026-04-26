local AddonName, NS = ...

local CopyTable = CopyTable
local next = next
local LibStub = LibStub

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

---@type PVPQueueTime
local PVPQueueTime = NS.PVPQueueTime
local PVPQueueTimeFrame = NS.PVPQueueTime.frame

local Interface = NS.Interface

local Options = {}
NS.Options = Options

function NS.OnDbChanged()
  Interface:ApplyConfig()
end

NS.AceConfig = {
  name = AddonName,
  type = "group",
  args = {
    lock = {
      name = "Lock the text into place",
      type = "toggle",
      width = "full",
      order = 1,
      set = function(_, val)
        NS.db.lock = val
        if val then
          Interface:Lock(NS.displayFrame)
        else
          Interface:Unlock(NS.displayFrame)
        end
      end,
      get = function(_)
        return NS.db.lock
      end,
    },
    hideInInstance = {
      name = "Hide while in an instance",
      desc = "Hides the queue display while inside any instance (dungeon, raid, battleground, arena)",
      type = "toggle",
      width = "full",
      order = 2,
      set = function(_, val)
        NS.db.hideInInstance = val
        Interface:CheckQueueStatus()
      end,
      get = function(_)
        return NS.db.hideInInstance
      end,
    },
    showMultiple = {
      name = "Show multiple queues",
      desc = "Show all active PvP queues stacked vertically instead of just the first",
      type = "toggle",
      width = "full",
      order = 3,
      set = function(_, val)
        NS.db.showMultiple = val
        Interface:CheckQueueStatus()
      end,
      get = function(_)
        return NS.db.showMultiple
      end,
    },
    abbreviateAverage = {
      name = 'Abbreviate "Average"',
      desc = 'Use "Avg" instead of "Average" in the wait time label',
      type = "toggle",
      width = "full",
      order = 4,
      set = function(_, val)
        NS.db.abbreviateAverage = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.abbreviateAverage
      end,
    },
    showSecondsWaitTime = {
      name = "Show seconds for Wait Time",
      desc = "Show seconds in the average wait time display",
      type = "toggle",
      width = "full",
      order = 5,
      set = function(_, val)
        NS.db.showSecondsWaitTime = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.showSecondsWaitTime
      end,
    },
    showSecondsInQueue = {
      name = "Show seconds for Time In Queue",
      desc = "Show seconds in the time in queue display",
      type = "toggle",
      width = "full",
      order = 6,
      set = function(_, val)
        NS.db.showSecondsInQueue = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.showSecondsInQueue
      end,
    },
    moveQueueEye = {
      name = "Move the Blizzard queue eye",
      desc = "When enabled, left-click and drag the Blizzard PvP queue eye to reposition it. The queue tooltip moves with it. Disable to restore the default placement.",
      type = "toggle",
      width = "full",
      order = 7,
      set = function(_, val)
        NS.db.moveQueueEye = val
        if not val then
          NS.db.queueEyePosition = false
        end
        Interface:SetupQueueEye()
        Interface:ApplyQueueEye()
      end,
      get = function(_)
        return NS.db.moveQueueEye
      end,
    },
    spacer1 = { name = " ", type = "description", order = 8, width = "full" },
    textAlignment = {
      name = "Text Alignment",
      type = "select",
      width = "normal",
      order = 9,
      values = {
        ["LEFT"] = "Left",
        ["CENTER"] = "Center",
        ["RIGHT"] = "Right",
      },
      set = function(_, val)
        NS.db.textAlignment = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.textAlignment
      end,
    },
    textOutline = {
      name = "Text Outline",
      type = "select",
      width = "normal",
      order = 10,
      values = {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
      },
      set = function(_, val)
        NS.db.textOutline = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.textOutline
      end,
    },
    lineSpacing = {
      type = "range",
      name = "Line Spacing",
      desc = "Spacing between the two text lines",
      width = "double",
      order = 11,
      min = 0,
      max = 20,
      step = 1,
      set = function(_, val)
        NS.db.lineSpacing = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.lineSpacing
      end,
    },
    spacer2 = { name = " ", type = "description", order = 12, width = "full" },
    textSize = {
      type = "range",
      name = "Font Size",
      width = "double",
      order = 13,
      min = 8,
      max = 64,
      step = 1,
      set = function(_, val)
        NS.db.textSize = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.textSize
      end,
    },
    spacer3 = { name = " ", type = "description", order = 14, width = "full" },
    font = {
      type = "select",
      name = "Font",
      width = 1.5,
      dialogControl = "LSM30_Font",
      values = SharedMedia:HashTable("font"),
      order = 15,
      set = function(_, val)
        NS.db.font = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.font
      end,
    },
    spacer4 = { name = "", type = "description", order = 16, width = 0.1 },
    textColor = {
      type = "color",
      name = "Text Color",
      width = 0.5,
      order = 17,
      hasAlpha = true,
      set = function(_, r, g, b, a)
        NS.db.textColor.r = r
        NS.db.textColor.g = g
        NS.db.textColor.b = b
        NS.db.textColor.a = a
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.textColor.r, NS.db.textColor.g, NS.db.textColor.b, NS.db.textColor.a
      end,
    },
    spacer5 = { name = " ", type = "description", order = 18, width = "full" },
    textShadow = {
      name = "Enable text shadow",
      type = "toggle",
      width = "full",
      order = 19,
      set = function(_, val)
        NS.db.textShadow = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.textShadow
      end,
    },
    shadowColor = {
      type = "color",
      name = "Shadow Color",
      width = 0.5,
      order = 20,
      hasAlpha = true,
      disabled = function()
        return not NS.db.textShadow
      end,
      set = function(_, r, g, b, a)
        NS.db.shadowColor.r = r
        NS.db.shadowColor.g = g
        NS.db.shadowColor.b = b
        NS.db.shadowColor.a = a
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.shadowColor.r, NS.db.shadowColor.g, NS.db.shadowColor.b, NS.db.shadowColor.a
      end,
    },
    spacer6 = { name = " ", type = "description", order = 21, width = "full" },
    showBackground = {
      name = "Show background",
      type = "toggle",
      width = "full",
      order = 22,
      set = function(_, val)
        NS.db.showBackground = val
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.showBackground
      end,
    },
    backgroundColor = {
      type = "color",
      name = "Background Color",
      width = 0.5,
      order = 23,
      hasAlpha = true,
      disabled = function()
        return not NS.db.showBackground
      end,
      set = function(_, r, g, b, a)
        NS.db.backgroundColor.r = r
        NS.db.backgroundColor.g = g
        NS.db.backgroundColor.b = b
        NS.db.backgroundColor.a = a
        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.backgroundColor.r, NS.db.backgroundColor.g, NS.db.backgroundColor.b, NS.db.backgroundColor.a
      end,
    },
    spacer7 = { name = " ", type = "description", order = 99, width = "full" },
    reset = {
      name = "Reset Everything",
      type = "execute",
      width = "normal",
      order = 100,
      func = function()
        PVPQueueTimeDB = CopyTable(NS.DefaultDatabase)
        NS.db = PVPQueueTimeDB
        NS.OnDbChanged()
      end,
    },
  },
}

function Options:SlashCommands(_)
  AceConfigDialog:Open(AddonName)
end

function Options:Setup()
  AceConfig:RegisterOptionsTable(AddonName, NS.AceConfig)
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName)

  SLASH_PQT1 = "/pvpqueuetime"
  SLASH_PQT2 = "/pvpqt"
  SLASH_PQT3 = "/pqt"

  function SlashCmdList.PQT(message)
    self:SlashCommands(message)
  end
end

function PVPQueueTime:ADDON_LOADED(addon)
  if addon == AddonName then
    PVPQueueTimeFrame:UnregisterEvent("ADDON_LOADED")

    PVPQueueTimeDB = PVPQueueTimeDB and next(PVPQueueTimeDB) ~= nil and PVPQueueTimeDB or {}

    NS.CopyDefaults(NS.DefaultDatabase, PVPQueueTimeDB)

    NS.db = PVPQueueTimeDB

    NS.CleanupDB(PVPQueueTimeDB, NS.DefaultDatabase)

    Options:Setup()
  end
end
PVPQueueTimeFrame:RegisterEvent("ADDON_LOADED")
