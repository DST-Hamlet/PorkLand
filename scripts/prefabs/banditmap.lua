require("map/treasurehunt")

local assets =
{
	Asset("ANIM", "anim/stash_map.zip"),
	Asset("ANIM", "anim/x_marks_spot_bandit.zip"),
}

local function revealTreasure(inst)
	if inst.treasure and inst.treasure:IsValid() then
		inst.treasure:Reveal(inst)
		inst.treasure:RevealFog(inst)
	end
end

local function showOnMinimap(treasure, reader)
	if treasure and treasure:IsValid() then
		treasure:FocusMinimap(treasure)
	end
end

local function readfn(inst, reader)

	local message
	if inst.treasure then
		--message = GetString(reader.prefab, "ANNOUNCE_TREASURE")
		revealTreasure(inst)
		inst.treasure:DoTaskInTime(0, function() showOnMinimap(inst.treasure, reader) end)
	else
		--reader.components.talker:Say(GetString(reader.prefab, messages[inst.message]))
		message = GetString(reader.prefab, "ANNOUNCE_MESSAGEBOTTLE", inst.message)
	end

	if message then
		reader.components.talker:Say(message)
	end

	inst.components.inventoryitem:RemoveFromOwner(true)
	inst:Remove()

	return true
end

local function placeBottle(inst)
	--place in deep water
	local world = GetWorld()
	local width, height = world.Map:GetSize()
	local ground = GROUND.INVALID
	local x, y, z = 0, 0, 0
	local edge_dist = 16
	local tries = 0
	while not world.Map:IsWater(ground) and tries < 7 do
		x, z = math.random(edge_dist, width - edge_dist), math.random(edge_dist, height - edge_dist)
		ground = world.Map:GetTile(x, z)
		tries = tries + 1
	end

	x = (x - width/2.0)*TILE_SCALE
	z = (z - height/2.0)*TILE_SCALE
	inst.Transform:SetPosition(x, y, z)
	inst.components.inventoryitem:OnHitGround()
end

local function banditmapfn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    anim:SetBank("stash_map")
    anim:SetBuild("stash_map")
    anim:PlayAnimation("idle")

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)

	inst.no_wet_prefix = true

	inst.components.inventoryitem:ChangeImageName("stash_map")


    inst:AddComponent("book")
    inst.components.book:SetOnReadFn(readfn)
    inst.components.book:SetAction(ACTIONS.READMAP)



	inst.treasure = nil
	inst.treasureguid = nil
	inst.message = math.random(1, #STRINGS.CHARACTERS.GENERIC.ANNOUNCE_MESSAGEBOTTLE)

	--placeBottle(inst)
	inst.PlaceBottle = placeBottle

	inst.OnSave = function(inst, data)
		local refs = {}
		if inst.treasure then
			data.treasure = inst.treasure.GUID
			table.insert(refs, inst.treasure.GUID)
		elseif inst.treasureguid then
			data.treasure = inst.treasureguid
			table.insert(refs, inst.treasureguid)
		end
		data.message = inst.message
		return refs
	end

	inst.OnLoadPostPass = function(inst, ents, data)
		inst.components.inventoryitem:OnHitGround() --this now handles hitting water or land 
		if data then
			if data.treasure then
				if ents[data.treasure] then
					inst.treasure = ents[data.treasure].entity
				end
				inst.treasureguid = data.treasure
			end
			inst.message = data.message
		end
	end

	return inst
end


------------------------------------------------------------------


local function onsavetreasure(inst, data)
    if not inst.components.workable then
        data.dug = true
    end

	if inst.treasureprev and inst.treasureprev ~= nil then
		data.treasureprev = inst.treasureprev.GUID
	end
	if inst.treasurenext and inst.treasurenext ~= nil then
		data.treasurenext = inst.treasurenext.GUID
	end
	if inst.loot then
		data.loot = inst.loot
	end
	if inst.revealed then
		data.revealed = inst.revealed
	end
end

local function onloadtreasure(inst, data)

    if data and data.dug or not inst.components.workable then
        inst:RemoveComponent("workable")
        inst.components.hole.canbury = true
        inst:RemoveTag("NOCLICK")
    end

    if data and data.loot and data.loot ~= nil then
    	inst.loot = data.loot
    end

    if data and data.revealed and data.revealed == true then
    	print("Reveal treasure")
    	inst:Reveal(inst)
    end
end

local function loadpostpasstreasure(inst, ents, data)

	if data then
		if data.loot and data.loot ~= nil then
			if type(data.loot) == "table" then
				inst.loot = data.loot[math.random(1, #data.loot)]
			else
				inst.loot = data.loot
			end
		end
		if data.treasureprev and data.treasureprev ~= nil then
			local ent = ents[data.treasureprev]
			if ent then
				inst.treasureprev = ent.entity
				inst:AddTag("linktreasure")
			end
		end
		if data.treasurenext and data.treasurenext ~= nil then
			local ent = ents[data.treasurenext]
			if ent then
				inst.treasurenext = ent.entity
				inst:AddTag("linkingtreasure")
			end
		end
		if data.bottles then
			linkBottles(inst, data.bottles)
		end
		if data.name then
			inst.debugname = data.name
		end
	end
end

local function onfinishcallback(inst, worker)

    inst.MiniMapEntity:SetEnabled(false)
    inst:RemoveComponent("workable")
    inst.components.hole.canbury = true

	if worker then
		-- figure out which side to drop the loot
		local pt = Vector3(inst.Transform:GetWorldPosition())
		local hispos = Vector3(worker.Transform:GetWorldPosition())

		local he_right = ((hispos - pt):Dot(TheCamera:GetRightVec()) > 0)

		if he_right then
			inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec()*(math.random()+1)))
			inst.components.lootdropper:DropLoot(pt - (TheCamera:GetRightVec()*(math.random()+1)))
		else
			inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec()*(math.random()+1)))
			inst.components.lootdropper:DropLoot(pt + (TheCamera:GetRightVec()*(math.random()+1)))
		end

		--inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/loot_reveal")
		GetWorld().components.banditmanager:SpawnTreasureChest(Point(inst.Transform:GetWorldPosition()))
		inst:Remove()
	end
end

local function afterblink(inst)
	if inst.blinktask then
		inst.blinktask:Cancel()
		inst.blinktask = nil
	end
--	inst:RemoveEventCallback("animover", function() inst.afterblink(inst) end)
	inst.AnimState:PlayAnimation("idle")
	inst.blinktask = inst:DoTaskInTime(math.random()*2+1,function() inst.blink(inst) end)
end

local function blink(inst)
	if inst.blinktask then
		inst.blinktask:Cancel()
		inst.blinktask = nil
	end
	inst.AnimState:PlayAnimation("blink")
	inst.blinktask = inst:DoTaskInTime(30/10,function() inst.afterblink(inst) end)
	--inst:ListenForEvent("animover", function()  
			--inst.AnimState:PlayAnimation("idle")
--			if false then
--				inst.afterblink(inst)
--			end
--		end) 
end

local function bandittreasurefn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local minimap = inst.entity:AddMiniMapEntity()

	inst.entity:AddSoundEmitter()

	inst:AddTag("buriedtreasure")
	inst:AddTag("NOCLICK")
	inst.entity:Hide()

	minimap:SetIcon( "xspot.png" )
	minimap:SetEnabled(false)

    anim:SetBank("x_marks_spot_bandit")
    anim:SetBuild("x_marks_spot_bandit")
    anim:PlayAnimation("idle")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst)
        if not inst.components.workable then
            return "DUG"
        end
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"peagawkfeather"})

    inst.components.workable:SetOnFinishCallback(onfinishcallback)

    inst:AddComponent("hole")

    inst.loot = ""
    inst.revealed = false

    inst.Reveal = function(inst)
    	print("Treasure revealed")
    	inst.revealed = true
    	inst.entity:Show()
    	inst.MiniMapEntity:SetEnabled(true)
    	inst:RemoveTag("NOCLICK")
	end

	inst.RevealFog = function(inst)
		print("Tresure fog revealed")
    	local x, y, z = inst.Transform:GetLocalPosition()
    	local minimap = GetWorld().minimap.MiniMap
    	local map = GetWorld().Map
        local cx, cy, cz = map:GetTileCenterPoint(x, 0, z)
        minimap:ShowArea(cx, cy, cz, 30)
        map:VisitTile(map:GetTileCoordsAtPoint(cx, cy, cz))
	end

	inst.IsRevealed = function(inst)
		return inst.revealed
	end

	inst.FocusMinimap = function(inst, bottle)
    	local px, py, pz = GetPlayer().Transform:GetWorldPosition()
    	local x, y, z = inst.Transform:GetLocalPosition()
    	local minimap = GetWorld().minimap.MiniMap
		print("Find treasure on minimap (" .. x .. ", "  .. z .. ")")
    	GetPlayer().HUD.controls:ToggleMap()
    	minimap:Focus(x - px, z - pz, -minimap:GetZoom()) --Zoom in all the way		
	end

	inst.OnSave = onsavetreasure
	inst.OnLoad = onloadtreasure
	inst.OnLoadPostPass = loadpostpasstreasure

--[[
	inst.SetRandomTreasure = function(inst)
		--inst:Reveal()
		local treasures = GetTreasureLootDefinitionTable()
		local treasure = GetRandomKey(treasures)
		inst.loot = treasure
		print("*******************************")
		dumptable(inst.loot,1,1,1)
	end
]]

    inst.blink = blink
    inst.afterblink = afterblink
    afterblink(inst)

    return inst
end

return Prefab("shipwrecked/objects/banditmap", banditmapfn, assets),
       Prefab("shipwrecked/objects/bandittreasure", bandittreasurefn, assets)
--[[
    local chest = SpawnPrefab("treasurechest")
    if not chest then
        self.loot = {}
        return
    end

    chest.Transform:SetPosition(pt.x, pt.y, pt.z)
    SpawnPrefab("collapse_small").Transform:SetPosition(pt.x, pt.y, pt.z)

    if chest.components.container then
        local player = GetPlayer()
        local lootprefabs = self:GetLoot()

        for p, n in pairs(lootprefabs) do
            for i = 1, n, 1 do
                local loot = SpawnPrefab(p)
                if loot.components.inventoryitem and not loot.components.container then
                    chest.components.container:GiveItem(loot, nil, nil, true, false)
                else
                    local pos = Vector3(pt.x, pt.y, pt.z)
                    local start_angle = math.random()*PI*2
                    local rad = 1
                    if chest.Physics then
                        rad = rad + chest.Physics:GetRadius()
                    end
                    local offset = FindWalkableOffset(pos, start_angle, rad, 8, false)
                    if offset == nil then
                        return
                    end

                    pos = pos + offset

                    loot.Transform:SetPosition(pos.x, pos.y, pos.z)
                    -- attacker?
                    if loot.components.combat then
                        loot.components.combat:SuggestTarget(player)
                    end
                end
            end
        end
    else
        SpawnTreasureLoot(name, lootdropper, pt)
    end
    self.loot = {}
]]