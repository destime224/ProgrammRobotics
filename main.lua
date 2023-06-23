worldModule = require("world")
utf8 = require("utf8")
tool = require("tool")

game = {}

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

            game.debug = {
                worldCenter = false,
                infoPanel = false,
                ignoreEdge = false
            }

            print("Debug mode enabled")
        end
    end

    _G.wWidth = love.graphics.getWidth()
    _G.wHeight = love.graphics.getHeight()

    _G.deskWidth, _G.deskHeight = love.window.getDesktopDimensions()

    _G.fonts = {
        ubuntu = {
            regular = love.graphics.newFont("fonts/ubuntu/Ubuntu-Regular.ttf", 20),
            italic = love.graphics.newFont("fonts/ubuntu/Ubuntu-Italic.ttf", 20),
            bold = love.graphics.newFont("fonts/ubuntu/Ubuntu-Bold.ttf", 20),
            boldItalic = love.graphics.newFont("fonts/ubuntu/Ubuntu-BoldItalic.ttf", 20)
        },

        pressStart = {
            regular = love.graphics.newFont("fonts/pressstart/PressStart2P-Regular.ttf", 20)
        }
    }
    fonts.pressStart.regular:setLineHeight(1.4)

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
        commandHistory = {},
        commandHistoryIndex = 0,
        drawOffset = 0,

        maxLine = 0.97,
        minLine = 0.1
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

    function game.console:addCommandToHistory()
        if self.commandHistory[1] ~= self.text then
            table.insert(self.commandHistory, 1, self.text)
            self.commandHistoryIndex = 0
        end
        if #self.commandHistory > 200 then
            table.remove(self.commandHistory)
        end
    end

    function game.console:getCommandFromHistory(off)
        if self.commandHistoryIndex + off == 0 then
            self.commandHistoryIndex = 0
            self.text = ""
            self.cursor.letter = 1
        elseif self.commandHistory[self.commandHistoryIndex + off] ~= nil then
            self.commandHistoryIndex = self.commandHistoryIndex + off
            self.text = self.commandHistory[self.commandHistoryIndex]
            self.cursor.letter = #self.text+1
        end
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
        }
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

        local _, wrText = fonts.ubuntu.regular:getWrap(text, self:getRealTextWidth())

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
        return fonts.ubuntu.regular:getHeight() * #self.history
    end

    game.world = {
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

    function game.world:createMap(w, h)
        local map = worldModule.Map.new(w, h)
        self.map = map

        rawset(game.interpreter.env.game, "world", tool.setReadOnly({
            getWidth = function() return map.width end,
            getHeight = function() return map.height end,
            getSeed = function() return map.seed end
        }))
        rawset(game.interpreter.env.game.world, "base" , self.map.base:getEnvTable())
        rawset(game.interpreter.env.game.world, "engineer" , self.map.engineer:getEnvTable())

        --self:addEntity(worldModule.Entity.new(self.map.camera.x, self.map.camera.y, 1, 1, 0, 1, nil, "engineer"))
    end

    function game.world:addEntity(entity)
        if self.map then
            table.insert(self.map.entities, entity)
            rawset(game.interpreter.env.game.world, #game.interpreter.env.game.world+1, entity:getEnvTable())
        end
    end

    function game.world:addBuild(build, base)
        base = base or false
        if self.map then
            table.insert(self.map.builds, build)
            rawset(game.interpreter.env.game.world, base and "base" or #game.interpreter.env.game.world+1, build:getEnvTable())
        end
    end

    function game.world:getRealCameraX()
        if self.map then
            return (self.width / 2) - self.map.camera.x * self:getRealZoom()
        end
        return 0
    end

    function game.world:getRealCameraY()
        if self.map then
            return (self.height / 2) - self.map.camera.y * self:getRealZoom()
        end
        return 0
    end

    function game.world:getRealZoom()
        if self.map then
            return self.map.camera.zoom * math.min(self.width, self.height) / 900
        end
        return 0
    end

    function game.world:getPositionByCursor()
        if self.map then
            return
                (self.cursor.x - self.width/2) / self:getRealZoom() + self.map.camera.x,
                (self.cursor.y - self.height/2) / self:getRealZoom() + self.map.camera.y
        end
        return 0, 0
    end

    -- interpreter in interpreter.lua
    game.interpreter = require("interpreter")
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
    game.output.height = wHeight - fonts.ubuntu.regular:getHeight()-10

    game.world.x = 0
    game.world.y = 0
    game.world.width = wHeight
    game.world.height = wHeight

    -- Console updating
    game.console.cursor.pos = fonts.ubuntu.regular:getWidth(game.console.text:sub(1, utf8.offset(game.console.text, game.console.cursor.letter)-1))

    if game.console.cursor.pos - game.console.drawOffset > game.console:getRealTextWidth() * game.console.maxLine then
        game.console.drawOffset = game.console.cursor.pos - game.console:getRealTextWidth() * game.console.maxLine
    elseif game.console.cursor.pos - game.console.drawOffset < game.console:getRealTextWidth() * game.console.minLine then
        game.console.drawOffset = math.max(0, game.console.cursor.pos - game.console:getRealTextWidth() * game.console.minLine)
    end

    -- World updating
    if game.world.map then
        if game.actived == game.world and tool.checkInRectangle(love.mouse.getX(), love.mouse.getY(), game.world.x, game.world.y, game.world.width, game.world.height) then
            game.world.cursor.x = love.mouse.getX()
            game.world.cursor.y = love.mouse.getY()
        end

        if not game.debug.ignoreEdge then
            game.world.map.camera.x = math.min(game.world.map.width + 0.5 - game.world.width / 2 / game.world:getRealZoom(), math.max(0.5 + game.world.width / 2 / game.world:getRealZoom(), game.world.map.camera.x))
            game.world.map.camera.y = math.min(game.world.map.height + 0.5 - game.world.height / 2 / game.world:getRealZoom(), math.max(0.5 + game.world.height / 2 / game.world:getRealZoom(), game.world.map.camera.y))
        end

        for i, entity in pairs(game.world.map.entities) do
            if entity.walk.walkTo then
                local dx = entity.walk.x - entity.x
                local dy = entity.walk.y - entity.y
                local dr = entity.walk.rotate - entity.rotate

                if math.abs(dx) >= entity.speed * dt then
                    entity.x = entity.x + entity.speed * dt * tool.sign(dx)
                else
                    entity.x = entity.walk.x
                end

                if math.abs(dy) >= entity.speed * dt then
                    entity.y = entity.y + entity.speed * dt * tool.sign(dy)
                else
                    entity.y = entity.walk.y
                end

                if math.abs(dr) >= entity.rSpeed * dt then
                    entity.rotate = entity.rotate + entity.rSpeed * dt * tool.sign(dr)
                else
                    entity.rotate = entity.walk.rotate
                end

                if entity.x == entity.walk.x and entity.y == entity.walk.y and entity.rotate == entity.walk.rotate then
                    entity.walk.walkTo = false
                end
            end
        end
    end
end

function love.draw()
    -- Console drawing
    love.graphics.push('all')
    love.graphics.setFont(fonts.ubuntu.regular)
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
    love.graphics.setFont(fonts.ubuntu.regular)
    drawFrame(game.output.x, game.output.y, game.output.width, game.output.height)

    love.graphics.setScissor(game.output:getRealTextX(), game.output.y, game.output:getRealTextWidth(), game.output.height)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(table.concat(game.output.history, '\n'), game.output:getRealTextX(), game.output.y - game.output.wheel.offset)
    love.graphics.pop()

    -- World drawing
    love.graphics.push('all')
    drawFrame(game.world.x, game.world.y, game.world.width, game.world.height, {love.math.colorFromBytes(166, 172, 204)}, {0, 0, 0, 0})

    if game.world.map then
        love.graphics.setScissor(game.world.x, game.world.y, game.world.width, game.world.height)

        love.graphics.setColor(love.math.colorFromBytes(15, 14, 38))
        for x, y, e in game.world.map:pairs() do
            if e == 1 then
                love.graphics.rectangle(
                    "fill",
                    (x - 0.5) * game.world:getRealZoom() + game.world:getRealCameraX(),
                    (y - 0.5) * game.world:getRealZoom() + game.world:getRealCameraY(),
                    game.world:getRealZoom(),
                    game.world:getRealZoom()
                )
            end
        end

        love.graphics.setColor(1, 1, 1)
        for i, entity in ipairs(game.world.map.entities) do
            love.graphics.draw(
                entity.sprite,
                entity.x * game.world:getRealZoom() + game.world:getRealCameraX(),
                entity.y * game.world:getRealZoom() + game.world:getRealCameraY(),
                entity.rotate,
                game.world:getRealZoom() * entity.width / entity.sprite:getWidth(),
                game.world:getRealZoom() * entity.height / entity.sprite:getHeight(),
                entity.sprite:getWidth()/2,
                entity.sprite:getHeight()/2
            )
        end

        for i, build in ipairs(game.world.map.builds) do
            love.graphics.draw(
                build.sprite,
                build.x * game.world:getRealZoom() + game.world:getRealCameraX(),
                build.y * game.world:getRealZoom() + game.world:getRealCameraY(),
                build.rotate,
                game.world:getRealZoom() * build.width / build.sprite:getWidth(),
                game.world:getRealZoom() * build.height / build.sprite:getHeight(),
                build.sprite:getWidth()/2,
                build.sprite:getHeight()/2
            )
        end
    end

    if game.world.fps then
        local fps = string.format("fps: " .. tostring(love.timer.getFPS()))
        love.graphics.setColor(0, 0.8, 0)
        love.graphics.print(fps, game.world.x + game.world.width - fonts.ubuntu.regular:getWidth(fps) * 0.7, game.world.y)
    end

    if game.debug.worldCenter then
        love.graphics.setColor(0, 0, 0)
        love.graphics.setPointSize(5)
        love.graphics.points(game.world.x + game.world.width / 2, game.world.y + game.world.height / 2)
    end

    if game.debug.infoPanel then
        love.graphics.setColor(1, 1, 1)
        local cursorPos = {game.world:getPositionByCursor()}
        love.graphics.print(string.format(
            "x: %s\ny: %s\ncamera.x: %s\ncamera.y: %s\nzoom: %s\nrealZoom: %s",
            cursorPos[1],
            cursorPos[2],
            game.world.map.camera.x,
            game.world.map.camera.y,
            game.world.map.camera.zoom,
            game.world:getRealZoom()))
    end
    love.graphics.pop()
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

function love.mousemoved(x, y, dx, dy)
    if game.actived == game.world and love.mouse.isDown(1) and game.world.map then
        game.world.map.camera.x = game.world.map.camera.x - dx / game.world:getRealZoom()
        game.world.map.camera.y = game.world.map.camera.y - dy / game.world:getRealZoom()
    end
end

function love.wheelmoved(x, y)
    if game.actived == game.output and game.output:getHistoryHeight() > game.output.height then
        game.output.wheel.offset = math.min(game.output:getHistoryHeight() - game.output.height + 4, math.max(0, game.output.wheel.offset - y * game.output.wheel.speed))
    elseif game.actived == game.world and game.world.map then
        game.world.map.camera.zoom = math.min(game.world.map.camera.zoomMax, math.max(game.world.map.camera.zoomMin, game.world.map.camera.zoom * 1.25 ^ y))
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
        elseif scancode == "up" then
            game.console:getCommandFromHistory(1)
        elseif scancode == "down" then
            game.console:getCommandFromHistory(-1)
        elseif scancode == "return" and game.console.text ~= "" then
            game.output:registrateCommand(game.console.text)
            game.interpreter:evalString(game.console.text)
            game.console:addCommandToHistory()
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
        --love.graphics.print(":(", wWidth/5, wHeight/20, 0, 20)

        love.timer.sleep(0.1)
    end
end