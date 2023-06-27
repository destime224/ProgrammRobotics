local function checkTypeNumber(v, min, max, float)
    float = float or true
    local _, fraction =  math.modf(v)
    if type(v) == "number" and (float and fraction == 0 or true) then
        min = min or -math.huge
        max = max or math.huge
        if v >= min and v <= max then
            return v
        end
    end
    --[[if min and min ~= -math.huge and max and max ~= math.huge then
        game.interpreter:sendError("The value must be integer (1, 2, 3, ...) also >= " .. tostring(min) .. " and <= " .. tostring(max))
    elseif min and min ~= -math.huge then
        game.interpreter:sendError("The value must be integer (1, 2, 3, ...) also >= " .. tostring(min))
    elseif max and max ~= math.huge then
        game.interpreter:sendError("The value must be integer (1, 2, 3, ...) also <= " .. tostring(max))
    else
        game.interpreter:sendError("The value must be integer")
    end]]
end

local function checkTypeBoolean(v)
    if type(v) == "boolean" then
        return v
    else
        --[[game.interpreter:sendError("The value must be boolean (true or false)")]]
    end
end

local function checkTypeString(v, ...)
    local strs = {...}
    local formStrs = table.concat(strs, "|")
    if type(v) == "string" then
        local overlap = #strs == 0
        for _, str in ipairs(strs) do
            if str == v then
                overlap = true
            end
        end

        if overlap then
            return v
        end
    else
        --[[if strs then
            game.interpreter:sendError("The value must be string (" .. formStrs .. ")")
        else
            game.interpreter:sendError("The value must be string")
        end]]
    end
end


local settings = {}
settings.__index = function(_, k)
    if type(k) ~= "string" then return end
    if k:sub(1, 2) == "__" then return end
    return settings[k][1]()
end
settings.__newindex = function(_, k, v)
    if type(k) ~= "string" then return end
    if k:sub(1, 2) == "__" then return end
    if type(settings[k]) ~= "table" then return end
    settings[k][2](v)
end

settings.fullscreen = {
    function()
        local v = love.window.getFullscreen()
        return v
    end,
    function(v)
        v = checkTypeBoolean(v)
        love.window.setFullscreen(v)
    end
}

settings.fullscreenType = {
    function()
        local _, v = love.window.getFullscreen()
        return v
    end,
    function(v)
        v = checkTypeString("desktop", "exclusive")
        love.window.setFullscreen(v)
    end
}

settings.windowX = {
    function()
        local v = love.window.getPosition()
        return v
    end,
    function(v)
        v = checkTypeNumber(v)
        love.window.setPosition(v, settings.windowY[1]())
    end
}

settings.windowY = {
    function()
        local _, v = love.window.getPosition()
        return v
    end,
    function(v)
        v = checkTypeNumber(v)
        love.window.setPosition(settings.windowX[1](), v)
    end
}

settings.display = {
    function()
        local _, _, v = love.window.getPosition()
        return v
    end,
    function(v)
        v = checkTypeNumber(v, 0, love.window.getDisplayCount(), false)
        love.window.setPosition(settings.windowX[1](), settings.windowY[1](), v)
    end
}

settings.windowWidth = {
    function()
        return wWidth
    end,
    function(v)
        v = checkTypeNumber(v, 1280, deskWidth)
        love.window.setMode(v, wHeight)
    end
}

settings.windowHeight = {
    function()
        return wHeight
    end,
    function(v)
        v = checkTypeNumber(v, 720, deskHeight)
        love.window.setMode(wWidth, v)
    end
}

settings.VSync = {
    function()
        return love.window.getVSync()
    end,
    function(v)
        v = checkTypeNumber(v, -1, 3)
        love.window.setVSync(v)
    end
}

settings.borderless = {
    function()
        local _, _, t = love.window.getMode()
        return t.borderless
    end,
    function(v)
        v = checkTypeBoolean(v)
        love.window.setMode(wWidth, wHeight, {borderless = v})
    end
}

settings.resizable = {
    function()
        local _, _, t = love.window.getMode()
        return t.resizable
    end,
    function(v)
       v = checkTypeBoolean(v)
       love.window.setMode(wWidth, wHeight, {resizable = v})
    end
}

settings.showFPS = {
    function()
        return game.world.fps
    end,
    function(v)
        v = checkTypeBoolean(v)
        game.world.fps = v
    end
}

return setmetatable({}, settings)