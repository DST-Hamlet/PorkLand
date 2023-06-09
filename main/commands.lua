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

function c_allplayerrevealmap()
	local size = 2 * TheWorld.Map:GetSize()
	for _, player in pairs(AllPlayers) do
		for x = -size, size, 32 do
			for z = -size, size, 32 do
				player.player_classified.MapExplorer:RevealArea(x, 0, z)
			end
		end
	end
end

function c_revealmap()
	local size = 2 * TheWorld.Map:GetSize()
    local player = ConsoleCommandPlayer()
    if player ~= nil then
        for x = -size, size, 32 do
            for z = -size, size, 32 do
                player.player_classified.MapExplorer:RevealArea(x, 0, z)
            end
        end
    end
end
