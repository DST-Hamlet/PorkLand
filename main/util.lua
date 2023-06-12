modimport("main/tileutil")
GLOBAL.setfenv(1, GLOBAL)

function GetWorldSetting(setting, default)
    local worldsettings = TheWorld and TheWorld.components.worldsettings
    if worldsettings then
        return worldsettings:GetSetting(setting)
    end
    return default
end

--Waves Util
-- Store the globals for optimization
local IA_OCEAN_PREFABS = IA_OCEAN_PREFABS
local DST_OCEAN_PREFABS = DST_OCEAN_PREFABS

local WAVE_SPAWN_DISTANCE = 1.5
local _SpawnAttackWaves = SpawnAttackWaves
function SpawnAttackWaves(position, rotation, spawn_radius, numWaves, totalAngle, waveSpeed, wavePrefab, idleTime, instantActive, ...)
    if TheWorld.has_ia_ocean then
        wavePrefab = IA_OCEAN_PREFABS[wavePrefab] or wavePrefab
        wavePrefab = wavePrefab or "wave_rogue"
    else
        wavePrefab = DST_OCEAN_PREFABS[wavePrefab] or wavePrefab
        wavePrefab = wavePrefab or "wave_med"
    end

    if wavePrefab ~= "wave_ripple" and wavePrefab ~= "wave_rogue" then
        return _SpawnAttackWaves(position, rotation, spawn_radius, numWaves, totalAngle, waveSpeed, wavePrefab, idleTime, instantActive, ...)
    end


    waveSpeed = waveSpeed or 6
    idleTime = idleTime or 5
    totalAngle = (numWaves == 1 and 0) or
            (totalAngle and (totalAngle % 361)) or
            360

    local anglePerWave = (totalAngle == 0 and 0) or
            (totalAngle == 360 and totalAngle/numWaves) or
            totalAngle/(numWaves - 1)

    local startAngle = rotation or math.random(-180, 180)
    local total_rad = (spawn_radius or 0.0) + WAVE_SPAWN_DISTANCE

    local wave_spawned = false
    for i = 0, numWaves - 1 do
        local angle = (startAngle - (totalAngle/2)) + (i * anglePerWave)
        local offset_direction = Vector3(math.cos(angle*DEGREES), 0, -math.sin(angle*DEGREES)):Normalize()
        local wavepos = position + (offset_direction * total_rad)

        if not TheWorld.Map:IsPassableAtPoint(wavepos:Get()) then
            wave_spawned = true

            local wave = SpawnPrefab(wavePrefab)
            wave.Transform:SetPosition(wavepos:Get())
            wave.Transform:SetRotation(angle)
            if type(waveSpeed) == "table" then
                wave.Physics:SetMotorVel(waveSpeed[1], waveSpeed[2], waveSpeed[3])
            else
                wave.Physics:SetMotorVel(waveSpeed, 0, 0)
            end
            wave.idle_time = idleTime

            -- Ugh just because of the next two blocks I had to hopy and paste all this -_- -Half
            if instantActive then
                wave.sg:GoToState("idle")
            end

            if wave.soundtidal then
                wave.SoundEmitter:PlaySound(wave.soundtidal)
            end
        end
    end

    -- Let our caller know if we actually spawned at least 1 wave.
    return wave_spawned
end

function SpawnWaves(inst, numWaves, totalAngle, waveSpeed, wavePrefab, initialOffset, idleTime, instantActive, random_angle)
    return SpawnAttackWaves(inst:GetPosition(), (random_angle and math.random(-180, 180)) or inst.Transform:GetRotation(), initialOffset or (inst.Physics and inst.Physics:GetRadius()) or 0.0, numWaves, totalAngle, waveSpeed, wavePrefab or "wave_med",  idleTime or 5, instantActive)
end

function IsPositionValidForEnt(inst, radius_check)
    return function(pt)
        return inst:IsAmphibious()
            or (inst:IsAquatic() and not inst:GetIsCloseToLand(radius_check, pt))
            or (inst:IsTerrestrial() and not inst:GetIsCloseToWater(radius_check, pt))
    end
end

--Climate Util

local function MakeTestFn(climate, countneutral)
    local climatetiles = CLIMATE_TURFS[string.upper(climate)]
    return function(tile)
        return (climatetiles and climatetiles[tile]) or (countneutral and CLIMATE_TURFS.NEUTRAL[tile])
    end
end

local function TestTurfs(pt, testfn)
    if pt then
        local num = 0
        local srcx, srcy = TheWorld.Map:GetTileCoordsAtPoint(pt:Get())
        for tilex = srcx - 2, srcx + 2, 2 do
            for tiley = srcy - 2, srcy + 2, 2 do
                local tile = TheWorld.Map:GetOriginalTile(tilex, tiley)
                if testfn(tile) then
                    num = num + 1 --no tile is pretty neutral to me
                    if tilex == 0 and tiley == 0 then
                        num = num + 1 --add extra weight to current tile -M
                    end
                end
            end
        end
        return num > 5 --more than half
    end
end

local function TestRoom(inst, pt, climate)
	if CLIMATE_ROOMS[string.upper(climate)] then
		if not TheWorld.Map:IsPassableAtPoint(pt.x, 0, pt.z) then
			return
		end
		-- print("TestRoom",inst)
		local roomid
		-- if inst and not inst.components.areaaware and (inst.components.locomotor or inst.components.inventoryitem or TheWorld.Map:GetPlatformAtPoint(pt.x, 0, pt.z) ~= nil)) then
			-- inst:AddComponent("areaaware") --make sure moving stuff updates more efficiently (then again, areaaware updates position every tick...)
		-- end
		if inst and inst.components.areaaware and inst.components.areaaware:GetCurrentArea() then
			roomid = inst.components.areaaware:GetCurrentArea().id
		else
			for i, node in ipairs(TheWorld.topology.nodes) do
				if TheSim:WorldPointInPoly(pt.x, pt.z, node.poly) then
					roomid = TheWorld.topology.ids[i]
					break
				end
			end
		end
		if roomid then
			-- if inst and inst:HasTag("player") then print("IN ROOM",roomid) end
			for _, v in pairs(CLIMATE_ROOMS[string.upper(climate)]) do
				if string.find(roomid, v) then
					-- if inst and inst:HasTag("player") then print("ROOM IS",climate) end
					return true
				end
			end
		end
	end
end

local function RoomHasTag(inst, pt, roomtag)
	-- if not TheWorld.Map:IsPassableAtPoint(pt.x, 0, pt.z) then
		-- return false
	-- end
	if inst and inst.components.areaaware and inst.components.areaaware:GetCurrentArea() then
		return inst.components.areaaware:CurrentlyInTag(roomtag)
	end
	for i, node in ipairs(TheWorld.topology.nodes) do
		if TheSim:WorldPointInPoly(pt.x, pt.z, node.poly) then
			return table.contains(node.tags, roomtag)
		end
	end
end

function CalculateClimate(inst, pt, neutralclimate)
	if inst then
        if not inst:IsValid() then
            -- print(inst.prefab.." is not valid, IA climate can't be checked.")
        end
		pt = inst:GetPosition()
	end
	local validclimates = {}
	for i, v in ipairs(CLIMATES) do
		if TheWorld:HasTag(v) then
			validclimates[#validclimates + 1] = v
		end
	end

	if #validclimates == 1 then
		return CLIMATE_IDS[validclimates[1]]
	else
		local _climate
		for i = 2, #validclimates, 1 do
			local climate = validclimates[i]
			if (TheWorld.topology and TheWorld.topology.ia_worldgen_version)
			--hardcoding like yeah B^)  -M
			and ((climate == "island" and (IsOnWater(inst or pt) or RoomHasTag(inst, pt, "islandclimate")))
				or (climate == "volcano" and RoomHasTag(inst, pt, "volcanoclimate")))
			or not (TheWorld.topology and TheWorld.topology.ia_worldgen_version)
			--Should the MakeTestFn functions get cached? -M
			and (TestRoom(inst, pt, climate) or TestTurfs(pt, MakeTestFn(climate, neutralclimate and (climate == CLIMATES[neutralclimate])))) then
				-- print("CALC CLIMATE FOR ", inst or pt, climate)
				return CLIMATE_IDS[climate]
			end
		end
		-- print("CALC CLIMATE FAILED ", inst or pt)
		return CLIMATE_IDS[validclimates[1]]
	end

	--failed, just guess based on the world tags
	-- return TheWorld:HasTag("forest") and CLIMATE_IDS.forest or TheWorld:HasTag("cave") and CLIMATE_IDS.cave or CLIMATE_IDS.forest
end

function GetClimate(inst, forceupdate, neutralclimate)
	if not inst or type(inst) ~= "table" then print("Invalid use of GetClimate", inst) print(debugstack()) return CLIMATE_IDS.forest end
    if TheWorld.ismastersim then
		if inst.is_a and inst:is_a(EntityScript) then
            if inst.prefab ~= nil then
    			if not inst.components.climatetracker then
    				inst:AddComponent("climatetracker")
    			end
    			return inst.components.climatetracker:GetClimate(forceupdate)
            else
                return CalculateClimate(inst, nil, neutralclimate)
            end
		elseif inst.is_a and inst:is_a(Vector3) then
			return CalculateClimate(nil, inst, neutralclimate)
		end
    else
        if inst.player_classified then
            return inst.player_classified._climate:value()
        elseif inst.is_a and inst:is_a(EntityScript) then
			if not forceupdate then
				for i, v in ipairs(CLIMATES) do
					if inst:HasTag("Climate_"..v) then
						return i
					end
				end
			end
			--failed, probably has no climatetracker, resort to CalculateClimate
			return CalculateClimate(inst, nil, neutralclimate)
		elseif inst.is_a and inst:is_a(Vector3) then
			return CalculateClimate(nil, inst, neutralclimate)
		end
    end
end

--
-- Is Climate --
function IsDSTClimate(climate)
    return climate == CLIMATE_IDS.forest or climate == CLIMATE_IDS.cave or climate == nil
end

function IsIAClimate(climate)
    return climate == CLIMATE_IDS.island or climate == CLIMATE_IDS.volcano
end

function IsPLClimate(climate)
    return climate == CLIMATE_IDS.porkland
end

function IsClimate(climate, target_climate)
    return CLIMATES[climate] == target_climate
end
-- In Climate --
function IsInDSTClimate(inst, forceupdate)
    local climate = GetClimate(inst, forceupdate)
    return IsDSTClimate(climate)
end

function IsInIAClimate(inst, forceupdate)
    local climate = GetClimate(inst, forceupdate)
    return IsIAClimate(climate)
end

function IsInPLClimate(inst, forceupdate)
    local climate = GetClimate(inst, forceupdate)
    return IsPLClimate(climate)
end

function IsInClimate(inst, climate, forceupdate, neutralclimate)
    return CLIMATES[GetClimate(inst, forceupdate, neutralclimate)] == climate
end
--

--End of Climate Util