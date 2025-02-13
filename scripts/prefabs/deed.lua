local assets =
{
    Asset("ANIM", "anim/deed.zip"),
}

local function GetRevealTargetPos(inst)
    if not TheWorld.playerhouse then
        return
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInterior(x, z) then
        return
    end
    return TheWorld.playerhouse:GetPosition()
end

local function OnBought(inst)
    print("DEED BOUGHT")
    TheWorld:PushEvent("deedbought")
end

local function fn(inst)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("deed")
    inst.AnimState:SetBuild("deed")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("treasuremap")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("mapspotrevealer")
    inst.components.mapspotrevealer:SetGetTargetFn(GetRevealTargetPos)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"

    inst:AddComponent("erasablepaper")

    inst.OnBought = OnBought

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("deed", fn, assets)
