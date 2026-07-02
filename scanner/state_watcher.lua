-- ==========================================
-- scanner/state_watcher.lua
-- وظيفته: المراقبة الديناميكية لحالة اللعبة (State Mutation Monitoring)
-- يكتشف التغيرات الصامتة اللي مبتعملش Error بس بتغير الداتا
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateWatcher = {}
StateWatcher.__index = StateWatcher

-- إعدادات التصفية (مهمة جداً عشان الـ Lag)
StateWatcher.Config = {
    IgnoreNoise = true,           -- تجاهل التغيرات الصغيرة جداً (الضوضاء)
    MinimumChangeThreshold = 0.5, -- أقل تغير يسجل (مثلاً لو الفلوس اتغيرت 0.1 مش هيسجلها، لو اتغيرت 10 هيسجلها)
    WatchLeaderstats = true,      -- مراقبة الفلوس والـ Stats الافتراضية
    WatchAttributes = false,       -- مراقبة الـ Attributes (ممكن تسبب لاج في بعض المابات السيئة)
    MaxLogs = 50                  -- أقصى عدد التغيرات اللي يحفظها في الذاكرة
}

StateWatcher.Connections = {} -- جدول لحفظ الـ Events عشان نقدر نوقفها لما نريد (Prevent Memory Leaks)
StateWatcher.Logs = {}       -- سجل التغيرات اللي حصلت

function StateWatcher:Init(logger)
    self.Logger = logger or {Warn = warn, Info = print}
    self.LocalPlayer = Players.LocalPlayer
    self.Snapshots = {} -- لقطات سريعة للقيم الحالية
    return self
end

-- دالة التهيئة: تبدأ تراقب اللاعب نفسه والقيم العامة
function StateWatcher:StartMonitoring()
    self.Logger.Info("[StateWatcher] Initializing Dynamic State Monitoring...")
    table.clear(self.Logs)
    self:DisconnectAll() -- نظف الاتصالات القديمة أول حاجة

    -- 1. مراقبة الـ Leaderstats (الفلوس، المستوى، الخ)
    if self.Config.WatchLeaderstats then
        self.LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(1) -- ننتظر الـ Character يكتمل
            local stats = char:FindFirstChild("leaderstats")
            if stats then
                self:WatchValueGroup(stats, "LocalLeaderstats")
            end
        end)
        
        -- لو اللاعب موجود بالفعل
        if self.LocalPlayer.Character then
            local stats = self.LocalPlayer.Character:FindFirstChild("leaderstats")
            if stats then
                self:WatchValueGroup(stats, "LocalLeaderstats")
            end
        end
    end

    -- 2. مراقبة الـ ReplicatedStorage للقيم العالمية (لو لقينا)
    self:ScanAndWatch(RS, "GlobalState", 0)
end

-- دالة عودية (Recursive) تدور على القيم وتعملها مراقبة
function StateWatcher:ScanAndWatch(parent, path, depth)
    if depth > 2 then return end -- منع اللاغ، لا ننزل أكتر من مستويين
    
    for _, obj in ipairs(parent:GetChildren()) do
        local currentPath = path .. "." .. obj.Name
        
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") then
            self:WatchSingleValue(obj, currentPath)
        elseif obj:IsA("Folder") and obj.Name ~= "Sounds" and obj.Name ~= "Animations" then
            -- لو كان فولدر، ادخل جوه دور
            self:ScanAndWatch(obj, currentPath, depth + 1)
        end
    end
end

-- مراقبة مجموعة قيم (زي الـ leaderstats)
function StateWatcher:WatchValueGroup(folder, groupName)
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") then
            self:WatchSingleValue(obj, groupName .. "." .. obj.Name)
        end
    end
end

-- === قلب الملف: دالة مراقبة القيمة الواحدة ===
function StateWatcher:WatchSingleValue(valueObj, fullPath)
    -- نحفظ القيمة الأصلية كلقطة سريعة (Snapshot)
    self.Snapshots[fullPath] = valueObj.Value
    
    -- إنشاء الاتصال (Connection)
    local connection
    connection = valueObj.Changed:Connect(function(newValue)
        local oldValue = self.Snapshots[fullPath]
        
        -- 1. فلتر التغييرات الصغيرة (Noise Filtering)
        if self.Config.IgnoreNoise and typeof(newValue) == "number" then
            local delta = math.abs(newValue - oldValue)
            if delta < self.Config.MinimumChangeThreshold then
                return -- التجاهل، التغير صغير جداً (ضوضاء)
            end
        end
        
        -- 2. تسجيل التغيير في الذاكرة
        local logEntry = {
            Time = os.clock(),
            Path = fullPath,
            OldValue = oldValue,
            NewValue = newValue,
            Delta = (typeof(newValue) == "number") and (newValue - oldValue) or nil
        }
        
        table.insert(self.Logs, 1, logEntry) -- نحط الجديد فوق
        if #self.Logs > self.Config.MaxLogs then
            table.remove(self.Logs) -- نشيل القديم من تحت
        end
        
        -- 3. طباعة التنبيه في الكونسل
        local alertType = "[STATE CHANGE]"
        local deltaStr = logEntry.Delta and string.format(" (Delta: %+g)", logEntry.Delta) or ""
        
        -- تحذير خاص لو القيمة اتزودت من غير مبرر (مثلاً فلوس incremented بدون سبب واضح)
        if logEntry.Delta and logEntry.Delta > self.Config.MinimumChangeThreshold * 10 then
            alertType = "[ANOMALY DETECTED]" -- تغير مفاجئ كبير
            self.Logger.Warn(string.format("%s %s%s -> %s%s", alertType, fullPath, tostring(oldValue), tostring(newValue), deltaStr))
        else
            self.Logger.Info(string.format("%s %s%s -> %s%s", alertType, fullPath, tostring(oldValue), tostring(newValue), deltaStr))
        end
        
        -- تحديث الـ Snapshot بالقيمة الجديدة
        self.Snapshots[fullPath] = newValue
    end)
    
    -- حفظ الـ Connection عشان نقدر نوقفه لما نظف الأداة
    table.insert(self.Connections, connection)
end

-- دالة مهمة جداً: تاخد لقطة سريعة للداتا الحالية (قبل ما ترسل Payload)
function StateWatcher:TakeSnapshot()
    self.Logger.Info("[StateWatcher] Snapshot taken. Send your payload now.")
    -- الـ Snapshots بتتحدث تلقائياً في الـ WatchSingleValue، بس بنعمل ده عشان نرسل إشارة إننا مستعدين
end

-- دالة مقارنة: تقارن الـ Snapshot اللي قبل الـ Payload بالحالة الحالية
function StateWatcher:CompareWithSnapshot(snapshotTime)
    local changes = {}
    -- هنا بنفلتر الـ Logs عشان نرجع بس اللي حصلت بعد وقت الـ Snapshot
    for _, log in ipairs(self.Logs) do
        if log.Time >= snapshotTime then
            table.insert(changes, log)
        end
    end
    return changes
end

-- تنظيف الذاكرة (Prevent Memory Leaks) - ضروري جداً في المشاريع الكبيرة
function StateWatcher:DisconnectAll()
    for _, conn in ipairs(self.Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(self.Connections)
    table.clear(self.Snapshots)
    self.Logger.Info("[StateWatcher] All connections disconnected. Memory cleared.")
end

return StateWatcher
