local HttpService = game:GetService("HttpService")

local MemScanner = {}
MemScanner.__index = MemScanner

MemScanner.HiddenInstances = {}
MemScanner.ProtectedModules = {}
MemScanner.ScriptContents = {}
MemScanner.SuspiciousPatterns = {}

local DangerousKeywords = {
    "loadstring", "loadfile", "dofile", "spawn", "delay",
    "tempted", "synapse", "krnl", "exploit", "inject",
    "bypass", "cheat", "hack", "crack", "dump",
    "encrypt", "decrypt", "obfuscate", "bytecode",
    "getgenv", "getrenv", "getreg", "getgc",
    "HookFunction", "hookmetamethod", "clonefunction",
    "getconnections", "getnilinstances", "getscriptbytecode",
    "firetouchinterest", "fireclickdetector"
}

local function formatPath(obj)
    local path = obj:GetFullName()
    return path
end

function MemScanner:Scan()
    self.HiddenInstances = {}
    self.ProtectedModules = {}
    self.ScriptContents = {}
    self.SuspiciousPatterns = {}

    if not getnilinstances then
        warn("[Nemesis MemoryScanner] getnilinstances() not available. Hidden scan disabled.")
        return
    end

    print("[Nemesis MemoryScanner] Scanning for hidden/modified instances...")

    for _, obj in ipairs(getnilinstances()) do
        local entry = {
            Name = obj.Name,
            Class = obj.ClassName,
            Path = formatPath(obj),
            Parent = obj.Parent and obj.Parent.Name or "None",
            IsArchivable = obj.Archivable
        }

        if obj:IsA("ModuleScript") then
            local source = ""
            local protected = false
            local ok, bytecode = pcall(function() return getscriptbytecode(obj) end)
            if not ok or not bytecode then
                ok, source = pcall(function() return obj.Source end)
                if not ok or source == "" then
                    protected = true
                    ok, source = pcall(function() return getscriptsource(obj) end)
                    if not ok then source = "[PROTECTED — Cannot read]" end
                end
            else
                source = "[BYTECODE — " .. #tostring(bytecode) .. " bytes]"
                ok, source = pcall(function() return obj.Source end)
                if not ok then source = "[BYTECODE ONLY]" end
            end

            entry.Source = source
            entry.Protected = protected

            if protected then
                table.insert(self.ProtectedModules, entry)
            end

            if not protected and source then
                for _, kw in ipairs(DangerousKeywords) do
                    if source:lower():find(kw) then
                        table.insert(self.SuspiciousPatterns, {
                            Module = obj.Name,
                            Found = kw
                        })
                    end
                end
            end

            local ClientRemoteRefs = {}
            local ServerRemoteRefs = {}
            if source then
                for line in source:gmatch("[^\r\n]+") do
                    local lowerLine = line:lower()
                    if lowerLine:find("remotevent") or lowerLine:find("remotefunction") then
                        table.insert(ClientRemoteRefs, line)
                    end
                    if lowerLine:find("fireserver") or lowerLine:find("invokeserver") then
                        table.insert(ClientRemoteRefs, line)
                    end
                    if lowerLine:find("fireclient") or lowerLine:find("invokeclient") then
                        table.insert(ServerRemoteRefs, line)
                    end
                end
            end
            entry.ClientRemoteRefs = ClientRemoteRefs
            entry.ServerRemoteRefs = ServerRemoteRefs

        elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local ok, conns = pcall(function() return getconnections(obj) end)
            if ok and conns then
                entry.Connections = #conns
            else
                entry.Connections = -1
            end
        end

        table.insert(self.HiddenInstances, entry)
    end

    print(string.format("  Hidden instances: %d", #self.HiddenInstances))
    print(string.format("  Protected modules: %d", #self.ProtectedModules))
    print(string.format("  Suspicious patterns: %d", #self.SuspiciousPatterns))
end

function MemScanner:ScanServices()
    local scanServices = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage"),
        game:GetService("StarterPlayer")
    }

    for _, service in ipairs(scanServices) do
        for _, obj in ipairs(service:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local ok, src = pcall(function() return obj.Source end)
                if ok and src then
                    local refs = {}
                    for line in src:gmatch("[^\r\n]+") do
                        if line:lower():find("remotevent") or line:lower():find("remotefunction") then
                            table.insert(refs, line)
                        end
                    end
                    if #refs > 0 then
                        table.insert(self.ScriptContents, {
                            Name = obj.Name,
                            Path = formatPath(obj),
                            RemoteRefs = refs
                        })
                    end
                end
            end
        end
    end

    print(string.format("  Scripts with remote refs: %d", #self.ScriptContents))
end

function MemScanner:PrintReport()
    if #self.HiddenInstances == 0 and #self.ProtectedModules == 0 then
        print("[Nemesis MemoryScanner] Run Scan() first.")
        return
    end

    print("\n" .. string.rep("=", 60))
    print("           MEMORY SCANNER — HIDDEN INSTANCES")
    print(string.rep("=", 60))

    if #self.ProtectedModules > 0 then
        print("\n  PROTECTED MODULES (High Interest):")
        for _, mod in ipairs(self.ProtectedModules) do
            print(string.format("    ! %s (%s)", mod.Name, mod.Class))
            print(string.format("      Path: %s", mod.Path))
        end
    end

    if #self.SuspiciousPatterns > 0 then
        print("\n  SUSPICIOUS KEYWORDS FOUND:")
        for _, pat in ipairs(self.SuspiciousPatterns) do
            print(string.format("    ! %s -> '%s'", pat.Module, pat.Found))
        end
    end

    if #self.ScriptContents > 0 then
        print("\n  SCRIPTS REFERENCING REMOTES:")
        for _, sc in ipairs(self.ScriptContents) do
            print(string.format("    %s (%s)", sc.Name, sc.Path))
            for _, ref in ipairs(sc.RemoteRefs) do
                print(string.format("      -> %s", ref:sub(1, 80)))
            end
        end
    end

    local hiddenRemotes = {}
    for _, inst in ipairs(self.HiddenInstances) do
        if inst.Class == "RemoteEvent" or inst.Class == "RemoteFunction" then
            table.insert(hiddenRemotes, inst)
        end
    end

    if #hiddenRemotes > 0 then
        print("\n  HIDDEN REMOTES IN MEMORY:")
        for _, r in ipairs(hiddenRemotes) do
            print(string.format("    %s (%s) — Connections: %s", r.Name, r.Class, tostring(r.Connections)))
            print(string.format("      Path: %s", r.Path))
        end
    end

    print("\n" .. string.rep("=", 60) .. "\n")
end

return MemScanner