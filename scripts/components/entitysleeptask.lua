local function OnEntitySleep(inst)
    local entitysleeptask = inst.components.entitysleeptask
    if entitysleeptask.sleepperiodtask == nil then
        entitysleeptask.sleepperiodtask = inst:DoPeriodicTask(entitysleeptask.time, entitysleeptask.sleepperiodfn)
    end
end

local function OnEntityWake(inst)
    local entitysleeptask = inst.components.entitysleeptask
    if entitysleeptask.sleepperiodtask ~= nil then
        entitysleeptask.sleepperiodtask:Cancel()
        entitysleeptask.sleepperiodtask = nil
    end
end

local EntitySleepTask = Class(function(self, inst)
    self.inst = inst
    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("entitywake", OnEntityWake)
    self.sleepperiodfn = function() print("WARNING: dont have components.entitysleeptask.sleepperiodfn") end
    self.time = math.random() * 5 + 7.5
    self.sleepperiodtask = nil
end)

function EntitySleepTask:SetSleepPeriodFn(fn, time)
    self.sleepperiodfn = fn
    self.time = time or math.random() * 5 + 7.5
end

function EntitySleepTask:OnRemoveFromEntity(...)
    if self.sleepperiodtask ~= nil then
        self.sleepperiodtask:Cancel()
        self.sleepperiodtask = nil
    end
    self.inst:RemoveEventCallback("entitysleep", OnEntitySleep)
    self.inst:RemoveEventCallback("entitywake", OnEntityWake)
end

return EntitySleepTask
