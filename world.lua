local world = {}

local emptyEntitySprite = (function ()
    local canvas = love.graphics.newCanvas(256, 256)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(7)
    love.graphics.line(25, 128, 215, 128)
    love.graphics.polygon("fill", 231, 128, 190, 169, 190, 87)

    love.graphics.setCanvas()
    return canvas
end)()

local emptyBuildSprite = (function ()
    local canvas = love.graphics.newCanvas(256, 256)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.1, 0, 0.1, 1)
    love.graphics.setCanvas()
    return canvas
end)()



local Map = {}
Map.__index = Map

function Map.new(w, h)
    local self = {}

    self.width = w
    self.height = h
    self.base = world.Base.new(
        tool.clamp(love.math.randomNormal(w*0.8/6, w/2), w*0.9, w*0.1),
        tool.clamp(love.math.randomNormal(h*0.8/6, h/2), h*0.9, h*0.1)
    )
    local angel = math.random(0, 2 * math.pi)
    self.engineer = world.Engineer.new(math.cos(angel) * 5 + self.base.x, math.sin(angel) * 5 + self.base.y, angel)

    self.landscape = {}
    self.normalHeight = .65
    self.scale = {
        x = .02,
        y = .03
    }
    self.seed = 1^4 * love.math.random()

    for y = 1, h do
        self.landscape[y] = {}
        for x = 1, w do
            if love.math.noise(x * self.scale.x + self.seed, y * self.scale.y + self.seed) >= self.normalHeight and tool.hypotenuse(self.base.x - x, self.base.y - y) >= 15 then
                self.landscape[y][x] = 1
            else
                self.landscape[y][x] = 0
            end
        end
    end

    self.entities = {self.engineer}
    self.builds = {self.base}
    -- self.worldModel = love.physics.newWorld()

    self.camera = {
        x = self.base.x,
        y = self.base.y,
        zoom = 20,
        zoomMin = 10,
        zoomMax = 100
    }

    setmetatable(self, Map)
    return self
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

function Map:getTile(x, y)
    x = math.floor(x+0.5)
    y = math.floor(y+0.5)
    if self.landscape[y] then
        return self.landscape[y][x]
    else
        return nil
    end
end

-- A* algorithm.
-- Returns table with tile coordinates.
function Map:aStar(sx, sy, ex, ey)
    local Node = {}
    Node.__index = Node

    function Node.new(x, y)
        local Self = {}

        Self.x = x
        Self.y = y
        Self.f = 0
        Self.g = 0
        Self.h = 0
        Self.parent = nil

        setmetatable(Self, Node)
        return Self
    end

    function Node.__eq(a, b)
        return a.x == b.x and a.y == b.y
    end

    function Node.__lt(a, b)
        return a.f < b.f
    end

    local start = Node.new(sx, sy)
    local end_ = Node.new(ex, ey)

    local closed = {}
    local open = {start}

    local i = 1
    while #open ~= 0 do
        local currentN = table.remove(open, 1)

        if currentN == end_ then
            local path = {}
            while currentN ~= nil do
                table.insert(path, 1, {currentN.x, currentN.y})
                currentN = currentN.parent
            end
            return tool.deepCopy(path)
        end

        table.insert(closed, currentN)

        local neighbors = {}
        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    local x, y = currentN.x + dx, currentN.y + dy
                    if self:getTile(x, y) ~= nil and self:getTile(x, y) ~= 1 then
                        table.insert(neighbors, Node.new(x, y))
                    end
                end
            end
        end

        for _, n in ipairs(neighbors) do
            local overlap = false
            for _, c in ipairs(closed) do
                if n == c then
                    overlap = true
                end
            end

            if not overlap then
                local newG = currentN.g + 1

                for _, o in ipairs(open) do
                    if n == o then
                        overlap = true
                    end
                end

                if overlap then
                    if newG < n.g then
                        n.g = newG
                        n.h = tool.hypotenuse(end_.x - n.x, end_.y - n.y)
                        n.f = n.g + n.h
                        n.parent = currentN
                    end
                else
                    n.g = newG
                    n.h = tool.hypotenuse(end_.x - n.x, end_.y - n.y)
                    n.f = n.g + n.h
                    n.parent = currentN
                    table.insert(open, n)
                end
            end
        end
        i = i + 1
        table.sort(open)
    end
    return nil
end



local Entity = {}
Entity.__index = Entity

function Entity.new(x, y, w, h, r, speed, sprite, ty)
    local self = {}

    self.x = x
    self.y = y
    self.rotate = r or 0

    self.walk = {}
    self.walk.walkTo = false
    self.walk.x = x
    self.walk.y = y
    self.walk.rotate = r

    self.width = w or 1
    self.height = h or 1
    self.speed = speed or 1
    self.rSpeed = math.rad(self.speed * 10^2)

    self.sprite = sprite or emptyEntitySprite
    self.type = ty

    setmetatable(self, Entity)
    return self
end

-- Generates table for interpreter enviroment
function Entity:getEnvTable()
    return tool.setReadOnly({
        walkTo = function(x, y) self:walkTo(x, y) end,
        getX = function() return self.x end,
        getY = function() return self.y end,
        getRotate = function() return self.rotate end,
        getWidth = function() return self.width end,
        getHeight = function() return self.height end,
        getSpeed = function() return self.speed end,
        getType = function() return self.type end
    })
end

function Entity:walkTo(x, y)
    self.walk.x, self.walk.y = x, y
    self.walk.rotate = math.atan2(y - self.y, x - self.x) % (2 * math.pi)
    self.walk.walkTo = true
end



local Engineer = {}
Engineer.__index = Engineer
setmetatable(Engineer, Entity)

function Engineer.new(x, y, r)
    local self = Entity.new(x, y, 0.75, 0.75, r, 1.5, nil, "engineer")

    setmetatable(self, Engineer)
    return self
end



local Build = {}
Build.__index = Build

function Build.new(x, y, w, h, r, sprite, ty)
    local self = {}

    local mx, _ = math.modf(x)
    local my, _ = math.modf(y)

    self.x = mx + (w % 2 == 1 and 0 or 0.5)
    self.y = my + (h % 2 == 1 and 0 or 0.5)
    self.rotate = math.floor(r / (2 * math.pi)) * (2 * math.pi) -- ???
    self.width = w
    self.height = h
    self.sprite = sprite or emptyBuildSprite
    self.type = ty

    setmetatable(self, Build)
    return self
end

function Build:getEnvTable()
    return tool.setReadOnly({
        getX = function() return self.x end,
        getY = function() return self.y end,
        getRotate = function() return self.rotate end,
        getWidth = function() return self.width end,
        getHeight = function() return self.height end
    })
end



local Base = {}
Base.__index = Base
setmetatable(Base, Build)

function Base.new(x, y, r)
    r = r or 0
    local self = Build.new(x, y, 3, 3, r, nil, "base")

    setmetatable(self, Base)
    return self
end



world.Map = Map

world.Entity = Entity
world.Engineer = Engineer

world.Build = Build
world.Base = Base
return world