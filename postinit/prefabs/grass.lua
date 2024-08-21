local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("grass", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local _onregenfn = inst.components.pickable.onregenfn
    local function onregenfn(inst, ...)
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if NUTRIENT_TILES[tile] then
            local cycles_left = inst.components.pickable.cycles_left
            local tallgrass = ReplacePrefab(inst, "grass_tall")
            tallgrass.components.hackable.cycles_left = cycles_left
            tallgrass.components.hackable.onregenfn(tallgrass)
            return
        end
        _onregenfn(inst, ...)
    end
    inst.components.pickable.onregenfn = onregenfn
end)
