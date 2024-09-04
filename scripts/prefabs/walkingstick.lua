local assets =
{
    Asset("ANIM", "anim/pl_walking_stick.zip"),
    Asset("ANIM", "anim/swap_walking_stick.zip"),
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_walking_stick", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
    end
    inst._owner = owner
    inst:ListenForEvent("locomote", inst._onlocomote, owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
        inst._owner = nil
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

local function onwornout(inst)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("pl_cane")
    inst.AnimState:SetBuild("pl_walking_stick") -- name collision with Woodie's walking stick :/
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.WALKING_STICK_DAMAGE)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable.walkspeedmult = TUNING.WALKING_STICK_SPEED_MULT

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.WALKING_STICK_PERISHTIME)
    inst.components.fueled:SetDepletedFn(onwornout)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    inst._onlocomote = function(owner)
        if owner.components.locomotor.wantstomoveforward then
            if not inst.components.fueled.consuming then
                inst.components.fueled:StartConsuming()
            end
        elseif inst.components.fueled.consuming then
            inst.components.fueled:StopConsuming()
        end
    end

    return inst
end

return Prefab("walkingstick", fn, assets)
