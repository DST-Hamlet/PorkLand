GLOBAL.setfenv(1, GLOBAL)

function c_settile(tile)
    tile = tile == nil and WORLD_TILES.QUAGMIRE_SOIL or
            type(tile) == "string" and WORLD_TILES[string.upper(tile)]
            or tile

    local x, y, z = TheInput:GetWorldPosition():Get()
    local coords_x, coords_y = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    TheWorld.Map:SetTile(coords_x, coords_y, tile)
end


function c_checktile()
    local player = ConsoleCommandPlayer()
    if player then
        local x, y, z = player.Transform:GetLocalPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)

        for tile_name, num  in pairs(WORLD_TILES) do
            if tile == num then
                print(tile_name, num)
                break
            end
        end
    end
end

function c_poison()
    local inst = c_select()
    if inst and inst.components.poisonable then
        if inst.components.poisonable:IsPoisoned() then
            inst.components.poisonable:DonePoisoning()
        else
            inst.components.poisonable:Poison()
        end
    end
end

function c_gotostate(state)
    local player = ConsoleCommandPlayer()
    if type(state) == "string" then
        player.sg:GoToState(state)
    end
end

function c_characterembark(boat_prefab)
    local x, y, z = TheInput:GetWorldPosition():Get()
    local wilson = SpawnPrefab("wilson")
    wilson.Transform:SetPosition(x, y, z)
    local boat = SpawnPrefab(boat_prefab or "boat_lograft")
    boat.Transform:SetPosition(x, y, z)
    wilson.components.sailor:Embark(boat)
end

function c_reseterror()
    TheSim:ResetError()
    c_reset()
end
