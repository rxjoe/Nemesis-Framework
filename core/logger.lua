local Logger = {}
Logger.__index = Logger

Logger.LogHistory = {}
Logger.MaxHistory = 500
Logger.Levels = {DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3}
Logger.CurrentLevel = 1
Logger.Timestamps = true

function Logger:Init()
    self.Prefix = "[NEMESIS]"
end

function Logger:_log(level, msg)
    if self.Levels[level] < self.CurrentLevel then return end
    local timestamp = self.Timestamps and ("[" .. os.date("%H:%M:%S") .. "]") or ""
    local output = string.format("%s %s [%s] %s", timestamp, self.Prefix, level, msg)
    print(output)

    table.insert(self.LogHistory, 1, {Level = level, Message = msg, Time = tick()})
    if #self.LogHistory > self.MaxHistory then table.remove(self.LogHistory) end
end

function Logger:Info(msg) self:_log("INFO", msg) end
function Logger:Warn(msg) self:_log("WARN", msg); warn(self.Prefix, "[WARN]", msg) end
function Logger:Error(msg) self:_log("ERROR", msg); error(self.Prefix .. " [ERROR] " .. msg) end
function Logger:Debug(msg) self:_log("DEBUG", msg) end

function Logger:SetLevel(level)
    if self.Levels[level] ~= nil then
        self.CurrentLevel = self.Levels[level]
    end
end

function Logger:GetHistory(count)
    count = count or 10
    local result = {}
    for i = 1, math.min(count, #self.LogHistory) do
        table.insert(result, self.LogHistory[i])
    end
    return result
end

return Logger