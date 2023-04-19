local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function GetWaveBearing(map, ex, ey, ez)
    local offs =
    {
        {-2,-2}, {-1,-2}, {0,-2}, {1,-2}, {2,-2},
        {-2,-1}, {-1,-1}, {0,-1}, {1,-1}, {2,-1},
        {-2, 0}, {-1, 0},         {1, 0}, {2, 0},
        {-2, 1}, {-1, 1}, {0, 1}, {1, 1}, {2, 1},
        {-2, 2}, {-1, 2}, {0, 2}, {1, 2}, {2, 2}
    }

    local width, height = map:GetSize()
    local halfw, halfh = 0.5 * width, 0.5 * height
    local x, y = map:GetTileXYAtPoint(ex, ey, ez)
    local xtotal, ztotal, n = 0, 0, 0

    for i = 1, #offs, 1 do
        local tile = map:GetTile(x + offs[i][1], y + offs[i][2])
        if IsLandTile(tile) or tile == WORLD_TILES.IMPASSABLE then
            xtotal = xtotal + ((x + offs[i][1] - halfw) * TILE_SCALE)
            ztotal = ztotal + ((y + offs[i][2] - halfh) * TILE_SCALE)
            n = n + 1
        end
    end

    local bearing = nil
    if n > 0 then
        local a = math.atan2(ztotal / n - ez, xtotal / n - ex)
        bearing = -a / DEGREES - 90
    end

    return bearing
end

local function TrySpawnIAWavesOrShore(self, map, x, y, z)
    local bearing = GetWaveBearing(map, x, y, z)
    if not bearing then
        return
    end

    local wave = SpawnPrefab("pl_wave_shore")
    wave.Transform:SetPosition(x, y, z)
    wave.Transform:SetRotation(bearing)
    wave:SetAnim()
end

local shimmer = {
    [WORLD_TILES.LILYPOND] = {per_sec = 80, spawn_rate = 0, tryspawn = TrySpawnIAWavesOrShore},
}

AddComponentPostInit("wavemanager", function(self)
    for tile, data in pairs(shimmer) do
        self.shimmer[tile] = data
    end

    -- self.shimmer_per_sec_mod = TUNING.WATERVISUALSHIMMER
end)
