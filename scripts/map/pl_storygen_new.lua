local AddPlMaptags = require("map/pl_map_tags")

require("map/storygen")

local function BuildStory(tasks, story_gen_params, level)
    local story = Story("GAME", tasks, terrain, story_gen_params, level)
    AddPlMaptags(story.map_tags)
    local task_nodes = story:GenerateRectangleNodes(tasks)

    return {
        root = story.rootNode,
        startNode = story.startNode,
        GlobalTags = story.GlobalTags,
        task_nodes = task_nodes,
    }, story
end

function Story:GenerateRectangleNodesFromTask(task)
    local room_choices = {}

    if task.entrance_room then
        local r = math.random()
        if task.entrance_room_chance == nil or task.entrance_room_chance > r then
            if type(task.entrance_room) == "table" then
                task.entrance_room = GetRandomItem(task.entrance_room)
            end

            local new_room = self:GetRoom(task.entrance_room)
            assert(new_room, "Couldn't find entrance room with name "..task.entrance_room)

            if new_room.contents == nil then
                new_room.contents = {}
            end

            if new_room.contents.fn then
                new_room.contents.fn(new_room)
            end
            new_room.entrance = true
            table.insert(room_choices, new_room)
        end
    end

    if task.room_choices_sorted then
        for i, roomdata in ipairs(task.room_choices_sorted) do
            local room = roomdata[1]
            local count = roomdata[2]
            if type(count) == "function" then
                count = count()
            end
            for id = 1, count do
                local new_room = self:GetRoom(room)

                assert(new_room, "Couldn't find room with name "..room)
                if new_room.contents == nil then
                    new_room.contents = {}
                end

                if new_room.contents.fn then
                    new_room.contents.fn(new_room)
                end
                table.insert(room_choices, new_room)
            end
        end
    elseif task.room_choices then
        for room, count in pairs(task.room_choices) do
            if type(count) == "function" then
                count = count()
            end
            for id = 1, count do
                local new_room = self:GetRoom(room)

                assert(new_room, "Couldn't find room with name "..room)
                if new_room.contents == nil then
                    new_room.contents = {}
                end

                if new_room.contents.fn then
                    new_room.contents.fn(new_room)
                end
                table.insert(room_choices, new_room)
            end
        end
    end

    local task_node = Graph(task.id, {
        parent = self.rootNode,
        default_bg = task.room_bg,
        colour = task.colour,
        background = task.background_room,
        set_pieces = task.set_pieces,
        random_set_pieces = task.random_set_pieces,
        maze_tiles = task.maze_tiles,
        maze_tile_size = task.maze_tile_size,
        room_tags = task.room_tags,
        required_prefabs = task.required_prefabs
    })

    task_node.substitutes = task.substitutes
    task_node.sorted = task.room_choices_sorted and true or false

    for roomID, next_room in ipairs(room_choices) do
        next_room.id = task.id .. ":" .. roomID .. ":" .. next_room.name  -- TODO: add room names for special rooms
        next_room.task = task.id

        self:RunTaskSubstitution(task, next_room.contents.distributeprefabs)

        local extra_contents, extra_tags = self:GetExtrasForRoom(next_room)

        local next_room_data = {
            type = next_room.entrance and NODE_TYPE.Blocker or next_room.type,
            task = next_room.task,
            name = next_room.name,
            colour = next_room.colour,
            value = next_room.value,
            internal_type = next_room.internal_type,
            tags = ArrayUnion(extra_tags, task.room_tags),
            custom_tiles = next_room.custom_tiles,
            custom_objects = next_room.custom_objects,
            terrain_contents = next_room.contents,
            terrain_contents_extra = extra_contents,
            terrain_filter = self.terrain.filter,
            entrance = next_room.entrance,
            required_prefabs = next_room.required_prefabs,
            random_node_exit_weight = next_room.random_node_exit_weight,
            random_node_entrance_weight = next_room.random_node_entrance_weight
        }

        local newNode = task_node:AddNode({
            id = next_room.id,
            data = next_room_data
        })

        newNode.sortID = roomID
        newNode.name = next_room.name
    end

    return task_node
end

function Story:GenerateRectangleNodes(taskset)
    if taskset == nil then return end

    -- Generate all the TERRAIN
    local task_nodes = {}
    for k, task in pairs(taskset) do
        assert(self.TERRAIN[task.id] == nil, "Cannot add the same task twice!")

        local task_node = self:GenerateRectangleNodesFromTask(task)
        self.TERRAIN[task.id] = task_node
        task_nodes[task.id] = task_node
    end

    return task_nodes
end

return BuildStory
