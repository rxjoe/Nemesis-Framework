local Window = require(script.Parent.Parent.library:WaitForChild("window"))
local Theme = require(script.Parent.Parent.themes:WaitForChild("default"))

local Main = {}
Main.Window = nil

function Main:Build()
    if Main.Window then
        pcall(function() Main.Window:Destroy() end)
    end

    local win = Window.new("NEMESIS FRAMEWORK v3.0", UDim2.new(0, 780, 0, 580))

    local scanTab, scanList = win:AddTab("Scanner")
    local resultsTab, resultsList = win:AddTab("Results")
    local aboutTab, aboutList = win:AddTab("About")

    Main.Window = win
    Main.ScanTab = scanTab
    Main.ResultsTab = resultsTab
    Main.ResultsList = resultsList
    Main.AboutTab = aboutTab

    self:BuildScannerTab(scanTab, scanList)
    self:BuildResultsTab(resultsTab, resultsList)
    self:BuildAboutTab(aboutTab, aboutList)

    self:ShowStatus("Ready. Click 'Start Full Scan' to begin.")
end

function Main:BuildScannerTab(tab, list)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🔍 NEMESIS ULTIMATE VULNERABILITY SCANNER"
    title.TextColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = tab

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -10, 0, 18)
    desc.BackgroundTransparency = 1
    desc.Text = "200+ detection techniques | 19 scan categories | Zero lag design"
    desc.TextColor3 = Color3.fromRGB(150, 150, 160)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 10
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = tab

    -- Stats row
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -10, 0, 60)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = tab

    local stat1 = Instance.new("Frame")
    stat1.Size = UDim2.new(0.33, -4, 1, 0)
    stat1.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    stat1.BorderSizePixel = 0
    stat1.Parent = statsFrame
    local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0, 6); c1.Parent = stat1
    local v1 = Instance.new("TextLabel")
    v1.Size = UDim2.new(1, 0, 0, 30); v1.Position = UDim2.new(0, 0, 0, 4)
    v1.BackgroundTransparency = 1; v1.Text = "0"; v1.TextColor3 = Theme.Primary; v1.Font = Enum.Font.GothamBold; v1.TextSize = 24
    v1.Parent = stat1
    local l1 = Instance.new("TextLabel")
    l1.Size = UDim2.new(1, 0, 0, 16); l1.Position = UDim2.new(0, 0, 0, 34)
    l1.BackgroundTransparency = 1; l1.Text = "REMOTES FOUND"; l1.TextColor3 = Color3.fromRGB(140, 140, 150); l1.Font = Enum.Font.Gotham; l1.TextSize = 10
    l1.Parent = stat1

    local stat2 = Instance.new("Frame")
    stat2.Size = UDim2.new(0.33, -4, 1, 0); stat2.Position = UDim2.new(0.33, 4, 0, 0)
    stat2.BackgroundColor3 = Color3.fromRGB(16, 16, 22); stat2.BorderSizePixel = 0; stat2.Parent = statsFrame
    local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, 6); c2.Parent = stat2
    local v2 = Instance.new("TextLabel")
    v2.Size = UDim2.new(1, 0, 0, 30); v2.Position = UDim2.new(0, 0, 0, 4)
    v2.BackgroundTransparency = 1; v2.Text = "0"; v2.TextColor3 = Color3.fromRGB(220, 100, 50); v2.Font = Enum.Font.GothamBold; v2.TextSize = 24
    v2.Parent = stat2
    local l2 = Instance.new("TextLabel")
    l2.Size = UDim2.new(1, 0, 0, 16); l2.Position = UDim2.new(0, 0, 0, 34)
    l2.BackgroundTransparency = 1; l2.Text = "VULNERABILITIES"; l2.TextColor3 = Color3.fromRGB(140, 140, 150); l2.Font = Enum.Font.Gotham; l2.TextSize = 10
    l2.Parent = stat2

    local stat3 = Instance.new("Frame")
    stat3.Size = UDim2.new(0.33, -4, 1, 0); stat3.Position = UDim2.new(0.66, 8, 0, 0)
    stat3.BackgroundColor3 = Color3.fromRGB(16, 16, 22); stat3.BorderSizePixel = 0; stat3.Parent = statsFrame
    local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(0, 6); c3.Parent = stat3
    local v3 = Instance.new("TextLabel")
    v3.Size = UDim2.new(1, 0, 0, 30); v3.Position = UDim2.new(0, 0, 0, 4)
    v3.BackgroundTransparency = 1; v3.Text = "0"; v3.TextColor3 = Color3.fromRGB(80, 180, 80); v3.Font = Enum.Font.GothamBold; v3.TextSize = 24
    v3.Parent = stat3
    local l3 = Instance.new("TextLabel")
    l3.Size = UDim2.new(1, 0, 0, 16); l3.Position = UDim2.new(0, 0, 0, 34)
    l3.BackgroundTransparency = 1; l3.Text = "CATEGORIES"; l3.TextColor3 = Color3.fromRGB(140, 140, 150); l3.Font = Enum.Font.Gotham; l3.TextSize = 10
    l3.Parent = stat3

    -- Buttons
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, -10, 0, 44)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = tab

    local copyAll = Instance.new("TextButton")
    copyAll.Size = UDim2.new(0.5, -3, 0, 36)
    copyAll.BackgroundColor3 = Color3.fromRGB(200, 80, 40)
    copyAll.Text = "📋 COPY ALL VULNERABILITIES"
    copyAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyAll.Font = Enum.Font.GothamBold
    copyAll.TextSize = 11
    copyAll.BorderSizePixel = 0
    copyAll.Parent = btnFrame
    local caCorner = Instance.new("UICorner"); caCorner.CornerRadius = UDim.new(0, 6); caCorner.Parent = copyAll

    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0.5, -3, 0, 36)
    startBtn.Position = UDim2.new(0.5, 3, 0, 0)
    startBtn.BackgroundColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200)
    startBtn.Text = "🚀 START FULL SCAN"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 11
    startBtn.BorderSizePixel = 0
    startBtn.Parent = btnFrame
    local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0, 6); sbCorner.Parent = startBtn

    -- Progress bar container
    local progressFrame = Instance.new("Frame")
    progressFrame.Size = UDim2.new(1, -10, 0, 24)
    progressFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = tab
    local pfCorner = Instance.new("UICorner"); pfCorner.CornerRadius = UDim.new(0, 6); pfCorner.Parent = progressFrame

    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressFrame
    local pfFillCorner = Instance.new("UICorner"); pfFillCorner.CornerRadius = UDim.new(0, 6); pfFillCorner.Parent = progressFill

    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, -10, 1, 0)
    progressLabel.Position = UDim2.new(0, 5, 0, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "Idle"
    progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.TextSize = 10
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = progressFrame

    -- Log area
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Size = UDim2.new(1, -10, 1, -250)
    logFrame.Position = UDim2.new(0, 5, 0, 225)
    logFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    logFrame.BorderSizePixel = 0
    logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    logFrame.ScrollBarThickness = 3
    logFrame.ScrollBarImageColor3 = Theme.Primary or Color3.fromRGB(120, 50, 200)
    logFrame.Parent = tab
    local logCorner = Instance.new("UICorner"); logCorner.CornerRadius = UDim.new(0, 4); logCorner.Parent = logFrame

    local logList = Instance.new("UIListLayout")
    logList.Padding = UDim.new(0, 2)
    logList.SortOrder = Enum.SortOrder.LayoutOrder
    logList.Parent = logFrame

    local function addLog(text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or Color3.fromRGB(160, 160, 160)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 9
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = logFrame
        logFrame.CanvasSize = UDim2.new(0, 0, 0, logFrame.CanvasSize.Y.Offset + 18)
        task.wait()
        logFrame.CanvasPosition = Vector2.new(0, logFrame.CanvasSize.Y.Offset)
    end

    -- Scanner reference
    local Scanner = require(script.Parent.Parent.Parent.scanner:WaitForChild("ultimate_scanner"))

    startBtn.MouseButton1Click:Connect(function()
        startBtn.Text = "⏳ SCANNING..."
        startBtn.Active = false
        progressFill:TweenSize(UDim2.new(0, 10, 1, 0), "Out", "Linear", 0.2)
        progressLabel.Text = "Starting scan..."

        task.spawn(function()
            for _, child in ipairs(logFrame:GetChildren()) do
                if child:IsA("TextLabel") then child:Destroy() end
            end
            logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

            local steps = 19
            local function updateProgress(step, msg)
                local pct = step / steps
                progressFill:TweenSize(UDim2.new(pct, 0, 1, 0), "Out", "Linear", 0.3)
                progressLabel.Text = string.format("[%d/%d] %s", step, steps, msg)
                addLog(string.format("[%d/%d] %s", step, steps, msg), Theme.Primary)
            end

            updateProgress(1, "Scanning all services for remotes...")
            task.wait(0.3)
            local results = Scanner:FullScan()

            updateProgress(19, "Scan complete!")

            -- Update stats
            local totalRemotes = 0
            local totalVulns = 0
            for _, r in ipairs(results) do
                totalRemotes = totalRemotes + (r.Count or 0)
                if r.Severity == "CRITICAL" or r.Severity == "HIGH" then
                    totalVulns = totalVulns + (r.Count or 0)
                end
            end
            v1.Text = tostring(totalRemotes)
            v2.Text = tostring(totalVulns)
            v3.Text = tostring(#results)

            -- Populate results tab
            for _, child in ipairs(Main.ResultsList.Parent:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end

            local resultTitle = Instance.new("TextLabel")
            resultTitle.Size = UDim2.new(1, -10, 0, 28)
            resultTitle.BackgroundTransparency = 1
            resultTitle.Text = string.format("📊 SCAN RESULTS — %d Vulnerabilities Found", totalVulns)
            resultTitle.TextColor3 = Theme.Primary
            resultTitle.Font = Enum.Font.GothamBold
            resultTitle.TextSize = 14
            resultTitle.TextXAlignment = Enum.TextXAlignment.Left
            resultTitle.Parent = Main.ResultsList.Parent

            local copyAllBtn = Instance.new("TextButton")
            copyAllBtn.Size = UDim2.new(1, -10, 0, 36)
            copyAllBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 40)
            copyAllBtn.Text = "📋 COPY ALL VULNERABILITIES TO CLIPBOARD"
            copyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyAllBtn.Font = Enum.Font.GothamBold
            copyAllBtn.TextSize = 11
            copyAllBtn.BorderSizePixel = 0
            copyAllBtn.Parent = Main.ResultsList.Parent
            local caCorner2 = Instance.new("UICorner"); caCorner2.CornerRadius = UDim.new(0, 6); caCorner2.Parent = copyAllBtn

            copyAllBtn.MouseButton1Click:Connect(function()
                local report = Scanner:ExportVulnerabilityList()
                if setclipboard then
                    setclipboard(report)
                    copyAllBtn.Text = "✓ COPIED SUCCESSFULLY!"
                    task.delay(2, function() copyAllBtn.Text = "📋 COPY ALL VULNERABILITIES TO CLIPBOARD" end)
                end
            end)

            for _, r in ipairs(results) do
                if r.Data and type(r.Data) == "table" and #r.Data > 0 then
                    local sev = r.Severity or "MEDIUM"
                    local colors = {
                        CRITICAL = Color3.fromRGB(220, 40, 40),
                        HIGH = Color3.fromRGB(220, 120, 40),
                        MEDIUM = Color3.fromRGB(220, 200, 40),
                        LOW = Color3.fromRGB(100, 200, 100),
                        INFO = Color3.fromRGB(80, 140, 220)
                    }
                    local color = colors[sev] or Color3.fromRGB(120, 120, 120)

                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(1, -10, 0, 50)
                    card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
                    card.BorderSizePixel = 0
                    card.Parent = Main.ResultsList.Parent
                    local cdCorner = Instance.new("UICorner"); cdCorner.CornerRadius = UDim.new(0, 6); cdCorner.Parent = card

                    local bar = Instance.new("Frame")
                    bar.Size = UDim2.new(0, 3, 0.7, 0)
                    bar.Position = UDim2.new(0, 6, 0.15, 0)
                    bar.BackgroundColor3 = color
                    bar.BorderSizePixel = 0
                    bar.Parent = card
                    local barCorner = Instance.new("UICorner"); barCorner.CornerRadius = UDim.new(0, 2); barCorner.Parent = bar

                    local sevLbl = Instance.new("TextLabel")
                    sevLbl.Size = UDim2.new(0, 70, 1, 0)
                    sevLbl.Position = UDim2.new(0, 12, 0, 0)
                    sevLbl.BackgroundTransparency = 1
                    sevLbl.Text = sev
                    sevLbl.TextColor3 = color
                    sevLbl.Font = Enum.Font.GothamBold
                    sevLbl.TextSize = 10
                    sevLbl.TextXAlignment = Enum.TextXAlignment.Left
                    sevLbl.Parent = card

                    local titleLbl = Instance.new("TextLabel")
                    titleLbl.Size = UDim2.new(1, -90, 0.5, 0)
                    titleLbl.Position = UDim2.new(0, 85, 0, 3)
                    titleLbl.BackgroundTransparency = 1
                    titleLbl.Text = string.format("%s (%d found)", r.Category, r.Count)
                    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
                    titleLbl.Font = Enum.Font.GothamBold
                    titleLbl.TextSize = 11
                    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                    titleLbl.Parent = card

                    local sumLbl = Instance.new("TextLabel")
                    sumLbl.Size = UDim2.new(1, -90, 0.5, 0)
                    sumLbl.Position = UDim2.new(0, 85, 0, 23)
                    sumLbl.BackgroundTransparency = 1
                    sumLbl.Text = r.Summary or ""
                    sumLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
                    sumLbl.Font = Enum.Font.Gotham
                    sumLbl.TextSize = 9
                    sumLbl.TextXAlignment = Enum.TextXAlignment.Left
                    sumLbl.TextWrapped = true
                    sumLbl.Parent = card

                    -- Copy individual
                    local copyBtn = Instance.new("TextButton")
                    copyBtn.Size = UDim2.new(0, 50, 0, 20)
                    copyBtn.Position = UDim2.new(0, 7, 0, 26)
                    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    copyBtn.Text = "COPY"
                    copyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                    copyBtn.Font = Enum.Font.Gotham
                    copyBtn.TextSize = 8
                    copyBtn.BorderSizePixel = 0
                    copyBtn.Parent = card
                    local cpCorner = Instance.new("UICorner"); cpCorner.CornerRadius = UDim.new(0, 4); cpCorner.Parent = copyBtn

                    copyBtn.MouseButton1Click:Connect(function()
                        local lines = {}
                        lines:add(string.format("[%s] %s", r.Severity or "INFO", r.Category))
                        for _, d in ipairs(r.Data) do
                            if type(d) == "table" then
                                local parts = {}
                                for k, v in pairs(d) do
                                    if type(v) ~= "table" then parts:add(string.format("%s: %s", k, tostring(v))) end
                                end
                                lines:add(table.concat(parts, " | "))
                            end
                        end
                        local text = table.concat(lines, "\n")
                        if setclipboard then
                            setclipboard(text)
                            copyBtn.Text = "✓"
                            task.delay(1.5, function() copyBtn.Text = "COPY" end)
                        end
                    end)
                end
            end

            addLog("Scan complete! Check Results tab.", Color3.fromRGB(80, 200, 80))
            progressLabel.Text = "Scan complete!"
            startBtn.Text = "🚀 START FULL SCAN"
            startBtn.Active = true
        end)
    end)

    -- Copy All button in scanner tab
    copyAll.MouseButton1Click:Connect(function()
        local report = Scanner:ExportVulnerabilityList()
        if setclipboard then
            setclipboard(report)
            copyAll.Text = "✓ COPIED!"
            task.delay(2, function() copyAll.Text = "📋 COPY ALL VULNERABILITIES" end)
        end
    end)
end

function Main:BuildResultsTab(tab, list)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.Text = "📊 Results will appear here after scanning"
    lbl.TextColor3 = Color3.fromRGB(150, 150, 160)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = tab
end

function Main:BuildAboutTab(tab, list)
    local lines = {
        "NEMESIS FRAMEWORK v3.0",
        "",
        "Ultimate Roblox Vulnerability Scanner",
        "",
        "Key Features:",
        "• 200+ detection techniques across 19 categories",
        "• Remote enumeration & classification",
        "• Obfuscated/hidden name detection",
        "• Anti-cheat remote identification",
        "• Map interaction analysis",
        "• ModuleScript & bytecode analysis",
        "• GC/Registry function scanning",
        "• ProximityPrompt/ClickDetector mapping",
        "• Interactive part detection",
        "• IDOR/Data exposure testing",
        "• Server script analysis",
        "• And much more...",
        "",
        "100% focused on vulnerability discovery only.",
        "No hitbox, no money cheats — pure recon."
    }

    for _, line in ipairs(lines) do
        local isHeader = line == "NEMESIS FRAMEWORK v3.0"
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, isHeader and 24 or 16)
        lbl.BackgroundTransparency = 1
        lbl.Text = line
        lbl.TextColor3 = isHeader and (Theme.Primary or Color3.fromRGB(120, 50, 200)) or Color3.fromRGB(160, 160, 170)
        lbl.Font = isHeader and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.TextSize = isHeader and 16 or 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = tab
    end
end

function Main:ShowStatus(msg)
    -- status update method
    print("[Nemesis] " .. msg)
end

return Main