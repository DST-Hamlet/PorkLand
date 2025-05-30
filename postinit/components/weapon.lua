GLOBAL.setfenv(1, GLOBAL)

local Weapon = require("components/weapon")

local _OnAttack = Weapon.OnAttack
function Weapon:OnAttack(attacker, target, projectile, ...)
    if projectile and projectile ~= self.inst then -- 远程武器固定掉耐久，不受efficientuser影响
        if self.onattack ~= nil then
            self.onattack(self.inst, attacker, target)
        end
    
        if self.inst.components.finiteuses ~= nil and not self.inst.components.finiteuses:IgnoresCombatDurabilityLoss()
            and not (projectile ~= nil and projectile.components.projectile ~= nil and projectile.components.projectile:IsBounced())
            then
            local uses = (self.attackwear or 1) * self.attackwearmultipliers:Get()
    
            self.inst.components.finiteuses:Use(uses)
        end
    else
        return _OnAttack(self, attacker, target, projectile, ...)
    end
end
