local function ondisabled(self, value, old_value)
    if value then
        self.inst:AddTag("door_disabled")
    else
        self.inst:RemoveTag("door_disabled")
    end
end

local function onhidden(self, value, old_value)
    if value then
        self.inst:AddTag("door_hidden")
    else
        self.inst:RemoveTag("door_hidden")
    end
end

local function ontarget(self, value)
    if value == "EXTERIOR" then
        self.inst:AddTag("door_exit")
    else
        self.inst:RemoveTag("door_exit")
    end
end

local Door = Class(function(self, inst)
    self.inst = inst
    self.disabled = false
    self.hidden = false
    self.disable_causes = {}
end, nil,
{
    disabled = ondisabled,
    hidden = onhidden,
    target_interior = ontarget,
})

function Door:UpdateTargetOffset()
    local door_inst = TheWorld.components.interiorspawner:GetDoorInst(self.target_door_id)
    if door_inst then
        local x_offset = 0
        local z_offset = 0

        if door_inst.door_target_offset_x ~= nil then
            x_offset = door_inst.door_target_offset_x
        end
        if door_inst.door_target_offset_z ~= nil then
            z_offset = door_inst.door_target_offset_z
        end

        self:SetTargetOffset(x_offset, 0, z_offset)
    end
end

function Door:SetTargetOffset(x, y, z)
    local dest = self.destination
    dest.target_offset_x = x
    dest.target_offset_y = y
    dest.target_offset_z = z
end

function Door:IsLocked()
    return self.disabled or self.hidden
end

local function DoTeleport(player, pos)
    player:StartThread(function()
        local x, y, z = pos:Get()

        -- local invincible = player.components.health.invincible
        -- player.components.health:SetInvincible(true)

        if TheWorld.components.interiorspawner
            and (TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
            and not TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)) then

        else
            player.Physics:Teleport(x, y, z)
        end
        player.components.interiorvisitor:UpdateExteriorPos()
        -- player.components.health:SetInvincible(invincible)

        if TheWorld.components.interiorspawner:IsInInterior(x, z) then

        else
            if player:HasTag("wanted_by_guards") then
                player:RemoveTag("wanted_by_guards")
                local x, y, z = player.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 35, {"guard"})
                for _, guard in ipairs(ents) do
                    guard:PushEvent("attacked", {
                        attacker = player,
                        damage = 0,
                        weapon = nil,
                    })
                end
            end
        end
    end)
end

function Door:GetOffsetPos(doer)
    local room = TheWorld.components.interiorspawner:GetInteriorCenter(self.inst:GetPosition())
    if room then
        -- don't throw player directly on door
        -- instead, give a slight offset to room center
        local door_pos = self.inst:GetPosition()
        local room_pos = room:GetPosition()
        local extra_dist = doer and doer.Physics and doer.Physics:GetRadius() or 0
        local offset = (room_pos - door_pos):GetNormalized() * (0.5 + extra_dist)
        return offset
    end

    return Vector3(0, 0, 0)
end

function Door:Activate(doer)
    if not self.target_interior then
        print("WARNING: this door gets activated but it doesn't have a target interior!", self.inst)
        return false
    end

    local function PlayDoorSound()
        self.inst:PushEvent("usedoor", {doer = doer})
    end

    if self.target_interior == "EXTERIOR" then
        -- use `target_exterior` firstly, then use current room id as default
        local id = self.target_exterior or self.interior_name
        local house = TheWorld.components.interiorspawner:GetExteriorById(id)
        if house then
            DoTeleport(doer, house:GetPosition() + Vector3(house:GetPhysicsRadius(1), 0, 0))
            doer:ForceFacePoint((doer:GetPosition() + Vector3(house:GetPhysicsRadius(1), 0, 0)):Get())
            PlayDoorSound()
            doer:PushEvent("used_door", {door = self.inst, exterior = true})
            if house.components.hackable and house.stage > 0 then -- 内部门用 vineable, 外部门用 hackable... 需要代码清理
                house.stage = 1
                house.components.hackable:Hack(doer, 9999)
            end
            return true
        end
    else
        local room = TheWorld.components.interiorspawner:GetInteriorCenter(self.target_interior)

        local target_door = room and room:GetDoorById(self.target_door_id)
        if target_door then
            local door_pos = target_door:GetPosition()
            local offset = target_door.components.door:GetOffsetPos(doer)
            DoTeleport(doer, door_pos + offset)
            doer:ForceFacePoint((doer:GetPosition() + target_door.components.door:GetOffsetPos()):Get())
            PlayDoorSound()
            doer:PushEvent("used_door", {door = self.inst, exterior = false})
            if target_door.components.vineable
                and target_door.components.vineable.vines
                and target_door.components.vineable.vines.components.hackable
                and target_door.components.vineable.vines.stage > 0 then

                target_door.components.vineable.vines.stage = 1
                target_door.components.vineable.vines.components.hackable:Hack(doer, 9999)
            end
            if target_door.components.vineable
                and target_door.regrowtask
                and target_door:TimeRemainingInTask(target_door.regrowtaskinfo) < TUNING.TOTAL_DAY_TIME then

                target_door.regrowtask:Cancel()
                target_door.regrowtask = nil
                target_door.regrowtaskinfo = nil
                target_door.components.vineable:BeginRegrow()
            end
            return true
        end
    end
    return false
end

function Door:SetDoorDisabled(status, cause)
    if cause then
        self.disable_causes[cause] = status
    end

    self.disabled = false
    for _, setting in pairs(self.disable_causes) do
        if setting then
            self.disabled = true
        end
    end
end

function Door:GetShadow()
    if not self.shadow and self.inst:HasTag("door_south") then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local shadows = TheSim:FindEntities(x, y, z, 2, {"door_shadow"})
        for i, v in ipairs(shadows) do
            self.shadow = v
            break
        end
    end
    return self.shadow
end

function Door:UpdateDoorVis()
    if not self.inst:IsInLimbo() then
        if self.hidden then
            self.inst:Hide()
            if self:GetShadow() then
                self:GetShadow():Hide()
            end
        else
            self.inst:Show()
            if self:GetShadow() then
                self:GetShadow():Show()
            end
        end
    end
end

function Door:SetHidden(hidden)
    self.hidden = hidden
    self:UpdateDoorVis()
end

function Door:OnSave()
    local data = {}
    data.door_id = self.door_id
    data.target_door_id = self.target_door_id
    data.interior_name =  self.interior_name
    data.target_interior = self.target_interior
    data.target_exterior = self.target_exterior

    if self.inst:HasTag("door_north") then
        data.door_north = true
    end
    if self.inst:HasTag("door_east") then
        data.door_east = true
    end
    if self.inst:HasTag("door_west") then
        data.door_west = true
    end
    if self.inst:HasTag("door_south") then
        data.door_south = true
    end
    if self.disabled then
        data.disabled = self.disabled
    end
    if self.hidden then
        data.hidden = self.hidden
    end
    if self.angle then
        data.angle = self.angle
    end
    if self.disable_causes then
        data.disable_causes = self.disable_causes
    end

    return data
end

function Door:OnLoad(data)
    if data.door_id then
        self.door_id = data.door_id
    end
    if data.target_door_id then
        self.target_door_id = data.target_door_id
    end
    if data.interior_name then
        self.interior_name = data.interior_name
    end
    if data.target_interior then
        self.target_interior = data.target_interior
    end
    if data.target_exterior then
        self.target_exterior = data.target_exterior
    end

    if data.disabled then
        self.disabled = data.disabled
    end
    if data.hidden then
        self.hidden = data.hidden
        self:UpdateDoorVis()
    end
    if data.angle then
        self.angle = data.angle
    end

    if data.door_north then
        self.inst:AddTag("door_north")
    end
    if data.door_east then
        self.inst:AddTag("door_east")
    end
    if data.door_west then
        self.inst:AddTag("door_west")
    end
    if data.door_south then
        self.inst:AddTag("door_south")
    end
    if data.disable_causes then
        self.disable_causes = data.disable_causes
    end
    local door_definition = {
        my_interior_name = data.interior_name,
        my_door_id = data.door_id,
        target_door_id = data.target_door_id,
        target_interior = data.target_interior,
        target_exterior = data.target_exterior,
    }
    if not self.inst:HasTag("predoor") then
        TheWorld.components.interiorspawner:AddDoor(self.inst, door_definition)
    end

    self:SetDoorDisabled()
end

return Door
