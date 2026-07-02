local Base = require(script.Parent:WaitForChild("base"))
local Slider = {}
Slider.__index = Slider

function Slider.new(text, pos, min, max, default)
    local self = setmetatable({}, Slider)
    self.Value = default or 5
    -- في المشاريع الحقيقية هنا بنصميم سحب بالماوس
    -- لكن لهيكل المشروع نعمله كتبويب بسيط
    self.Instance = Base:Create("TextLabel", {
        Size = UDim2.new(0, 200, 0, 30),
        Position = pos or UDim2.new(0, 0, 0, 0),
        Text = text .. ": " .. self.Value,
        TextColor3 = Color3.fromRGB(200,200,200),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BorderSizePixel = 0
    })
    Base:AddCorner(self.Instance)
    return self
end
function Slider:GetValue() return self.Value end
return Slider
