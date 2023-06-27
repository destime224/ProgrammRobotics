local tool = {}

-- Empty function.
tool.NONE = function() end

function tool.drawFrame(x, y, w, h, bc, ec)
    x = x or 0
    y = y or 0
    w = w or 0
    h = h or 0

    love.graphics.setColor(unpack(bc or {0, 0, 0}))
    love.graphics.rectangle("fill", x, y, w, h)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(unpack(ec or {1, 1, 1}))
    love.graphics.rectangle("line", x, y, w, h)
end

-- Returns boolean if x, y in rectangle.
function tool.checkInRectangle(x, y, rx, ry, rw, rh)
    if x and y and rx and ry and rw and rh then return x > rx and y > ry and x < rx + rw and y < ry + rh end
end

-- Returns a copy of table. Does not copy tables in the table.
function tool.copyTable(table)
    local otherTable = {}
    for k, v in pairs(table) do
        otherTable[k] = v
    end
    return otherTable
end

-- Returns a copy of table. Alose copyes tables in the table.
function tool.deepCopy(table) --[[NOT safe for tables have themself as element.]]
    local otherTable = {}
    for k, v in pairs(table) do
        if type(v) == "table" then
            otherTable[k] = tool.deepCopy(v)
        else
            otherTable[k] = v
        end
    end
    return otherTable
end

-- Returns a hypotenuse of a and b.
function tool.hypotenuse(a, b)
    return math.sqrt(a^2 + b^2)
end

-- Returns a sign of number in -1, 0, 1.
function tool.sign(i)
    if i < 0 then
        return - 1
    elseif i > 0 then
        return 1
    else
        return 0
    end
end

-- Returns a value if value <= max and value >= min otherwise max (value >= max) or min (value <= min).
function tool.clamp(value, max, min)
    -- hahahahahahah
    if value > max then return max
    elseif value < min then return min
    else return value end
end

return tool