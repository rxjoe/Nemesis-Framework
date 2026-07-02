local Physics = {}
function Physics:Pull(target, force)
    if target and target.AssemblyLinearVelocity then
        target.AssemblyLinearVelocity = force
    end
end
return Physics
