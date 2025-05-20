local SHOPTYPES = require("prefabs/pig_shop_defs").SHOPTYPES

local assets =
{
    Asset("ANIM", "anim/pedestal_crate.zip"),
    Asset("ANIM", "anim/pedestal_crate_cloche.zip"),
    Asset("ANIM", "anim/pedestal_crate_cost.zip"),
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

local function GetNewProduct(inst)
    if not inst.shop_type then
        return
    end
    local items = TheWorld.state.isfiesta and SHOPTYPES[inst.shop_type .. "_fiesta"] or SHOPTYPES[inst.shop_type]
    if items then
        return GetRandomItem(items)
    end
end

local function SpawnInventory(inst, prefab, costprefab, cost)
    inst.components.shopped:SetCost(costprefab, cost)
    inst.components.shopped:SetItemToSell(prefab)
end

local function InitShop(inst, shop_type)
    inst.shop_type = shop_type
    local itemset = inst.saleitem or GetNewProduct(inst)
    SpawnInventory(inst, itemset[1], itemset[2], itemset[3])
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
        inst.components.shopped:SetCost("cost-nil", nil)
        inst:MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_ROBBED")
    elseif force or (inst:IsAsleep() and not inst:HasTag("justsellonce") and (not inst.components.shopped:GetItemToSell() or math.random() < 0.16)) then
        local newproduct = inst.saleitem or GetNewProduct(inst)
        SpawnInventory(inst, newproduct[1], newproduct[2], newproduct[3])
    end
end

local function OnSetCost(inst, cost_prefab, cost)
    local image = cost_prefab == "oinc" and cost and "cost-"..cost or cost_prefab
    if image then
        local texname = image..".tex"
        inst.costvisual.AnimState:OverrideSymbol("SWAP_COST", GetInventoryItemAtlas(texname), texname)
        -- inst.AnimState:OverrideSymbol("SWAP_SIGN", "store_items", image)
    else
        inst.costvisual.AnimState:ClearOverrideSymbol("SWAP_COST")
    end
end

local function OnRobbed(inst, robber)
    -- This is exposed through postinit/components/kramped.lua
    TheWorld.components.kramped:OnNaughtyAction(6, robber)
end

local function OnSave(inst, data)
    data.interiorID = inst.interiorID
    data.animation = inst.animation

    data.shop_type = inst.shop_type
    data.saleitem = inst.saleitem
    data.justsellonce = inst:HasTag("justsellonce")
    data.nodailyrestock = inst:HasTag("nodailyrestock")
end

local function OnLoad(inst, data)
    if data then
        inst.saleitem = data.saleitem
        inst.interiorID = data.interiorID
        inst.shop_type = data.shop_type

        if data.animation then
            inst.animation = data.animation
            inst.AnimState:PlayAnimation(data.animation)
            inst.clochevisual.AnimState:PlayAnimation(data.animation)
            inst.costvisual:UpdateVisual(data.animation)
        end

        if data.justsellonce then
            inst:AddTag("justsellonce")
        end
        if data.nodailyrestock then
            inst:AddTag("nodailyrestock")
        end
    end
end

local function OnEntityWake(inst)
    if TheWorld.state.isfiesta then
        inst.AnimState:PlayAnimation("idle_yotp")
        if TheWorld.ismastersim then
            inst.clochevisual.AnimState:PlayAnimation("idle_yotp")
            inst.costvisual:UpdateVisual("idle_yotp")
        end
    else
        inst.AnimState:PlayAnimation(inst.animation)
        if TheWorld.ismastersim then
            inst.clochevisual.AnimState:PlayAnimation(inst.animation)
            inst.costvisual:UpdateVisual(inst.animation)
        end
    end
end

local function OnItemGet(inst, data)
    if data and data.item and data.item.components.perishable then
        data.item.components.perishable:StopPerishing()
    end
end

local function OnItemLose(inst, data)
    if data and data.prev_item and data.prev_item.components.perishable then
        data.prev_item.components.perishable:StartPerishing()
    end
end

local function CreateClocheVisual(inst) -- 玻璃罩
    local clochevisual = SpawnPrefab("shop_buyer_clochevisual")
    clochevisual.parentshelf = inst
    clochevisual.entity:SetParent(inst.entity)
    return clochevisual
end

local function clochevisual_fn() -- 玻璃罩
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.persists = false

    inst.AnimState:SetBuild("pedestal_crate_cloche")
    inst.AnimState:SetBank("pedestal")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetFinalOffset(3)

    return inst
end

local front_cost_visuals =
{
    idle_traystand = true,
    idle_cablespool = true,
    idle_wagon = true,
    idle_cakestand_dome = true,
    idle_fridge_display = true,
    idle_mahoganycase = true,
    idle_stoneslab = true,
    idle_metal = true,
    idle_yotp = true,
    idle_marble_dome = true,
}

local function UpdateCostVisual(inst, anim)
    inst.AnimState:PlayAnimation(anim)
    if front_cost_visuals[anim] then
        inst.AnimState:SetFinalOffset(4)
        inst.Follower:FollowSymbol(inst.parentshelf.GUID, nil, 0, 0, 0.002) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）
    else
        inst.AnimState:SetFinalOffset(0)
        inst.Follower:FollowSymbol(inst.parentshelf.GUID, nil, 0, 0, 0.0005) -- 价格牌默认图层低于玻璃罩和物品，高于货架本体
    end
end

local function CreateCostVisual(inst) -- 价格牌
    local costvisual = SpawnPrefab("shop_buyer_costvisual")
    costvisual.parentshelf = inst
    costvisual.entity:SetParent(inst.entity)

    costvisual:UpdateVisual(inst.animation)

    return costvisual
end

local function costvisual_fn() -- 价格牌
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.persists = false

    inst.AnimState:SetBuild("pedestal_crate_cost")
    inst.AnimState:SetBank("pedestal")
    inst.AnimState:PlayAnimation("idle")

    inst.UpdateVisual = UpdateCostVisual -- 注意：在parent改变动画时需要调用这个函数以改变costvisual的动画

    return inst
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
    inst.AnimState:SetFinalOffset(-1)

    inst.anim_def = {}
    inst.anim_def.slot_bank = "lock12_west_visual_slot"
    inst.anim_def.slot_symbol_prefix = "SWAP_SIGN"
    inst.GetSlotSymbol = GetSlotSymbol

    inst:AddTag("NOCLICK")
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

    inst:AddComponent("gridnudger")

    inst.animation = "idle"

    inst.clochevisual = CreateClocheVisual(inst)

    inst:DoStaticTaskInTime(0, function()
        inst.clochevisual.Follower:FollowSymbol(inst.GUID, nil, 0, 0, 0.0015) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）
    end)

    inst.costvisual = CreateCostVisual(inst)

    inst:DoStaticTaskInTime(0, function()
        inst.costvisual:UpdateVisual(inst.animation) -- 毫无疑问，这是为了解决层级bug的屎山，因为有时SetFinalOffset会失效（特别是在离0点特别远的位置）
    end)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("shop_buyer")
    inst.components.container.CanTakeItemInSlot = function() return true end
    inst.components.container.Open = function() end
    inst.components.container.skipopensnd = true

    inst:AddComponent("visualslotmanager")

    inst:AddComponent("shopped")
    inst.components.shopped:OnSetCost(OnSetCost)
    inst.components.shopped:SetOnRobbed(OnRobbed)

    MakeHauntable(inst)

    inst.MakeShopkeeperSpeech = MakeShopkeeperSpeech
    inst.Restock = Restock
    inst.InitShop = InitShop

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnEntityWake = OnEntityWake

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)
    inst:WatchWorldState("cycles", function() inst:Restock() end)
    inst:WatchWorldState("isfiesta", function() inst:Restock() end)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("shop_buyer", fn, assets),
    Prefab("shop_buyer_clochevisual", clochevisual_fn, assets),
    Prefab("shop_buyer_costvisual", costvisual_fn, assets)
