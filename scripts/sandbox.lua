local SandBox = {}
SandBox.__index = SandBox

-- The _G is same for sandbox objects
local global = {}

global.__index = global
global.__newindex = function(_, k, v)
    if v.__type == "readonly" or v.__type == "protected" then
        -- error()
    elseif k == "__index" or k == "__newindex" then

    else
        global[k] = v
    end
end

SandBox.global = setmetatable({}, global)

function SandBox.new(sandboxName, ...)
    local self = {}
    local args = {...}

    self.protected = "_G coroutine math string table"
    self.sandboxName = "@" .. sandboxName
    self.envNames = {}

    -- Base environment
    self.environment = SandBox.setProtected(self, {
        _G = SandBox.global,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        type = type,
        tonumber = tonumber,
        tostring = tostring,
        _VERSION = _VERSION,
        unpack = unpack,
        select = select,

        string = SandBox.setReadOnly({
            byte = string.byte,
            char = string.char,
            find = string.find,
            format = string.format,
            gmatch = string.gmatch,
            gsub = string.gsub,
            len = string.len,
            lower = string.lower,
            match = string.match,
            rep = string.rep,
            reverse = string.reverse,
            sub = string.sub,
            upper = string.upper
        }),

        table = SandBox.setReadOnly({
            insert = table.insert,
            maxn = table.maxn,
            remove = table.remove,
            sort = table.sort,
            concat = table.concat
        }),

        math = SandBox.setReadOnly({
            abs = math.abs,
            acos = math.acos,
            asin = math.asin,
            atan = math.atan,
            atan2 = math.atan2,
            ceil = math.ceil,
            cos = math.cos,
            cosh = math.cosh,
            deg = math.deg,
            exp = math.exp,
            floor = math.floor,
            fmod = math.fmod,
            frexp = math.frexp,
            huge = math.huge,
            ldexp = math.ldexp,
            log = math.log,
            log10 = math.log10,
            max = math.max,
            min = math.min,
            modf = math.modf,
            pi = math.pi,
            pow = math.pow,
            rad = math.rad,
            random = math.random,
            randomseed = math.randomseed,
            sin = math.sin,
            sinh = math.sinh,
            sqrt = math.sqrt,
            tan = math.tan,
            tanh = math.tanh
        }),

        --[[
            pcall = pcall,
            error = error,
            assert = assert,
            xpcall = xpcall
        ]]
    })

    for i = 1, #args, 2 do
        game.SandBox.overrideElementOfReadOnly(self.environment, args[i+1], args[i])
        table.insert(self.envNames, args[i+1])
    end

    setmetatable(self, SandBox)
    return self
end

function SandBox:eval(strs, interact)
    --interact = interact or false
    local i = 0
    local f, result = load(function() i = i + 1; return strs[i] end, self.sandboxName, "t", self.environment)
    local success
    if f then
        success, result = pcall(f)
    end

    if not success and result then
        if (type(result) == "table" and result.sandbox) or result:sub(1, #self.sandboxName - 1) == self.sandboxName:sub(2) then
            game.output:error(tostring(result))
            return
        end
        error(result)
    end
end

function SandBox.sendError(msg)
    msg = msg or "nil"
    local level = 1
    while true do
        local info = debug.getinfo(level, "Sl")
        if not info then break end
        if info.what == "main" then
            local e = setmetatable({sandbox = true}, {__tostring = function() return ("%s:%d: %s"):format(info.source:sub(2), info.currentline, msg) end})
            error(e)
        end
        level = level + 1
    end
end

--[[function SandBox.traceback(msg, level)
    level = level or 2
    local traceback = {"stack traceback"}
    if msg then
        table.insert(traceback, 1, msg)
    end
    while true do
        local info = debug.getinfo(level)
        if not info then break end
        if info.source:sub(1, 1) ~= "@" and info.source:sub(1, 1) ~= "=" then
            local line = ("%s:%d: in %s"):format(info.source, info.currentline, info.namewhat) .. (info.name and (" " .. info.name) or (" " .. "?"))
            table.insert(traceback, line)
        end
        level = level + 1
    end
    return table.concat(traceback, "\n")
end]]

-- Returns table whose elements can not be overrided.
function SandBox.setReadOnly(table)
    table.__type = "readonly"
    table.__index = table
    table.__newindex = function(_, k, v)
        -- error(string.format("You can not add or override \"%s\". This table is readonly.", k))
    end
    return setmetatable({}, table)
end

-- Overrides element of readonly table
function SandBox.overrideElementOfReadOnly(table, key, value)
    if string.sub(key, 1, 2) ~= "__" then
        local mt = getmetatable(table)
        mt[key] = value
    end
end

-- Used by only SandBox.
function SandBox:setProtected(table)
    table.__type = "protected"
    table.__index = table
    table.__newindex = function(_, k, v)
        local overlap = false
        if string.sub(k, 1, 2) == "__" then overlap = true end
        for pr in self.protected:gmatch("%a+") do
            if k == pr then overlap = true end
        end

        for _, name in ipairs(self.envNames) do
            if k == name then overlap = true end
        end

        if overlap then
            game.SandBox.sendError(string.format("The element \"%s\" is protected", k))
        else
            table[k] = v
        end
    end
    return setmetatable({}, table)
end



return SandBox