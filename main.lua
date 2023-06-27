function love.load(args)
    package.path = "./scripts/?.lua;./scripts/?/init.lua;" .. package.path
    utf8 = require("utf8")
    tool = require("tool")
    require("objects")
    love.physics.setMeter(1)

    game = {debug = {}}
    for _, arg in ipairs(args) do
        if arg == "--debug" or arg == "-d" then
            game.debug = {
                true, -- #game.debug will be 1
                worldCenter = false,
                infoPanel = false,
                ignoreEdge = false,
                drawShapes = false
            }
            print("Debug mode enabled")
        end
    end
    game.SandBox = require("sandbox")
    game.env, game.debug.env = unpack(require("env"))

    wWidth = love.graphics.getWidth()
    wHeight = love.graphics.getHeight()

    deskWidth, deskHeight = love.window.getDesktopDimensions()

    spritesheet = love.graphics.newImage("sprites/spritesheet.png")

    sprites = {
        obstacle = love.graphics.newQuad(256 * 3 + 1, 1, 254, 254, spritesheet),
        build = love.graphics.newQuad(1, 1, 254, 254, spritesheet),
        entity = love.graphics.newQuad(256 * 1 + 1, 1, 254, 254, spritesheet),
        shape = {
            rectangle = love.graphics.newQuad(256 * 2 + 1, 1, 254, 254, spritesheet)
        }
    }

    fonts = {
        ubuntu = {
            regular = love.graphics.newFont("fonts/ubuntu/Ubuntu-Regular.ttf", 20),
            italic = love.graphics.newFont("fonts/ubuntu/Ubuntu-Italic.ttf", 20),
            bold = love.graphics.newFont("fonts/ubuntu/Ubuntu-Bold.ttf", 20),
            boldItalic = love.graphics.newFont("fonts/ubuntu/Ubuntu-BoldItalic.ttf", 20)
        },

        ubuntuMono = {
            regular = love.graphics.newFont("fonts/ubuntuMono/UbuntuMono-Regular.ttf", 20),
            italic = love.graphics.newFont("fonts/ubuntuMono/UbuntuMono-Italic.ttf", 20),
            bold = love.graphics.newFont("fonts/ubuntuMono/UbuntuMono-Bold.ttf", 20),
            boldItalic = love.graphics.newFont("fonts/ubuntuMono/UbuntuMono-BoldItalic.ttf", 20)
        },

        pressStart = {
            regular = love.graphics.newFont("fonts/pressstart/PressStart2P-Regular.ttf", 20)
        }
    }
    fonts.pressStart.regular:setLineHeight(1.4)
    love.keyboard.setKeyRepeat(true)

    game.console = require("console")
    game.output = require("output")
    game.world = require("world")
end

function love.update(dt)
    wWidth = love.graphics.getWidth()
    wHeight = love.graphics.getHeight()

    game.console:update()
    game.output:update()
    game.world:update(dt)
end

function love.draw()
    game.console:show()
    game.output:show()
    game.world:show()
end

function love.mousepressed(x, y, button, isTouch, presses)
    -- One of the worse scripts I wrote :)
    if tool.checkInRectangle(x, y, game.console.x, game.console.y, game.console.width, game.console.height) then
        game.actived = game.console
    elseif tool.checkInRectangle(x, y, game.output.x, game.output.y, game.output.width, game.output.height) then
        game.actived = game.output
    elseif tool.checkInRectangle(x, y, game.world.x, game.world.y, game.world.width, game.world.height) then
        game.actived = game.world
    else
        game.actived = nil
    end
end

function love.textinput(...)
    if type(game.actived) == "table" then
        if type(game.actived.textinput) == "function" then
            game.actived:textinput(...)
        end
    end
end

function love.mousemoved(...)
    if type(game.actived) == "table" then
        if type(game.actived.mousemoved) == "function" then
            game.actived:mousemoved(...)
        end
    end
end

function love.wheelmoved(...)
    if type(game.actived) == "table" then
        if type(game.actived.wheelmoved) == "function" then
            game.actived:wheelmoved(...)
        end
    end
end

function love.keypressed(...)
    if type(game.actived) == "table" then
        if type(game.actived.keypressed) == "function" then
            game.actived:keypressed(...)
        end
    end
end

function love.errorhandler(msg)
	msg = tostring(msg)

    local copied = false
    local originalTraceback = debug.traceback(msg, 3)
    local traceback = "Sorry, but something went wrong...\n\nError: " .. originalTraceback
    print(traceback)

    traceback = traceback:gsub('\t', '')
    traceback = traceback:gsub("stack traceback:", "\nTraceback:")

    love.audio.stop()
    love.graphics.reset()

    local font = love.graphics.setFont(fonts.pressStart.regular)
    love.graphics.setColor(1, 1, 1)

    if love.system then
        traceback = traceback .. "\n\nPress Ctrl+C to copy this message"
    end

	return function()
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" or e == "keypressed" and a == "escape" then
                return 1
            elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
                if not copied then
                    love.system.setClipboardText(originalTraceback)
                    traceback = traceback .. "\nCopied to clipboard."
                    copied = true
                end
            end
        end

        love.graphics.clear(0, 0, 0)
        love.graphics.printf(traceback, wWidth*0.1, wHeight*0.1, wWidth-wWidth/3-5, "left", 0, 0.63)
        love.graphics.present()
        love.timer.sleep(0.1)
    end
end