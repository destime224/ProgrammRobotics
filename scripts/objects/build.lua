local Build = {}
Build.__index = Build

function Build.new(x, y, sprites, name)
    local self = {}

    self.x = math.floor(x)
    self.y = math.floor(y)
    self.sprites = sprites or {{sprites.build}}
    self.parts = {}
    self.name = name
    self.type = "build"

    setmetatable(self, Build)
    return self
end

Build.update = tool.NONE

function Build:getEnv()
    return game.SandBox.setReadOnly({
        getX = function() return self.x end,
        getY = function() return self.y end,
        getCenteredX = function() return self:getCenteredX() end,
        getCenteredY = function() return self:getCenteredY() end,
        getWidth = function() return self:getWidth() end,
        getHeight = function() return self:getHeight() end,
        getName = function() return self.name end,
        getType = function() return self.type end
    })
end

function Build:getWidth()
    local max = 0
    for _, t in ipairs(self.sprites) do
        max = math.max(max, #t)
    end
    return max
end

function Build:getHeight()
    return #self.sprites
end

function Build:getCenteredX()
    return self.x + self:getWidth() / 2
end

function Build:getCenteredY()
    return self.y + self:getHeight() / 2
end

return Build