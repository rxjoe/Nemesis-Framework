local MemScanner = {}
function MemScanner:Scan()
    local results = {}
    if getnilinstances then
        for _, obj in ipairs(getnilinstances()) do
            if obj:IsA("ModuleScript") or obj:IsA("RemoteEvent") then
                table.insert(results, {Name = obj.Name, Class = obj.ClassName})
            end
        end
    end
    return results
end
return MemScanner
