local Base = require(script.Parent.Parent.library:WaitForChild("base"))
local Theme = require(script.Parent.Parent.themes:WaitForChild("default"))
local Main = {}

function Main:Build()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NemesisUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = Base:Create("Frame", {
        Size = UDim2.new(0, 300, 0, 400),
        Position = UDim2.new(0, 50, 0.5, -200),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true
    })
    Frame.Parent = ScreenGui
    Base:AddCorner(Frame, 10)
    Base:AddStroke(Frame, Theme.Primary, 1.5)

    local Title = Base:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Header,
        TextColor3 = Theme.Primary,
        Text = "NEMESIS FRAMEWORK",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        BorderSizePixel = 0
    })
    Title.Parent = Frame
    Base:AddCorner(Title, 10)
end
return Main
