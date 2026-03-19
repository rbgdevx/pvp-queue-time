local _, NS = ...

local pairs = pairs
local type = type
local next = next
local setmetatable = setmetatable
local getmetatable = getmetatable
local SecondsToTime = SecondsToTime
local mfloor = math.floor

NS.FormatTimeInQueue = function(seconds)
  local db = NS.db
  if seconds >= 60 then
    if db and not db.showSecondsInQueue then
      return SecondsToTime(seconds, false, false, 1)
    end
    return SecondsToTime(seconds)
  else
    if db and db.showSecondsInQueue then
      local secs = mfloor(seconds % 60)
      return "0 Min " .. secs .. " Sec"
    end
    return LESS_THAN_ONE_MINUTE
  end
end

NS.FormatEstimatedWait = function(seconds)
  local db = NS.db
  if seconds >= 60 then
    if db and not db.showSecondsWaitTime then
      return SecondsToTime(seconds, false, false, 1)
    end
    return SecondsToTime(seconds)
  else
    return LESS_THAN_ONE_MINUTE
  end
end

NS.GetAvgWaitLabel = function()
  local db = NS.db
  if db and db.abbreviateAverage then
    return "Avg Wait Time: "
  end
  return "Average Wait Time: "
end

NS.GetQueueLabel = function()
  return "Time In Queue: "
end

-- Copies table values from src to dst if they don't exist in dst
NS.CopyDefaults = function(src, dst)
  if type(src) ~= "table" then
    return {}
  end

  if type(dst) ~= "table" then
    dst = {}
  end

  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = NS.CopyDefaults(v, dst[k])
    elseif type(v) ~= type(dst[k]) then
      dst[k] = v
    end
  end

  return dst
end

NS.CopyTable = function(src, dest)
  if type(src) ~= "table" then
    return src
  end

  if dest and dest[src] then
    return dest[src]
  end

  local s = dest or {}
  local res = {}
  s[src] = res

  for k, v in next, src do
    res[NS.CopyTable(k, s)] = NS.CopyTable(v, s)
  end

  return setmetatable(res, getmetatable(src))
end

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
  for key, value in pairs(src) do
    if dst[key] == nil then
      src[key] = nil
    elseif type(value) == "table" then
      dst[key] = NS.CleanupDB(value, dst[key])
    end
  end
  return dst
end
