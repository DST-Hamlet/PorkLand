GLOBAL.setfenv(1, GLOBAL)

---@param min_scale number
---@param max_scale number
function MakeBlowInHurricane(inst, min_scale, max_scale)
    if not TheWorld.ismastersim then
        return
    end

    if not TheWorld:HasTag("porkland") then
        return
    end

    if not inst.components.pl_blowinwind then
        inst:AddComponent("pl_blowinwind")
    end

    inst.components.pl_blowinwind:SetAverageSpeed(TUNING.WILSON_RUN_SPEED - 1)
    inst.components.pl_blowinwind:SetMaxSpeedMultiplier(min_scale or 0.1)
    inst.components.pl_blowinwind:SetMinSpeedMultiplier(max_scale or 1.0)
    inst.components.pl_blowinwind:Start()
end

function RemoveBlowInHurricane(inst)
    inst:RemoveComponent("pl_blowinwind")
end


function MakeHackableBlowInWindGust(inst, wind_speed, destroy_chance)
    inst.onblownpstdone = function(inst)
        if inst.components.hackable and
            inst.components.hackable:CanBeHacked() and
            (
                inst.AnimState:IsCurrentAnimation("blown_pst") or
                inst.AnimState:IsCurrentAnimation("blown_loop") or
                inst.AnimState:IsCurrentAnimation("blown_pre")
            )
        then
            inst.AnimState:PlayAnimation("idle", true)
        end
        inst:RemoveEventCallback("animover", inst.onblownpstdone)
    end

    inst.ongustanimdone = function(inst)
        if inst.components.hackable and inst.components.hackable:CanBeHacked() then
            if inst.components.blowinwindgust:IsGusting() then
                local anim = math.random(1, 2)
                inst.AnimState:PlayAnimation("blown_loop"..anim, false)
            else
                inst:DoTaskInTime(math.random()/2, function(inst)
                    inst:RemoveEventCallback("animover", inst.ongustanimdone)

                    -- This may not be true anymore
                    if inst.components.hackable and inst.components.hackable:CanBeHacked() then
                        inst.AnimState:PlayAnimation("blown_pst", false)
                        -- changed this from a push animation to an animover listen event so that it can be interrupted if necessary, and that a check can be made at the end to know if it should go to idle at that time.
                        --inst.AnimState:PushAnimation("idle", true)
                        inst:ListenForEvent("animover", inst.onblownpstdone)
                    end
                end)
            end
        else
            inst:RemoveEventCallback("animover", inst.ongustanimdone)
        end
    end

    inst.onguststart = function(inst, windspeed)
        inst:DoTaskInTime(math.random()/2, function(inst)
            if inst.components.hackable and inst.components.hackable:CanBeHacked() then
                inst.AnimState:PlayAnimation("blown_pre", false)
                inst:ListenForEvent("animover", inst.ongustanimdone)
            end
        end)
    end

    inst.ongusthack = function(inst)
        if inst.components.hackable and inst.components.hackable:CanBeHacked() then
            inst.components.hackable:MakeEmpty()
            inst.components.lootdropper:SpawnLootPrefab(inst.components.hackable.product)
        end
    end

    inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(wind_speed)
    inst.components.blowinwindgust:SetDestroyChance(destroy_chance)
    inst.components.blowinwindgust:SetGustStartFn(inst.onguststart)
    inst.components.blowinwindgust:SetGustEndFn(inst.onblownpstdone)
    inst.components.blowinwindgust:SetDestroyFn(inst.ongusthack)
    inst.components.blowinwindgust:Start()
end

function MakePickableBlowInWindGust(inst, wind_speed, destroy_chance)
    if not TheWorld.ismastersim then
        return
    end

    inst.onblownpstdone = function(inst)
        if inst.components.pickable and
            inst.components.pickable:CanBePicked() and
            (
                inst.AnimState:IsCurrentAnimation("blown_pst") or
                inst.AnimState:IsCurrentAnimation("blown_loop") or
                inst.AnimState:IsCurrentAnimation("blown_pre")
            )
        then
            inst.AnimState:PlayAnimation("idle", true)
        end
        inst:RemoveEventCallback("animover", inst.onblownpstdone)
    end

    inst.ongustanimdone = function(inst)
        if inst.components.pickable and inst.components.pickable:CanBePicked() then
            if inst.components.blowinwindgust:IsGusting() then
                local anim = math.random(1, 2)
                inst.AnimState:PlayAnimation("blown_loop" .. anim, false)
            else
                inst:DoTaskInTime(math.random() / 2, function(inst)
                    inst:RemoveEventCallback("animover", inst.ongustanimdone)

                    -- This may not be true anymore
                    if inst.components.pickable and inst.components.pickable:CanBePicked() then
                        inst.AnimState:PlayAnimation("blown_pst", false)
                        -- changed this from a push animation to an animover listen event so that it can be interrupted if necessary,
                        -- and that a check can be made at the end to know if it should go to idle at that time.
                        inst:ListenForEvent("animover", inst.onblownpstdone)
                    end
                end)
            end
        else
            inst:RemoveEventCallback("animover", inst.ongustanimdone)
        end
    end

    inst.onguststart = function(inst, windspeed)
        inst:DoTaskInTime(math.random() / 2, function(inst)
            if inst.components.pickable and inst.components.pickable:CanBePicked() then
                inst.AnimState:PlayAnimation("blown_pre", false)
                inst:ListenForEvent("animover", inst.ongustanimdone)
            end
        end)
    end

    inst.ongustpick = function(inst)
        if inst.components.pickable and inst.components.pickable:CanBePicked() then
            inst.components.pickable:Pick(inst)
        end
    end

    inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(wind_speed)
    inst.components.blowinwindgust:SetDestroyChance(destroy_chance)
    inst.components.blowinwindgust:SetGustStartFn(inst.onguststart)
    inst.components.blowinwindgust:SetGustEndFn(inst.onblownpstdone)
    inst.components.blowinwindgust:SetDestroyFn(inst.ongustpick)
    inst.components.blowinwindgust:Start()
end

local function remove_blowinwindgust(inst)
    inst:RemoveComponent("blowinwindgust")
    inst:RemoveEventCallback("onburnt", remove_blowinwindgust)
    inst:RemoveEventCallback("workfinished", remove_blowinwindgust)
end

---@param stages table The stage names in blown animation
--- Note: Call this after defining inst:OnLoad since this overrides it
function MakeTreeBlowInWindGust(inst, stages, threshold, destroy_chance)
    local function PushSway(inst)
        if math.random() > .5 then
            inst.AnimState:PushAnimation("sway1_loop_" .. stages[inst.components.growable.stage], true)
        else
            inst.AnimState:PushAnimation("sway2_loop_" .. stages[inst.components.growable.stage], true)
        end
    end

    local function OnGustAnimDone(inst)
        if inst:HasTag("stump") or inst:HasTag("burnt") then
            inst:RemoveEventCallback("animover", OnGustAnimDone)
            return
        end

        if inst.components.blowinwindgust and inst.components.blowinwindgust:IsGusting() then
            local anim = math.random(1, 2)
            inst.AnimState:PlayAnimation("blown_loop_" .. stages[inst.components.growable.stage] .. tostring(anim), false)
        else
            inst:DoTaskInTime(math.random() / 2, function(inst)
                if not inst:HasTag("stump") and not inst:HasTag("burnt") then
                    inst.AnimState:PlayAnimation("blown_pst_".. stages[inst.components.growable.stage], false)
                    PushSway(inst)
                end
                inst:RemoveEventCallback("animover", OnGustAnimDone)
            end)
        end
    end

    local function OnGustStart(inst, windspeed)
        if inst:HasTag("stump") or inst:HasTag("burnt") then
            return
        end
        inst:DoTaskInTime(math.random() / 2, function(inst)
            if inst:HasTag("stump") or inst:HasTag("burnt") then
                return
            end

            -- TODO: Tree fall sound
            -- if inst.spotemitter == nil then
            --     AddToNearSpotEmitter(inst, "treeherd", "tree_creak_emitter", TUNING.TREE_CREAK_RANGE)
            -- end
            inst.AnimState:PlayAnimation("blown_pre_".. stages[inst.components.growable.stage], false)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wind_tree_creak")
            inst:ListenForEvent("animover", OnGustAnimDone)
        end)
    end

    local function OnGustFall(inst)
        if inst.components.workable then
            inst.components.workable:Destroy(TheWorld)
        end
    end

    inst:AddComponent("blowinwindgust")
    inst.components.blowinwindgust:SetWindSpeedThreshold(threshold)
    inst.components.blowinwindgust:SetDestroyChance(destroy_chance)
    inst.components.blowinwindgust:SetGustStartFn(OnGustStart)
    inst.components.blowinwindgust:SetDestroyFn(OnGustFall)
    inst.components.blowinwindgust:Start()

    local onload = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if onload then onload(inst, data) end
        if data and (data.stump or data.burnt) then
            inst:RemoveComponent("blowinwindgust")
        end
    end

    if inst.components.burnable then
        inst:ListenForEvent("onburnt", remove_blowinwindgust)
    end

    if inst.components.workable then
        inst:ListenForEvent("workfinished", remove_blowinwindgust)
    end
end

function MakePoisonableCharacter(inst, sym, offset, fxstyle, damage_penalty, attack_period_penalty, speed_penalty, hunger_burn, sanity_scale)
    if not inst.components.poisonable then
        inst:AddComponent("poisonable")
    end

    inst.components.poisonable:AddPoisonFX("poisonbubble", offset or Vector3(0, 0, 0), sym)

    if fxstyle == nil or fxstyle == "loop" then
        inst.components.poisonable.show_fx = true
        inst.components.poisonable.loop_fx = true
    elseif fxstyle == "none" then
        inst.components.poisonable.show_fx = false
        inst.components.poisonable.loop_fx = false
    elseif fxstyle == "player" then
        inst.components.poisonable.show_fx = true
        inst.components.poisonable.loop_fx = true
    end

    inst.components.poisonable:SetOnPoisonedFn(function()
        if inst.player_classified then
            inst.player_classified.ispoisoned:set(true)
            inst.ispoisoned = true
        end

        if inst.components.combat then
            inst.components.combat:AddDamageModifier("poison", damage_penalty or TUNING.POISON_DAMAGE_MOD)
            inst.components.combat:AddPeriodModifier("poison", attack_period_penalty or TUNING.POISON_ATTACK_PERIOD_MOD)
        end

        if inst.components.locomotor then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "poison", speed_penalty or TUNING.POISON_SPEED_MOD)
        end

        if inst.components.hunger then
            inst.components.hunger.burnratemodifiers:SetModifier(inst, hunger_burn or TUNING.POISON_HUNGER_DRAIN_MOD, "poison")
        end

        if inst.components.sanity then
            inst.components.sanity.externalmodifiers:SetModifier(inst, -inst.components.poisonable.damage_per_interval * (sanity_scale or TUNING.POISON_SANITY_SCALE), "poison")
        end
    end)

    inst.components.poisonable:SetOnPoisonDoneFn(function()
        if inst.player_classified then
            inst.player_classified.ispoisoned:set(false)
            inst.ispoisoned = false
        end

        if inst.components.combat then
            inst.components.combat:RemoveDamageModifier("poison")
            inst.components.combat:RemovePeriodModifier("poison")
        end

        if inst.components.locomotor then
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "poison")
        end

        if inst.components.hunger then
            inst.components.hunger.burnratemodifiers:RemoveModifier(inst, "poison")
        end

        if inst.components.sanity then
            inst.components.sanity.externalmodifiers:RemoveModifier(inst, "poison")
        end
    end)
end

function MakeAmphibiousCharacterPhysics(inst, mass, radius)
    inst.entity:AddPhysics()
    inst.Physics:SetMass(mass)
    inst.Physics:SetCapsule(radius, 1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:ClearCollidesWith(COLLISION.LAND_OCEAN_LIMITS)
    inst:AddTag("amphibious")
end

function ChangeToAmphibiousCharacterPhysics(inst, mass, rad)
    local phys = inst.Physics
    if mass then
        phys:SetMass(mass)
        phys:SetFriction(0)
    end
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:ClearCollidesWith(COLLISION.LAND_OCEAN_LIMITS)
    if rad then
        phys:SetCapsule(rad, 1)
    end
    if mass then
        phys:SetDamping(5) -- 最后执行摩擦力, 否则会出问题. 例如联机版的鬼魂漂移bug
    end
    return phys
end

function ChangeToJunmpingPhysics(inst, mass, rad)
    local phys = inst.Physics
    if mass then
        phys:SetMass(mass)
        phys:SetFriction(0)
    end
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD)
    if rad then
        phys:SetCapsule(rad, 1)
    end
    if mass then
        phys:SetDamping(5) -- 最后执行摩擦力, 否则会出问题. 例如联机版的鬼魂漂移bug
    end
    return phys
end

---@param land_bank string
---@param water_bank string
---@param should_silent function|nil
---@param on_enter_water function|nil
---@param on_exit_water function|nil
function MakeAmphibious(inst, land_bank, water_bank, should_silent, on_enter_water, on_exit_water)
    should_silent = should_silent or function(inst)
        return (inst.components.freezable and inst.components.freezable:IsFrozen())
            or (inst.components.sleeper and inst.components.sleeper:IsAsleep())
    end

    local function OnEnterWater(inst)
        if on_enter_water then
            on_enter_water(inst)
        end

        if inst.DynamicShadow then
            if not (inst.sg and inst.sg:HasStateTag("falling")) then
                inst.DynamicShadow:Enable(false)
            end
        end

        if inst.components.burnable then
            inst.components.burnable:Extinguish()
        end

        -- Don't exit current state under this condition
        if should_silent(inst) then
            inst.AnimState:SetBank(water_bank)
            return
        end

        -- animation is handled in stategraph event
        inst:PushEvent("switch_to_water")
    end

    local function OnExitWater(inst)
        if on_exit_water then
            on_exit_water(inst)
        end

        if inst.DynamicShadow then
            inst.DynamicShadow:Enable(true)
        end

        if should_silent(inst) then
            inst.AnimState:SetBank(land_bank)
            return
        end

        -- animation is handled in stategraph event
        inst:PushEvent("switch_to_land")
    end

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetEnterWaterFn(OnEnterWater)
    inst.components.amphibiouscreature:SetExitWaterFn(OnExitWater)
    inst.components.amphibiouscreature.RefreshBankFn = function(self)
        local x, y, z = self.inst.Transform:GetWorldPosition()
        if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) then
            self.inst.AnimState:SetBank(water_bank)
        else
            self.inst.AnimState:SetBank(land_bank)
        end
    end
end

function UpdateSailorPathcaps(inst, allowocean)
    if inst:IsSailing() and inst.components.locomotor and not inst.components.amphibiouscreature ~= nil then
        inst.components.locomotor.pathcaps = inst.components.locomotor.pathcaps or {}
        inst.components.locomotor.pathcaps.ignoreLand = allowocean
        inst.components.locomotor.pathcaps.allowocean = allowocean
    end
end

local _MakeInventoryPhysics = MakeInventoryPhysics
function MakeInventoryPhysics(inst, mass, rad, ...)
    local physics = _MakeInventoryPhysics(inst, mass, rad, ...)
    if TheWorld:HasTag("porkland") then
        physics:ClearCollidesWith(COLLISION.LIMITS)
        physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    return physics
end

local _ChangeToInventoryItemPhysics = ChangeToInventoryItemPhysics
function ChangeToInventoryItemPhysics(inst, mass, rad, ...)
    local physics = _ChangeToInventoryItemPhysics(inst, mass, rad, ...)
    if TheWorld:HasTag("porkland") then
        physics:ClearCollidesWith(COLLISION.LIMITS)
        physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    return physics
end

function MakeThrowablePhysics(inst, mass, rad, ...)
    local physics = MakeInventoryPhysics(inst, mass, rad, ...)
    inst.Physics:SetFriction(100)
    inst.Physics:SetRestitution(0)
    inst.Physics:SetDontRemoveOnSleep(true)

    return physics
end

function MakeCharacterThrowablePhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetFriction(100)
    phys:SetRestitution(0)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.SMALLOBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
    phys:SetCapsule(rad, 1)
    if TheWorld:HasTag("porkland") then
        phys:ClearCollidesWith(COLLISION.LIMITS)
        phys:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    return phys
end

local _MakeProjectilePhysics = MakeProjectilePhysics
function MakeProjectilePhysics(inst, mass, rad, ...)
    local physics = _MakeProjectilePhysics(inst, mass, rad, ...)
    if TheWorld:HasTag("porkland") then
        physics:ClearCollidesWith(COLLISION.LIMITS)
        physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    return physics
end

function ChangeToFlyingCharacterPhysics(inst, mass, rad)
    local phys = inst.Physics
    if mass then
        phys:SetMass(mass)
        phys:SetFriction(0)
    end
    phys:SetCollisionGroup(COLLISION.FLYERS)
    phys:ClearCollisionMask()
    phys:CollidesWith((TheWorld:CanFlyingCrossBarriers() and COLLISION.GROUND) or COLLISION.WORLD)
    phys:CollidesWith(COLLISION.FLYERS)
    if rad then
        phys:SetCapsule(rad, 1)
    end
    if mass then
        phys:SetDamping(5) -- 最后执行摩擦力, 否则会出问题. 例如联机版的鬼魂漂移bug
    end
    return phys
end

local _ChangeToCharacterPhysics = ChangeToCharacterPhysics
function ChangeToCharacterPhysics(inst, mass, rad, ...)
    local physics = _ChangeToCharacterPhysics(inst, mass, rad, ...)
    if mass then
        physics:SetDamping(5) -- 最后执行摩擦力, 否则会出问题. 例如联机版的鬼魂漂移bug
    end
    return physics
end

local _MakeFlyingCharacterPhysics = MakeFlyingCharacterPhysics
function MakeFlyingCharacterPhysics(inst, mass, rad, ...)
    local physics = _MakeFlyingCharacterPhysics(inst, mass, rad, ...)
    inst.OnLandPhysics = function(inst)
        local newmass = inst.Physics:GetMass()
        local newrad = inst.Physics:GetRadius()
        ChangeToCharacterPhysics(inst, newmass, newrad)
    end
    inst.OnRaisePhysics = function(inst)
        local newmass = inst.Physics:GetMass()
        local newrad = inst.Physics:GetRadius()
        ChangeToFlyingCharacterPhysics(inst, newmass, newrad)
    end
    return physics
end

local _MakeGhostPhysics = MakeGhostPhysics
function MakeGhostPhysics(inst, ...)
    _MakeGhostPhysics(inst, ...)
    local physics = inst.Physics
    if TheWorld:HasTag("porkland") then
        physics:ClearCollidesWith(COLLISION.LIMITS)
    end
    return physics
end

local _RemovePhysicsColliders = RemovePhysicsColliders
function RemovePhysicsColliders(inst, ...)
    _RemovePhysicsColliders(inst, ...)
    local physics = inst.Physics
    if TheWorld:HasTag("porkland") and physics:GetMass() > 0 then
        physics:ClearCollidesWith(COLLISION.LIMITS)
        physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    return physics
end

function MakeHauntableDoor(inst)
    if not inst.components.door then
        print("Warning: Trying to call MakeHauntableDoor without door component")
        return
    end

    if not inst.components.hauntable then
        inst:AddComponent("hauntable")
    end
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, player)
        inst:PushEvent("open")
    end)
end

function MakeHauntableVineDoor(inst)
    if not inst.components.hackable and not inst.components.vineable then
        print("Warning: Trying to call MakeHauntableVineDoor without hackable or vineable component")
        return
    end

    if not inst.components.hauntable then
        inst:AddComponent("hauntable")
    end
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, player)
        if math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
            if inst.components.vineable and inst.components.vineable.vines and
                inst.components.vineable.vines.components.hackable and inst.components.vineable.vines.stage > 0 then
                    inst.components.vineable.vines.components.hackable:Hack(player, 1)
            elseif inst.components.hackable and inst.stage > 0 then -- 内部门用vineable, 外部门用hackable...需要代码清理
                inst.components.hackable:Hack(player, 1)
            end
        end
        return false
    end)
end

local function build_rectangle_collision_mesh(rad, height, width)
    local points = {
        Vector3(-width / 2, 0, -rad / 2),
        Vector3(width / 2, 0, -rad / 2),
        Vector3(width / 2, 0, rad / 2),
        Vector3(-width / 2, 0, rad / 2),
    }
    local triangles = {}
    local y0 = 0
    local y1 = height
    for i = 1, 4 do
        local p1 = points[i]
        local p2 = points[i == 4 and 1 or i + 1]

        table.insert(triangles, p1.x)
        table.insert(triangles, y0)
        table.insert(triangles, p1.z)

        table.insert(triangles, p1.x)
        table.insert(triangles, y1)
        table.insert(triangles, p1.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y0)
        table.insert(triangles, p2.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y0)
        table.insert(triangles, p2.z)

        table.insert(triangles, p1.x)
        table.insert(triangles, y1)
        table.insert(triangles, p1.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y1)
        table.insert(triangles, p2.z)
    end

    return triangles
end

function MakeInteriorPhysics(inst, rad, height, width)
    height = height or 20

    inst:AddTag("blocker")
    inst.Physics = inst.Physics or inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetTriangleMesh(build_rectangle_collision_mesh(rad, height, width or rad))
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
end

function MakeInteriorWallPhysics(inst, rad, height, width)
    height = height or 20

    inst:AddTag("blocker")
    inst.Physics = inst.Physics or inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetTriangleMesh(build_rectangle_collision_mesh(rad, height, width or rad))
    inst.Physics:SetCollisionGroup(COLLISION.GROUND)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.FLYERS)
end

--- Compatible with Don't Starve's MakeInventoryFloatable
function PorkLandMakeInventoryFloatable(inst, water_anim, land_anim)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations(water_anim or "idle_water", land_anim or "idle")
end
