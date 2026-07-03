-- Nemesis Framework v3.0 Ultimate
-- الصق الكود ده في الـ executor بتاعك وشغله

local BASE = "https://raw.githubusercontent.com/rxjoe/Nemesis-Framework/main"

local Files = {
    ["core/environment"] = "/core/environment.lua",
    ["core/signals"] = "/core/signals.lua",
    ["core/logger"] = "/core/logger.lua",
    ["config/settings"] = "/config/settings.lua",
    ["config/filters"] = "/config/filters.lua",
    ["scanner/struct_mapper"] = "/scanner/struct_mapper.lua",
    ["scanner/state_watcher"] = "/scanner/state_watcher.lua",
    ["scanner/memory_scanner"] = "/scanner/memory_scanner.lua",
    ["scanner/argument_sniffer"] = "/scanner/argument_sniffer.lua",
    ["scanner/remote_profiler"] = "/scanner/remote_profiler.lua",
    ["scanner/ultimate_scanner"] = "/scanner/ultimate_scanner.lua",
    ["modules/network_spoofer"] = "/modules/network_spoofer.lua",
    ["modules/physics_manipulator"] = "/modules/physics_manipulator.lua",
    ["ui/themes/default"] = "/ui/themes/default.lua",
    ["ui/library/base"] = "/ui/library/base.lua",
    ["ui/library/button"] = "/ui/library/button.lua",
    ["ui/library/toggle"] = "/ui/library/toggle.lua",
    ["ui/library/slider"] = "/ui/library/slider.lua",
    ["ui/library/window"] = "/ui/library/window.lua",
    ["ui/controllers/main_controller"] = "/ui/controllers/main_controller.lua",
    ["ui/controllers/scanner_controller"] = "/ui/controllers/scanner_controller.lua",
}

local function getURL(url)
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok then return result end
    ok, result = pcall(function()
        local s = syn.request({Url = url, Method = "GET"})
        return s and s.Body or ""
    end)
    if ok then return result end
    ok, result = pcall(function()
        local s = request({Url = url, Method = "GET"})
        return s and s.Body or ""
    end)
    if ok then return result end
    ok, result = pcall(function()
        return game:GetService("HttpService"):GetAsync(url)
    end)
    if ok then return result end
    return nil
end

local RS = game:GetService("ReplicatedStorage")
local Folder = Instance.new("Folder")
Folder.Name = "NemesisFramework"
Folder.Parent = RS

local function Make(path, src)
    local parts = path:split("/")
    local cur = Folder
    for i, name in ipairs(parts) do
        local child = cur:FindFirstChild(name)
        if not child then
            child = (i == #parts) and Instance.new("ModuleScript") or Instance.new("Folder")
            child.Name = name
            child.Parent = cur
        end
        if i == #parts and src then child.Source = src end
        cur = child
    end
    return cur
end

print("[Nemesis] Downloading...")
local ok = true
for path, url in pairs(Files) do
    local src = getURL(BASE .. url)
    if src then
        Make(path, src)
        print("  + " .. path)
    else
        warn("  X " .. path)
        ok = false
    end
    task.wait()
end

local initSrc = getURL(BASE .. "/init.lua")
if initSrc then
    local m = Instance.new("ModuleScript")
    m.Name = "init"
    m.Source = initSrc
    m.Parent = Folder
    print("[Nemesis] Loading framework...")
    local ok2, result = pcall(function() return require(m) end)
    if ok2 then
        print("[Nemesis] Framework loaded! UI should appear.")
    else
        warn("[Nemesis] Load error: " .. tostring(result))
    end
else
    warn("[Nemesis] Failed to download init.lua")
end