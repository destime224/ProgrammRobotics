local tool = {}

-- Empty function
tool.NONE = function() end


-- Checkers
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

function tool.checkTypeBoolean()
    return function (v, f)
        if type(v) == "boolean" then
            f(v)
        else
            game.interpreter:sendError("The value must be boolean (true or false)")
        end
    end
end

function tool.checkTypeString(...)
    local strs = {...}
    local formStrs = table.concat(strs, "|")
    return function (v, f)
        if type(v) == "string" then
            local overlap = false
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

-- Safe tables for interpreter
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


-- Copy and deepcopy
function tool.copyTable(table)
    local otherTable = {}
    for k, v in pairs(table) do
        otherTable[k] = v
    end
    return otherTable
end

function tool.deepCopy(table) --[[NOT safe for tables have themself as element]]
    local otherTable = {}
    for k, v in pairs(table) do
        if type(v) == "table" then
            otherTable[k] = tool.deepCopy(v)
        else
            otherTable[k] = v
        end
    end
end

-- math
function tool.hypotenuse(a, b)
    return math.sqrt(a^2 + b^2)
end

function tool.sign(i)
    if i < 0 then
        return - 1
    elseif i > 0 then
        return 1
    else
        return 0
    end
end

return tool