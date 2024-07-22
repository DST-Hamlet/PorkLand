GLOBAL.setfenv(1, GLOBAL)

local Pathfinder = Pathfinder

local _AddWall = Pathfinder.AddWall
function Pathfinder:AddWall(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z) then
        return TheWorld.components.worldpathfindermanager:AddWall(x, y, z)
    else
        return _AddWall(self, x, y, z, ...)
    end
end

local _RemoveWall = Pathfinder.RemoveWall
function Pathfinder:RemoveWall(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z) then
        return TheWorld.components.worldpathfindermanager:RemoveWall(x, y, z)
    else
        return _RemoveWall(self, x, y, z, ...)
    end
end

local _IsClear = Pathfinder.IsClear
function Pathfinder:IsClear(x, y, z, tx, ty, tz, data, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z) then
        return TheWorld.components.worldpathfindermanager:IsClear(x, y, z, tx, ty, tz, data)
    else
        return _IsClear(self, x, y, z, tx, ty, tz, data, ...)
    end
end

local _SubmitSearch = Pathfinder.SubmitSearch
function Pathfinder:SubmitSearch(x, y, z, tx, ty, tz, data, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z) then
        return TheWorld.components.worldpathfindermanager:SubmitSearch(x, y, z, tx, ty, tz, data)
    else
        return _SubmitSearch(self, x, y, z, tx, ty, tz, data, ...)
    end
end

local _GetSearchStatus = Pathfinder.GetSearchStatus
function Pathfinder:GetSearchStatus(search, ...)
    if type(search) == "table" and search.isinterior then
        return search.status
    else
        return _GetSearchStatus(self, search, ...)
    end
end

local _GetSearchResult = Pathfinder.GetSearchResult
function Pathfinder:GetSearchResult(search, ...)
    if type(search) == "table" and search.isinterior then
        return search.path
    else
        return _GetSearchResult(self, search, ...)
    end
end

local _KillSearch = Pathfinder.KillSearch
function Pathfinder:KillSearch(search, ...)
    if type(search) == "table" and search.isinterior then
        return TheWorld.components.worldpathfindermanager:KillSearch(search)
    else
        return _KillSearch(self, search, ...)
    end
end



