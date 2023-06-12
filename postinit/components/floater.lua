local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local Floater = require("components/floater")

-- TODO: a lot of this is pretty messy maybe it should be redone

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

function Floater:PlayThrowAnim()
    if self.showing_effect then
        self:PlayWaterAnim()
    else
        self:PlayLandAnim()
    end

    self.inst.AnimState:ClearOverrideSymbol("water_ripple")
    self.inst.AnimState:ClearOverrideSymbol("water_shadow")
end

function Floater:PlaySplashFx(x, y, z, tile)
    if self.splash and (not self.inst.components.inventoryitem or not self.inst.components.inventoryitem:IsHeld()) then
        local _world = TheWorld
        local splash
        if _world.has_ia_ocean  then
            splash = SpawnPrefab("splash_water_float") -- Has a custom sound
        else
            splash = SpawnPrefab("splash")
        end
        splash.Transform:SetPosition(x, y, z)
    end
end

--just override this blasted thing -Half
--there are so many changes its better to simply overite it, plus this way it only checks the tile once and the events are pushed after the values are set properly
function Floater:OnLandedServer()
    local shouldfloat = self:ShouldShowEffect()
    if not self.showing_effect and shouldfloat then
        -- If something lands in a place where the water effect should be shown, and it has an inventory component,
        -- update the inventory component to represent the associated wetness.
        -- Don't apply the wetness to something held by someone, though.
        if self.inst.components.inventoryitem ~= nil and not self.inst.components.inventoryitem:IsHeld() and not self.inst:HasTag("likewateroffducksback") then
            self.inst.components.inventoryitem:AddMoisture(TUNING.OCEAN_WETNESS)
        end

        local x, y, z = self.inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        self:PlaySplashFx(x, y, z, tile)

        self._is_landed:set(true)
        self.showing_effect = true
        self.inst:PushEvent("floater_startfloating") --moved to after showing_effect and _is_landed so our functions have the correct information (this caused issues with obsidian tools updating anims onlanding)
        self:SwitchToFloatAnim()
    elseif self.showing_effect and not shouldfloat then --this inbred monstrosity didint support items going from water to land....

        local x, y, z = self.inst.Transform:GetWorldPosition()
        --TODO find nearby water and do a splash based on type
        --local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        self:PlaySplashFx(x, y, z)

        self._is_landed:set(false)
        self.showing_effect = false
        self.inst:PushEvent("floater_stopfloating") --moved to after showing_effect and _is_landed so our functions have the correct information

        self:SwitchToDefaultAnim()
    end
end
--TODO QUite Advanced stuff
-- local _ShouldShowEffect = Floater.ShouldShowEffect
-- function Floater:ShouldShowEffect(...)
-- 	-- if not floating dont start floating on impassable tiles (lava)
--     local _map = TheWorld.Map
--     if not self.showing_effect then
--         local pos_x, pos_y, pos_z = self.inst.Transform:GetWorldPosition()
--         local tile = _map:GetTileAtPoint(pos_x, pos_y, pos_z)
--         if TileGroupManager:IsImpassableTile(tile) then
--             return false
--         end
--     end

--     return _map:RunWithoutIACorners(_ShouldShowEffect, self, ...)
-- end

local _OnLandedClient = Floater.OnLandedClient
function Floater:OnLandedClient(...)
	if not self.no_float_fx then
		return _OnLandedClient(self, ...)
    else
        self.showing_effect = true
	end
end

--The floater component is incredibly dumb. -M
local _IsFloating = Floater.IsFloating
function Floater:IsFloating(...)
	return _IsFloating(self, ...) and not (self.inst.replica.inventoryitem and self.inst.replica.inventoryitem:IsHeld())
end


----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------
