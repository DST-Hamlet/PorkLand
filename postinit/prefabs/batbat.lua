local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("batbat", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _onattack = inst.components.weapon.onattack
    inst.components.weapon.onattack = function (inst, owner, target, ...)
        if not target:HasTag("no_durability_loss_on_hit") then
            _onattack(inst, owner, target, ...)
        end
    end
end)
