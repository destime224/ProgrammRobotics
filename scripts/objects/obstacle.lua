local Obstacle = {}
Obstacle.__index = Obstacle

function Obstacle.new(wm, x, y, sprite, name)
    local self = {}

    self.body = love.physics.newBody(wm, math.floor(x), math.floor(y), "static")
    self.fixture = love.physics.newFixture(self.body, love.physics.newPolygonShape(0, 0, 1, 0, 0, 1, 1, 1))
    self.shapeSprite = sprites.shape.rectangle
    self.sprite = sprite or sprite.obstacle
    self.type = "obstacle"
    self.name = name

    setmetatable(self, Obstacle)
    return self
end

function Obstacle:show(batch, worldUI)
    local _, _, w, h = self.sprite:getViewport()
    batch:add(
        self.sprite,
        self.body:getX() * worldUI:getRealZoom() + worldUI:getRealCameraX(),
        self.body:getY() * worldUI:getRealZoom() + worldUI:getRealCameraY(),
        0,
        worldUI:getRealZoom() / (w - 1),
        worldUI:getRealZoom() / (h - 1)
    )
end

return Obstacle