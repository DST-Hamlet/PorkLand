local assets =
{
    Asset("ANIM", "anim/pedestal_crate.zip"),
}

local function MakeShopkeeperSpeech(inst, speech)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, {"shopkeep"})
    for _, shopkeeper in ipairs(ents) do
        shopkeeper:ShopkeeperSpeech(speech)
    end
end

local function SetImage(inst, ent)
    local src = ent
    local image = nil

    if src ~= nil and src.components.inventoryitem ~= nil then
        image = src.prefab
        if src.components.inventoryitem then
            image = src.components.inventoryitem:GetImage():gsub("%.tex", "")
        end
    end

    if image ~= nil then
        local texname = image..".tex"
        inst.AnimState:OverrideSymbol("SWAP_SIGN", GetInventoryItemAtlas(texname), texname)
        --inst.AnimState:OverrideSymbol("SWAP_SIGN", "store_items", image)
        inst.imagename = image
    else
        inst.imagename = ""
        inst.AnimState:ClearOverrideSymbol("SWAP_SIGN")
    end
end

local function SetImageFromName(inst, name)
    local image = name

    if image ~= nil then
        local texname = image..".tex"
        inst.AnimState:OverrideSymbol("SWAP_SIGN", GetInventoryItemAtlas(texname), texname)
        --inst.AnimState:OverrideSymbol("SWAP_SIGN", "store_items", image)
        inst.imagename = image
    else
        inst.imagename = ""
        inst.AnimState:ClearOverrideSymbol("SWAP_SIGN")
    end
end

local function SetCost(inst, costprefab, cost)
    local image = nil

    if costprefab then
        image = costprefab
    end
    if costprefab == "oinc" and cost then
        image = "cost-"..cost
    end

    if image ~= nil then
        local texname = image..".tex"
        inst.AnimState:OverrideSymbol("SWAP_COST", GetInventoryItemAtlas(texname), texname)
        --inst.AnimState:OverrideSymbol("SWAP_SIGN", "store_items", image)
        inst.costimagename = image
    else
        inst.costimagename = ""
        inst.AnimState:ClearOverrideSymbol("SWAP_COST")
    end
end

local function SpawnInventory(inst, prefabtype, costprefab, cost)
    inst.costprefab = costprefab
    inst.cost = cost

    local item = nil
    if prefabtype ~= nil then
        item = SpawnPrefab(prefabtype)
    else
        item = SpawnPrefab(inst.prefabtype)
    end

    if item ~= nil then
        inst:SetImage(item)
        inst:SetCost(costprefab,cost)
        inst.components.shopdispenser:SetItem(item)
        item:Remove()
    end
end


local function TimedInventory(inst, prefabtype)
    inst.prefabtype = prefabtype
    local time = 300 + math.random() * 300
    inst.components.shopdispenser:RemoveItem()
    inst:SetImage(nil)
    inst:DoTaskInTime(time, function() inst:SpawnInventory(nil) end)
end

local function SoldItem(inst)
    inst.components.shopdispenser:RemoveItem()
    inst:SetImage(nil)
end

local function restock(inst, force)
    if inst:HasTag("nodailyrestock") then
        print("NO DAILY RESTOCK")
        return
    elseif inst:HasTag("robbed") then
        inst.costprefab = "cost-nil"
        SetCost(inst, "cost-nil")
        MakeShopkeeperSpeech("CITY_PIG_SHOPKEEPER_ROBBED")
    elseif (inst:IsInLimbo() and (inst.imagename == "" or math.random() < 0.16) and not inst:HasTag("justsellonce")) or force then
        print("CHANGING ITEM")
        local newproduct = inst.components.shopped.shop.components.shopinterior:GetNewProduct(inst.components.shopped.shoptype)
        if inst.saleitem then
            newproduct = inst.saleitem
        end
        SpawnInventory(inst, newproduct[1],newproduct[2],newproduct[3])
    end
end


local function displaynamefn(inst)
    return "whatever"
end

local function onsave(inst, data)
    data.imagename = inst.imagename
    data.costprefab = inst.costprefab
    data.cost = inst.cost
    data.interiorID = inst.interiorID
    data.startAnim = inst.startAnim
    data.saleitem = inst.saleitem
    data.justsellonce = inst:HasTag("justsellonce")
    data.nodailyrestock = inst:HasTag("nodailyrestock")
end

local function onload(inst, data)
    if data then
        if data.imagename then
            SetImageFromName(inst, data.imagename)
        end
        if data.cost then
            inst.cost = data.cost
        end
        if data.costprefab then
           inst.costprefab = data.costprefab
           SetCost(inst, inst.costprefab, inst.cost)
        end
        if data.interiorID then
            inst.interiorID  = data.interiorID
        end
        if data.startAnim then
            inst.startAnim = data.startAnim
            inst.AnimState:PlayAnimation(data.startAnim)
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
        inst.AnimState:PlayAnimation(inst.startAnim)
    end
end

local function common()
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

    inst:AddTag("shop_pedestal")

    inst.imagename = nil

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

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    inst.SetImage = SetImage
    inst.SetCost = SetCost
    inst.SetImageFromName = SetImageFromName
    inst.SpawnInventory = SpawnInventory
    inst.TimedInventory = TimedInventory
    inst.MakeShopkeeperSpeech = MakeShopkeeperSpeech
    inst.SoldItem = SoldItem

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.restock = restock

    inst.OnEntityWake = OnEntityWake

    return inst
end

local function buyer()
    local inst = common()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("shopdispenser")
    inst:AddComponent("shopped")

    inst:WatchWorldState("isday", restock)
    inst:WatchWorldState("isfiesta", restock)

    return inst
end

local function seller()
    local inst = common()
    return inst
end

return Prefab("shop_buyer", buyer, assets),
       Prefab("shop_seller", seller, assets)
