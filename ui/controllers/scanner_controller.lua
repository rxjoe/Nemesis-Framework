local Button = require(script.Parent.Parent.library:WaitForChild("button"))
local Toggle = require(script.Parent.Parent.library:WaitForChild("toggle"))
local Signals = require(script.Parent.Parent.Parent.core:WaitForChild("signals"))
local Controller = {}

function Controller:Build()
    local ScreenGui = game:GetService("CoreGui"):WaitForChild("NemesisUI")
    local MainFrame = ScreenGui:FindFirstChild("Frame")
    
    -- زرار بدء التحليل
    local ScanBtn = Button.new("1. Start Remote Profiler", UDim2.new(0, 15, 0, 50), UDim2.new(0, 270, 0, 30))
    ScanBtn:SetCallback(function()
        Signals:Fire("StartScan")
    end)
    ScanBtn.Instance.Parent = MainFrame

    -- زرار بدء اختبار الثغرات
    local SpoofBtn = Button.new("2. Run Spoof Payloads", UDim2.new(0, 15, 0, 90), UDim2.new(0, 270, 0, 30))
    SpoofBtn:SetCallback(function()
        Signals:Fire("RunSpoofTests")
    end)
    SpoofBtn.Instance.Parent = MainFrame

    -- توجل لمراقبة الحالة (مجرد مثال)
    local StateToggle = Toggle.new("State Watcher", UDim2.new(0, 15, 0, 130))
    StateToggle.Instance.Parent = MainFrame
end
return Controller
