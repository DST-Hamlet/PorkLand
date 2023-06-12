local assets =
{
    Asset("ANIM", "anim/laser_hit_sparks_fx.zip"),
}

local assets_scorch =
{
    Asset("ANIM", "anim/laser_burntground.zip"),
}

local assets_trail =
{
    Asset("ANIM", "anim/laser_smoke_fx.zip"),
}

local prefabs =
{
    "laserscorch",
    "lasertrail",
    "laserhit",
}

local LAUNCH_SPEED = .2
local RADIUS = 1.7

local function SetLightRadius(inst, radius)
    inst.Light:SetRadius(radius)
end

local function DisableLight(inst)
    inst.Light:Enable(false)
end
local function setfires(x,y,z)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS, nil, { "laser", "DECOR", "INLIMBO" })) do 
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end
local function DoDamage(inst, targets, skiptoss)
    inst.task = nil

    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.AnimState ~= nil then
        inst.AnimState:PlayAnimation("hit_"..tostring(math.random(5)))
        inst:Show()
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

        inst.Light:Enable(true)
        inst:DoTaskInTime(4 * FRAMES, SetLightRadius, .5)
        inst:DoTaskInTime(5 * FRAMES, DisableLight)

        SpawnPrefab("laserscorch").Transform:SetPosition(x, 0, z)
        local fx = SpawnPrefab("lasertrail")
        fx.Transform:SetPosition(x, 0, z)
        fx:FastForward(GetRandomMinMax(.3, .7))
    else
        inst:DoTaskInTime(2 * FRAMES, inst.Remove)
    end
    setfires(x,y,z)
    inst.components.combat.ignorehitrange = true
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, nil, { "laser", "DECOR", "INLIMBO" })) do  --  { "_combat", "pickable", "campfire", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
        if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) and not v:HasTag("laser_immune") then            


            local vradius = 0
            if v.Physics then
                vradius = v.Physics:GetRadius()
            end

            local range = RADIUS + vradius
            if v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
                local isworkable = false
                if v.components.workable ~= nil then
                    local work_action = v.components.workable:GetWorkAction()
                    --V2C: nil action for campfires
                    isworkable =
                        (   work_action == nil and v:HasTag("campfire")    ) or
                        
                            (   work_action == ACTIONS.CHOP or
                                work_action == ACTIONS.HAMMER or
                                work_action == ACTIONS.MINE or   
                                work_action == ACTIONS.DIG
                            )
                end
                if isworkable then
                    targets[v] = true
                    v:DoTaskInTime(0.6, function() 
                        if v.components.workable then
                            v.components.workable:Destroy(inst) 
                            v:DoTaskInTime(0,function() setfires(x,y,z) end)
                        end
                     end)
                    if v:IsValid() and v:HasTag("stump") then
                        v:Remove()
                    end
                elseif v.components.pickable ~= nil
                    and v.components.pickable:CanBePicked()
                    and not v:HasTag("intense") then
                    targets[v] = true
                    local num = v.components.pickable.numtoharvest or 1
                    local product = v.components.pickable.product
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                    if product ~= nil and num > 0 then
                        for i = 1, num do
                            local loot = SpawnPrefab(product)
                            loot.Transform:SetPosition(x1, 0, z1)
                            skiptoss[loot] = true
                            targets[loot] = true
                            --Launch(loot, inst, LAUNCH_SPEED)
                        end
                    end
                    --[[
                elseif inst.components.combat:CanTarget(v) then
                    targets[v] = true
                    if inst.caster ~= nil and inst.caster:IsValid() then
                        inst.caster.components.combat.ignorehitrange = true
                        inst.caster.components.combat:DoAttack(v)
                        inst.caster.components.combat.ignorehitrange = false
                    else
                        inst.components.combat:DoAttack(v)
                    end                    

                    if v:IsValid() then
                        if not v.components.health or not v.components.health:IsDead() then
                            if v.components.freezable ~= nil then
                                if v.components.freezable:IsFrozen() then
                                    v.components.freezable:Unfreeze()
                                elseif v.components.freezable.coldness > 0 then
                                    v.components.freezable:AddColdness(-2)
                                end
                            end
                            if v.components.temperature ~= nil then
                                local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                                local curtemp = v.components.temperature:GetCurrent()
                                if maxtemp > curtemp then
                                    v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                                end
                            end
                        end
                    end]]

                elseif v.components.health then                    
                    inst.components.combat:DoAttack(v)                
                    if v:IsValid() then
                        if not v.components.health or not v.components.health:IsDead() then
                            if v.components.freezable ~= nil then
                                if v.components.freezable:IsFrozen() then
                                    v.components.freezable:Unfreeze()
                                elseif v.components.freezable.coldness > 0 then
                                    v.components.freezable:AddColdness(-2)
                                end
                            end
                            if v.components.temperature ~= nil then
                                local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                                local curtemp = v.components.temperature:GetCurrent()
                                if maxtemp > curtemp then
                                    v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                                end
                            end
                        end
                    end                   
                end
                if v:IsValid() and v.AnimState then
                    SpawnPrefab("laserhit"):SetTarget(v)
                end

            end
        end
    end
    inst.components.combat.ignorehitrange = false
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, { "_inventoryitem" }, { "locomotor", "INLIMBO" })) do
        if not skiptoss[v] then
            local radius = 0
            if v.Physics then
                radius = v.Physics:GetRadius()
            end            
            local range = RADIUS + radius
            if v:GetDistanceSqToPoint(Vector3(x, y, z) ) < range * range then
                if v.components.mine ~= nil then
                    targets[v] = true
                    skiptoss[v] = true
                    v.components.mine:Deactivate()
                end
                if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
                    targets[v] = true
                    skiptoss[v] = true
                    Launch(v, inst, LAUNCH_SPEED)
                end
            end
        end
    end
end

local function Trigger(inst, delay, targets, skiptoss)
    if inst.task ~= nil then
        inst.task:Cancel()
        if (delay or 0) > 0 then
            inst.task = inst:DoTaskInTime(delay, DoDamage, targets or {}, skiptoss or {})
        else
            DoDamage(inst, targets or {}, skiptoss or {})
        end
    end
end

local function KeepTargetFn()
    return false
end

local function common_fn(isempty)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

	inst.entity:SetPristine()

    if not isempty then
        inst.entity:AddAnimState()
        inst.AnimState:SetBank("laser_hits_sparks")
        inst.AnimState:SetBuild("laser_hit_sparks_fx")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)

        inst.entity:AddLight()
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(1)
        inst.Light:SetFalloff(.7)
        inst.Light:SetColour(1, .2, .3)
        inst.Light:Enable(false)
    end

	if not TheWorld.ismastersim then
		return inst
	end

    inst:Hide()

    inst:AddTag("notarget")
    inst:AddTag("hostile")
    inst:AddTag("laser")

    inst:SetPrefabNameOverride("deerclops")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.LASER_DAMAGE)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst.task = inst:DoTaskInTime(0, inst.Remove)
    inst.Trigger = Trigger
    inst.persists = false

    return inst
end

local function fn()
    local inst = common_fn(false)
    inst.Light:Enable(false)
    return inst
end

local function emptyfn()
    return common_fn(true)
end

local SCORCH_RED_FRAMES = 20
local SCORCH_DELAY_FRAMES = 40
local SCORCH_FADE_FRAMES = 15

local function Scorch_OnFadeDirty(inst)
    --V2C: hack alert: using SetHightlightColour to achieve something like OverrideAddColour
    --     (that function does not exist), because we know this FX can never be highlighted!
    if inst._fade:value() > SCORCH_FADE_FRAMES + SCORCH_DELAY_FRAMES then
        local k = (inst._fade:value() - SCORCH_FADE_FRAMES - SCORCH_DELAY_FRAMES) / SCORCH_RED_FRAMES
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst.AnimState:SetHighlightColour(k, 0, 0, 0)
    elseif inst._fade:value() >= SCORCH_FADE_FRAMES then
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst.AnimState:SetHighlightColour()
    else
        local k = inst._fade:value() / SCORCH_FADE_FRAMES
        k = k * k
        inst.AnimState:OverrideMultColour(k, k, k, k)
        inst.AnimState:SetHighlightColour()
    end
end

local function Scorch_OnUpdateFade(inst)
    inst.alpha = math.max(0, inst.alpha - (1/90) )
    inst.AnimState:SetMultColour(1, 1, 1,  inst.alpha)
    if inst.alpha == 0 then
        inst:Remove()
    end
    --[[
    if inst._fade:value() > 1 then
        inst._fade:set_local(inst._fade:value() - 1)
        Scorch_OnFadeDirty(inst)
    elseif inst._fade:value() > 0 then
        inst._fade:set_local(0)
        inst.AnimState:OverrideMultColour(0, 0, 0, 0)
    end]]
end

local function scorchfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	inst.entity:SetPristine()

    inst.AnimState:SetBuild("laser_burntground")
    inst.AnimState:SetBank("burntground")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("laser")

	if not TheWorld.ismastersim then
		return inst
	end

--    inst._fade = net_byte(inst.GUID, "laserscorch._fade", "fadedirty")
--    inst._fade:set(SCORCH_RED_FRAMES + SCORCH_DELAY_FRAMES + SCORCH_FADE_FRAMES)
    inst.alpha = 1
    inst:DoPeriodicTask(0, Scorch_OnUpdateFade)
  --  Scorch_OnFadeDirty(inst)

    --if not TheWorld.ismastersim then
    --    inst:ListenForEvent("fadedirty", Scorch_OnFadeDirty)

  --      return inst
--    end

    inst.Transform:SetRotation(math.random() * 360)

    return inst
end

local function FastForwardTrail(inst, pct)
    if inst._task ~= nil then
        inst._task:Cancel()
    end
    local len = inst.AnimState:GetCurrentAnimationLength()
    pct = math.clamp(pct, 0, 1)
    inst.AnimState:SetTime(len * pct)
    inst._task = inst:DoTaskInTime(len * (1 - pct) + 2 * FRAMES, inst.Remove)
end

local function trailfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("laser_smoke_fx")
    inst.AnimState:SetBuild("laser_smoke_fx")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetAddColour(1, 0, 0, 1)
    inst.AnimState:SetMultColour(1, 0, 0, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst._task = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

    inst.FastForward = FastForwardTrail

    return inst
end

local function OnRemoveHit(inst)
    if inst.target ~= nil and inst.target:IsValid() then
        if inst.target.components.colouradder == nil then
            if inst.target.components.freezable ~= nil then
                inst.target.components.freezable:UpdateTint()
            else
                inst.target.AnimState:SetAddColour(0, 0, 0, 1)
            end
        end
        if inst.target.components.bloomer == nil then
            inst.target.AnimState:ClearBloomEffectHandle()
        end
    end
end

local function UpdateHit(inst, target)
    if target:IsValid() then
        local oldflash = inst.flash
        inst.flash = math.max(0, inst.flash - .075)
        if inst.flash > 0 then
            local c = math.min(1, inst.flash)
            if target.components.colouradder ~= nil then
                target.components.colouradder:PushColour(inst, c, 0, 0, 0)
            else
                target.AnimState:SetAddColour(c, 0, 0, 1)
            end
            if inst.flash < .3 and oldflash >= .3 then
                if target.components.bloomer ~= nil then
                    target.components.bloomer:PopBloom(inst)
                else
                    target.AnimState:ClearBloomEffectHandle()
                end
            end
            return
        end
    end
    inst:Remove()
end

local function SetTarget(inst, target)
    if inst.inittask ~= nil then
        inst.inittask:Cancel()
        inst.inittask = nil

        inst.target = target
        inst.OnRemoveEntity = OnRemoveHit

        if target.components.bloomer ~= nil then
            target.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
        else
            target.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
        inst.flash = .8 + math.random() * .4
        inst:DoPeriodicTask(0, UpdateHit, nil, target)
        UpdateHit(inst, target)
    end
end

local function hitfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
    inst.SetTarget = SetTarget
    inst.inittask = inst:DoTaskInTime(0, inst.Remove)

    return inst
end

return Prefab("laser", fn, assets, prefabs),
    Prefab("laserempty", emptyfn, assets, prefabs),
    Prefab("laserscorch", scorchfn, assets_scorch),
    Prefab("lasertrail", trailfn, assets_trail),
    Prefab("laserhit", hitfn)
