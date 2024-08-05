-- local STATUS_CALCULATING = 0 -- 复制自components/locomotor.lua
-- local STATUS_FOUNDPATH = 1
-- local STATUS_NOPATH = 2

local WorldPathfinderManager = Class(function(self, inst)
    self.inst = inst
    self.interior_pathfinder = {}
    self.pathfinder_searchs = {}
end, nil, nil)

function WorldPathfinderManager:AddWall(x, y, z)
    local pathfinder_entity = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
    return pathfinder_entity.components.interiorpathfinder:AddWall(x, y, z)
end

function WorldPathfinderManager:RemoveWall(x, y, z)
    local pathfinder_entity = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
    return pathfinder_entity.components.interiorpathfinder:RemoveWall(x, y, z)
end

function WorldPathfinderManager:HasWall(x, y, z)
    local pathfinder_entity = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
    return pathfinder_entity.components.interiorpathfinder:HasWall(x, y, z)
end

function WorldPathfinderManager:IsClear(x, y, z, tx, ty, tz, data) -- 检测两点之间的直线寻路是否有阻挡
    local pathfinder_entity = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
    return pathfinder_entity.components.interiorpathfinder:IsClear(x, y, z, tx, ty, tz, data)
end

function WorldPathfinderManager:SubmitSearch(x, y, z, tx, ty, tz, data) -- 计算寻路并储存结果
    local pathfinder_entity = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
    local search = pathfinder_entity.components.interiorpathfinder:CalculateSearch(x, y, z, tx, ty, tz, data)
    table.insert(self.pathfinder_searchs, search)
    return search
end

function WorldPathfinderManager:KillSearch(search)
    for i,v in ipairs(self.pathfinder_searchs) do
        if v == search then
            table.remove(self.pathfinder_searchs, i)
            break
        end
    end
end

return WorldPathfinderManager
