GLOBAL.setfenv(1, GLOBAL)

function MakeHackableBlowInWindGust()
end

function MakeAmphibiousCharacterPhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith((TheWorld.has_ocean and COLLISION.GROUND) or COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    return phys
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
