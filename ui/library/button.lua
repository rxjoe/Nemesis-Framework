local Base = require(script.Parent:WaitForChild("base"))
local Button = {}
Button.__index = Button

function Button.new(text, pos, size)
    local self = setmetatable({}, Button)
    self.Instance = Base:Create("TextButton", {
        Size = size or UDim2.new(0, 200, 0, 30),
        Position = pos or UDim2.new(0, 0, 0, 0),
        Text = text,
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel = 0
    })
    Base:AddCorner(self.Instance)
    return self
end

function Button:SetCallback(cb)
    self.Instance.MouseButton1Click:Connect(cb)
end
return Button
