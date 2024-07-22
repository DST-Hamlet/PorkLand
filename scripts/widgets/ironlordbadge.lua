local Badge = require("widgets/badge")

local IronlordBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "livingartifact_meter", owner)

    self.value = TUNING.IRON_LORD_TIME

    owner:ListenForEvent("ironlorddelta", function(_, data)
        self:SetPercent(data.percent, TUNING.IRON_LORD_TIME)
    end, owner)
end)

function IronlordBadge:SetPercent(value, max)
    Badge.SetPercent(self, value, max)
    self.value = value
end

return IronlordBadge
