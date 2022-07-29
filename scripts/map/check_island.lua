local worldtiles = {}
local function Within(x, y, radius, tile)
    local direction = 0
	for i = 1, radius do
		if not worldtiles[y] then
			break
		elseif worldtiles[y][x + i] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y] then
			break
		elseif worldtiles[y][x - i] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y + i] then
			break
		elseif worldtiles[y + i][x] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y - i] then
			break
		elseif worldtiles[y - i][x] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y + i] then
			break
		elseif worldtiles[y + i][x + i] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y + i] then
			break
		elseif worldtiles[y + i][x - i] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y - i] then
			break
		elseif worldtiles[y - i][x + i] == tile then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if not worldtiles[y - i] then
			break
		elseif worldtiles[y - i][x - i] == tile then
			direction = direction + 1
			break
		end
	end

    return direction == 8
end

local function IsClose(x, y, radius, tile)
	for i = -radius, radius, 1 do
		if worldtiles[y + i][x - radius] == tile or worldtiles[y + i][x + radius] == tile then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if worldtiles[y - radius][x + i] == tile or worldtiles[y + radius][x + i] == tile then
			return true
		end
	end
	return false
end

local function GetLinkEdage(x, y)
    worldtiles[y][x] = nil
	for i = x - 2, x + 2 do
		for j = y - 2, y + 2 do
			if worldtiles[j][i] == "edge" then
				GetLinkEdage(i, j)
			end
		end
	end
end

local function GetIslandCount(width, height)
	-- get simple table
    for y = 5, height - 5, 1 do
		worldtiles[y] = {}
        for x = 5, width - 5, 1 do
            if WithinTile(x, y, 30, IsLandTile) then
				worldtiles[y][x] = "tile"
			else
				worldtiles[y][x] = "impassible"
            end
        end
    end

	-- fill island  cavity, in case
    for y = 5, height - 5, 1 do
        for x = 5, width - 5, 1 do
            if worldtiles[y][x] == "impassible" and Within(x, y, 50, "tile") then
                worldtiles[y][x] = "tile"
            end
        end
    end

	-- get island edge
    for y = 10, height - 10, 1 do
        for x = 10, width - 10, 1 do
            if worldtiles[y][x] ~= "tile" and IsClose(x, y, 1, "tile") then
				worldtiles[y][x] = "edge"
            end
        end
    end

	-- count island num by edge
    local island_count = 0
    for y = 10, height - 10, 1 do
        for x = 10, width - 10, 1 do
			if worldtiles[y][x] == "edge" then
				GetLinkEdage(x, y)
				island_count = island_count + 1
			end
        end
    end
	return island_count
end

return GetIslandCount