
--------------------------------------------------------------------------
--[[ BrambleManager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "BrambleManager should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local VALID_TILES = {
    [WORLD_TILES.DEEPRAINFOREST] = true,
    [WORLD_TILES.GASJUNGLE] = true,
    [WORLD_TILES.RAINFOREST] = true,
    [WORLD_TILES.PLAINS] = true,
    [WORLD_TILES.PAINTED] = true,
    [WORLD_TILES.DIRT] = true,
}

local BRAMBLE_MIN_DISTANCE_SQ = 80 * 80

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _bramble_spots = {}
local _bramble_to_spawn = 7
local _bramble_spawned = false
local _disabled = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function SpawnBrambles()
    if not next(_bramble_spots) then
        return
    end

    local selected = {}
    local options = deepcopy(_bramble_spots)
    local num_options = #options -- options will have holes(nil value)

    for i = #options, 1, -1 do
        local to_test = options[i]
        local x, y, z = Vector3(to_test.x, 0, to_test.z):Get()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if not VALID_TILES[tile] or not TheWorld.Map:ReverseIsVisualGroundAtPoint(x, y, z) then
            table.remove(options, i)
        end
    end

    for i = 1, _bramble_to_spawn do
        -- reached max density, stop spawning more
        if not next(options) then
            break
        end

        local choice = GetRandomItem(options)
        table.insert(selected, choice)

        for ii = #options, 1, -1 do
            local to_test = options[ii]
            if distsq(choice.x, choice.z, to_test.x, to_test.z) < BRAMBLE_MIN_DISTANCE_SQ then -- minimum distance between 2 brambles is 40
                table.remove(options, ii)
            end
        end
    end

    for _, choice in pairs(selected) do
        local bramble = SpawnPrefab("bramble")
        bramble.Transform:SetPosition(choice.x, 0, choice.z)
    end

    _bramble_spawned = true
end

local function OnseasonChange(src, season)
    if _disabled then
        return
    end

    if season == SEASONS.LUSH then
        if not _bramble_spawned then
            SpawnBrambles()
        end
    else
        _bramble_spawned = false
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:Disable(disable)
    _disabled = disable == true
end

function self:RegisterBramble(bramble)
    local x, _, z = bramble.Transform:GetWorldPosition()
    table.insert(_bramble_spots, {x = x, z = z})
    bramble:Remove()
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self.inst:WatchWorldState("season", OnseasonChange)

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    return {
        bramble_spawned = _bramble_spawned,
        bramble_spots = _bramble_spots,
    }
end

function self:OnLoad(data)
    if not data then
        return
    end

    _bramble_spawned = data.bramble_spawned
    _bramble_spots = data.bramble_spots or {}
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------


--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
