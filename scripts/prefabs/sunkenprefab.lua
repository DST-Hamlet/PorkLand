local SHADER = "shaders/anim_sunken.ksh"

local assets =
{
    Asset("ANIM", "anim/bubbles_sunk.zip"),
    Asset("ANIM", "anim/sunken_visual_slot.zip"),
    Asset("SHADER", SHADER),
}



local function ontimerdone(inst, data)
    if data.name == "destroy" then
        inst:Remove()
    end
end

local function dobubblefx(inst)
    inst.AnimState:PlayAnimation("bubble_pre")
    inst.AnimState:PushAnimation("bubble_loop")
    inst.AnimState:PushAnimation("bubble_pst", false)
    inst:DoTaskInTime((math.random() * 15 + 15), dobubblefx)
end

local function UpdateVisual(inst)
    if not inst.visual then
        inst.visual = SpawnPrefab("sunkenvisual")
        inst.highlightchildren = {inst.visual}
        inst._sunkenvisual:set(inst.visual)
    end
    inst.visual:SetUp(inst, inst.components.container:GetItemInSlot(1))

    if inst.components.container:IsEmpty() then
        inst.persists = false
        inst:DoTaskInTime(0, inst.Remove)
    end
end

local function init(inst, item)
    if not item then
        inst:Remove()
        return
    end

    inst.Transform:SetPosition(item.Transform:GetWorldPosition())

    if item and (item.components.health or item.components.murderable) then -- 复制自ACTIONS.MURDER.fn
        if item.components.lootdropper then
            local stacksize = item.components.stackable and item.components.stackable:StackSize() or 1
            for i = 1, stacksize do
                if item.inventoryloot then
                    item.components.lootdropper:SetChanceLootTable(item.inventoryloot)
                end
                local loots = item.components.lootdropper:GenerateLoot()
                for k, v in pairs(loots) do
                    local loot = SpawnPrefab(v)
                    if loot then
                        loot.Transform:SetPosition(item.Transform:GetWorldPosition())
                        SinkEntity(loot)
                    end
                end
            end
        end
        item:Remove()
    else
        if not inst.components.container:GiveItem(item, nil, nil, false) then
            item:Remove()
        end
    end

    if inst.components.container:IsEmpty() then
        inst:Remove()
    end

    inst.components.timer:StartTimer("destroy", TUNING.SUNKENPREFAB_REMOVE_TIME)
end

local function OnItemGet(inst, data)
    inst:UpdateVisual()

    if data.item and data.item.components.inventoryitemmoisture then
        data.item.components.inventoryitemmoisture:DoDelta(TUNING.MAX_WETNESS)
        data.item.components.inventoryitemmoisture.moisture_override = TUNING.MAX_WETNESS
    end
end

local function OnItemLose(inst, data)
    inst:UpdateVisual()

    if data.prev_item and data.prev_item:IsValid() and data.prev_item.components.inventoryitemmoisture then
        data.prev_item.components.inventoryitemmoisture.moisture_override = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("bubbles_sunk")
    inst.AnimState:SetBuild("bubbles_sunk")

    inst:AddTag("sunkencontainer")
    inst:AddTag("fishable")
    inst:AddTag("wet")
    inst:AddTag("NOBLOCK")
    inst:AddTag("spoiler")

    inst._sunkenvisual = net_entity(inst.GUID, "_sunkenvisual", "sunkenvisualdirty")

    inst:SetPrefabNameOverride("SUNKEN_RELIC")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("sunkenvisualdirty", function() inst.highlightchildren = {inst._sunkenvisual:value()} end)
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("sunkenprefab")
    inst.components.container.canbeopened = false

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst:DoTaskInTime((math.random() * 15 + 15), dobubblefx)

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    inst.UpdateVisual = UpdateVisual
    inst.Initialize = init

    return inst
end

local function SetUp(inst, parent, item)
    if item ~= nil then
        inst.AnimState:OverrideSymbol("visual_slot", item.replica.inventoryitem:GetAtlas(), item.replica.inventoryitem:GetImage())
    else
        inst.AnimState:ClearOverrideSymbol("visual_slot")
    end

    inst.entity:SetParent(parent.entity)
    inst.Transform:SetPosition(0, 0, 0)
    inst.Follower:FollowSymbol(parent.GUID, nil, 0, 100, 0)
end

local function SunkenVisualfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("noblock")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath(SHADER))
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MIN)
    inst.AnimState:SetMultColour(0.0, 0.0, 0.0, 1)
    inst.AnimState:SetBank("sunken_visual_slot")
    inst.AnimState:SetBuild("sunken_visual_slot")
    inst.AnimState:PlayAnimation("idle")

    inst.persists = false

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetUp = SetUp

    return inst
end

return Prefab("sunkenprefab", fn, assets),
    Prefab("sunkenvisual", SunkenVisualfn, assets)
