local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function FreezeMovements(inst, should_freeze)
    inst._playerlink:AddOrRemoveTag("has_movements_frozen_follower", should_freeze)
    inst:AddOrRemoveTag("movements_frozen", should_freeze)
end

local HAUNT_CANT_TAGS = {"catchable", "DECOR", "FX", "haunted", "INLIMBO", "NOCLICK"}
local function DoGhostHauntTarget(inst, target)
    if (inst.sg and inst.sg:HasStateTag("nocommand"))
            or (inst.components.health and inst.components.health:IsDead()) then
        return
    end

    for _, cant_tag in pairs(HAUNT_CANT_TAGS) do
        if target:HasTag(cant_tag) then
            return
        end
    end

    inst._haunt_target = target
    inst:ListenForEvent("onremove", inst._OnHauntTargetRemoved, inst._haunt_target)
end

AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("do_ghost_haunt_target", DoGhostHauntTarget)
    inst.FreezeMovements = FreezeMovements
end)
