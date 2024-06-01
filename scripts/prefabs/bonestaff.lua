local assets =
{
	Asset("ANIM", "anim/pl_staffs.zip"),
	Asset("ANIM", "anim/pl_swap_staffs.zip"),
}

local prefabs =
{
    "gaze_beam"
}

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "pl_swap_staffs", "bonestaff")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function SpawnGaze(inst)
    local owner = nil
    owner = inst.components.inventoryitem:GetGrandOwner()
    local mousepos = TheInput:GetWorldPosition()
    local rotation = nil

    if TheInput:ControllerAttached() then
        local pc = ThePlayer.components.playercontroller
        if pc.reticule and pc.reticule.targetpos then
            local pt = pc.reticule.targetpos
            rotation = owner:GetAngleToPoint(pt.x, pt.y, pt.z)
        end

        if not rotation then
            rotation = owner.Transform:GetRotation()
        end
    else
        rotation = owner:GetAngleToPoint(mousepos.x, mousepos.y, mousepos.z)
    end

    local beam = SpawnPrefab("gaze_beam")
    local pt = Vector3(owner.Transform:GetWorldPosition())
    local angle = rotation * DEGREES
    local radius = 4
    local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin(angle))
    local newpt = pt+offset

    beam.Transform:SetPosition(newpt.x, newpt.y, newpt.z)
    beam.host = owner

    beam.Transform:SetRotation(rotation)
end

local function EndGaze(inst)
    if inst.gazetask then
        inst.gazetask:Cancel()
        inst.gazetask = nil
    end
    inst.SoundEmitter:KillSound("gazor")
end

local function endbonecast(inst)
    EndGaze(inst)
end

local function CastSpell(staff, target, pos, caster)
    EndGaze(staff)

    local owner = staff.components.inventoryitem:GetGrandOwner()
    if owner then
        staff.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/gaze_start")
        staff.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/gaze_LP", "gazor")
        staff.gazetask = staff:DoPeriodicTask(0.4, function()
            if owner.sg:HasStateTag("spell") then
                SpawnGaze(staff)
            else
                EndGaze(staff)
            end
        end, 0)
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
    inst.components.floater:UpdateAnimations("bonestaff_water", "bonestaff")

    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("pl_staffs")
    inst.AnimState:PlayAnimation("bonestaff")

    inst:AddTag("bonestaff")
    inst:AddTag("nopunch")
    inst:AddTag("nosteal")
    inst:AddTag("show_spoilage")
    -- shadowlevel (from shadowlevel component) added to pristine state for optimization
    inst:AddTag("shadowlevel")

    inst.fxcolour = {223/255, 208/255, 69/255}

    inst:AddComponent("reticule")
    inst.components.reticule.ease = true
    inst.components.reticule.targetfn = function()
        return Vector3(ThePlayer.entity:LocalToWorldSpace(5, 0.001, 0))
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(CastSpell)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canusefrominventory = false
    inst.castfast = true

    inst:AddComponent("perishable")
    inst.components.perishable.onperishreplacement = "boneshard"
    inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY/2)
    inst.components.perishable:StartPerishing()

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.STAFF_SHADOW_LEVEL)

    inst.endcast = endbonecast

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("bonestaff", fn, assets, prefabs)
