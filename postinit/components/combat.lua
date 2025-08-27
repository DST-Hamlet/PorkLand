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
function Combat:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
    if self.inst:HasTag("difficult_to_hit") then
        if not self.inst:CanBeHit({ attacker = attacker, weapon = weapon or self:GetWeapon() }) then
            self.inst:PushEvent("avoidattack", { attacker = attacker, weapon = weapon or self:GetWeapon() })
            damage, spdamage = 0, nil
        end
    end

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

    local rets = {_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)}

    if rets[1] and attacker and poisonAttack and self.inst.components and self.inst.components.poisonable then
        self.inst.components.poisonable:Poison()
    end

    return unpack(rets)
end

local _CalcDamage = Combat.CalcDamage
function Combat:CalcDamage(target, weapon, multiplier, ...)
    if target:HasTag("alwaysblock") then
        return 0
    end

    if self.overridecalcdamagefn then
        return self.overridecalcdamagefn(self, target, weapon, multiplier, ...)
    end
    return _CalcDamage(self, target, weapon, multiplier, ...)
end

local _DoAttack = Combat.DoAttack
function Combat:DoAttack(targ, weapon, projectile, ...)
    local _targ = targ
    if _targ == nil then
        _targ = self.target
    end
    local _weapon = weapon
    if _weapon == nil then
        _weapon = self:GetWeapon()
    end
    if not (_weapon and ((_weapon.components.projectile ~= nil) or (_weapon.components.complexprojectile ~= nil) or _weapon.components.weapon:CanRangedAttack()))
        or ((weapon ~= nil) and (weapon == projectile)) then -- 近战武器攻击/发射物命中 时进行是否可击中的判定。发射物发射时不进行判定

        if _targ and _targ:HasTag("difficult_to_hit") then
            if not _targ:CanBeHit({ attacker = self.inst, weapon = _weapon or self:GetWeapon() }) then
                _targ:PushEvent("avoidattack", { attacker = self.inst, weapon = _weapon or self:GetWeapon() })
                self.inst:PushEvent("onmissother", { target = _targ, weapon = _weapon or self:GetWeapon() })
                self:ClearAttackTemps()
                return
            end
        end
    end

    local old_damagemultiplier
    if projectile then
        old_damagemultiplier = self.damagemultiplier
        self.damagemultiplier = 1
    end

    local rets = {_DoAttack(self, targ, weapon, projectile, ...)}
    
    if old_damagemultiplier then
        self.damagemultiplier = old_damagemultiplier
    end

    return unpack(rets)
end

local _SuggestTarget = Combat.SuggestTarget
function Combat:SuggestTarget(target)
    if self.suggesttargetfn and not self.suggesttargetfn(self.inst, {target = target}) then
        return false
    end

    if not self.target and target and target:HasTag("sneaky") then
        if self.inst:GetDistanceSqToInst(target) > 6 * 6 then
            return false
        end
    end

    return _SuggestTarget(self, target)
end

AddComponentPostInit("combat", function(self, inst)
    self.poisonstrength = 1

    self.poisonous = nil
    self.gasattack = nil

    self.attack_damage_modifiers = {} -- % modifiers on self:CalcDamage()
    self.attack_period_modifiers = {} -- % modifiers on self.min_attack_period
end)
