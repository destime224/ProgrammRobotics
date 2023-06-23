settings = {}
local _, _, t = love.window.getMode()

settings.fullscreen = {}
settings.fullscreen[1] = t.fullscreen
settings.fullscreen[2] = tool.checkTypeBoolean()
settings.fullscreen[3] = function(v) love.window.setFullscreen(v) end

settings.fullscreenType = {}
settings.fullscreenType[1] = t.fullscreentype
settings.fullscreenType[2] = tool.checkTypeString("desktop", "exclusive", "normal")
settings.fullscreenType[3] = function(v) love.window.setFullscreen(settings.fullscreen[1], v) end

settings.windowX = {}
settings.windowX[1] = t.x
settings.windowX[2] = tool.checkTypeInteger(0, deskWidth - wWidth)
settings.windowX[3] = function(v)
    local _, y, _ = love.window.getPosition()
    love.window.setPosition(v, y)
end

settings.windowY = {}
settings.windowY[1] = t.y
settings.windowY[2] = tool.checkTypeInteger(0, deskHeight - wHeight)
settings.windowY[3] = function(v) love.window.setPosition(settings.windowX[1], v) end

settings.windowWidth = {}
settings.windowWidth[1] = wWidth
settings.windowWidth[2] = tool.checkTypeInteger(1280, deskWidth - settings.windowX[1])
settings.windowWidth[3] = function(v) love.window.setMode(v, wHeight) end

settings.windowHeight = {}
settings.windowHeight[1] = wHeight
settings.windowHeight[2] = tool.checkTypeInteger(720, deskHeight - settings.windowY[1])
settings.windowHeight[3] = function(v) love.window.setMode(wWidth, v) end

settings.VSync = {}
settings.VSync[1] = t.vsync
settings.VSync[2] = tool.checkTypeInteger(-1, 1)
settings.VSync[3] = function(v) love.window.setVSync(v) end

settings.borderless = {}
settings.borderless[1] = t.borderless
settings.borderless[2] = tool.checkTypeBoolean()
settings.borderless[3] = function(v) love.window.setMode(wWidth, wHeight, {borderless = v}) end

settings.resizable = {}
settings.resizable[1] = t.resizable
settings.resizable[2] = tool.checkTypeBoolean()
settings.resizable[3] = function(v) love.window.setMode(wWidth, wHeight, {resizable = v}) end

settings.showFPS = {}
settings.showFPS[1] = game.world.fps
settings.showFPS[2] = tool.checkTypeBoolean()
settings.showFPS[3] = function(v) game.world.fps = v end

local env = tool.setGameSafe({
    assert = assert,
    ipairs = ipairs,
    pairs = pairs,
    pcall = pcall,
    xpcall = xpcall,
    next = next,
    select = select,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    unpack = unpack,
    _VERSION = _VERSION,
    string = tool.copyTable(string),
    table = tool.copyTable(table),
    math = tool.copyTable(math),

    game = tool.setReadOnly({
        version = GameV,
        quit = function()
            love.event.quit(0)
        end,
        export = tool.NONE,
        credits = function() game.output:credits() end,
        createWorld = function(w, h)
            w = type(w) == "number" and w or 256
            h = type(h) == "number" and h or 256
            if w < 128 or w > 1024 or h < 128 or h > 1024 then
                game.interpreter:sendError("Width and height must be >= 128 and <= 1024")
            end
            game.world:createMap(w, h)
            game.output:print("The world (" .. game.world.map.width .. "x" .. game.world.map.height .. ") was successfully created")
        end,

        output = tool.setReadOnly({
            print = function(...) game.output:print(...) end,
            error = function(message) game.interpreter:sendError(message) end,
            clear = function() game.output:clear() end
        }),

        settings = setmetatable({}, {
            __index = function(_, k)
                local _, result = xpcall(function() return settings[k][1] end, function() error("There is no setting " .. tostring(k), 2) end)
                return result
            end,

            __newindex = function(table, k, v)
                local setExist, _ = pcall(function() return settings[k][1] end)

                if not setExist then
                    rawset(table, k, v)
                    return
                end

                local s, r = pcall(settings[k][2], v, settings[k][3])
                if s then
                    settings[k][1] = v
                else
                    error(r, 2)
                end
            end,

            __metatable = true
        })
    })
})

if game.debug then
    rawset(env, "debug", {
        spawnEntity = function(x, y)
            x = x or game.world.map.camera.x
            y = y or game.world.map.camera.y
            game.world:addEntity(worldModule.Entity.new(x, y))
        end,

        setCenterPoint = function(bool)
            bool = bool or not game.debug.worldCenter
            game.debug.worldCenter = bool
        end,

        generateError = function(msg)
            error(msg or "simple text")
        end,

        setIgnoreEdge = function(bool)
            bool = bool or not game.debug.ignoreEdge
            game.debug.ignoreEdge = bool
        end,

        setInfoPanel = function(bool)
            bool = bool or not game.debug.infoPanel
            game.debug.infoPanel = bool
        end,
        mainEnv = _G
    })
end




local Error = {}
Error.__index = Error
Error.__tostring = function(table) return table.message end

function Error.new(message)
    local self = {}

    self.message = message or ""
    self.info = "IE" -- Interpreter Error

    setmetatable(self, Error)
    return self
end



local interpreter = {
    env = env,
}

function interpreter:evalString(str)
    local f, err = load(str, "@stdin", "t", self.env)
    if f then
        local success, result = pcall(f)
        if not success then
            if result.info == "IE" or result:sub(1, 5) == "stdin" then
                game.output:print("Error: " .. tostring(result))
            else
                error(result)
            end
        end
    else
        game.output:print("Error: " .. err)
    end
end

function interpreter:sendError(message)
    local level = 1
    local trace = ""
    while true do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        if info.what == "main" then
            trace = trace .. string.format("%s:%d ", info.short_src, info.currentline)
        end
        level = level + 1
    end
    error(Error.new(trace .. message))
end

return interpreter