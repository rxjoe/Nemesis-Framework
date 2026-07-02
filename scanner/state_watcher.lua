local Players = game:GetService("Players")

local StateWatcher = {}
StateWatcher.__index = StateWatcher

StateWatcher.Config = {
    IgnoreNoise = true,
    MinimumChangeThreshold = 0.5,
    WatchLeaderstats = true,
    WatchAttributes = false,
    MaxLogs = 200,
    ScanDepth = 3
}

StateWatcher.Connections = {}
StateWatcher.Logs = {}
StateWatcher.Snapshots = {}

function StateWatcher:Init(logger)
    self.Logger = logger or {Warn = warn, Info = print}
    self.LocalPlayer = Players.LocalPlayer
    return self
end

function StateWatcher:StartMonitoring()
    self.Logger:Info("[StateWatcher] Starting Dynamic State Monitoring...")
    table.clear(self.Logs)
    self:DisconnectAll()

    if self.Config.WatchLeaderstats and self.LocalPlayer then
        self.LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(1)
            local stats = char:FindFirstChild("leaderstats")
            if stats then self:WatchValueGroup(stats, "LocalLeaderstats") end
        end)
        if self.LocalPlayer.Character then
            local stats = self.LocalPlayer.Character:FindFirstChild("leaderstats")
            if stats then self:WatchValueGroup(stats, "LocalLeaderstats") end
        end
    end

    self:ScanAndWatch(game:GetService("ReplicatedStorage"), "RS", 0)
end

function StateWatcher:ScanAndWatch(parent, path, depth)
    if depth > self.Config.ScanDepth then return end
    if not parent then return end

    for _, obj in ipairs(parent:GetChildren()) do
        local currentPath = path .. "." .. obj.Name
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") then
            self:WatchSingleValue(obj, currentPath)
        elseif obj:IsA("Folder") and not obj.Name:find("Sound") and not obj.Name:find("Anim") then
            self:ScanAndWatch(obj, currentPath, depth + 1)
        end
    end
end

function StateWatcher:WatchValueGroup(folder, groupName)
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") then
            self:WatchSingleValue(obj, groupName .. "." .. obj.Name)
        end
    end
end

function StateWatcher:WatchSingleValue(valueObj, fullPath)
    self.Snapshots[fullPath] = valueObj.Value

    local connection = valueObj.Changed:Connect(function(newValue)
        local oldValue = self.Snapshots[fullPath]

        if self.Config.IgnoreNoise and typeof(newValue) == "number" then
            if math.abs(newValue - oldValue) < self.Config.MinimumChangeThreshold then return end
        end

        local logEntry = {
            Time = os.clock(),
            Path = fullPath,
            OldValue = oldValue,
            NewValue = newValue,
            Delta = (typeof(newValue) == "number") and (newValue - oldValue) or nil
        }

        table.insert(self.Logs, 1, logEntry)
        if #self.Logs > self.Config.MaxLogs then table.remove(self.Logs) end

        local alertType = "[STATE]"
        if logEntry.Delta and logEntry.Delta > self.Config.MinimumChangeThreshold * 10 then
            alertType = "[ANOMALY!]"
            self.Logger:Warn(string.format("%s %s: %s -> %s (Delta: %+g)", alertType, fullPath, tostring(oldValue), tostring(newValue), logEntry.Delta))
        else
            self.Logger:Info(string.format("%s %s: %s -> %s", alertType, fullPath, tostring(oldValue), tostring(newValue)))
        end

        self.Snapshots[fullPath] = newValue
    end)

    table.insert(self.Connections, connection)
end

function StateWatcher:TakeSnapshot()
    self.Logger:Info("[StateWatcher] Snapshot taken.")
end

function StateWatcher:CompareWithSnapshot(snapshotTime)
    local changes = {}
    for _, log in ipairs(self.Logs) do
        if log.Time >= snapshotTime then table.insert(changes, log) end
    end
    return changes
end

function StateWatcher:DisconnectAll()
    for _, conn in ipairs(self.Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(self.Connections)
    table.clear(self.Snapshots)
    self.Logger:Info("[StateWatcher] Connections cleared.")
end

return StateWatcher