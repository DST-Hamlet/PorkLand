local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Combat = require("components/combat")

function Combat:AddDamageModifier(key, mod)
    self.attack_damage_modifiers[key] = mod
end

function Combat:RemoveDamageModifier(key)
    self.attack_damage_modifiers[key] = nil
end

function Combat:GetDamageModifier()
    local mod = 1
    for _, v in pairs(self.attack_damage_modifiers) do
        mod = mod + v
    end
    return mod
end

function Combat:AddPeriodModifier(key, mod)
    self.attack_period_modifiers[key] = { mod = mod, effective = self.min_attack_period * mod }
    self:SetAttackPeriod(self.min_attack_period * (1 + mod))
end

function Combat:RemovePeriodModifier(key)
    if not self.attack_damage_modifiers[key] then
        return
    end
    self:SetAttackPeriod(self.min_attack_period - self.attack_period_modifiers[key].effective)
    self.attack_period_modifiers[key] = nil
end

function Combat:GetIsAttackPoison(attacker)
    local poisonAttack = false
    local poisonGasAttack = false

    if self.inst:HasTag("poisonable") and attacker then
        if (attacker.components.combat and attacker.components.combat.poisonous) or
        ((attacker.components.poisonable and attacker.components.poisonable:IsPoisoned() and attacker.components.poisonable.transfer_poison_on_attack)
        and (attacker.components.combat and not attacker.components.combat:GetWeapon())) then

            poisonAttack = true

            if (attacker.components.combat and attacker.components.combat.poisonous and attacker.components.combat.gasattack) then
                poisonGasAttack = true
            end
        end
    end

    return poisonAttack, poisonGasAttack
end

local _GetAttacked = Combat.GetAttacked
function Combat:GetAttacked(attacker, damage, weapon, stimuli, ...)
    local poisonAttack, poisonGasAttack = self:GetIsAttackPoison(attacker)

    if poisonGasAttack and self.inst.components.poisonable then
        self.inst.components.poisonable:Poison(true)
        return
    end

    local blocked = false

    if damage and (self.inst.components.sailor and self.inst.components.sailor.boat and self.inst.components.sailor.boat.components.boathealth) then
        local boathealth = self.inst.components.sailor.boat.components.boathealth
        if damage > 0 and not boathealth:IsInvincible() then
            boathealth:DoDelta(-damage, "combat", attacker and attacker.prefab or "NIL")
        else
            blocked = true
        end

        if not blocked then
            self.inst:PushEvent("boatattacked", {attacker = attacker, damage = damage, weapon = weapon, stimuli = stimuli, redirected = false})

            if self.onhitfn then
                self.onhitfn(self.inst, attacker, damage)
            end

            if attacker then
                attacker:PushEvent("onhitother", {target = self.inst, damage = damage, stimuli = stimuli, redirected = false})
                if attacker.components.combat and attacker.components.combat.onhitotherfn then
                    attacker.components.combat.onhitotherfn(attacker, self.inst, damage, stimuli)
                end
            end
        else
            self.inst:PushEvent("blocked", {attacker = attacker})
        end

        return not blocked
    end

    local rets = {_GetAttacked(self, attacker, damage, weapon, stimuli, ...)}

    if rets[1] and attacker and poisonAttack and self.inst.components and self.inst.components.poisonable then
        self.inst.components.poisonable:Poison()
    end

    return unpack(rets)
end

local _CalcDamage = Combat.CalcDamage
function Combat:CalcDamage(target, weapon, multiplier, ...)
    local rets = {_CalcDamage(self, target, weapon, multiplier, ...)}
    local bonus = self.damagebonus or 0  -- not affected by multipliers

    local dmg = rets[1]
    dmg = (dmg - bonus) * self:GetDamageModifier() + bonus
    return unpack(rets)
end

local _DoAttack = Combat.DoAttack
function Combat:DoAttack(targ, weapon, projectile, ...)
    if projectile == nil then
        if targ and targ:HasTag("difficult_to_hit") and not self.AOEarc then
            if not targ:CanBeAttack({ attacker = self.inst, weapon = weapon or self:GetWeapon() }) then
                targ:PushEvent("avoidattack", { attacker = self.inst, weapon = weapon or self:GetWeapon() })
                self.inst:PushEvent("onmissother", { target = targ, weapon = weapon or self:GetWeapon() })
                self:ClearAttackTemps()
                return
            end
        end
    else
        if targ and targ:HasTag("difficult_to_hit") and not self.AOEarc then
            if not targ:CanBeHit({ attacker = self.inst, weapon = weapon or self:GetWeapon() }) then
                targ:PushEvent("avoidattack", { attacker = self.inst, weapon = weapon or self:GetWeapon() })
                self.inst:PushEvent("onmissother", { target = targ, weapon = weapon or self:GetWeapon() })
                self:ClearAttackTemps()
                return
            end
        end
    end
    return _DoAttack(self, targ, weapon, projectile, ...)
end

AddComponentPostInit("combat", function(self, inst)
    self.poisonstrength = 1

    self.poisonous = nil
    self.gasattack = nil

    self.attack_damage_modifiers = {} -- % modifiers on self:CalcDamage()
    self.attack_period_modifiers = {} -- % modifiers on self.min_attack_period
end)
