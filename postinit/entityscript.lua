GLOBAL.setfenv(1, GLOBAL)

local unpack = unpack
local COLLISION = COLLISION
local PhysicsCollisionCallbacks = PhysicsCollisionCallbacks

local should_pass_ground = {}

local _SetOceanBlendParams = AnimState.SetOceanBlendParams
function AnimState:SetOceanBlendParams(...)
    if TheWorld.has_ia_ocean then return end
    return _SetOceanBlendParams(self, ...)
end

local _SetLayer = AnimState.SetLayer
function AnimState:SetLayer(layer, ...)
    if TheWorld.has_ia_ocean and layer <= LAYER_BELOW_GROUND then
        layer = LAYER_BACKGROUND -- TODO: if sorting issues occur use ground and increase the sort
    end
    return _SetLayer(self, layer, ...)
end

function EntityScript:GetIsCloseToWater(radius, pt, attempts)
    radius = radius or 1
    pt = pt or Point(self.Transform:GetWorldPosition())
    attempts = attempts or 8
    local waterPos = FindValidPositionByFan(0, radius, attempts, function(offset)
        local test_point = pt + offset
        --if IsOceanTile(TheWorld.Map:GetTileAtPoint(test_point:Get()))  then
        if IsOnOcean(test_point) then
            return true
        end
        return false
    end)

    return waterPos ~= nil
end

local _AddPlatformFollower = EntityScript.AddPlatformFollower
function EntityScript:AddPlatformFollower(child, ...)
    _AddPlatformFollower(self, child, ...)
    if child ~= nil and child.components.drydrownable ~= nil then
        child:PushEvent("onhitcoastline")
    end
end

-- local _GetCurrentTileType = EntityScript.GetCurrentTileType
-- function EntityScript:GetCurrentTileType(...)
--     local map = TheWorld.Map
--     if map.ia_overhang then
--     -- WARNING: This function is only an approximate, if you only care if the ground is valid or not then call IsOnValidGround()
--         local ptx, pty, ptz = self.Transform:GetWorldPosition()
--         local tilecenter_x, tilecenter_y, tilecenter_z  = map:GetTileCenterPoint(ptx, 0, ptz)
--         local tx, ty = map:GetTileCoordsAtPoint(ptx, 0, ptz)
--         local actual_tile = map:GetTile(tx, ty)

--         if actual_tile ~= nil and tilecenter_x ~= nil and tilecenter_z ~= nil then
--             if not TileGroupManager:IsOceanTile(actual_tile) then
--                 local xpercent = (tilecenter_x - ptx) / TILE_SCALE + .25
--                 local ypercent = (tilecenter_z - ptz) / TILE_SCALE + .25

--                 local x_min = xpercent > .666 and -1 or 0
--                 local x_max = xpercent < .333 and 1 or 0
--                 local y_min = ypercent > .666 and -1 or 0
--                 local y_max = ypercent < .333 and 1 or 0

--                 local x_off = 0
--                 local y_off = 0

--                 for x = x_min, x_max do
--                     for y = y_min, y_max do
--                         local tile = map:GetTile(tx + x, ty + y)
--                         if tile > actual_tile then
--                             actual_tile = tile
--                             x_off = x
--                             y_off = y
--                         end
--                     end
--                 end
--             end

--             return actual_tile, GetTileInfo(actual_tile)
--         end
--     else
--         return _GetCurrentTileType(self, ...)
--     end
-- end

function EntityScript:GetIsCloseToLand(radius, pt, attempts)
    radius = radius or 1
    pt = pt or Point(self.Transform:GetWorldPosition())
    attempts = attempts or 8
    local landPos = FindValidPositionByFan(0, radius, attempts, function(offset)
        local test_point = pt + offset
        --if not IsOceanTile(TheWorld.Map:GetTileAtPoint(test_point:Get()))  then
        if not IsOnOcean(test_point) then
            return true
        end
        return false
    end)

    return landPos ~= nil
end

function EntityScript:IsSailing()
    return (self.components.sailor ~= nil and self.components.sailor:IsSailing())
        or (self:HasTag("_sailor") and self:HasTag("sailing"))
end

-- Note: These only work on mastersim....
function EntityScript:IsAmphibious()
    return self.components.locomotor and self.components.locomotor:IsAmphibious()
end

function EntityScript:IsAquatic()
    return self.components.locomotor and self.components.locomotor:IsAquatic()
end

function EntityScript:IsTerrestrial()
    return self.components.locomotor and self.components.locomotor:IsTerrestrial()
end

function EntityScript:CanOnWater()
    return (self.components.locomotor == nil or self.components.locomotor:CanPathfindOnWater())
        or (self.components.drownable ~= nil and not self.components.drownable:CanDrownOverWater())
end

function EntityScript:CanOnLand()
    return (self.components.locomotor == nil or self.components.locomotor:CanPathfindOnLand() or self:HasTag("player"))
        and not self:IsSailing()
end


function SilenceEvent(event, data, ...)
    return event.."_silenced", data
end

function EntityScript:AddPushEventPostFn(event, fn, source)
    source = source or self

    if not source.pushevent_postfn then
        source.pushevent_postfn = {}
    end

    source.pushevent_postfn[event] = fn
end

local _PushEvent = EntityScript.PushEvent
function EntityScript:PushEvent(event, data, ...)
    local eventfn = self.pushevent_postfn ~= nil and self.pushevent_postfn[event] or nil

    if eventfn ~= nil then
        local newevent, newdata = eventfn(event, data, ...)

        if newevent ~= nil then
            event = newevent
        end
        if newdata ~= nil then
            data = newdata
        end
    end
    -- print(event)
    -- print(data)

    _PushEvent(self, event, data, ...)
end

function EntityScript:GetEventCallbacks(event, source, source_file)
    source = source or self

    assert(self.event_listening[event] and self.event_listening[event][source])

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                return fn
            end
        else
            return fn
        end
    end
end

local _PerformBufferedAction = EntityScript.PerformBufferedAction
function EntityScript:PerformBufferedAction(...)
    local _bufferedaction = self.bufferedaction
    if _PerformBufferedAction(self, ...) == true then
        self:PushEvent("actionsuccess", {action = _bufferedaction})
        return true
    end
end

local _SetPrefabName = EntityScript.SetPrefabName
function EntityScript:SetPrefabName(name, ...)
    _SetPrefabName(self, name, ...)
    self.entity:SetPrefabName(self.realprefab or self.prefab)
end

local _GetSaveRecord = EntityScript.GetSaveRecord
function EntityScript:GetSaveRecord(...)
    local record, refs = _GetSaveRecord(self, ...)
    record.realprefab = self.realprefab
    return record, refs
end

local _SpawnSaveRecord = SpawnSaveRecord
function SpawnSaveRecord(saved, ...)
    saved.prefab = saved.realprefab or saved.prefab
    return _SpawnSaveRecord(saved, ...)
end

local NOCLICK = {}

function RemoveLocalNOCLICK(ent)
    NOCLICK[ent.entity or ent] = nil
    ent:RemoveEventCallback("onremove", RemoveLocalNOCLICK)
end

function LocalNOCLICK(ent)
    NOCLICK[ent.entity or ent] = true
    ent:ListenForEvent("onremove", RemoveLocalNOCLICK)
end

function IsLocalNOCLICKed(ent)
    return NOCLICK[ent.entity or ent] == true
end

function EntityScript:GetPhysicsCollisionCallback()
    return PhysicsCollisionCallbacks[self.GUID]
end

function Physics:SetShouldPassGround(enable)
    if enable then
        if self:GetCollisionGroup() == COLLISION.ITEMS then
            self:ClearCollidesWith(COLLISION.LAND_OCEAN_LIMITS + COLLISION.PERMEABLE_GROUND)
        end
    end
    should_pass_ground[self] = enable
end

function Physics:ShouldPassGround()
    return should_pass_ground[self]
end

local _CollidesWith = Physics.CollidesWith
function Physics:CollidesWith(collision, ...)
    local rets = {_CollidesWith(self, collision, ...)}
    if self:ShouldPassGround() and self:GetCollisionGroup() == COLLISION.ITEMS then
        self:ClearCollidesWith(COLLISION.LAND_OCEAN_LIMITS + COLLISION.PERMEABLE_GROUND)
    end
    return unpack(rets)
end

local _SetCollisionGroup = Physics.SetCollisionGroup
function Physics:SetCollisionGroup(group, ...)
    if self:ShouldPassGround() and group == COLLISION.ITEMS then
        self:ClearCollidesWith(COLLISION.LAND_OCEAN_LIMITS + COLLISION.PERMEABLE_GROUND)
    end
    return _SetCollisionGroup(self, group, ...)
end

local _Remove = EntityScript.Remove
function EntityScript:Remove(...)
    if should_pass_ground[self.Physics] then
        should_pass_ground[self.Physics] = nil
    end
    return _Remove(self, ...)
end

