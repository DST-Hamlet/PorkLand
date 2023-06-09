local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Floater = require("components/floater")

function Floater:UpdateAnimations(water_anim, land_anim)
	self.wateranim = water_anim or self.wateranim
	self.landanim = land_anim or self.landanim

	if self.showing_effect then
		self:PlayWaterAnim()
	else
		self:PlayLandAnim()
	end
end

function Floater:PlayLandAnim()
    local land_anim = self.landanim

    if land_anim and not self.inst.AnimState:IsCurrentAnimation(land_anim) then
        self.inst.AnimState:PlayAnimation(land_anim, true)
	end

    self.inst.AnimState:SetLayer(LAYER_WORLD)
    self.inst.AnimState:SetSortOrder(0)
    self.inst.AnimState:OverrideSymbol("water_ripple", "ripple_build", "water_ripple")
    self.inst.AnimState:OverrideSymbol("water_shadow", "ripple_build", "water_shadow")
end

function Floater:PlayWaterAnim()
    local water_anim = self.wateranim

    if water_anim and not self.inst.AnimState:IsCurrentAnimation(water_anim) then
        self.inst.AnimState:PlayAnimation(water_anim, true)
        self.inst.AnimState:SetTime(math.random())
    end

    self.inst.AnimState:SetLayer(LAYER_BACKGROUND)
    self.inst.AnimState:SetSortOrder(3)
    self.inst.AnimState:OverrideSymbol("water_ripple", "ripple_build", "water_ripple")
    self.inst.AnimState:OverrideSymbol("water_shadow", "ripple_build", "water_shadow")
end

function Floater:PlayThrowAnim()
    if self.inst:IsOnWater(self.inst) then
        self:PlayWaterAnim()
    else
        self:PlayLandAnim()
    end

    self.inst.AnimState:ClearOverrideSymbol("water_ripple")
    self.inst.AnimState:ClearOverrideSymbol("water_shadow")
end

local function OnHitWater(inst)
    if inst.components.floater ~= nil and inst.components.floater.wateranim then
        inst.components.floater:PlayWaterAnim()
    end

    if inst.components.sinkable ~= nil then
		inst.components.sinkable:OnHitWater()
	end
end

local function OnHitLand(inst)
    if inst.components.floater ~= nil and inst.components.floater.landanim then
        inst.components.floater:PlayLandAnim()
    end
end

PLENV.AddComponentPostInit("floater", function(self)
    if TheNet:GetIsMasterSimulation() then
        self.inst:ListenForEvent("floater_startfloating", OnHitWater)
        self.inst:ListenForEvent("floater_stopfloating", OnHitLand)
    end
end)
