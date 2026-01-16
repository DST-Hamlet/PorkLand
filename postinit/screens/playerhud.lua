GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")

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

    self.boatover = self.overlayroot:AddChild(BoatOver(owner))
    self.inst:ListenForEvent("boatattacked", function(inst, data) return self.boatover:Flash() end, self.owner)

    self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))

    self.fogover = self.overlayroot:AddChild(FogOver(owner))
    self.fogover:MoveToBack()
    self.fogover:Hide()

    self.pollenover = self.overlayroot:AddChild(PollenOver(owner))
    self.pollenover:Hide()
    self.inst:ListenForEvent("updatepollen", function(inst, data) return self.pollenover:UpdateState(data.sneezetime) end, self.owner)
    
    self.leavesover = self.overlayroot:AddChild(LeavesOver(owner))

    self.livingartifactover = self.overlayroot:AddChild(LivingArtifactOver(owner))
    self.inst:ListenForEvent("livingartifactoveron", function(inst, data) self.livingartifactover:TurnOn() end, self.owner)
    self.inst:ListenForEvent("livingartifactoveroff", function(inst, data) self.livingartifactover:TurnOff() end, self.owner)
    self.inst:ListenForEvent("livingartifactoverpulse", function(inst, data) self.livingartifactover:Flash(data) end, self.owner)

    -- 亚丹: 暂时注释掉这一部分, 因为太屎山了
    -- self.inst:ListenForEvent("sanity_stun", function(inst, data) self:GoInsane() end, self.owner)
    -- self.inst:ListenForEvent("sanity_stun_over", function(inst, data)
        -- if self.owner.replica.sanity:IsSane() then
            -- self:GoSane()
        -- end
    -- end, self.owner)
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
    elseif TheWorld.state.fogstate == FOG_STATE.CLEAR then
        intensity = 0
    end

    if self.owner.replica.inventory:EquipHasTag("batvision") then
        intensity = intensity * 0.3
    end

    if self.owner.replica.inventory:EquipHasTag("clearfog") or self.owner:HasTag("inside_interior") then
        intensity = 0
    end

    if camera.distance and not camera.dollyzoom then
        local dist_percent = (camera.distance - camera.mindist) / (camera.maxdist - camera.mindist)
        local cutoff = TUNING.HUD_CLOUD_CUTOFF
        if dist_percent > cutoff then
            camera.should_push_down = true
            local p = easing.outCubic(dist_percent - cutoff, 0, .5, 1 - cutoff)
            intensity = math.max(intensity, p)
            TheMixer:PushMix("high")
        else
            camera.should_push_down = false
            TheMixer:PopMix("high")
        end
    end

    if intensity > 0 then
        self.clouds:Show()
    else
        self.clouds:Hide()
    end

    self.clouds:GetAnimState():SetMultColour(1, 1, 1, intensity)
    TheFocalPoint.SoundEmitter:SetVolume("windsound", intensity)
end

local _OpenContainer = PlayerHud.OpenContainer
function PlayerHud:OpenContainer(container, ...)
    if container.replica.container.type == "boat" then
        return self:OpenBoat(container)
    end

    return _OpenContainer(self, container, ...)
end

function PlayerHud:OpenBoat(boat) -- 此函数复制自OpenContainer，目的为使船容器的界面挂载在controls.inv.root上
    local sailing = false
    if self.owner and self.owner.replica.sailor:GetBoat() == boat then
        sailing = true
    end

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

        self.controls.containers[boat] = boatwidget
    end
end

local _OnUpdate = PlayerHud.OnUpdate
function PlayerHud:OnUpdate(dt, ...)
    _OnUpdate(self, dt, ...)

    if self.leavesover then
        self.leavesover:OnUpdate(dt)
    end

    if self.owner and self.batsonar then
        if self.owner.replica.inventory:EquipHasTag("bat_hat") then
            self.batsonar:StartSonar()
        else
            self.batsonar:StopSonar()
        end
    end
end
