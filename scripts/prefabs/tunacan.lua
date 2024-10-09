local assets =
{
    Asset("ANIM", "anim/tuna.zip"),
}

local prefabs =
{
    "fishmeat_cooked",
}

local function OnUnWrappedFn(inst, pos, doer)
    if doer and doer.SoundEmitter then
        doer.SoundEmitter:PlaySound("dontstarve_DLC002/common/can_open")
    else
        --This sound does not play on client, presumably because the Remove gets networked/processed first. -from IA Mobstar
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/can_open")
    end
    local owner = inst.components.inventoryitem.owner
    inst:Remove()
    local steak = SpawnPrefab("fishmeat_cooked")
    if owner and owner.components.inventory then
        --TODO test if we're in the doers inv, remember the slot, and put the steak there. -from IA Mobstar
        --亚丹: 蜜罐也需要类似的机制, 使得转化后的产物和转化前的物品处于同一个格子
        owner.components.inventory:GiveItem(steak)
    else
        if steak.Physics ~= nil then
            steak.Physics:Teleport(pos:Get())
        else
            steak.Transform:SetPosition(pos:Get())
        end
        steak.components.inventoryitem:OnDropped(false, .5)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("tuna")
    inst.AnimState:SetBuild("tuna")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst:AddTag("tincan")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "tuna"

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 1

    inst:AddComponent("unwrappable")
    inst.components.unwrappable:SetOnUnwrappedFn(OnUnWrappedFn)

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("tunacan", fn, assets, prefabs)
