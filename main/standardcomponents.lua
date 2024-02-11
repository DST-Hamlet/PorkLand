GLOBAL.setfenv(1, GLOBAL)

---@param minscale number
---@param maxscale number
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
            inst.components.pickable:MakeEmpty()
            inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product)
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


local stage_lookup_table = {
    "short",
    "normal",
    "tall",
    "old",
}

---NOTE: You MUST call this function after defining OnLoad, OnBurntFn and OnFinishCallback
---@param tree_type string EVERGREEN, DECIDUOUS or JUNGLETREE 
function MakeTreeblowInWindGust(inst, tree_type)
    local function PushSway(inst)
        if math.random() > .5 then
            inst.AnimState:PushAnimation(inst.anims.sway1, true)
        else
            inst.AnimState:PushAnimation(inst.anims.sway2, true)
        end
    end

    local function OnGustAnimDone(inst)
        if inst:HasTag("stump") or inst:HasTag("burnt") then
            inst:RemoveEventCallback("animover", OnGustAnimDone)
            return
        end

        if inst.components.blowinwindgust and inst.components.blowinwindgust:IsGusting() then
            local anim = math.random(1, 2)
            inst.AnimState:PlayAnimation("blown_loop_" .. stage_lookup_table[inst.components.growable.stage] .. tostring(anim), false)
        else
            inst:DoTaskInTime(math.random() / 2, function(inst)
                if not inst:HasTag("stump") and not inst:HasTag("burnt") then
                    inst.AnimState:PlayAnimation("blown_pst_".. stage_lookup_table[inst.components.growable.stage], false)
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
            inst.AnimState:PlayAnimation("blown_pre_".. stage_lookup_table[inst.components.growable.stage], false)
            -- inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wind_tree_creak")
            inst:ListenForEvent("animover", OnGustAnimDone)
        end)
    end

    local function OnGustFall(inst)
        inst.components.workable.onfinish(inst, TheWorld)
    end

    if not inst.components.blowinwindgust then
        inst:AddComponent("blowinwindgust")
    end

    inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING[tree_type .. "_WINDBLOWN_SPEED"])
    inst.components.blowinwindgust:SetDestroyChance(TUNING[tree_type .. "_WINDBLOWN_FALL_CHANCE"])
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

    local onburnt = inst.components.burnable.onburnt
    inst.components.burnable:SetOnBurntFn(function(inst)
        if onburnt then onburnt(inst) end
        inst:RemoveComponent("blowinwindgust")
    end)

    local onfinish = inst.components.workable.onfinish
    inst.components.workable:SetOnFinishCallback(function(inst, chopper)
        if onfinish then onfinish(inst, chopper) end
        inst:RemoveComponent("blowinwindgust")
    end)
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
        inst.components.poisonable.loop_fx = false
    end

    inst.components.poisonable:SetOnPoisonedFn(function()
        if inst.player_classified then
            inst.player_classified.ispoisoned:set(true)
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

local _MakeInventoryPhysics = MakeInventoryPhysics
function MakeInventoryPhysics(inst, mass, rad)
    local physics = _MakeInventoryPhysics(inst, mass, rad)
    if TheWorld:HasTag("porkland") then
        physics:ClearCollidesWith(COLLISION.LIMITS)
        physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
    end
    return physics
end
