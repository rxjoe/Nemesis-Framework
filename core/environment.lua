local Env = {}
function Env:Init()
    if not getgenv().Nemesis then
        getgenv().Nemesis = {}
    end
    -- فحص إمكانية الهوك (مهم للأمان)
    getgenv().Nemesis.CanHook = (hookmetamethod ~= nil)
end
return Env
