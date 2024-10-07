local AddPrefabPostInitAny = AddPrefabPostInitAny
GLOBAL.setfenv(1, GLOBAL)

local VARIANTS = require("main/visualvariant_defs").VARIANTS

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if VARIANTS[inst.prefab] and inst.components.visualvariant == nil then
        inst:AddComponent("visualvariant")
        inst.components.visualvariant:SetVariantData(inst.prefab)
    end
end)
