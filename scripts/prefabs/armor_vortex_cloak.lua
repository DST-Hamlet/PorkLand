local assets =
{
    Asset("ANIM", "anim/armor_vortex_cloak.zip"),
    Asset("ANIM", "anim/cloak_fx.zip"),
    Asset("ANIM", "anim/ui_krampusbag_2x5.zip")
}

local function SetSoundparam(inst)
    local param = Remap(inst.components.fueled.currentfuel, 0, inst.components.fueled.maxfuel, 0, 1)
    inst.SoundEmitter:SetParameter("vortex", "intensity", param)
end

local function SpawnFx(owner)
    local fx = SpawnPrefab("armorvortexcloak_fx")
    local x, y, z = owner.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x + math.random() * 0.25 - 0.25 / 2, y, z + math.random() * 0.25 -0.25 / 2)
end

local function OnResistDamage(inst, damage)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    local fx = SpawnPrefab("vortex_cloak_fx")
    fx.entity:SetParent(owner.entity)

    local sanity = owner.components.sanity
    if sanity then
        local unsaneness = damage * TUNING.ARMORVORTEX_DMG_AS_SANITY
        sanity:DoDelta(-unsaneness, false)
    end

    inst.components.fueled:DoDelta(-4 * TUNING.LARGE_FUEL * damage / TUNING.ARMORVORTEX)
end

local function ShouldResistFn(inst)
    if not inst.components.equippable:IsEquipped() then
        return false
    end
    if inst.components.fueled:IsEmpty() then
        return false
    end
    local owner = inst.components.inventoryitem.owner
    return owner and not (owner.components.inventory and owner.components.inventory:EquipHasTag("forcefield")) -- thulecite crown
end

local function CLIENT_PlayFuelSound(inst)
    local parent = inst.entity:GetParent()
    local container = parent ~= nil and (parent.replica.inventory or parent.replica.container) or nil
    if container ~= nil and container:IsOpenedBy(ThePlayer) then
        TheFocalPoint.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/vortex_armour/add_fuel")
    end
end

local function SERVER_PlayFuelSound(inst)
    local owner = inst.components.inventoryitem.owner
    if owner == nil then
        inst.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/vortex_armour/add_fuel")
    elseif inst.components.equippable:IsEquipped() and owner.SoundEmitter ~= nil then
        owner.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/vortex_armour/add_fuel")
    else
        inst.playfuelsound:push()
        -- Dedicated server does not need to trigger sfx
        if not TheNet:IsDedicated() then
            CLIENT_PlayFuelSound(inst)
        end
    end
end

local function OnTakeFuel(inst, fuel)
    SERVER_PlayFuelSound(inst)
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_vortex_cloak", "swap_body")
    owner.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/vortex_armour/equip_off")

    inst.components.container:Open(owner)

    inst.fx_task = inst:DoPeriodicTask(0.1, function() 
        if not inst.components.fueled:IsEmpty() then
            SpawnFx(owner)
        end
    end)

    -- 由于许多人反映这个音效干扰性过强，因此暂时禁用这个音效——或许可以仅在玩家移动时播放这个音效？
    -- inst.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/vortex_armour/LP", "vortex")
    SetSoundparam(inst)
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.SoundEmitter:PlaySound("porkland_soundpackage/common/crafted/vortex_armour/equip_on")

    inst.components.container:Close(owner)

    if inst.fx_task then
        inst.fx_task:Cancel()
        inst.fx_task = nil
    end

    inst.SoundEmitter:KillSound("vortex")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "anim")

    inst.AnimState:SetBank("armor_vortex_cloak")
    inst.AnimState:SetBuild("armor_vortex_cloak")
    inst.AnimState:PlayAnimation("anim")

    inst.MiniMapEntity:SetIcon("armor_vortex_cloak.tex")

    inst:AddTag("vortex_cloak")
    inst:AddTag("shadow_item")

    --shadowlevel (from shadowlevel component) added to pristine state for optimization
    inst:AddTag("shadowlevel")

    inst.foleysound = "dontstarve_DLC003/common/crafted/vortex_armour/foley"

    inst.playfuelsound = net_event(inst.GUID, "armorvortexcloak.playfuelsound")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("armorvortexcloak.playfuelsound", CLIENT_PlayFuelSound)
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("armorvortexcloak")

    inst:AddComponent("resistance")
    inst.components.resistance:SetShouldResistFn(ShouldResistFn)
    inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
    inst.components.resistance.alltype_tags = true
    inst.components.resistance:SetNoTags({"shadow", "darkness"}) -- doesn't protect from shadow creatures

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(4 * TUNING.LARGE_FUEL)
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled.secondaryfueltype = FUELTYPE.ANCIENT_REMNANT
    inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
    inst.components.fueled.accepting = true
    inst.components.fueled.bonusmult = 0.4

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.ARMOTVORTEX_SHADOW_LEVEL)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return  Prefab("armorvortexcloak", fn, assets)
