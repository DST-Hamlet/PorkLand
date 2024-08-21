local valid_tiles = {
    [WORLD_TILES.DEEPRAINFOREST] = true,
    [WORLD_TILES.GASJUNGLE] = true,
    [WORLD_TILES.RAINFOREST] = true,
    [WORLD_TILES.PLAINS] = true,
    [WORLD_TILES.PAINTED] = true,
    -- [WORLD_TILES.BATTLEGROUND] = true,
    [WORLD_TILES.DIRT] = true,
}

local function TestLocation(inst, pt)
    local tile = TheWorld.Map:GetTileAtPoint(pt.x , pt.y, pt.z)

    if not valid_tiles[tile] then
        return false
    end

    if not IsSurroundedByLand(pt.x, pt.y, pt.z, 3) then
        return false
    end

    local result = true
    local brambleblocked = false

    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 1, {"blocker"})
    for _, ent in pairs(ents) do
        if ent:HasTag("bramble") then
            brambleblocked = true
            break
        end
    end

    if next(ents) then
        result = false
    end

    return result, brambleblocked
end

local function SpawnSpike(inst, pt, rotation)
    local new_spike = SpawnPrefab("bramblespike")
    new_spike.Transform:SetPosition(pt.x, pt.y, pt.z)
    new_spike.Transform:SetRotation(rotation)

    inst.components.bramblechain.child = new_spike
    new_spike.components.bramblechain.parent = inst

    new_spike.core = inst.core
    new_spike.coredistance = inst.coredistance + 1
    inst.core.sustainable_hedges = inst.core.sustainable_hedges -1

    return new_spike
end

local BrambleChain = Class(function(self, inst)
    self.inst = inst

    self.parent = nil
    self.child = nil

    self.destroy_count = 0 -- number of children destroyed on each side
end)

function BrambleChain:SpawnChain(angle)
    local dist = 1.5
    local deflection = 0.6

    local pt = self.inst:GetPosition()
    pt.x = pt.x + dist * math.cos(angle)
    pt.z = pt.z + dist * math.sin(angle)

    local deviation = 0
    local new_spike = nil
    local flip = true

    while deviation < PI/1.5 and not new_spike do
        local no_blocker, bramble_blocked = TestLocation(self.inst, pt)
        if no_blocker then
            local rotation = angle +  deflection - (math.random() * deflection * 2)
            new_spike = SpawnSpike(self.inst, pt, rotation)
        elseif bramble_blocked then
            -- if bramble blocked.. end.
            deviation = PI/1.5
        else
            deviation = deviation * -1
            if flip then
                flip = false
                if deviation < 0 then
                    deviation = deviation - PI/10
                else
                    deviation = deviation + PI/10
                end
            else
                flip = true
            end

            pt = self.inst:GetPosition()
            angle = self.inst.Transform:GetRotation() + deviation
            pt.x = pt.x + dist * math.cos(angle)
            pt.z = pt.z + dist * math.sin(angle)
        end
    end
end

function BrambleChain:Destroy(count)
    if math.random() < 0.4 then
        count = count -1
    end

    self.natural_decay = true

    if self.destroy_count < count then -- destroy_count is the number of brambles to kill on either side
        self.destroy_count = count
    end

    if self.destroy_count > 0 then
        self.inst:DoTaskInTime(0.2, function()
            self.natrual_decay = true
            self.inst.components.health:Kill()
        end)
    end
end

function BrambleChain:OnDeath()
    if not self.natural_decay then
        self.destroy_count = 3-- sets a min of 3. But can go much further due to the 30% chance to recude the rot number.
    end

    if self.core and self.core:IsValid() then
        self.core.sustainable_hedges = self.core.sustainable_hedges + 1
    end

    if self.child and self.child:IsValid() then
        self.child.components.bramblechain:Destroy(self.destroy_count)
    end

    if self.parent and self.parent:IsValid() then
        self.parent.components.bramblechain:Destroy(self.destroy_count)
    end
end

function BrambleChain:OnSave()
    local data = {}
    local refs = {}

    if self.core and self.core:IsValid() then
        data.core = self.core.GUID
        refs.core = self.core.GUID
    end

    if self.child and self.child:IsValid() then
        data.child = self.child.GUID
        refs.child = self.child.GUID
    end

    if self.parent and self.parent:IsValid() then
        data.parent = self.parent.GUID
        refs.parent = self.parent.GUID
    end

    if self.natural_decay then
        data.natural_decay = self.natural_decay
    end

    if self.destroy_count then
        data.destroy_count = self.destroy_count
    end

    return data, refs
end

function BrambleChain:LoadPostPass(ents, data)
    if not data then
        return
    end

    if data.core and ents[data.core] then
        self.core = ents[data.core].entity
    end

    if data.child and ents[data.child] then
        self.child = ents[data.child].entity
    end

    if data.parent and ents[data.parent] then
        self.parent = ents[data.parent].entity
    end

    if data.natural_decay then
        self.natural_decay = data.natural_decay
    end

    if data.destroy_count then
        self.destroy_count = data.destroy_count
    end
end

return BrambleChain
