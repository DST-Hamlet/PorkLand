local Vineable = Class(function(self, inst)
    self.inst = inst
    self.vined = false
end)

function Vineable:SetUpVine()
    self.vined = true
    self.vines = SpawnPrefab("pig_ruins_creeping_vines")
    self.inst:AddChild(self.vines)
    self.vines.Transform:SetPosition(0, 0, 0)
    self.vines.door = self.inst
    self.vines.setup(self.vines)
    self.vines_open = false

    -- self.inst:ListenForEvent("exitedruins", function() self:SetDoorDissabled(true) end, GetPlayer())
end

function Vineable:SetDoorDissabled(setting)
    self.inst.disableDoor(self.inst, setting, "vines")
    if setting then
        if self.inst.regrowtask then
            self.inst.regrowtask:Cancel()
            self.inst.regrowtask = nil
        end
        if self.vined then
            self.inst:AddTag("NOCLICK")
            self.vines_open = false
        end
    else
        if self.vined then
            self.inst:RemoveTag("NOCLICK")
            self.vines_open = true
        end
    end

    self:UpdateVineVisual()
end

function Vineable:SetGrowTask(time)
     self.inst.regrowtask, self.inst.regrowtaskinfo = self.inst:ResumeTask(time, function()
        self:SetDoorDissabled(true)
    end)
end

function Vineable:BeginRegrow()
    self:SetGrowTask(20 + math.random() * 20)
end

function Vineable:UpdateVineVisual()
    -- gets the vines to update their visuals.
    if self.vines then
        if self.vines_open then
            self.vines.hackedopen(self.vines)
        else
            self.vines.regrow(self.vines)
        end
    end
end

function Vineable:InitInteriorPrefab()
    if self.inst.components.door and self.inst.components.door.disable_causes and self.inst.components.door.disable_causes["vines"] == true then
        if self.vined then
            self:SetDoorDissabled(true)
        end
    else
        if self.vined then
            self:SetDoorDissabled(false)
        end
    end
end

function Vineable:OnSave()
    local data = {
        vined = self.vined,
    }

    if self.inst.regrowtask then
        data.regrowtimeleft = self.inst:TimeRemainingInTask(self.inst.regrowtaskinfo)
        self.inst.regrowtask:Cancel()
        self.inst.regrowtask = nil
        self.inst.regrowtaskinfo = nil
    end
    if self.vines_open then
        data.vines_open = self.vines_open
    end

    if next(data) then
        return data
    end
end

function Vineable:LoadPostPass(ents, data)
    if data.vined then
        self:SetUpVine()

        if data.vines_open then
            self:SetDoorDissabled(false)
        else
            self:SetDoorDissabled(true)
        end
    end

    if data.regrowtimeleft then
        self:SetGrowTask(data.regrowtimeleft)
    end
end

return Vineable
