--[WARNING]: This file is imported into modclientmain.lua, be careful!

local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local _basic_init_fn = basic_init_fn
function basic_init_fn(inst, build_name, def_build, ...)
    if inst and inst.components.visualvariant then
        inst.components.visualvariant:Set()
    end
    return _basic_init_fn(inst, build_name, def_build, ...)
end