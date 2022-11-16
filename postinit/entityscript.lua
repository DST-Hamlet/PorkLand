GLOBAL.setfenv(1, GLOBAL)

function EntityScript:GetIsOnWater(x, y, z)  -- temporary
    local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
    return Ham_IsWaterTile(tile)
end
