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

--Tool designed by Rezecib.
---@param fn function
---@param name string
---@return any, number | nil
local function get_upvalue(fn, name)
    local i = 1
    while true do
        local value_name, value = debug.getupvalue(fn, i)
        if value_name == name then
            return value, i
        elseif value_name == nil then
            return
        end
        i = i + 1
    end
end

---@param fn function
---@param path string
---@return any, number, function
function ToolUtil.GetUpvalue(fn, path)
    local value, prv, i = fn, nil, nil ---@type any, function | nil, number | nil
    for part in path:gmatch("[^%.]+") do
        print(part)
        prv = fn
        value, i = get_upvalue(value, part)
        assert(i ~= nil, "could't find " .. path)
    end
    return value, i, prv
end

---@param fn function
---@param path string
---@param value any
function ToolUtil.SetUpvalue(fn, value, path)
    local _, i, source_fn = ToolUtil.GetUpvalue(fn, path)
    debug.setupvalue(source_fn, i, value)
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
