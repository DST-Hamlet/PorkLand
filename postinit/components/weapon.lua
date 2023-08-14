GLOBAL.setfenv(1, GLOBAL)

local Weapon = require("components/weapon")

local _OnAttack = Weapon.OnAttack
function Weapon:OnAttack(attacker, target, projectile, ...)
    local _attackwear = self.attackwear
    if target:HasTag("no_durability_loss_on_hit") then
        self.attackwear = 0
    end

    _OnAttack(self, attacker, target, projectile, ...)
    self.attackwear = _attackwear
end
