local Mystery = Class(function(self, inst)
    self.inst = inst
    self.reward = nil
    self.investigaters = {}

    inst:DoTaskInTime(0, function()
            if not self.rolled then
                self:RollForMystery()
            end
        end) -- 或许可以不在玩家进入世界的第一帧进行这部分计算
end)

function Mystery:GenerateReward()
    local mid_tier = {"flint", "goldnugget", "oinc", "oinc10"}

    local toy_tier = {}
    for i = 1, NUM_TRINKETS do
        table.insert(toy_tier, "trinket_" .. tostring(i))
    end

    local high_tier = {}
    for i = 1, 3 do
        table.insert(high_tier, "relic_" .. tostring(i))
    end

    if math.random() < 0.4 then
        return nil
    elseif math.random() < 0.7 then
        if math.random() < 0.5 and #toy_tier > 0 then
            return toy_tier[math.random(#toy_tier)]
        else
            return mid_tier[math.random(#mid_tier)]
        end
    else
        return high_tier[math.random(#high_tier)]
    end
end

function Mystery:AddReward(reward)
    -- if not self.inst.components.hiddendanger then
        -- self.inst:AddComponent("hiddendanger")
    -- end
    -- self.inst.components.hiddendanger.effect = "peculiar_marker_fx"

    local color = 0.5 + math.random() * 0.5
    self.inst.AnimState:SetMultColour(color-0.15, color-0.15, color, 1)

    self.inst:AddTag("mystery")
    self.reward = reward or self:GenerateReward()
end

function Mystery:SpawnReward()
    if self.inst:HasTag("mystery") then
        self.inst.components.lootdropper:SpawnLootPrefab(self.reward)
    end
    self.reward = nil
    self.inst:RemoveTag("mystery")
end

function Mystery:RollForMystery()
    self.rolled = true
    if math.random() <= 0.05 then
        self:AddReward()
    end
end

function Mystery:SearchTest(doer, searchtimes)
    if doer and doer.components.uniqueidentity then
        local doer_uniqueid = doer.components.uniqueidentity:GetID()
        if self.investigaters[doer_uniqueid] == nil then
            self.investigaters[doer_uniqueid] = 0
        end
        if math.random() < self.investigaters[doer_uniqueid]/2000 + 1/500 then
            if self.reward == nil then
                doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_MYSTERY_NOREWARD"))
            end
            self:SpawnReward()
            return true
        else
            self.investigaters[doer_uniqueid] = self.investigaters[doer_uniqueid] + 1
            doer:PushEvent("onsearchmystery_failed", {searchtimes = self.investigaters[doer_uniqueid]})
            if self.investigaters[doer_uniqueid] < 10 then
                return false, "JUSTSTART"
            elseif self.investigaters[doer_uniqueid] < 40 then
                return false, "SEARCHFORAWHILE"
            else
                return false, "CLOSETOSUCCESS"
            end
        end
    end
end

function Mystery:OnLoad(data)
    if data.reward then
        self.reward = data.reward
    end

    if data.reward then
        self:AddReward(data.reward)
    end
    if data.rolled then
        self.rolled = data.rolled
    end
    if data.investigaters then
        self.investigaters = data.investigaters
    end
end

function Mystery:OnSave()
    local data = {}

    if self.reward then
        data.reward = self.reward
    end

    if self.investigaters then
        data.investigaters = self.investigaters
    end

    data.rolled = self.rolled
    return data
end

function Mystery:Investigate(doer)
    if doer and doer.components.uniqueidentity then
        local doer_uniqueid = doer.components.uniqueidentity:GetID()
        self.investigaters[doer_uniqueid] = 99999
    end
    if doer and doer.components.talker then
        if self.reward then
            doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_MYSTERY_FOUND"))
            if self.inst.components.hiddendanger then
                -- self.inst.components.hiddendanger:ChangeFx("identified_marker_fx")
            end
        else
            doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_MYSTERY_NOREWARD"))
            if self.inst.components.hiddendanger then

            end
        end
    end
end

return Mystery
