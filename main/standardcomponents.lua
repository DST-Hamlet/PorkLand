GLOBAL.setfenv(1, GLOBAL)

function MakeBlowInHurricane()
end

function MakeHackableBlowInWindGust()
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

---@param land_bank string
---@param water_bank string
---@param should_silent function
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
            inst.DynamicShadow:Enable(false)
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
end
