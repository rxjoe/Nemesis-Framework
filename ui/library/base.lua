local Base = {}
function Base:Create(classType, properties)
    local inst = Instance.new(classType)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    return inst
end
function Base:AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end
function Base:AddStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(255,255,255)
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end
return Base
