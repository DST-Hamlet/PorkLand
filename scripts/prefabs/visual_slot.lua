local assets =
{
    Asset("ANIM", "anim/visual_slot.zip"),
    Asset("ANIM", "anim/inventory_fx_sparkle.zip"),
}

local function GetItemName(inst)
    local item = inst.replica.visualslot and inst.replica.visualslot:GetItem() or nil
    if item then
        return item:GetDisplayName()
    end

    return ""
end

local function GetItemDescription(inst, viewer)
    local item = inst.replica.visualslot and inst.replica.visualslot:GetItem() or nil
    if item and item.components.inspectable then
        return item.components.inspectable:GetDescription(viewer)
    end

    return ""
end

local function IsLowPriorityAction(act, force_inspect)
    return act and act.action == ACTIONS.HAMMER
end

local function CanMouseThrough(inst)
    local shelf = inst.replica.visualslot and inst.replica.visualslot:GetShelf() or nil
    if not inst:HasTag("fire") and ThePlayer ~= nil and ThePlayer.components.playeractionpicker ~= nil
        and shelf and shelf:IsValid() then
        local force_inspect = ThePlayer.components.playercontroller ~= nil and ThePlayer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT)
        local lmb, rmb = ThePlayer.components.playeractionpicker:DoGetMouseActions(inst:GetPosition(), shelf)
        return IsLowPriorityAction(rmb, force_inspect)
    end
end

local function DestOverride(inst)
    local shelf = inst.replica.visualslot:GetShelf()
    if shelf and shelf:IsValid() then
        return shelf.Transform:GetWorldPosition()
    end

    return inst.Transform:GetWorldPosition()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower() -- 由于visual_slot使用了FollowSymbol, 因此请尽量不要让它与逻辑相关, 除非再设置一个不使用由于visual_slot使用了FollowSymbol的parent
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("visual_slot")

    inst:AddTag("NOBLOCK")

    inst.displaynamefn = GetItemName

    inst.CanMouseThrough = CanMouseThrough

    inst.DestOverride = DestOverride

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
