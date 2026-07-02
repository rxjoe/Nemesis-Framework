local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Sniffer = {}
Sniffer.__index = Sniffer

Sniffer.CapturedData = {}
Sniffer.Hooks = {}
Sniffer.Enabled = false
Sniffer.OldNamecall = nil

Sniffer.ArgumentDatabase = {}
Sniffer.PatternCache = {}

local IgnoredEvents = {
    "BindableEvent", "BindableFunction",
    "Frame", "ScrollingFrame", "TextLabel", "TextButton",
    "ImageButton", "ImageLabel", "ViewportFrame"
}

function Sniffer:Start()
    if self.Enabled then return end
    self.Enabled = true
    self.CapturedData = {}
    self.OldNamecall = nil

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(...)
        local self = ...
        local method = getnamecallmethod()

        if method == "FireServer" and self:IsA("RemoteEvent") then
            local args = {select(1, ...)}
            table.remove(args, 1)
            self:Capture("FireServer", self, args)

        elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
            local args = {select(1, ...)}
            table.remove(args, 1)
            self:Capture("InvokeServer", self, args)

        elseif method == "FireAllClients" and self:IsA("RemoteEvent") then
            local args = {select(1, ...)}
            table.remove(args, 1)
            self:Capture("FireAllClients", self, args)

        elseif method == "InvokeClient" and self:IsA("RemoteFunction") then
            local args = {select(1, ...)}
            table.remove(args, 1)
            self:Capture("InvokeClient", self, args)
        end

        return oldNamecall(...)
    end)

    self.OldNamecall = oldNamecall
    self.Hooks["__namecall"] = oldNamecall

    print("[Nemesis Sniffer] Remote argument sniffer activated. Listening for remote traffic...")
end

function Sniffer:Stop()
    if not self.Enabled then return end
    self.Enabled = false

    if self.OldNamecall then
        hookmetamethod(game, "__namecall", self.OldNamecall)
        self.OldNamecall = nil
    end

    print("[Nemesis Sniffer] Sniffer deactivated.")
end

function Sniffer:Capture(method, remote, args)
    if not remote or not remote.Name then return end

    local entry = {
        Time = tick(),
        RemoteName = remote.Name,
        RemoteClass = remote.ClassName,
        RemotePath = remote:GetFullName(),
        Method = method,
        Args = args,
        ArgCount = #args,
        ArgTypes = {}
    }

    for i, arg in ipairs(args) do
        entry.ArgTypes[i] = typeof(arg)
    end

    table.insert(self.CapturedData, entry)
    self:BuildArgumentPattern(entry)

    if #self.CapturedData > 500 then
        table.remove(self.CapturedData, 1)
    end
end

function Sniffer:BuildArgumentPattern(entry)
    local db = self.ArgumentDatabase
    if not db[entry.RemoteName] then
        db[entry.RemoteName] = {
            Name = entry.RemoteName,
            Path = entry.RemotePath,
            Class = entry.RemoteClass,
            Calls = 0,
            UniquePatterns = {},
            CommonPatterns = {},
            AllArgTypes = {}
        }
    end

    local info = db[entry.RemoteName]
    info.Calls = info.Calls + 1

    local patternKey = table.concat(entry.ArgTypes, ",")
    if not info.UniquePatterns[patternKey] then
        info.UniquePatterns[patternKey] = 0
    end
    info.UniquePatterns[patternKey] = info.UniquePatterns[patternKey] + 1

    if not info.CommonPatterns[patternKey] then
        info.CommonPatterns[patternKey] = entry.Args
    end

    for i, t in ipairs(entry.ArgTypes) do
        if not info.AllArgTypes[i] then
            info.AllArgTypes[i] = {}
        end
        info.AllArgTypes[i][t] = (info.AllArgTypes[i][t] or 0) + 1
    end
end

function Sniffer:GetArgumentPattern(remoteName)
    local info = self.ArgumentDatabase[remoteName]
    if not info or info.Calls == 0 then return nil end

    local mostCommon = ""
    local mostCount = 0
    for pattern, count in pairs(info.UniquePatterns) do
        if count > mostCount then
            mostCommon = pattern
            mostCount = count
        end
    end

    local sampleArgs = info.CommonPatterns[mostCommon]
    local types = {}
    if mostCommon ~= "" then
        types = mostCommon:split(",")
    end

    return {
        RemoteName = remoteName,
        TotalCalls = info.Calls,
        MostCommonPattern = mostCommon,
        ArgTypes = types,
        SampleArgs = sampleArgs,
        Confidence = mostCount / info.Calls
    }
end

function Sniffer:GetAllPatterns()
    local results = {}
    for name, info in pairs(self.ArgumentDatabase) do
        if info.Calls > 0 then
            table.insert(results, {
                Name = name,
                Calls = info.Calls,
                Patterns = info.UniquePatterns,
                Path = info.Path,
                Class = info.Class
            })
        end
    end
    table.sort(results, function(a, b) return a.Calls > b.Calls end)
    return results
end

function Sniffer:GenerateTestPayloads(remoteName)
    local info = self.ArgumentDatabase[remoteName]
    if not info then return nil end

    local payloads = {}
    if info.Calls > 0 then
        for pattern, sampleArgs in pairs(info.CommonPatterns) do
            table.insert(payloads, {
                Type = "Replay",
                Args = sampleArgs,
                Source = "Captured"
            })
        end
    end

    local types = info.AllArgTypes
    local fuzzArgs = {}
    for i = 1, #types do
        local t = next(types[i])
        if t == "number" then
            fuzzArgs[i] = 999999999
        elseif t == "string" then
            fuzzArgs[i] = "FREE_HACK_6969"
        elseif t == "boolean" then
            fuzzArgs[i] = true
        elseif t == "table" then
            fuzzArgs[i] = {}
        else
            fuzzArgs[i] = nil
        end
    end

    table.insert(payloads, {
        Type = "BoundaryHigh",
        Args = fuzzArgs,
        Source = "Generated"
    })

    local negativeArgs = {}
    for i = 1, #types do
        local t = next(types[i])
        if t == "number" then
            negativeArgs[i] = -999999999
        elseif t == "string" then
            negativeArgs[i] = ""
        elseif t == "boolean" then
            negativeArgs[i] = false
        else
            negativeArgs[i] = nil
        end
    end

    table.insert(payloads, {
        Type = "BoundaryLow",
        Args = negativeArgs,
        Source = "Generated"
    })

    return payloads
end

function Sniffer:PrintSummary()
    if #self.CapturedData == 0 then
        print("[Nemesis Sniffer] No remote traffic captured yet.")
        return
    end

    print("\n" .. string.rep("=", 60))
    print("         ARGUMENT SNIFFER — CAPTURED DATA")
    print(string.rep("=", 60))
    print(string.format("\nTotal Calls Intercepted: %d", #self.CapturedData))
    print(string.format("Unique Remotes: %d", (function()
        local names = {} for _, e in ipairs(self.CapturedData) do names[e.RemoteName] = true end local c = 0 for _ in pairs(names) do c = c + 1 end return c end)()))

    local sorted = {}
    for name, info in pairs(self.ArgumentDatabase) do
        table.insert(sorted, {Name = name, Calls = info.Calls, Patterns = #info.UniquePatterns, Path = info.Path})
    end
    table.sort(sorted, function(a, b) return a.Calls > b.Calls end)

    print("\n  Most Active Remotes:")
    for i, entry in ipairs(sorted) do
        print(string.format("    %d. %s — %d calls, %d pattern(s)", i, entry.Name, entry.Calls, entry.Patterns))
        print(string.format("       Path: %s", entry.Path))
        if i >= 10 then break end
    end

    print("\n  Recent Captures (last 5):")
    local start = math.max(1, #self.CapturedData - 4)
    for i = start, #self.CapturedData do
        local e = self.CapturedData[i]
        print(string.format("    %s.%s(%s)", e.RemoteName, e.Method, table.concat(e.ArgTypes, ", ")))
    end

    print("\n" .. string.rep("=", 60) .. "\n")
end

return Sniffer