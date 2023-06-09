worldModule = require("world")
utf8 = require("utf8")
tool = require("tool")

game = {
    debugMode = false
}

local function drawFrame(x, y, w, h, bc, ec)
    love.graphics.setColor(unpack(bc or {0, 0, 0}))
    love.graphics.rectangle("fill", x, y, w, h)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(unpack(ec or {1, 1, 1}))
    love.graphics.rectangle("line", x, y, w, h)
end

function love.load(args)

    for i, arg in ipairs(args) do
        if arg == "--debug" or arg == "-d" then
            game.debugMode = true
            print("Debug mode enabled")
        end
    end

    _G.wWidth = love.graphics.getWidth()
    _G.wHeight = love.graphics.getHeight()

    _G.deskWidth, _G.deskHeight = love.window.getDesktopDimensions()

    _G.fonts = {
        ubuntu = {
            regular = "fonts/ubuntu/Ubuntu-Regular.ttf",
            italic = "fonts/ubuntu/Ubuntu-Italic.ttf",
            bold = "fonts/ubuntu/Ubuntu-Bold.ttf",
            boldItalic = "fonts/ubuntu/Ubuntu-BoldItalic.ttf"
        },

        pressStart = {
            regular = "fonts/pressstart/PressStart2P-Regular.ttf"
        }
    }

    love.keyboard.setKeyRepeat(true)

    --[[ Console
        Console use the font with size 20px + spacing (3px) + offset (10px) = 33px
    ]]
    game.console = {
        x = 0,
        y = 0,
        width = 0,
        height = 0,

        text = "",
        cursor = {
            pos = 0,
            letter = 1
        },
        drawOffset = 0,

        maxLine = 0.97,
        minLine = 0.1,

        font = love.graphics.newFont(fonts.ubuntu.regular, 20)
    }

    -- clear the console text
    function game.console:clear()
        self.text = ""
        self.cursor.letter = 1
    end

    -- add text before cursor
    function game.console:addText(text)
        self.text = self.text:sub(1, utf8.offset(self.text, self.cursor.letter) - 1) .. text .. self.text:sub(utf8.offset(self.text, self.cursor.letter))
        self.cursor.letter = self.cursor.letter + utf8.len(text)
        --print(self.text, self.cursor.letter)
    end

    -- delete symbol before cursor
    function game.console:deleteSymbol()
        --[[
            qweфыа = 9b

            q 113  1 1b
            w 119  2 1b
            e 101  3 1b
            ф 1092 4 2b
            ы 1099 6 2b
            а 1072 8 2b

            qweффыы|аа - delete ыы
            letter = 6
            self.text = self.text:sub(1, utf8.offset(self.text, self.cursor.letter - 1) - 1) .. self.text:sub(utf8.offset(self.text, self.cursor.letter))
        ]]
        if self.cursor.letter ~= 1 then
            self.text = self.text:sub(1, utf8.offset(self.text, self.cursor.letter - 1) - 1) .. self.text:sub(utf8.offset(self.text, self.cursor.letter))
            self.cursor.letter = self.cursor.letter - 1
        end
        --print(self.text, self.cursor.letter)
    end

    function game.console:moveCursor(offset)
        self.cursor.letter = math.min(utf8.len(self.text) + 1, math.max(1, self.cursor.letter + offset))
    end

    function game.console:getRealTextX()
        return self.x + 4
    end

    function game.console:getRealTextWidth()
        return self.width - 8
    end

    game.output = {
        x = 0,
        y = 0,
        width = 0,
        height = 0,

        --[[This line is just a hack
        
        There is bug for method `Font.getWrap` that works wrong when is called in function `love.load`
        So i cannot use `game.output.credits` in `love.load`]]
        history = {"ProgrammRobotics ".. GameV .." by DarkDrawKill", _VERSION},
        wheel = {
            offset = 0,
            speed = 20
        },

        font = love.graphics.newFont(fonts.ubuntu.regular, 20)
    }

    -- print the text
    function game.output:print(...)
        if #{...} == 0 then
            return
        end

        local text = ""
        for i, t in ipairs({...}) do
            xpcall(function() text = text .. tostring(t) .. " " end, function(err) print("Element " .. i .. "can't be string") end)
        end

        local _, wrText = self.font:getWrap(text, self:getRealTextWidth())

        for _, t in ipairs(wrText) do
            table.insert(self.history, t)
            if #self.history > 1000 then
                table.remove(self.history, 1)
            end
        end

        if self:getHistoryHeight() > self.height then
            self.wheel.offset = self:getHistoryHeight() - self.height + 4
        end
    end

    -- clear output
    function game.output:clear()
        self.history = {}
        self.wheel.offset = 0
    end

    function game.output:credits()
        self:print(string.format("ProgrammRobotics %s by DarkDrawKill\n%s", GameV, _VERSION))
    end

    -- "print(1, 2, 3)" => ">>> print(1, 2, 3)"
    function game.output:registrateCommand(command)
        -- There is the nobreak space (U+0160 or 255 in ASCII)
        command = ">>> " .. command
        self:print(command)
    end

    function game.output:getRealTextX()
        return game.console.getRealTextX(self)
    end

    function game.output:getRealTextWidth()
        return game.console.getRealTextWidth(self)
    end

    -- get history height in pixels
    function game.output:getHistoryHeight()
        return self.font:getHeight() * #self.history
    end

    -- interpreter in interpreter.lua
    game.interpreter = require("interpreter")

    game.world = {
        x = 0,
        y = 0,
        width = 0,
        height = 0,
        worldCenter = false,

        map = nil
    }

    function game.world:createMap(w, h)
        local map = worldModule.Map.new(w, h)

        if game.world.map then
            local camera = game.world.map.camera

            game.world.map = map
            game.world.map.camera = camera
        else
            game.world.map = map
        end

        rawset(game.interpreter.env.game, "world", tool.setReadOnly({
            getWidth = function() return map.width end,
            getHeight = function() return map.height end,
            getSeed = function() return map.seed end
        }))

        game.world:addEntity(worldModule.Entity.new(game.world.map.camera.x, game.world.map.camera.y, 0, 1, 1, 1, nil, "engineer"))
    end

    function game.world:addEntity(entity)
        if game.world.map then
            table.insert(game.world.map.entities, entity)
            rawset(game.interpreter.env.game.world, entity.tag, entity:getEnvTable())
        end
    end
end

function love.update(dt)
    _G.wWidth = love.graphics.getWidth()
    _G.wHeight = love.graphics.getHeight()

    -- UI size updating
    game.console.x = wHeight
    game.console.y = wHeight-33
    game.console.width = wWidth-wHeight
    game.console.height = 33

    game.output.x = wHeight
    game.output.y = 0
    game.output.width = wWidth - wHeight
    game.output.height = wHeight - game.output.font:getHeight()-10

    game.world.x = 0
    game.world.y = 0
    game.world.width = wHeight
    game.world.height = wHeight

    -- Console updating
    game.console.cursor.pos = game.console.font:getWidth(game.console.text:sub(1, utf8.offset(game.console.text, game.console.cursor.letter)-1))

    if game.console.cursor.pos - game.console.drawOffset > game.console:getRealTextWidth() * game.console.maxLine then
        game.console.drawOffset = game.console.cursor.pos - game.console:getRealTextWidth() * game.console.maxLine
    elseif game.console.cursor.pos - game.console.drawOffset < game.console:getRealTextWidth() * game.console.minLine then
        game.console.drawOffset = math.max(0, game.console.cursor.pos - game.console:getRealTextWidth() * game.console.minLine)
    end

    -- Entites
    if game.world.map then
        for i, entity in pairs(game.world.map.entities) do
            local dx = entity.walk.x - entity.x
            local dy = entity.walk.y - entity.y

            if math.abs(dx) >= entity.speed then
                entity.x = entity.x + entity.speed * dt * tool.sign(dx)
            else
                entity.x = entity.walk.x
            end

            if math.abs(dy) >= entity.speed then
                entity.y = entity.y + entity.speed * dt * tool.sign(dy)
            else
                entity.y = entity.walk.y
            end
        end
    end
end

function love.draw()
    -- Console drawing
    love.graphics.push('all')
    love.graphics.setFont(game.console.font)
    drawFrame(game.console.x, game.console.y, game.console.width, game.console.height)

    love.graphics.setScissor(game.console.x, game.console.y, game.console:getRealTextWidth(), game.console.height)
    local offsetX = game.console:getRealTextX() - game.console.drawOffset

    if game.actived ~= game.console and game.console.text == "" then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("Lua command...", offsetX, game.console.y+5)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(game.console.text, offsetX, game.console.y+5)
    end

    if game.actived == game.console and (love.timer.getTime() % 1) > 0.5 then
        love.graphics.setLineWidth(1)
        love.graphics.setLineStyle("smooth")
        love.graphics.line(
            offsetX + game.console.cursor.pos,
            game.console.y + 5,
            offsetX + game.console.cursor.pos,
            game.console.y + game.console.height - 5
        )
    end
    love.graphics.pop()

    -- Output drawing
    love.graphics.push('all')
    love.graphics.setFont(game.output.font)
    drawFrame(game.output.x, game.output.y, game.output.width, game.output.height)

    love.graphics.setScissor(game.output:getRealTextX(), game.output.y, game.output:getRealTextWidth(), game.output.height)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(table.concat(game.output.history, '\n'), game.output:getRealTextX(), game.output.y - game.output.wheel.offset)
    love.graphics.pop()

    -- World drawing
    love.graphics.push('all')
    drawFrame(game.world.x, game.world.y, game.world.width, game.world.height, {love.math.colorFromBytes(166, 172, 204)}, {0, 0, 0, 0})

    love.graphics.setColor(love.math.colorFromBytes(15, 14, 38))
    if game.world.map then
        love.graphics.setScissor(game.world.x, game.world.y, game.world.width, game.world.height)
        for x, y, e in game.world.map:pairs() do
            if e == 1 then
                love.graphics.rectangle(
                    "fill",
                    (x - 0.5) * game.world.map:getRealZoom() + game.world.map:getRealCameraX(),
                    (y - 0.5) * game.world.map:getRealZoom() + game.world.map:getRealCameraY(),
                    game.world.map:getRealZoom(),
                    game.world.map:getRealZoom()
                )
            end
        end

        for i, entity in ipairs(game.world.map.entities) do
            love.graphics.draw(
                entity.sprite,
                (entity.x - 0.5) * game.world.map:getRealZoom() + game.world.map:getRealCameraX(),
                (entity.y - 0.5) * game.world.map:getRealZoom() + game.world.map:getRealCameraY(),
                0,
                game.world.map:getRealZoom() * entity.width / entity.sprite:getWidth(),
                game.world.map:getRealZoom() * entity.height / entity.sprite:getHeight()
            )
        end
    end

    if game.world.worldCenter then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setPointSize(5)
        love.graphics.points(game.world.x + game.world.width / 2, game.world.y + game.world.height / 2)
    end
    love.graphics.pop()
end

function love.mousepressed(x, y, button, isTouch, presses)
    -- One of the worse scripts I wrote :)
    if x > game.console.x and y > game.console.y and x < game.console.x + game.console.width and y < game.console.y + game.console.height then
        game.actived = game.console
    elseif x > game.output.x and y > game.output.y and x < game.output.x + game.output.width and y < game.output.y + game.output.height then
        game.actived = game.output
    elseif x > game.world.x and y > game.world.y and x < game.world.x + game.world.width and y < game.world.y + game.world.height then
        game.actived = game.world
    else
        game.actived = nil
    end
end

function love.mousemoved(x, y, dx, dy)
    if game.actived == game.world and love.mouse.isDown(1) and game.world.map then
        game.world.map.camera.x = math.min(game.world.map.width + 0.5 - game.world.width / 2 / game.world.map:getRealZoom(), math.max(0.5 + game.world.width / 2 / game.world.map:getRealZoom(), game.world.map.camera.x - dx / game.world.map:getRealZoom()))
        game.world.map.camera.y = math.min(game.world.map.height + 0.5 - game.world.height / 2 / game.world.map:getRealZoom(), math.max(0.5 + game.world.height / 2 / game.world.map:getRealZoom(), game.world.map.camera.y - dy / game.world.map:getRealZoom()))
    end
end

function love.wheelmoved(x, y)
    if game.actived == game.output and game.output:getHistoryHeight() > game.output.height then
        game.output.wheel.offset = math.min(game.output:getHistoryHeight() - game.output.height + 4, math.max(0, game.output.wheel.offset - y * game.output.wheel.speed))
    elseif game.actived == game.world and game.world.map then
        game.world.map.camera.zoom = math.min(game.world.map.camera.zoomMax, math.max(game.world.map.camera.zoomMin, game.world.map.camera.zoom * 1.25 ^ y))
        game.world.map.camera.x = math.min(game.world.map.width + 0.5 - game.world.width / 2 / game.world.map:getRealZoom(), math.max(0.5 + game.world.width / 2 / game.world.map:getRealZoom(), game.world.map.camera.x))
        game.world.map.camera.y = math.min(game.world.map.height + 0.5 - game.world.height / 2 / game.world.map:getRealZoom(), math.max(0.5 + game.world.height / 2 / game.world.map:getRealZoom(), game.world.map.camera.y))
    end
end

function love.keypressed(key, scancode, isRepeat)
    if game.actived == game.console then
        if scancode == "backspace" then
            game.console:deleteSymbol()
        elseif scancode == "left" then
            game.console:moveCursor(-1)
        elseif scancode == "right" then
            game.console:moveCursor(1)
        elseif scancode == "return" and game.console.text ~= "" then
            game.output:registrateCommand(game.console.text)
            game.interpreter:evalString(game.console.text)
            game.console:clear()
        elseif scancode == "v" and love.keyboard.isDown("lctrl", "rctrl") then
            game.console:addText(love.system.getClipboardText())
        end
    end
end

function love.textinput(text)
    if game.actived == game.console then
        game.console:addText(text)
    end
end

function love.errorhandler(msg)
	msg = tostring(msg)

    local copied = false
    local originalTraceback = debug.traceback(debug.traceback(msg, 3))
    local traceback = "Sorry, but something went wrong...\n\nError: " .. originalTraceback
    print(traceback)

    traceback = traceback:gsub('\t', '')
    traceback = traceback:gsub("stack traceback:", "\nTraceback:")

    love.audio.stop()
    love.graphics.reset()

    local font = love.graphics.newFont(fonts.pressStart.regular, 14)
    font:setLineHeight(1.4)
    local smileFont = love.graphics.newFont(fonts.pressStart.regular, 30)

    love.graphics.setFont(font)
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
        love.graphics.setFont(font)
        love.graphics.printf(traceback, wWidth/3, wHeight/7, wWidth-wWidth/3-5)
        love.graphics.setFont(smileFont)
        love.graphics.print(":(", wWidth/25, wHeight/3.6, math.rad(90), wHeight/144, wWidth/151, 0, love.graphics.getFont():getHeight())
        love.graphics.present()
        --love.graphics.print(":)", wWidth/5, wHeight/20, 0, 20)

        love.timer.sleep(0.1)
    end
end