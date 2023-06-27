local BuildPart = {}
BuildPart.__index = BuildPart
setmetatable(BuildPart, objects.Obstacle)

function BuildPart.new(wm, x, y, sprite, build)
    local self = objects.Obstacle.new(wm, x, y, sprite, build.name)

    self.build = build

    setmetatable(self, BuildPart)
    return self
end

return BuildPart