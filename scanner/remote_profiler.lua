-- ==========================================
-- scanner/remote_profiler.lua
-- وظيفته: تحليل الريماوتات لاستخراج "الليدرز" (Leads) المحتملة للثغرات المنطقية
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Profiler = {}
Profiler.__index = Profiler

-- كائن لتخزين التقارير
Profiler.Findings = {
    PrivilegeEscalation = {},
    BusinessLogic = {},
    DataExposure = {},
    UnusualBehaviors = {}
}

-- كلمات مفتاحية للبحث عنها (يمكن توسيعها من config/filters.lua لاحقاً)
local Keywords = {
    Admin = {"command", "execute", "mod", "admin", "kick", "ban", "teleport", "punish"},
    Economy = {"purchase", "buy", "sell", "trade", "currency", "ammo", "cost", "price", "rebirth"},
    Data = {"getplayer", "getdata", "getstats", "getlevel", "getinventory", "getowned", "getequipped"}
}

function Profiler:Analyze()
    print("[Nemesis Profiler] Starting Deep Remote Analysis...")
    table.clear(self.Findings) -- نظف التقارير القديمة

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local nameLower = obj.Name:lower()
            local path = obj:GetFullName() -- عشان نعرف الريموت موجود فين بالظبط
            
            self:CheckForPrivilegeEscalation(obj, nameLower, path)
            self:CheckForBusinessFlaws(obj, nameLower, path)
            self:CheckForDataExposure(obj, nameLower, path)
            self:CheckForUnusualBehaviors(obj, nameLower, path)
        end
    end
    
    self:GenerateReport()
end

-- 1. فحص صلاحيات الأدمن
function Profiler:CheckForPrivilegeEscalation(obj, name, path)
    for _, kw in ipairs(Keywords.Admin) do
        if name:find(kw) then
            table.insert(self.Findings.PrivilegeEscalation, {
                Remote = obj.Name,
                Type = obj.ClassName,
                Path = path,
                Severity = "HIGH",
                Reason = "Name suggests administrative/control functionality. Verify if server checks player rank before processing."
            })
            break
        end
    end
end

-- 2. فحص المنطق التجاري والاقتصاد
function Profiler:CheckForBusinessFlaws(obj, name, path)
    -- نركز على الـ Functions لأنها غالباً بترجع قيمة (مثلاً: هل الشراء تم أم لا؟)
    if obj:IsA("RemoteFunction") then
        for _, kw in ipairs(Keywords.Economy) do
            if name:find(kw) then
                table.insert(self.Findings.BusinessLogic, {
                    Remote = obj.Name,
                    Type = obj.ClassName,
                    Path = path,
                    Severity = "CRITICAL",
                    Reason = "Economic RemoteFunction found. Vulnerable to 'Race Conditions' if fired rapidly. Also check if client can manipulate price arguments."
                })
                break
            end
        end
    elseif obj:IsA("RemoteEvent") then
        for _, kw in ipairs(Keywords.Economy) do
            if name:find(kw) then
                table.insert(self.Findings.BusinessLogic, {
                    Remote = obj.Name,
                    Type = obj.ClassName,
                    Path = path,
                    Severity = "MEDIUM",
                    Reason = "Economic event found. Check if server validates player funds BEFORE executing the action."
                })
                break
            end
        end
    end
end

-- 3. فحص تسريب البيانات
function Profiler:CheckForDataExposure(obj, name, path)
    -- الـ Functions هي اللي بترجع داتا، الـ Events بتستقبل
    if obj:IsA("RemoteFunction") then
        for _, kw in ipairs(Keywords.Data) do
            if name:find(kw) then
                table.insert(self.Findings.DataExposure, {
                    Remote = obj.Name,
                    Type = obj.ClassName,
                    Path = path,
                    Severity = "HIGH",
                    Reason = "Data retrieval function found. Test if passing another player's UserID returns their private data (IDOR Vulnerability)."
                })
                break
            end
        end
    end
end

-- 4. سلوكيات غير معتادة (تحليل إضافي)
function Profiler:CheckForUnusualBehaviors(obj, name, path)
    -- مثال: ريماوت اسمه "CommunicateHead" (اللي لقيناه في الماب بتاعتك) ده شكله غريب ومشتبه فيه
    if name:find("head") and not name:find("communicate") then
        -- طبيعي
    elseif name:find("communicatehead") then
         table.insert(self.Findings.UnusualBehaviors, {
            Remote = obj.Name,
            Type = obj.ClassName,
            Path = path,
            Severity = "INFO",
            Reason = "Unusual naming convention ('CommunicateHead'). Might be related to headshot registration, decapitation, or custom hitbox logic. Requires manual tracing."
        })
    end
end

-- طباعة التقرير النهائي في الكونسل
function Profiler:GenerateReport()
    print("\n=========================================")
    print("       NEMESIS VULNERABILITY REPORT       ")
    print("=========================================")
    
    local function PrintCategory(categoryName, findings)
        print("\n[" .. categoryName .. "]")
        if #findings == 0 then
            print("  - No potential vulnerabilities found.")
            return
        end
        for i, finding in ipairs(findings) do
            print(string.format("  [%s] %s (%s)", finding.Severity, finding.Remote, finding.Type))
            print("    Path: %s", finding.Path)
            print("    -> %s", finding.Reason)
        end
    end

    PrintCategory("PRIVILEGE ESCALATION", self.Findings.PrivilegeEscalation)
    PrintCategory("BUSINESS LOGIC FLAWS", self.Findings.BusinessLogic)
    PrintCategory("DATA EXPOSURE", self.Findings.DataExposure)
    PrintCategory("UNUSUAL BEHAVIORS", self.Findings.UnusualBehaviors)
    
    print("\n=========================================\n")
end

return Profiler
