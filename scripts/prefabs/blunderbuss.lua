local assets =
{
    Asset("ANIM", "anim/blunderbuss.zip"),
    Asset("ANIM", "anim/swap_blunderbuss.zip"),
    Asset("ANIM", "anim/swap_blunderbuss_loaded.zip"),
    Asset("ANIM", "anim/blunderbuss_ammo.zip"),
}

local function OnEquip(inst, owner, force)
    owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_blunderbuss")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst,owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function AbleToTakeAmmon(inst, ammo, giver)
    return not inst:HasTag("blunderbuss_loaded")
end

local function CanTakeAmmo(inst, ammo, giver)
    return ammo.prefab == "gunpowder"
end

local function OnTakeAmmo(inst, data)
    if not data == "loading" and (not data or not data.item) then
        return
    end

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/weapon/blunderbuss_load")

    --Set up as projectile thrower instead of crummy bat
    inst:AddTag("projectile")
    inst.components.weapon:SetProjectile("gunpowder_projectile")
    inst:AddTag("blunderbuss_loaded")

    --Change ranges
    inst.components.weapon:SetRange(TUNING.BLUNDERBUSS_ATTACK_RANGE, TUNING.BLUNDERBUSS_HIT_RANGE)

    inst.override_bank = "swap_blunderbuss_loaded"

    --If equipped, change current equip overrides
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_blunderbuss")
    end

    --Change invo image.
    inst.components.inventoryitem:ChangeImageName("blunderbuss_loaded")
end

local function OnLoseAmmo(inst)
    --Go back to crummy bat mode
    inst:RemoveTag("projectile")
    inst.components.weapon:SetProjectile(nil)
    inst:RemoveTag("blunderbuss_loaded")

    --Change ranges back to melee
    inst.components.weapon:SetRange(nil, nil)

    --Change equip overrides
    inst.override_bank = "swap_blunderbuss"

    --If equipped, change current equip overrides
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        owner.AnimState:OverrideSymbol("swap_object", inst.override_bank, "swap_blunderbuss")
    end

    inst.components.inventoryitem:ChangeImageName("blunderbuss")
end

local function OnProjectileLaunched(inst, attacker, target, proj)
    if attacker and attacker.AnimState then
        proj.Transform:SetPosition(attacker.AnimState:GetSymbolPosition("swap_object", 0, 0, 0))
    else
        local x, y, z = attacker.Transform:GetWorldPosition()
        proj.Transform:SetPosition(x, y + 2.5, z)
    end

    if proj.components.projectile then
        proj.components.projectile:Throw(inst, target, attacker)
    end

    local removed_item = inst.components.inventory.itemslots[1]
    inst.components.inventory:RemoveItem(removed_item, false)

    if removed_item then
        removed_item:Remove()
    end

    OnLoseAmmo(inst)
end

local function OnSave(inst, data)
    data.blunderbuss_loaded = inst:HasTag("blunderbuss_loaded")
end

local function OnLoad(inst, data)
    if data and data.blunderbuss_loaded then
        OnTakeAmmo(inst, "loading")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.AnimState:SetBank("blunderbuss")
    inst.AnimState:SetBuild("blunderbuss")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("blunderbuss")
    inst:AddTag("rangedweapon")
    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("weapon")
    inst.components.weapon.projectilelaunchsymbol = "swap_object"
    inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)

    inst:AddComponent("inventoryitem")

    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 1

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToTakeAmmon)
    inst.components.trader:SetAcceptTest(CanTakeAmmo)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("trade", OnTakeAmmo)

    inst.override_bank = "swap_blunderbuss"

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function OnHit(inst, attacker, target)
    local fx = SpawnPrefab("impact")
    if fx and attacker then
        local follower = fx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        fx:FacePoint(attacker.Transform:GetWorldPosition())
    end

    inst:Remove()
end

local function projectile_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank("amo01")
    inst.AnimState:SetBuild("blunderbuss_ammo")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.GUNPOWDER_DAMAGE)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(50)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile.has_damage_set = true

    inst.persists = false

    return inst
end

return Prefab("blunderbuss", fn, assets),
       Prefab("gunpowder_projectile", projectile_fn, assets)
