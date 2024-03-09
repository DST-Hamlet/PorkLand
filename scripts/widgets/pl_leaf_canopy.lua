local Widget = require("widgets/widget")
local UIAnim = require("widgets/uianim")

local CANOPY_TILES = {
    [WORLD_TILES.GASJUNGLE] = true,
	[WORLD_TILES.DEEPRAINFOREST] = true,
	[WORLD_TILES.PIGRUINS] = true,
}

local LeavesOver = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "LeavesOver")

    self:SetClickable(false)

    self.leavesTop = self:AddChild(UIAnim())
    self.leavesTop:SetClickable(false)
    self.leavesTop:SetHAnchor(ANCHOR_MIDDLE)
    self.leavesTop:SetVAnchor(ANCHOR_TOP)
    self.leavesTop:GetAnimState():SetBank("leaves_canopy2")
    self.leavesTop:GetAnimState():SetBuild("leaves_canopy2")
    self.leavesTop:GetAnimState():PlayAnimation("idle", true)
    self.leavesTop:GetAnimState():SetMultColour(1, 1, 1, 1)
    self.leavesTop:GetAnimState():AnimateWhilePaused(false)
    self.leavesTop:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)
	-- self.leavesTop:GetAnimState():SetEffectParams( 0.784, 0.784, 0.784, 1)    
	self.leavesTop:Hide()
end)

function LeavesOver:SetLeavesTopColorMult(r, g, b)
    self.leavestopmultiplytarget = {r = r, g = g, b = b}
end

function LeavesOver:OnUpdate(dt)
	local wasup = self.leavestop_intensity and self.leavestop_intensity > 0 or false

	if not self.leavestopmultiplytarget then
		self.leavestopmultiplytarget = {r = 1, g = 1, b = 1}
		self.leavestopmultiplycurrent = {r = 1, g = 1, b = 1}
	end

    if TheWorld.state.isdusk then
        self:SetLeavesTopColorMult(0.6, 0.6, 0.6)
    elseif TheWorld.state.isnight then
        self:SetLeavesTopColorMult(0.1, 0.1, 0.1)
    else
        self:SetLeavesTopColorMult(1, 1, 1)
    end

	if not self.leavesTop then
        return
    end

    if self.leavestopmultiplycurrent ~= self.leavestopmultiplytarget then
        if self.leavestopmultiplycurrent.r > self.leavestopmultiplytarget.r then
            self.leavestopmultiplycurrent.r = math.max(self.leavestopmultiplytarget.r, self.leavestopmultiplycurrent.r - dt)
            self.leavestopmultiplycurrent.g = math.max(self.leavestopmultiplytarget.g, self.leavestopmultiplycurrent.g - dt)
            self.leavestopmultiplycurrent.b = math.max(self.leavestopmultiplytarget.b, self.leavestopmultiplycurrent.b - dt)
        else
            self.leavestopmultiplycurrent.r = math.min(self.leavestopmultiplytarget.r, self.leavestopmultiplycurrent.r + dt)
            self.leavestopmultiplycurrent.g = math.min(self.leavestopmultiplytarget.g, self.leavestopmultiplycurrent.g + dt)
            self.leavestopmultiplycurrent.b = math.min(self.leavestopmultiplytarget.b, self.leavestopmultiplycurrent.b + dt)
        end
        self.leavesTop:GetAnimState():SetMultColour(self.leavestopmultiplycurrent.r, self.leavestopmultiplycurrent.g, self.leavestopmultiplycurrent.b, 1)
    end

    if not self.leavestop_intensity then
        self.leavestop_intensity = 0
    end

    self.under_leaves = false

    local x, y ,z = self.owner.Transform:GetWorldPosition()
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    if CANOPY_TILES[tile] then
        self.under_leaves = true
    end

    if self.under_leaves then
        self.leavestop_intensity = math.min(1, self.leavestop_intensity + (1/30))
    else
        self.leavestop_intensity = math.max(0, self.leavestop_intensity - (1/30))
    end

    if self.leavestop_intensity == 0 then
        if wasup then
            self.owner:PushEvent("canopyout")
        end

        self.leavesTop:Hide()
    else
        self.leavesTop:Show()

        if self.leavestop_intensity == 1 then
            if not self.leavesfullyin then
                self.leavesTop:GetAnimState():PlayAnimation("idle", true)
                self.leavesfullyin = true
                self.owner:PushEvent("canopyin")
            else
                if self.owner.sg:HasStateTag("moving") then
                    if not self.leavesmoving then
                        self.leavesmoving = true
                        self.leavesTop:GetAnimState():PlayAnimation("run_pre")
                        self.leavesTop:GetAnimState():PushAnimation("run_loop", true)
                    end
                else
                    if self.leavesmoving then
                        self.leavesmoving = nil
                        self.leavesTop:GetAnimState():PlayAnimation("run_pst")
                        self.leavesTop:GetAnimState():PushAnimation("idle", true)
                        self.leaves_olddir = nil
                    end
                end
            end
        else
            self.leavesfullyin = nil
            self.leavesmoving = nil
            self.leavesTop:GetAnimState():SetPercent("zoom_in", self.leavestop_intensity)
        end
    end
end

return LeavesOver
