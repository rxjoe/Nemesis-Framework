local Root = script.Parent

local Nemesis = {}

Nemesis.Environment = require(Root.core:WaitForChild("environment"))
Nemesis.Signals = require(Root.core:WaitForChild("signals"))
Nemesis.Logger = require(Root.core:WaitForChild("logger"))

Nemesis.Config = require(Root.config:WaitForChild("settings"))
Nemesis.Filters = require(Root.config:WaitForChild("filters"))

Nemesis.StructMapper = require(Root.scanner:WaitForChild("struct_mapper"))
Nemesis.StateWatcher = require(Root.scanner:WaitForChild("state_watcher"))
Nemesis.MemoryScanner = require(Root.scanner:WaitForChild("memory_scanner"))
Nemesis.ArgSniffer = require(Root.scanner:WaitForChild("argument_sniffer"))
Nemesis.UltimateScanner = require(Root.scanner:WaitForChild("ultimate_scanner"))

Nemesis.NetworkSpoofer = require(Root.modules:WaitForChild("network_spoofer"))
Nemesis.PhysicsManipulator = require(Root.modules:WaitForChild("physics_manipulator"))

Nemesis.Theme = require(Root.ui.themes:WaitForChild("default"))
Nemesis.MainController = require(Root.ui.controllers:WaitForChild("main_controller"))
Nemesis.ScannerController = require(Root.ui.controllers:WaitForChild("scanner_controller"))

function Nemesis:Start()
    self.Environment:Init()
    self.Logger:Init()
    self.Logger:Info("Nemesis Framework v3.0 Ultimate — Loading...")

    self.StateWatcher:Init(self.Logger)
    self.NetworkSpoofer:Init(self.Logger)

    self.Logger:Info("Building interface...")
    self.MainController:Build()

    self.Signals:Connect("StartFullScan", function()
        self.Logger:Info("=== NEMESIS ULTIMATE SCAN STARTING ===")
        self.UltimateScanner:FullScan()
        self.Logger:Info("=== SCAN COMPLETE — Check Results tab ===")
    end)

    self.Logger:Info("Nemesis Framework v3.0 Loaded Successfully.")
    self.Logger:Info("Click 'Start Full Scan' to begin vulnerability discovery.")
end

Nemesis:Start()

return Nemesis