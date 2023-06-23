local tool = {}

-- Empty function.
tool.NONE = function() end

-- Returns a integer checker.
function tool.checkTypeInteger(min, max)
    return function(v, f)
        local _, fraction =  math.modf(v)
        if type(v) == "number" and fraction == 0 then
            min = min or -math.huge
            max = max or math.huge
            if v >= min and v <= max then
                f(v)
                return
            end
        end
        if min and min ~= -math.huge and max and max ~= math.huge then
            game.interpreter:sendError("The value must be integer (1, 2, 3, ...) also >= " .. tostring(min) .. " and <= " .. tostring(max))
        elseif min and min ~= -math.huge then
            game.interpreter:sendError("The value must be integer (1, 2, 3, ...) also >= " .. tostring(min))
        elseif max and max ~= math.huge then
            game.interpreter:sendError("The value must be integer (1, 2, 3, ...) also <= " .. tostring(max))
        else
            game.interpreter:sendError("The value must be integer")
        end
    end
end

-- Returns a boolean checker.
function tool.checkTypeBoolean()
    return function (v, f)
        if type(v) == "boolean" then
            f(v)
        else
            game.interpreter:sendError("The value must be boolean (true or false)")
        end
    end
end

-- Returns a string checker.
function tool.checkTypeString(...)
    local strs = {...}
    local formStrs = table.concat(strs, "|")
    return function (v, f)
        if type(v) == "string" then
            local overlap = #strs == 0
            for _, str in ipairs(strs) do
                if str == v then
                    overlap = true
                end
            end

            if not overlap then
                game.interpreter:sendError("The value must be " .. formStrs)
            end
            f(v)
        else
            if strs then
                game.interpreter:sendError("The value must be string (" .. formStrs .. ")")
            else
                game.interpreter:sendError("The value must be string")
            end
        end
    end
end

-- Returns boolean if x, y in rectangle.
function tool.checkInRectangle(x, y, rx, ry, rw, rh)
    return x > rx and y > ry and x < rx + rw and y < ry + rh
end

-- Returns the table whose elements can't be overrided.
function tool.setReadOnly(table)
    local readOnlyMetatable = {
        __metatable = true,
        __index = function(_, k)
            local s, r = pcall(function() return table[k] end)
            if not s then
                game.interpreter:sendError(r)
            end
            return r
        end,
        __newindex = function()
            game.interpreter:sendError("The table is read-only")
        end
    }
    return setmetatable({}, readOnlyMetatable)
end

-- Return a table whose element "game" can't be overrided.
function tool.setGameSafe(table)
    local gameSafeMetatable = {
        __metatable = true,
        __index = function(_, k)
            local s, r = pcall(function() return table[k] end)
            if not s then
                game.interpreter:sendError(r)
            end
            return r
        end,
        __newindex = function(_, k, v)
            if k ~= "game" then
                table[k] = v
            else
                game.interpreter:sendError("The game table can't be removed or overrided")
            end
        end
    }
    return setmetatable({}, gameSafeMetatable)
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