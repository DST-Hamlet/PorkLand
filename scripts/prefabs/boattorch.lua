local MakeVisualBoatEquip = require("prefabs/visualboatequip")

local assets = {
    Asset("ANIM", "anim/swap_torch_boat.zip"),
}

local prefabs = {
    "boat_torch_light",
}

local function fuelupdate(inst)
    if inst._light ~= nil then
        local fuelpercent = inst.components.fueled:GetPercent()
        inst._light.Light:SetIntensity(Lerp(0.4, 0.6, fuelpercent))
        inst._light.Light:SetRadius(Lerp(3, 5, fuelpercent))
        inst._light.Light:SetFalloff(0.9)
    end
end

local function setswapsymbol(inst, symbol)
    if inst.visual then
        inst.visual.AnimState:OverrideSymbol("swap_lantern", inst.visualbuild, symbol)
    end
end

local function turnon(inst)
    if not inst.components.fueled:IsEmpty() then
        if inst.onsound then
            for i, v in ipairs(inst.onsound) do
                inst.SoundEmitter:PlaySound(v)
            end
        end

        if not inst.SoundEmitter:PlayingSound("boatlamp") then
            inst.SoundEmitter:PlaySound("ia/common/boatlantern_lp", "boatlamp")
        end

        if inst.components.fueled then
            inst.components.fueled:StartConsuming()
        end

        if inst._light == nil or not inst._light:IsValid() then
            inst._light = SpawnPrefab(inst.prefab .."_light")
            if inst.components.fueled.accepting then
                fuelupdate(inst)
            end
        end

        local owner = inst.components.inventoryitem.owner

        inst._light.entity:SetParent((owner or inst).entity)
        setswapsymbol(inst, "swap_lantern")
    end

    inst.components.inventoryitem:ChangeImageName(nil)
end

local function turnoff(inst)
    inst.SoundEmitter:KillSound("boatlamp")

    if inst.offsound then
        for i, v in ipairs(inst.offsound) do
            inst.SoundEmitter:PlaySound(v)
        end
    end

    if inst.components.fueled then
        inst.components.fueled:StopConsuming()
    end

    setswapsymbol(inst, "swap_lantern_off")

	if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
	end

    inst.components.inventoryitem:ChangeImageName(inst.prefab.."_off")
end

local function onequip(inst, owner)
    if owner.components.boatvisualmanager then
        owner.components.boatvisualmanager:SpawnBoatEquipVisuals(inst, inst.visualprefab)
    end
    if owner.components.sailable then
        inst:ListenForEvent("embarked", inst.onembarked, owner)
        inst:ListenForEvent("disembarked", inst.ondisembarked, owner)
    end
    setswapsymbol(inst, inst.components.equippable:IsToggledOn() and "swap_lantern" or "swap_lantern_off")
end

local function onunequip(inst, owner)
    if owner.components.boatvisualmanager then
        owner.components.boatvisualmanager:RemoveBoatEquipVisuals(inst)
    end
    if owner.components.sailable then
        inst:RemoveEventCallback("embarked", inst.onembarked, owner)
        inst:RemoveEventCallback("disembarked", inst.ondisembarked, owner)
    end
	if inst.components.equippable:IsToggledOn() then
		inst.components.equippable:ToggleOff()
	end
end

local function nofuel(inst)
    if inst.components.fueled.accepting then
        inst.components.equippable.togglable = false
        -- turnoff(inst)
        inst.components.equippable:ToggleOff()
    else
        inst:Remove()
    end
end

local function takefuel(inst)
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        inst.components.equippable.togglable = true
        -- turnon(inst)
        inst.components.equippable:ToggleOn()
    end
end

local function onremove(inst)
    if inst._light ~= nil then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
    end
end

local function ondropped(inst)
	if inst.components.equippable:IsToggledOn() then
		inst.components.equippable:ToggleOff()
	end
end

local function commonpristinefn(bank, build)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst.visualbuild = build

	MakeInventoryFloatable(inst)
	inst.components.floater:UpdateAnimations("idle_water", "idle")

    return inst
end

local function serverfn(inst, image_name)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName(image_name)
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_LAMP
    inst.components.equippable.equipslot = nil
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.togglable = true
    inst.components.equippable.toggledonfn = turnon
    inst.components.equippable.toggledofffn = turnoff

    inst.onembarked = function(owner, data)
        if inst._light ~= nil and inst._light:IsValid() then
            local owner = data.sailor
            if owner then
                inst._light.entity:SetParent(owner.entity)
            end
        end
    end
    inst.ondisembarked = function()
        if inst._light ~= nil and inst._light:IsValid() then
            local owner = inst.components.inventoryitem.owner
            inst._light.entity:SetParent((owner or inst).entity)
        end
    end

    MakeHauntableLaunch(inst)

    inst.OnRemove = onremove

    return inst
end

local function fn()
    local inst = commonpristinefn("torch_boat", "swap_torch_boat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.onsound = {"dontstarve/wilson/torch_swing"}
    inst.offsound = {"ia/common/boatlantern_turnoff", "dontstarve/common/fireOut"}

    serverfn(inst, "boat_torch_off")

    inst.visualprefab = "boat_torch"

    inst.components.fueled.fueltype = "BURNABLE"
    inst.components.fueled:InitializeFuelLevel(TUNING.BOAT_TORCH_LIGHTTIME)

    return inst
end

local function MakeLight(name, common_postinit)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        common_postinit(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        return inst
    end

    return Prefab(name, fn)

end

local function common(inst)
    inst.Light:SetColour(200/255, 200/255, 50/255)
    inst.Light:SetRadius(2)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
end

function visual_common(inst)
    inst.AnimState:SetBank("sail_visual")
    inst.AnimState:SetBuild("swap_torch_boat")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetSortWorldOffset(0, 0.05, 0) --below the player

    function inst.components.boatvisualanims.update(inst, dt)
        if inst.AnimState:GetCurrentFacing() == FACING_DOWN then
            inst.AnimState:SetSortWorldOffset(0, 0.15, 0) --above the player
        else
            inst.AnimState:SetSortWorldOffset(0, 0.05, 0) --below the player
        end
    end
end


return  Prefab("boat_torch", fn, assets, prefabs),
        MakeLight("boat_torch_light", common),
        MakeVisualBoatEquip("boat_torch", assets, nil, visual_common)
