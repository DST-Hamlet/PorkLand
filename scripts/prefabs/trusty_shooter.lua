local assets =
{
    Asset("ANIM", "anim/swap_trusty_shooter.zip"),
    Asset("ANIM", "anim/trusty_shooter.zip"),
    Asset("INV_IMAGE", "trusty_shooter_unloaded"),
    Asset("MINIMAP_IMAGE", "trusty_shooter"),
}

local function OnEquip(inst, owner, force)
    owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_trusty_shooter")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container then
        inst.components.container:Open(owner)
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container then
        inst.components.container:Close()
    end
end

local function OnEquipToModel(inst, owner, from_ground)
    if inst.components.container then
        inst.components.container:Close()
    end
end

local function CanTakeAmmo(inst, ammo)
    return not ammo.replica.health
        and not ammo:HasTag("irreplaceable")
        and not ammo:HasTag("invalidammo")
end

local function SetAmmoDamageAndRange(inst, ammo)
    if ammo.components.equippable then
        inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_HIGH, TUNING.TRUSTY_SHOOTER_HIT_RANGE_HIGH)
        inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_HIGH)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/load_3")
        return
    end

    for _, v in ipairs(TUNING.TRUSTY_SHOOTER_TIERS.AMMO_HIGH) do
        if ammo.prefab == v then
            inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_HIGH, TUNING.TRUSTY_SHOOTER_HIT_RANGE_HIGH)
            inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_HIGH)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/load_3")
            return
        end
    end

    for _, v in ipairs(TUNING.TRUSTY_SHOOTER_TIERS.AMMO_LOW) do
        if ammo.prefab == v then
            inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_LOW, TUNING.TRUSTY_SHOOTER_HIT_RANGE_LOW)
            inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_LOW)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/load_1")
            return
        end
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/load_2")
    inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_MEDIUM, TUNING.TRUSTY_SHOOTER_HIT_RANGE_MEDIUM)
    inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_MEDIUM)
end

local function LoadWeapon(inst, item)
        -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/load_2")

    inst:AddTag("projectile")
    inst.components.weapon:SetProjectile(item.prefab)
    inst:AddTag("gun")

    SetAmmoDamageAndRange(inst, item)

    --If equipped, change current equip overrides
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and inst.components.equippable and inst.components.equippable:IsEquipped() then
        owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_trusty_shooter")
    end

    inst.components.inventoryitem:ChangeImageName("trusty_shooter")
end

local function OnTakeAmmo(inst, data)
    local ammo = data and data.item
    if ammo then
        LoadWeapon(inst, data.item)
    end
end

local function ResetAmmo(inst)
    --Go back to crummy bat mode
    inst:RemoveTag("projectile")
    inst.components.weapon:SetProjectile(nil)
    inst:RemoveTag("gun")

    --Change ranges back to melee
    inst.components.weapon:SetRange(nil, nil)
    inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)

    --Change equip overrides
    inst.override_bank = "swap_trusty_shooter"

    --If equipped, change current equip overrides
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and inst.components.equippable and inst.components.equippable:IsEquipped() then
        owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_trusty_shooter")
    end

    inst.components.inventoryitem:ChangeImageName("trusty_shooter_unloaded")
end

local function OnProjectileHit(inst, attacker, target, weapon)
    -- TODO: Make this work
    -- inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/bag_impact")
    local impactfx = SpawnPrefab("impact")
    if impactfx and attacker then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        impactfx:FacePoint(attacker.Transform:GetWorldPosition())
    end

    inst:Remove()
end

local function OnProjectileLaunched(inst, attacker, target, proj)
    if inst.components.container then
        local ammo_stack = inst.components.container:GetItemInSlot(1)
        local item = inst.components.container:RemoveItem(ammo_stack)
        if item then
            item:Remove()
        end
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/shoot")

    proj:AddComponent("projectile")

    proj.components.projectile:SetSpeed(35)
    proj.components.projectile:SetOnHitFn(OnProjectileHit)

    proj.components.inventoryitem.canbepickedup = false

    proj:RemoveComponent("blowinwind")

    proj.persists = false

    -- If the projectile still exists in 2 seconds something went wrong
    proj.self_destruct = proj:DoTaskInTime(2, proj.Remove)

    if attacker and attacker.AnimState then
        proj.Transform:SetPosition(attacker.AnimState:GetSymbolPosition("swap_object", 0, 0, 0))
    else
        local x, y, z = attacker.Transform:GetWorldPosition()
        proj.Transform:SetPosition(x, y + 2.5, z)
    end
    proj.components.projectile:Throw(inst, target, attacker)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("trusty_shooter.tex")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("trusty_shooter")
    inst.AnimState:SetBuild("trusty_shooter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hand_gun")
    inst:AddTag("irreplaceable")

    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    inst.CanTakeAmmo = CanTakeAmmo

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.restrictedtag = "trusty_shooter"
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

    inst:AddComponent("weapon")
    inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("trusty_shooter_unloaded")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("trusty_shooter")
    inst.components.container.canbeopened = false
    inst.components.container.stay_open_on_hide = true
    inst:ListenForEvent("itemget", OnTakeAmmo)
    inst:ListenForEvent("itemlose", ResetAmmo)

    inst.override_bank = "swap_trusty_shooter"

    -- inst:AddComponent("characterspecific")
    -- inst.components.characterspecific:SetOwner("wheeler")

    return inst
end

return Prefab("trusty_shooter", fn, assets)
