local debug
local env = game.SandBox.setReadOnly({
    version = GameV,
    credits = function() game.output:credits() end,
    quit = function()
        love.event.quit(0)
    end,

    createWorld = function(w, h)
        w = type(w) == "number" and w or 256
        h = type(h) == "number" and h or 256
        if w < 128 or w > 1024 or h < 128 or h > 1024 then
            game.output:error("Width and height must be >= 128 and <= 1024")
            return
        end
        game.world:createMap(w, h)
        game.output:print("The world (" .. game.world.map.width .. "x" .. game.world.map.height .. ") was successfully created")
    end,

    output = game.SandBox.setReadOnly({
        print = function(...)
            game.output:print(...)
        end,

        warn = function(...)
            game.output:warning(...)
        end,

        clear = function()
            game.output:clear()
        end
    }),

    console = game.SandBox.setReadOnly({
        error = function(msg)
            game.SandBox.sendError(msg)
        end
    }),

    settings = require("settings")
})

-- to enable debug mode run project with -d or --debug
if #game.debug ~= 0 then
    debug = game.SandBox.setReadOnly({
        main = _G,
        setInfoPanel = function(bool)
            bool = bool or not game.debug.infoPanel
            game.debug.infoPanel = bool
        end,

        setWorldCenter = function(bool)
            bool = bool or not game.debug.worldCenter
            game.debug.worldCenter = bool
        end,

        setIgnoreEdge = function(bool)
            bool = bool or not game.debug.ignoreEdge
            game.debug.ignoreEdge = bool
        end,

        setDrawShapes = function(bool)
            bool = bool or not game.debug.drawShapes
            game.debug.drawShapes = bool
        end
    })
end

return {env, debug}