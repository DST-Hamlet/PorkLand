local function SpawnRipple(inst)
    if inst.sg and inst.sg:HasStateTag("moving") then
        inst.SoundEmitter:PlaySound("dontstarve/movement/run_marsh")
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ripple = SpawnPrefab("puddle_ripple_slow_fx")

    ripple.Transform:SetPosition(x, y, z)
    if not inst:HasTag("largecreature") then
        if inst:HasTag("_inventoryitem") then
            ripple.Transform:SetScale(0.65, 0.65, 0.65)
        else
            ripple.Transform:SetScale(0.75, 0.75, 0.75)
        end
    end
end

local Ripplespawner = Class(function(self, inst)
    self.inst = inst
    self.range = 3
    self.objects = {}
end)

function Ripplespawner:OnEntitySleep()
    self.inst:StopUpdatingComponent(self)
    for GUID, ent in pairs(self.objects)do
        if self.objects[GUID] and self.objects[GUID].ripple_task then
            self.objects[GUID].ripple_task:Cancel()
            self.objects[GUID].ripple_task = nil
        end
        self.objects[GUID] = nil
    end
end

function Ripplespawner:OnEntityWake()
    self.inst:StartUpdatingComponent(self)
end

local CANT_TAGS = {"flying", "INLIMBO", "FX", "playerghost", "DECOR", "brightmare", "nightmarecreature", "shadowcreature"}
local MUST_ONE_TAGS = {"monster", "animal", "character", "isinventoryitem", "tree", "structure"}
function Ripplespawner:OnUpdate(dt)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = {}

    if self.range > 0 then
        ents = TheSim:FindEntities(x, y, z, self.range, nil, CANT_TAGS, MUST_ONE_TAGS)
    end

    local temp_list = {}

    for i, ent in ipairs(ents) do
        temp_list[ent.GUID] = ent
    end

    for GUID, ent in pairs(self.objects) do
        if not temp_list[GUID] then
            if self.objects[GUID].ripple_task then
                self.objects[GUID].ripple_task:Cancel()
                self.objects[GUID].ripple_task = nil
            end
            self.objects[GUID] = nil
        end
    end

    for GUID, ent in pairs(temp_list) do
        if not self.objects[GUID] then
            self.objects[GUID] = ent
            ent.ripple_task = ent:DoPeriodicTask(0.4, SpawnRipple(ent))
        end
    end
end

function Ripplespawner:SetRange(newrange)
    self.range = newrange
end

return Ripplespawner
