local assets =
{
    Asset("ANIM", "anim/tracker.zip"),
    Asset("ANIM", "anim/swap_tracker.zip"),
    Asset("INV_IMAGE", "tracker"),
    Asset("INV_IMAGE", "tracker_open"),
    Asset("ANIM", "anim/tracker_pointer.zip"),
    Asset("MINIMAP_IMAGE", "tracker"),
}

local SPECIAL_LOOT_TABLE =
{
    ["dug_grass"] =
    {
        grass = true,
        grass_tall = true,
    },
    ["dug_saping"] =
    {
        saping = true,
    },
    ["dug_nettle"] =
    {
        nettle = true,
    },
    ["iron"] =
    {
        ancient_robot_ribs = true,
        ancient_robot_claw = true,
        ancient_robot_leg = true,
        ancient_robot_head = true,
        ancient_robots_assembly = true,
    },
    ["waterdrop"] =
    {
        lifeplant = true,
    },
    ["boat_cork_item"] =
    {
        boat_cork = true,
    }
}

local function CanGiveLoot(inst, goal_inst)
    local prefab = goal_inst.prefab
    if not (inst.components.inventoryitem and (inst.components.inventoryitem.owner ~= nil)) and (inst:HasTag("track_ignore_limbo") or not inst:IsInLimbo()) then
        if inst.prefab == prefab then
            return true

        elseif SPECIAL_LOOT_TABLE[prefab] and SPECIAL_LOOT_TABLE[prefab][inst.prefab] then
            return true

        elseif inst.components.pickable and inst.components.pickable:CanBePicked() and inst.components.pickable.product == prefab then
            return true

        elseif inst.components.harvestable and inst.components.harvestable:CanBeHarvested() and inst.components.harvestable.product == prefab then
            return true

        elseif inst.components.dryable and inst.components.dryable.product == prefab then
            return true

        elseif inst.components.shearable and inst.components.shearable:CanShear() and inst.components.shearable.product == prefab then
            return true

        elseif inst.components.dislodgeable and inst.components.dislodgeable:CanBeDislodged() and inst.components.dislodgeable.product == prefab then
            return true

        elseif inst.components.mystery and inst.components.mystery.reward == prefab then
            return true

        elseif inst.components.cookable and inst.components.cookable.product == prefab then
            return true

        elseif inst.components.storageloot and inst.components.storageloot:HasLoot(prefab) then
            return true

        elseif inst.components.lootdropper then
            local possible_loots = inst.components.lootdropper:GetAllPossibleLoot()
            if possible_loots[prefab] then
                return true
            end
        end
    end
    return false
end

local SEARCH_RADIUS = 150
local MAX_TRACK_RADIUS = SEARCH_RADIUS * 5
local pos_table =
{
    {0, 0},
    {1, 0},
    {1, 60}, -- 半径，角度
    {1, 120},
    {1, 180},
    {1, 240},
    {1, 300},
    {2, 0},
    {1.7320508, 30},
    {2, 60},
    {1.7320508, 90},
    {2, 120},
    {1.7320508, 150},
    {2, 180},
    {1.7320508, 210},
    {2, 240},
    {1.7320508, 270},
    {2, 300},
    {1.7320508, 330},
}

local function TrackNext(x, y, z, inst, goal_inst)
    if not goal_inst then
        return
    end

    local ents = TheSim:FindEntities(x, y, z, SEARCH_RADIUS, nil, {"INLIMBO"}) -- or we could include a flag to the search?
    for i, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() and CanGiveLoot(v, goal_inst) and inst:IsInSameIsland(v) then
            return v
        end
    end
end

local function TrackNext_Interior(x, y, z, inst, goal_inst)
    if not goal_inst then
        return
    end

    local ents = TheSim:FindEntities(x, y, z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"}) -- or we could include a flag to the search?
    for i, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() and CanGiveLoot(v, goal_inst) and inst:IsInSameRoomGroup(v) then
            return v
        end
    end
end

local function ReSetTrackingData(inst)
    if inst.target_item_update then
        inst.target_item_update:Cancel()
        inst.target_item_update = nil
    end

    inst.track_data = {}
    inst.track_data.index = 1
    inst.track_data.baserandom = math.random() * 360
    inst.track_data.start_pos = inst:GetPosition()
    inst.tracked_item = nil
    local center = inst:GetCurrentInteriorCenter()
    if center then
        inst.track_data.roomgroup = TheWorld.components.interiorspawner:GetSortedRoomsInGroup(center)
        table.insert(inst.track_data.roomgroup, center)
        local current_x, current_y = center:GetCoordinates()
        table.sort(inst.track_data.roomgroup, function(a, b)
            local a_x, a_y = a:GetCoordinates()
            local b_x, b_y = b:GetCoordinates()
            return distsq(current_x, current_y, a_x, a_y) < distsq(current_x, current_y, b_x, b_y)
        end)
    end

    inst._hastarget:set(false)
    inst._istracking:set(false)
end

local function ServerUpdateTargetPos(inst, x, y, z)
    inst._targetpos.x:set(x)
    inst._targetpos.z:set(z)
end

local function StartTracking(inst)
    ReSetTrackingData(inst)

    inst._istracking:set(true)

    if not inst:GetIsInInterior() then
        inst:TryTracking()
    else
        inst:TryTracking_Interior()
    end
end

local function TryTracking(inst)
    inst.target_item_update = nil
    local update_time = FRAMES
    local owner = inst.components.inventoryitem.owner
    if not (owner and owner:HasTag("tracker_user")) then
        ReSetTrackingData(inst)
        inst._istracking:set(true)
        inst.target_item_update = inst:DoTaskInTime(update_time, inst.TryTracking)
        return
    end

    if inst.tracked_item then
        if not inst.tracked_item:IsValid()
            or (inst.tracked_item:IsInLimbo() and not inst.tracked_item:HasTag("track_ignore_limbo"))
            or not CanGiveLoot(inst.tracked_item, inst.components.container:GetItemInSlot(1))
            or not inst:IsInSameIsland(inst.tracked_item)
            or not (inst:GetDistanceSqToInst(inst.tracked_item) <= MAX_TRACK_RADIUS * MAX_TRACK_RADIUS) then

            ReSetTrackingData(inst)
            inst._istracking:set(true)
        else
            inst:ServerUpdateTargetPos(inst.tracked_item.Transform:GetWorldPosition())
            inst._hastarget:set(true)
        end
    end
    if not inst.tracked_item then
        local x, _, z = inst.track_data.start_pos:Get()
        local index = inst.track_data.index
        local item = inst.components.container:GetItemInSlot(1)

        if index > #pos_table then
            ReSetTrackingData(inst)
            inst._istracking:set(true)
            inst.track_data.failed = true
        else
            local radius = pos_table[index][1] * SEARCH_RADIUS * 2 * 0.866025
            local angle = (pos_table[index][2] + inst.track_data.baserandom) * DEGREES -- 二分之根号3
            local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))
            x = x + offset.x
            z = z + offset.z
            local target_item = TrackNext(x, 0, z, inst, item)
            inst.track_data.index = index + 1
            if target_item then
                inst.tracked_item = target_item
                if (inst.track_data.index - 1) > 7 then
                    owner:PushEvent("trackitem_far")
                else
                    owner:PushEvent("trackitem_close")
                end

                inst:ServerUpdateTargetPos(inst.tracked_item.Transform:GetWorldPosition())
                inst._hastarget:set(true)

                inst.track_data.index = 1
                inst.track_data.baserandom = math.random() * 360
                inst.track_data.start_pos = inst:GetPosition()
            else
                update_time = 8 * FRAMES
                if inst.track_data.failed then
                    owner:PushEvent("canttrackitem")
                    inst.track_data.failed = nil
                end
            end
        end
    end

    inst.target_item_update = inst:DoTaskInTime(update_time, inst.TryTracking)
end


local function TryTracking_Interior(inst)
    inst.target_item_update = nil
    local update_time = FRAMES
    local owner = inst.components.inventoryitem.owner
    if not (owner and owner:HasTag("tracker_user")) then
        ReSetTrackingData(inst)
        inst._istracking:set(true)
        inst.target_item_update = inst:DoTaskInTime(update_time, inst.TryTracking_Interior)
        return
    end

    if inst.tracked_item then
        if not inst.tracked_item:IsValid()
            or (inst.tracked_item:IsInLimbo() and not inst.tracked_item:HasTag("track_ignore_limbo"))
            or not CanGiveLoot(inst.tracked_item, inst.components.container:GetItemInSlot(1))
            or not inst:IsInSameRoomGroup(inst.tracked_item) then

            ReSetTrackingData(inst)
            inst._istracking:set(true)
        else
            local offset = inst:GetRelativePositionInRoom(inst.tracked_item)
            inst:ServerUpdateTargetPos((inst:GetPosition() + offset):Get())
            inst._hastarget:set(true)
        end
    end
    if inst.track_data.roomgroup == nil then
        ReSetTrackingData(inst)
        inst._istracking:set(true)
        inst.target_item_update = inst:DoTaskInTime(update_time, inst.TryTracking_Interior)
        return
    end
    if not inst.tracked_item then
        local x, _, z = inst.track_data.start_pos:Get()
        local index = inst.track_data.index
        local item = inst.components.container:GetItemInSlot(1)

        if index > #inst.track_data.roomgroup then
            ReSetTrackingData(inst)
            inst._istracking:set(true)
            inst.track_data.failed = true
        else
            x, _, z = inst.track_data.roomgroup[index].Transform:GetWorldPosition()
            local target_item = TrackNext_Interior(x, 0, z, inst, item)
            inst.track_data.index = index + 1
            if target_item then
                inst.tracked_item = target_item
                owner:PushEvent("trackitem_close")

                local offset = inst:GetRelativePositionInRoom(inst.tracked_item)
                inst:ServerUpdateTargetPos((inst:GetPosition() + offset):Get())
                inst._hastarget:set(true)

                inst.track_data.index = 1
                inst.track_data.baserandom = math.random() * 360
                inst.track_data.start_pos = inst:GetPosition()
            else
                update_time = 4 * FRAMES
                if inst.track_data.failed then
                    owner:PushEvent("canttrackitem")
                    inst.track_data.failed = nil
                end
            end
        end
    end

    inst.target_item_update = inst:DoTaskInTime(update_time, inst.TryTracking_Interior)
end

local function OnEquip(inst, owner, force)
    owner.AnimState:OverrideSymbol("swap_object", "swap_tracker", "swap_tracker")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container:GetItemInSlot(1) then
        StartTracking(inst)
    end

    inst:ListenForEvent("roomgroupchange", inst.refresh_tracking_owner_listener, owner)

    if inst.components.container then
        inst.components.container:Open(owner)
    end

    inst.components.fueled:StartConsuming()

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:AddRevealSource(inst, "compassbearer")
    end
    owner:AddTag("compassbearer")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner.AnimState:ClearOverrideSymbol("swap_object")

    ReSetTrackingData(inst)
    if inst.refresh_tracking_owner_listener then
        inst:RemoveEventCallback("roomgroupchange", inst.refresh_tracking_owner_listener, owner)
    end

    if inst.components.container then
        inst.components.container:Close()
    end

    inst.components.fueled:StopConsuming()

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:RemoveRevealSource(inst)
    end
    owner:RemoveTag("compassbearer")
end

local function OnEquipToModel(inst, owner, from_ground)
    if inst.components.container then
        inst.components.container:Close()
    end

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:RemoveRevealSource(inst)
    end
    owner:RemoveTag("compassbearer")
end

local function OnItemLose(inst, data)
    ReSetTrackingData(inst)

    inst.components.inventoryitem:ChangeImageName("wheeler_tracker_open")
end

local function OnItemGet(inst, data)
    inst.components.inventoryitem:ChangeImageName("wheeler_tracker")

    if inst.components.equippable:IsEquipped() then
        StartTracking(inst)
    end
end

local function OnItemGetClient(inst, data)
    local item = data and data.item
    if item and ThePlayer and ThePlayer:HasTag("tracker_user") and inst.replica.inventoryitem:IsHeldBy(ThePlayer) then
        local container_classified = inst.replica.container and inst.replica.container.classified
        if not (container_classified
            and container_classified._itemspreview
            and container_classified._itemspreview[data.slot]
            and container_classified._itemspreview[data.slot].prefab == item.prefab
        ) then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/tracker/close")
        end
    end
end

local function OnItemLoseClient(inst, data)
    if ThePlayer and ThePlayer:HasTag("tracker_user") and inst.replica.inventoryitem:IsHeldBy(ThePlayer) then
        local container_classified = inst.replica.container and inst.replica.container.classified
        if not (container_classified
            and container_classified._itemspreview
            and container_classified._itemspreview[data.slot] == nil
        ) then
            TheFocalPoint.SoundEmitter:PlaySound("porkland_soundpackage/characters/wheeler/tracker/open")
        end
    end
end

local function ondepleted(inst)
    if inst.components.inventoryitem ~= nil
        and inst.components.inventoryitem.owner ~= nil then
        local data = {
            prefab = inst.prefab,
            equipslot = inst.components.equippable.equipslot,
            announce = "ANNOUNCE_COMPASS_OUT",
        }
        inst.components.inventoryitem.owner:PushEvent("itemranout", data)
    end
    inst.components.container:DropEverything(inst:GetPosition())
    inst:Remove()
end

local function onattack(inst, attacker, target)
    if inst.components.fueled ~= nil then
        inst.components.fueled:DoDelta(inst.components.fueled.maxfuel * TUNING.WHEELER_TRACKER_ATTACK_DECAY_PERCENT)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("tracker.tex")

    inst.AnimState:SetBank("tracker")
    inst.AnimState:SetBuild("tracker")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst:AddTag("tracker_compass")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("itemget", OnItemGetClient)
        inst:ListenForEvent("itemlose", OnItemLoseClient)
    end

    inst._istracking = net_bool(inst.GUID, "_istracking")
    inst._hastarget = net_bool(inst.GUID, "_hastarget")

    inst._targetpos = {
        x = net_float(inst.GUID, "_targetpos.x"),
        z = net_float(inst.GUID, "_targetpos.z"),
    }

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("wheeler_tracker_open")

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("wheeler_tracker")
    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:InitializeFuelLevel(TUNING.WHEELER_TRACKER_FUEL)
    inst.components.fueled:SetDepletedFn(ondepleted)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)

    inst.track_data = {}

    inst:DoTaskInTime(0, function() -- 游戏载入时，会在错误的坐标进行搜寻，因此需要重新开始
        if inst.target_item_update then
            if inst.components.container:GetItemInSlot(1) and inst.components.equippable:IsEquipped() then
                StartTracking(inst)
            end
        end
    end)

    inst.refresh_tracking_owner_listener = function(owner)
        if inst.components.container:GetItemInSlot(1) and inst.components.equippable:IsEquipped() then
            StartTracking(inst)
        end
    end
    inst.ServerUpdateTargetPos = ServerUpdateTargetPos
    inst.TryTracking = TryTracking
    inst.TryTracking_Interior = TryTracking_Interior
    return inst
end

return Prefab("wheeler_tracker", fn, assets)
