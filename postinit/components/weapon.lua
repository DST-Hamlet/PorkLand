GLOBAL.setfenv(1, GLOBAL)

local Weapon = require("components/weapon")

local _OnAttack = Weapon.OnAttack
function Weapon:OnAttack(attacker, target, projectile)
    if not projectile and target:HasTag("no_durability_loss_on_hit") then -- gnat
        return
    end

    _OnAttack(self, attacker, target, projectile)
end
