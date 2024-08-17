local Uptile = Class(function(self, inst)
    self.inst = inst
    self.tilesfixed =
    {
        pigruins = false
    }
end)

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
                        if tile == WORLD_TILES.PIGRUINS and not tile_under then
                            local tilevalue = table.contains(node.tags, "Gas_Jungle") and WORLD_TILES.GASJUNGLE or WORLD_TILES.DEEPRAINFOREST
                            undertile:SetTileUnderneath(x, y, tilevalue)
                        elseif tile == WORLD_TILES.PIGRUINS_NOCANOPY then
                            map:SetTile(x, y, WORLD_TILES.PIGRUINS)
                        end
                    end
                end
            end
        end
        self.tilesfixed["pigruins"] = true
    end
end

function Uptile:OnLoad(data)
    if data ~= nil then
        if data.tilesfixed ~= nil then
            for k, v in pairs(tilesfixed) do
                self.tilesfixed[k] = data.tilesfixed[k]
            end
        end
    end
end

return Uptile
