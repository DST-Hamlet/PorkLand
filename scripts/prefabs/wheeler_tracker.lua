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
    return FindEntity(inst, 1000, function(entity)
        return CanGiveLoot(entity, goal_inst)
    end)
end

local function DeactivateTracking(inst)
    if inst.arrow_rotation_update then
        inst.arrow_rotation_update:Cancel()
        inst.arrow_rotation_update = nil
    end

    if inst.distance_update then
        inst.distance_update:Cancel()
        inst.distance_update = nil
    end

    if inst.arrow then
        inst.arrow:Remove()
        inst.arrow = nil
    end
end

local function ActivateTracking(inst)
    local owner = inst.components.inventoryitem.owner
    if not owner then
        return
    end

    if inst.tracked_item then
        if not inst.arrow then
            inst.arrow = SpawnPrefab("wheeler_tracker_arrow")
            owner:AddChild(inst.arrow)
            inst.arrow.Network:SetClassifiedTarget(owner)
        end

        if inst.arrow_rotation_update == nil then
            inst.arrow_rotation_update = inst:DoPeriodicTask(0, function()
                if not inst.tracked_item
                    or not inst.tracked_item:IsValid()
                    or inst.tracked_item:IsInLimbo()
                    or not CanGiveLoot(inst.tracked_item, inst.components.container:GetItemInSlot(1)) then

                    inst.tracked_item = nil
                    DeactivateTracking(inst)
                    inst.tracked_item = TrackNext(inst, inst.components.container:GetItemInSlot(1))
                    ActivateTracking(inst)
                else
                    inst.arrow:UpdateRotation(inst.tracked_item.Transform:GetWorldPosition())
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
end

local function OnEquipToModel(inst, owner, from_ground)
    if inst.components.container then
        inst.components.container:Close()
    end
end

local  function OnItemLose(inst, data)
    DeactivateTracking(inst)

    inst.components.inventoryitem:ChangeImageName("tracker_open")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/tracker/open")
end

local function OnItemGet(inst, data)
    inst.components.inventoryitem:ChangeImageName("tracker")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/tracker/close")

    if inst.components.equippable:IsEquipped() then
        DeactivateTracking(inst)
        inst.tracked_item = TrackNext(inst, data.item)
        ActivateTracking(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("tracker.tex")

    inst.AnimState:SetBank("tracker")
    inst.AnimState:SetBuild("tracker")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst:AddTag("irreplaceable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("tracker_open")

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.restrictedtag = "tracker_user"
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("wheeler_tracker")
    inst.components.container.canbeopened = false
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    -- inst:AddComponent("characterspecific")
    -- inst.components.characterspecific:SetOwner("wheeler")

    return inst
end

local function arrowfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("tracker_pointer")
    inst.AnimState:SetBuild("tracker_pointer")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(4)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.UpdateRotation = function(inst, x, y, z)
        inst:FacePoint(x, y, z)
        inst.Transform:SetRotation(inst.Transform:GetRotation() + 90 - inst.parent.Transform:GetRotation())
    end

    return inst
end

return Prefab("wheeler_tracker", fn, assets),
       Prefab("wheeler_tracker_arrow", arrowfn, assets)
