local visualboatequip = require("prefabs/visualboatequip")

local net_assets=
{
    Asset("ANIM", "anim/swap_trawlnet.zip"),
    Asset("ANIM", "anim/swap_trawlnet_half.zip"),
    Asset("ANIM", "anim/swap_trawlnet_full.zip"),
}

local dropped_assets=
{
    Asset("ANIM", "anim/swap_trawlnet.zip"),
    -- Asset("ANIM", "anim/ui_chest_3x2.zip"),
}

local LOOT_DEFS = require("prefabs/trawlnet_loot_defs")

local GetLootTable = LOOT_DEFS.GetLootTable

local UNIQUE_ITEMS = LOOT_DEFS.UNIQUE_ITEMS
local SPECIAL_CASE_PREFABS = LOOT_DEFS.SPECIAL_CASE_PREFABS


local function gettrawlbuild(inst)
    if not inst.components.inventory then return "swap_trawlnet" end
    local fullness = inst.components.inventory:NumItems()/inst.components.inventory.maxslots
    if fullness <= 0.33 then
        return "swap_trawlnet"
    elseif fullness <= 0.66 then
        return "swap_trawlnet_half"
    else
        return "swap_trawlnet_full"
    end
end

local function ontrawlpickup(inst, numitems, pickup)
    local owner = inst.components.inventoryitem.owner
    local sailor = nil

    if owner and owner.components.sailable then
        sailor = owner.components.sailable.sailor
        if inst.visual then
            inst.visual.AnimState:SetBuild(gettrawlbuild(inst))
        end
        if sailor then
            if pickup.components.weighable ~= nil then
                pickup.components.weighable:SetPlayerAsOwner(sailor)
            end

            sailor:PushEvent("trawlitem")
            inst.trawlitem:set_local(true)
            inst.trawlitem:set(true)
        end
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/collect")
end


local function updatespeedmult(inst)
    local fullpenalty = TUNING.TRAWLING_SPEED_MULT
    local penalty = fullpenalty * (inst.components.inventory:NumItems()/TUNING.TRAWLNET_MAX_ITEMS)

    local owner = inst.components.inventoryitem.owner
    if owner and owner.components.sailable then
        local sailor = owner.components.sailable.sailor
        if sailor then
            sailor.components.locomotor:SetExternalSpeedMultiplier(inst, "TRAWL", 1 - penalty)
        end
    end
end

local function pickupitem(inst,pickup)
    if pickup then
        local num = inst.components.inventory:NumItems()
        inst.components.inventory:GiveItem(pickup, num + 1)
        ontrawlpickup(inst, num + 1, pickup)

        if inst.components.inventory:IsFull() then
            local owner = inst.components.inventoryitem.owner
            if owner then
                if owner.components.sailable and owner.components.sailable.sailor then
                    owner.components.sailable.sailor:PushEvent("trawl_full")
                end
                owner.components.container:DropItem(inst)
            end
        else
            updatespeedmult(inst)
        end
    end
end

local function isItemUnique(item)
    for i = 1, #UNIQUE_ITEMS do
        if UNIQUE_ITEMS[i] == item then
            return true
        end
    end
    return false
end

local function hasUniqueItem(inst)
    for k,v in pairs(inst.components.inventory.itemslots) do
        for i = 1, #UNIQUE_ITEMS do
            if UNIQUE_ITEMS[i] == v then
                return true
            end
        end
    end

    return false
end

local function getLootList(inst)
    local loottable = GetLootTable(inst)

    return loottable
end

local function selectLoot(inst)
    local total = 0
    local lootList = getLootList(inst)

    for i = 1, #lootList do
        total = total + lootList[i][2]
    end

    local choice = math.random(0,total)
    total = 0
    for i = 1, #lootList do
        total = total + lootList[i][2]
        if choice <= total then
            local loot = lootList[i][1]

            --Check if the player has already found one of these
            if isItemUnique(loot) and hasUniqueItem(inst) then
                --If so, pick a different item to give
                loot = selectLoot(inst)
                --NOTE - Possible infinite loop here if only possible loot is unique items.
            end

            return loot
        end
    end
end

local function droploot(inst, owner)
    local chest = SpawnPrefab("trawlnetdropped")
    local pt = inst:GetPosition()

    chest:DoDetach()

    chest.Transform:SetPosition(pt.x, pt.y, pt.z)

    local slotnum = 1
    for k,v in pairs(inst.components.inventory.itemslots) do
        chest.components.container:GiveItem(v, slotnum)
        slotnum = slotnum + 1
    end

    if owner and owner.components.sailable and owner.components.sailable.sailor then
        local sailor = owner.components.sailable.sailor
        local angle = sailor.Transform:GetRotation()
        local dist = -3
        local offset = Vector3(dist * math.cos(angle*DEGREES), 0, -dist*math.sin(angle*DEGREES))
        local chestpos = sailor:GetPosition() + offset
        chest.Transform:SetPosition(chestpos:Get())
        chest:FacePoint(pt:Get())
    end
end

local function generateLoot(inst)
    return SpawnPrefab(selectLoot(inst))
end

local function stoptrawling(inst)
    inst.trawling = false
    if inst.trawltask then
        inst.trawltask:Cancel()
    end
end

local function IsBehind(inst, tar)
    local pt = inst:GetPosition()
    local hp = tar:GetPosition()

    local heading_angle = -(inst.Transform:GetRotation())
    local dir = Vector3(math.cos(heading_angle*DEGREES),0, math.sin(heading_angle*DEGREES))

    local offset = (hp - pt):GetNormalized()
    local dot = offset:Dot(dir)

    local dist = pt:Dist(hp)

    return dot <= 0 and dist >= 1
end

local TRAWL_CANT_ITEM_TAGS = {"FX", "NOCLICK"}
local function CanTrawlItem(item)
    return item.components.inventoryitem ~= nil
        and not item.components.inventoryitem:IsHeld()
        and item.components.inventoryitem.cangoincontainer
        and item.components.floater ~= nil
        and not item:HasOneOfTags(TRAWL_CANT_ITEM_TAGS)
end

local TRAWL_CANT_TAGS = {"trap", "player"}
local function updateTrawling(inst)
    if not inst.trawling then
        return
    end

    local owner = inst.components.inventoryitem.owner
    local sailor = nil

    if owner and owner.components.sailable then
        sailor = owner.components.sailable.sailor
    end

    if not sailor then
        print("NO SAILOR IN TRAWLNET?! SOMETHING WENT WRONG!")
        stoptrawling(inst)
        return
    end

    local pickup = nil
    local pos = inst:GetPosition()
    local displacement = pos - inst.lastPos
    inst.distanceCounter = inst.distanceCounter + displacement:Length()

    if inst.distanceCounter > TUNING.TRAWLNET_ITEM_DISTANCE then
        pickup = generateLoot(inst)
        inst.distanceCounter = 0
    end

    inst.lastPos = pos
    -- TODO: oceanfishable support! -Half
    if not pickup then
        local range = 2
        pickup = FindEntity(sailor, range, function(item)
            return SPECIAL_CASE_PREFABS[item.prefab] ~= nil or IsBehind(sailor, item) and CanTrawlItem(item) end, nil, TRAWL_CANT_TAGS)
    end

    if pickup and SPECIAL_CASE_PREFABS[pickup.prefab] then
        pickup = SPECIAL_CASE_PREFABS[pickup.prefab](pickup,inst)
    end

    if pickup then
        pickupitem(inst,pickup)
    end

end

local function starttrawling(inst)
    inst.trawling = true
    inst.lastPos = inst:GetPosition()
    inst.trawltask = inst:DoPeriodicTask(FRAMES * 5, updateTrawling)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/attach")
end

local function embarked(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
    starttrawling(item)
    updatespeedmult(item)
end

local function disembarked(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
    stoptrawling(item)

    if data.sailor.components.locomotor then
        data.sailor.components.locomotor:RemoveExternalSpeedMultiplier(item, "TRAWL")
    end
end

local function onequip(inst, owner)
    if owner.components.boatvisualmanager then
        owner.components.boatvisualmanager:SpawnBoatEquipVisuals(inst, "trawlnet")
    end
    inst.components.inventoryitem.cangoincontainer = false
    inst:ListenForEvent("embarked", embarked, owner)
    inst:ListenForEvent("disembarked", disembarked, owner)
    updatespeedmult(inst)
    starttrawling(inst)
end

local function onunequip(inst, owner)
    if owner.components.boatvisualmanager then
        owner.components.boatvisualmanager:RemoveBoatEquipVisuals(inst)
    end
    if owner.components.sailable and owner.components.sailable.sailor then
        if owner.components.sailable.sailor.components.locomotor then
            owner.components.sailable.sailor.components.locomotor:RemoveExternalSpeedMultiplier(inst, "TRAWL")
        end
    end

    inst:RemoveEventCallback("embarked", embarked, owner)
    inst:RemoveEventCallback("disembarked", disembarked, owner)
    stoptrawling(inst)
    --Only do the following if this entity is not in the process of getting removed already (fixes issue #246 - Duplication Bug)
    if Ents[inst.GUID] then
        droploot(inst, owner)
        inst:DoTaskInTime(2*FRAMES, inst.Remove)
    end
end

local function net(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("trawlnet")
    inst.AnimState:SetBuild("swap_trawlnet")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    inst:AddTag("trawlnet")
    inst:AddTag("show_invspace")
    inst:AddTag("boat_equip_sail")

    inst.trawlitem = net_bool(inst.GUID, "trawlitem", not TheWorld.ismastersim and "trawlitem" or nil)

    if not TheWorld.ismastersim then
        inst:ListenForEvent("trawlitem", function(inst)
            ThePlayer:PushEvent("trawlitem")
        end)
    end

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    inst:AddComponent("inventoryitem")

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = TUNING.TRAWLNET_MAX_ITEMS

    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_SAIL
    inst.components.equippable.equipslot = nil
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst.currentLoot = {}
    inst.uniqueItemsFound = {}
    inst.distanceCounter = 0
    inst.trawltask = nil
    inst.rowsound = "ia/common/trawl_net/move_LP"

    -- Used in trawlnet_loot_defs.lua
    inst.pickupitem = pickupitem

    updatespeedmult(inst)

    return inst
end


local function sink(inst, instant)
    if not instant then
        inst.AnimState:PlayAnimation("sink_pst")
        inst:ListenForEvent("animover", function()
            inst.components.container:DropEverything()
            inst:Remove()
        end)
    else
        -- this is to catch the nets that for some reason dont have the right timer save data.
        inst.components.container:DropEverything()
        inst:Remove()
    end
end

local function getsinkstate(inst)
    if inst.components.timer:TimerExists("sink") then
        return "sink"
    elseif inst.components.timer:TimerExists("startsink") then
        return "full"
    end
    return "sink"
end

local function startsink(inst)
    inst.AnimState:PlayAnimation("full_to_sink")
    inst.components.timer:StartTimer("sink", TUNING.TRAWL_SINK_TIME * 1/3)
    inst.AnimState:PushAnimation("idle_"..getsinkstate(inst), true)
end


local function dodetach(inst)
    inst.components.timer:StartTimer("startsink", TUNING.TRAWL_SINK_TIME * 2/3)
    inst.AnimState:PlayAnimation("detach")
    inst.AnimState:PushAnimation("idle_"..getsinkstate(inst), true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/detach")
end

local function onopen(inst)
    inst.AnimState:PlayAnimation("interact_"..getsinkstate(inst))
    inst.AnimState:PushAnimation("idle_"..getsinkstate(inst), true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/open")
end

local function onclose(inst)
    inst.AnimState:PlayAnimation("interact_"..getsinkstate(inst))
    inst.AnimState:PushAnimation("idle_"..getsinkstate(inst), true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/trawl_net/close")
end

local function ontimerdone(inst, data)
    if data.name == "startsink" then
        startsink(inst)
    end

    if data.name == "sink" then
        sink(inst)
    end
    --These are sticking around some times.. maybe the timer name is being lost somehow? This will catch that?
    if data.name ~= "sink" and data.name ~= "startsink" then
        sink(inst)
    end
end


local function getstatusfn(inst, viewer)
    local sinkstate = getsinkstate(inst)
    local timeleft = (inst.components.timer and inst.components.timer:GetTimeLeft("startsink")) or TUNING.TRAWL_SINK_TIME
    if sinkstate == "sink" then
        return "SOON"
    elseif sinkstate == "full" and timeleft <= (TUNING.TRAWL_SINK_TIME * 0.66) * 0.5 then
        return "SOONISH"
    else
        return "GENERIC"
    end
end

local function onloadtimer(inst)
    if not inst.components.timer:TimerExists("sink") and not inst.components.timer:TimerExists("startsink") then
        print("TRAWL NET HAD NO TIMERS AND WAS FORCE SUNK")
        sink(inst, true)
    end
end

local function onload(inst, data)
    inst.AnimState:PlayAnimation("idle_"..getsinkstate(inst), true)
end

local function dropped_net()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetTwoFaced()

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.AnimState:SetBank("trawlnet")
    inst.AnimState:SetBuild("swap_trawlnet")
    inst.AnimState:PlayAnimation("idle_full", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    MakeInventoryPhysics(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatusfn

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("trawlnetdropped")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst.onloadtimer = onloadtimer

    inst.DoDetach = dodetach

    -- this task is here because sometimes the savedata on the timer is empty.. so no timers are reloaded.
    -- when that happens, the nets sit around forever.
    inst:DoTaskInTime(0,function() onloadtimer(inst) end)

    inst.OnLoad = onload

    return inst
end

local function trawlnet_visual_common(inst)
    inst.visualchild.AnimState:SetBank("sail_visual")
    inst.visualchild.AnimState:SetBuild("swap_trawlnet")
    inst.visualchild.AnimState:PlayAnimation("idle_loop", true)
    inst.visualchild.AnimState:SetFinalOffset(FINALOFFSET_MIN)  -- below the player
end

return Prefab("trawlnet", net, net_assets),
    visualboatequip.MakeVisualBoatEquip("trawlnet", net_assets, nil, trawlnet_visual_common),
    visualboatequip.MakeVisualBoatEquipChild("trawlnet", net_assets, nil, trawlnet_visual_common),
    Prefab("trawlnetdropped", dropped_net, dropped_assets)

