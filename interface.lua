local AddonName, NS = ...

local GetBattlefieldStatus = GetBattlefieldStatus
local GetBattlefieldEstimatedWaitTime = GetBattlefieldEstimatedWaitTime
local GetBattlefieldTimeWaited = GetBattlefieldTimeWaited
local GetMaxBattlefieldID = GetMaxBattlefieldID
local IsInInstance = IsInInstance
local math_floor = math.floor
local LibStub = LibStub

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

local Interface = {}
NS.Interface = Interface

local UPDATE_INTERVAL = 1.0
local DEFAULT_LINE_SPACING = 2
local ENTRY_SPACING = 12
local PADDING_X = 16
local PADDING_Y = 12

local ALIGN_POINTS = {
  LEFT = { top = "TOPLEFT", x = 8 },
  CENTER = { top = "TOP", x = 0 },
  RIGHT = { top = "TOPRIGHT", x = -8 },
}

local function FormatQueueTime(ms)
  local totalSec = math_floor(ms / 1000)
  if totalSec < 0 then
    totalSec = 0
  end
  local mins = math_floor(totalSec / 60)
  local secs = totalSec % 60
  return mins .. " min " .. string.format("%02d", secs) .. " sec"
end

NS.UpdateFont = function(fontString)
  local db = NS.db
  if not db then
    return
  end
  local fontPath = SharedMedia:Fetch("font", db.font)
  fontString:SetFont(fontPath, db.textSize, db.textOutline)
end

-------------------------------------------------
-- Display frame
-------------------------------------------------
local frame = CreateFrame("Frame", "PVPQueueTimeDisplayFrame", UIParent)
frame:SetSize(270, 74)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:Hide()
NS.displayFrame = frame

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:Hide()

-------------------------------------------------
-- Lock / Unlock
-------------------------------------------------
function Interface:MakeUnmovable(f)
  f:SetMovable(false)
  f:RegisterForDrag()
  f:SetScript("OnDragStart", nil)
  f:SetScript("OnDragStop", nil)
end

function Interface:MakeMoveable(f)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if NS.db.lock == false then
      self:StartMoving()
    end
  end)
  f:SetScript("OnDragStop", function(self)
    if NS.db.lock == false then
      self:StopMovingOrSizing()
      local a, _, b, c, d = self:GetPoint()
      NS.db.position[1] = a
      NS.db.position[2] = b
      NS.db.position[3] = c
      NS.db.position[4] = d
    end
  end)
end

function Interface:RemoveControls(f)
  f:EnableMouse(false)
  f:SetScript("OnMouseUp", nil)
end

function Interface:AddControls(f)
  f:EnableMouse(true)
  f:SetScript("OnMouseUp", function(_, btn)
    if NS.db.lock == false and btn == "RightButton" then
      AceConfigDialog:Open(AddonName)
    end
  end)
end

function Interface:Lock(f)
  self:RemoveControls(f)
  self:MakeUnmovable(f)
end

function Interface:Unlock(f)
  self:AddControls(f)
  self:MakeMoveable(f)
end

-------------------------------------------------
-- Queue entry pool
-------------------------------------------------
local queueEntries = {}
local activeSlots = {}

local function GetOrCreateEntry(index)
  if queueEntries[index] then
    return queueEntries[index]
  end

  local avgText = frame:CreateFontString(nil, "OVERLAY")
  local queueText = frame:CreateFontString(nil, "OVERLAY")

  queueEntries[index] = { avgText = avgText, queueText = queueText }
  return queueEntries[index]
end

-------------------------------------------------
-- Apply config
-------------------------------------------------
local function ApplyConfigToEntry(entry, prevEntry)
  local db = NS.db
  if not db then
    return
  end
  local align = ALIGN_POINTS[db.textAlignment] or ALIGN_POINTS["CENTER"]

  -- Font
  NS.UpdateFont(entry.avgText)
  NS.UpdateFont(entry.queueText)

  -- Text color
  entry.avgText:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a)
  entry.queueText:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a)

  -- Text shadow
  if db.textShadow then
    entry.avgText:SetShadowColor(db.shadowColor.r, db.shadowColor.g, db.shadowColor.b, db.shadowColor.a)
    entry.avgText:SetShadowOffset(1, -1)
    entry.queueText:SetShadowColor(db.shadowColor.r, db.shadowColor.g, db.shadowColor.b, db.shadowColor.a)
    entry.queueText:SetShadowOffset(1, -1)
  else
    entry.avgText:SetShadowOffset(0, 0)
    entry.queueText:SetShadowOffset(0, 0)
  end

  -- Alignment
  entry.avgText:ClearAllPoints()
  entry.queueText:ClearAllPoints()

  if prevEntry then
    entry.avgText:SetPoint("TOP", prevEntry.queueText, "BOTTOM", 0, -ENTRY_SPACING)
  else
    entry.avgText:SetPoint(align.top, frame, align.top, align.x, -6)
  end

  entry.avgText:SetJustifyH(db.textAlignment)
  local lineSpacing = db.lineSpacing or DEFAULT_LINE_SPACING
  entry.queueText:SetPoint("TOP", entry.avgText, "BOTTOM", 0, -lineSpacing)
  entry.queueText:SetJustifyH(db.textAlignment)
end

function Interface:ApplyConfig()
  local db = NS.db
  if not db then
    return
  end

  -- Background
  if db.showBackground then
    local a = db.backgroundColor.a
    if a <= 0 then
      a = 0.6
    end
    bg:SetColorTexture(db.backgroundColor.r, db.backgroundColor.g, db.backgroundColor.b, a)
    bg:Show()
  else
    bg:Hide()
  end

  -- Lock state
  if db.lock then
    self:Lock(frame)
  else
    self:Unlock(frame)
  end

  -- Apply to all existing entries
  local prev = nil
  for i = 1, #queueEntries do
    ApplyConfigToEntry(queueEntries[i], prev)
    prev = queueEntries[i]
  end
end

-------------------------------------------------
-- Resize frame to fit text content
-------------------------------------------------
local function ResizeFrame(count)
  if count <= 0 then
    return
  end
  local db = NS.db
  if not db then
    return
  end

  -- Height
  local lineHeight = db.textSize + 2
  local lineSpacing = db.lineSpacing or DEFAULT_LINE_SPACING
  local entryHeight = (lineHeight * 2) + lineSpacing
  local totalHeight = (entryHeight * count) + (ENTRY_SPACING * (count - 1)) + PADDING_Y

  -- Width: find the widest text string across all visible entries
  local maxWidth = 0
  for i = 1, count do
    local entry = queueEntries[i]
    if entry then
      local w1 = entry.avgText:GetStringWidth() or 0
      local w2 = entry.queueText:GetStringWidth() or 0
      if w1 > maxWidth then
        maxWidth = w1
      end
      if w2 > maxWidth then
        maxWidth = w2
      end
    end
  end

  frame:SetSize(maxWidth + PADDING_X, totalHeight)
end

-------------------------------------------------
-- Queue status
-------------------------------------------------
function Interface:CheckQueueStatus()
  local db = NS.db
  if not db then
    return
  end

  wipe(activeSlots)

  -- Hide while inside any instance
  if db and db.hideInInstance and IsInInstance() then
    frame:Hide()
    return
  end

  for i = 1, GetMaxBattlefieldID() do
    local status = GetBattlefieldStatus(i)
    if status == "queued" then
      activeSlots[#activeSlots + 1] = i
      if not db or not db.showMultiple then
        break
      end
    end
  end

  if #activeSlots > 0 then
    local prev = nil
    for idx = 1, #activeSlots do
      local entry = GetOrCreateEntry(idx)
      ApplyConfigToEntry(entry, prev)
      entry.avgText:SetText("Avg Wait time: --")
      entry.queueText:SetText("Time In Queue: --")
      entry.avgText:Show()
      entry.queueText:Show()
      prev = entry
    end

    for idx = #activeSlots + 1, #queueEntries do
      queueEntries[idx].avgText:Hide()
      queueEntries[idx].queueText:Hide()
    end

    ResizeFrame(#activeSlots)
    self:ApplyConfig()
    frame:Show()
  else
    frame:Hide()
  end
end

function Interface:RestorePosition()
  if NS.db and NS.db.position then
    local pos = NS.db.position
    frame:ClearAllPoints()
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
  end
end

-------------------------------------------------
-- OnUpdate
-------------------------------------------------
local elapsed_accumulator = 0
frame:SetScript("OnUpdate", function(self, elapsed)
  elapsed_accumulator = elapsed_accumulator + elapsed
  if elapsed_accumulator < UPDATE_INTERVAL then
    return
  end
  elapsed_accumulator = 0

  for idx, slot in ipairs(activeSlots) do
    local entry = queueEntries[idx]
    if entry then
      local estWaitMs = GetBattlefieldEstimatedWaitTime(slot)
      local timeWaitedMs = GetBattlefieldTimeWaited(slot)
      entry.avgText:SetText("Avg Wait time: " .. FormatQueueTime(estWaitMs))
      entry.queueText:SetText("Time In Queue: " .. FormatQueueTime(timeWaitedMs))
    end
  end

  ResizeFrame(#activeSlots)
end)
