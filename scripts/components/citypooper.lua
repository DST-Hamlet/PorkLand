local CityPooper = Class(function(self, inst)
    self.inst = inst
    self.enabled = true
    self:SetPoopTask()
end)

function CityPooper:TestForPoop(force)
    local poop_manager = TheWorld.components.periodicpoopmanager
    local city_id = self.inst.components.citypossession.cityID

    if poop_manager:AllowPoop(city_id) then
        if force then
                local poop = SpawnPrefab("poop")
                -- find a place to spawn us, not too close to us
                local pt = self.inst:GetPosition()
                local dist = math.random(4) + 4
                local angle = math.random() * TWOPI
                local offset = FindWalkableOffset(pt, angle, dist)
                if offset then
                    pt = pt + offset
                end
                poop.Transform:SetPosition(pt:Get())
                poop.cityID = city_id
                poop_manager:OnPoop(city_id, poop)
        else
            if TheWorld.state.isday and math.random() <= 0.5 then
                local poop = SpawnPrefab("poop")
                poop.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                poop.cityID = city_id
                poop_manager:OnPoop(city_id, poop)
            end
        end
    end

    self:SetPoopTask()
end

function CityPooper:SetPoopTask(time)
    if self.poop_task then
        self.poop_task:Cancel()
        self.poop_task = nil
        self.poop_info = nil
    end

    if not time then
        time = math.random() * TUNING.TOTAL_DAY_TIME * 2
    end

    self.poop_task, self.poop_info = self.inst:ResumeTask(time, function()
        self:TestForPoop()
    end)
end

function CityPooper:OnEntitySleep()
    if self.poop_task then
        self.poop_task:Cancel()
        self.poop_task = nil
        self.poop_info = nil
    end
end

function CityPooper:OnEntityWake()
    -- did we have any remaining business?
    if self.poop_info then
        local time = GetTime()
        local pooptime = self.poop_info.start + self.poop_info.time
        if time > pooptime then
            -- relieve us like right now
            self:TestForPoop(true)
        end
    else
        -- not sure this can ever happen, but just in case, we definitely would want a bathroom break
        self:SetPoopTask()
    end
end

return CityPooper
