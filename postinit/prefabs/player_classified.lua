local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnPoisonDamage(parent, data)
    parent.player_classified.poisonpulse:set_local(true)
    parent.player_classified.poisonpulse:set(true)
end

local function OnPoisonPulseDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("poisondamage")
    end
end

local function RegisterNetListeners(inst)
    if TheWorld.ismastersim then
        inst._parent = inst.entity:GetParent()
        inst:ListenForEvent("poisondamage", OnPoisonDamage, inst._parent)
    else
        inst.poisonpulse:set_local(false)
        inst:ListenForEvent("poisonpulsedirty", OnPoisonPulseDirty)
    end
end

AddPrefabPostInit("player_classified", function(inst)
    inst.ispoisoned = inst.ispoisoned or net_bool(inst.GUID, "poisonable.ispoisoned")
    inst.poisonpulse = inst.poisonpulse or net_bool(inst.GUID, "poisonable.poisonpulse", "poisonpulsedirty")

    inst.externalspeedmultiplier_decelerate = net_float(inst.GUID, "locomotor.externalspeedmultiplier_decelerate")
    inst.externalspeedmultiplier_decelerate:set(1)

    inst:DoTaskInTime(0, RegisterNetListeners)
end)
