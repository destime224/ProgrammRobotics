local Map = {}
Map.__index = Map

function Map.new(w, h)
    local self = {}
    self.worldModel = love.physics.newWorld()


    self.width = w
    self.height = h
    self.base = objects.Base.new(
        tool.clamp(love.math.randomNormal(w*0.8/6, w/2), w*0.9, w*0.1),
        tool.clamp(love.math.randomNormal(h*0.8/6, h/2), h*0.9, h*0.1)
    )

    local angel = love.math.random(0, 2 * math.pi * 10^4) / 10^4
    self.engineer = objects.Engineer.new(self.worldModel, math.cos(angel) * 5 + self.base:getCenteredX(), math.sin(angel) * 5 + self.base:getCenteredY(), -angel)

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
            if love.math.noise(x * self.scale.x + self.seed, y * self.scale.y + self.seed) >= self.normalHeight and tool.hypotenuse(self.base:getCenteredX() - x, self.base:getCenteredY() - y) >= 15 then
                self.landscape[y][x] = objects.Mountain.new(self.worldModel, x, y)
            end
        end
    end

    self.entities = {}
    self.builds = {}

    game.SandBox.overrideElementOfReadOnly(game.env, "world", Map.getEnv(self))

    Map.addBuild(self, self.base, "base")
    Map.addEntity(self, self.engineer, "engineer")

    self.camera = {
        x = self.base:getCenteredX(),
        y = self.base:getCenteredY(),
        zoom = 20,
        zoomMin = 10,
        zoomMax = 100
    }

    setmetatable(self, Map)
    return self
end

function Map:update(dt)
    self.worldModel:update(dt)

    for _, build in ipairs(self.builds) do
        if type(build.update) == "function" then
            build:update(dt)
        end
    end

    for _, entity in ipairs(self.entities) do
        if type(entity.update) == "function" then
            entity:update(dt)
        end
    end
end

function Map:getEnv()
    return game.SandBox.setReadOnly({
        getWidth = function() return self.width end,
        getHeight = function() return self.height end,
        getSeed = function() return self.seed end
    })
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
    if type(self.landscape[y]) == "table" then
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
                    if x > 0 and x <= self.width and y > 0 and y <= self.height and self:getTile(x, y) == nil then
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

function Map:addBuild(build, name)
    if build.type ~= "build" then return end

    for y = 1, build:getHeight() do
        for x = 1, build:getWidth() do
            local rx = build.x + x - 1
            local ry = build.y + y - 1
            if self.landscape[ry][rx] ~= nil or rx > self.width or ry > self.height then return end
        end
    end

    for y = 1, build:getHeight() do
        for x = 1, build:getWidth() do
            local rx = build.x + x - 1
            local ry = build.y + y - 1
            local sprite = build.sprites[y][x]
            if sprite then
                local part = objects.BuildPart.new(self.worldModel, rx, ry, sprite, build)
                self.landscape[ry][rx] = part
                table.insert(build.parts, part)
            end
        end
    end

    build.map = self
    table.insert(self.builds, build)
    if type(name) == "string" then
        game.SandBox.overrideElementOfReadOnly(game.env.world, name, build:getEnv())
    end
    return true
end

function Map:addEntity(entity, name)
    if entity.type ~= "entity" or self.landscape[math.floor(entity.body:getY())][math.floor(entity.body:getX())] ~= nil then return end

    entity.map = self
    table.insert(self.entities, entity)
    if type(name) == "string" then
        game.SandBox.overrideElementOfReadOnly(game.env.world, name, entity:getEnv())
    end
end

return Map