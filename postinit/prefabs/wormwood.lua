local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local function fn(inst)
    inst:AddTag("hayfeverimune")
end

PLENV.AddPrefabPostInit("wormwood", fn)
