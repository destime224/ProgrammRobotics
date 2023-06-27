local Base = {}
Base.__index = Base
setmetatable(Base, objects.Build)

function Base.new(x, y)
    local self = objects.Build.new(
        x,
        y,
        {{sprites.build, sprites.build, sprites.build}, {sprites.build, sprites.build, sprites.build}, {sprites.build, sprites.build, sprites.build}},
        "base"
    )

    setmetatable(self, Base)
    return self
end

return Base