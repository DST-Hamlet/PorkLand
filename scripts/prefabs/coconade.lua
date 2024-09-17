local assets =
{
    Asset("ANIM", "anim/coconade.zip"),
    Asset("ANIM", "anim/swap_coconade.zip"),

    Asset("ANIM", "anim/explode_large.zip"),
    Asset("ANIM", "anim/explode_ring_fx.zip"),
}

local prefabs =
{
    "explode_large",
    "explodering_fx",
    "reticule",
}

local function addfirefx(inst, owner)
    if not inst.fire then
		inst.SoundEmitter:KillSound("hiss")
    	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/cocnade_fuse_loop", "hiss")
        inst.fire = SpawnPrefab("torchfire")
        inst.fire.entity:AddFollower()
    end
    if owner then
        inst.fire.Follower:FollowSymbol(owner.GUID, "swap_object", 40, -140, 1)
    else
        inst.fire.Follower:FollowSymbol(inst.GUID, "swap_flame", 0, 0, 0.1)
    end
end

local function removefirefx(inst)
    if inst.fire then
        inst.SoundEmitter:KillSound("hiss")
        inst.fire:Remove()
        inst.fire = nil
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", inst.swapsymbol, inst.swapbuild)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    if inst.components.burnable:IsBurning() then
        addfirefx(inst, owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    removefirefx(inst)
end

local function ondropped(inst)
    if inst.components.burnable:IsBurning() then
        addfirefx(inst)
    end
end

local function onputininventory(inst)
    removefirefx(inst)
    if inst.components.burnable:IsBurning() then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/cocnade_fuse_loop", "hiss")
    end
end

local function onthrown(inst, thrower, pt)
    inst.Transform:SetFourFaced()
    inst:FacePoint(pt:Get())
    inst.AnimState:PlayAnimation("throw", true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/coconade_throw")
end

local function onexplode(inst, scale)
    scale = scale or 1

    local explode = SpawnPrefab("explode_large")
    local ring = SpawnPrefab("explodering_fx")
    local x, y, z = inst.Transform:GetWorldPosition()

    ring.Transform:SetPosition(x, y, z)
    ring.Transform:SetScale(scale, scale, scale)

    explode.Transform:SetPosition(x, y, z)
    explode.Transform:SetScale(scale, scale, scale)
end

local function onignite(inst)
    inst.components.fuse:StartFuse()
    if inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        addfirefx(inst, owner)
    elseif not inst.components.inventoryitem:IsHeld() then
        addfirefx(inst)
    end
end

local function OnExtinguished(inst)
	inst.SoundEmitter:KillSound("hiss")
	removefirefx(inst)
	inst.components.fuse:StopFuse()

	if inst.LightTask then
		inst.LightTask:Cancel()
	end
end

local function ondepleted(inst)
    inst.components.explosive:OnBurnt()
end

local function getstatus(inst)
    if inst.components.burnable:IsBurning() then
        return "BURNING"
    end
end

local function onremove(inst)
    inst.SoundEmitter:KillSound("hiss")
    removefirefx(inst)
    if inst.LightTask then
        inst.LightTask:Cancel()
    end
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local map = TheWorld.Map
    local pos = Vector3()
    -- Attack range is 8, leave room for error
    -- Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if map:IsPassableAtPoint(pos.x, pos.y, pos.z, true) and not map:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    inst.Physics:SetFriction(.2)
    inst.Physics:SetRestitution(.8)

    inst:AddTag("thrown")
    inst:AddTag("projectile")
    inst:AddTag("fuse") --UI optimisation
    inst:AddTag("allowinventoryburning")
    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("coconade")
    inst:AddTag("explosive")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    inst.OnRemoveEntity = onremove

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    return inst
end

local function masterfn(inst)
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    MakeHauntableLaunch(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(onputininventory)

    inst:AddComponent("fuse")
    inst.components.fuse:SetFuseTime(TUNING.COCONADE_FUSE)
    inst.components.fuse.onfusedone = ondepleted

    inst:AddComponent("burnable")
    inst.components.burnable.nofx = true
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(OnExtinguished)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -- consider using complexprojectile instead and dumping "throwable"
    -- action "TOSS" should be already suitable
    inst:AddComponent("throwable")
    inst.components.throwable.onthrown = onthrown
    inst.components.throwable.yOffset = 1
    inst.components.throwable.speed = 12

    inst:ListenForEvent("on_landed", function(item) inst.components.floater:SwitchToDefaultAnim() end)

    inst:AddComponent("explosive")

    return inst
end

local function firefn()
    local inst = commonfn()

    inst.AnimState:SetBank("coconade")
    inst.AnimState:SetBuild("coconade")
    inst.AnimState:PlayAnimation("idle")

    inst.swapsymbol = "swap_coconade"
    inst.swapbuild = "swap_coconade"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	masterfn(inst)

	inst.components.explosive:SetOnExplodeFn(onexplode)
	inst.components.explosive.explosivedamage = TUNING.COCONADE_DAMAGE
	inst.components.explosive.explosiverange = TUNING.COCONADE_EXPLOSIONRANGE
	inst.components.explosive.buildingdamage = TUNING.COCONADE_BUILDINGDAMAGE

    return inst
end

return Prefab("coconade", firefn, assets, prefabs)
