local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Health = require("components/health")

function Health:DoPoisonDamage(amount, doer)
    if not self.invincible and self.vulnerabletopoisondamage and self.poison_damage_scale > 0 then
        if amount > 0 then
            self:DoDelta(-amount * self.poison_damage_scale, false, "poison")
        end
    end
end

AddComponentPostInit("health", function(self)
    self.vulnerabletopoisondamage = true
    self.poison_damage_scale = 1
end)
