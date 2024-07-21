local assets =
{
    Asset("ANIM", "anim/visual_slot.zip"),
    Asset("ANIM", "anim/inventory_fx_sparkle.zip"),
}

local function GetItemName(inst)
    local item = inst.replica.visualslot:GetItem()
    if item then
        return item:GetDisplayName()
    end

    return ""
end

local function GetItemDescription(inst, viewer)
    local item = inst.replica.visualslot:GetItem()
    if item and item.components.inspectable then
        return item.components.inspectable:GetDescription(viewer)
    end

    return ""
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("visual_slot")

    inst:AddTag("NOBLOCK")

    inst.displaynamefn = GetItemName

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = GetItemDescription

    inst:AddComponent("visualslot")

    inst.persists = false

    return inst
end

return Prefab("visual_slot", fn, assets)
