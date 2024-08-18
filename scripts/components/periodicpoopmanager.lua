local PeriodicPoopManager = Class(function(self, inst)
    self.inst = inst
    self.poop_count_per_city = {}
    self.max_poop_per_city = { 5, 10 }
    self.poop_data = {}
end)

function PeriodicPoopManager:OnSave()
    local data = {
        poop_data = self.poop_data
    }
    local references = table.getkeys(self.poop_data)
    return data, references
end

function PeriodicPoopManager:LoadPostPass(ents, data)
    for guid, city_id in pairs(data.poop_data) do
        local poop = ents[guid] and ents[guid].entity
        if poop then
            poop.cityID = city_id
            self:OnPoop(city_id, poop)
        end
    end
end

function PeriodicPoopManager:OnPoop(city_id, poop)
    if self.poop_count_per_city[city_id] then
        self.poop_count_per_city[city_id] = self.poop_count_per_city[city_id] + 1
    else
        self.poop_count_per_city[city_id] = 1
    end

    self.poop_data[poop.GUID] = city_id
end

local MUST_TAGS = {"city_pig"}
local CANT_TAGS = {"guard"}
function PeriodicPoopManager:OnPickedUp(city_id, poop, owner)
    self.poop_count_per_city[city_id] = self.poop_count_per_city[city_id] or 0

    self.poop_count_per_city[city_id] = self.poop_count_per_city[city_id] - 1
    self.poop_data[poop.GUID] = nil

    if not (owner and owner:HasTag("player")) then
        return
    end

    local closest_pig = FindEntity(owner, 20, function(inst)
        return inst.components.citypossession and inst.components.citypossession.cityID == city_id
    end, MUST_TAGS, CANT_TAGS)
    if closest_pig then
        closest_pig.poop_tip = owner
    end
end

function PeriodicPoopManager:AllowPoop(city_id)
    if not self.poop_count_per_city[city_id] then
        self.poop_count_per_city[city_id] = 0
    end

    --local result = self.poop_count_per_city[city_id] < 7
    return self.poop_count_per_city[city_id] < self.max_poop_per_city[city_id]
end

return PeriodicPoopManager
