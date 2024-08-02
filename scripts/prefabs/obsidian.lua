local assets =
{
    Asset("ANIM", "anim/obsidian.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations( "idle_water", "idle")

    inst.AnimState:SetBank("obsidian")
    inst.AnimState:SetBuild("obsidian")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("molebait")
    --waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")

    inst.no_wet_prefix = true

    inst.entity:SetPristine()

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("on_landed", function()
            if inst.components.floater:ShouldShowEffect() then -- we landed on water
                inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/obsidian_wetsizzles")
            end
        end)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("inventoryitem")

    inst:AddComponent("bait")

    MakeHauntableLaunch(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.HEAVY, TUNING.WINDBLOWN_SCALE_MAX.HEAVY)

    return inst
end

return Prefab("obsidian", fn, assets)
