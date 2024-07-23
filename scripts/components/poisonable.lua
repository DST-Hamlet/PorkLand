local function OnKilled(inst)
    local poisonable = inst.components.poisonable

    if poisonable then
        poisonable:KillFX()
    end
end

-- Binary state problematic for non-players? should have a timer that gets set to infinite for players and some discrete time for non-players
local Poisonable = Class(function(self, inst)
    self.inst = inst

    self.poisoned = false

    self.fxdata = {}
    self.fxlevel = 1
    self.fxchildren = {}

    self.onpoisoned = nil
    self.oncured = nil

    self.show_fx = true
    self.loop_fx = true

    self.duration = TUNING.POISON_DURATION
    self.damage_per_interval = TUNING.POISON_DAMAGE_PER_INTERVAL
    self.interval = TUNING.POISON_INTERVAL

    self.severity = 1

    self.transfer_poison_on_attack = false

    self.start_time = nil

    self.inst:AddTag("poisonable")

    self.blockall = nil

    self.inst:ListenForEvent("death", OnKilled)
end)

function Poisonable:IsPoisonBlockerEquiped()
    if self.blockall then
        return true
    end

    -- check armour
    if self.inst.components.inventory then
        for _, equipslot in pairs(self.inst.components.inventory.equipslots) do
            if equipslot.components.equippable and equipslot.components.equippable:IsPoisonBlocker() then
                return true
            end
        end
    end

    return false
end

function Poisonable:IsPoisonGasBlockerEquiped()
    if self.blockall then
        return true
    end

    -- check armour
    if self.inst.components.inventory then
        for _, equipslot in pairs(self.inst.components.inventory.equipslots) do
            if equipslot.components.equippable and equipslot.components.equippable:IsPoisonGasBlocker() then
                return true
            end
        end
    end

    return false
end

function Poisonable:CanBePoisoned(gas)
    if not GetWorldSetting("poison", true) then
        return false
    end

    if self.poisoned or self.blockall then
        -- already poisoned
        return false
    end

    -- Normal poison, check normal blockers
    if not gas and self:IsPoisonBlockerEquiped() then
        return false
    end

    -- Gas poison, check gas blockers
    if gas and self:IsPoisonGasBlockerEquiped() then
        return false
    end

    if self.immune then
        return false
    end

    return true
end

function Poisonable:SetOnPoisonedFn(fn)
    self.onpoisoned = fn
end

function Poisonable:SetOnPoisonDoneFn(fn)
    self.onpoisondone = fn
end

function Poisonable:SetOnCuredFn(fn)
    self.oncured = fn
end

-- Add an effect to be spawned when poisoning
---@param prefab The prefab to spawn as the effect
---@param offset The offset from the poisoning entity/symbol that the effect should appear at
---@param followsymbol Optional symbol for the effect to follow
function Poisonable:AddPoisonFX(prefab, offset, followsymbol)
    table.insert(self.fxdata, {prefab = prefab, x = offset.x, y = offset.y, z = offset.z, follow = followsymbol})
end

function Poisonable:IsPoisoned()
    return self.poisoned
end

function Poisonable:GetDebugString()
    return string.format("%s ", self.poisoned and "POISONED" or "NOT POISONED")
end

function Poisonable:OnRemoveEntity()
    self:KillFX()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

function Poisonable:Poison(isGas, loadTime, strength)
    if loadTime or self:CanBePoisoned(isGas) then
        self.severity = strength and math.max(strength, self.severity) or self.severity
        self.inst:AddTag("poison")
        self.poisoned = true
        self.start_time = loadTime and (GetTime() - loadTime) or GetTime()

        if self.duration > 0 and self.show_fx then
            self:SpawnFX()
        end

        if self.onpoisoned then
            self.onpoisoned(self.inst)
        end

        if self.inst.components.areapoisoner and self.duration > 0 then
            self.inst.components.areapoisoner:StartSpreading(loadTime and -loadTime or self.duration)
        end

        if self.task then
            self.task:Cancel()
            self.task = nil
        end

        self:DoPoison()
    end
end

function Poisonable:GetDamageRampScale()
    if not self.start_time then
        return 0
    else
        local elapsed_time = GetTime() - self.start_time
        local scale = 1
        for _, data in pairs(TUNING.POISON_DAMAGE_RAMP) do
            if elapsed_time > data.time then
                scale = data.damage_scale
            else
                break
            end
        end
        return scale
    end
end

function Poisonable:GetIntervalRampScale()
    if not self.start_time then
        return 0
    else
        local elapsed_time = GetTime() - self.start_time
        local scale = 1
        for _, data in pairs(TUNING.POISON_DAMAGE_RAMP) do
            if elapsed_time > data.time then
                scale = data.interval_scale
            else
                break
            end
        end

        return scale
    end
end

function Poisonable:GetFXLevel()
    if not self.start_time then
        return 0
    else
        local elapsed_time = GetTime() - self.start_time
        local level = 1
        for _, data in pairs(TUNING.POISON_DAMAGE_RAMP) do
            if elapsed_time > data.time then
                level = data.fxlevel
            else
                break
            end
        end

        return level
    end
end

function Poisonable:DoPoison(dt)
    if self.poisoned then
        -- print("Execute Poisonable:DoPoison on " .. tostring(self.inst) .. " -> duration = " .. tostring(self.duration) .. " / start time = " .. tostring(self.start_time) .. " / dt = " .. tostring(GetTime() - self.start_time))

        local ramp_scale = self:GetDamageRampScale()

        if self.duration > 0 then
            if self.start_time and GetTime() - self.start_time >= self.duration then
                if dt and self.inst.components.health and self.inst.components.health.vulnerabletopoisondamage then
                    local intervals = math.floor(dt / self.interval)
                    local damage = self.damage_per_interval * intervals * self.severity  -- Ignore ramp scale here since we're doing a bunch of catch up
                    self.inst.components.health:DoPoisonDamage(damage)
                    self.inst:PushEvent("poisondamage", {damage = damage})
                end
                self:DonePoisoning()
            else
                if not self.inst:IsInLimbo() then
                    if self.inst.components.health and self.inst.components.health.vulnerabletopoisondamage then
                        dt = dt or 1
                        local damage = self.damage_per_interval * dt * ramp_scale * self.severity
                        self.inst.components.health:DoPoisonDamage(damage)
                        self.inst:PushEvent("poisondamage", {damage = damage})
                        if not self.loop_fx and self.show_fx then
                            self:SpawnFX()
                        end
                    end
                end
            end
        else
            if self.inst.components.health and self.inst.components.health.vulnerabletopoisondamage then
                local damage = self.damage_per_interval * ramp_scale * self.severity
                self.inst.components.health:DoPoisonDamage(damage)
                self.inst:PushEvent("poisondamage", {damage = damage})
            end
            self:SpawnFX()
        end
    end

    if self.poisoned then
        local interval_scale = self:GetIntervalRampScale()
        self.task = self.inst:DoTaskInTime(self.interval * interval_scale, function() self:DoPoison() end)
    end
end

function Poisonable:DonePoisoning()
    self:KillFX()
    self.poisoned = false
    self.start_time = nil
    self.severity = 1
    self.inst:RemoveTag("poison")

    if self.task then
        self.task:Cancel()
        self.task = nil
    end

    if self.inst.components.areapoisoner then
        self.inst.components.areapoisoner:StopSpreading()
    end

    if self.onpoisondone then
        self.onpoisondone(self.inst)
    end
end

local function ImmunityOver(inst)
    local poisonable = inst.components.poisonable
    if poisonable then
        poisonable.immune = false
        poisonable:KillFX()
    end
end

function Poisonable:Cure(curer, give_immunity, immunity_duration)
    self:DonePoisoning()

    if curer and curer.components.finiteuses then
        curer.components.finiteuses:Use()
    elseif curer and curer.components.stackable then
        curer.components.stackable:Get(1):Remove()
    end

    if self.oncured then
        self.oncured()
    end

    if give_immunity then
        if self.immunetask then
            self.immunetask:Cancel()
        end
        self.immune = true
        self:SpawnFX()
        self.immunetask = self.inst:DoTaskInTime(immunity_duration or TUNING.POISON_IMMUNE_DURATION, ImmunityOver)
    end
end

function Poisonable:SetBlockAll(blockall)
    if not self.blockall then
        self:Cure()
    end

    self.blockall = blockall
end

function Poisonable:SpawnFX()
    self:KillFX()

    if not self.fxdata then
        self.fxdata = {prefab = "poisonbubble", x = 0, y = 0, z = 0, level = self:GetFXLevel()}
    end

    if self.fxdata then
        for _, data in pairs(self.fxdata) do
            data.level = self:GetFXLevel()
            local loop = self.loop_fx and "_loop" or ""
            local fx = SpawnPrefab(data.prefab .. "_level" .. data.level .. loop)

            if fx then
                fx.Transform:SetScale(self.inst.Transform:GetScale())
            if self.immune then
                fx.AnimState:SetMultColour(183/255, 33/255, 63/255, 0.5)
            else
                fx.AnimState:SetMultColour(1, 1, 1, 1)
            end

            if data.follow then
                local follower = fx.entity:AddFollower()
                follower:FollowSymbol(self.inst.GUID, data.follow, data.x, data.y, data.z)
            else
                self.inst:AddChild(fx)
                fx.Transform:SetPosition(data.x, data.y, data.z)
            end
                table.insert(self.fxchildren, fx)
            end
        end
    end
end

function Poisonable:KillFX()
    for k, fx in pairs(self.fxchildren) do
        fx:StopBubbles()
        self.fxchildren[k] = nil
    end
end

function Poisonable:OnRemoveFromEntity()
    self:Cure()
    self.inst:RemoveTag("poisonable")
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

-- srosen need to save/load immune data too
function Poisonable:OnSave()
    return {
        severity = self.severity,
        poisoned = self.poisoned,
        poisontimeelapsed = self.start_time and (GetTime() - self.start_time) or nil,
    }
end

function Poisonable:OnLoad(data)
    if data and data.poisoned and data.poisontimeelapsed and data.severity then
        if data.poisontimeelapsed > 0 then
            self:Poison(false, data.poisontimeelapsed)
            self.inst:DoTaskInTime(0, function(inst)
                if inst.player_classified then inst.player_classified.ispoisoned:set(true) end
            end)
        end
        self.severity = data.severity
    end
end

return Poisonable
