-- نظام الرسائل المركزي (Event Bus)
local Signals = {}
Signals.Listeners = {}

function Signals:Connect(eventName, callback)
    if not self.Listeners[eventName] then self.Listeners[eventName] = {} end
    table.insert(self.Listeners[eventName], callback)
end

function Signals:Fire(eventName, ...)
    if not self.Listeners[eventName] then return end
    for _, cb in ipairs(self.Listeners[eventName]) do
        task.spawn(function() cb(...) end) -- تشغيل غير متزامن عشان ما يلزقش
    end
end
return Signals
