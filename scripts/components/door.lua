local function ondisabled(self, value)
    if value then
        self.inst:AddTag("door_disabled")
    else
        self.inst:RemoveTag("door_disabled")
    end
end

local function onhidden(self, value)
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

function Door:CollectSceneActions(doer, actions)
    if not self.inst:HasTag("predoor") and not self.hidden then
        table.insert(actions, ACTIONS.USEDOOR)
    end
end

function Door:Activate(doer)
    self.inst:PushEvent("usedoor", {doer = doer})
end

function Door:UpdateDoorStatus(status, cause)
    if cause then
        self.disable_causes[cause] = status
    end

    self.disabled = false
    for _cause, setting in pairs(self.disable_causes) do
        if setting then
            self.disabled = true
        end
    end
end

function Door:UpdateDoorVis()
    if not self.inst:IsInLimbo() then
        if self.hidden then
            self.inst:Hide()
            if self.inst.shadow then
                self.inst.shadow:Hide()
            end
        else
            self.inst:Show()
            if self.inst.shadow then
                self.inst.shadow:Show()
            end
        end
    end
end

function Door:SetHidden(hidden)
    self.hidden = hidden
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
    self:UpdateDoorStatus()
end

return Door
