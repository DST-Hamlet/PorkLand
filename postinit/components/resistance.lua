GLOBAL.setfenv(1, GLOBAL)

local Resistance = require("components/resistance")

-- not_tags are the mob tags this wouldn't protect you from
function Resistance:SetNoTags(tags)
    self.not_tags = tags
end

local _HasResistance = Resistance.HasResistance
function Resistance:HasResistance(attacker, weapon)
    if self.not_tags then
        for _, tag in pairs(self.not_tags) do
            if attacker and attacker:HasTag(tag) then
                return false
            end
        end
    end

    if self.alltype_tags then
        return true
    end
    return _HasResistance(self, attacker, weapon)
end
