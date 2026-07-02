local Hitbox = {}
Hitbox.Active = {}
function Hitbox:Toggle(state, profile, size)
    -- كودHitbox المعتمد على الـ profile اللي يجي من StructMapper
    -- (مبسط لهيكل المشروع)
    print("Hitbox Toggled:", state, "Target:", profile.Target and profile.Target.Name)
end
return Hitbox
