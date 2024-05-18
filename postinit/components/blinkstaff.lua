GLOBAL.setfenv(1, GLOBAL)
local BlinkStaff = require("components/blinkstaff")

local function OnBlinked(caster, self, dpt)
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
	local pt = dpt:GetPosition()
	if pt ~= nil and TheWorld.Map:IsOceanTileAtPoint(pt:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pt) then
	    caster.Physics:Teleport(pt:Get())
	end
    self:SpawnEffect(caster)
    if self.postsound and self.postsound ~= "" then
        caster.SoundEmitter:PlaySound(self.postsound)
    end
end

local _Blink = BlinkStaff.Blink
function BlinkStaff:Blink(pt, caster, ...)
    if not caster:IsSailing() then
        return _Blink(self, pt, caster, ...)
    end

    if (caster.sg ~= nil and caster.sg.currentstate.name ~= "quicktele") or
        not TheWorld.Map:IsOceanTileAtPoint(pt:Get()) or
        TheWorld.Map:IsGroundTargetBlocked(pt) then
        return false
    elseif self.blinktask ~= nil then
        self.blinktask:Cancel()
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

    self.blinktask = caster:DoTaskInTime(.25, OnBlinked, self, DynamicPosition(pt))

    if self.onblinkfn ~= nil then
        self.onblinkfn(self.inst, pt, caster)
    end

    return true
end
