local function onimune(self, imune)
    if imune then
        self:Disable(true)
    else
        self:OnHayFever(TheWorld.state.ishayfever, true)  -- try enabled
    end
end

local function onenabled(self, val)
    self.inst.replica.hayfever:SetEnabled(val)
end

local function onnextsneeze(self, sneezetime)
    self.inst.replica.hayfever:SetSneezeTime(sneezetime)
end

local Hayfever = Class(function(self, inst)
    self.inst = inst
    self.enabled = false
    self.sneezed = false
    self.imune = false
    self.nextsneeze = self:GetNextSneezTimeInitial()

    self._onhayfever = function(_, ishayfever) self:OnHayFever(ishayfever) end

    self.inst:WatchWorldState("ishayfever", self._onhayfever)
    self:OnHayFever(TheWorld.state.ishayfever)
end,
nil, {
    imune = onimune,
    enabled = onenabled,
    nextsneeze = onnextsneeze,
})

function Hayfever:GetNextSneezTime()
    return math.random(10, 40)
end

function Hayfever:GetNextSneezTimeInitial()
    return math.random(60, 80)
end

function Hayfever:SetNextSneezeTime(newtime)
    if self.nextsneeze < newtime then
        self.nextsneeze = newtime
    end
end

local MUST_TAGS = {"prevents_hayfever"}
function Hayfever:CanSneeze()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, MUST_TAGS)

    if self.inst:HasTag("has_gasmask") or self.inst:HasTag("has_hayfeverhat") or #ents > 0 then
        return false
    end

    return true
end

function Hayfever:DoSneezeEffects()
    if self.inst.components.sanity ~= nil then
        self.inst.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY * 3)
    end

    -- cause player to drop stuff here.
    local itemstodrop = math.random(1, 5) - 1

    if itemstodrop > 0 then
        for i = 1, itemstodrop do
            local item = self.inst.components.inventory:FindItem(function(item)
                return not item:HasTag("nosteal")
            end)

            if item then
                self.inst.components.inventory:DropItem(item, false, true)
            end
        end
    end
end

function Hayfever:OnUpdate(dt)
    if self:CanSneeze() then
        if self.nextsneeze <= 0 then
            if not self.inst.sg.wantstosneeze then
                -- large chance to sneeze twice in a row
                if self.sneezed or math.random() > 0.7 then
                    self.sneezed = false
                    self.nextsneeze = self:GetNextSneezTime()
                else
                    self.sneezed = true
                    self.nextsneeze = 1
                end

                self.inst:PushEvent("sneeze")
            end
        else
            self.nextsneeze = self.nextsneeze - dt
        end
    else
        if self.nextsneeze < 120 then
            self.nextsneeze = self.nextsneeze + (dt * 0.9)
        end
    end
end

function Hayfever:Enable(nosay)
    if not GetWorldSetting("hayfever", true) then
        return
    end

    if self.imune then
        return
    end

    if not self.enabled then
        -- print("Hayvever Started")
        if not nosay then
            self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_HAYFEVER"))
        end
        self.enabled = true
    end

    self.inst:StartUpdatingComponent(self)
end

function Hayfever:Disable(nosay)
    if self.enabled then
        -- print("Hayvever over")

        self.enabled = false
        self.nextsneeze = self:GetNextSneezTimeInitial()

        if not nosay then
            self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_HAYFEVER_OFF"))
        end
    end

    self.inst:StopUpdatingComponent(self)
end

function Hayfever:OnHayFever(enabled, nosay)
    if enabled then
        self:Enable(nosay)
    else
        self:Disable(nosay)
    end
end

function Hayfever:OnRemoveEntity()
    self:Disable(true)
    self.inst:StopWatchingWorldState("ishayfever", self._onhayfever)
end

function Hayfever:OnSave()
    local data = {}

    data.enabled = self.enabled
    data.sneezed = self.sneezed
    data.nextsneeze = self.nextsneeze

    return data
end

function Hayfever:OnLoad(data)
    if data then
        self.sneezed = data.sneezed
        self.nextsneeze = data.nextsneeze or self:GetNextSneezTimeInitial()
    end

    if data.enabled then
        self:Enable()
    end
end

function Hayfever:GetDebugString()
    return string.format("nextsneeze: %s", self.nextsneeze)
end

return Hayfever
