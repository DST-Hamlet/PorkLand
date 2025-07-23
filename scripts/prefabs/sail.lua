local visualboatequip = require("prefabs/visualboatequip")

local snakeskinsail_assets = {
    Asset("ANIM", "anim/swap_sail_snakeskin.zip"),
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
    -- local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
end

local function OnDisembarked(boat, data)
    local item = boat.components.container:GetItemInBoatSlot(BOATEQUIPSLOTS.BOAT_SAIL)
    StopConsuming(item)
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
        if owner.components.sailable then
            owner.components.sailable:SetExternalSpeedMultiplier(inst, "SAIL", inst.sail_speed_mult)
            owner.components.sailable:SetExternalAccelerationMultiplier(inst, "SAIL", inst.sail_accel_mult)
            --owner.components.sailable:SetExternalDecelerationMultiplier(inst, "SAIL", inst.sail_accel_mult)
        end
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

            if owner.components.sailable then
                owner.components.sailable:RemoveExternalSpeedMultiplier(inst, "SAIL")
                owner.components.sailable:RemoveExternalAccelerationMultiplier(inst, "SAIL")
            end
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

    PorkLandMakeInventoryFloatable(inst)

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
    inst.components.fueled.fueltype = FUELTYPE.USAGE
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
    inst.AnimState:SetBuild("swap_sail_snakeskin")
    inst.AnimState:PlayAnimation("idle")

    inst.loopsound = "dontstarve_DLC002/common/sail_LP_snakeskin"
    inst.flapsound = "dontstarve_DLC002/common/sail_flap_snakeskin"

    if not TheWorld.ismastersim then
        return inst
    end

    inst.visualprefab = "sail_snakeskin"

    inst:AddComponent("visualvariant")
    inst.components.visualvariant:SetVariantData("sail_snakeskin")

    inst.components.fueled:InitializeFuelLevel(TUNING.SAIL_SNAKESKIN_PERISH_TIME)
    inst.sail_speed_mult = TUNING.SAIL_SNAKESKIN_SPEED_MULT
    inst.sail_accel_mult = TUNING.SAIL_SNAKESKIN_ACCEL_MULT

    return inst
end

local function make_sail_snakeskin_visual_setup(build)
    return function (inst)
        inst.visualchild.AnimState:SetBank("sail_visual")
        inst.visualchild.AnimState:SetBuild(build)
        inst.visualchild.AnimState:PlayAnimation("idle_loop", true)
        inst.visualchild.AnimState:SetFinalOffset(FINALOFFSET_MIN + 2)  -- below the player

        function inst.components.boatvisualanims.update(inst, dt)
            if inst.visualchild.AnimState:GetCurrentFacing() == FACING_UP then
                inst.visualchild.AnimState:SetFinalOffset(FINALOFFSET_MAX - 2)  -- above the player
            else
                inst.visualchild.AnimState:SetFinalOffset(FINALOFFSET_MIN + 2)  -- below the player
            end
        end
    end
end

return Prefab("sail_snakeskin", snakeskinsail_fn, snakeskinsail_assets),
    visualboatequip.MakeVisualBoatEquip("sail_snakeskin", snakeskinsail_assets, nil, make_sail_snakeskin_visual_setup("swap_sail_snakeskin")),
    visualboatequip.MakeVisualBoatEquipChild("sail_snakeskin", snakeskinsail_assets),
    visualboatequip.MakeVisualBoatEquip("sail_snakeskin_scaly", snakeskinsail_assets, nil, make_sail_snakeskin_visual_setup("swap_sail_snakeskin_scaly")),
    visualboatequip.MakeVisualBoatEquipChild("sail_snakeskin_scaly", snakeskinsail_assets)
