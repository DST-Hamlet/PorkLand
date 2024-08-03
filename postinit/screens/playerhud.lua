GLOBAL.setfenv(1, GLOBAL)

local BatSonar = require("widgets/batsonar")
local BoatOver = require("widgets/boatover")
local FogOver = require("widgets/fogover")
local LeavesOver = require("widgets/pl_leaf_canopy")
local LivingArtifactOver = require("widgets/livingartifactover")
local PoisonOver = require("widgets/poisonover")
local PollenOver = require("widgets/pollenover")
local ContainerWidget = require("widgets/containerwidget")

local PlayerHud = require("screens/playerhud")

local _CreateOverlays = PlayerHud.CreateOverlays
function PlayerHud:CreateOverlays(owner, ...)
    _CreateOverlays(self, owner, ...)

    self.batsonar = self.overlayroot:AddChild(BatSonar(owner))
    self.inst:ListenForEvent("startbatsonar", function(inst, data) return self.batsonar:StartSonar() end, self.owner)
    self.inst:ListenForEvent("stopbatsonar", function(inst, data) return self.batsonar:StopSonar() end, self.owner)

    self.boatover = self.overlayroot:AddChild(BoatOver(owner))
    self.inst:ListenForEvent("boatattacked", function(inst, data) return self.boatover:Flash() end, self.owner)

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

    self.livingartifactover = self.overlayroot:AddChild(LivingArtifactOver(owner))
    self.inst:ListenForEvent("livingartifactoveron", function(inst, data) self.livingartifactover:TurnOn() end, self.owner)
    self.inst:ListenForEvent("livingartifactoveroff", function(inst, data) self.livingartifactover:TurnOff() end, self.owner)
    self.inst:ListenForEvent("livingartifactoverpulse", function(inst, data) self.livingartifactover:Flash(data) end, self.owner)
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

function PlayerHud:OpenBoat(boat, sailing)
    if boat then
        local boatwidget = nil
        if sailing then
            self.controls.inv.boatwidget = self.controls.inv.root:AddChild(ContainerWidget(self.owner))
            boatwidget = self.controls.inv.boatwidget
            boatwidget:SetScale(1)
            boatwidget.scalewithinventory = false
            boatwidget:MoveToBack()
            boatwidget.inv_boatwidget = true
            self.controls.inv:Rebuild()
        else
            boatwidget = self.controls.containerroot:AddChild(ContainerWidget(self.owner))
        end

        boatwidget:Open(boat, self.owner, not sailing)

        for k,v in pairs(self.controls.containers) do
            if v.container then
                if v.parent == boatwidget.parent or k == boat then
                    v:Close()
                end
            else
                self.controls.containers[k] = nil
            end
        end

        self.controls.containers[boat] = boatwidget
    end
end

local _OnUpdate = PlayerHud.OnUpdate
function PlayerHud:OnUpdate(dt, ...)
    _OnUpdate(self, dt, ...)

    if self.leavesover then
        self.leavesover:OnUpdate(dt)
    end
end
