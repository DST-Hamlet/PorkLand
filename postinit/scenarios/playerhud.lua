GLOBAL.setfenv(1, GLOBAL)

local FogOver = require("widgets/fogover")
local LeavesOver = require("widgets/pl_leaf_canopy")
local PoisonOver = require("widgets/poisonover")
local PollenOver = require("widgets/pollenover")

local PlayerHud = require("screens/playerhud")

local _CreateOverlays = PlayerHud.CreateOverlays
function PlayerHud:CreateOverlays(owner, ...)
    _CreateOverlays(self, owner, ...)

    self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))

    self.fogover = self.overlayroot:AddChild(FogOver(owner))
    self.fogover:Hide()
    self.inst:ListenForEvent("startfog", function(inst, data) return self.fogover:StartFog() end, self.owner)
    self.inst:ListenForEvent("stopfog", function(inst, data) return self.fogover:StopFog() end, self.owner)
    self.inst:ListenForEvent("setfog", function(inst, data) return self.fogover:SetFog() end, self.owner)

    self.pollenover = self.overlayroot:AddChild(PollenOver(owner))
    self.pollenover:Hide()
    self.inst:ListenForEvent("updatepollen", function(inst, data) return self.pollenover:UpdateState(data.sneezetime) end, self.owner)

    self.leavesover = self.overlayroot:AddChild(LeavesOver(owner))
end

local _UpdateClouds = PlayerHud.UpdateClouds
function PlayerHud:UpdateClouds(camera)
    if TheWorld.state.fogstate ~= FOG_STATE.CLEAR and self.clouds then
        -- manage the clouds fx during foggy wether
        self:UpdateFogClouds(camera)
    else
        _UpdateClouds(self, camera)
    end
end

function PlayerHud:UpdateFogClouds(camera)
    -- if camera.interior then
    --     self.clouds:Hide()
    --     self.clouds_on = false
    --     return
    -- else
        self.clouds:Show()
        self.clouds_on = true
    -- end

    if not TheFocalPoint.SoundEmitter:PlayingSound("windsound") then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/clouds", "windsound")
    end

    local intensityMax = 0.2

    local intensity = 0
    local time = math.max(math.min(TheWorld.state.fogtime, TheWorld.state.fog_transition_time), 0)

    if TheWorld.state.fogstate == FOG_STATE.SETTING then
        intensity = Remap(time, TheWorld.state.fog_transition_time, 0, 0, intensityMax)
    elseif TheWorld.state.fogstate == FOG_STATE.FOGGY then
        intensity = intensityMax
    elseif TheWorld.state.fogstate == FOG_STATE.LIFTING then
        intensity = Remap(time, TheWorld.state.fog_transition_time, 0, intensityMax, 0)
    end

    if self.owner.replica.inventory:EquipHasTag("batvision") then
        intensity = intensity * 0.3
    end

    if self.owner.replica.inventory:EquipHasTag("clearfog") then
        intensity = 0
    end

    self.clouds:GetAnimState():SetMultColour(1, 1, 1, intensity)
    TheFocalPoint.SoundEmitter:SetVolume("windsound", intensity)
end

local _OnUpdate = PlayerHud.OnUpdate
function PlayerHud:OnUpdate(dt, ...)
    _OnUpdate(self, dt, ...)

    if self.leavesover then
        self.leavesover:OnUpdate(dt)
    end
end
