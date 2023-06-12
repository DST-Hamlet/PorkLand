local function onclimate(self, climate, _climate)
    if self.inst.player_classified ~= nil then
        self.inst.player_classified._climate:set(climate or CLIMATE_IDS.forest)
    end
    if _climate then
        self.inst:RemoveTag("Climate_"..CLIMATES[_climate])
    end
    if climate then
        self.inst:AddTag("Climate_"..CLIMATES[climate])
    end
end

local function onperiod(self, period)
    if period ~= nil then
        self.inst:StartUpdatingComponent(self)
    else
        self.inst:StopUpdatingComponent(self)
    end
end

local ClimateTracker = Class(function(self, inst)
    self.inst = inst
    self.climate = nil
    self.period = nil
    self.timetonextperiod = 0
    self.climatepos = nil

    inst:DoTaskInTime(0,function() self:GetClimate() end)
end, 
nil, 
{
    climate = onclimate,
    period = onperiod,
})

function ClimateTracker:OnUpdate(dt)
    self.timetonextperiod = self.timetonextperiod - dt
    if self.timetonextperiod <= 0 then

        self:GetClimate()

        self.timetonextperiod = self.period
    end
end

function ClimateTracker:GetClimate(forceupdate)
    local pt = self.inst:GetPosition()
    if forceupdate or not self.climatepos or pt:Dist(self.climatepos) > 2 then
		local oldclimate = self.climate
        if type(self.climateoverride) == "function" or type(self.climateoverride) == "number" then
            self.climate = type(self.climateoverride) == "function" and self.climateoverride(self.inst, pt) or self.climateoverride
        else
			local climate = CalculateClimate(self.inst, nil, self.climate)
			if climate and climate ~= self.climate then
				self.climate = climate
			end
			-- if self.inst:HasTag("player") then print(self.inst, "CLIMATE", climate) end
        end
        self.climatepos = pt
		if self.climate ~= oldclimate then
			self.inst:PushEvent("climatechange", {climate = self.climate, oldclimate = oldclimate})
		end
    end
    return self.climate
end

--convenience function :)
function ClimateTracker:IsInClimate(climate)
    if not self.climate then
        self:GetClimate()
    end
    return CLIMATES[self.climate] == climate
end

--convert climate to string, and then back on save, incase the ordering changes.
function ClimateTracker:OnSave()
	local data = {}
	if self.climate then
		data.climate = CLIMATES[self.climate]
	end
	if self.climatepos then
		data.climatepos = {x = self.climatepos.x, y = self.climatepos.y, z = self.climatepos.z}
	end
	if next(data) then
		return data
	end
end

function ClimateTracker:OnLoad(data, refs)
	if data.climate then
		self.climate = CLIMATE_IDS[data.climate]
	end
	if data.climatepos then
		self.climatepos = Vector3(data.climatepos.x, data.climatepos.y, data.climatepos.z)
	end
    self.inst:PushEvent("climatechange", {climate = self.climate})
end

function ClimateTracker:GetDebugString()
	if self.climate or self.climatepos then
		return (CLIMATES[self.climate or 0] or "<nil>") .." climate, last test pos: ".. tostring(self.climatepos or "<nil>")
	end
end

return ClimateTracker