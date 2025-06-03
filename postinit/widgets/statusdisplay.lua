local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)
local StatusDisplays = require("widgets/statusdisplays")
local BeaverBadge = require("widgets/beaverbadge")

local _HealthDelta = StatusDisplays.HealthDelta
function StatusDisplays:HealthDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _HealthDelta(self, data)
    end
end

local _HungerDelta = StatusDisplays.HungerDelta
function StatusDisplays:HungerDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _HungerDelta(self, data)
    end
end

local _SanityDelta = StatusDisplays.SanityDelta
function StatusDisplays:SanityDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _SanityDelta(self, data)
    end
end

function StatusDisplays:SetWereMode(weremode, nofx)
    if self.isghostmode or self.wereness == nil then
        return
    elseif weremode then
        self.heart:Hide()
        self.stomach:Hide()
        self.brain:Hide()
        self.wereness:Show()
        self.wereness:SetPosition((self.heart:GetPosition() + self.brain:GetPosition() + self.stomach:GetPosition()) / 3)
        if not nofx then
            self.wereness:SpawnNewFX()
        end
    else
        self.heart:Show()
        self.stomach:Show()
        self.brain:Show()
        self.wereness:Hide()
        if not nofx then
            self.wereness:SpawnShatterFX()
        end
    end
end

AddClassPostConstruct("widgets/statusdisplays", function(self)

end)
