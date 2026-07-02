-- ==========================================
-- modules/network_spoofer.lua
-- وظيفته: أخذ التقارير من الـ Profiler وإرسال Payloads اختبارية لإثبات الثغرات
-- (Boundary Testing & Type Confusion)
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spoofer = {}
Spoofier.__index = Spoofer

-- إعدادات الأمان (مهمة جداً عشان ما تبانش كـ Attacker وتتبنطرد بسرعة)
Spoofer.Config = {
    DelayBetweenTests = 0.5, -- مهلة بين كل اختبار (ثانية ونص) عشان ما تعملش Rate Limit
    MaxTestsPerRemote = 3,   -- أقصى عدد اختبارات لكل ريماوت (عشان تاخد وقت في الإصلاح مش تستفز السيرفر)
    StopOnServerResponse = false -- لو لقيت السيرفر بيرد بيانات غريبة، وقف اختبر غيره
}

-- مكتبة الـ Payloads الذكية (مبنية على علم الـ Cyber Security)
-- كل كاتيجوري جواها بيانات مصممة عشان تكشف خطأ منطقي معين
local PayloadLibrary = {
    -- اختبارات الاقتصاد: هل السيرفر بيقبل أرقام سلبية أو صفر؟
    Economy = {
        { Name = "Negative Price Injection", Args = {nil, -99999}, Expect = "Success/Item Given" },
        { Name = "Zero Cost Bypass", Args = {nil, 0}, Expect = "Success/Item Given" },
        { Name = "Type Confusion (String)", Args = {nil, "FREE_HACK"}, Expect = "Server Error/Success" },
    },
    
    -- اختبارات الصلاحيات: هل السيرفر بيتأكد إنك أدمن؟
    Privilege = {
        { Name = "Basic Mass Kill Command", Args = {"kill all"}, Expect = "Server Error/Action Executed" },
        { Name = "Currency Injection Command", Args = {"give me 999999 money"}, Expect = "Server Error/Balance Changed" },
    },
    
    -- اختبارات تسريب البيانات (IDOR): هل تقدر تجيب داتا غيرك؟
    DataExposure = {
        -- إرسال UserID لاعب تاني (مثلاً روبلوكس نفسه أو أي ID وهمي) بدل ID الخاص بك
        { Name = "IDOR Test (Target ID: 1)", Args = {1}, Expect = "Returns Data not belonging to you" },
    }
}

-- دالة تحويل الـ Args لتنسيق نصي عشان الطباعة
local function FormatArgs(args)
    local str = {}
    for _, a in ipairs(args) do
        table.insert(str, tostring(a))
    end
    table.concat(str, ", ")
end

function Spoofer:Init(logger)
    self.Logger = logger or {Warn = warn, Info = print}
    self.Results = {}
    return self
end

-- الدالة الرئيسية: تأخذ الريماوتات المشبوهة من الـ Profiler وتبدأ الاختبار
function Spoofer:RunTests(findingsTable)
    self.Logger.Info("[Spoofer] Starting Intelligent Payload Injection...")
    self.Results = {}

    -- 1. اختبار ثغرات الصلاحيات (الأخطأ)
    if #findingsTable.PrivilegeEscalation > 0 then
        self.Logger.Warn("[Spoofer] Testing HIGH SEVERITY: Privilege Escalation")
        for _, finding in ipairs(findingsTable.PrivilegeEscalation) do
            local remote = ReplicatedStorage:FindFirstChild(finding.Remote, true)
            if remote then
                self:TestRemote(remote, "Privilege", finding)
                task.wait(self.Config.DelayBetweenTests * 2) -- ننتظر أطول عشان الخطأ ده خطير
            end
        end
    end

    -- 2. اختبار ثغرات الاقتصاد
    if #findingsTable.BusinessLogic > 0 then
        self.Logger.Warn("[Spoofer] Testing CRITICAL SEVERITY: Business Logic")
        for _, finding in ipairs(findingsTable.BusinessLogic) do
            local remote = ReplicatedStorage:FindFirstChild(finding.Remote, true)
            if remote then
                self:TestRemote(remote, "Economy", finding)
                task.wait(self.Config.DelayBetweenTests)
            end
        end
    end

    -- 3. اختبار تسريب البيانات
    if #findingsTable.DataExposure > 0 then
        self.Logger.Warn("[Spoofer] Testing HIGH SEVERITY: Data Exposure (IDOR)")
        for _, finding in ipairs(findingsTable.DataExposure) do
            local remote = ReplicatedStorage:FindFirstChild(finding.Remote, true)
            if remote then
                self:TestRemote(remote, "DataExposure", finding)
                task.wait(self.Config.DelayBetweenTests)
            end
        end
    end

    self.Logger.Info("[Spoofer] Testing Complete. Check Results table.")
end

-- دالة اختبار الريماوت الواحد
function Spoofer:TestRemote(remoteObj, category, findingInfo)
    local payloads = PayloadLibrary[category]
    if not payloads then return end

    self.Logger.Info("  -> Testing: " .. remoteObj.Name .. " (" .. category .. ")")

    for i, payload in ipairs(payloads) do
        if i > self.Config.MaxTestsPerRemote then break end -- حد أقصى لعدد المحاولات

        local success, response = pcall(function()
            -- ملاحظة هامة: الإكسيكويتورات الجديدة ممكن تمنع الإرسال لو الأنواع غلط، عشان كده الـ pcall ضروري
            if remoteObj:IsA("RemoteFunction") then
                -- الـ InvokeServer بيرجع قيمة، وهذه القيمة هي كنز الثغرة
                return remoteObj:InvokeServer(unpack(payload.Args))
            else
                remoteObj:FireServer(unpack(payload.Args))
                return "[Event Fired Successfully - No Return Value]"
            end
        end)

        -- تحليل النتيجة
        local resultStr = tostring(response)
        local isVulnerable = false

        -- إذا السيرفر رد بـ Success أو رد بيانات بدل ما يعطي Error، معناها الثغرة موجودة
        if success then
            if string.find(resultStr:lower(), "success") or string.find(resultStr:lower(), "true") or resultStr ~= "[Event Fired Successfully - No Return Value]" then
                isVulnerable = true
            end
            -- إذا رد بـ Table فيها داتا في حالة الـ Data Exposure
            if category == "DataExposure" and type(response) == "table" then
                isVulnerable = true
            end
        end

        -- تسجيل النتيجة
        local logMsg = string.format("     [%s] Payload: %s | Server Response: %s", 
            isVulnerable and "POTENTIAL VULN" or "SAFE/DENIED", 
            payload.Name, 
            string.sub(resultStr, 1, 50) .. (string.len(resultStr) > 50 and "..." or "")
        )

        if isVulnerable then
            self.Logger.Warn(logMsg) -- لون أصفر/برتقالي في الكونسل
            table.insert(self.Results, {
                Remote = remoteObj.Name,
                Payload = payload.Name,
                Response = response,
                Vulnerable = true
            })
            
            if self.Config.StopOnServerResponse then break end
        else
            self.Logger.Info(logMsg)
        end

        task.wait(self.Config.DelayBetweenTests)
    end
end

return Spoofer
