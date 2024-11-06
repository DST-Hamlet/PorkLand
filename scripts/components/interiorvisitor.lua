-- component that record infomations about player interior status
local CC_DEF_INDEX = require("main/interior_texture_defs").CC_DEF_INDEX

local function on_x(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_pos_x:set(math.floor(value + 0.5))
    end
end

local function on_z(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_pos_z:set(math.floor(value + 0.5))
    end
end

local function on_center_ent(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.center_ent:set(value)
    end
end

local function on_interior_cc(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.interior_cc:set(CC_DEF_INDEX[value] or 0)
    end
end

local function init(inst)
    local interiorvisitor = inst.components.interiorvisitor
    if interiorvisitor then
        interiorvisitor:Init()
    end
end

local function on_respawned_from_ghost(inst)
    local interiorvisitor = inst.components.interiorvisitor
    if interiorvisitor then
        interiorvisitor:RecordMapOnEnteringNewRoom()
    end
end

local InteriorVisitor = Class(function(self, inst)
    self.inst = inst
    self.exterior_pos_x = 0
    self.exterior_pos_z = 0
    self.interior_cc = "images/colour_cubes/day05_cc.tex"
    self.center_ent = nil
    self.last_center_ent = nil
    self.interior_map = {}
    self.scheduled_sync_map_data = {
        addition = {},
        deletion = {},
    }
    self.anthill_visited_time = {}

    -- self.restore_physics_task = nil

    self.last_mainland_pos = nil

    self.inst:DoStaticTaskInTime(0, init)
    self.record_map_on_room_removal = function(_, data)
        self:RecordMap(data.id, nil)
    end
    self.inst:ListenForEvent("room_removed", self.record_map_on_room_removal, TheWorld)
    self.inst:ListenForEvent("ms_respawnedfromghost", on_respawned_from_ghost)
end, nil,
{
    exterior_pos_x = on_x,
    exterior_pos_z = on_z,
    center_ent = on_center_ent,
    interior_cc = on_interior_cc,
})

function InteriorVisitor:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("room_removed", self.record_map_on_room_removal, TheWorld)
    self.inst:RemoveEventCallback("ms_respawnedfromghost", on_respawned_from_ghost)
end

local function BitAND(a,b)
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra, rb = a%2, b%2
        if ra + rb >1 then c = c + p end
        a, b, p = (a-ra)/2, (b-rb)/2, p*2
    end
    return c
end

function InteriorVisitor:UpdatePlayerAndCreaturePhysics(ent)
    local center = ent:GetPosition()
    local radius = ent:GetSearchRadius()
    for _, v in ipairs(TheSim:FindEntities(center.x, 0, center.z, radius, nil, {"INLIMBO", "pl_invisiblewall"})) do
        if v.Physics ~= nil and v.Physics:GetCollisionGroup() ~= COLLISION.OBSTACLES then
            self:TunePhysics(v, ent)
        end
    end
end

function InteriorVisitor:TunePhysics(inst, ent)
    if inst and inst:IsValid() and inst.Physics ~= nil then
        local player_pos = inst:GetPosition()
        local center_pos = ent:GetPosition()
        local offset = center_pos - player_pos
        local width, depth = ent:GetSize()
        if (math.abs(offset.x) > depth/2 + 1 or math.abs(offset.z) > width/2 + 1)
            and #(TheSim:FindEntities(player_pos.x, 0, player_pos.z, 2, {"pl_invisiblewall"})) > 0 then
            local mask = inst.Physics:GetCollisionMask()
            if BitAND(mask, COLLISION.OBSTACLES) > 0 then
                inst.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
                self:DelayRestorePhysics(inst, .4)
            end
        end
    end
end

function InteriorVisitor:DelayRestorePhysics(inst, delay)
    if inst.interiorvisitor_restore_physics_task then
        inst.interiorvisitor_restore_physics_task:Cancel()
    end

    inst.interiorvisitor_restore_physics_task = inst:DoTaskInTime(delay or 1, function()
        if inst.Physics then
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        end
    end)
end

local function is_anthill_room(id)
    local interior_spawner = TheWorld.components.interiorspawner
    local interior_define = interior_spawner:GetInteriorDefine(id)
    return interior_define and interior_define.dungeon_name == "ANTHILL1"
end

function InteriorVisitor:RecordMap(id, data, no_send)
    self.interior_map[id] = data

    if is_anthill_room(id) then
        if data then
            self.anthill_visited_time[id] = TheWorld.anthill_entrance.maze_reset_count
        else
            self.anthill_visited_time[id] = nil
        end
    end

    if no_send then
        return
    end

    self.scheduled_sync_map_data.addition[id] = data
    if not data then
        table.insert(self.scheduled_sync_map_data.deletion, id)
    end
    if not self.scheduled_sync_map_data_task then
        self.scheduled_sync_map_data_task = self.inst:DoStaticTaskInTime(0, function()
            if not IsTableEmpty(self.scheduled_sync_map_data.deletion) then
                SendModRPCToClient(GetClientModRPC("PorkLand", "remove_interior_map"), self.inst.userid, ZipAndEncodeString(self.scheduled_sync_map_data.deletion))
            end
            if not IsTableEmpty(self.scheduled_sync_map_data.addition) then
                SendModRPCToClient(GetClientModRPC("PorkLand", "interior_map"), self.inst.userid, ZipAndEncodeString(self.scheduled_sync_map_data.addition))
            end
            self.scheduled_sync_map_data = {
                addition = {},
                deletion = {},
            }
            self.scheduled_sync_map_data_task = nil
        end)
    end
end

function InteriorVisitor:RecordAnthillDoorMapReset(no_send)
    local anthill_entrance = TheWorld.anthill_entrance
    if not anthill_entrance then
        print("No anthill entrance!")
        return
    end

    for id, data in pairs(self.interior_map) do
        if is_anthill_room(id) then
            if id == (self.center_ent and self.center_ent.interiorID) then
                self:RecordMap(id, data, true)
            elseif not (self.anthill_visited_time[id] and self.anthill_visited_time[id] >= TheWorld.anthill_entrance.maze_reset_count) then
                for _, door in ipairs(data.doors) do
                    door.unknown = true
                    door.hidden = false
                end
                self:RecordMap(id, data, no_send)
            end
        end
    end
    if self.center_ent and is_anthill_room(self.center_ent.interiorID) then
        self:UpdateSurroundingDoorMaps(self.center_ent, nil, self.interior_map[self.center_ent.interiorID])
    end
end

function InteriorVisitor:ValidateAndMigrateMapData()
    for id, map_data in pairs(self.interior_map) do
        local center = TheWorld.components.interiorspawner:GetInteriorCenter(id)
        if not center or (map_data.uuid and map_data.uuid ~= center.uuid) then
            self.interior_map[id] = nil
            self.anthill_visited_time[id] = nil
        elseif not map_data.group_id then
            local group_id = center:GetGroupId()
            local x, y = center:GetCoordinates()
            map_data.group_id = group_id
            map_data.coord_x = x
            map_data.coord_y = y
        end
    end
    self:RecordAnthillDoorMapReset(true)
end

local op_dir_str = {
    north = "south",
    east  = "west",
    south = "north",
    west  = "east",
}

local function get_door_at_direction(center, direction)
    local x, _, z = center.Transform:GetWorldPosition()
    local doors = TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door", "door_"..direction})
    return doors[1]
end

function InteriorVisitor:UpdateSurroundingDoorMaps(center_ent, last_center_ent, map_data)
    if not map_data then
        return
    end
    local interior_spawner = TheWorld.components.interiorspawner
    for _, door in ipairs(map_data.doors) do
        local target_interior = door.target_interior
        local target_interior_map = self.interior_map[target_interior]
        if target_interior_map then
            local target_center = interior_spawner:GetInteriorCenter(target_interior)
            if target_center and target_center ~= last_center_ent then
                local door_ent = get_door_at_direction(center_ent, door.direction)
                local hidden = door_ent:HasTag("door_hidden")
                local disabled = door_ent:HasTag("door_disabled")
                for _, target_interior_door in ipairs(target_interior_map.doors) do
                    if target_interior_door.direction == op_dir_str[door.direction] then
                        local dirty = false
                        if target_interior_door.hidden ~= hidden then
                            target_interior_door.hidden = hidden
                            dirty = true
                        end
                        if target_interior_door.disabled ~= disabled then
                            target_interior_door.disabled = disabled
                            dirty = true
                        end
                        if target_interior_door.unknown then
                            target_interior_door.unknown = nil
                            dirty = true
                        end
                        if dirty then
                            self:RecordMap(target_interior, target_interior_map)
                        end
                        break
                    end
                end
            end
        end
    end
end

function InteriorVisitor:CanRecordMap(room_id)
    -- Can record if we're not ghost or if have previously visited this room
    return not self.inst:HasTag("playerghost") or self.interior_map[room_id]
end

function InteriorVisitor:RecordMapOnEnteringNewRoom(last_center)
    local current_center = self.center_ent
    if current_center and self:CanRecordMap(current_center.interiorID) then
        local map_data = current_center:CollectMinimapData()
        self:UpdateSurroundingDoorMaps(current_center, last_center, map_data)
        self:RecordMap(current_center.interiorID, map_data)
    end
    -- Record again and ignore non cacheable things once we're out of the last visited room
    if last_center and last_center ~= current_center and last_center:IsValid() and self:CanRecordMap(last_center.interiorID) then
        local map_data = last_center:CollectMinimapData(true)
        self:UpdateSurroundingDoorMaps(last_center, current_center, map_data)
        self:RecordMap(last_center.interiorID, map_data)
    end
end

function InteriorVisitor:UpdateExteriorPos()
    local interior_spawner = TheWorld.components.interiorspawner
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local ent = interior_spawner:GetInteriorCenter(Vector3(x, 0, z))

    self.center_ent = ent
    local last_center_ent = self.last_center_ent
    self.last_center_ent = ent

    if last_center_ent ~= ent then
        self:RecordMapOnEnteringNewRoom(last_center_ent)
    end

    local grue = self.inst.components.grue or {}

    if ent then
        if not self.inst:HasTag("inside_interior") then
            self.inst:AddTag("inside_interior")
        end
        self.inst:PushEvent("enterinterior", {from = last_center_ent, to = ent})
        self.interior_cc = ent.interior_cc
        grue.pl_no_light_interior = --[[ent:HasInteriorTag("NO_LIGHT") or]] true
        if grue.pl_no_light_interior then
            self.inst:AddTag("pl_no_light_interior")
            grue:Start()
        else
            self.inst:RemoveTag("pl_no_light_interior")
        end
        self:UpdatePlayerAndCreaturePhysics(ent)

        if ent:GetIsSingleRoom() then -- check if this room is single, if so, get the unique exit
            local door = ent:GetDoorToExterior()
            local house = interior_spawner:GetExteriorById(door.components.door.interior_name)
            if house ~= nil then
                local x, _, z = house.Transform:GetWorldPosition()
                -- when opening minimap inside a single room,
                -- focus on exterior house position
                self.exterior_pos_x = x
                self.exterior_pos_z = z
                return
            end
        end
    else
        if self.inst:HasTag("inside_interior") then
            self.inst:RemoveTag("inside_interior")
            self.inst:PushEvent("leaveinterior", {from = last_center_ent, to = nil})
        end
        grue.pl_no_light_interior = false
        self.inst:RemoveTag("pl_no_light_interior")

        if not interior_spawner:IsInInteriorRegion(x, z) then
            self.last_mainland_pos = {x = x, z = z}
        end
    end

    self.exterior_pos_x = 0
    self.exterior_pos_z = 0
end

function InteriorVisitor:OnSave()
    return {
        last_mainland_pos = self.last_mainland_pos,
        interior_map = self.interior_map,
        anthill_visited_time = self.anthill_visited_time,
    }
end

function InteriorVisitor:OnLoad(data)
    if data.last_mainland_pos then
        self.last_mainland_pos = data.last_mainland_pos
    end
    if data.interior_map then
        self.interior_map = data.interior_map
    end
    if data.anthill_visited_time then
        self.anthill_visited_time = data.anthill_visited_time
    end

    for id, map_data in pairs(self.interior_map) do -- 转换旧存档的数据格式
        if map_data.floor_texture then
            map_data.minimap_floor_texture = map_data.floor_texture
            map_data.floor_texture = nil
        end
    end

    -- restore player position if interior was destroyed
    if GetTick() > 0 and self.last_mainland_pos ~= nil then
        local x, _, z = self.inst.Transform:GetWorldPosition()
        if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
            and not TheWorld.components.interiorspawner:IsInInterior(x, z) then
            self.inst.Transform:SetPosition(self.last_mainland_pos.x, 0, self.last_mainland_pos.z)
        end
    end
end

-- This should be called after all entities loaded
function InteriorVisitor:Init()
    self:ValidateAndMigrateMapData()
    -- Don't quite understand why ThePlayer can be nil when the client receives this,
    -- from HandleClientRPC in networkclientrpc.lua, it shouldn't happen, but it does anyway,
    -- since this is not critical to the client on initial load, use a delay here to mitigate this
    self.inst:DoStaticTaskInTime(3, function()
        SendModRPCToClient(GetClientModRPC("PorkLand", "interior_map"), self.inst.userid, ZipAndEncodeString(self.interior_map))
    end)
end

return InteriorVisitor
