local Base = require(script.Parent:WaitForChild("base"))
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(text, pos, defaultState)
    local self = setmetatable({}, Toggle)
    self.State = defaultState or false
    self.Instance = Base:Create("TextButton", {
        Size = UDim2.new(0, 200, 0, 30),
        Position = pos or UDim2.new(0, 0, 0, 0),
        Text = text .. ": " .. (self.State and "ON" or "OFF"),
        TextColor3 = self.State and Color3.fromRGB(0,255,0) or Color3.fromRGB(200,200,200),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel = 0
    })
    Base:AddCorner(self.Instance)
    
    self.Instance.MouseButton1Click:Connect(function()
        self.State = not self.State
        self.Instance.Text = text .. ": " .. (self.State and "ON" or "OFF")
        self.Instance.TextColor3 = self.State and Color3.fromRGB(0,255,0) or Color3.fromRGB(200,200,200)
    end)
    return self
end

function Toggle:IsOn() return self.State end
return Toggle
