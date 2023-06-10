local function onnextsneeze(self, sneezetime)
    self.inst.replica.hayfever:SetSneezeTime(sneezetime)
end

local function onenabled(self, val)
    self.inst.replica.hayfever:SetEnabled(val)
end

local Hayfever = Class(function(self, inst)
    self.inst = inst
    self.enabled = false
    self.sneezed = false
    self.nextsneeze = self:GetNextSneezTimeInitial()

    self._seasontick = function(src, data) self:OnSeasonTick(data) end

    self.inst:ListenForEvent("seasontick", self._seasontick, TheWorld)
    self:OnSeasonTick({progress = TheWorld.state.seasonprogress, season = TheWorld.state.season})
end,
nil, {
    nextsneeze = onnextsneeze,
    enabled = onenabled,
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
        local findItems = self.inst.components.inventory:FindItems(function(item)
            return not item:HasTag("nosteal")
        end)

        for i = 1, itemstodrop do
            if #findItems > 0 then
                local itemnum = math.random(1, #findItems)
                local item = table.remove(findItems, itemnum)

                if item then
                    local direction = Vector3(math.random(1) - 2 , 0, math.random(1) - 2)
                    self.inst.components.inventory:DropItem(item, false, direction:GetNormalized())
                end
            end
        end
    end
end

function Hayfever:OnUpdate(dt)
    if self:CanSneeze() then
        if self.nextsneeze <= 0 then
            if not self.inst.sg.statemem.wantstosneeze then
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

function Hayfever:Enable()
    if not GetWorldSetting("hayfever", true) then
        return
    end

    if not self.enabled then
            -- print("Hayvever Started")

        self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_HAYFEVER"))
        self.enabled = true
    end

    self.inst:StartUpdatingComponent(self)
end

function Hayfever:Disable()
    if self.enabled then
        -- print("Hayvever over")

        self.enabled = false
        self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_HAYFEVER_OFF"))
        self.nextsneeze = self:GetNextSneezTimeInitial()
    end

    self.inst:StopUpdatingComponent(self)
end

function Hayfever:OnRemoveEntity()
    self:Disable()

    self.inst:RemoveEventCallback("seasontick", self._seasontick, TheWorld)
end

function Hayfever:OnSeasonTick(data)
    if data.season == "lush" then
        if data.progress > 0.1 then
            self:Enable()
        end
    elseif data.progress > 0.02 or TheWorld.state.isaporkalypse then
        self:Disable()
    end
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
        self.enabled = data.enabled
        self.sneezed = data.sneezed
        self.nextsneeze = data.nextsneeze or self:GetNextSneezTimeInitial()
    end

    if self.enabled then
        self:Enable()
    end
end

function Hayfever:GetDebugString()
    return string.format("nextsneeze: %s", self.nextsneeze)
end

return Hayfever
