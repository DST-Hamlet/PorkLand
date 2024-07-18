local assets =
{
    Asset("ANIM", "anim/shelf_slot.zip"),
}

local function GetItemName(inst)
    local item = inst.replica.visualshelfslot:GetItem()
    if item then
        return item:GetDisplayName()
    end

    return ""
end

local function GetItemDescription(inst, viewer)
    local item = inst.replica.visualshelfslot:GetItem()
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
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("shelf_slot")
    inst.AnimState:SetBank("shelf_slot")
    inst.AnimState:PlayAnimation("idle")
    -- inst.AnimState:Hide("mouseclick")

    -- inst:AddTag("NOCLICK")
    inst:AddTag("shelf_visual_slot")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOFORAGE")

    inst.displaynamefn = GetItemName

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = GetItemDescription

    inst:AddComponent("visualshelfslot")

    inst.persists = false

    return inst
end

return Prefab("visual_shelf_slot", fn, assets)
