local assets =
{
    Asset("ANIM", "anim/sandhill.zip")
}

local function ongustblowawayfn(inst)
    inst.components.disappears:Disappear()
    return true
end

local function OnHaunt(inst)
    inst.components.disappears:Disappear()
    return true
end

local function sandfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("sandhill")
    inst.AnimState:SetBank("sandhill")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("disappears")
    inst.components.disappears.sound = "dontstarve/common/dust_blowaway"
    inst.components.disappears.anim = "disappear"

    inst:AddComponent("inspectable")
    -----------------
    inst:AddComponent("stackable")
    -----------------
    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown_on_successful_haunt = false
    inst.components.hauntable.usefx = false
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)
    -----------------
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    ----------------------

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.SAND_WINDBLOWN_SPEED)
    inst.components.blowinwindgust:SetDestroyChance(TUNING.SAND_WINDBLOWN_FALL_CHANCE)
    inst.components.blowinwindgust:SetDestroyFn(ongustblowawayfn)

    return inst
end

return Prefab("sand", sandfn, assets)
