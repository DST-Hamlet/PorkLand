return Class(function(self, inst)

assert(TheWorld.ismastersim, "GiantGrubSpawner should not exist on client")

local MAX_GRUB_COUNT = 12
local GIANT_GRUB_TIMER_NAME = "GRUB_RESPAWN_TIME"

self.inst = inst

local _world = TheWorld
local _worldsettingstimer = _world.components.worldsettingstimer
local _anthill
local _giant_grubs = {}

local function GetSpawnTime()
    return TUNING.GIANT_GRUB_RESPAWN_TIME * math.random()
end

local function StartRespawnTimer(time)
    _worldsettingstimer:StopTimer(GIANT_GRUB_TIMER_NAME)
    _worldsettingstimer:StartTimer(GIANT_GRUB_TIMER_NAME, time or GetSpawnTime(), false)
end

local function OnGiantGrubSpawned(grub)
    table.insert(_giant_grubs, grub)
    grub:ListenForEvent("onremove", function()
        RemoveByValue(_giant_grubs, grub)
    end)
end

local function SpawnGiantGrub()
    if GetTableSize(_giant_grubs) >= MAX_GRUB_COUNT then
        return
    end

    if not _anthill then
        _anthill = TheSim:FindFirstEntityWithTag("ant_hill_entrance")
        if not _anthill or not _anthill.rooms then
            return
        end
    end

    local random_x, random_y = math.random(1, 5), math.random(1, 5)
    local interiorID = _anthill.rooms[random_x][random_y].id
    local centre = _world.components.interiorspawner:GetInteriorCenter(interiorID)
    local pos = centre:GetPosition()
    pos.x = pos.x + (math.random() * 7) - (7 / 2)
    pos.z = pos.z + (math.random() * 13) - (13 / 2)

    local grub = SpawnPrefab("giantgrub")
    grub.Transform:SetPosition(pos.x, 0, pos.z)
    grub.sg:GoToState("walk")
    OnGiantGrubSpawned(grub)
end

self.inst:DoTaskInTime(0, function()
    if not _anthill then
        _anthill = TheSim:FindFirstEntityWithTag("ant_hill_entrance")
    end
end)

_worldsettingstimer:AddTimer(GIANT_GRUB_TIMER_NAME, TUNING.GIANT_GRUB_RESPAWN_TIME, TUNING.GIANT_GRUB_ENABLED, function()
    SpawnGiantGrub()
    StartRespawnTimer()
end)
StartRespawnTimer()

function self:OnSave()
    local refs = {}
    local data = {
        grubs = {}
    }

    for _, grub in pairs(_giant_grubs) do
        table.insert(data.grubs, grub.GUID)
        table.insert(refs, grub.GUID)
    end

    if _anthill then
        data.anthill = _anthill.GUID
        table.insert(refs, _anthill.GUID)
    end

    return data, refs
end

function self:LoadPostPass(ents, data)
    if not data then
        return
    end
    for i, GUID in ipairs(data.grubs) do
        if ents[GUID] then
            OnGiantGrubSpawned(ents[GUID].entity)
        end
    end
    if ents[data.anthill] then
        _anthill = ents[data.anthill].entity
    end
end

function self:GetDebugString()
    local s = string.format("Next spawn in: %2.2f seconds", _worldsettingstimer:GetTimeLeft(GIANT_GRUB_TIMER_NAME))
    return s
end

end)
