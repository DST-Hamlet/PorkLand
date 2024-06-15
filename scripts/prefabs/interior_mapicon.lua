local function bg()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(false)
    inst.MiniMapEntity:SetIsProxy(true)
	inst.MiniMapEntity:SetIcon("pl_black_bg.tex")
	inst.MiniMapEntity:SetPriority(TUNING.INTERIOR_MINIMAP_PRIORITY_START)

	inst.entity:SetCanSleep(false)

	inst.persists = false

    inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")

	return inst
end

local function Render(inst, value)
	for _, v in ipairs(inst.tiles) do
		v.MiniMapEntity:SetEnabled(value)
	end
end

local function bg_group()
	local inst = CreateEntity()

	inst.entity:AddTransform()

	local tiles = {}
	for i = -20, 20 do
		for j = -20, 20 do
			local v = bg()
			v.Transform:SetPosition(i * 50, 0, j * 50)
			v:ListenForEvent("onremove", function() v:Remove() end, inst)
			table.insert(tiles, v)
		end
	end

	inst.tiles = tiles
	inst.persists = false

	inst:AddTag("NOBLOCK")

	inst.Render = Render
	inst:Render(false)

	return inst
end

local function fg_group()
	local inst = CreateEntity()

    inst.entity:AddTransform()

	local tiles = {}
	for i = 0, 20 do
		for j = 0, 20 do
			local v = bg()
			v.Transform:SetPosition(i * 50, 0, j * 50)
			v:ListenForEvent("onremove", function() v:Remove() end, inst)
			v.entity:SetParent(inst.entity)
			table.insert(tiles, v)
		end
	end

	inst.tiles = tiles
	inst.persists = false

    inst:AddTag("NOBLOCK")

	inst.Render = Render
	inst:Render(true)

	return inst
end

local function local_icon()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetIsProxy(true)

	inst.entity:SetCanSleep(false)

	inst.persists = false

	inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")

	return inst
end

local FRAME_OFFSET = 1
local DOOR_OFFSET = 5
local ITEM_OFFSET = 10

local POSITION_SCALE = TUNING.INTERIOR_MINIMAP_POSITION_SCALE

local function SizeToString(width, depth)
	if width == 15 and depth == 10
		or width == 18 and depth == 12
		or width == 24 and depth == 16
		or width == 26 and depth == 18 then
		return width.."x"..depth
	else
		return SizeToString(18, 12) -- default (not recommended)
	end
end

-- TODO: 需要大量房间的性能测试
local function SetMinimapData(inst, data)
	inst.minimap_data = data

	inst.MiniMapEntity:SetIcon("pl_frame_" .. SizeToString(data.width, data.depth) .. ".tex")
	inst.MiniMapEntity:SetEnabled(true)

	-- TODO: support priority
	-- "ents":{"vamp_cave_burrow.png":[[0,0]],"winona.png":[[-7.5001220703125,0]],"vamp_bat_cave_exit.png":[[-9,0]],"stalagmite_tall.png":[[-2.5570068359375,3.3013305664062]]},"pos":[986,906]}
	for icon, pos_list in pairs(data.ents)do
		if inst.icons[icon] == nil then
			inst.icons[icon] = {}
		end
		local ent_list = inst.icons[icon]
		for i, pos in ipairs(pos_list)do
			if ent_list[i] == nil then
				ent_list[i] = local_icon()
				ent_list[i].entity:SetParent(inst.entity)
			end
			-- TODO: fix priority
			local ent = ent_list[i]
			local map = ent_list[i].MiniMapEntity
			ent.Transform:SetPosition( pos[1] * POSITION_SCALE, 0, pos[2] * POSITION_SCALE)
			map:SetEnabled(true)
			map:SetPriority(TUNING.INTERIOR_MINIMAP_PRIORITY_START + pos[3] + ITEM_OFFSET)
			map:SetIcon(icon)
		end
		-- Hide unnecessary ents
		for i = #pos_list + 1, #ent_list do
			ent_list[i].MiniMapEntity:SetEnabled(false)
		end
	end
	for icon, ents in pairs(inst.icons)do
		if data.ents[icon] == nil then
			for _, v in ipairs(ents)do
				v.MiniMapEntity:SetEnabled(false)
			end
		end
	end
end

local function room()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetIsProxy(true)
	inst.MiniMapEntity:SetPriority(TUNING.INTERIOR_MINIMAP_PRIORITY_START + FRAME_OFFSET)

	inst.icons = {}
	inst.render = false
	inst.SetMinimapData = SetMinimapData

	inst.Render = function(_, value)
		inst.render = value
		inst.MiniMapEntity:SetEnabled(value)
		if value == false then
			for _, ents in pairs(inst.icons)do
				for _,v in ipairs(ents)do
					v.MiniMapEntity:SetEnabled(false)
				end
			end
		end
	end

	inst.persists = false

	inst:AddTag("NOBLOCK")

	return inst
end

local function Update(inst)
	if ThePlayer == nil or TheNet:IsDedicated() then
		return
	end

	for _,v in pairs(inst.icons)do
		v.MiniMapEntity:SetEnabled(false)
	end

	local ent = ThePlayer.replica.interiorvisitor:GetCenterEnt()
	if ent ~= nil and ent:HasInteriorMinimap() then
		local width, height = ent:GetSize()
		inst.MiniMapEntity:SetIcon("pl_frame_"..SizeToString(width, height)..".tex")
		inst.MiniMapEntity:SetEnabled(true)
		local x, _, z = ent.Transform:GetWorldPosition()
		for _,v in ipairs(TheSim:FindEntities(x, 0, z, ent:GetSearchRadius(), nil, {"INLIMBO", "pl_mapicon", "pl_interior_no_minimap"}))do
			if v.Network ~= nil and v.MiniMapEntity ~= nil then
				local id = v.Network:GetNetworkID()
				if inst.icons[id] == nil then
					-- TODO: 这里并未限制最大数量
					-- 以后可以优化成lru_cache
					inst.icons[id] = local_icon()
					inst.icons[id].entity:SetParent(inst.entity)
				end
				inst.icons[id].MiniMapEntity:SetEnabled(true)
				inst.icons[id].MiniMapEntity:CopyIcon(v.MiniMapEntity)
				inst.icons[id].MiniMapEntity:SetPriority(TUNING.INTERIOR_MINIMAP_PRIORITY_START + ITEM_OFFSET + (v.MiniMapEntity:GetPriority() or 0))
				local pos = v:GetPosition()
				inst.icons[id].Transform:SetPosition(
					(pos.x - x)* POSITION_SCALE,
					0,
					(pos.z - z)* POSITION_SCALE)
			end
		end
	else
		inst.MiniMapEntity:SetEnabled(false)
	end
end

-- client side room minimap renderer for room containing ThePlayer
-- unique (only one at map center)
-- no lagging compared with room() (which need ClientRPC to update)
local function room_client()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetIsProxy(true)
	inst.MiniMapEntity:SetPriority(TUNING.INTERIOR_MINIMAP_PRIORITY_START + FRAME_OFFSET)

	inst.icons = {}
	inst.Update = Update

	inst.Render = function(inst, value)
		if not value then
			inst.MiniMapEntity:SetEnabled(false)
			for _,v in pairs(inst.icons) do
				v.MiniMapEntity:SetEnabled(false)
			end
		else
			assert("param not support, use inst:Update()")
		end
	end

	inst.persists = false

	inst:AddTag("NOBLOCK")

	return inst
end

local function SetDirection(inst, dir)
	if dir == "north" or dir == "south" then
		inst.MiniMapEntity:SetIcon("pl_interior_passage4.tex")
	else
		inst.MiniMapEntity:SetIcon("pl_interior_passage3.tex")
	end
end

local function door()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetIsProxy(true)
	inst.MiniMapEntity:SetPriority(TUNING.INTERIOR_MINIMAP_PRIORITY_START + FRAME_OFFSET + DOOR_OFFSET)

	inst.SetDirection = SetDirection

	inst.Render = function(_, value)
		inst.MiniMapEntity:SetEnabled(value)
	end

	inst.persists = false
	inst:AddTag("NOBLOCK")

	return inst
end

return  Prefab("pl_interior_minimap_bg", bg_group),
	    Prefab("pl_interior_minimap_fg", fg_group),
	    Prefab("pl_interior_minimap_room", room),
	    Prefab("pl_interior_minimap_room_client", room_client),
	    Prefab("pl_interior_minimap_door", door),
	    Prefab("pl_local_icon", local_icon)