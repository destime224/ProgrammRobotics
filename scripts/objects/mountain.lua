local Mountain = {}
Mountain.__index = Mountain
setmetatable(Mountain, objects.Obstacle)

function Mountain.new(wm, x, y)
    local self = objects.Obstacle.new(wm, x, y, sprites.obstacle, "mountain")

    setmetatable(self, Mountain)
    return self
end

return Mountain