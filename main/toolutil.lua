local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

ToolUtil = {}
PLENV.ToolUtil = ToolUtil

local hidefns = {}
function ToolUtil.HideFn(hidefn, realfn)
    hidefns[hidefn] = realfn
end

local _debug_getupvalue = debug.getupvalue
function debug.getupvalue(fn, ...)
    return _debug_getupvalue(hidefns[fn] or fn, ...)
end
ToolUtil.HideFn(debug.getupvalue, _debug_getupvalue)

local _debug_setupvalue = debug.setupvalue
function debug.setupvalue(fn, ...)
    return _debug_setupvalue(hidefns[fn] or fn, ...)
end
ToolUtil.HideFn(debug.setupvalue, _debug_setupvalue)

-- `GetUpvalue` and `SetUpvalue` were modified base on the upvalue tool designed by Rezecib

local function upvalue_iter(fn)
    local i = 0
    return function()
        i = i + 1
        local value_name, value = debug.getupvalue(fn, i)
        return value_name, value, i
    end
end

-- Find the upvalue by comparing the names through all upvalues,
-- returns the value and the up index
local function find_upvalue(fn, name)
    for value_name, value, index in upvalue_iter(fn) do
        if value_name == name then
            return value, index
        end
    end
end

local MAX_UPVALUE_SEARCH_DEPTH = 3

--- Returns the upvalue, the up index, and the scope function
---
--- ## Examples:
---
--- ```lua
--- local telestaff_constructor = Prefabs["telestaff"].fn
--- local teleport_start, teleport_func, i = ToolUtil.GetUpvalue(telestaff_constructor, "teleport_func.teleport_start")
--- debug.setupvalue(teleport_func, i, function(...) print("hooked") return teleport_start(...) end)
--- ```
---@param fn function
---@param path string
---@return any, function, number
function ToolUtil.GetUpvalue(fn, path, depth)
    if not depth then
        depth = 1
    end

    local value, scope_fn, index = fn, nil, nil ---@type any, function | nil, number | nil

    for part in path:gmatch("[^%.]+") do
        scope_fn = value
        value, index = find_upvalue(value, part)

        if value == nil then
            -- Another mod might be hooking the function,
            -- we search all the upvalues inside this function and see if there's a match
            if depth < MAX_UPVALUE_SEARCH_DEPTH then
                for _, value in upvalue_iter(fn) do
                    if type(value) == "function" then
                        local value, scope_fn, index = ToolUtil.GetUpvalue(value, path, depth + 1)
                        if value then
                            return value, scope_fn, index
                        end
                    end
                end
            end
            break
        end
    end

    return value, scope_fn, index
end

---@param fn function
---@param path string
---@param value any
function ToolUtil.SetUpvalue(fn, path, value)
    local _, scope_fn, index = ToolUtil.GetUpvalue(fn, path)
    debug.setupvalue(scope_fn, index, value)
end

---@param t table
function ToolUtil.IsArray(t)
    if type(t) ~= "table" or not next(t) then
        return false
    end

    local n = #t
    for i, v in pairs(t) do
        if type(i) ~= "number" or i <= 0 or i > n then
            return false
        end
    end

    return true
end

---@param target table
---@param add_table table
---@param override boolean
function ToolUtil.MergeTable(target, add_table, override)
    target = target or {}

    for k, v in pairs(add_table) do
        if type(v) == "table" then
            if not target[k] then
                target[k] = {}
            elseif type(target[k]) ~= "table" then
                if override then
                    target[k] = {}
                else
                    error("Can not override" .. k .. " to a table")
                end
            end

            ToolUtil.MergeTable(target[k], v, override)
        else
            if ToolUtil.IsArray(target) and not override then
                table.insert(target, v)
            elseif not target[k] or override then
                target[k] = v
            end
        end
    end
end

function ToolUtil.RegisterInventoryItemAtlas(atlas_path)
    local atlas = resolvefilepath(atlas_path)

    local file = io.open(atlas, "r")
    local data = file:read("*all")
    file:close()

    local str = string.gsub(data, "%s+", "")
    local _, _, elements = string.find(str, "<Elements>(.-)</Elements>")

    for s in string.gmatch(elements, "<Element(.-)/>") do
        local _, _, image = string.find(s, "name=\"(.-)\"")
        if image ~= nil then
            RegisterInventoryItemAtlas(atlas, image)
            RegisterInventoryItemAtlas(atlas, hash(image))  -- for client
        end
    end
end

---@param class table
---@param prop_key string
---@param pre_fn function | nil
---@param post_fn function | nil
function ToolUtil.HookSetter(class, prop_key, pre_fn, post_fn)
    local _ = rawget(class, "_")
    local prop = _[prop_key]
    assert(_ ~= nil, "Class does not support property setters")
    assert(_[prop_key] ~= nil, "Class does not " .. prop_key .. " setters")

    local fn = prop[2]
    prop[2] = function(...)
        if pre_fn then pre_fn(...) end
        fn(...)
        if post_fn then post_fn(...) end
    end
end
