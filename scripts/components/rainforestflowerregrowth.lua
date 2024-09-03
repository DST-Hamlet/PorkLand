--------------------------------------------------------------------------
--[[ RainforestFlowerRegrowth class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "RainforestFlowerRegrowth should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local UPDATE_PERIOD = 10 -- seconds
local NUM_POINTS_PER_SITE = 1
local COUNTER_REQUIREMENT = 5
local FLOWER_DENSITY = 50 -- 1 per unit distance
local FIND_FLOWER_RADIUS = 50
local FIND_FLOWER_MUST_TAGS = {"flower_rainforest"}
local VALID_FLOWER_TILES = {
    [WORLD_TILES.DEEPRAINFOREST] = true,
    [WORLD_TILES.DEEPRAINFOREST_NOCANOPY] = true,
    [WORLD_TILES.RAINFOREST] = true,
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

local _world = TheWorld
local _map = _world.Map
local _task
local _counters = {}

local function is_point_suitable(x, z)
    local tile = _map:GetTileAtPoint(x, 0, z)
    if not VALID_FLOWER_TILES[tile] then
        return false
    end

    if not _map:CanPlantAtPoint(x, 0, z) then
        return false
    end

    local flowers = TheSim:FindEntities(x, 0, z, FIND_FLOWER_RADIUS, FIND_FLOWER_MUST_TAGS)
    if #flowers >= FLOWER_DENSITY then
        return false
    end

    return true
end

local function OnUpdate()
    for index, area in pairs(_world.topology.nodes) do
        local points_x, points_y = _map:GetRandomPointsForSite(area.x, area.y, area.poly, NUM_POINTS_PER_SITE)
        if #points_x == 1 and #points_y == 1 then
            local x = points_x[1]
			local z = points_y[1]

            local suitable = is_point_suitable(x, z)
            if suitable then
                if not _counters[index] then
                    _counters[index] = 1
                else
                    _counters[index] = _counters[index] + 1
                end
                if _counters[index] >= COUNTER_REQUIREMENT then
                    local flower = SpawnPrefab("flower_rainforest")
                    flower.Transform:SetPosition(x, 0, z) -- could use some anim/player vision check
                    _counters[index] = 0
                end
            end
        end
    end
end

local function OnIsRaining(_src, israining)
    if israining then
        _task = self.inst:DoPeriodicTask(UPDATE_PERIOD, OnUpdate)
    elseif _task then
        _task:Cancel()
        _task = nil
    end
end

inst:WatchWorldState("israining", OnIsRaining)

function self:OnPostInit()
    OnIsRaining(nil, _world.state.israining)
end

function self:OnSave()
    local data = {}
    data.counters = _counters
    return data
end

function self:OnLoad(data)
    if data and data.counters then
        _counters = data.counters
    end
end

end)