local Logger = {}
function Logger:Init()
    self.Prefix = "[NEMESIS]"
end
function Logger:Info(msg) print(self.Prefix, "[INFO]", msg) end
function Logger:Warn(msg) warn(self.Prefix, "[WARN]", msg) end
function Logger:Error(msg) error(self.Prefix, "[ERROR]", msg) end
return Logger
