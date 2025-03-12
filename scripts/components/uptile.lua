local Uptile = Class(function(self, inst)
    self.inst = inst
    self.tilesfixed =
    {
        pigruins = false,
        lilypond_version_1 = false,
        mud_falloff = false,
    }

    self.inst:DoStaticTaskInTime(0, function()
        self:FixAllTiles()
    end)
end)

local adjacent = {
    {x = 1, z = 0, angle = 0},
    {x = -1, z = 0, angle = 180},
    {x = 0, z = 1, angle = 270},
    {x = 0, z = -1, angle = 90},
}

local diagonal = {
    {x = 1, z = 1, angle = 270},
    {x = 1, z = -1, angle = 0},
    {x = -1, z = 1, angle = 180},
    {x = -1, z = -1, angle = 90},
}

function Uptile:FixAllTiles(force) -- 请确保在世界第一次加载时执行，或者在undertile和uptile都完成onload后执行
    local undertile = TheWorld.components.undertile
    local alltilefixed = true
    for k, v in pairs(self.tilesfixed) do
        if not v then
            alltilefixed = false
        end
    end
    if undertile and (not alltilefixed or force) then
        print("SHOULD FIX UNDERTILES!!!")
        local map = TheWorld.Map
        local width, height = map:GetSize()
        for x = 0, width - 1 do
            for y = 0, height - 1 do
                local tile = map:GetTile(x, y)
                local tile_under = undertile:GetTileUnderneath(x, y)
                local tx, _, tz = map:GetPointAtTile(x, y)
                local node_index = map:GetNodeIdAtPoint(tx, 0, tz)
                local node = TheWorld.topology.nodes[node_index]
                if node and node.tags then
                    if not self.tilesfixed["pigruins"] then
                        if not tile_under and table.contains(node.tags, "Canopy") then
                            local tilevalue = table.contains(node.tags, "Gas_Jungle") and WORLD_TILES.GASJUNGLE or WORLD_TILES.DEEPRAINFOREST
                            undertile:SetTileUnderneath(x, y, tilevalue)
                        elseif tile == WORLD_TILES.PIGRUINS_NOCANOPY then
                            map:SetTile(x, y, WORLD_TILES.PIGRUINS)
                        end
                    end
                end

                if not self.tilesfixed["lilypond_version_1"] then
                    if tile == WORLD_TILES.LILYPOND then
                        local has_adjacent_waterfall = false
                        for i, v in ipairs(adjacent) do
                            local neibor_tile = map:GetTile(x + v.x, y + v.z)
                            if neibor_tile and neibor_tile == WORLD_TILES.IMPASSABLE then
                                local waterfall = SpawnPrefab("waterfall_lilypond")
                                waterfall.Transform:SetPosition(tx + v.x * 3.5, _, tz + v.z * 3.5)
                                waterfall._paramrotation:set(-v.angle)
                                has_adjacent_waterfall = true
                            end
                        end
                        if has_adjacent_waterfall then
                            for i, v in ipairs(diagonal) do
                                local neibor_tile = map:GetTile(x + v.x, y + v.z)
                                local neibor_tile_x = map:GetTile(x + v.x, y)
                                local neibor_tile_z = map:GetTile(x, y + v.z)
                                if neibor_tile and neibor_tile == WORLD_TILES.IMPASSABLE
                                    and neibor_tile_x and neibor_tile_x ~= WORLD_TILES.LILYPOND
                                    and neibor_tile_z and neibor_tile_z ~= WORLD_TILES.LILYPOND then

                                    local waterfall = SpawnPrefab("waterfall_lilypond_corner")
                                    waterfall.Transform:SetPosition(tx + v.x * 3.5, _, tz + v.z * 3.5)
                                    waterfall._paramrotation:set(- v.angle - 90)
                                end
                            end
                        end
                    end
                end

                if not self.tilesfixed["mud_falloff"] then
                    if TileGroupManager:IsLandTile(tile) then
                        for i, v in ipairs(adjacent) do
                            local neibor_tile = map:GetTile(x + v.x, y + v.z)
                            if neibor_tile and not TileGroupManager:IsLandTile(neibor_tile) then
                                local falloff = SpawnPrefab("falloff_fx")
                                falloff.Transform:SetPosition(tx + v.x * 2, _, tz + v.z * 2)
                                falloff._paramrotation:set(-v.angle + 90)
                            end
                        end
                    end
                end
            end
        end
        self.tilesfixed["pigruins"] = true
        self.tilesfixed["lilypond_version_1"] = true
        self.tilesfixed["mud_falloff"] = true
    end
end

function Uptile:OnLoad(data)
    if data ~= nil then
        if data.tilesfixed ~= nil then
            for k, v in pairs(data.tilesfixed) do
                self.tilesfixed[k] = data.tilesfixed[k]
            end
        end
    end
end

function Uptile:OnSave()
    return {
        tilesfixed = self.tilesfixed
    }
end

return Uptile
