-- We don't really need to add a whole component, but I can't be bothered to rewrite this with updatelooper

--Falloff, Intensity, Radius, Colour.
local SizeTweener = Class(function(self, inst)
    self.inst = inst

    --initial values
    self.i_size = nil

    --target values
    self.t_size = nil

    --function
    self.callback = nil --call @ end of tween

    self.time = nil
    self.timepassed = 0

    self.tweening = false

    self.inst:ListenForEvent("sizetweener_start", function() self.tweening = true end)
    self.inst:ListenForEvent("sizetweener_end ", function() self.tweening = false end)

end)

function SizeTweener:EndTween()
    if self.t_size then
        self.inst.Transform:SetScale(self.t_size, self.t_size, self.t_size)
    end

    self.inst:StopUpdatingComponent(self)
    self.inst:PushEvent("sizetweener_end")
    self.tweening = false

    if self.callback then
        self.callback(self.inst)
    end
end

function SizeTweener:StartTween(size, time, callback)
    self.callback = callback

    self.i_size = self.inst.Transform:GetScale()
    self.t_size = size

    self.time = time
    self.timepassed = 0
    self.inst:PushEvent("sizetweener_start")

    if self.time > 0 then
        self.inst:StartUpdatingComponent(self)
    else
        self:EndTween()
    end
end

function SizeTweener:OnUpdate(dt)
    self.timepassed = self.timepassed + dt
    local t = self.timepassed/self.time

    if self.i_size and self.t_size then
        local s = (Lerp(self.i_size, self.t_size, t))
        self.inst.Transform:SetScale(s,s,s)
    end

    if self.timepassed >= self.time then
        self:EndTween()
    end
end

return SizeTweener
