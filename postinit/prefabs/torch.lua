local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("torch", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local onattack = inst.components.weapon.onattack
    inst.components.weapon:SetOnAttack(function(weapon, attacker, target, ...)
        if not attacker.components.skilltreeupdater then
            if target and target:IsValid() and target.components.burnable and math.random() < TUNING.TORCH_ATTACK_IGNITE_PERCENT * target.components.burnable.flammability then
                target.components.burnable:Ignite(nil, attacker)
            end
            return
        end
        return onattack(weapon, attacker, target, ...)
    end)
end)
