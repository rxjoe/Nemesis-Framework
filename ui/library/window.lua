local Base = require(script.Parent:WaitForChild("base"))
local Theme = require(script.Parent.Parent.themes:WaitForChild("default"))

local Window = {}
Window.__index = Window

function Window.new(title, size, position)
    local self = setmetatable({}, Window)
    self.Components = {}
    self.Tabs = {}
    self.CurrentTab = nil
    self.Frame = nil

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NemesisUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    self.ScreenGui = ScreenGui

    self.Main = Base:Create("Frame", {
        Size = size or UDim2.new(0, 750, 0, 550),
        Position = position or UDim2.new(0.5, -375, 0.5, -275),
        BackgroundColor3 = Theme.Background or Color3.fromRGB(10, 10, 15),
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        ClipsDescendants = true
    })
    self.Main.Parent = ScreenGui
    Base:AddCorner(self.Main, 8)
    Base:AddStroke(self.Main, Theme.Primary or Color3.fromRGB(120, 50, 200), 1.5)

    self.Header = Base:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Header or Color3.fromRGB(18, 18, 25),
        BorderSizePixel = 0
    })
    self.Header.Parent = self.Main
    Base:AddCorner(self.Header, 8)

    local headerFill = Base:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Theme.Header or Color3.fromRGB(18, 18, 25),
        BorderSizePixel = 0
    })
    headerFill.Parent = self.Header

    self.Title = Base:Create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "NEMESIS FRAMEWORK",
        TextColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self.Title.Parent = self.Header

    self.CloseBtn = Base:Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 7),
        BackgroundColor3 = Color3.fromRGB(40, 20, 25),
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 80, 80),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0
    })
    self.CloseBtn.Parent = self.Header
    Base:AddCorner(self.CloseBtn, 6)
    self.CloseBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    self.TabBar = Base:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundColor3 = Theme.Background or Color3.fromRGB(10, 10, 15),
        BorderSizePixel = 0
    })
    self.TabBar.Parent = self.Main

    self.TabHolder = Base:Create("Frame", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1
    })
    self.TabHolder.Parent = self.TabBar

    self.TabButtons = {}
    self.TabFrames = {}
    self.TabIndex = 0
    self.TabPos = 0

    self.ContentArea = Base:Create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -98),
        Position = UDim2.new(0, 10, 0, 86),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    self.ContentArea.Parent = self.Main

    self.ContentList = Base:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    self.ContentList.Parent = self.ContentArea

    return self
end

function Window:AddTab(name)
    self.TabIndex = self.TabIndex + 1
    local idx = self.TabIndex

    local btn = Base:Create("TextButton", {
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0, self.TabPos, 0, 4),
        BackgroundColor3 = Theme.Button or Color3.fromRGB(25, 25, 35),
        Text = name,
        TextColor3 = Theme.Text or Color3.fromRGB(180, 180, 180),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        BorderSizePixel = 0
    })
    btn.Parent = self.TabHolder
    Base:AddCorner(btn, 6)
    self.TabPos = self.TabPos + 96

    table.insert(self.TabButtons, btn)
    self.Tabs[name] = {Button = btn, Index = idx}

    local frame = Base:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    frame.Parent = self.ContentArea

    local list = Base:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    list.Parent = frame

    self.TabFrames[name] = frame

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    if not self.CurrentTab then
        self:SelectTab(name)
    end

    return frame, list
end

function Window:SelectTab(name)
    if self.CurrentTab then
        local prev = self.TabButtons[self.Tabs[self.CurrentTab].Index]
        if prev then
            prev.BackgroundColor3 = Theme.Button or Color3.fromRGB(25, 25, 35)
            prev.TextColor3 = Theme.Text or Color3.fromRGB(180, 180, 180)
        end
        local prevFrame = self.TabFrames[self.CurrentTab]
        if prevFrame then prevFrame.Visible = false end
    end

    self.CurrentTab = name
    local btn = self.TabButtons[self.Tabs[name].Index]
    if btn then
        btn.BackgroundColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    local frame = self.TabFrames[name]
    if frame then frame.Visible = true end
end

function Window:AddLabel(text, parent)
    local label = Base:Create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text or Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    label.Parent = parent or self.ContentArea
    return label
end

function Window:AddSection(text, parent)
    local frame = Base:Create("Frame", {
        Size = UDim2.new(1, -10, 0, 28),
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        BorderSizePixel = 0
    })
    frame.Parent = parent or self.ContentArea
    Base:AddCorner(frame, 4)

    local label = Base:Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    label.Parent = frame
    return frame
end

function Window:AddCard(title, content, parent)
    local card = Base:Create("Frame", {
        Size = UDim2.new(1, -10, 0, 60),
        BackgroundColor3 = Color3.fromRGB(16, 16, 22),
        BorderSizePixel = 0
    })
    card.Parent = parent or self.ContentArea
    Base:AddCorner(card, 6)
    Base:AddStroke(card, Color3.fromRGB(30, 30, 40), 1)

    local titleLbl = Base:Create("TextLabel", {
        Size = UDim2.new(0.7, -15, 0, 22),
        Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Accent or Color3.fromRGB(255, 200, 100),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    titleLbl.Parent = card

    local contentLbl = Base:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 26),
        Position = UDim2.new(0, 10, 0, 28),
        BackgroundTransparency = 1,
        Text = content or "",
        TextColor3 = Color3.fromRGB(160, 160, 170),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    contentLbl.Parent = card

    return card
end

function Window:AddButton(text, callback, parent)
    local btn = Base:Create("TextButton", {
        Size = UDim2.new(0, 160, 0, 32),
        BackgroundColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0
    })
    btn.Parent = parent or self.ContentArea
    Base:AddCorner(btn, 6)

    local hover = false
    btn.MouseEnter:Connect(function() if not hover then btn.BackgroundColor3 = (Theme.Primary or Color3.fromRGB(120, 50, 200)):Lerp(Color3.fromRGB(255,255,255), 0.15); hover = true end end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200); hover = false end)

    if callback then
        btn.MouseButton1Click:Connect(function()
            task.spawn(callback)
        end)
    end

    return btn
end

function Window:AddCopyButton(text, getTextCallback, parent)
    local btn = self:AddButton(text, function()
        local t = getTextCallback and getTextCallback() or ""
        if setclipboard then
            setclipboard(t)
            btn.Text = "✓ COPIED!"
            task.delay(2, function() btn.Text = text end)
        end
    end, parent)
    btn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    return btn
end

function Window:AddResultCard(severity, title, detail, parent)
    local colors = {
        CRITICAL = Color3.fromRGB(220, 40, 40),
        HIGH = Color3.fromRGB(220, 120, 40),
        MEDIUM = Color3.fromRGB(220, 200, 40),
        LOW = Color3.fromRGB(100, 200, 100),
        INFO = Color3.fromRGB(80, 140, 220)
    }
    local color = colors[severity] or Color3.fromRGB(120, 120, 120)

    local card = Base:Create("Frame", {
        Size = UDim2.new(1, -10, 0, 44),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BorderSizePixel = 0
    })
    card.Parent = parent or self.ContentArea
    Base:AddCorner(card, 4)

    local bar = Base:Create("Frame", {
        Size = UDim2.new(0, 3, 0.7, 0),
        Position = UDim2.new(0, 4, 0.15, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0
    })
    bar.Parent = card
    Base:AddCorner(bar, 2)

    local sevLbl = Base:Create("TextLabel", {
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = severity or "INFO",
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    sevLbl.Parent = card

    local titleLbl = Base:Create("TextLabel", {
        Size = UDim2.new(1, -90, 0.5, 0),
        Position = UDim2.new(0, 80, 0, 4),
        BackgroundTransparency = 1,
        Text = title or "",
        TextColor3 = Color3.fromRGB(220, 220, 220),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    titleLbl.Parent = card

    local detailLbl = Base:Create("TextLabel", {
        Size = UDim2.new(1, -90, 0.5, 0),
        Position = UDim2.new(0, 80, 0, 20),
        BackgroundTransparency = 1,
        Text = detail or "",
        TextColor3 = Color3.fromRGB(140, 140, 150),
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    detailLbl.Parent = card

    return card
end

function Window:AddProgress(text, parent)
    local frame = Base:Create("Frame", {
        Size = UDim2.new(1, -10, 0, 22),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0
    })
    frame.Parent = parent or self.ContentArea
    Base:AddCorner(frame, 4)

    local fill = Base:Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        BorderSizePixel = 0
    })
    fill.Parent = frame
    Base:AddCorner(fill, 4)

    local label = Base:Create("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    label.Parent = frame

    return {Frame = frame, Fill = fill, Label = label}
end

function Window:AddStatBox(title, value, parent)
    local frame = Base:Create("Frame", {
        Size = UDim2.new(0.5, -6, 0, 50),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BorderSizePixel = 0
    })
    frame.Parent = parent or self.ContentArea
    Base:AddCorner(frame, 6)
    Base:AddStroke(frame, Color3.fromRGB(30, 30, 40), 1)

    local valLbl = Base:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundTransparency = 1,
        Text = tostring(value or "0"),
        TextColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200),
        Font = Enum.Font.GothamBold,
        TextSize = 22
    })
    valLbl.Parent = frame

    local titleLbl = Base:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = title or "",
        TextColor3 = Color3.fromRGB(140, 140, 150),
        Font = Enum.Font.Gotham,
        TextSize = 10
    })
    titleLbl.Parent = frame

    return frame
end

function Window:Destroy()
    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
    end
end

return Window