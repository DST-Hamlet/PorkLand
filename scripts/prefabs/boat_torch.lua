local visualboatequip = require("prefabs/visualboatequip")

local torchassets = {
    Asset("ANIM", "anim/swap_torch_boat.zip"),
}

local torchprefabs = {
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
        inst.visual.visualchild.AnimState:OverrideSymbol("swap_lantern", inst.visualbuild, symbol)
        inst.visual._oversymbol:set(symbol)
    end
end

local function turnon(inst)
    if not inst.components.fueled:IsEmpty() then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")

        if not inst.SoundEmitter:PlayingSound("boatlamp") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boatlantern_lp", "boatlamp")
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
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boatlantern_turnoff")

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

local function OnRemove(inst)
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

local function OnSave(inst)
    return {was_on = inst.components.fueled.consuming}
end

local function OnLoad(inst, data)
    if data and data.was_on then
        turnon(inst)
    else
        turnoff(inst)
    end
end

local function torchfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("torch_boat")
    inst.AnimState:SetBuild("swap_torch_boat")
    inst.AnimState:PlayAnimation("idle")

    inst.visualbuild = "swap_torch_boat"

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("boat_torch_off")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:InitializeFuelLevel(TUNING.BOAT_TORCH_LIGHTTIME)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.boatequipslot = BOATEQUIPSLOTS.BOAT_LAMP
    inst.components.equippable.equipslot = nil
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.togglable = true
    inst.components.equippable.toggledonfn = turnon
    inst.components.equippable.toggledofffn = turnoff

    MakeHauntableLaunch(inst)

    inst.visualprefab = "boat_torch"

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnRemove = OnRemove

    inst.onembarked = function(owner, data)
        if inst._light ~= nil and inst._light:IsValid() then
            local sailor = data.sailor
            if sailor then
                inst._light.entity:SetParent(sailor.entity)
            end
        end
    end
    inst.ondisembarked = function()
        if inst._light ~= nil and inst._light:IsValid() then
            local owner = inst.components.inventoryitem.owner
            inst._light.entity:SetParent((owner or inst).entity)
        end
    end

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

local function torchlightcommon(inst)
    inst.Light:SetColour(200/255, 200/255, 50/255)
    inst.Light:SetRadius(2)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
end

local function torch_visual_common(inst)
    inst.visualchild.AnimState:SetBank("sail_visual")
    inst.visualchild.AnimState:SetBuild("swap_torch_boat")
    inst.visualchild.AnimState:PlayAnimation("idle_loop")
    inst.visualchild.AnimState:SetSortWorldOffset(0, 0.05, 0) --below the player

    inst._oversymbol = net_string(inst.GUID, "_oversymbol", "symboldirty")
    inst._oversymbol:set("swap_lantern_off")

    if not TheWorld.ismastersim then
        inst:ListenForEvent("symboldirty", function()
            if "symboldirty" ~= "" then
                inst.visualchild.AnimState:OverrideSymbol("swap_lantern", "swap_torch_boat", inst._oversymbol:value())
            end
        end)
    end

    function inst.components.boatvisualanims.update(inst, dt)
        if inst.visualchild.AnimState:GetCurrentFacing() == FACING_DOWN then
            inst.visualchild.AnimState:SetSortWorldOffset(0, 0.15, 0) --above the player
        else
            inst.visualchild.AnimState:SetSortWorldOffset(0, 0.05, 0) --below the player
        end
    end
end


return Prefab("boat_torch", torchfn, torchassets, torchprefabs),
       MakeLight("boat_torch_light", torchlightcommon),
       visualboatequip.MakeVisualBoatEquip("boat_torch", torchassets, nil, torch_visual_common),
       visualboatequip.MakeVisualBoatEquipChild("boat_torch", torchassets, nil, torch_visual_common)
