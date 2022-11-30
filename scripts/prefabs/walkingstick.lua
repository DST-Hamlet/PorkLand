local assets =
{
	Asset("ANIM", "anim/walking_stick.zip"),
	Asset("ANIM", "anim/swap_walking_stick.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_walking_stick", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    inst.equipped = true
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    inst.equipped = false
    inst.components.fueled:StopConsuming()
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

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    -- MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.AnimState:SetBank("walking_stick")
    inst.AnimState:SetBuild("walking_stick")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("walkingstick")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.WALKING_STICK_DAMAGE)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.WALKING_STICK_SPEED_MULT

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = "USAGE"
    inst.components.fueled:InitializeFuelLevel(TUNING.WALKING_STICK_PERISHTIME)
    inst.components.fueled:SetDepletedFn(onwornout)

    local player = ThePlayer
    inst:ListenForEvent("locomote", function()
            if player.sg and player.sg:HasStateTag("moving") and inst.equipped then
                inst.components.fueled:StartConsuming()
            else
                inst.components.fueled:StopConsuming()
        end
    end)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("walkingstick", fn, assets)
