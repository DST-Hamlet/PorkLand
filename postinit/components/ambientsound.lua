local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function StartWindSound(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/rain/islandwindAMB", "WIND")
end

local function SetWindIntensity(inst, intensity)
    inst.SoundEmitter:SetParameter("WIND", "intensity", intensity)
end

local function StopWindSound(inst)
    inst.SoundEmitter:KillSound("WIND")
end

--[[ TODO: add ambient sounds
AddComponentPostInit("ambientsound", function(self)
    local _playing_wind = false
    local _wind_intensity = 0

    local OnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        OnUpdate(self, dt)

        if TheWorld.net.components.plateauwind:GetWindSpeed() > 0 then
            if _playing_wind then
                StartWindSound(inst)
                _playing_wind = true
            end
            
            if _playing_wind then 
                _wind_intensity = TheWorld.net.components.plateauwind:GetWindSpeed()
                if _wind_intensity > 1 then
                    _wind_intensity = 1
                end
                SetWindIntensity(inst, _wind_intensity)
            end 
        else
            _wind_intensity = 0
            if _playing_wind then
                StopWindSound(inst)
                _playing_wind = false
            end
        end
    end
end)
--]]
