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
function RoomBuilder:CanBuildRoomAtDirection(house_id, current_room_id, direction)
    if not TheWorld.components.interiorspawner:CanBuildMorePlayerRoom(house_id) then
        return false, "NO_SPACE"
    end

    local target_room_id = TheWorld.components.interiorspawner:GetPlayerRoomInDirection(house_id, current_room_id, TheWorld.components.interiorspawner:GetDirByLabel(direction))
    if target_room_id == house_id and direction == "north" then -- connecting to starting room's south door is not allowed, since that's the house exit
        return false, "BLOCKED_EXIT"
    end

    if target_room_id then
        return true, "CONNECTING"
    else
        return true, "CREATING"
    end
end

local function CreateNewRoom(door_frame, current_interior, house_id)
    local interior_spawner = TheWorld.components.interiorspawner

    local dir = door_frame.baseanimname
    local ID = interior_spawner:GetNewID()
    local name = "playerhouse" .. ID

    local room_exits = {}
    room_exits[PLAYER_INTERIOR_EXIT_DIR_DATA[dir].opposing_exit_dir] = {
        target_room = current_interior.interiorID,
        bank =  "player_house_doors",
        build = "player_house_doors",
        room = ID,
        prefab_name = door_frame.prefab,
        house_door = true,
    }

    -- Adds the player room def to the interior_spawner so we can find the adjacent rooms
    interior_spawner:RegisterPlayerRoom(house_id, ID, current_interior.interiorID, interior_spawner:GetDirByLabel(dir))

    local doors_to_activate = {}
    -- Finds all the rooms surrounding the newly built room
    local surrounding_rooms = interior_spawner:GetSurroundingPlayerRooms(house_id, ID, PLAYER_INTERIOR_EXIT_DIR_DATA[dir].op_dir)
    -- Goes through all the adjacent rooms, checks if they have a pre built door and adds them to doors_to_activate
    for _, room_data in pairs(surrounding_rooms) do
        local direction
        local current_x, current_y = interior_spawner:GetPlayerRoomIndexByID(house_id, current_interior.interiorID)
        if room_data.dir.y > current_y then
            direction = "north"
        elseif room_data.dir.y < current_y then
            direction = "south"
        elseif room_data.dir.x > current_x then
            direction = "east"
        elseif room_data.dir.x < current_x then
            direction = "west"
        end

        local room_id = room_data.id
        local center = interior_spawner:GetInteriorCenter(room_id)
        local x, y, z = center.Transform:GetWorldPosition()
        local doors = TheSim:FindEntities(x, y, z, 50, {"predoor"})
        for _, obj in pairs(doors) do
            local op_dir = PLAYER_INTERIOR_EXIT_DIR_DATA[direction] and PLAYER_INTERIOR_EXIT_DIR_DATA[direction].op_dir
            if obj.baseanimname == op_dir then
                room_exits[PLAYER_INTERIOR_EXIT_DIR_DATA[op_dir].opposing_exit_dir] = {
                    target_room = room_id,
                    bank =  "player_house_doors",
                    build = "player_house_doors",
                    room = ID,
                    prefab_name = obj.prefab,
                    house_door = true,
                }

                doors_to_activate[obj] = room_id
            end
        end
    end

    -- Actually creates the room
    local def = interior_spawner:CreateRoom("generic_interior", width, nil, depth, name, ID, addprops, room_exits, walltexture, floortexture, minimaptexture, nil, colorcube, nil, true, "inside", "HOUSE", WORLD_TILES.WOODFLOOR)
    interior_spawner:SpawnInterior(def)

    local room = interior_spawner:GetInteriorCenter(ID)
    room:AddInteriorTags("home_prototyper")

    -- Activates all the doors in the adjacent rooms
    for door_to_activate, adjacent_room_id in pairs(doors_to_activate) do
        door_to_activate:ActivateSelf(ID, adjacent_room_id)
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
        target_interior = ID,
        target_door_id = ID .. PLAYER_INTERIOR_EXIT_DIR_DATA[dir].target_door_id_dir
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

    local house_id = interior_spawner:GetPlayerHouseByRoomId(current_room_id)
    local can_build, cause = self:CanBuildRoomAtDirection(house_id, current_room_id, door_frame.baseanimname)
    if not can_build then
        return false, cause
    end

    if cause == "CONNECTING" then -- change this logic?
        local target_interior_id = interior_spawner:GetPlayerRoomInDirection(house_id, current_room_id, interior_spawner:GetDirByLabel(door_frame.baseanimname))
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
