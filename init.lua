-- ==========================================
-- init.lua (Entry Point)
-- هذا هو أول ملف يتم تشغيله عند_require_ الأداة
-- ==========================================

local Nemesis = {}

-- تحميل الأنظمة الأساسية
Nemesis.Environment = require(script.core:WaitForChild("environment"))
Nemesis.Signals = require(script.core:WaitForChild("signals"))
Nemesis.Logger = require(script.core:WaitForChild("logger"))

-- تحميل الإعدادات
Nemesis.Config = require(script.config:WaitForChild("settings"))
Nemesis.Filters = require(script.config:WaitForChild("filters"))

-- تحميل الماسحات (Scanners)
Nemesis.StructMapper = require(script.scanner:WaitForChild("struct_mapper"))
Nemesis.Profiler = require(script.scanner:WaitForChild("remote_profiler"))
Nemesis.StateWatcher = require(script.scanner:WaitForChild("state_watcher"))
Nemesis.MemoryScanner = require(script.scanner:WaitForChild("memory_scanner"))

-- تحميل أدوات الاستغلال (Modules)
Nemesis.HitboxEngine = require(script.modules:WaitForChild("hitbox_engine"))
Nemesis.NetworkSpoofer = require(script.modules:WaitForChild("network_spoofer"))

-- تحميل الواجهة
Nemesis.Theme = require(script.ui.themes:WaitForChild("default"))
Nemesis.MainController = require(script.ui.controllers:WaitForChild("main_controller"))
Nemesis.ScannerController = require(script.ui.controllers:WaitForChild("scanner_controller"))

-- دالة التشغيل الرئيسية
function Nemesis:Start()
    self.Environment:Init() -- ضبط البيئة
    self.Logger:Init()      -- تشغيل الطابعة
    self.Logger:Info("Nemesis Framework Initializing...")
    
    -- بناء الواجهة الرسومية
    self.MainController:Build()
    self.ScannerController:Build()
    
    -- ربط الأحداث (الجسر بين الواجهة والكود)
    self.Signals:Connect("StartScan", function()
        self.Profiler:Analyze()
    end)
    
    self.Signals:Connect("RunSpoofTests", function()
        self.StateWatcher:TakeSnapshot()
        self.NetworkSpoofer:RunTests(self.Profiler.Findings)
    end)

    self.Logger:Info("Nemesis Framework Loaded Successfully.")
end

-- تنفيذ المشروع
Nemesis:Start()

return Nemesis
