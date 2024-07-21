local onsunken = function(self, onsunken)
    if onsunken then
        self.inst:AddTag("sink")
    else
        self.inst:RemoveTag("sink")
    end
end

local Sinkable = Class(function(self, inst)
    self.inst = inst

    self.oldname = inst.name
    self.sunken = nil
    self.onhitwaterfn = nil
    self.onnolongerlandedfn = nil

    self.inst:ListenForEvent("on_no_longer_landed", function() self:OnNoLongerLanded() end)  -- "retrieve"事件代表播放被钓起的视觉效果，但是真正被钓鱼者获得在这之后
    self.inst:ListenForEvent("floater_startfloating", function() self:OnHitWater() end)
end,
nil,
{
    sunken = onsunken
})

function Sinkable:OnRemoveFromEntity()
    self.inst:RemoveTag("fishable")

    self.inst:RemoveEventCallback("on_no_longer_landed", function() self:OnNoLongerLanded() end)
    self.inst:RemoveEventCallback("floater_startfloating", function() self:OnHitWater() end)
end

function Sinkable:InSunkening()
    return self.sunken
end

function Sinkable:SetOnNoLongerLandedfn(fn)
    self.onnolongerlandedfn = fn
end

function Sinkable:OnNoLongerLanded()
    if self.sunken then
        self.sunken = false
        self.inst.AnimState:SetLayer(LAYER_WORLD)
        if self.onnolongerlandedfn then
            self.onnolongerlandedfn(self.inst)
        end
    end
end

function Sinkable:SetOnHitWaterfn(fn)
    self.onhitwaterfn = fn
end

function Sinkable:OnHitWater()
    if self.inst:IsOnOcean() then
        self.sunken = true
        self.inst.AnimState:SetLayer(LAYER_BACKGROUND)
        if self.onhitwaterfn then
            self.onhitwaterfn(self.inst)
        end
    end
end

function Sinkable:OnSave()
    return {
        oldname = self.oldname
    }
end

function Sinkable:OnLoad(data)
    if data ~= nil then
         if data.oldname ~= nil then
             self.oldname = data.oldname
         end
    end
end

return Sinkable
