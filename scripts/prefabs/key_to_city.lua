local assets = {
    Asset("ANIM", "anim/key_to_city.zip"),
}

local function OnActivate(inst)
    inst:DoTaskInTime(0, function()
        inst.SoundEmitter:KillSound("sound")
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding", "sound")

        if inst.killsoundtask then
            inst.killsoundtask:Cancel()
            inst.killsoundtask = nil
        end

        inst.killsoundtask = inst:DoTaskInTime(2, function()
            inst.SoundEmitter:KillSound("sound")
            inst.killsoundtask = nil
        end)
    end)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("keytocity")
    inst.AnimState:SetBuild("key_to_city")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetPriority(15)
    inst.MiniMapEntity:SetIcon("key_to_city.tex")

    inst:AddTag("prototyper")
    inst:AddTag("prototyper_ignore_inlimbo")
    inst:AddTag("no_interior_protoyping")
    inst:AddTag("irreplaceable")

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
