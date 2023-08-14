-- hack storygen functions is very trouble, so we rewrite it  -- Jerry
require("map/storygen")

local AddMapTag = require("map/addmaptags")

function Story:PorkLandRestrictNodesByKey(startParentNode, unusedTasks)
    local lastNode = startParentNode
        print("Startparent node:",startParentNode.id)
    local usedTasks = {}
    usedTasks[startParentNode.id] = startParentNode
    startParentNode.story_depth = 0
    local story_depth = 1
    local currentNode = nil

    local last_parent = 1 -- this is a desperate attempt to distribute the nodes better

    local function FindAttachNodes(taskid, node, target_tasks)

        local unlockingNodes = {}

        for target_taskid, target_node in pairs(target_tasks) do

            local locks = {}
            for i,v in ipairs(self.tasks[taskid].locks) do
                local lock = {keys=LOCKS_KEYS[v], unlocked = false}
                locks[v] = lock
            end

            local availableKeys = {} --What are we allowed to connect to this task?

            for i, v in ipairs(self.tasks[target_taskid].keys_given) do --Get the keys that the last area we generated gives
                availableKeys[v] = {}
                table.insert(availableKeys[v], target_node)
            end

            for lock, lockData in pairs(locks) do                         --For each lock:
                for key, keyNodes in pairs(availableKeys) do             --Do we have a key...
                    for reqKeyIdx, reqKey in ipairs(lockData.keys) do     --...for this lock?
                        if reqKey == key then                             --If yes, get the nodes
                            lockData.unlocked = true                     --Unlock the lock.
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

            local lowest = {i = 999, node = nil}
            local highest = {i = -1, node = nil}
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

            if self.gen_params.branching == nil or self.gen_params.branching == "default" then
                last_parent = ((last_parent-1) % GetTableSize(parents)) + 1
                local parent_i = 1
                for k,v in pairs(parents) do
                    if parent_i < last_parent then
                        parent_i = parent_i + 1
                    else
                        last_parent = last_parent + 1
                        effectiveLastNode = v
                        break
                    end
                end
            elseif self.gen_params.branching == "most" then
                effectiveLastNode = lowest.node
            elseif self.gen_params.branching == "least" then
                effectiveLastNode = highest.node
            elseif self.gen_params.branching == "never" then
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

            if self.gen_params.island_percent ~= nil
                and self.gen_params.island_percent >= math.random()
                and currentNodeEntrance.data.entrance == false then
                self:SeperateStoryByBlanks(lastNodeExit, currentNodeEntrance)
            else
                self.rootNode:LockGraph(effectiveLastNode.id..'->'..currentNode.id, lastNodeExit, currentNodeEntrance, {type = "none", key = self.tasks[currentNode.id].locks, node = nil})
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
            AppendNode( self:GetRandomNodeFromTasks(unusedTasks), usedTasks )
        else
            for taskid, unlockingNodes in pairs(candidateTasks) do
                AppendNode(unusedTasks[taskid], unlockingNodes)
            end
        end
    end

    return lastNode:GetRandomNode()
end

local function BuildPorkLandStory(tasks, story_gen_params, level)
    print("Building PorkLand Story", tasks)

    local story = Story("GAME", tasks, terrain, story_gen_params, level)
    AddMapTag(story.map_tags)
    story:IA_GenerateNodesFromTasks(story.PorkLandRestrictNodesByKey)

    local world_size = 0
    if story_gen_params.world_size == "medium" then
        world_size = 1
    elseif story_gen_params.world_size == "large" or story_gen_params.world_size == "default" then
        world_size = 2
    elseif story_gen_params.world_size == "huge" then
        world_size = 3
    end

    local min_bg = (level.background_node_range and level.background_node_range[1] or 0) + world_size
    local max_bg = (level.background_node_range and level.background_node_range[2] or 2) + world_size

    story:IA_AddBGNodes(min_bg, max_bg)
    story:IA_InsertAdditionalSetPieces()
    story:IA_PlaceTeleportatoParts()

    return {root = story.rootNode, startNode = story.startNode, GlobalTags = story.GlobalTags, water = story.water_content}, story
end

return BuildPorkLandStory
