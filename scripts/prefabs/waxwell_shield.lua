local assets = {
    Asset("ANIM", "anim/forcefield.zip"),
}

local prefabs = {
    "forcefieldfx"
}

local function RemoveShield(inst)
    if inst._fx then
        inst._fx:Remove()
    end
    if inst.erode_task then
        inst.erode_task:Cancel()
    end
    inst:Remove()
end

local function OnDeath(inst, data)
    inst.erode_task = inst:DoTaskInTime(10 * FRAMES, function()
        if inst._owner:IsValid() then
            inst._owner.components.health:DoDelta(-1)
            inst._owner.components.combat.redirectdamagefn = nil
            inst._owner:Remove("has_shadow_shield")
        end

        RemoveShield(inst)
    end)
end

local function SetOwner(inst, owner)
    if inst._owner then
        return
    end
    inst._owner = owner
    inst._owner:AddTag("has_shadow_shield")
    assert(inst._owner.components.combat.redirectdamagefn == nil) -- THIS NEEDS TO BE NIL!!!! -- TODO: remove assert in product
    inst._owner.components.combat.redirectdamagefn = function(owner_inst, attacker, damage, weapon, stimuli, spdamage)
        return inst -- you might want to specify which damage this can block
    end

    if inst._fx ~= nil then
        inst._fx:kill_fx()
    end
    inst._fx = SpawnPrefab("forcefieldfx")
    inst._fx.entity:SetParent(owner.entity)
    inst._fx.Transform:SetPosition(0, 0.2, 0)

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("death", RemoveShield, inst._owner)
    -- could add a onhit event here
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(75)
    inst.components.health:StartRegen(-1, 1)
    inst.components.health.nofadeout = true -- manage remove event manually

    inst:AddComponent("combat") -- for redirectdamagefn

    inst.SetOwner = SetOwner
    inst.persists = false

    return inst
end

return Prefab("waxwell_shield", fn, assets, prefabs)
