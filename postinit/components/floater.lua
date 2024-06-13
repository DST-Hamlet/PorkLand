local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Floater = require("components/floater")

function Floater:UpdateAnimations(water_anim, land_anim)
    self.wateranim = water_anim or self.wateranim
    self.landanim = land_anim or self.landanim
    self.no_float_fx = true

    if self.showing_effect then
        self:PlayWaterAnim()
    else
        self:PlayLandAnim()
    end
end

function Floater:PlayWaterAnim()
    if self.wateranim ~= nil then
        local anim = self.wateranim
        if type(self.wateranim) == "function" then
            anim = self.wateranim(self.inst)
        end

        if not self.inst.AnimState:IsCurrentAnimation(anim) then
            self.inst.AnimState:PlayAnimation(anim, true)
            self.inst.AnimState:SetTime(math.random())
        end

        self.inst.AnimState:OverrideSymbol("water_ripple", "ripple_build", "water_ripple")
        self.inst.AnimState:OverrideSymbol("water_shadow", "ripple_build", "water_shadow")
    end
end

function Floater:PlayLandAnim()
    if self.landanim ~= nil then
        local anim = self.landanim
        if type(self.landanim) == "function" then
            anim = self.landanim(self.inst)
        end

        if not self.inst.AnimState:IsCurrentAnimation(anim) then
            self.inst.AnimState:PlayAnimation(anim, true)
        end

        self.inst.AnimState:OverrideSymbol("water_ripple", "ripple_build", "water_ripple")
        self.inst.AnimState:OverrideSymbol("water_shadow", "ripple_build", "water_shadow")
    end
end

function Floater:PlaySplashFx()
    if self.splash and (not self.inst.components.inventoryitem or not self.inst.components.inventoryitem:IsHeld()) then
        -- The SW splash effect has a different and iconic sound
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local splash = SpawnPrefab(TheWorld.has_pl_ocean and "splash_water_drop" or "splash")
        splash.Transform:SetPosition(x, y, z)
    end
end

local _ShouldShowEffect = Floater.ShouldShowEffect
function Floater:ShouldShowEffect()
    if not TheWorld:HasTag("porkland") then
        return _ShouldShowEffect(self)
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()

    -- No effect for cloud
    return TheWorld.Map:ReverseIsVisualWaterAtPoint(x, 0, z)
end

-- Other mods use the anim methods (for example skin mods) so we need to wrap them
local _SwitchToFloatAnim = Floater.SwitchToFloatAnim
function Floater:SwitchToFloatAnim(...)
    self:PlayWaterAnim()
    return _SwitchToFloatAnim(self, ...)
end

local _SwitchToDefaultAnim = Floater.SwitchToDefaultAnim
function Floater:SwitchToDefaultAnim(...)
    self:PlayLandAnim()
    return _SwitchToDefaultAnim(self, ...)
end

local _OnLandedServer = Floater.OnLandedServer
function Floater:OnLandedServer(...)
    local _showing_effect = self.showing_effect
    local _splash = self.splash
    self.splash = false

    local rets = {_OnLandedServer(self, ...)}
    if _showing_effect and not self:ShouldShowEffect() then
        self.inst:PushEvent("floater_stopfloating")
        self._is_landed:set(false)
        self.showing_effect = false

        self:SwitchToDefaultAnim()
    end

    self.splash = _splash
    if _showing_effect ~= self.showing_effect then
        if self.splash then
            self:PlaySplashFx()
        end
    end

    return unpack(rets)
end

local _OnLandedClient = Floater.OnLandedClient
function Floater:OnLandedClient(...)
    if not self.no_float_fx then
        return _OnLandedClient(self, ...)
    else
        self.showing_effect = true
    end
end
