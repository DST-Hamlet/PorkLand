local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function ServerGetSpeedMultiplier(self)
    local mult = self:ExternalSpeedMultiplier()
    if self.inst.components.inventory ~= nil then
        if self.inst.components.rider ~= nil and self.inst.components.rider:IsRiding() then
            mult = self.inst.components.rider:GetMount().components.locomotor:GetSpeedMultiplier()
            local saddle = self.inst.components.rider:GetSaddle()
            if saddle ~= nil and saddle.components.saddler ~= nil then
                mult = mult + (saddle.components.saddler:GetBonusSpeedMult() - 1)
            end
        elseif self.inst.replica.sailor and self.inst.replica.sailor:GetBoat() then
            mult = mult + (self.inst.replica.sailor._currentspeed:value() / self:RunSpeed() - 1)
        elseif self.inst.components.inventory.isopen then
            -- NOTE: Check if inventory is open because client GetEquips returns
            --       nothing if inventory is closed.
            --       Don't check visibility though.
			local is_mighty = self.inst.components.mightiness ~= nil and self.inst.components.mightiness:GetState() == "mighty"
            for k, v in pairs(self.inst.components.inventory.equipslots) do
                if v.components.equippable ~= nil then
					local item_speed_mult = v.components.equippable:GetWalkSpeedMult()
                    if is_mighty and item_speed_mult < 1 then
						item_speed_mult = 1
					end

                    mult = mult + (item_speed_mult - 1)
                end
            end
        end
    end

    mult = mult + ((self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) - 1)

    return mult * self.throttle
end

local function ClientGetSpeedMultiplier(self)
    local mult = self:ExternalSpeedMultiplier()
    local inventory = self.inst.replica.inventory
    if inventory ~= nil then
        local rider = self.inst.replica.rider
        if rider ~= nil and rider:IsRiding() then
            mult = self.inst.components.rider:GetMount().components.locomotor:GetSpeedMultiplier()
            local saddle = rider:GetSaddle()
            local inventoryitem = saddle ~= nil and saddle.replica.inventoryitem or nil
            if inventoryitem ~= nil then
                mult = mult + (inventoryitem:GetWalkSpeedMult() - 1)
            end
        elseif self.inst.replica.sailor and self.inst.replica.sailor:GetBoat() then
            mult = self.inst.replica.sailor._currentspeed:value() / self:RunSpeed()
        else
            -- NOTE: GetEquips returns empty if inventory is closed! (Hidden still returns items.)
			local is_mighty = self.inst:HasTag("mightiness_mighty")
            for k, v in pairs(inventory:GetEquips()) do
                local inventoryitem = v.replica.inventoryitem
                if inventoryitem ~= nil then
					local item_speed_mult = inventoryitem:GetWalkSpeedMult()
                    if is_mighty and item_speed_mult < 1 then
						item_speed_mult = 1
					end
                    mult = mult + (item_speed_mult - 1)
                end
            end
        end
    end

    mult = mult + ((self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) - 1)

    return mult * self.throttle
end

local function RecalculateExternalSpeedMultiplier(self, sources)
    local m = 1
    for source, src_params in pairs(sources) do
        for k, v in pairs(src_params.multipliers) do
            m = m + (v - 1)
        end
    end
    return m
end

AddComponentPostInit("locomotor", function(self, inst)
    if not TheWorld:HasTag("porkland") then
        return
    end

    if self.ismastersim then
        self.GetSpeedMultiplier = ServerGetSpeedMultiplier
    else
        self.GetSpeedMultiplier = ClientGetSpeedMultiplier
    end

    self.RecalculateExternalSpeedMultiplier = RecalculateExternalSpeedMultiplier
end)
