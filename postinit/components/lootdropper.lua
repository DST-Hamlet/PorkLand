GLOBAL.setfenv(1, GLOBAL)

local LootDropper = require("components/lootdropper")

local _SpawnLootPrefab = LootDropper.SpawnLootPrefab
function LootDropper:SpawnLootPrefab(loot, pt, ...)
    local item = _SpawnLootPrefab(self, loot, pt, ...)

    if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() and item.components.perishable then
        item.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
    end

    return item
end

function LootDropper:DropLootPrefab(loot, pt, setangle, arc, alwaysinfront, dropdir)
	if loot ~= nil then
		if pt == nil then
			pt = self.inst:GetPosition()
		end

        -- local interiorspawner = TheWorld.components.interiorspawner

		-- -- Prevents loot from getting stuck inside interiors walls.
		-- if interiorspawner.current_interior and not IsPointInInteriorBounds(self.inst:GetPosition(), 1) then
		-- 	local originpt = interiorspawner:GetSpawnOrigin()

		-- 	dropdir = Vector3(originpt.x - pt.x, 0.0, originpt.z - pt.z):GetNormalized() -- Drops towards the center of the room.
		-- end

		if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() and loot.components.perishable then
			loot.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
		end

        if loot.components.inventoryitem ~= nil then
            loot.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
        end

		loot.Transform:SetPosition(pt:Get())

		if self.inst.Physics ~= nil and loot.Physics ~= nil then

			local angle = math.random()*2*PI
			local speed = self.speed or 1
            local dir = dropdir ~= nil and dropdir or Vector3(math.cos(angle), 0, math.sin(angle))

			if setangle and arc then
				arc = arc * DEGREES
				angle = setangle * DEGREES + (math.random()*arc - arc/2)
			elseif setangle then
				angle = setangle / DEGREES
			end

			if alwaysinfront then
			    local down = TheCamera:GetDownVec()
			    angle = math.atan2(down.z, down.x) + (math.random()*60-30) * DEGREES
			end

			speed = speed * math.random()
			loot.Physics:SetVel(speed*math.cos(angle), GetRandomWithVariance(8, 4), speed*math.sin(angle))
            pt = pt + dir*((loot.Physics:GetRadius() or 1) + (self.inst.Physics:GetRadius() or 0))
            loot.Transform:SetPosition(pt.x,pt.y,pt.z)
		end

		return loot
	end
end
