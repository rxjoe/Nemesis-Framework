local Nemesis = {}

Nemesis.Environment = require(script.core:WaitForChild("environment"))
Nemesis.Signals = require(script.core:WaitForChild("signals"))
Nemesis.Logger = require(script.core:WaitForChild("logger"))

Nemesis.Config = require(script.config:WaitForChild("settings"))
Nemesis.Filters = require(script.config:WaitForChild("filters"))

Nemesis.StructMapper = require(script.scanner:WaitForChild("struct_mapper"))
Nemesis.Profiler = require(script.scanner:WaitForChild("remote_profiler"))
Nemesis.StateWatcher = require(script.scanner:WaitForChild("state_watcher"))
Nemesis.MemoryScanner = require(script.scanner:WaitForChild("memory_scanner"))
Nemesis.ArgSniffer = require(script.scanner:WaitForChild("argument_sniffer"))

Nemesis.HitboxEngine = require(script.modules:WaitForChild("hitbox_engine"))
Nemesis.RayInterceptor = require(script.modules:WaitForChild("ray_interceptor"))
Nemesis.PhysicsManipulator = require(script.modules:WaitForChild("physics_manipulator"))
Nemesis.NetworkSpoofer = require(script.modules:WaitForChild("network_spoofer"))

Nemesis.Theme = require(script.ui.themes:WaitForChild("default"))
Nemesis.MainController = require(script.ui.controllers:WaitForChild("main_controller"))
Nemesis.ScannerController = require(script.ui.controllers:WaitForChild("scanner_controller"))

function Nemesis:Start()
    self.Environment:Init()
    self.Logger:Init()
    self.Logger:Info("Nemesis Framework v2.0 Initializing...")

    self.StateWatcher:Init(self.Logger)

    self.MainController:Build()
    self.ScannerController:Build()

    self.Signals:Connect("StartFullScan", function()
        self.Logger:Info("=== FULL VULNERABILITY SCAN STARTING ===")
        self.Profiler:Analyze()
        self.MemoryScanner:Scan()
        self.MemoryScanner:ScanServices()
        self.ArgSniffer:Start()
        self.Profiler:PrintReport()
        self.MemoryScanner:PrintReport()
        self.Logger:Info("=== SCAN COMPLETE ===")
    end)

    self.Signals:Connect("RunSpoofTests", function()
        self.StateWatcher:TakeSnapshot()
        self.NetworkSpoofer:RunTests(self.Profiler.Findings)
    end)

    self.Signals:Connect("StopSniffer", function()
        self.ArgSniffer:Stop()
        self.ArgSniffer:PrintSummary()
    end)

    self.Signals:Connect("ExportResults", function()
        local report = self.Profiler:ExportReport()
        self.Logger:Info("Report exported. Length: " .. #report .. " characters")
        setclipboard and setclipboard(report)
    end)

    self.Logger:Info("Nemesis Framework v2.0 Loaded Successfully.")
    self.Logger:Info("Commands: StartFullScan | RunSpoofTests | StopSniffer | ExportResults")
end

Nemesis:Start()

return Nemesis