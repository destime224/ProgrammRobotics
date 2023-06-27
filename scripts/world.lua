local World = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    fps = true,

    cursor = {
        x = 0,
        y = 0
    },

    map = nil
}

function World:update(dt)
    self.x = 0
    self.y = 0
    self.width = wHeight
    self.height = wHeight

    -- World updating
    if self.map then
        if tool.checkInRectangle(love.mouse.getX(), love.mouse.getY(), self.x, self.y, self.width, self.height) then
            self.cursor.x = love.mouse.getX()
            self.cursor.y = love.mouse.getY()
        end

        if not game.debug.ignoreEdge then
            self.map.camera.x = math.min(self.map.width - self.width / 2 / self:getRealZoom() + 1, math.max(self.width / 2 / self:getRealZoom() + 1, self.map.camera.x))
            self.map.camera.y = math.min(self.map.height - self.height / 2 / self:getRealZoom() + 1, math.max(self.height / 2 / self:getRealZoom() + 1, self.map.camera.y))
        end

        self.map:update(dt)
    end
end

function World:show()
    love.graphics.push('all')
    tool.drawFrame(self.x, self.y, self.width, self.height, {love.math.colorFromBytes(166, 172, 204)}, {0, 0, 0, 0})

    if self.map then
        love.graphics.setScissor(self.x, self.y, self.width, self.height)
        love.graphics.setColor(1, 1, 1)
 
        local batch = love.graphics.newSpriteBatch(spritesheet)
        local shapes = {}
        for x, y, obs in self.map:pairs() do
            if obs then
                if obs.sprite then
                    local dx = self.map.camera.x - x
                    local dy = self.map.camera.y - y
                    if dx == tool.clamp(dx, self.width / 2 / self:getRealZoom() + 1, -self.width / 2 / self:getRealZoom()) and dy == tool.clamp(dy, self.height / 2 / self:getRealZoom() + 1, -self.height / 2 / self:getRealZoom()) then
                        obs:show(batch, self)
                        if game.debug.drawShapes and type(obs.shape.getPoints) == "function" then
                            local points = {obs.body:getWorldPoints(obs.body:getFixtures()[1]:getShape():getPoints())}
                            for i = 1, #points, 2 do
                                points[i] = points[i] * self:getRealZoom() + self:getRealCameraX()
                                points[i + 1] = points[i + 1] * self:getRealZoom() + self:getRealCameraY()
                            end
                            table.insert(shapes, points)
                        end
                    end
                end
            end
        end

        for _, entity in ipairs(self.map.entities) do
            if entity.type == "entity" then
                local dx = self.map.camera.x - entity.body:getX()
                local dy = self.map.camera.y - entity.body:getY()
                if dx == tool.clamp(dx, self.width / 2 / self:getRealZoom() + entity.width, -self.width / 2 / self:getRealZoom() - entity.width) and dy == tool.clamp(dy, self.height / 2 / self:getRealZoom() + entity.height, -self.height / 2 / self:getRealZoom() - entity.height) then
                    entity:show(batch, self)
                    if game.debug.drawShapes and type(entity.shape.getPoints) == "function" then
                        local points = {entity.body:getWorldPoints(entity.body:getFixtures()[1]:getShape():getPoints())}
                        for i = 1, #points, 2 do
                            points[i] = points[i] * self:getRealZoom() + self:getRealCameraX()
                            points[i + 1] = points[i + 1] * self:getRealZoom() + self:getRealCameraY()
                        end
                        table.insert(shapes, points)
                    end
                end
            end
        end
        love.graphics.draw(batch)

        for _, points in ipairs(shapes) do
            love.graphics.polygon("line", points)
        end

        if game.debug.infoPanel then
            love.graphics.setColor(1, 1, 1)
            local cursorPos = {self:getPositionByCursor()}
            love.graphics.print(string.format(
                "x: %s\ny: %s\ncamera.x: %s\ncamera.y: %s\nzoom: %s\nrealZoom: %s",
                cursorPos[1],
                cursorPos[2],
                self.map.camera.x,
                self.map.camera.y,
                self.map.camera.zoom,
                self:getRealZoom()))
        end
    end

    if self.fps then
        local fps = string.format("fps: " .. tostring(love.timer.getFPS()))
        love.graphics.setFont(fonts.ubuntu.bold)
        love.graphics.setColor(0, 0.8, 0)
        love.graphics.print(fps, self.x + self.width - fonts.ubuntu.regular:getWidth(fps) * 0.7, self.y, 0, 0.65)
    end

    if game.debug.worldCenter then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setPointSize(5)
        love.graphics.points(self.x + self.width / 2, self.y + self.height / 2)
    end
    love.graphics.pop()
end

function World:mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) and self.map then
        self.map.camera.x = self.map.camera.x - dx / self:getRealZoom()
        self.map.camera.y = self.map.camera.y - dy / self:getRealZoom()
    end
end

function World:wheelmoved(x, y)
    if self.map then
        self.map.camera.zoom = math.min(self.map.camera.zoomMax, math.max(self.map.camera.zoomMin, self.map.camera.zoom * 1.25 ^ y))
    end
end

function World:createMap(w, h)
    local map = objects.Map.new(w, h)
    self.map = map
end

function World:addEntity(entity)
    if self.map then
        table.insert(self.map.entities, entity)
    end
end

function World:addBuild(build, base)
    base = base or false
    if self.map then
        table.insert(self.map.builds, build)
    end
end

function World:getRealCameraX()
    if self.map then
        return (self.width / 2) - self.map.camera.x * self:getRealZoom()
    end
    return 0
end

function World:getRealCameraY()
    if self.map then
        return (self.height / 2) - self.map.camera.y * self:getRealZoom()
    end
    return 0
end

function World:getRealZoom()
    if self.map then
        return self.map.camera.zoom * math.min(self.width, self.height) / 900
    end
    return 0
end

function World:getPositionByCursor()
    if self.map then
        return
            (self.cursor.x - self.width/2) / self:getRealZoom() + self.map.camera.x,
            (self.cursor.y - self.height/2) / self:getRealZoom() + self.map.camera.y
    end
    return 0, 0
end

return World