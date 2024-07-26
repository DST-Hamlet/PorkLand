-- hack storygen functions is very trouble, so we rewrite it  -- Jerry
require("map/storygen")
local AddPlMaptags = require("map/pl_map_tags")
local TaskRegionMap = require("map/task_region_map")

local function RestrictNodesByKey(story, startParentNode, unusedTasks)
    local lastNode = startParentNode
    print("Startparent node:", startParentNode.id)
    local usedTasks = {}
    usedTasks[startParentNode.id] = startParentNode
    startParentNode.story_depth = 0
    local story_depth = 1
    local currentNode = nil

    local last_parent = 1  -- this is a desperate attempt to distribute the nodes better

    local function FindAttachNodes(taskid, node, target_tasks)
        local unlockingNodes = {}

        for target_taskid, target_node in pairs(target_tasks) do
            local locks = {}
            for i, v in ipairs(story.tasks[taskid].locks) do
                local lock = { keys = LOCKS_KEYS[v], unlocked = false }
                locks[v] = lock
            end

            local availableKeys = {}  -- What are we allowed to connect to this task?

            for i, v in ipairs(story.tasks[target_taskid].keys_given) do  -- Get the keys that the last area we generated gives
                availableKeys[v] = {}
                table.insert(availableKeys[v], target_node)
            end

            for lock, lockData in pairs(locks) do                     -- For each lock:
                for key, keyNodes in pairs(availableKeys) do          -- Do we have a key...
                    for reqKeyIdx, reqKey in ipairs(lockData.keys) do -- ...for this lock?
                        if reqKey == key then                         -- If yes, get the nodes
                            lockData.unlocked = true                  -- Unlock the lock.
                        end
                    end
                end
            end

            local unlocked = true
            for lock, lockData in pairs(locks) do
                if lockData.unlocked == false then
                    unlocked = false
                    break
                end
            end

            if unlocked then
                unlockingNodes[target_taskid] = target_node
            else
            end
        end

        return unlockingNodes
    end

    while GetTableSize(unusedTasks) > 0 do
        local effectiveLastNode = lastNode

        local candidateTasks = {}


        for taskid, node in pairs(unusedTasks) do
            local unlockingNodes = FindAttachNodes(taskid, node, usedTasks)

            if GetTableSize(unlockingNodes) > 0 then
                candidateTasks[taskid] = unlockingNodes
            end
        end

        local function AppendNode(in_node, parents)
            currentNode = in_node

            local lowest = { i = 999, node = nil }
            local highest = { i = -1, node = nil }
            for id, node in pairs(parents) do
                if node.story_depth >= highest.i then
                    highest.i = node.story_depth
                    highest.node = node
                end
                if node.story_depth < lowest.i then
                    lowest.i = node.story_depth
                    lowest.node = node
                end
            end

            if story.gen_params.branching == nil or story.gen_params.branching == "default" then
                last_parent = ((last_parent - 1) % GetTableSize(parents)) + 1
                local parent_i = 1
                for k, v in pairs(parents) do
                    if parent_i < last_parent then
                        parent_i = parent_i + 1
                    else
                        last_parent = last_parent + 1
                        effectiveLastNode = v
                        break
                    end
                end
            elseif story.gen_params.branching == "most" then
                effectiveLastNode = lowest.node
            elseif story.gen_params.branching == "least" then
                effectiveLastNode = highest.node
            elseif story.gen_params.branching == "never" then
                effectiveLastNode = lastNode
            end

            currentNode.story_depth = story_depth
            story_depth = story_depth + 1

            local lastNodeExit = effectiveLastNode:GetRandomNode()
            local currentNodeEntrance = currentNode:GetRandomNode()
            if currentNode.entrancenode then
                currentNodeEntrance = currentNode.entrancenode
            end

            assert(lastNodeExit)
            assert(currentNodeEntrance)

            if story.gen_params.island_percent ~= nil
                and story.gen_params.island_percent >= math.random()
                and currentNodeEntrance.data.entrance == false then
                    story:SeperateStoryByBlanks(lastNodeExit, currentNodeEntrance)
            else
                story.rootNode:LockGraph(effectiveLastNode.id .. '->' .. currentNode.id, lastNodeExit, currentNodeEntrance,
                    { type = "none", key = story.tasks[currentNode.id].locks, node = nil })
            end

            -- print_lockandkey_ex("\t\tAdding keys to keyring:")
            -- for i,v in ipairs(self.tasks[currentNode.id].keys_given) do
            --     if availableKeys[v] == nil then
            --         availableKeys[v] = {}
            --     end
            --     table.insert(availableKeys[v], currentNode)
            --     print_lockandkey_ex("\t\t",KEYS_ARRAY[v])
            -- end

            unusedTasks[currentNode.id] = nil
            usedTasks[currentNode.id] = currentNode
            lastNode = currentNode
            currentNode = nil
        end

        if next(candidateTasks) == nil then
            AppendNode(story:GetRandomNodeFromTasks(unusedTasks), usedTasks)
        else
            for taskid, unlockingNodes in pairs(candidateTasks) do
                AppendNode(unusedTasks[taskid], unlockingNodes)
            end
        end
    end

    return lastNode:GetRandomNode()
end

function Story:GenerateNodesForIsland(taskSet, linkFn)
    local taskNodes = {}
    for _, task in pairs(taskSet) do
        local task_node = self:GenerateNodesFromTask(task, task.crosslink_factor or 1) -- 0.5)
        self.TERRAIN[task.id] = task_node
        taskNodes[task.id] = task_node
    end

    local startingTask = self:_FindStartingTask(taskNodes)
    taskNodes[startingTask.id] = nil

    local entranceNode = startingTask:GetRandomNodeForEntrance()
    local finalNode = linkFn(self, startingTask, taskNodes)

    return {startingTask = startingTask, entranceNode = entranceNode, finalNode = finalNode, taskNodes = taskNodes}
end

function Story:Pl_InsertAdditionalSetPieces(task_nodes)
    local obj_layout = require("map/object_layout")

    local function is_water_ok(room, layout)
        local water_room = room.data.type == "water" or IsOceanTile(room.data.value)
        local water_layout = layout and layout.water == true
        return (water_room and water_layout) or (not water_room and not water_layout)
    end
    local function is_target_tile(room, layout)
        local tile = room.data.value ~= nil and room.data.value
        local need_tiles = layout and layout.only_in_tiles
        if need_tiles == nil then
            return true
        end
        local has_target_tile = false
        for i, v in ipairs(need_tiles) do
            if v == tile then
                has_target_tile = true
            end
        end
        return has_target_tile
    end

    local tasks = task_nodes or self.rootNode:GetChildren()
    for id, task in pairs(tasks) do
        if task.set_pieces ~= nil and #task.set_pieces > 0 then
            for i, setpiece_data in ipairs(task.set_pieces) do
                local is_entrance = function(room)
                    -- return true if the room is an entrance
                    return room.data.entrance ~= nil and room.data.entrance == true
                end
                local is_background_ok = function(room)
                    -- return true if the piece is not backround restricted, or if it is but we are on a background
                    return setpiece_data.restrict_to ~= "background" or room.data.type == "background"
                end
                local isnt_blank = function(room)
                    return room.data.type ~= "blank" and not TileGroupManager:IsImpassableTile(room.data.value)
                end

                local layout = obj_layout.LayoutForDefinition(setpiece_data.name)
                local choicekeys = shuffledKeys(task.nodes)
                local choice = nil
                for _, choicekey in ipairs(choicekeys) do
                    if not is_entrance(task.nodes[choicekey]) and is_background_ok(task.nodes[choicekey]) and is_water_ok(task.nodes[choicekey], layout) and isnt_blank(task.nodes[choicekey]) and is_target_tile(task.nodes[choicekey], layout) then
                        choice = choicekey
                        break
                    end
                end

                if choice == nil then
                    print("Warning! Couldn't find a spot in " .. task.id .. " for " .. setpiece_data.name)
                    break
                end

                -- print("Placing " .. setpiece_data.name .. " in " .. task.id .. ":" .. task.nodes[choice].id)

                if task.nodes[choice].data.terrain_contents.countstaticlayouts == nil then
                    task.nodes[choice].data.terrain_contents.countstaticlayouts = {}
                end
                -- print ("Set peice", name, choice, room_choices._et[choice].contents, room_choices._et[choice].contents.countstaticlayouts[name])
                task.nodes[choice].data.terrain_contents.countstaticlayouts[setpiece_data.name] = 1
            end
        end
        if task.random_set_pieces ~= nil and #task.random_set_pieces > 0 then
            for k, setpiece_name in ipairs(task.random_set_pieces) do
                local layout = obj_layout.LayoutForDefinition(setpiece_name)
                local choicekeys = shuffledKeys(task.nodes)
                local choice = nil
                for i, choicekey in ipairs(choicekeys) do
                    local is_entrance = function(room)
                        -- return true if the room is an entrance
                        return room.data.entrance ~= nil and room.data.entrance == true
                    end
                    local isnt_blank = function(room)
                        return room.data.type ~= "blank"
                    end

                    if not is_entrance(task.nodes[choicekey]) and isnt_blank(task.nodes[choicekey]) and is_water_ok(task.nodes[choicekey], layout) and is_target_tile(task.nodes[choicekey], layout) then
                        choice = choicekey
                        break
                    end
                end

                if choice == nil then
                    print("Warning! Couldn't find a spot in " .. task.id .. " for " .. setpiece_name)
                    break
                end

                -- print("Placing " .. setpiece_data.name .. " in " .. task.id .. ":" .. task.nodes[choice].id)

                if task.nodes[choice].data.terrain_contents.countstaticlayouts == nil then
                    task.nodes[choice].data.terrain_contents.countstaticlayouts = {}
                end
                -- print ("Set peice", name, choice, room_choices._et[choice].contents, room_choices._et[choice].contents.countstaticlayouts[name])
                task.nodes[choice].data.terrain_contents.countstaticlayouts[setpiece_name] = 1
            end
        end
    end
end

function Story:AddIslandToPorkland(on_region_added_fn)
    for region_id, region_taskset in pairs(self.region_tasksets) do
        if region_id ~= "A" then
            local c1, c2 = self:FindMainlandNodesForNewRegion()
            local new_island = self:GenerateNodesForRegion(region_taskset, "RestrictNodesByKey")

            local new_task_nodes = {}
            for k, v in pairs(region_taskset) do
                new_task_nodes[k] = self.TERRAIN[k]
            end

            if region_id ~= "E" then
                self:AddBGNodes(self.min_bg, self.max_bg, new_task_nodes)
            end
            -- self:AddCoveNodes(new_task_nodes)
            self:Pl_InsertAdditionalSetPieces(new_task_nodes)

            self:LinkRegions(c1, new_island.entranceNode)
            self:LinkRegions(c2, new_island.finalNode)

            if on_region_added_fn ~= nil then
                on_region_added_fn(region_id)
            end
        end
    end
end

local function BuildPorkLandStory(tasks, story_gen_params, level)
    print("Building PorkLand Story", tasks)

    local story = Story("GAME", tasks, terrain, story_gen_params, level)
    story.region_tasksets = {}
    for task_id, task in pairs(story.tasks) do
        local region = TaskRegionMap[task_id]
        story.region_tasksets[region] = story.region_tasksets[region] or {}
        story.region_tasksets[region][task_id] = task
    end
    AddPlMaptags(story.map_tags)

    local world_size = 0
    if story_gen_params.world_size == "medium" then
        world_size = 1
    elseif story_gen_params.world_size == "large" or story_gen_params.world_size == "default" then
        world_size = 2
    elseif story_gen_params.world_size == "huge" then
        world_size = 3
    end

    story.min_bg = (level.background_node_range and level.background_node_range[1] or 0) + world_size
    story.max_bg = (level.background_node_range and level.background_node_range[2] or 2) + world_size

    local g = story:GenerateNodesForRegion(story.region_tasksets["A"], "RestrictNodesByKey")

    story.main_task_nodes = g.taskNodes
    story.startNode = story:_AddPlayerStartNode(g)
    story:AddBGNodes(story.min_bg, story.max_bg)
    story:Pl_InsertAdditionalSetPieces()
    -- story:Pl_PlaceTeleportatoParts()

    return { root = story.rootNode, startNode = story.startNode, GlobalTags = story.GlobalTags }, story
end

return BuildPorkLandStory
