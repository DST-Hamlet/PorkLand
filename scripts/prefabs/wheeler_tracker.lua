local assets=
{
    Asset("ANIM", "anim/tracker.zip"),
    Asset("INV_IMAGE", "tracker"),
    Asset("INV_IMAGE", "tracker_open"),
    Asset("ANIM", "anim/tracker_pointer.zip"),
    Asset("MINIMAP_IMAGE", "tracker"),
}

local function CanGiveLoot(inst, goal_inst)
    local prefab = goal_inst.prefab
    if not (inst.components.inventoryitem and (inst.components.inventoryitem.owner ~= nil)) and not inst:IsInLimbo() then
        if inst.prefab == prefab then
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

        elseif inst.components.cookable and inst.components.cookable.product == prefab then
            return true

        elseif goal_inst.components.deployable and goal_inst.components.deployable.product == inst.prefab then
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

local function TrackNext(inst, goal_inst)
    -- local prefab = goal_inst.prefab
    -- print("TRACKING A", prefab)

    -- TODO: Optimize this
    if inst:GetIsInInterior() then
        return FindEntity(inst, 60, function(entity)
            return CanGiveLoot(entity, goal_inst)
        end) 
    end

    return FindEntity(inst, 200, function(entity)
        return CanGiveLoot(entity, goal_inst)
    end)
end

local function DeactivateTracking(inst)
    if inst.arrow_rotation_update then
        inst.arrow_rotation_update:Cancel()
        inst.arrow_rotation_update = nil
    end

    inst._istracking:set(false)
end

local function ServerUpdateTragetPos(inst, x, y, z)
    inst._targetpos.x:set(x)
    inst._targetpos.z:set(z)
end

local function ActivateTracking(inst)
    local owner = inst.components.inventoryitem.owner
    if not (owner and owner:HasTag("tracker_user")) then
        return
    end

    if inst.tracked_item then
        if inst.arrow_rotation_update == nil then
            inst.arrow_rotation_update = inst:DoPeriodicTask(FRAMES, function()
                if not inst.tracked_item
                    or not inst.tracked_item:IsValid()
                    or inst.tracked_item:IsInLimbo()
                    or not CanGiveLoot(inst.tracked_item, inst.components.container:GetItemInSlot(1)) then

                    inst.tracked_item = nil
                    DeactivateTracking(inst)
                    inst.tracked_item = TrackNext(inst, inst.components.container:GetItemInSlot(1))
                    ActivateTracking(inst)
                else
                    inst:ServerUpdateTragetPos(inst.tracked_item.Transform:GetWorldPosition())
                    inst._istracking:set(true)
                end
            end)
        end
    else
        owner.components.talker:Say(GetString(owner.prefab, "ANNOUNCE_NOTHING_FOUND"))
    end
end

local function RefreshTracking(inst)
    DeactivateTracking(inst)

    local item = inst.components.container:GetItemInSlot(1)
    if item then
        inst.tracked_item = TrackNext(inst, item)
        ActivateTracking(inst)
    end
end

local function OnEquip(inst, owner, force)
    owner.AnimState:ClearOverrideSymbol("swap_object")

    RefreshTracking(inst)
    inst.refresh_tracking_owner_listener = function() RefreshTracking(inst) end
    inst:ListenForEvent("leaveinterior", inst.refresh_tracking_owner_listener, owner)
    inst:ListenForEvent("enterinterior", inst.refresh_tracking_owner_listener, owner)

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
    DeactivateTracking(inst)
    if inst.refresh_tracking_owner_listener then
        inst:ListenForEvent("leaveinterior", inst.refresh_tracking_owner_listener, owner)
        inst:ListenForEvent("enterinterior", inst.refresh_tracking_owner_listener, owner)
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
    DeactivateTracking(inst)

    inst.components.inventoryitem:ChangeImageName("wheeler_tracker_open")
end

local function OnItemGet(inst, data)
    inst.components.inventoryitem:ChangeImageName("wheeler_tracker")

    if inst.components.equippable:IsEquipped() then
        RefreshTracking(inst)
    end
end

local function OnItemGetClient(inst, data)
    local item = data and data.item
    if item and inst.replica.inventoryitem:IsHeldBy(ThePlayer) then
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
    if  inst.replica.inventoryitem:IsHeldBy(ThePlayer) then
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
    inst.components.container.canbeopened = false
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:InitializeFuelLevel(TUNING.WHEELER_TRACKER_FUEL)
    inst.components.fueled:SetDepletedFn(ondepleted)

    inst.ServerUpdateTragetPos = ServerUpdateTragetPos
    return inst
end

return Prefab("wheeler_tracker", fn, assets)
