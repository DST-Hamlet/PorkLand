local floortexture = "levels/textures/noise_woodfloor.tex"
local walltexture = "levels/textures/interiors/shop_wall_woodwall.tex"
local minimaptexture = "levels/textures/map_interior/mini_floor_wood.tex"
local colorcube = "images/colour_cubes/pigshop_interior_cc.tex"
local width = 15
local depth = 10
local addprops = {
    {name = "deco_roomglow", x_offset = 0, z_offset = 0 },

    {name = "deco_antiquities_cornerbeam",  x_offset = -5, z_offset =  -15/2, rotation = 90, flip = true, addtags = {"playercrafted"}},
    {name = "deco_antiquities_cornerbeam",  x_offset = -5, z_offset =   15/2, rotation = 90,              addtags = {"playercrafted"}},
    {name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset = -15/2, rotation = 90, flip = true, addtags = {"playercrafted"}},
    {name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset =  15/2, rotation = 90,              addtags = {"playercrafted"}},
    {name = "swinging_light_rope_1", x_offset = -2, z_offset =  0, rotation = -90,                        addtags = {"playercrafted"}},
}

local RoomBuilder = Class(function(self, inst)
    self.inst = inst
end)

---@return boolean can_build
---@return string cause
function RoomBuilder:CanBuildRoomAtDirection(house_id, current_interior, direction)
    if not TheWorld.components.interiorspawner:CanBuildMorePlayerRoom(house_id) then
        return false, "NO_SPACE"
    end

    local target_room = TheWorld.components.interiorspawner:GetRoomInDirection(current_interior, TheWorld.components.interiorspawner:GetDirByLabel(direction))
    if target_room then
        local x, y = target_room:GetCoordinates()
        if x == 0 and y == 0 and direction == "north" then -- connecting to starting room's south door is not allowed, since that's the house exit
            return false, "BLOCKED_EXIT"
        else
            return true, "CONNECTING"
        end
    else
        return true, "CREATING"
    end
end

local function CreateNewRoom(door_frame, current_interior, house_id)
    local interior_spawner = TheWorld.components.interiorspawner

    local dir = door_frame.baseanimname
    local id = interior_spawner:GetNewID()
    local name = "playerhouse" .. id

    local room_exits = {}
    room_exits[PLAYER_INTERIOR_EXIT_DIR_DATA[dir].opposing_exit_dir] = {
        target_room = current_interior.interiorID,
        bank =  "player_house_doors",
        build = "player_house_doors",
        room = id,
        prefab_name = door_frame.prefab,
        house_door = true,
    }

    local doors_to_activate = {}
    -- Finds all the rooms surrounding the newly built room
    local direction_coordinates = interior_spawner:GetDirByLabel(dir)
    local current_x, current_y = current_interior:GetCoordinates()
    local target_coordinate_x = current_x + direction_coordinates.x
    local target_coordinate_y = current_y + direction_coordinates.y
    local surrounding_rooms = interior_spawner:GetSurroundingRooms(house_id, target_coordinate_x, target_coordinate_y)
    -- Goes through all the adjacent rooms, checks if they have a pre built door and adds them to doors_to_activate
    for _, room_data in pairs(surrounding_rooms) do
        local room_id = room_data.interior.interiorID
        local x, y, z = room_data.interior.Transform:GetWorldPosition()
        local doors = TheSim:FindEntities(x, y, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"predoor"})
        for _, obj in pairs(doors) do
            local op_dir = PLAYER_INTERIOR_EXIT_DIR_DATA[room_data.direction.label].op_dir
            if obj.baseanimname == op_dir then
                room_exits[PLAYER_INTERIOR_EXIT_DIR_DATA[op_dir].opposing_exit_dir] = {
                    target_room = room_id,
                    bank =  "player_house_doors",
                    build = "player_house_doors",
                    room = id,
                    prefab_name = obj.prefab,
                    house_door = true,
                }

                doors_to_activate[obj] = room_id
            end
        end
    end

    -- Actually creates the room
    interior_spawner:CreateRoom({
        width = width,
        height = nil,
        depth = depth,
        dungeon_name = name,
        roomindex = id,
        addprops = addprops,
        exits = room_exits,
        walltexture = walltexture,
        floortexture = floortexture,
        minimaptexture = minimaptexture,
        colour_cube = colorcube,
        playerroom = true,
        reverb = "inside",
        ambient_sound = "HOUSE",
        footstep_tile = WORLD_TILES.WOODFLOOR,
        cameraoffset = nil,
        zoom = nil,
        group_id = house_id,
        interior_coordinate_x = target_coordinate_x,
        interior_coordinate_y = target_coordinate_y,
    })

    local room = interior_spawner:GetInteriorCenter(id)
    room:AddInteriorTags("home_prototyper")

    -- Activates all the doors in the adjacent rooms
    for door_to_activate, adjacent_room_id in pairs(doors_to_activate) do
        door_to_activate:ActivateSelf(id, adjacent_room_id)
    end

    -- -- If there are already built doors in the same direction as the door being used to build, activate them
    -- local pt = interior_spawner:getSpawnOrigin()
    -- local other_doors = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, {"predoor"})
    -- for _, other_door in ipairs(other_doors) do
    --     if other_door ~= door_frame and other_door.baseanimname and other_door.baseanimname == door_frame.baseanimname then
    --         other_door.ActivateSelf(other_door, ID, current_interior)
    --     end
    -- end

    local door_def =
    {
        my_interior_name = current_interior.interiorID,
        my_door_id = current_interior.interiorID .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].my_door_id_dir,
        target_interior = id,
        target_door_id = id .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].target_door_id_dir
    }

    interior_spawner:AddDoor(door_frame, door_def)

    door_frame.components.door:SetDoorDisabled(false, "house_prop")
    door_frame.InitHouseDoor(door_frame, dir)
end

local function ConnectRoom(door_frame, current_room_id, target_room_id)
    local interior_spawner = TheWorld.components.interiorspawner

    local dir = door_frame.baseanimname

    local door_def =
    {
        my_interior_name = current_room_id,
        my_door_id = current_room_id .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].my_door_id_dir,
        target_interior = target_room_id,
        target_door_id = target_room_id .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].target_door_id_dir
    }

    interior_spawner:AddDoor(door_frame, door_def)
    door_frame:ActivateSelf(target_room_id, current_room_id)
end

function RoomBuilder:BuildRoom(door_frame, permit)
    if not door_frame:HasTag("predoor") then
        return false, "ALREADY_BUILT"
    end

    local interior_spawner = TheWorld.components.interiorspawner
    local current_interior = interior_spawner:GetInteriorCenter(door_frame:GetPosition())
    local current_room_id = current_interior.interiorID

    local house_id = current_interior:GetGroupId()
    local can_build, cause = self:CanBuildRoomAtDirection(house_id, current_interior, door_frame.baseanimname)
    if not can_build then
        return false, cause
    end

    if cause == "CONNECTING" then -- change this logic?
        local target_interior_id = interior_spawner:GetRoomInDirection(current_interior, interior_spawner:GetDirByLabel(door_frame.baseanimname))
        ConnectRoom(door_frame, current_room_id, target_interior_id)
    else
        CreateNewRoom(door_frame, current_interior, house_id)
    end

    door_frame:AddTag("interior_door")
    door_frame:AddTag("client_forward_action_target")
    door_frame:RemoveTag("predoor")

    if permit then
       permit:Remove()
    end

    return true
end

return RoomBuilder
