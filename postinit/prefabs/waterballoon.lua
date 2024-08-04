local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnSpreadProtection(inst, x, y, z)
    local wateryprotection = inst.components.wateryprotection
    local ents = TheSim:FindEntities(x, y, z, wateryprotection.protection_dist or 4, nil, wateryprotection.ignoretags)
    for _, v in pairs(ents) do
        if not v.components.moistureoverride and not v.components.moisture and not v.components.inventoryitemmoisture then
            v:AddComponent("moistureoverride")
            v:StartUpdatingComponent(v.components.moistureoverride)
        end

        if v.components.moistureoverride then
            v.components.moistureoverride:AddOnce(wateryprotection.addwetness)
        end
    end
end

AddPrefabPostInit("waterballoon", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.wateryprotection.onspreadprotectionfn = OnSpreadProtection
end)
