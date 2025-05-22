local assets =
{
    Asset("ANIM", "anim/swap_trusty_shooter.zip"),
    Asset("ANIM", "anim/trusty_shooter.zip"),
    Asset("INV_IMAGE", "trusty_shooter_unloaded"),
    Asset("MINIMAP_IMAGE", "trusty_shooter"),
}

local function SetAmmoDamageAndRange(inst, ammo, owner)
    -- Only wheeler gets the full damage and range
    local modifier = owner and owner:HasTag("trusty_shooter") and 1 or 0.5

    if ammo then
        if ammo.components.equippable then
            inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_HIGH * modifier, TUNING.TRUSTY_SHOOTER_HIT_RANGE_HIGH * modifier)
            inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_HIGH * modifier)
            return
        end

        for _, v in ipairs(TUNING.TRUSTY_SHOOTER_TIERS.AMMO_HIGH) do
            if ammo.prefab == v then
                inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_HIGH * modifier, TUNING.TRUSTY_SHOOTER_HIT_RANGE_HIGH * modifier)
                inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_HIGH * modifier)
                return
            end
        end

        for _, v in ipairs(TUNING.TRUSTY_SHOOTER_TIERS.AMMO_LOW) do
            if ammo.prefab == v then
                inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_LOW * modifier, TUNING.TRUSTY_SHOOTER_HIT_RANGE_LOW * modifier)
                inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_LOW * modifier)
                return
            end
        end
    end

    inst.components.weapon:SetRange(TUNING.TRUSTY_SHOOTER_ATTACK_RANGE_MEDIUM * modifier, TUNING.TRUSTY_SHOOTER_HIT_RANGE_MEDIUM * modifier)
    inst.components.weapon:SetDamage(TUNING.TRUSTY_SHOOTER_DAMAGE_MEDIUM * modifier)
end

local function OnEquip(inst, owner, force)
    owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_trusty_shooter")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container then
        inst.components.container:Open(owner)

        local item = inst.components.container:GetItemInSlot(1)
        if item and item:IsValid() then
            inst:AddTag("gun")
            SetAmmoDamageAndRange(inst, item, owner)
        end
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

local function GetTakeAmmoSound(ammo)
    if ammo.replica.equippable then
        return "dontstarve_DLC003/characters/wheeler/air_horn/load_3"
    end
    for _, v in ipairs(TUNING.TRUSTY_SHOOTER_TIERS.AMMO_HIGH) do
        if ammo.prefab == v then
            return "dontstarve_DLC003/characters/wheeler/air_horn/load_3"
        end
    end
    for _, v in ipairs(TUNING.TRUSTY_SHOOTER_TIERS.AMMO_LOW) do
        if ammo.prefab == v then
            return "dontstarve_DLC003/characters/wheeler/air_horn/load_1"
        end
    end
    return "dontstarve_DLC003/characters/wheeler/air_horn/load_2"
end

local function LoadWeapon(inst, item)
        -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/load_2")

    inst:AddTag("projectile")
    inst.components.weapon:SetProjectile(item.prefab)
    inst:AddTag("hand_gun_loaded")

    --If equipped, change current equip overrides
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and inst.components.equippable and inst.components.equippable:IsEquipped() then
        owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_trusty_shooter")
    end

    inst:AddTag("gun")
    SetAmmoDamageAndRange(inst, item, owner)

    inst.components.inventoryitem:ChangeImageName("trusty_shooter")
end

local function OnTakeAmmo(inst, data)
    local ammo = data and data.item
    if ammo then
        LoadWeapon(inst, data.item)
    end
end

local function OnTakeAmmoClient(inst, data)
    local ammo = data and data.item
    if ammo and inst.replica.inventoryitem:IsHeldBy(ThePlayer) then
        local container_classified = inst.replica.container and inst.replica.container.classified
        if not (container_classified
            and container_classified._itemspreview
            and container_classified._itemspreview[data.slot]
            and container_classified._itemspreview[data.slot].prefab == ammo.prefab
        ) then
            TheFocalPoint.SoundEmitter:PlaySound(GetTakeAmmoSound(ammo))
        end
    end
end

local function ResetAmmo(inst)
    --Go back to crummy bat mode
    inst:RemoveTag("projectile")
    inst.components.weapon:SetProjectile(nil)
    inst:RemoveTag("hand_gun_loaded")
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
    local damage = inst.components.weapon.damage

    if inst.components.container then
        local ammo_stack = inst.components.container:GetItemInSlot(1)
        local item = inst.components.container:RemoveItem(ammo_stack)
        if item then
            item:Remove()
        end
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/characters/wheeler/air_horn/shoot")

    if proj.components.projectile_gun == nil then
        proj:AddComponent("projectile_gun")
    end

    proj.components.projectile_gun.damage = damage
    proj.components.projectile_gun:SetSpeed(35)
    proj.components.projectile_gun:SetOnHitFn(OnProjectileHit)

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
    proj.components.projectile_gun:Throw(inst, target, attacker)

    inst.components.finiteuses:Use(1)
end

local function OnFinished(inst)
    inst.components.container:DropEverything(inst:GetPosition())
    inst:Remove()
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
    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    inst.CanTakeAmmo = CanTakeAmmo

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("itemget", OnTakeAmmoClient)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

    inst:AddComponent("weapon")
    inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("trusty_shooter_unloaded")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("trusty_shooter")
    inst:ListenForEvent("itemget", OnTakeAmmo)
    inst:ListenForEvent("itemlose", ResetAmmo)

    inst.override_bank = "swap_trusty_shooter"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(OnFinished)
    inst.components.finiteuses:SetMaxUses(TUNING.TRUSTY_SHOOTER_USES)
    inst.components.finiteuses:SetUses(TUNING.TRUSTY_SHOOTER_USES)

    return inst
end

return Prefab("trusty_shooter", fn, assets)
