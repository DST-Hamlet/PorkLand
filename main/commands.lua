GLOBAL.setfenv(1, GLOBAL)

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
