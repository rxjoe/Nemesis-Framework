local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Profiler = {}
Profiler.__index = Profiler

Profiler.Findings = {
    PrivilegeEscalation = {},
    BusinessLogic = {},
    DataExposure = {},
    UnusualBehaviors = {},
    AntiExploit = {},
    HiddenRemotes = {},
    ModuleScripts = {},
    ScriptReferences = {}
}

Profiler.AllRemotes = {}
Profiler.ScanTargets = {
    ReplicatedStorage, ServerStorage, ServerScriptService, Players,
    game:GetService("StarterGui"), game:GetService("StarterPack"),
    game:GetService("StarterPlayer")
}

local Keywords = {
    Admin = {"command", "execute", "mod", "admin", "kick", "ban", "teleport", "punish", "god", "kill", "slay", "respawn", "goto", "bring", "freeze", "unfreeze", "remotely", "control", "manage", "owner", "shutdown"},
    Economy = {"purchase", "buy", "sell", "trade", "currency", "ammo", "cost", "price", "rebirth", "shop", "upgrade", "craft", "salvage", "recycle", "convert", "exchange", "donate", "pay", "withdraw", "deposit", "bid", "auction"},
    Data = {"getplayer", "getdata", "getstats", "getlevel", "getinventory", "getowned", "getequipped", "loaddata", "fetch", "request", "getcharacter", "getinfo", "lookup", "query", "retrieve", "getall"},
    AntiCheat = {"detect", "flag", "ban", "kick", "log", "report", "check", "validate", "verify", "authentication", "antitamper", "antihack", "integrity", "hash", "checksum", "signature", "token"},
    Map = {"door", "gate", "button", "switch", "lever", "elevator", "platform", "bridge", "trap", "spike", "lava", "killbrick", "teleport", "spawn", "checkpoint", "finish", "win", "complete", "objective", "mission", "interact", "trigger", "zone", "region", "volume"},
    Character = {"humanoid", "health", "damage", "takeDamage", "applyDamage", "dealDamage", "hurt", "heal", "revive", "respawnCharacter", "setHealth", "setWalkSpeed", "setJumpPower", "stun", "root", "ragdoll", "transform"}
}

local VulnerabilityPatterns = {
    Privilege = {"admin", "ban", "kick", "teleport", "command", "execute", "mod", "owner", "control"},
    Economy = {"buy", "sell", "purchase", "trade", "upgrade", "craft", "convert", "exchange"},
    IDOR = {"getplayer", "getdata", "getstats", "getinfo", "lookup", "fetch"},
    RateLimit = {"attack", "click", "swing", "shoot", "fire", "use", "interact"},
    AntiCheat = {"detect", "validate", "verify", "check"}
}

local function getRemotePath(obj)
    local path = obj:GetFullName()
    return path
end

local function isSuspiciousName(name)
    local special = {"_", "-", " ", "*", "$", "#", "@", "!"}
    for _, c in ipairs(special) do
        if name:find(c) then return true end
    end
    return false
end

local function hasObfuscatedName(name)
    if #name <= 2 then return true end
    local alphaCount = 0
    for i = 1, #name do
        local byte = string.byte(name, i)
        if (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) then
            alphaCount = alphaCount + 1
        end
    end
    local ratio = alphaCount / #name
    return ratio < 0.5
end

function Profiler:ScanService(service, depth)
    if depth > 4 then return end
    if not service then return end

    for _, obj in ipairs(service:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local entry = {
                Name = obj.Name,
                Class = obj.ClassName,
                Path = getRemotePath(obj),
                Parent = obj.Parent and obj.Parent.Name or "Unknown",
                Service = service.Name,
                SuspiciousName = isSuspiciousName(obj.Name),
                Obfuscated = hasObfuscatedName(obj.Name),
                Connections = 0
            }

            local ok, conns = pcall(function() return getconnections(obj) end)
            if ok and conns then
                entry.Connections = #conns
                for _, conn in ipairs(conns) do
                    if conn.Function then
                        local info = pcall(function() return debug.getinfo(conn.Function) end)
                        if info and type(info) == "table" then
                            entry.HandlerSource = info.short_src or "Unknown"
                        end
                    end
                end
            end

            table.insert(self.AllRemotes, entry)
            self:ClassifyRemote(obj, entry)
        end

        if obj:IsA("ModuleScript") then
            local ok, src = pcall(function() return getscriptbytecode(obj) end)
            if not ok then
                ok, src = pcall(function() return obj.Source end)
            end
            if ok and src then
                local analysis = self:AnalyzeScriptSource(obj.Name, src)
                if analysis then
                    table.insert(self.Findings.ScriptReferences, analysis)
                end
            end
            table.insert(self.Findings.ModuleScripts, {
                Name = obj.Name,
                Path = getRemotePath(obj),
                Service = service.Name,
                Protected = not ok
            })
        end
    end
end

function Profiler:AnalyzeScriptSource(name, source)
    local findings = {}
    for _, kw in ipairs(Keywords.Admin) do
        if source:lower():find(kw) then
            table.insert(findings, "AdminKeyword: " .. kw)
        end
    end
    for _, kw in ipairs(Keywords.Economy) do
        if source:lower():find(kw) then
            table.insert(findings, "EconomyKeyword: " .. kw)
        end
    end
    if #findings > 0 then
        return {Name = name, Keywords = findings}
    end
    return nil
end

function Profiler:ClassifyRemote(obj, entry)
    local nameLower = obj.Name:lower()
    local path = entry.Path

    for _, kw in ipairs(Keywords.Admin) do
        if nameLower:find(kw) then
            table.insert(self.Findings.PrivilegeEscalation, {
                Remote = obj.Name, Type = obj.ClassName,
                Path = path, Severity = "HIGH",
                Connections = entry.Connections,
                Reason = "Name suggests admin/control functionality. Server must verify rank."
            })
            break
        end
    end

    if obj:IsA("RemoteFunction") then
        for _, kw in ipairs(Keywords.Economy) do
            if nameLower:find(kw) then
                table.insert(self.Findings.BusinessLogic, {
                    Remote = obj.Name, Type = obj.ClassName,
                    Path = path, Severity = "CRITICAL",
                    Connections = entry.Connections,
                    Reason = "Economic RemoteFunction → Race condition risk. Check if server validates balance on each call."
                })
                break
            end
        end
    elseif obj:IsA("RemoteEvent") then
        for _, kw in ipairs(Keywords.Economy) do
            if nameLower:find(kw) then
                table.insert(self.Findings.BusinessLogic, {
                    Remote = obj.Name, Type = obj.ClassName,
                    Path = path, Severity = "MEDIUM",
                    Connections = entry.Connections,
                    Reason = "Economic event. Server MUST validate funds BEFORE processing."
                })
                break
            end
        end
    end

    if obj:IsA("RemoteFunction") then
        for _, kw in ipairs(Keywords.Data) do
            if nameLower:find(kw) then
                table.insert(self.Findings.DataExposure, {
                    Remote = obj.Name, Type = obj.ClassName,
                    Path = path, Severity = "HIGH",
                    Connections = entry.Connections,
                    Reason = "Data retrieval function → IDOR risk. Test with another player's UserID."
                })
                break
            end
        end
    end

    for _, kw in ipairs(Keywords.AntiCheat) do
        if nameLower:find(kw) then
            table.insert(self.Findings.AntiExploit, {
                Remote = obj.Name, Type = obj.ClassName,
                Path = path, Severity = "INFO",
                Connections = entry.Connections,
                Reason = "Anti-cheat related remote. Monitor carefully to avoid detection."
            })
            break
        end
    end

    for _, kw in ipairs(Keywords.Map) do
        if nameLower:find(kw) then
            table.insert(self.Findings.UnusualBehaviors, {
                Remote = obj.Name, Type = obj.ClassName,
                Path = path, Severity = "MEDIUM",
                Connections = entry.Connections,
                Reason = "Map interaction remote → test for logic flaws, rate limits, and bypasses."
            })
            break
        end
    end

    if entry.Obfuscated or entry.SuspiciousName then
        table.insert(self.Findings.HiddenRemotes, {
            Remote = obj.Name, Type = obj.ClassName,
            Path = path, Severity = "HIGH",
            Connections = entry.Connections,
            Reason = "Obfuscated/suspicious name → intentionally hidden. High priority target."
        })
    end
end

function Profiler:ScanLocalScripts()
    local player = Players.LocalPlayer
    if not player then return end
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local entry = {
                Name = obj.Name, Class = obj.ClassName,
                Path = getRemotePath(obj), Parent = obj.Parent and obj.Parent.Name or "Unknown",
                Service = "PlayerGui", SuspiciousName = isSuspiciousName(obj.Name),
                Obfuscated = hasObfuscatedName(obj.Name), Connections = 0
            }
            local ok, conns = pcall(function() return getconnections(obj) end)
            if ok and conns then
                entry.Connections = #conns
            end
            table.insert(self.AllRemotes, entry)
            self:ClassifyRemote(obj, entry)
        end
    end
end

function Profiler:Analyze()
    self.AllRemotes = {}
    for _, category in pairs(self.Findings) do
        if type(category) == "table" then table.clear(category) end
    end

    print("[Nemesis Profiler] Deep Remote Analysis — Scanning all services...")

    for _, service in ipairs(self.ScanTargets) do
        local ok = pcall(function() self:ScanService(service, 0) end)
        if ok then
            print("  Scanned: " .. service.Name)
        end
    end

    self:ScanLocalScripts()

    print(string.format("\n  Total Remotes Found: %d", #self.AllRemotes))
    print(string.format("  ModuleScripts Found: %d", #self.Findings.ModuleScripts))
    print(string.format("  Script References: %d", #self.Findings.ScriptReferences))

    if #self.Findings.HiddenRemotes > 0 then
        print(string.format("  HIDDEN/OBFUSCATED REMOTES: %d (!)", #self.Findings.HiddenRemotes))
    end
end

function Profiler:PrintReport()
    if #self.AllRemotes == 0 then
        print("[Nemesis Profiler] No remotes found. Run Analyze() first.")
        return
    end

    print("\n" .. string.rep("=", 60))
    print("            NEMESIS VULNERABILITY REPORT")
    print(string.rep("=", 60))

    print(string.format("\nTOTAL REMOTES FOUND: %d", #self.AllRemotes))
    print(string.format("  RemoteEvents:  %d", (function()
        local c = 0 for _, r in ipairs(self.AllRemotes) do if r.Class == "RemoteEvent" then c = c + 1 end end return c end)()))
    print(string.format("  RemoteFunctions: %d", (function()
        local c = 0 for _, r in ipairs(self.AllRemotes) do if r.Class == "RemoteFunction" then c = c + 1 end end return c end)()))

    local function PrintCategory(title, findings)
        print("\n  [" .. title .. "] — " .. #findings .. " found")
        if #findings == 0 then
            print("    No potential vulnerabilities detected.")
            return
        end
        for i, f in ipairs(findings) do
            local icon = f.Severity == "CRITICAL" and "!!" or f.Severity == "HIGH" and "!" or f.Severity == "MEDIUM" and "-" or "i"
            print(string.format("    %s [%s] %s (%s)", icon, f.Severity, f.Remote, f.Type))
            print(string.format("       Path: %s", f.Path))
            if f.Connections then
                print(string.format("       Handler Connections: %d", f.Connections))
            end
            print(string.format("       -> %s", f.Reason))
        end
    end

    PrintCategory("PRIVILEGE ESCALATION", self.Findings.PrivilegeEscalation)
    PrintCategory("BUSINESS LOGIC FLAWS", self.Findings.BusinessLogic)
    PrintCategory("DATA EXPOSURE / IDOR", self.Findings.DataExposure)
    PrintCategory("ANTI-EXPLOIT DETECTION", self.Findings.AntiExploit)
    PrintCategory("MAP INTERACTION REMOTES", self.Findings.UnusualBehaviors)
    PrintCategory("HIDDEN / OBFUSCATED REMOTES", self.Findings.HiddenRemotes)

    print("\n  --- ALL REMOTE DUMP ---")
    for i, r in ipairs(self.AllRemotes) do
        local flag = ""
        if r.Obfuscated then flag = flag .. " [OBFUSCATED]" end
        if r.SuspiciousName then flag = flag .. " [SUSPICIOUS]" end
        print(string.format("    %d. %s (%s)%s", i, r.Name, r.Class, flag))
        print(string.format("       Parent: %s | Service: %s", r.Parent, r.Service))
    end

    print("\n" .. string.rep("=", 60) .. "\n")
end

function Profiler:ExportReport()
    local data = {
        Timestamp = os.time(),
        TotalRemotes = #self.AllRemotes,
        AllRemotes = self.AllRemotes,
        Findings = self.Findings
    }
    return HttpService:JSONEncode(data)
end

function Profiler:GetRemoteByPath(fullName)
    for _, r in ipairs(self.AllRemotes) do
        if r.Path == fullName then return r end
    end
    return nil
end

function Profiler:GetRemoteByName(name)
    local results = {}
    for _, r in ipairs(self.AllRemotes) do
        if r.Name:lower():find(name:lower()) then
            table.insert(results, r)
        end
    end
    return results
end

return Profiler