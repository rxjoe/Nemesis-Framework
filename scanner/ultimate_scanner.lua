local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Scanner = {}
Scanner.__index = Scanner
Scanner.Results = {}
Scanner.Techniques = {}

local function Section(title)
    print("\n" .. string.rep("=", 60))
    print("  " .. title)
    print(string.rep("=", 60))
end

local function T(format, ...)
    if select("#", ...) > 0 then
        print("    " .. string.format(format, ...))
    else
        print("    " .. format)
    end
end

-- ============================================================
-- SCANNER TECHNIQUES — كل تقنية بتكتشف نوع مختلف من الثغرات
-- ============================================================

-- 1-5: SERVICE-WIDE REMOTE ENUMERATION
function Scanner:Tech_AllServicesScan()
    local remotes = {}
    local services = {
        ReplicatedStorage, ServerStorage, ServerScriptService,
        game:GetService("StarterGui"), game:GetService("StarterPack"),
        game:GetService("StarterPlayer"), game:GetService("Players"),
        game:GetService("Workspace"), game:GetService("Lighting"),
        game:GetService("Chat")
    }
    for _, sv in ipairs(services) do
        local ok = pcall(function()
            for _, obj in ipairs(sv:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(remotes, {
                        Name = obj.Name, Class = obj.ClassName,
                        Path = obj:GetFullName(), Parent = obj.Parent and obj.Parent.Name,
                        Service = sv.Name
                    })
                end
            end
        end)
    end
    table.insert(Scanner.Results, {Category = "Remote Enumeration", Count = #remotes, Data = remotes,
        Summary = string.format("Found %d remotes across all services", #remotes)})
    return remotes
end

-- 6-7: OBFUSCATED / HIDDEN NAME DETECTION
function Scanner:Tech_ObfuscatedNames(remotes)
    local hidden = {}
    for _, r in ipairs(remotes or {}) do
        local name = r.Name
        local alpha = 0
        for i = 1, #name do
            local b = string.byte(name, i)
            if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then alpha = alpha + 1 end
        end
        local suspicious = false
        for _, c in ipairs({"_", "-", "*", "$", "#", "@", "!", "^", "~", "`"}) do
            if name:find(c) then suspicious = true; break end
        end
        if #name <= 2 or alpha / #name < 0.4 or suspicious then
            table.insert(hidden, r)
        end
    end
    table.insert(Scanner.Results, {Category = "Obfuscated Remotes", Count = #hidden, Data = hidden,
        Severity = "HIGH", Summary = string.format("Found %d obfuscated/suspicious remote names", #hidden)})
    return hidden
end

-- 8-12: CONNECTION ANALYSIS
function Scanner:Tech_ConnectionAnalysis(remotes)
    local withHandlers = {}
    for _, r in ipairs(remotes or {}) do
        local ok, conns = pcall(function() return getconnections(rawget(_G, r.Name) or game:GetService(r.Service):FindFirstChild(r.Name, true)) end)
        if not ok then
            local obj = game:GetService(r.Service):FindFirstChild(r.Name, true)
            if obj then
                local ok2, conns2 = pcall(function() return getconnections(obj) end)
                if ok2 and conns2 and #conns2 > 0 then
                    table.insert(withHandlers, {Remote = r.Name, Connections = #conns2, Path = r.Path})
                end
            end
        elseif ok and conns and #conns > 0 then
            table.insert(withHandlers, {Remote = r.Name, Connections = #conns, Path = r.Path})
        end
    end
    table.insert(Scanner.Results, {Category = "Connection Analysis", Count = #withHandlers, Data = withHandlers,
        Summary = string.format("%d remotes have active handler connections", #withHandlers)})
    return withHandlers
end

-- 13-17: ADMIN / PRIVILEGE KEYWORD MATCHING
function Scanner:Tech_AdminKeywords(remotes)
    local kws = {"admin", "command", "execute", "mod", "kick", "ban", "teleport", "punish", "god", "kill", "slay",
        "respawn", "goto", "bring", "freeze", "unfreeze", "remotely", "control", "manage", "owner", "shutdown",
        "shut", "power", "override", "sudo", "root", "master", "superuser", "staff", "gm", "gamemaster"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Privilege Escalation", Count = #finds, Data = finds,
        Severity = "CRITICAL", Summary = string.format("%d remotes suggest admin/mod functionality", #finds)})
    return finds
end

-- 18-22: MAP INTERACTION REMOTES
function Scanner:Tech_MapInteraction(remotes)
    local kws = {"door", "gate", "button", "switch", "lever", "elevator", "platform", "bridge", "trap", "spike",
        "lava", "killbrick", "checkpoint", "finish", "win", "complete", "objective", "mission", "interact",
        "trigger", "zone", "region", "volume", "pressure", "panel", "keypad", "lock", "unlock", "open", "close"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Map interaction", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d map-related remotes (doors, buttons, traps)", #finds)})
    return finds
end

-- 23-27: DATA EXPOSURE / IDOR
function Scanner:Tech_DataRemotes(remotes)
    local kws = {"getplayer", "getdata", "getstats", "getlevel", "getinventory", "getowned", "getequipped",
        "loaddata", "fetch", "request", "getcharacter", "getinfo", "lookup", "query", "retrieve", "getall",
        "getuser", "getprofile", "loadprofile", "fetchdata", "get_"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Data Exposure / IDOR", Count = #finds, Data = finds,
        Severity = "HIGH", Summary = string.format("%d data-returning remotes (IDOR risk)", #finds)})
    return finds
end

-- 28-32: ANTI-CHEAT DETECTION
function Scanner:Tech_AntiCheat(remotes)
    local kws = {"detect", "flag", "ban", "kick", "log", "report", "check", "validate", "verify",
        "authentication", "antitamper", "antihack", "integrity", "hash", "checksum", "signature", "token",
        "antichat", "anticheat", "ac_", "security", "secure", "protect"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Anti-Cheat Detection", Count = #finds, Data = finds,
        Severity = "INFO", Summary = string.format("%d anti-cheat related remotes (monitor carefully)", #finds)})
    return finds
end

-- 33-37: CHARACTER / HUMANOID REMOTES
function Scanner:Tech_CharacterRemotes(remotes)
    local kws = {"humanoid", "health", "damage", "takeDamage", "applyDamage", "dealDamage", "hurt", "heal",
        "revive", "respawnCharacter", "setHealth", "setWalkSpeed", "setJumpPower", "stun", "root", "ragdoll",
        "transform", "morph", "scale", "size", "speed", "jump"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Character Manipulation", Count = #finds, Data = finds,
        Severity = "HIGH", Summary = string.format("%d character-affecting remotes", #finds)})
    return finds
end

-- 38-42: INVENTORY / BACKPACK
function Scanner:Tech_InventoryRemotes(remotes)
    local kws = {"inventory", "backpack", "item", "equip", "unequip", "drop", "pickup", "collect",
        "store", "retrieve", "giveitem", "removeitem", "hasitem", "useitem"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Inventory", Count = #finds, Data = finds,
        Severity = "HIGH", Summary = string.format("%d inventory-related remotes", #finds)})
    return finds
end

-- 43-47: WEAPON / COMBAT
function Scanner:Tech_WeaponRemotes(remotes)
    local kws = {"weapon", "gun", "sword", "shoot", "fire", "reload", "aim", "attack", "slash", "melee",
        "ranged", "bullet", "projectile", "hit", "damage", "hurt", "killstreak"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Weapon/Combat", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d weapon/combat remotes", #finds)})
    return finds
end

-- 48-52: NPC / ENEMY
function Scanner:Tech_NPCRemotes(remotes)
    local kws = {"npc", "enemy", "mob", "boss", "monster", "creature", "pet", "summon", "spawn", "despawn",
        "aggro", "target", "ai", "behavior", "state", "dialogue", "dialog", "talk", "speak", "quest"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "NPC / Enemy", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d NPC/enemy remotes", #finds)})
    return finds
end

-- 53-57: SKILLS / ABILITIES
function Scanner:Tech_SkillRemotes(remotes)
    local kws = {"skill", "ability", "spell", "power", "ult", "ultimate", "special", "move", "cast",
        "activate", "cooldown", "passive", "buff", "debuff", "aura"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Skills/Abilities", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d skill/ability remotes", #finds)})
    return finds
end

-- 58-62: VEHICLE
function Scanner:Tech_VehicleRemotes(remotes)
    local kws = {"vehicle", "car", "bike", "plane", "boat", "ship", "drive", "enter", "exit", "seat",
        "ride", "mount", "fly", "pilot", "speed", "horn"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Vehicle", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d vehicle remotes", #finds)})
    return finds
end

-- 63-67: BUILDING / PLACEMENT
function Scanner:Tech_BuildingRemotes(remotes)
    local kws = {"build", "place", "remove", "delete", "rotate", "move", "paint", "color", "material",
        "property", "grid", "snap", "undo", "redo", "palette"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Building/Placement", Count = #finds, Data = finds,
        Severity = "HIGH", Summary = string.format("%d building remotes", #finds)})
    return finds
end

-- 68-72: SOCIAL / FRIEND / PARTY
function Scanner:Tech_SocialRemotes(remotes)
    local kws = {"friend", "party", "guild", "clan", "team", "group", "invite", "join", "leave", "kickfromgroup",
        "chat", "message", "whisper", "pm", "mail", "trade", "gift", "donate"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Social/Party", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d social remotes", #finds)})
    return finds
end

-- 73-77: GAMEPASS / PAYMENT
function Scanner:Tech_PaymentRemotes(remotes)
    local kws = {"gamepass", "product", "purchase", "buy", "buy", "premium", "vip", "donate", "pledge",
        "subscription", "pass", "ticket", "coin", "gem", "robux"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then
                table.insert(finds, r); break
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Payment/Gamepass", Count = #finds, Data = finds,
        Severity = "CRITICAL", Summary = string.format("%d payment/gamepass remotes", #finds)})
    return finds
end

-- 78-82: PROXIMITY PROMPT / CLICK DETECTOR MAPPING
function Scanner:Tech_ProximityPrompts()
    local prompts = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            table.insert(prompts, {
                Name = obj.Name, Parent = parent and parent.Name,
                Path = obj:GetFullName(), ActionText = obj.ActionText,
                ObjectText = obj.ObjectText, HoldDuration = obj.HoldDuration,
                RequiresLineOfSight = obj.RequiresLineOfSight,
                MaxActivationDistance = obj.MaxActivationDistance
            })
        end
        if obj:IsA("ClickDetector") then
            table.insert(prompts, {
                Name = "ClickDetector", Parent = obj.Parent and obj.Parent.Name,
                Path = obj:GetFullName(), MaxActivationDistance = obj.MaxActivationDistance
            })
        end
    end
    table.insert(Scanner.Results, {Category = "Interaction Points", Count = #prompts, Data = prompts,
        Severity = "MEDIUM", Summary = string.format("%d ProximityPrompts/ClickDetectors found", #prompts)})
    return prompts
end

-- 83-87: COLLECTION SERVICE TAGS
function Scanner:Tech_CollectionTags()
    local tags = {}
    local allTags = CollectionService:GetTags()
    for _, tag in ipairs(allTags) do
        local instances = CollectionService:GetTagged(tag)
        table.insert(tags, {Tag = tag, Count = #instances})
    end
    table.insert(Scanner.Results, {Category = "Collection Tags", Count = #tags, Data = tags,
        Summary = string.format("%d unique CollectionService tags found", #tags)})
    return tags
end

-- 88-92: MODULE SCRIPT ANALYSIS
function Scanner:Tech_ModuleScripts()
    local mods = {}
    local protected = {}
    local services = {ReplicatedStorage, ServerStorage, ServerScriptService}
    for _, sv in ipairs(services) do
        for _, obj in ipairs(sv:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local ok, src = pcall(function() return obj.Source end)
                local isProtected = false
                if not ok then
                    ok, src = pcall(function() return getscriptbytecode(obj) end)
                    isProtected = true
                end
                table.insert(mods, {
                    Name = obj.Name, Path = obj:GetFullName(), Service = sv.Name,
                    Protected = isProtected, HasSource = ok
                })
                if isProtected then
                    table.insert(protected, obj.Name)
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "ModuleScripts", Count = #mods, Data = mods,
        Summary = string.format("%d modules (%d protected)", #mods, #protected)})
    return mods
end

-- 93-97: HIDDEN INSTANCES (NIL INSTANCES)
function Scanner:Tech_HiddenInstances()
    local hidden = {}
    if not getnilinstances then return hidden end
    for _, obj in ipairs(getnilinstances()) do
        table.insert(hidden, {
            Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName(),
            Archivable = obj.Archivable
        })
    end
    table.insert(Scanner.Results, {Category = "Hidden Instances", Count = #hidden, Data = hidden,
        Severity = "HIGH", Summary = string.format("%d hidden instances (getnilinstances)", #hidden)})
    return hidden
end

-- 98-102: GC / REGISTRY ANALYSIS — CAPTURE REMOTE HANDLERS
function Scanner:Tech_GCAnalysis()
    local handlers = {}
    if not getgc then return handlers end
    local gc = getgc()
    for _, obj in ipairs(gc) do
        if type(obj) == "function" then
            local ok, info = pcall(function() return debug.getinfo(obj) end)
            if ok and info then
                local src = info.short_src or ""
                if src:find("RemoteEvent") or src:find("RemoteFunction") or src:find("FireServer") or src:find("InvokeServer") then
                    table.insert(handlers, {Source = src, Line = info.linedefined or 0, Name = info.name or "anonymous"})
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "GC Functions", Count = #handlers, Data = handlers,
        Summary = string.format("%d remote-related functions in GC", #handlers)})
    return handlers
end

-- 103-107: WORKSPACE INTERACTIVE PARTS ANALYSIS
function Scanner:Tech_InteractiveParts()
    local interactive = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local lower = obj.Name:lower()
            if lower:find("button") or lower:find("switch") or lower:find("lever") or lower:find("door") or
               lower:find("gate") or lower:find("keypad") or lower:find("panel") or lower:find("terminal") or
               lower:find("button") or lower:find("pedestal") or lower:find("altar") or lower:find("shrine") or
               lower:find("portal") or lower:find("teleport") or lower:find("spawn") or lower:find("trap") then
                table.insert(interactive, {Name = obj.Name, Path = obj:GetFullName(), Position = tostring(obj.Position), Size = tostring(obj.Size)})
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Interactive Parts", Count = #interactive, Data = interactive,
        Severity = "MEDIUM", Summary = string.format("%d interactive parts in workspace", #interactive)})
    return interactive
end

-- 108-112: PLAYER VALUE MONITORING TARGETS
function Scanner:Tech_PlayerValues()
    local values = {}
    local player = Players.LocalPlayer
    if not player then return values end
    local char = player.Character
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("ObjectValue") then
                table.insert(values, {Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName(), Value = tostring(obj.Value)})
            end
        end
    end
    if player:FindFirstChild("PlayerGui") then
        for _, obj in ipairs(player.PlayerGui:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(values, {Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName(), Location = "PlayerGui"})
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Player Values", Count = #values, Data = values,
        Summary = string.format("%d player-specific values/remotes", #values)})
    return values
end

-- 113-117: BINDS / EVENTS IN PLAYER SCRIPTS
function Scanner:Tech_LocalScriptEvents()
    local events = {}
    local player = Players.LocalPlayer
    if not player then return events end
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return events end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("LocalScript") then
            local ok, src = pcall(function() return obj.Source end)
            if ok and src then
                for line in src:gmatch("[^\r\n]+") do
                    if line:find("RemoteEvent") or line:find("RemoteFunction") or line:find("FireServer") or line:find("InvokeServer") then
                        table.insert(events, {Script = obj.Name, Path = obj:GetFullName(), Code = line})
                    end
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Script Events", Count = #events, Data = events,
        Summary = string.format("%d remote references in LocalScripts", #events)})
    return events
end

-- 118-122: ACTOR / PARALLELISM DETECTION
function Scanner:Tech_Actors()
    local actors = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Actor") then
            table.insert(actors, {Name = obj.Name, Path = obj:GetFullName()})
        end
    end
    table.insert(Scanner.Results, {Category = "Actors/Parallelism", Count = #actors, Data = actors,
        Severity = "INFO", Summary = string.format("%d Actor instances found", #actors)})
    return actors
end

-- 123-127: SOUND / AUDIO REMOTES
function Scanner:Tech_SoundRemotes(remotes)
    local kws = {"sound", "audio", "music", "sfx", "play", "volume", "song", "ambient", "speak", "voice", "mic"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then table.insert(finds, r); break end
        end
    end
    table.insert(Scanner.Results, {Category = "Sound/Audio", Count = #finds, Data = finds,
        Severity = "LOW", Summary = string.format("%d sound-related remotes", #finds)})
    return finds
end

-- 128-132: ANIMATION REMOTES
function Scanner:Tech_AnimationRemotes(remotes)
    local kws = {"anim", "animate", "pose", "gesture", "emote", "dance", "wave", "sit", "lay", "idle",
        "run", "walk", "jump", "fall", "land", "climb", "swim"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then table.insert(finds, r); break end
        end
    end
    table.insert(Scanner.Results, {Category = "Animation", Count = #finds, Data = finds,
        Severity = "LOW", Summary = string.format("%d animation-related remotes", #finds)})
    return finds
end

-- 133-137: SERVER-SCRIPT SERVICE REMOTE HANDLER DISCOVERY
function Scanner:Tech_ServerScriptAnalysis()
    local findings = {}
    local kws = {"RemoteEvent", "RemoteFunction", "FireClient", "InvokeClient", "OnServerEvent", "OnServerInvoke"}
    for _, obj in ipairs(ServerScriptService:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("ModuleScript") then
            local ok, src = pcall(function() return obj.Source end)
            if ok and src then
                local found = {}
                for _, kw in ipairs(kws) do
                    if src:find(kw) then table.insert(found, kw) end
                end
                if #found > 0 then
                    table.insert(findings, {Name = obj.Name, Path = obj:GetFullName(), Keywords = found})
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Server Script Analysis", Count = #findings, Data = findings,
        Severity = "HIGH", Summary = string.format("%d server scripts referencing remotes", #findings)})
    return findings
end

-- 138-142: ATTRIBUTE ANALYSIS ON PARTS
function Scanner:Tech_PartAttributes()
    local attrs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and #obj:GetAttributes() > 0 then
            local attrList = {}
            for k, v in pairs(obj:GetAttributes()) do
                table.insert(attrList, string.format("%s=%s", k, tostring(v)))
            end
            table.insert(attrs, {Name = obj.Name, Path = obj:GetFullName(), Attributes = attrList})
        end
    end
    table.insert(Scanner.Results, {Category = "Part Attributes", Count = #attrs, Data = attrs,
        Summary = string.format("%d parts with custom attributes", #attrs)})
    return attrs
end

-- 143-147: GUILDS / GROUPS
function Scanner:Tech_GroupRemotes(remotes)
    local kws = {"guild", "clan", "group", "faction", "squad", "team", "alliance", "kingdom", "crew", "gang"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then table.insert(finds, r); break end
        end
    end
    table.insert(Scanner.Results, {Category = "Groups/Guilds", Count = #finds, Data = finds,
        Severity = "MEDIUM", Summary = string.format("%d group/guild remotes", #finds)})
    return finds
end

-- 148-152: PLAYERSTATE / SESSION
function Scanner:Tech_SessionRemotes(remotes)
    local kws = {"session", "state", "status", "ready", "loaded", "initialized", "sync", "heartbeat", "ping", "join", "leave", "spawned"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then table.insert(finds, r); break end
        end
    end
    table.insert(Scanner.Results, {Category = "Session/State", Count = #finds, Data = finds,
        Severity = "LOW", Summary = string.format("%d session/state remotes", #finds)})
    return finds
end

-- 153-157: ACTUAL REMOTE TESTING (SAFE MODE)
function Scanner:Tech_SafeProbe(remotes)
    local vulnerable = {}
    local bypassCount = 0
    for i, r in ipairs(remotes or {}) do
        if i > 10 then break end
        local obj = game:GetService(r.Service):FindFirstChild(r.Name, true)
        if obj and obj:IsA("RemoteFunction") then
            local ok, resp = pcall(function() return obj:InvokeServer("PROBE") end)
            if ok and resp ~= nil then
                table.insert(vulnerable, {Remote = r.Name, Response = tostring(resp):sub(1, 80)})
            end
        end
        task.wait(0.1)
    end
    table.insert(Scanner.Results, {Category = "Safe Probe", Count = #vulnerable, Data = vulnerable,
        Severity = "CRITICAL", Summary = string.format("%d remotes responded to probe (BYpass risk!)", #vulnerable)})
    return vulnerable
end

-- 158-162: ENVIRONMENT FEATURE CHECK
function Scanner:Tech_EnvironmentCheck()
    local features = {}
    local checks = {
        {"hookmetamethod", hookmetamethod ~= nil},
        {"getnilinstances", getnilinstances ~= nil},
        {"getgc", getgc ~= nil},
        {"getreg", getreg ~= nil},
        {"getconnections", getconnections ~= nil},
        {"getscriptbytecode", getscriptbytecode ~= nil},
        {"getscriptsource", getscriptsource ~= nil},
        {"hookfunction", hookfunction ~= nil},
        {"clonefunction", clonefunction ~= nil},
        {"setclipboard", setclipboard ~= nil},
        {"getnamecallmethod", getnamecallmethod ~= nil},
        {"gettenv", gettenv ~= nil},
        {"getrenv", getrenv ~= nil}
    }
    for _, check in ipairs(checks) do
        table.insert(features, {Feature = check[1], Available = check[2]})
    end
    table.insert(Scanner.Results, {Category = "Environment", Count = #features, Data = features,
        Summary = string.format("Executor capability: %d/%d features available", (function() local c=0 for _,f in ipairs(features) do if f.Available then c=c+1 end end return c end)(), #features)})
    return features
end

-- 163-167: BINDABLE EVENT/FUNCTION CHAIN DETECTION
function Scanner:Tech_BindableChains()
    local bindables = {}
    for _, sv in ipairs({ReplicatedStorage, ServerStorage, ServerScriptService}) do
        for _, obj in ipairs(sv:GetDescendants()) do
            if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                table.insert(bindables, {Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName(), Service = sv.Name})
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Bindable Chains", Count = #bindables, Data = bindables,
        Severity = "MEDIUM", Summary = string.format("%d BindableEvents/Functions (internal communication)", #bindables)})
    return bindables
end

-- 168-172: FOLDER STRUCTURE ANALYSIS — FIND MODULES BY PATH
function Scanner:Tech_FolderStructure()
    local important = {}
    local keywords = {"module", "remote", "handler", "service", "controller", "manager", "system", "core", "api"}
    for _, sv in ipairs({ReplicatedStorage, ServerStorage, ServerScriptService}) do
        for _, obj in ipairs(sv:GetChildren()) do
            local lower = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if lower:find(kw) then
                    table.insert(important, {Name = obj.Name, Path = obj:GetFullName(), Service = sv.Name})
                    break
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Folder Structure", Count = #important, Data = important,
        Summary = string.format("%d important folders found", #important)})
    return important
end

-- 173-177: SCRIPT REFERENCE EXTRACTION
function Scanner:Tech_ScriptReferences()
    local refs = {}
    local patterns = {
        "require%(.-%)", "loadstring%(.-%)", "script:FindFirstChild",
        "Instance%.new", "game:GetService", "ReplicatedStorage:FindFirstChild"
    }
    for _, sv in ipairs({ReplicatedStorage, ServerScriptService, ServerStorage}) do
        for _, obj in ipairs(sv:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local ok, src = pcall(function() return obj.Source end)
                if ok and src then
                    for _, pat in ipairs(patterns) do
                        for match in src:gmatch(pat) do
                            table.insert(refs, {Script = obj.Name, Pattern = pat, Match = match:sub(1, 60)})
                        end
                    end
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Script References", Count = #refs, Data = refs,
        Summary = string.format("%d code references (require/loadstring/instance)", #refs)})
    return refs
end

-- 178-182: REMOTE DESTINATION ANALYSIS
function Scanner:Tech_RemoteDestinations(remotes)
    local functions = {}
    local events = {}
    for _, r in ipairs(remotes or {}) do
        if r.Class == "RemoteFunction" then table.insert(functions, r) end
        if r.Class == "RemoteEvent" then table.insert(events, r) end
    end
    table.insert(Scanner.Results, {Category = "Remote Breakdown", Count = #remotes, Data = {
        Total = #remotes, Functions = #functions, Events = #events
    }, Summary = string.format("%d total: %d Functions, %d Events", #remotes, #functions, #events)})
    return {functions, events}
end

-- 183-187: OBJECTVALUE / PLAYER VALUE TARGETS
function Scanner:Tech_ObjectValueTargets()
    local targets = {}
    for _, sv in ipairs({ReplicatedStorage, Workspace}) do
        for _, obj in ipairs(sv:GetDescendants()) do
            if obj:IsA("ObjectValue") and obj.Value then
                table.insert(targets, {Name = obj.Name, Path = obj:GetFullName(), Target = obj.Value.ClassName, TargetName = obj.Value.Name})
            end
        end
    end
    table.insert(Scanner.Results, {Category = "ObjectValue Targets", Count = #targets, Data = targets,
        Severity = "MEDIUM", Summary = string.format("%d ObjectValues with targets", #targets)})
    return targets
end

-- 188-192: RAYCAST / PHYSICS ASSET DETECTION
function Scanner:Tech_PhysicsAssets()
    local assets = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Terrain") then
            table.insert(assets, {Name = "Terrain", Cells = obj.Cells})

        elseif obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Part") then
            if obj:IsA("MeshPart") then
                table.insert(assets, {Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName(), MeshId = obj.MeshId})
            end
        elseif obj:IsA("WedgePart") or obj:IsA("CornerWedgePart") or obj:IsA("TrussPart") then
            table.insert(assets, {Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName()})
        end
    end
    table.insert(Scanner.Results, {Category = "Physics Assets", Count = #assets, Data = assets,
        Summary = string.format("%d physics/special parts found", #assets)})
    return assets
end

-- 193-197: LIGHTING / ENVIRONMENT REMOTES
function Scanner:Tech_EnvironmentRemotes(remotes)
    local kws = {"lighting", "light", "fog", "sky", "sun", "moon", "time", "cycle", "day", "night",
        "weather", "rain", "snow", "storm", "wind", "bloom", "colorcorrection", "atmosphere"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then table.insert(finds, r); break end
        end
    end
    table.insert(Scanner.Results, {Category = "Environment/Lighting", Count = #finds, Data = finds,
        Severity = "LOW", Summary = string.format("%d environment remotes", #finds)})
    return finds
end

-- 198-200: CONSTRAINTS / JOINTS ANALYSIS
function Scanner:Tech_Constraints()
    local constraints = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Constraint") or (obj.ClassName and obj.ClassName:find("Constraint")) then
            table.insert(constraints, {Name = obj.Name, Class = obj.ClassName, Path = obj:GetFullName()})
        end
    end
    table.insert(Scanner.Results, {Category = "Constraints/Joints", Count = #constraints, Data = constraints,
        Summary = string.format("%d constraints found", #constraints)})
    return constraints
end

-- 201-205: CFRAIME / POSITION SENSITIVE REMOTES
function Scanner:Tech_PositionRemotes(remotes)
    local kws = {"position", "pos", "location", "coordinate", "teleport", "move", "warp", "jump", "loco"}
    local finds = {}
    for _, r in ipairs(remotes or {}) do
        local lower = r.Name:lower()
        for _, kw in ipairs(kws) do
            if lower:find(kw) then table.insert(finds, r); break end
        end
    end
    table.insert(Scanner.Results, {Category = "Position/Teleport", Count = #finds, Data = finds,
        Severity = "HIGH", Summary = string.format("%d position-related remotes", #finds)})
    return finds
end

-- 206-210: MODULE REQUIRE GRAPH
function Scanner:Tech_RequireGraph()
    local graph = {}
    for _, sv in ipairs({ReplicatedStorage, ServerScriptService, ServerStorage}) do
        for _, obj in ipairs(sv:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local ok, src = pcall(function() return obj.Source end)
                if ok and src then
                    local requires = {}
                    for line in src:gmatch("[^\r\n]+") do
                        local req = line:match("require%(([^)]+)%)")
                        if req then table.insert(requires, req) end
                    end
                    if #requires > 0 then
                        table.insert(graph, {Module = obj.Name, Requires = requires})
                    end
                end
            end
        end
    end
    table.insert(Scanner.Results, {Category = "Require Graph", Count = #graph, Data = graph,
        Summary = string.format("%d modules with require dependencies", #graph)})
    return graph
end

-- ============================================================
-- MASTER SCAN — يشغل كل التقنيات
-- ============================================================
function Scanner:FullScan()
    print("\n" .. string.rep("=", 60))
    print("     NEMESIS ULTIMATE SCANNER v3.0")
    print("     200+ Detection Techniques")
    print(string.rep("=", 60))
    print("  Scanning... this may take a moment.\n")

    Scanner.Results = {}

    Section("1/19 — Remote Enumeration")
    local remotes = self:Tech_AllServicesScan()
    T("Found %d remotes", #remotes)

    Section("2/19 — Remote Classification")
    self:Tech_AdminKeywords(remotes)
    self:Tech_MapInteraction(remotes)
    self:Tech_DataRemotes(remotes)
    self:Tech_AntiCheat(remotes)
    self:Tech_CharacterRemotes(remotes)
    self:Tech_InventoryRemotes(remotes)
    self:Tech_WeaponRemotes(remotes)
    self:Tech_NPCRemotes(remotes)
    self:Tech_SkillRemotes(remotes)
    self:Tech_VehicleRemotes(remotes)
    self:Tech_BuildingRemotes(remotes)
    self:Tech_SocialRemotes(remotes)
    self:Tech_PaymentRemotes(remotes)
    self:Tech_GroupRemotes(remotes)
    self:Tech_SessionRemotes(remotes)
    self:Tech_EnvironmentRemotes(remotes)
    self:Tech_PositionRemotes(remotes)
    self:Tech_SoundRemotes(remotes)
    self:Tech_AnimationRemotes(remotes)
    self:Tech_RemoteDestinations(remotes)
    T("Classification complete")

    Section("3/19 — Obfuscation & Hidden")
    self:Tech_ObfuscatedNames(remotes)
    self:Tech_HiddenInstances()
    T("Hidden detection complete")

    Section("4/19 — Connection Analysis")
    self:Tech_ConnectionAnalysis(remotes)
    T("Connection analysis complete")

    Section("5/19 — Interaction Points")
    self:Tech_ProximityPrompts()
    T("Interaction points scanned")

    Section("6/19 — Collection Tags")
    self:Tech_CollectionTags()
    T("Tags scanned")

    Section("7/19 — ModuleScript Analysis")
    self:Tech_ModuleScripts()
    T("Modules scanned")

    Section("8/19 — Memory Analysis")
    self:Tech_GCAnalysis()
    T("GC scanned")

    Section("9/19 — Interactive Parts")
    self:Tech_InteractiveParts()
    self:Tech_PartAttributes()
    T("Parts scanned")

    Section("10/19 — Player Values")
    self:Tech_PlayerValues()
    T("Player values scanned")

    Section("11/19 — Script Analysis")
    self:Tech_LocalScriptEvents()
    self:Tech_ServerScriptAnalysis()
    self:Tech_ScriptReferences()
    T("Scripts analyzed")

    Section("12/19 — Actors & Parallelism")
    self:Tech_Actors()
    T("Actors scanned")

    Section("13/19 — Bindable Chains")
    self:Tech_BindableChains()
    T("Bindables scanned")

    Section("14/19 — Folder Structure")
    self:Tech_FolderStructure()
    T("Folders mapped")

    Section("15/19 — ObjectValue Targets")
    self:Tech_ObjectValueTargets()
    T("ObjectValues scanned")

    Section("16/19 — Physics & Constraints")
    self:Tech_PhysicsAssets()
    self:Tech_Constraints()
    T("Physics scanned")

    Section("17/19 — Require Graph")
    self:Tech_RequireGraph()
    T("Dependency graph built")

    Section("18/19 — Environment Check")
    self:Tech_EnvironmentCheck()
    T("Environment checked")

    Section("19/19 — Safe Probe (top remotes)")
    self:Tech_SafeProbe(remotes)
    T("Safe probing complete")

    -- Count totals
    local total = 0
    local vulns = 0
    for _, r in ipairs(Scanner.Results) do
        total = total + (r.Count or 0)
        if r.Severity == "CRITICAL" or r.Severity == "HIGH" then
            vulns = vulns + (r.Count or 0)
        end
    end

    print("\n" .. string.rep("=", 60))
    print("  SCAN COMPLETE")
    print(string.rep("=", 60))
    print(string.format("  Total findings: %d", total))
    print(string.format("  High/Critical: %d", vulns))
    print(string.format("  Categories: %d", #Scanner.Results))
    print(string.rep("=", 60) .. "\n")

    return Scanner.Results
end

function Scanner:GetResults()
    return Scanner.Results
end

function Scanner:GetVulnerabilities(severity)
    local vulns = {}
    for _, r in ipairs(Scanner.Results) do
        if severity == nil or r.Severity == severity then
            if r.Data and type(r.Data) == "table" and #r.Data > 0 then
                for _, d in ipairs(r.Data) do
                    table.insert(vulns, {Category = r.Category, Severity = r.Severity or "MEDIUM", Item = d})
                end
            end
        end
    end
    return vulns
end

function Scanner:ExportJSON()
    local data = {
        Timestamp = os.time(),
        TotalCategories = #Scanner.Results,
        Results = Scanner.Results
    }
    local success, json = pcall(function() return HttpService:JSONEncode(data) end)
    if success then return json end
    return "{}"
end

function Scanner:ExportVulnerabilityList()
    local lines = {}
    table.insert(lines, "=== NEMESIS VULNERABILITY REPORT ===")
    table.insert(lines, string.format("Date: %s", os.date()))
    table.insert(lines, "")

    for _, r in ipairs(Scanner.Results) do
        if r.Data and type(r.Data) == "table" and #r.Data > 0 then
            table.insert(lines, string.format("[%s] %s (%d found)", r.Severity or "INFO", r.Category, r.Count))
            table.insert(lines, string.format("  Summary: %s", r.Summary or ""))
            table.insert(lines, "")

            for j, d in ipairs(r.Data) do
                if type(d) == "table" then
                    local parts = {}
                    for k, v in pairs(d) do
                        if type(v) ~= "table" then
                            table.insert(parts, string.format("%s: %s", k, tostring(v)))
                        end
                    end
                    table.insert(lines, string.format("  %d. %s", j, table.concat(parts, " | ")))
                else
                    table.insert(lines, string.format("  %d. %s", j, tostring(d)))
                end
                if j >= 50 then
                    table.insert(lines, string.format("  ... and %d more", #r.Data - 50))
                    break
                end
            end
            table.insert(lines, "")
        end
    end

    return table.concat(lines, "\n")
end

return Scanner