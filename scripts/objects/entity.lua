local Entity = {}
Entity.__index = Entity

function Entity.new(wm, x, y, w, h, r, speed, sprite, name)
    local self = {}

    self.body = love.physics.newBody(wm, x, y, "dynamic")
    self.fixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(w + 0.1, h + 0.1))

    self.walk = {}

    self.width = w
    self.height = h
    self.body:setAngle(-r)
    self.speed = speed
    self.shapeSprite = sprites.shape.rectangle
    self.sprite = sprite or sprites.entity

    self.name = name
    self.type = "entity"

    setmetatable(self, Entity)
    return self
end

function Entity:update(dt)
    local dx, dy = 0, 0
    self.walk.timePass = self.walk.timePass or 0

    if self.walk.timePass > (self.walk.time or 8) then
        self.walk = {}
    end

    if self.walk.x then
        dx = self.walk.x - self.body:getX()
        if dx < 0.1 and dx > -0.1 then
            self.walk.x = nil
        end
    end
    if self.walk.y then
        dy = self.walk.y - self.body:getY()
        if dy < 0.1 and dy > -0.1 then
            self.walk.y = nil
        end
    end

    if not self.walk.x and self.walk.y then
        self.walk.time = nil
    end

    local angle = math.atan2(dy, dx)
    local cos = dx ~= 0 and math.cos(angle) or 0
    local sin = dy ~= 0 and math.sin(angle) or 0

    if cos ~= 0 and sin ~= 0 then
        self.body:setAngle(angle)
    end

    self.body:setLinearVelocity(self.speed * cos, self.speed * sin)
    if self.walk.time then
        self.walk.timePass = self.walk.timePass + dt
    end
end

function Entity:show(batch, worldUI)
    local _, _, w, h = self.sprite:getViewport()
    batch:add(
        self.sprite,
        self.body:getX() * worldUI:getRealZoom() + worldUI:getRealCameraX(),
        self.body:getY() * worldUI:getRealZoom() + worldUI:getRealCameraY(),
        self.body:getAngle(),
        worldUI:getRealZoom() / w,
        worldUI:getRealZoom() / h,
        w / 2,
        h / 2
    )
end

function Entity:getEnv()
    return game.SandBox.setReadOnly({
        getX = function() return self:getCenteredX() end,
        getY = function() return self:getCenteredY() end,
        getWidth = function() return self.width end,
        getHeight = function() return self.height end,
        getRotate = function() return self.rotate end,
        getSpeed = function() return self.speed end,
        getName = function() return self.name end,
        getType = function() return self.type end,
        walkTo = function(x, y) self:walkTo(x, y) end,
        walkToVector = function(dx, dy) self:walkToVector(dx, dy) end,
        rotate = function(r) self:rotate(r) end
    })
end

function Entity:getCenteredX()
    return self.body:getX() + self.width / 2
end

function Entity:getCenteredY()
    return self.body:getY() + self.height / 2
end

function Entity:rotate(r)
    self.body:setAngle(-r)
end

function Entity:walkTo(x, y, time)
    self.walk.x, self.walk.y = x, y
    self.walk.time =  (time or 8)
    self.walk.timePass = 0
end

function Entity:walkToVector(dx, dy, time)
    self:walkTo(self.body:getX() + dx, self.body:getY() + dy, time)
end

return Entity