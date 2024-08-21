local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function startrowing(inst, data)
    inst.components.equippable.onunequipfn(inst, data and data.owner or nil)
    if inst.components.inventoryitem.onputininventoryfn then -- this should be "turnoff"
        inst.components.inventoryitem.onputininventoryfn(inst, data and data.owner or nil)
    end
end
local function stoprowing(inst, data)
    inst.components.equippable.onequipfn(inst, data and data.owner or nil)
end

local function PostInit(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("startrowing", startrowing)
    inst:ListenForEvent("stoprowing", stoprowing)
end

AddPrefabPostInit("redlantern", PostInit)
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

    PostInit(inst)
end)
