local Nemesis = {}

Nemesis.Environment = require(script.core:WaitForChild("environment"))
Nemesis.Signals = require(script.core:WaitForChild("signals"))
Nemesis.Logger = require(script.core:WaitForChild("logger"))

Nemesis.Config = require(script.config:WaitForChild("settings"))
Nemesis.Filters = require(script.config:WaitForChild("filters"))

Nemesis.StructMapper = require(script.scanner:WaitForChild("struct_mapper"))
Nemesis.StateWatcher = require(script.scanner:WaitForChild("state_watcher"))
Nemesis.MemoryScanner = require(script.scanner:WaitForChild("memory_scanner"))
Nemesis.ArgSniffer = require(script.scanner:WaitForChild("argument_sniffer"))
Nemesis.UltimateScanner = require(script.scanner:WaitForChild("ultimate_scanner"))

Nemesis.NetworkSpoofer = require(script.modules:WaitForChild("network_spoofer"))
Nemesis.PhysicsManipulator = require(script.modules:WaitForChild("physics_manipulator"))

Nemesis.Theme = require(script.ui.themes:WaitForChild("default"))
Nemesis.MainController = require(script.ui.controllers:WaitForChild("main_controller"))
Nemesis.ScannerController = require(script.ui.controllers:WaitForChild("scanner_controller"))

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