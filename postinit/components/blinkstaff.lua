GLOBAL.setfenv(1, GLOBAL)
local BlinkStaff = require("components/blinkstaff")

local function OnBoatBlinked(caster, self, pt, boat)
    if caster.sg == nil then
        caster:Show()
        if caster.components.health ~= nil then
            caster.components.health:SetInvincible(false)
        end
        if caster.DynamicShadow ~= nil then
            caster.DynamicShadow:Enable(true)
        end
    elseif caster.sg.statemem.onstopblinking ~= nil then
        caster.sg.statemem.onstopblinking()
    end
    if pt ~= nil then
        caster.Physics:Teleport(pt:Get())
    end
    if boat ~= nil and boat.components.sailable and boat.components.sailable.sailor == nil then
        caster.components.sailor:Embark(boat)
    end
    if boat.components.sailable then
        boat.components.sailable.isembarking = false
    end
    self:SpawnEffect(caster)
    if self.postsound and self.postsound ~= "" then
        caster.SoundEmitter:PlaySound(self.postsound)
    end
end

function BlinkStaff:BlinkToBoat(boat, caster, ...)
    local pt = boat:GetPosition()

    if (caster.sg ~= nil and caster.sg.currentstate.name ~= "quicktele") then
        return false
    elseif self.blinktask ~= nil then
        self.blinktask:Cancel()
    end
    if caster.components.sailor and caster.components.sailor:IsSailing() then
        caster.components.sailor:Disembark(nil, nil, true)
    end

    self:SpawnEffect(caster)
    if self.presound and self.presound ~= "" then
        caster.SoundEmitter:PlaySound(self.presound)
    end

    if caster.sg == nil then
        caster:Hide()
        if caster.DynamicShadow ~= nil then
            caster.DynamicShadow:Enable(false)
        end
        if caster.components.health ~= nil then
            caster.components.health:SetInvincible(true)
        end
    elseif caster.sg.statemem.onstartblinking ~= nil then
        caster.sg.statemem.onstartblinking()
    end

    if boat.components.sailable then
        boat.components.sailable.isembarking = true
    end

    self.blinktask = caster:DoTaskInTime(.25, OnBoatBlinked, self, pt, boat)

    if self.onblinkfn ~= nil then
        self.onblinkfn(self.inst, pt, caster)
    end

    return true
end

local _Blink = BlinkStaff.Blink
function BlinkStaff:Blink(pt, caster, ...) -- 落点位于非船位置的传送函数
    local blink_success = _Blink(self, pt, caster, ...)
    if blink_success then
        if caster.components.sailor and caster.components.sailor:IsSailing() then
            caster.components.sailor:Disembark(nil, nil, true)
        end
    end
    return blink_success
end

