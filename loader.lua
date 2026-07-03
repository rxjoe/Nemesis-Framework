-- Nemesis Framework v3.0 Ultimate — Loader
-- الصق الكود ده في الـ executor بتاعك

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

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NemesisFolder = Instance.new("Folder")
NemesisFolder.Name = "NemesisFramework"
NemesisFolder.Parent = ReplicatedStorage

local function createModule(path, source)
    local parts = path:split("/")
    local current = NemesisFolder
    for i, name in ipairs(parts) do
        local child = current:FindFirstChild(name)
        if not child then
            if i == #parts then
                child = Instance.new("ModuleScript")
                child.Name = name
                child.Source = source or ""
                child.Parent = current
            else
                child = Instance.new("Folder")
                child.Name = name
                child.Parent = current
            end
        end
        current = child
    end
    return current
end

print("[Nemesis] Downloading framework files...")

local success = true
for path, url in pairs(Files) do
    local ok, source = pcall(function()
        return HttpService:GetAsync(BASE .. url)
    end)
    if ok then
        createModule(path, source)
        print("  [OK] " .. path)
    else
        print("  [FAIL] " .. path .. " - " .. tostring(source))
        success = false
    end
    task.wait(0.05)
end

if success then
    print("[Nemesis] All files downloaded. Loading framework...")
    local mainModule = NemesisFolder:FindFirstChild("init")
    if not mainModule then
        local ok, initSource = pcall(function()
            return HttpService:GetAsync(BASE .. "/init.lua")
        end)
        if ok then
            mainModule = Instance.new("ModuleScript")
            mainModule.Name = "init"
            mainModule.Source = initSource
            mainModule.Parent = NemesisFolder
        end
    end
    if mainModule then
        local nemesis = require(mainModule)
        print("[Nemesis] Framework loaded successfully!")
    end
else
    warn("[Nemesis] Some files failed to download. Check your connection.")
end