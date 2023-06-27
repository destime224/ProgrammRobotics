local Console = {
    font = fonts.ubuntuMono.regular,
    sandbox = game.SandBox.new("stdin", game.env, "game", game.debug.env, "debug"),

    text = "",
    cursor = {
        ps1 = "> ",
        ps2 = ">>> ",
        pos = 0,
        letter = 1
    },
    commandHistory = {},
    commandHistoryIndex = 0,
    commandQueue = {},
    drawOffset = 0,

    maxLine = 0.97,
    minLine = 0.1
}
Console.cursor.cps = Console.cursor.ps1

function Console:update()
    self.x = wHeight
    self.y = wHeight-(self.font:getHeight()+10)
    self.width = wWidth-wHeight
    self.height = (self.font:getHeight()+10)

    if self.cursor.pos - self.drawOffset > self:getRealTextWidth() * self.maxLine then
        self.drawOffset = self.cursor.pos - self:getRealTextWidth() * self.maxLine
    elseif self.cursor.pos - self.drawOffset < self:getRealTextWidth() * self.minLine then
        self.drawOffset = math.max(0, self.cursor.pos - self:getRealTextWidth() * self.minLine)
    end

    self.cursor.pos = self.font:getWidth(self.cursor.cps .. self.text:sub(1, utf8.offset(self.text, self.cursor.letter)-1))
end

function Console:show()
    if not self.x or not self.y or not self.width or not self.height then return end
    love.graphics.push('all')
    love.graphics.setFont(self.font)

    tool.drawFrame(self.x, self.y, self.width, self.height)

    love.graphics.setScissor(self.x, self.y, self:getRealTextWidth(), self.height)
    local offsetX = self:getRealTextX() - self.drawOffset
    love.graphics.print(self.cursor.cps .. self.text, offsetX, self.y+5)

    if game.actived == self then
        love.graphics.rectangle(
            "fill",
            offsetX + self.cursor.pos,
            self.y + 5,
            self.font:getWidth(self:getSymbol()),
            self.height - 10
        )
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self:getSymbol(), offsetX + self.cursor.pos, self.y + 5)
    else
        local lineWidth = 2
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(lineWidth)
        love.graphics.rectangle(
            "line",
            offsetX + self.cursor.pos + 1,
            self.y + 6,
            self.font:getWidth(self:getSymbol()) - 2,
            self.height - 12
        )
    end
    love.graphics.pop()
end

function Console:textinput(text)
    self:addText(text)
end

function Console:keypressed(key, scan)
    if scan == "backspace" then
        self:deleteSymbol()
    elseif scan == "left" then
        self:moveCursor(-1)
    elseif scan == "right" then
        self:moveCursor(1)
    elseif scan == "up" then
        self:getCommandFromHistory(1)
    elseif scan == "down" then
        self:getCommandFromHistory(-1)
    elseif scan == "return" and love.keyboard.isDown("lshift", "rshift") then
        table.insert(self.commandQueue, self.text .. " ")
        self.commandHistoryIndex = 0
        self.cursor.cps = self.cursor.ps2
        self:clear()
    elseif scan == "return" and self.text ~= "" then
        table.insert(self.commandQueue, self.text .. " ")
        game.output:registrateCommand(self.commandQueue)
        table.insert(self.commandQueue, "")
        self.commandHistoryIndex = 0
        self.cursor.cps = self.cursor.ps1
        self.sandbox:eval(self.commandQueue)
        self.commandQueue = {}
        self:addCommandToHistory(self.text)
        self:clear()
    elseif scan == "v" and love.keyboard.isDown("lctrl", "rctrl") then
        self:addText(love.system.getClipboardText())
    end
end

-- clear the Console text
function Console:clear()
    self.text = ""
    self.cursor.letter = 1
end

-- add text before cursor
function Console:addText(text)
    self.text = self.text:sub(1, utf8.offset(self.text, self.cursor.letter) - 1) .. text .. self.text:sub(utf8.offset(self.text, self.cursor.letter))
    self.cursor.letter = self.cursor.letter + 1
end

-- delete symbol before cursor
function Console:deleteSymbol(letter)
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
    letter = letter or self.cursor.letter
    if letter ~= 1 then
        self.text = self.text:sub(1, utf8.offset(self.text, letter - 1) - 1) .. self.text:sub(utf8.offset(self.text, letter))
        self.cursor.letter = self.cursor.letter - 1
    end
end

function Console:moveCursor(offset)
    self.cursor.letter = math.min(utf8.len(self.text) + 1, math.max(1, self.cursor.letter + offset))
end

function Console:addCommandToHistory(text)
    if self.commandHistory[1] ~= text then
        table.insert(self.commandHistory, 1, text)
        self.commandHistoryIndex = 0
    end
    if #self.commandHistory > 200 then
        table.remove(self.commandHistory)
    end
end

function Console:getSymbol(letter)
    letter = letter or self.cursor.letter

    if letter > utf8.len(self.text) then
        return " "
    end

    return self.text:sub(utf8.offset(self.text, letter), utf8.offset(self.text, letter + 1) - 1)
end

function Console:getCommandFromHistory(off)
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

function Console:getRealTextX()
    return self.x + 5
end

function Console:getRealTextWidth()
    return self.width - 10
end

return Console