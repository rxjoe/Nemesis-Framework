local Players = game:GetService("Players")

local Mapper = {}
Mapper.__index = Mapper

Mapper.ScannedProfiles = {}

function Mapper:Analyze(character)
    if not character then
        character = Players.LocalPlayer and Players.LocalPlayer.Character
        if not character then
            return {Type = "NoCharacter", Parts = {}, Target = nil}
        end
    end

    local profile = {
        Type = "Unknown",
        Parts = {},
        Target = nil,
        BonePositions = {},
        SpecialParts = {}
    }

    if character:FindFirstChild("UpperTorso") then
        profile.Type = "R15"
        profile.Target = character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso")
        for _, boneName in ipairs({"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
            local part = character:FindFirstChild(boneName)
            if part then
                profile.BonePositions[boneName] = part.Position
            end
        end
    elseif character:FindFirstChild("Torso") then
        profile.Type = "R6"
        profile.Target = character:FindFirstChild("Head") or character:FindFirstChild("Torso")
        for _, boneName in ipairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
            local part = character:FindFirstChild(boneName)
            if part then
                profile.BonePositions[boneName] = part.Position
            end
        end
    else
        profile.Type = "Custom"
        profile.Target = character:FindFirstChildWhichIsA("BasePart")
        for _, p in ipairs(character:GetChildren()) do
            if p:IsA("BasePart") then
                table.insert(profile.SpecialParts, {Name = p.Name, Position = p.Position, Size = p.Size})
            end
        end
    end

    for _, p in ipairs(character:GetDescendants()) do
        if p:IsA("BasePart") and not p:IsA("Accessory") then
            table.insert(profile.Parts, {
                Name = p.Name,
                Class = p.ClassName,
                Size = p.Size,
                Position = p.Position,
                Mass = p:IsA("Part") and p.Mass or nil
            })
        end
    end

    profile.TotalParts = #profile.Parts
    profile.AveragePartSize = Vector3.new(0, 0, 0)
    if #profile.Parts > 0 then
        local sum = Vector3.new(0, 0, 0)
        for _, p in ipairs(profile.Parts) do
            sum = sum + p.Size
        end
        profile.AveragePartSize = sum / #profile.Parts
    end

    table.insert(self.ScannedProfiles, profile)
    return profile
end

function Mapper:GetHumanoid()
    local player = Players.LocalPlayer
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChildWhichIsA("Humanoid")
end

function Mapper:DetectRigType(character)
    if character:FindFirstChild("UpperTorso") then return "R15" end
    if character:FindFirstChild("Torso") then return "R6" end
    return "Custom"
end

function Mapper:FindHead(character)
    local head = character:FindFirstChild("Head")
    if not head then
        for _, p in ipairs(character:GetChildren()) do
            if p:IsA("BasePart") and (p.Name:lower():find("head") or p.Size.Y > 1) then
                head = p
                break
            end
        end
    end
    return head
end

function Mapper:GetCharacterBounds(character)
    if not character then return nil end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if root then return root.Size end
    end
    local parts = {}
    for _, p in ipairs(character:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(parts, p) end
    end
    if #parts == 0 then return Vector3.new(2, 2, 1) end
    local min, max = parts[1].Position, parts[1].Position
    for _, p in ipairs(parts) do
        min = Vector3.new(math.min(min.X, p.Position.X), math.min(min.Y, p.Position.Y), math.min(min.Z, p.Position.Z))
        max = Vector3.new(math.max(max.X, p.Position.X), math.max(max.Y, p.Position.Y), math.max(max.Z, p.Position.Z))
    end
    return max - min
end

return Mapper