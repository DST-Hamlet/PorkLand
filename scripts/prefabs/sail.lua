local MakeVisualBoatEquip = require("prefabs/visualboatequip")

local snakeskinsail_assets = {
    Asset("ANIM", "anim/swap_sail_snakeskin_scaly.zip"),
}

local function StartConsuming(inst)
    if inst.components.fueled and not inst.components.fueled.consuming then
        inst.components.fueled:StartConsuming()
    end
end

local function StopConsuming(inst)
    if inst.components.fueled and inst.components.fueled.consuming then
        inst.components.fueled:StopConsuming()
    end
end

local function OnEmbarked(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)

    -- if data.sailor.components.locomotor then
    --     data.sailor.components.locomotor:SetExternalSpeedMultiplier(item, "SAIL", item.sail_speed_mult)
    --     data.sailor.components.locomotor:SetExternalAccelerationMultiplier(item, "SAIL", item.sail_accel_mult)
    --     data.sailor.components.locomotor:SetExternalDecelerationMultiplier(item, "SAIL", item.sail_accel_mult)
    -- end
end

local function OnDisembarked(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
    StopConsuming(item)

    -- if data.sailor.components.locomotor then
    --     data.sailor.components.locomotor:RemoveExternalSpeedMultiplier(item, "SAIL")
    --     data.sailor.components.locomotor:RemoveExternalAccelerationMultiplier(item, "SAIL")
    --     data.sailor.components.locomotor:RemoveExternalDecelerationMultiplier(item, "SAIL")
    -- end
end

local function OnStartMoving(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
    StartConsuming(item)
end

local function OnStopMoving(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
    StopConsuming(item)
end

local function OnEquip(inst, owner)
    if not owner or not owner.components.sailable then
		print("WARNING: Equipped sail (",inst,") without valid boat: ", owner)
		return false
	end

    if owner.components.boatvisualmanager then
        owner.components.boatvisualmanager:SpawnBoatEquipVisuals(inst, inst.visualprefab)
    end

	if owner.components.sailable.sailor then
        local sailor = owner.components.sailable.sailor
        sailor:PushEvent("sailequipped")
        inst.sailquipped:set_local(true)
        inst.sailquipped:set(true)
        if inst.flapsound then
            sailor.SoundEmitter:PlaySound(inst.flapsound)
        end
<<<<<<< Updated upstream
        -- if sailor.components.locomotor then
        --     sailor.components.locomotor:SetExternalSpeedMultiplier(inst, "SAIL", inst.sail_speed_mult)
        --     sailor.components.locomotor:SetExternalAccelerationMultiplier(inst, "SAIL", inst.sail_accel_mult)
        --     sailor.components.locomotor:SetExternalDecelerationMultiplier(inst, "SAIL", inst.sail_accel_mult)
        -- end
=======
        if owner.components.sailable then
            owner.components.sailable:SetExternalSpeedMultiplier(inst, "SAIL", inst.sail_speed_mult)
            owner.components.sailable:SetExternalAccelerationMultiplier(inst, "SAIL", inst.sail_accel_mult)
            --owner.components.sailable:SetExternalDecelerationMultiplier(inst, "SAIL", inst.sail_accel_mult)
        end
>>>>>>> Stashed changes
    end

    inst:ListenForEvent("embarked", OnEmbarked, owner)
    inst:ListenForEvent("disembarked", OnDisembarked, owner)
    inst:ListenForEvent("boatstartmoving", OnStartMoving, owner)
    inst:ListenForEvent("boatstopmoving", OnStopMoving, owner)
end

local function OnUnequip(inst, owner)
    if owner then
        if owner.components.boatvisualmanager then
            owner.components.boatvisualmanager:RemoveBoatEquipVisuals(inst)
        end
		if owner.components.sailable and owner.components.sailable.sailor then
			local sailor = owner.components.sailable.sailor
			sailor:PushEvent("sailunequipped")
			inst.sailquipped:set_local(false)
			inst.sailquipped:set(false)
			if inst.flapsound then
				sailor.SoundEmitter:PlaySound(inst.flapsound)
			end

<<<<<<< Updated upstream
			-- if sailor.components.locomotor then
			-- 	sailor.components.locomotor:RemoveExternalSpeedMultiplier(inst, "SAIL")
			-- 	sailor.components.locomotor:RemoveExternalAccelerationMultiplier(inst, "SAIL")
			-- 	sailor.components.locomotor:RemoveExternalDecelerationMultiplier(inst, "SAIL")
			-- end
=======
			if owner.components.sailable then
			    owner.components.sailable:RemoveExternalSpeedMultiplier(inst, "SAIL")
			 	owner.components.sailable:RemoveExternalAccelerationMultiplier(inst, "SAIL")
			 	--owner.components.sailable:RemoveExternalDecelerationMultiplier(inst, "SAIL")
			end
>>>>>>> Stashed changes
		end

		inst:RemoveEventCallback("embarked", OnEmbarked, owner)
		inst:RemoveEventCallback("disembarked", OnDisembarked, owner)
		inst:RemoveEventCallback("boatstartmoving", OnStartMoving, owner)
		inst:RemoveEventCallback("boatstopmoving", OnStopMoving, owner)
	end

    StopConsuming(inst)

    if inst.RemoveOnUnequip then
        inst:DoTaskInTime(2 * FRAMES, inst.Remove)
    end
end

local function SailPerish(inst)
    OnUnequip(inst, inst.components.inventoryitem.owner)
    inst:Remove()
end

local function common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst:AddTag("sail")

    -- networking the equip/unequip event
    inst.sailquipped = net_bool(inst.GUID, "sailquipped", not TheWorld.ismastersim and "sailquipped" or nil)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("sailquipped", function(inst)
            if inst.sailquipped:value() then
                ThePlayer:PushEvent("sailequipped")
            else
                ThePlayer:PushEvent("sailunequipped")
            end
        end)

        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = "USAGE"
    inst.components.fueled:SetDepletedFn(SailPerish)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_SAIL
    inst.components.equippable.equipslot = nil
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    MakeHauntableLaunch(inst)
    MakeSmallPropagator(inst)
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)

    return inst
end

local function snakeskinsail_fn()
    local inst = common()

    inst.AnimState:SetBank("sail")
    inst.AnimState:SetBuild("swap_sail_snakeskin_scaly")
    inst.AnimState:PlayAnimation("idle")

    inst.loopsound = "dontstarve_DLC002/common/sail_LP/snakeskin"
    inst.flapsound = "dontstarve_DLC002/common/sail_flap/snakeskin"

    if not TheWorld.ismastersim then
        return inst
    end

    inst.visualprefab = "sail_snakeskin_scaly"

    inst.components.fueled:InitializeFuelLevel(TUNING.SAIL_SNAKESKIN_PERISH_TIME)
    inst.sail_speed_mult = TUNING.SAIL_SNAKESKIN_SPEED_MULT
    inst.sail_accel_mult = TUNING.SAIL_SNAKESKIN_ACCEL_MULT

    return inst
end

local function snakeskinsail_visual_common(inst)
    inst.AnimState:SetBank("sail_visual")
    inst.AnimState:SetBuild("swap_sail_snakeskin_scaly")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetSortWorldOffset(0, 0.05, 0)  -- below the player

    function inst.components.boatvisualanims.update(inst, dt)
        if inst.AnimState:GetCurrentFacing() == FACING_UP then
            inst.AnimState:SetSortWorldOffset(0, 0.15, 0)  -- above the player
        else
            inst.AnimState:SetSortWorldOffset(0, 0.05, 0)  -- below the player
        end
    end
end

return Prefab("sail_snakeskin_scaly", snakeskinsail_fn, snakeskinsail_assets),
    MakeVisualBoatEquip("sail_snakeskin_scaly", snakeskinsail_assets, nil, snakeskinsail_visual_common)
