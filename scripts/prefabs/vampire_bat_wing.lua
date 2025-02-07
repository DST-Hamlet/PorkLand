local assets =
{
    Asset("ANIM", "anim/batwing.zip"),
}

local prefabs =
{
    "batwing",
}

-- See postinit/prefabs/batwing.lua
local function fn()
    local inst = Prefabs["batwing"].fn(TheSim)
    inst.is_vampire_bat_wing = true
    inst:SetPrefabName("batwing")
    return inst
end

return Prefab("vampire_bat_wing", fn, assets, prefabs)
