GLOBAL.setfenv(1, GLOBAL)

local DEFAULT_DARK_THRESHOLD = 0.05
local DEFAULT_LIGHT_THRESHOLD = 0.1
local DEFAULT_MIN_LIGHT_THRESHOLD = 0.0

local _lightwatcher_to_data = {}

_AddLightWatcher = Entity.AddLightWatcher
function Entity:AddLightWatcher(...)
	local guid = self:GetGUID()
	local inst = Ents[guid]
    if not inst or not inst:IsValid() or inst.LightWatcher then return _AddLightWatcher(self, ...) end

	local lightwatcher = _AddLightWatcher(self, ...)
    _lightwatcher_to_data[lightwatcher] = {
        inst = inst,
        darkthresh = DEFAULT_DARK_THRESHOLD,
        lightthresh = DEFAULT_LIGHT_THRESHOLD,
        minlightthresh = DEFAULT_MIN_LIGHT_THRESHOLD,
    }

    local _lightwatcher = getmetatable(lightwatcher).__index

    local old_GetLightValue = _lightwatcher.GetLightValue
    _lightwatcher.GetLightValue = function(self)
        local inst = _lightwatcher_to_data[self].inst
        if not (inst and inst:IsValid()) then
            return 0
        end
        local x, y, z = inst.Transform:GetWorldPosition()
        return TheSim:GetLightAtPoint(x, y, z)
    end
end
