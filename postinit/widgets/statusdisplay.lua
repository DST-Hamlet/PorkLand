local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)
local StatusDisplays = require("widgets/statusdisplays")
local BeaverBadge = require("widgets/beaverbadge")

local _HealthDelta = StatusDisplays.HealthDelta
function StatusDisplays:HealthDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _HealthDelta(self, data)
    end
end

local _HungerDelta = StatusDisplays.HungerDelta
function StatusDisplays:HungerDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _HungerDelta(self, data)
    end
end

local _SanityDelta = StatusDisplays.SanityDelta
function StatusDisplays:SanityDelta(data)
    if not self.owner:HasTag("ironlord") then
        return _SanityDelta(self, data)
    end
end

local _OnSetPlayerMode = ToolUtil.GetUpvalue(StatusDisplays.SetGhostMode, "OnSetPlayerMode")
local _OnSetGhostMode = ToolUtil.GetUpvalue(StatusDisplays.SetGhostMode, "OnSetGhostMode")
ToolUtil.SetUpvalue(StatusDisplays.SetGhostMode, function(inst, self)
    _OnSetPlayerMode(inst, self)
    if self.beaverness ~= nil and self.onbeavernessdelta == nil then
        self.onbeavernessdelta = function(owner, data) self:BeavernessDelta(data) end
        self.inst:ListenForEvent("beavernessdelta", self.onbeavernessdelta, self.owner)
        self:SetBeavernessPercent(self.owner:GetBeaverness())
    end
end, "OnSetPlayerMode")
ToolUtil.SetUpvalue(StatusDisplays.SetGhostMode, function(inst, self)
    _OnSetGhostMode(inst, self)
    if self.onbeavernessdelta ~= nil then
        self.inst:RemoveEventCallback("beavernessdelta", self.onbeavernessdelta, self.owner)
        self.onbeavernessdelta = nil
    end
end, "OnSetGhostMode")

local _ShowStatusNumbers = StatusDisplays.ShowStatusNumbers
function StatusDisplays:ShowStatusNumbers()
    _ShowStatusNumbers(self)
    if self.beaverness ~= nil then
        self.beaverness.num:Show()
    end
end

local _HideStatusNumbers = StatusDisplays.HideStatusNumbers
function StatusDisplays:HideStatusNumbers()
    _HideStatusNumbers(self)
    if self.beaverness ~= nil then
        self.beaverness.num:Hide()
    end
end

local _SetGhostMode = StatusDisplays.SetGhostMode
function StatusDisplays:SetGhostMode(ghostmode)
    _SetGhostMode(self, ghostmode)
    if not self.isghostmode == not ghostmode then --force boolean
        return
    elseif ghostmode then
        if self.beaverness ~= nil then
            self.beaverness:Hide()
            self.beaverness:StopWarning()
        end
    else
        if self.beaverness ~= nil then
            self.beaverness:Show()
        end
    end
end

function StatusDisplays:AddBeaverness()
    if self.beaverness == nil then
        self.beaverness = self:AddChild(BeaverBadge(self.owner))
        self.beaverness:SetPosition(-80, -40, 0)

        if self.isghostmode then
            self.beaverness:Hide()
        elseif self.modetask == nil and self.onbeavernessdelta == nil then
            self.onbeavernessdelta = function(owner, data) self:BeavernessDelta(data) end
            self.inst:ListenForEvent("beavernessdelta", self.onbeavernessdelta, self.owner)
            self:SetBeavernessPercent(self.owner:GetBeaverness())
        end
    end
end

function StatusDisplays:RemoveBeaverness()
    if self.beaverness ~= nil then
        if self.onbeavernessdelta ~= nil then
            self.inst:RemoveEventCallback("beavernessdelta", self.onbeavernessdelta, self.owner)
            self.onbeavernessdelta = nil
        end

        self:SetBeaverMode(false)
        self.beaverness:Kill()
        self.beaverness = nil
    end
end

function StatusDisplays:SetBeaverMode(beavermode)
    if self.isghostmode or self.beaverness == nil then
        return
    elseif beavermode then
        self.stomach:Hide()
        self.beaverness:SetPosition(-40, 20, 0)
    else
        self.stomach:Show()
        self.beaverness:SetPosition(-80, -40, 0)
    end
end

function StatusDisplays:SetBeavernessPercent(pct)
    self.beaverness:SetPercent(pct)
end

function StatusDisplays:BeavernessDelta(data)
    self:SetBeavernessPercent(data.newpercent)

    if not data.overtime then
        if data.newpercent > data.oldpercent then
            self.beaverness:PulseGreen()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
        elseif data.newpercent < data.oldpercent then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down")
            self.beaverness:PulseRed()
        end
    end
end

AddClassPostConstruct("widgets/statusdisplays", function(self)
    if self.owner:HasTag("beaverness") then
        self:AddBeaverness()
    end
end)
