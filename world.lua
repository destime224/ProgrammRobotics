local world = {}

local emptySprite = function()
    local canvas = love.graphics.newCanvas(256, 256)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setCanvas()
    return canvas
end



local Map = {}
Map.__index = Map

function Map.new(w, h)
    local self = {}

    self.width = w
    self.height = h

    self.landscape = {}
    self.seed = 10000 * math.random()
    for y = 1, h do
        self.landscape[y] = {}
        for x = 1, w do
            if love.math.noise(self.seed+x/35, self.seed+y/35) >= 0.65 then
                self.landscape[y][x] = 1
            else
                self.landscape[y][x] = 0
            end
        end
    end

    self.entities = {}
    self.builds = {}
    -- self.worldModel = love.physics.newWorld()

    self.camera = {
        x = w/2,
        y = h/2,
        zoom = 10,
        zoomMin = 10,
        zoomMax = 100
    }

    setmetatable(self, Map)
    return self
end

function Map:getRealCameraX()
    return (game.world.width / 2) - self.camera.x * self:getRealZoom()
end

function Map:getRealCameraY()
    return (game.world.height / 2) - self.camera.y * self:getRealZoom()
end

function Map:getRealZoom()
    return self.camera.zoom * math.min(game.world.width, game.world.height) / 900
end

function Map:pairs()
    --[[
           1  2  3  4  5
        1 [] [] [] [] []
        2 [] [] [] [] []
        3 [] [] [] [] []
        4 [] [] [] [] []
        5 [] [] [] [] []

        x = (index - 1) % 5 + 1
        y = math.floor((index - 1) / 5) + 1

        we can change `index - 1` (1 - 25) to `index` (0 - 24)
    ]]
    local index = 0

    return function()
        if index >= self.width * self.height then
            return nil
        end
        local x = index % self.width + 1
        local y = math.floor(index / self.width) + 1

        index = index + 1

        return x, y, self.landscape[y][x]
    end
end



local Entity = {}
Entity.__index = Entity

function Entity.new(x, y, r, w, h, speed, sprite, tag)
    local self = {}

    self.x = x
    self.y = y
    self.rotate = r or 0

    self.walk = {}
    self.walk.x = x
    self.walk.y = y

    self.width = w or 1
    self.height = h or 1
    self.speed = speed or 1

    self.sprite = sprite or emptySprite()
    self.tag = tag

    setmetatable(self, Entity)
    return self
end

-- Generate table for interpreter enviroment
function Entity:getEnvTable()
    return tool.setReadOnly({
        walkTo = function(x, y) self:walkTo(x, y) end,
        getX = function() return self.x end,
        getY = function() return self.y end,
        getRotate = function() return self.rotate end,
        getWidth = function() return self.width end,
        getHeight = function() return self.height end,
        getSpeed = function() return self.speed end,
        getTag = function() return self.tag end
    })
end

function Entity:walkTo(x, y, rad)
    self.walk.x, self.walk.y = x, y
end



world.Map = Map
world.Entity = Entity
return world