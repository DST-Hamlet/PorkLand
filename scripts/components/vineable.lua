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
    if self.vines.components.rotatingbillboard then
        self.vines.Transform:SetRotation(90) -- 使得藤蔓在世界坐标系中面朝摄像机
    end
    self.vines_open = false

    -- self.inst:ListenForEvent("exitedruins", function() self:SetDoorDisabled(true) end, GetPlayer())
end

function Vineable:SetDoorDisabled(setting)
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
        self:SetDoorDisabled(true)
    end)
end

function Vineable:BeginRegrow()
    self:SetGrowTask(TUNING.TOTAL_DAY_TIME * (1 + math.random()))
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
    if self.inst.components.rotatingbillboard then
        self.inst.components.rotatingbillboard:SyncMaskAnimation()
    end
end

function Vineable:InitInteriorPrefab()
    if self.inst.components.door and self.inst.components.door.disable_causes and self.inst.components.door.disable_causes["vines"] == true then
        if self.vined then
            self:SetDoorDisabled(true)
        end
    else
        if self.vined then
            self:SetDoorDisabled(false)
        end
    end
end

function Vineable:OnSave()
    local data = {
        vined = self.vined,
    }

    if self.inst.regrowtask then
        data.regrowtimeleft = self.inst:TimeRemainingInTask(self.inst.regrowtaskinfo)
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
            self:SetDoorDisabled(false)
        else
            self:SetDoorDisabled(true)
        end
    end

    if data.regrowtimeleft then
        self:SetGrowTask(data.regrowtimeleft)
    end
end

return Vineable
