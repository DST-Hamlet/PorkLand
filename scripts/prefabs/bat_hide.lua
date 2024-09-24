local assets =
{
    Asset("ANIM", "anim/bat_leather.zip"),
}

local prefabs =
{
    "pigskin",
}

-- See postinit/prefabs/pigskin.lua
local function fn()
    local inst = Prefabs["pigskin"].fn(TheSim)
    inst.is_bat_hide = true
    inst:SetPrefabName("pigskin")
    return inst
end

return Prefab("bat_hide", fn, assets, prefabs)
