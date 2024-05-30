local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Health = require("components/health")

function Health:DoPoisonDamage(amount, doer)
    if not self.invincible and self.vulnerabletopoisondamage and self.poison_damage_scale > 0 then
        if amount > 0 then
            self:DoDelta(-amount * self.poison_damage_scale, false, "poison")
        end
    end
end

local function TileCheck(inst, self)
    if not inst:IsInLimbo() then
        if not inst:CanOnWater() and inst.components.drownable == nil and inst.components.inventoryitem == nil then  --如果生物有drownable或者inventoryitem组件，那么在沉水判定由这些组件来完成
            if TheWorld.Map:ReverseIsVisualWaterAtPoint(inst.Transform:GetWorldPosition()) and not self:IsDead() then
                self:Kill()  -- 不能到水上的生物到了水上？杀！
            end
        end

        if not inst:CanOnLand() and inst.components.inventoryitem == nil then  --假设某一天会有可以被放进格子带走的水生生物......
            if TheWorld.Map:ReverseIsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) and not self:IsDead() then
                self:Kill()  -- 不能到陆地的生物到了陆地上？杀！
            end
        end

        if not inst:CanOnImpassable() then
            if not TheWorld.Map:ReverseIsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) and not TheWorld.Map:ReverseIsVisualWaterAtPoint(inst.Transform:GetWorldPosition()) and not self:IsDead() then
                self:Kill()  -- 不能到虚空的生物到了虚空？杀！
            end
        end
    end
end

function Health:OnEntityWake()
    if self.testtask ~= nil then
        self.testtask:Cancel()
        if TheWorld:HasTag("porkland") then
            self.testtask = self.inst:DoPeriodicTask(0.5, TileCheck, 0.25 + math.random() * 0.25, self)
        end
    end
end

function Health:OnEntitySleep()
    if self.checktask ~= nil then
        self.checktask:Cancel()
    end
end

AddComponentPostInit("health", function(self)
    self.vulnerabletopoisondamage = true
    self.poison_damage_scale = 1

    self.testtask = self.inst:DoPeriodicTask(0.5, TileCheck, 0.25 + math.random() * 0.25, self)
end)
