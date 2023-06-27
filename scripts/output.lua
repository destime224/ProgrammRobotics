local Output = {
    font = fonts.ubuntu.regular,

    x = 0,
    y = 0,
    width = 0,
    height = 0,

    --[[This line is just a hack
    
    Method `Font.getWrap` works wrong when is called in function `love.load`
    So i cannot use `game.output:credits()` in `love.load`]]
    history = {{{1, 1, 1}, "ProgrammRobotics ".. GameV .." by DarkDrawKill"}, {{1, 1, 1}, _VERSION}},
    wheel = {
        offset = 0,
        speed = 20
    }
}

function Output:update()
    self.x = wHeight
    self.y = 0
    self.width = wWidth - wHeight
    self.height = wHeight - self.font:getHeight()-10
end

function Output:show()
    love.graphics.push('all')
    love.graphics.setFont(self.font)
    tool.drawFrame(self.x, self.y, self.width, self.height)

    love.graphics.setScissor(self:getRealTextX(), self.y, self:getRealTextWidth(), self.height)

    love.graphics.setColor(1, 1, 1)

    local text = {}
    for i, t in ipairs(self.history) do
        local suffix = i == #self.history and "" or "\n"
        table.insert(text, t[1])
        table.insert(text, t[2] .. suffix)
    end
    love.graphics.print(text, self:getRealTextX(), self.y - self.wheel.offset)
    love.graphics.pop()
end

function Output:wheelmoved(x, y)
    if self:getHistoryHeight() > self.height then
        self.wheel.offset = math.min(self:getHistoryHeight() - self.height + 4, math.max(0, self.wheel.offset - y * self.wheel.speed))
    end
end

-- print the text
function Output:add(...)
    local args = {...}
    if #args == 0 then
        return
    end

    local color = {1, 1, 1}
    if type(args[1]) == "table" then
        color = table.remove(args, 1)
    end

    local text = ""
    for i, t in ipairs(args) do
        xpcall(function() text = text .. tostring(t) .. " " end, function(err) print("Element " .. i .. "can't be string") end)
    end

    local _, wrText = self.font:getWrap(text, self:getRealTextWidth())

    for _, t in ipairs(wrText) do
        table.insert(self.history, {color, t})
        if #self.history > 1000 then
            table.remove(self.history, 1)
        end
    end

    if self:getHistoryHeight() > self.height then
        self.wheel.offset = self:getHistoryHeight() - self.height + 4
    end
end

function Output:print(...)
    self:add({1, 1, 1}, ...)
end

function Output:warning(...)
    self:add({0.9, 0.9, 0}, ...)
end

function Output:error(msg)
    self:add({0.9, 0, 0}, "Error: " .. msg)
end

-- clear Output
function Output:clear()
    self.history = {}
    self.wheel.offset = 0
end

function Output:credits()
    self:print(string.format("ProgrammRobotics %s by DarkDrawKill\n%s", GameV, _VERSION))
end

-- "print(1, 2, 3)" => ">>> print(1, 2, 3)"
function Output:registrateCommand(command)
    -- There is the nobreak space (U+0160 or 255 in ASCII)
    command = ">>> " .. table.concat(command, "\n")
    self:print(command)
end

function Output:getRealTextX()
    return game.console.getRealTextX(self)
end

function Output:getRealTextWidth()
    return game.console.getRealTextWidth(self)
end

-- get history height in pixels
function Output:getHistoryHeight()
    return self.font:getHeight() * #self.history
end

return Output