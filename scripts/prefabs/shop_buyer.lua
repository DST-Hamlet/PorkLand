local assets =
{
    Asset("ANIM", "anim/pedestal_crate.zip"),
}

local function GetSlotSymbol(inst, slot)
    return inst.anim_def.slot_symbol_prefix .. slot
end

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            TheWorld.Pathfinder:AddWall(inst._pfpos:Get())
        end
    elseif inst._pfpos ~= nil then
        TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get())
        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function MakeObstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

local function ClearObstacle(inst)
    inst.Physics:SetActive(false)
    inst._ispathfinding:set(false)
end

local function onremove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

local function OnEntityWake(inst)
    if TheWorld.state.isfiesta then
        inst.AnimState:PlayAnimation("idle_yotp")
    else
        inst.AnimState:PlayAnimation(inst.animation)
    end
end

local function MakeShopkeeperSpeech(inst, speech)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, {"shopkeep"})
    for _, shopkeeper in ipairs(ents) do
        shopkeeper:ShopkeeperSpeech(speech)
    end
end

local function Restock(inst, force)
    if inst:HasTag("nodailyrestock") then
        -- print("NO DAILY RESTOCK")
        return
    elseif inst:HasTag("robbed") then
        inst.components.shopped:SetCost("cost-nil")
        MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_ROBBED")
    elseif force or (inst:IsAsleep() and not inst:HasTag("justsellonce") and (not inst.components.shopped:GetItemToSell() or math.random() < 0.16)) then
        print("CHANGING ITEM")
        local newproduct = inst.saleitem or inst.components.shopped:GetNewProduct()
        inst.components.shopped:SpawnInventory(newproduct[1], newproduct[2], newproduct[3])
    end
end

local function OnSetCost(inst, cost_prefab, cost)
    local image = cost_prefab == "oinc" and cost and "cost-"..cost or cost_prefab
    if image then
        local texname = image..".tex"
        inst.AnimState:OverrideSymbol("SWAP_COST", GetInventoryItemAtlas(texname), texname)
        -- inst.AnimState:OverrideSymbol("SWAP_SIGN", "store_items", image)
    else
        inst.AnimState:ClearOverrideSymbol("SWAP_COST")
    end
end

local function OnSave(inst, data)
    data.interiorID = inst.interiorID
    data.animation = inst.animation

    data.saleitem = inst.saleitem
    data.justsellonce = inst:HasTag("justsellonce")
    data.nodailyrestock = inst:HasTag("nodailyrestock")
end

local function OnLoad(inst, data)
    if data then
        if data.interiorID then
            inst.interiorID  = data.interiorID
        end
        if data.animation then
            inst.animation = data.animation
            inst.AnimState:PlayAnimation(data.animation)
        end
        if data.saleitem then
            inst.saleitem = data.saleitem
        end
        if data.justsellonce then
            inst:AddTag("justsellonce")
        end
        if data.nodailyrestock then
            inst:AddTag("nodailyrestock")
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("accomplishment_shrine.tex")

    MakeObstaclePhysics(inst, .25)

    inst.AnimState:SetBank("pedestal")
    inst.AnimState:SetBuild("pedestal_crate")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetFinalOffset(1)

    inst.anim_def = {}
    inst.anim_def.slot_bank = "lock12_west_visual_slot"
    inst.anim_def.slot_symbol_prefix = "SWAP_SIGN"
    inst.GetSlotSymbol = GetSlotSymbol

    inst:AddTag("shop_pedestal")

    ------- Copied from prefabs/wall.lua -------
    inst._pfpos = nil
    inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
    MakeObstacle(inst)
    -- Delay this because makeobstacle sets pathfinding on by default
    -- but we don't to handle it until after our position is set
    inst:DoTaskInTime(0, InitializePathFinding)

    inst:ListenForEvent("onremove", onremove)
    --------------------------------------------

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("shelf_")
    inst.components.container.Open = function() end
    inst.components.container.skipopensnd = true

    inst:AddComponent("shopped")
    inst.components.shopped:OnSetCost(OnSetCost)

    inst:AddComponent("visualslotmanager")

    inst.MakeShopkeeperSpeech = MakeShopkeeperSpeech
    inst.Restock = Restock

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnEntityWake = OnEntityWake

    inst:WatchWorldState("cycle", function() inst:Restock() end)
    inst:WatchWorldState("isfiesta", function() inst:Restock() end)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("shop_buyer", fn, assets)
