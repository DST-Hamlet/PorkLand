local assets =
{
    Asset("ANIM", "anim/antsuit.zip"),
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "antsuit", "swap_body")
    inst.components.fueled:StartConsuming()
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst.components.fueled:StopConsuming()
    if owner.components.leader then
        owner:DoTaskInTime(0, function() -- in case of equipment swapping 
            if not IsPlayerInAntDisguise(owner) then
                owner.components.leader:RemoveFollowersByTag("ant")
            end
        end)
    end
end

local function FueledUpdateFn(inst)
    inst.components.armor:SetPercent(inst.components.fueled:GetPercent())
end

local function OnTakenDamage(inst, damage_amount)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/antsuit/hit")

    if inst.components.fueled then
        local percent = inst.components.fueled:GetPercent()
        local new_percent = percent - (damage_amount * inst.components.armor.absorb_percent / inst.components.armor.maxcondition)
        inst.components.fueled:SetPercent(new_percent)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "anim")

    inst.AnimState:SetBank("antsuit")
    inst.AnimState:SetBuild("antsuit")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("antsuit")

    inst.foleysound = "dontstarve_DLC003/common/crafted/antsuit/foley"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMORWOOD, TUNING.ARMORWOOD_ABSORPTION)
    inst.components.armor.ontakedamage = OnTakenDamage

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.ANTSUIT_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)
    inst.components.fueled:SetUpdateFn(FueledUpdateFn)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("antsuit", fn, assets)
