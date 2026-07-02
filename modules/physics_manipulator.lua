local Physics = {}
Physics.__index = Physics

Physics.Config = {
    MaxForce = 500,
    SmoothPull = true,
    AntiGravity = false
}

Physics.ActiveEffects = {}

function Physics:Pull(target, force)
    if not target then return end

    if target:IsA("BasePart") and target.AssemblyLinearVelocity then
        if self.Config.SmoothPull then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = force or Vector3.new(0, 50, 0)
            bv.MaxForce = Vector3.new(self.Config.MaxForce, self.Config.MaxForce, self.Config.MaxForce)
            bv.P = math.huge
            bv.Parent = target
            table.insert(self.ActiveEffects, bv)
            task.delay(0.5, function()
                if bv and bv.Parent then bv:Destroy() end
            end)
        else
            target.AssemblyLinearVelocity = force or Vector3.new(0, 50, 0)
        end
    end
end

function Physics:Push(target, force)
    if not target or not target:IsA("BasePart") then return end
    if target.AssemblyLinearVelocity then
        target.AssemblyLinearVelocity = force or Vector3.new(0, -50, 0)
    end
end

function Physics:Attract(targets, originPoint, strength)
    for _, target in ipairs(targets) do
        if target:IsA("BasePart") then
            local direction = (originPoint - target.Position).Unit
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = direction * (strength or 100)
            bv.MaxForce = Vector3.new(5000, 5000, 5000)
            bv.P = math.huge
            bv.Parent = target
            table.insert(self.ActiveEffects, bv)
            task.delay(1, function()
                if bv and bv.Parent then pcall(function() bv:Destroy() end) end
            end)
        end
    end
end

function Physics:Repel(targets, originPoint, strength)
    for _, target in ipairs(targets) do
        if target:IsA("BasePart") then
            local direction = (target.Position - originPoint).Unit
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = direction * (strength or 100)
            bv.MaxForce = Vector3.new(5000, 5000, 5000)
            bv.P = math.huge
            bv.Parent = target
            table.insert(self.ActiveEffects, bv)
            task.delay(1, function()
                if bv and bv.Parent then pcall(function() bv:Destroy() end) end
            end)
        end
    end
end

function Physics:Float(target, height)
    if not target then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, height or 10, 0)
    bv.MaxForce = Vector3.new(0, self.Config.MaxForce, 0)
    bv.P = math.huge
    bv.Parent = target
    table.insert(self.ActiveEffects, bv)
    return bv
end

function Physics:Stop(target)
    if target and target:IsA("BasePart") then
        target.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        target.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

function Physics:Cleanup()
    for _, effect in ipairs(self.ActiveEffects) do
        pcall(function() effect:Destroy() end)
    end
    self.ActiveEffects = {}
end

function Physics:SetGravity(part, enabled)
    if not part then return end
    if enabled == false then
        local bf = Instance.new("BodyForce")
        bf.Force = Vector3.new(0, part:GetMass() * game.Workspace.Gravity, 0)
        bf.Parent = part
        table.insert(self.ActiveEffects, bf)
    end
end

return Physics