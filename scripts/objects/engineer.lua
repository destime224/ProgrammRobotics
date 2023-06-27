local Engineer = {}
Engineer.__index = Engineer
setmetatable(Engineer, objects.Entity)

function Engineer.new(wm, x, y, r)
    local self = objects.Entity.new(wm, x, y, 0.9, 0.9, r, 1.2, sprites.entity, "engineer")

    setmetatable(self, Engineer)
    return self
end

return Engineer