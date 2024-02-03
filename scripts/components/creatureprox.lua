local CANT_TAGS = {"INTERIOR_LIMBO", "FX", "NOCLICK", "DECOR", "INLIMBO"}
local CREATURE_MUST_ONE_TAGS = {"character", "animal", "monster", "stationarymonster", "insect", "smallcreature", "structure", "oceanfish", "smalloceancreature"}
local INVENTORY_MUST_ONE_TAGS = {"character", "animal", "monster","smallcreature", "insect", "_inventoryitem"}
local function OnUpdate(inst, self)
    if not self.enabled then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    local range = self.isclose and self.far or self.near
    local must_one_tags = self.inventorytrigger and INVENTORY_MUST_ONE_TAGS or CREATURE_MUST_ONE_TAGS

    local ents = TheSim:FindEntities(x, y, z, range, nil, CANT_TAGS, must_one_tags)
    for i = #ents, 1, -1 do
        if (self.findtestfn and not self.findtestfn(ents[i], inst)) or self.alivemode == IsEntityDeadOrGhost(ents[i]) then
            table.remove(ents, i)
        end
    end

    local change = false
    if not IsTableEmpty(ents) then
        change = true

        if self.inproxfn then
            for _, ent in ipairs(ents)do
                self.inproxfn(inst, ent)
            end
        end
    end

    if self.isclose ~= change then
        self.isclose = change

        if self.isclose then
            if self.onnear then
                self.onnear(inst, ents)
            end
        else
            if self.onfar then
                self.onfar(inst, ents)
            end
        end
    end

    if self.onupdate then
        self.onupdate(inst)
    end
end

local CreatureProx = Class(function(self, inst)
    self.inst = inst
    self.near = 2
    self.far = 3
    self.isclose = false
    self.inventorytrigger = false
    self.alivemode = true
    self.period = 10 * FRAMES
    self.findtestfn = nil
    self.inproxfn = nil
    self.onnear = nil
    self.onfar = nil
    self.inprox = nil
    self.onupdate = nil
    self.enabled = true
    self.task = nil

    self:Schedule()
end)

function CreatureProx:GetDebugString()
    return self.isclose and "NEAR" or "FAR"
end

function CreatureProx:SetEnabled(enabled)
    self.enabled = enabled
    if enabled == false then
        self.isclose = nil
    end
end

function CreatureProx:SetInventoryTrigger(inventorytrigger)
    self.inventorytrigger = inventorytrigger
end

function CreatureProx:SetPlayerAliveMode(alivemode)
    self.alivemode = alivemode
end

function CreatureProx:SetFindTestFn(fn)
    self.findtestfn = fn
end

function CreatureProx:SetInProxFn(fn)
    self.inproxfn = fn
end

function CreatureProx:SetOnNear(fn)
    self.onnear = fn
end

function CreatureProx:SetOnFar(fn)
    self.onfar = fn
end

function CreatureProx:SetOnUpdate(fn)
    self.onupdate = fn
end

function CreatureProx:IsClose()
    return self.isclose
end

function CreatureProx:SetDist(near, far)
    self.near = near
    self.far = far
end

function CreatureProx:Schedule(new_period)
    if new_period ~= nil then
        self.period = new_period
    end

    self:Stop()
    self.task = self.inst:DoPeriodicTask(self.period, OnUpdate, math.random() * self.period, self)
end

function CreatureProx:ForceUpdate()
    OnUpdate(self.inst, self)
end

function CreatureProx:Stop()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function CreatureProx:OnEntitySleep()
    self:ForceUpdate()
    self:Stop()
end

function CreatureProx:OnEntityWake()
    self:Schedule()
    self:ForceUpdate()
end

CreatureProx.OnRemoveEntity = CreatureProx.Stop
CreatureProx.OnRemoveFromEntity = CreatureProx.Stop

function CreatureProx:OnSave()
    return {enabled = self.enabled}
end

function CreatureProx:OnLoad(data)
    if data.enabled then
        self.enabled = data.enabled
    end
end

return CreatureProx
