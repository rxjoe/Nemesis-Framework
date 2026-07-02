local Mapper = {}
function Mapper:Analyze(character)
    local profile = {Type = "Unknown", Parts = {}}
    if character:FindFirstChild("UpperTorso") then
        profile.Type = "R15"
        profile.Target = character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso")
    elseif character:FindFirstChild("Torso") then
        profile.Type = "R6"
        profile.Target = character:FindFirstChild("Head") or character:FindFirstChild("Torso")
    end
    
    for _, p in ipairs(character:GetDescendants()) do
        if p:IsA("BasePart") and not p:IsA("Accessory") then
            table.insert(profile.Parts, p.Name)
        end
    end
    return profile
end
return Mapper
