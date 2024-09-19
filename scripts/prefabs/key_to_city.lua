local assets = {
    Asset("ANIM", "anim/key_to_city.zip"),
}

local function OnActivate(inst)
    -- inst.AnimState:PlayAnimation("use")
    -- inst.AnimState:PushAnimation("idle")
    -- inst.AnimState:PushAnimation("proximity_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_run", "sound")

    inst:DoTaskInTime(1.5, function()
        inst.SoundEmitter:KillSound("sound")
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding", "sound")
    end)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("keytocity")
    inst.AnimState:SetBuild("key_to_city")
    inst:AddTag("prototyper")
    inst:AddTag("no_interior_protoyping")
    inst:AddTag("irreplaceable")

    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("prototyper")
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.CITY
    inst.components.prototyper.onactivate = OnActivate

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("key_to_city", fn, assets)
