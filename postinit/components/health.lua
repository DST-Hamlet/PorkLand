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

function Health:SetBaseHealth(amount) -- 每个角色都需要这个
    self.basehealth = amount
end

local _SetMaxHealth = Health.SetMaxHealth
function Health:SetMaxHealth(amount, ...)
    if self.basehealth == nil and self.inst:HasTag("player") then -- basehealth是用于体型缩放机制的变量，玩家默认添加
        self.basehealth = amount
    end
    return _SetMaxHealth(self, amount, ...)
end

AddComponentPostInit("health", function(self)
    self.vulnerabletopoisondamage = true
    self.poison_damage_scale = 1
end)
