local Ripplespawner = Class(function(self, inst)
    self.inst = inst
    self.range = 3
    self.objects = {}
end)

function Ripplespawner:spawnripple(inst)
    if inst.sg and inst.sg:HasStateTag("moving") then
        inst.SoundEmitter:PlaySound("dontstarve/movement/run_marsh")
    end    local x,y,z = inst.Transform:GetWorldPosition()
    local ripple = SpawnPrefab("puddle_ripple_slow_fx")
    
    ripple.Transform:SetPosition(x,y,z)
    if not inst:HasTag("largecreature") then
        if inst:HasTag("isinventoryitem") then
            ripple.Transform:SetScale(0.65,0.65,0.65)
        else    
            ripple.Transform:SetScale(0.75,0.75,0.75)
        end
    end
end

function Ripplespawner:OnEntitySleep()
	self.inst:StopUpdatingComponent(self)
    for GUID, ent in pairs(self.objects)do  
        if self.objects[GUID] and self.objects[GUID].rippletask then
            self.objects[GUID].rippletask:Cancel()
            self.objects[GUID].rippletask = nil
        end
        self.objects[GUID] = nil                    
    end
end

function Ripplespawner:OnEntityWake()
	self.inst:StartUpdatingComponent(self)
end

function Ripplespawner:OnUpdate(dt)
    local x,y,z = self.inst.Transform:GetWorldPosition()
    local ents = {}
    
    if self.range > 0 then
        ents = TheSim:FindEntities(x,y,z, self.range, nil,{"flying","INLIMBO"}, {"monster","animal","character","isinventoryitem","tree","structure"})
    end

    local templist = {}

    for i, ent in ipairs(ents) do
        templist[ent.GUID] = ent
    end

    for GUID, ent in pairs(self.objects)do
        if not templist[GUID] then
            if self.objects[GUID].rippletask then
                self.objects[GUID].rippletask:Cancel()
                self.objects[GUID].rippletask = nil
            end
            self.objects[GUID] = nil            
        end
    end

    for GUID, ent in pairs(templist)do
        if not self.objects[GUID] then
            self.objects[GUID] = ent
            ent.rippletask = ent:DoPeriodicTask(0.4,function(ent) self:spawnripple(ent) end)
        end
    end
end

function Ripplespawner:SetRange(newrange)
    self.range = newrange
end

return Ripplespawner
