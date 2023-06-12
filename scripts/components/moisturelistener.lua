--Updated by "inventorymoisture" on the world.
--Updated in batches to avoid slowdown due to the amount of inventory items.
local updatePeriod = 5
local MoistureListener = Class(function(self, inst)
	self.inst = inst
	self.owner = nil

	self.moisture = 0

	self.wet = false

	self.dryingSpeed = -1
	self.dryingResistance = 1

	self.wetnessSpeed = 0.5
	self.wetnessResistance = 1

	self.lastUpdate = GetTime() or 0

	self.wetnessThreshold = TUNING.MOISTURE_WET_THRESHOLD
	self.drynessThreshold = TUNING.MOISTURE_DRY_THRESHOLD

	--self.inst:DoTaskInTime(0, function() TheWorld.components.inventorymoisture:TrackItem(self.inst) end)
end)

function MoistureListener:OnSave()
	local data = {}
	data.moisture = self.moisture
	return data
end

function MoistureListener:OnLoad(data)
	if data then
		self.moisture = data.moisture
	end
end

function MoistureListener:GetDebugString()
	return string.format("Current Moisture: %2.2f, Target Moisture: %2.2f", self.moisture, self:GetTargetMoisture() or 0)
end

function MoistureListener:OnUpdate()
	self:UpdateMoisture(GetTime() - self.lastUpdate)
    print("Update")
end

function MoistureListener:UpdateMoisture(dt)
    print("Update")
	--Do these events really need to be called every time this updates even if the item is already wet/dry?
	if self.components.moisture:GetMoisture() >= self.wetnessThreshold and not self.wet then
		self.wet = true
        self.inst:PushEvent("itemwet")
	elseif self.components.moisture:GetMoisture() < self.drynessThreshold and self.wet then
		self.wet = false
        self.inst:PushEvent("itemdry")
	end

	if self.components.moisture:GetMoisture() > 0 and not self.moist then
		self.moist = true
		self.inst:PushEvent("ismoist")
	elseif self.components.moisture:GetMoisture() <= 0 and self.moist then
		self.moist = false
		self.inst:PushEvent("isnotmoist")
	end

	self.lastUpdate = GetTime()
end


return MoistureListener
