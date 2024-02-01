-- This file is copy form Island Adventures

local function onhackable(self)
    if self.canbehacked and self.caninteractwith then
        self.inst:AddTag("HACK_workable")
    else
        self.inst:RemoveTag("HACK_workable")
    end

    local shearable = self.inst.components.shearable
    if shearable then
        shearable.canshaveable = self.inst:HasTag("HACK_workable")
    end
end

local function oncyclesleft(self, cyclesleft)
    if cyclesleft == 0 then
        self.inst:AddTag("barren")
    else
        self.inst:RemoveTag("barren")
    end
end

local Hackable = Class(function(self, inst)
    self.inst = inst
    self.canbehacked = nil
    self.regentime = nil
    self.baseregentime = nil
    self.product = nil
    self.onregenfn = nil
    self.onhackedfn = nil
    self.onfinishfn = nil
    self.makeemptyfn = nil
    self.makefullfn = nil
    self.cycles_left = nil
    self.max_cycles = nil
    self.transplanted = false
    self.caninteractwith = true
    self.numtoharvest = 1
    self.wildfirestarter = false

    self.hacksleft = 1
    self.maxhacks = 1

    self.drophacked = PL_CONFIG.droplootground
    self.dropheight = nil

    self.paused = false
    self.pause_time = 0
    self.targettime = nil

    self.protected_cycles = nil
    self.task = nil
end,
nil,
{
    canbehacked = onhackable,
    caninteractwith = onhackable,
    cycles_left = oncyclesleft,
})

function Hackable:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end

    self.inst:RemoveTag("hack_workable")
    self.inst:RemoveTag("barren")
end

local function OnRegen(inst)
    inst.components.hackable:Regen()
end

function Hackable:LongUpdate(dt)
    if not self.paused and self.targettime ~= nil and not self.inst:HasTag("withered") then
        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end

        local time = GetTime()
        if self.targettime > time + dt then
            -- resechedule
            local time_to_hackable = self.targettime - time - dt
            if TheWorld.state.isspring then
                time_to_hackable = time_to_hackable * TUNING.SPRING_GROWTH_MODIFIER
            end
            self.task = self.inst:DoTaskInTime(time_to_hackable, OnRegen)
            self.targettime = time + time_to_hackable
        else
            -- become hackable right away
            self:Regen()
        end
    end
end

function Hackable:IsWildfireStarter()
    return self.wildfirestarter == true or self.inst:HasTag("withered")
end

function Hackable:FinishGrowing()
    if self.task ~= nil and not (self.canbehacked or self.inst:HasTag("withered")) then
        self.task:Cancel()
        self.task = nil
        self:Regen()
    end
end

function Hackable:Resume()
    if self.paused then
        self.paused = false
        if not (self.canbehacked or self:IsBarren()) then
            if self.pause_time ~= nil then
                if TheWorld.state.isspring then
                    self.pause_time = self.pause_time * TUNING.SPRING_GROWTH_MODIFIER
                end
                if self.task ~= nil then
                    self.task:Cancel()
                end
                self.task = self.inst:DoTaskInTime(self.pause_time, OnRegen)
                self.targettime = GetTime() + self.pause_time
            else
                self:MakeEmpty()
            end
        end
    end
end

function Hackable:Pause()
    if not self.paused then
        self.paused = true
        self.pause_time = self.targettime ~= nil and math.max(0, self.targettime - GetTime()) or nil

        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end
    end
end

function Hackable:GetDebugString()
    local time = GetTime()
    local str = ""
    if self.caninteractwith then
        str = str .. "caninteractwith "
    end
    if self.paused then
        str = str .. "paused "
        if self.pause_time ~= nil then
            str = str .. string.format("%2.2f ", self.pause_time)
        end
    end
    if not self.transplanted then
        str = str .. "Not transplanted "
    elseif self.max_cycles ~= nil and self.cycles_left ~= nil then
        str = str .. string.format("transplated; cycles: %d/%d ", self.cycles_left, self.max_cycles)
    end
    if self.protected_cycles ~= nil and self.protected_cycles > 0 then
        str = str .. string.format("protected cycles: %d ", self.protected_cycles)
    end
    if self.targettime ~= nil and self.targettime > time then
        str = str .. string.format("Regen in: %.2f ", self.targettime - time)
    end
    return str
end

function Hackable:SetUp(product, regen, number)
    self.canbehacked = true
    self.product = product
    self.baseregentime = regen
    self.regentime = regen
    self.numtoharvest = number or 1
end

-------------------------------------------------------------------------------
--V2C: Sadly, these weren't being used most of the time
--     so for consitency, don't use them anymore -__-"
--     Keeping them around in case MODs were using them
--Mobb: Y-Yeah! What he said!
--Jerry: Now it's used by grass_tall
function Hackable:SetOnHackedFn(fn)
    self.onhackedfn = fn
end

function Hackable:SetOnRegenFn(fn)
    self.onregenfn = fn
end

function Hackable:SetMakeBarrenFn(fn)
    self.makebarrenfn = fn
end

function Hackable:SetMakeEmptyFn(fn)
    self.makeemptyfn = fn
end
-------------------------------------------------------------------------------

function Hackable:CanBeFertilized()
    return self:IsBarren() or self.inst:HasTag("withered")
end

function Hackable:ChangeProduct(newProduct)
    self.product = newProduct
end

function Hackable:Fertilize(fertilizer, doer)
    if self.inst.components.burnable ~= nil then
        self.inst.components.burnable:StopSmoldering()
    end

    local fertilize_cycles = 0
    if fertilizer.components.fertilizer ~= nil then
        if doer ~= nil and
            doer.SoundEmitter ~= nil and
            fertilizer.components.fertilizer.fertilize_sound ~= nil then
            doer.SoundEmitter:PlaySound(fertilizer.components.fertilizer.fertilize_sound)
        end
        fertilize_cycles = fertilizer.components.fertilizer.withered_cycles
    end

    if fertilizer.components.finiteuses ~= nil then
        fertilizer.components.finiteuses:Use()
    else
        fertilizer.components.stackable:Get():Remove()
    end

    self.cycles_left = self.max_cycles

    if self.inst.components.witherable ~= nil then
        self.protected_cycles = (self.protected_cycles or 0) + fertilize_cycles
        if self.protected_cycles <= 0 then
            self.protected_cycles = nil
        end

        self.inst.components.witherable:Enable(self.protected_cycles == nil)
        if self.inst.components.witherable:IsWithered() then
            self.inst.components.witherable:ForceRejuvenate()
        else
            self:MakeEmpty()
        end
    else
        self:MakeEmpty()
    end
end

function Hackable:OnSave()
    local data =
    {
        protected_cycles = self.protected_cycles,
        hacked = not self.canbehacked and true or nil,
        transplanted = self.transplanted and true or nil,
        paused = self.paused and true or nil,
        caninteractwith = self.caninteractwith and true or nil,
        hacksleft = self.hacksleft,
    }

    if self.cycles_left ~= self.max_cycles then
        data.cycles_left = self.cycles_left
        data.max_cycles = self.max_cycles
    end

    if self.pause_time ~= nil and self.pause_time > 0 then
        data.pause_time = self.pause_time
    end

    if self.targettime ~= nil then
        local time = GetTime()
        if self.targettime > time then
            data.time = math.floor(self.targettime - time)
        end
    end

    return next(data) ~= nil and data or nil
end

function Hackable:OnLoad(data)
    self.transplanted = data.transplanted or false
    self.cycles_left = data.cycles_left or self.cycles_left
    self.max_cycles = data.max_cycles or self.max_cycles
    self.hacksleft = data.hacksleft or self.hacksleft

    if data.hacked or data.time ~= nil then
        if self:IsBarren() and self.makebarrenfn ~= nil then
            self.makebarrenfn(self.inst, true)
        elseif self.makeemptyfn ~= nil then
            self.makeemptyfn(self.inst)
        end
        self.canbehacked = false
    else
        if self.makefullfn ~= nil then
            self.makefullfn(self.inst)
        end
        self.canbehacked = true
    end

    if data.caninteractwith then
        self.caninteractwith = data.caninteractwith
    end

    if data.paused then
        self.paused = true
        self.pause_time = data.pause_time
        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end
    elseif data.time ~= nil then
        if self.task ~= nil then
            self.task:Cancel()
        end
        self.task = self.inst:DoTaskInTime(data.time, OnRegen)
        self.targettime = GetTime() + data.time
    end

    if data.makealwaysbarren == 1 and self.makebarrenfn ~= nil then
        self:MakeBarren()
    end

    self.protected_cycles = data.protected_cycles ~= nil and data.protected_cycles > 0 and data.protected_cycles or nil
    if self.inst.components.witherable ~= nil then
        self.inst.components.witherable:Enable(self.protected_cycles == nil)
    end
end

function Hackable:IsBarren()
    return self.cycles_left == 0
end

function Hackable:CanBeHacked()
    return self.canbehacked
end

function Hackable:Regen()
    self.canbehacked = true
    self.hacksleft = self.maxhacks
    if self.onregenfn ~= nil then
        self.onregenfn(self.inst)
    end
    if self.makefullfn ~= nil then
        self.makefullfn(self.inst)
    end
    self.targettime = nil
    self.task = nil
end

function Hackable:MakeBarren()
    self.cycles_left = 0

    local wasempty = not self.canbehacked
    self.canbehacked = false

    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end

    if self.makebarrenfn ~= nil then
        self.makebarrenfn(self.inst, wasempty)
    end
end

function Hackable:OnTransplant()
    self.transplanted = true

    if self.ontransplantfn ~= nil then
        self.ontransplantfn(self.inst)
    end
end

function Hackable:MakeEmpty()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end

    if self.makeemptyfn ~= nil then
        self.makeemptyfn(self.inst)
    end

    self.canbehacked = false

    if not self.paused and self.baseregentime ~= nil then
        local time = self.baseregentime
        if self.getregentimefn ~= nil then
            time = self.getregentimefn(self.inst)
        end
        if TheWorld.state.isspring then
            time = time * TUNING.SPRING_GROWTH_MODIFIER
        end

        self.task = self.inst:DoTaskInTime(time, OnRegen)
        self.targettime = GetTime() + time
    end
end

function Hackable:Hack(hacker, numworks, shear_mult, from_shears)
    if self.canbehacked and self.caninteractwith then

        self.hacksleft = self.hacksleft - numworks

        if hacker ~= nil then
            hacker:PushEvent("working", {hack_target = self.inst}) -- send data under a different name because the reason hackable exists is to allow two actions at the same time (in most cases ACTIONS.HACK and ACTIONS.DIG) and listeners that check this data will simply run the code based on workables ACTION.DIG (for example mightyness gain for wolfgang) -Half
        end
        -- Check work left here and fire callback and early out if there's still more work to do
         if self.onhackedfn then
            self.onhackedfn(self.inst, hacker, self.hacksleft, from_shears)
        end

        if(self.hacksleft <= 0) then
            if self.transplanted and self.cycles_left ~= nil then
                self.cycles_left = math.max(0, self.cycles_left - 1)
            end

            if self.protected_cycles ~= nil then
                self.protected_cycles = self.protected_cycles - 1
                if self.protected_cycles < 0 then
                    self.protected_cycles = nil
                    if self.inst.components.witherable ~= nil then
                        self.inst.components.witherable:Enable(true)
                    end
                end
            end

            local loot = nil
            shear_mult = shear_mult or 1
            if self.product ~= nil then
                if hacker ~= nil and hacker:HasTag("player") and hacker.components.inventory ~= nil and not self.drophacked then -- mobs (wildbores) shouldnt hack items into there inventory now -Half
                    loot = SpawnPrefab(self.product)
                    if loot ~= nil then
                        if loot.components.inventoryitem ~= nil then
                            loot.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
                        end
                        local numtoharvest = self.numtoharvest * shear_mult
                        if numtoharvest > 1 and loot.components.stackable ~= nil then
                            loot.components.stackable:SetStackSize(numtoharvest)
                        end
                        hacker:PushEvent("hacksomething", {object = self.inst, loot = loot})
                        hacker.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                    end
                elseif self.inst.components.lootdropper ~= nil then
                    local num = (self.numtoharvest or 1) * shear_mult
                    local pt = self.inst:GetPosition()
                    pt.y = pt.y + (self.dropheight or 0)
                    for i = 1, num do
                        self.inst.components.lootdropper:SpawnLootPrefab(self.product, pt)
                    end
                end
            end

            if self.onfinishfn ~= nil then
                self.onfinishfn(self.inst, hacker, loot)
            end

            self.canbehacked = false

            if self.baseregentime ~= nil and not (self.paused or self:IsBarren() or self.inst:HasTag("withered")) then
                if TheWorld.state.isspring then
                    self.regentime = self.baseregentime * TUNING.SPRING_GROWTH_MODIFIER
                end

                if self.task ~= nil then
                    self.task:Cancel()
                end
                self.task = self.inst:DoTaskInTime(self.regentime, OnRegen)
                self.targettime = GetTime() + self.regentime
            end

            self.inst:PushEvent("hacked", {hacker = hacker, loot = loot, plant = self.inst})
        end
    end
end

return Hackable
