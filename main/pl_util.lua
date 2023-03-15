local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

Pl_Util = {}
PLENV.Pl_Util = Pl_Util

local hidefns = {}
function Pl_Util.HideHackFn(hidefn, realfn)
    hidefns[hidefn] = realfn
end

local _debug_getupvalue = debug.getupvalue
function debug.getupvalue(fn, ...)
    local rets = {_debug_getupvalue(hidefns[fn] or fn, ...)}
    return unpack(rets)
end
Pl_Util.HideHackFn(debug.getupvalue, _debug_getupvalue)

local _debug_setupvalue = debug.setupvalue
function debug.setupvalue(fn, ...)
    local rets = {_debug_setupvalue(hidefns[fn] or fn, ...)}
    return unpack(rets)
end
Pl_Util.HideHackFn(debug.setupvalue, _debug_setupvalue)

function Pl_Util.GetUpvalue(fn, name, recurse_levels)
    assert(type(fn) == "function")

    recurse_levels = recurse_levels or 0
    local source_fn = fn
    local i = 1

	while true do
        local _name, value = debug.getupvalue(fn, i)
        if _name == nil then
            return
        elseif _name == name then
            return value, i, source_fn
        elseif type(value) == "function" and recurse_levels > 0 then
            local _value, _i, _source_fn = Pl_Util.GetUpvalue(value, name, recurse_levels - 1)
            if _value ~= nil then
                return _value, _i, _source_fn
            end
        end

        i = i + 1
	end
end

function Pl_Util.SetUpvalue(fn, value, name, recurse_levels)
    local _, i, source_fn = Pl_Util.GetUpvalue(fn, name, recurse_levels)
    debug.setupvalue(source_fn, i, value)
end

function Pl_Util.RegisterInventoryItemAtlas(atlas_path)
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
