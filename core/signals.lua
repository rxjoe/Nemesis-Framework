local Signals = {}
Signals.__index = Signals

Signals.Listeners = {}
Signals.History = {}
Signals.MaxHistory = 100

function Signals:Connect(eventName, callback)
    if not self.Listeners[eventName] then self.Listeners[eventName] = {} end
    table.insert(self.Listeners[eventName], callback)
    local id = #self.Listeners[eventName]
    return {
        Disconnect = function()
            self.Listeners[eventName][id] = nil
        end,
        Id = id,
        Event = eventName
    }
end

function Signals:Fire(eventName, ...)
    if not self.Listeners[eventName] then return end

    table.insert(self.History, 1, {Event = eventName, Time = tick(), Args = {...}})
    if #self.History > self.MaxHistory then table.remove(self.History) end

    for _, cb in ipairs(self.Listeners[eventName]) do
        if cb then
            task.spawn(function()
                local ok, err = pcall(cb, ...)
                if not ok then
                    warn("[Nemesis Signals] Error in event '" .. eventName .. "': " .. tostring(err))
                end
            end)
        end
    end
end

function Signals:Once(eventName, callback)
    local connection
    connection = self:Connect(eventName, function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signals:RemoveAll(eventName)
    if eventName then
        self.Listeners[eventName] = {}
    else
        for k in pairs(self.Listeners) do self.Listeners[k] = {} end
    end
end

return Signals