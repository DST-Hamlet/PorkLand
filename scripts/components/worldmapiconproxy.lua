return Class(function(self, inst)

    self.inst = inst

    local ismastersim = TheWorld.ismastersim
    local center_ents = {} -- {[K: ent]: true}
    local last_data_string = {} -- {[guid: number]: string}

    local bg = SpawnPrefab("pl_interior_minimap_bg") -- shelter center minimaps
    local client_minimap_room_ents = {} -- {[net_id: number]: Ent}
    local client_data = {} -- {[net_id: number]: Data}

    local client_minimap_door_ents = {} -- {[key: `${uuid}-${dir}`]: Ent}
    local client_visited_uuid = {} -- {[uuid: string]: true}

    local player_room_ent = SpawnPrefab("pl_interior_minimap_room_client") -- center, client ThePlayer only

    local minimap_type = nil -- "interior" | "exterior"

    local _activatedplayer = nil

    local function GetPlayerID()
        return _activatedplayer ~= nil and _activatedplayer.userid or ""
    end

    self.AddInteriorCenter = ismastersim and function(_, ent)
        assert(ent:HasTag("pl_interiorcenter"))
        center_ents[ent] = true
    end or function() end

    function self:RegisterInterior()
        --
    end

    function self:OnGetMapDataFromServer(message)
        local lines = {}
        for l in message:gmatch("[^\n]+")do
            table.insert(lines, l)
        end
        assert(#lines % 2 == 0, "data line numbers must be even")
        for i = 1, #lines/2 do
            local center = lines[i*2 - 1]
            local ents =  lines[i*2]
            local success, center, ents = pcall(function()
                return json.decode(center), json.decode(ents)
            end)
            if success then
                local id = center.net_id
                local pos = center.pos
                if ents == "" then
                    client_data[id] = nil
                else
                    client_data[id] = center
                    center.ents = ents
                end
            end
        end
    end

    function self:OnGetVisitedUUIDFromServer(message)
        local success, data = pcall(json.decode, message)
        if success and type(data) == "table" then
            client_visited_uuid = data
        end
    end

    local function OnPlayerActivated(_, player)
        _activatedplayer = player
        player.pl_changeinterior_handler = function(_, data)
            local ent = data.to
            if ent ~= nil and ent:HasInteriorMinimap() then
                bg:Render(true)
                --player_room_ent:Update()
                minimap_type = "interior"
            else
                bg:Render(false)
                player_room_ent:Render(false)
                minimap_type = "exterior"
            end
        end
        player:ListenForEvent("enterinterior", player.pl_changeinterior_handler)
        player:ListenForEvent("leaveinterior", player.pl_changeinterior_handler)
    end

    local function OnPlayerDeactivated(_, player)
        if _activatedplayer == player then
            _activatedplayer = nil
        end
        if player and player.pl_changeinterior_handler then
            player:RemoveEventCallback("enterinterior", player.pl_changeinterior_handler)
            player.pl_changeinterior_handler = nil
        end
    end

    inst:ListenForEvent("playeractivated", OnPlayerActivated, TheWorld)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated, TheWorld)

    local function CheckDirty(data)
        local guid = data.guid
        local s = json.encode(data.ents)
        local diff = last_data_string[guid] ~= s
        last_data_string[guid] = s
        return diff, s
    end

    self.OnUpdate = ismastersim and function()
        local temp = {}
        for ent in pairs(center_ents)do
            if not ent:IsValid() and ent.net_id ~= nil then
                center_ents[ent] = nil
                table.insert(temp, json.encode({
                    net_id = ent.net_id,
                    master_guid = nil,
                    pos = { 0, 0 },
                }))
                table.insert(temp, "\"\"") -- decode to empty string
            else
                local data = ent:CollectMinimapData()
                if data.no_minimap then
                    -- do nothing
                else
                    local diff, s = CheckDirty(data)
                    if diff then
                        table.insert(temp, json.encode({
                            net_id = data.net_id,
                            master_guid = data.guid,
                            interiorID = data.interiorID, -- for layout searching
                            width = data.width,
                            depth = data.depth,
                            world_pos_x = data.center.x,
                            world_pos_z = data.center.z,
                        }))
                        table.insert(temp, s)
                    end
                end
            end
        end
        if #temp ~= 0 then
            local message = table.concat(temp, "\n")
            local ids = {}
            for _,v in pairs(AllPlayers)do
                if v == _activatedplayer then
                    -- host in mastersim
                    self:OnGetMapDataFromServer(message)
                elseif v.userid ~= nil and v.userid ~= "" then
                    table.insert(ids, v.userid)
                end
            end
            if #ids > 0 then
                SendModRPCToClient(GetClientModRPC("PorkLand", "mapdata"), ids, TheSim:ZipAndEncodeString(message))
            end
        end

        -- layout
        if GetTick() % 2 == 0 then
            TheWorld.components.interiorspawner:BuildAllMinimapLayout()
            TheWorld.components.interiorspawner:SendMinimapLayoutData()
        end

        -- mapvisited
        for _,v in pairs(AllPlayers)do
            if v.components.interiorvisitor ~= nil and v:HasTag("inside_interior") then
                if v.userid ~= nil and v.userid ~= "" then
                    local message = json.encode(v.components.interiorvisitor.visited_uuid)
                    SendModRPCToClient(CLIENT_MOD_RPC["PorkLand"]["visited_uuid"], {v.userid}, message)
                end
                if v == _activatedplayer then
                    client_visited_uuid = v.components.interiorvisitor.visited_uuid
                end
            end
        end

        self:RenderInteriorMinimaps()

        ---  TODO: 对于新加入的其他玩家需要发送完整数据
    end or function()

        self:RenderInteriorMinimaps()
    end

    local function ApplyMinimapData(net_id)
        local ent = client_minimap_room_ents[net_id] or SpawnPrefab("pl_interior_minimap_room")
        client_minimap_room_ents[net_id] = ent
        ent:SetMinimapData(client_data[net_id])
        return ent
    end

    local DIR_VEC = {
        north = Vector3(-1, 0, 0),
        south = Vector3(1, 0, 0),
        east = Vector3(0, 0, 1),
        west = Vector3(0, 0, -1),
    }

    local function ShouldRender(uuid)
        if uuid == nil then
            return true
        elseif client_visited_uuid[uuid] then
            return true
        end
    end

    function self:RenderInteriorMinimaps()
        if TheNet:IsDedicated() then
            return
        end
        if _activatedplayer == nil then
            return
        end

        for _,v in pairs(client_minimap_room_ents)do
            v:Render(false)
        end
        for _,v in pairs(client_minimap_door_ents)do
            v:Render(false)
        end

        --player_room_ent:Update()

        local ent = _activatedplayer.replica.interiorvisitor:GetCenterEnt()
        local layout_map = TheWorld.components.interiorspawner.interior_layout_map
        -- TODO: ↑ 这里写的有点屎山，应当把所有地图相关逻辑放在本组件内

        if ent == nil then
            return
        end
        local id = ent.Network:GetNetworkID()
        -- print(ent, id)
        local current_id = id
        if client_data[id] == nil then
            return
        end

        local interiorID = client_data[id].interiorID
        local layout = interiorID
        for i = 1, 1000 do
            layout = layout_map[layout]
            if type(layout) == "table" or type(layout) == "nil" then
                break
            end
        end
        if type(layout) ~= "table" then
            -- should not happen, but go on anyway...
            ApplyMinimapData(id)
            -- c_forcecrash()
            return
        end

        local ent_list = {}
        local origin = nil

        for _,v in ipairs(layout)do
            local interiorID = v.interior_name
            local net_id = v.net_id
            local pos = Point(v.pos_x, 0, v.pos_z)
            local width = v.width
            local depth = v.depth
            local visited_players = v.visited_players
            local uuid = v.uuid
            local doors = v.doors
            if client_data[net_id] ~= nil and (ShouldRender(uuid) or v.force_visited) then
                -- render visited room
                local ent = ApplyMinimapData(net_id)
                ent.layout_pos = pos
                ent.grid_x = v.grid_x
                ent.grid_z = v.grid_z
                table.insert(ent_list, ent)
                for _,d in pairs(doors)do
                    local vec = d.dir ~= nil and DIR_VEC[d.dir]
                    if vec ~= nil then
                        local key = interiorID.."-door-"..d.dir
                        local icon = client_minimap_door_ents[key] or
                            SpawnPrefab("pl_interior_minimap_door")
                        client_minimap_door_ents[key] = icon
                        icon:SetDirection(d.dir)
                        icon.layout_pos = pos + Vector3(
                            vec.x * (depth + TUNING.INTERIOR_MINIMAP_DOOR_SPACE) / 2,
                            0,
                            vec.z * (width + TUNING.INTERIOR_MINIMAP_DOOR_SPACE) / 2)
                        table.insert(ent_list, icon)
                    end
                end
            else
                -- no render?
            end

            if net_id == current_id then
                origin = pos
            end
        end

        assert(origin ~= nil, "Failed to find origin in layout")
        for _,v in ipairs(ent_list)do
            local pos = (v.layout_pos - origin)* TUNING.INTERIOR_MINIMAP_POSITION_SCALE
            if math.abs(pos.x) + math.abs(pos.z) < .1 then
                -- 0, 0 --> skip, use room_client
                v:Render(false)
                -- player_room_ent:Update()
            else
                -- others --> render them
                v.Transform:SetPosition(pos:Get())
                v:Render(true)
            end
        end
    end

    function self:ShouldRemapPosition(player)
        if player == _activatedplayer then
            return minimap_type == "interior"
        elseif TheWorld.ismastersim then
            return true
        end
    end

    function self:RemapSoulhopPosition(player, pos, remapped)
        -- client action collector
        if player == _activatedplayer and not remapped then
            if minimap_type == "interior" then
                local center_data = nil
                local target_room = nil
                local offset = nil
                for _,v in pairs(client_minimap_room_ents)do
                    if v.render and v.minimap_data ~= nil then -- only teleport to visible room
                        local data = v.minimap_data
                        local room_pos = v:GetPosition()
                        if room_pos:LengthSq() < 4 then
                            center_data = {
                                grid_x = v.grid_x,
                                grid_z = v.grid_z,
                            }
                        end
                        if target_room == nil then
                            offset = (pos - room_pos)/TUNING.INTERIOR_MINIMAP_POSITION_SCALE
                            if math.abs(offset.z) < (data.width/2 - 1) and math.abs(offset.x) < (data.depth/2 - 1) then
                                target_room = v
                            end
                        end
                    end
                end
                if center_data and target_room then
                    -- Manhattan distance
                    local dist = math.abs(target_room.grid_x - center_data.grid_x) + math.abs(target_room.grid_z - center_data.grid_z)
                    local consume = math.max(1, math.ceil(dist / 2))
                    local world_pos = Point(
                        target_room.minimap_data.world_pos_x + offset.x,
                        0,
                        target_room.minimap_data.world_pos_z + offset.z)

                    local act_data = {
                        maxsouls = TUNING.WORTOX_MAX_SOULS,
                        distancemod = 0,
                        distanceperhop = 0,
                        distancefloat = consume,
                        distancecount = consume,
                        aimassisted = false,
                        is_remapped = true,
                    }
                    return world_pos, { type = "interior", data = act_data}
                end
            else
                return pos, { type = "exterior" }
            end
        elseif TheWorld.ismastersim then
            -- server remap (only calculate soul cost)
            local x, _, z = player.Transform:GetWorldPosition()
            local room1 = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
            local x, _, z = pos:Get()
            local room2 = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)

            if room1 and room1.grid_x and room1.grid_z
                and room2 and room2.grid_x and room2.grid_z then
                -- Manhattan distance
                local dist = math.abs(room1.grid_x - room2.grid_x) + math.abs(room1.grid_z - room2.grid_z)
                local consume = math.max(1, math.ceil(dist / 2))

                local act_data = {
                    maxsouls = TUNING.WORTOX_MAX_SOULS,
                    distancemod = 0,
                    distanceperhop = 0,
                    distancefloat = consume,
                    distancecount = consume,
                    aimassisted = false,
                }
                return pos, { type = "interior", data = act_data }
            end
        end
    end

    --inst:StartUpdatingComponent(self)

    end)
