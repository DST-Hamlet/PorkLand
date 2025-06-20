local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local function TryCompass(self)
    if self.owner.replica.inventory ~= nil then
        local equipment = self.owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equipment ~= nil and equipment:HasTag("tracker_compass") then
            --self:OnEquipCompass(equipment)
            self:OpenCompass()
            self.compass_item = equipment
            return true
        end
    end
    --self:OnEquipCompass(nil)
    self:CloseCompass()
    return false
end

--base class for imagebuttons and animbuttons.
local HudCompass_Wheeler = Class(Widget, function(self, owner, isattached)
    self.owner = owner
    Widget._ctor(self, "Hud Compass")
    self:SetClickable(false)

    self.isattached = isattached

    self.bg = self:AddChild(UIAnim())

    self.needle = self:AddChild(UIAnim())
    self.needle:GetAnimState():SetBank("compass_needle")
    self.needle:GetAnimState():SetBuild("compass_needle")
    self.needle:GetAnimState():PlayAnimation("idle", true)

    if isattached then
        self.bg:GetAnimState():SetBank("wheeler_compass_hud")
        self.bg:GetAnimState():SetBuild("wheeler_compass_hud")
        self.bg:GetAnimState():PlayAnimation("hidden")

        self.needle:SetPosition(0, 70, 0)
        self.needle:Hide()
    else
        self.bg:GetAnimState():SetBank("wheeler_compass_bg")
        self.bg:GetAnimState():SetBuild("wheeler_compass_bg")
        self.bg:GetAnimState():PlayAnimation("idle")
        self:StartUpdateNeedle()
    end

    self:Hide()

    self.displayheading = 0
    self.currentheading = 0
    self.offsetheading = 0
    self.forceperdegree = 0.08
    self.headingvel = 0
    self.damping = 0.92
    self.easein = 0

    self.compass_item = nil

    --self.currentcompass = nil

    self.basepos = Vector3(0, 0, 0)

    self.inst:ListenForEvent("refreshinventory", function(inst)
        TryCompass(self)
    end, self.owner)

    self.inst:ListenForEvent("equip", function(inst, data)
        if data.item ~= nil and data.item:HasTag("tracker_compass") then
            --self:OnEquipCompass(data.item)
            self:OpenCompass()
            self.compass_item = data.item
        end
    end, self.owner)
    self.inst:ListenForEvent("unequip", function(inst, data)
        if data.eslot == EQUIPSLOTS.HANDS then
            --self:OnEquipCompass(nil)
            self:CloseCompass()
            self.compass_item = nil
        end
    end, self.owner)
    --Client only event, because when inventory is closed, we will stop
    --getting "equip" and "unequip" events, but we can also assume that
    --our inventory is emptied.
    self.inst:ListenForEvent("inventoryclosed", function()
        self:CloseCompass()
    end, self.owner)

    self.isopen = false
    self.istransitioning = false
    self.wantstoclose = false

    self.ontransout = function(bginst)
        self.inst:RemoveEventCallback("animover", self.ontransout, bginst)
        self.istransitioning = false
        self.bg:GetAnimState():PlayAnimation("idle")
        self.needle:Show()
        self:StartUpdateNeedle()
    end

    self.ontransin = function(bginst)
        self.inst:RemoveEventCallback("animover", self.ontransin, bginst)
        self.istransitioning = false
        self.bg:GetAnimState():PlayAnimation("hidden")
        self:Hide()
        self:StopUpdating()
    end

    TryCompass(self)
end)

--------------------------------------------------------------------------
--The one compass to rule them all.
--(aka. all other widgets' needles can follow the master's needle -_-)
local mastercompass = nil

local function OnRemoveMaster(inst)
    if inst == mastercompass.inst then
        mastercompass = nil
    end
end

function HudCompass_Wheeler:SetMaster()
    if mastercompass ~= nil and mastercompass ~= self then
        mastercompass.inst:RemoveEventCallback("onremove", OnRemoveMaster)
    end
    mastercompass = self
    self.inst:ListenForEvent("onremove", OnRemoveMaster)
end

function HudCompass_Wheeler:CopyMasterNeedle()
    self.displayheading = mastercompass.displayheading
    self.currentheading = mastercompass.currentheading
    self.offsetheading = mastercompass.offsetheading
    self.headingvel = mastercompass.headingvel
    self.easein = mastercompass.easin
end
--------------------------------------------------------------------------

function HudCompass_Wheeler:OpenCompass()
    if not self.isattached then
        if not self.isopen then
            self.isopen = true
            if mastercompass ~= nil and mastercompass ~= self then
                self:CopyMasterNeedle()
            else
                self.displayheading = self:GetCompassHeading()
                self.currentheading = self.displayheading
                self.offsetheading = 0
                self.headingvel = 0
                self.easein = 1
            end
            self.needle:SetRotation(self.displayheading)
            self:StartUpdating()
            self:Show()
        end
        return
    elseif self.wantstoclose then
        self.wantstoclose = false
        self.easein = 0
        return
    elseif self.isopen then
        return
    end

    self.isopen = true
    self.displayheading = 0
    self.currentheading = 0
    self.offsetheading = 0
    self.headingvel = 0
    self.easein = 0

    self.needle:SetRotation(0)

    if self.istransitioning then
        self.inst:RemoveEventCallback("animover", self.ontransin, self.bg.inst)
    else
        self.istransitioning = true
    end

    self.bg:GetAnimState():PlayAnimation("trans_out")
    self.inst:ListenForEvent("animover", self.ontransout, self.bg.inst)
    self:Show()
    self:StartUpdating()
end

function HudCompass_Wheeler:CloseCompass()
    if not self.isattached then
        if self.isopen then
            self.isopen = false
            self:StopUpdating()
            self:Hide()
        end
        return
    elseif not self.isopen then
        return
    elseif math.abs(self.displayheading) > 1 then
        self.wantstoclose = true
        return
    end

    self.isopen = false
    self.wantstoclose = false

    if self.istransitioning then
        self.inst:RemoveEventCallback("animover", self.ontransout, self.bg.inst)
    else
        self.istransitioning = true
    end

    self:StopUpdateNeedle()
    self.needle:Hide()
    self.bg:GetAnimState():PlayAnimation("trans_in")
    self.inst:ListenForEvent("animover", self.ontransin, self.bg.inst)
end

--[[
function HudCompass_Wheeler:OnEquipCompass(compass)
    if compass ~= nil then
        self.currentcompass = compass
        self:OpenCompass()
    else
        self.currentcompass = nil
        self:CloseCompass()
    end
end
]]

local function NormalizeHeading(heading)
    while heading < -180 do heading = heading + 360 end
    while heading > 180 do heading = heading -360 end
    return heading
end

local function EaseHeading(heading0, heading1, k)
    local delta = NormalizeHeading(heading1 - heading0)
    return NormalizeHeading(heading0 + math.clamp(delta * k, -20, 20))
end

function HudCompass_Wheeler:GetCompassHeading()
    if self.compass_item
        and self.compass_item:IsValid()
        and self.compass_item._istracking:value() then

        if self.compass_item._hastarget:value() then
            local x = self.compass_item._targetpos.x:value()
            local z = self.compass_item._targetpos.z:value()
            local x1, _, z1 = self.owner.Transform:GetWorldPosition()
            return x1 == x and z1 == z
                and 0
                or math.atan2(z1 - z, x - x1) * RADIANS + TheCamera:GetHeading() +180
        else
            return GetTime() * 360
        end
    end

    return TheCamera ~= nil and (TheCamera:GetHeading() - 45) or 0
end

function HudCompass_Wheeler:UpdatePosition(dt)
    if not self.isattached then
        self:SetPosition(self.basepos.x, self.basepos.y, self.basepos.z)
        return
    end

    local target_y = self.basepos.y
    if self.compass_item then
        if self.compass_item.replica.container:IsOpenedBy(self.owner) then
            target_y = target_y + 120
        end
    end
    local current_y = self:GetPosition().y
    if target_y > current_y then
        current_y = math.min(current_y + 600 * dt, target_y)
    elseif target_y < current_y then
        current_y = math.max(current_y - 600 * dt, target_y)
    end
    self:SetPosition(self.basepos.x, current_y, self.basepos.z)
end

function HudCompass_Wheeler:SetBasePosition(x, y, z)
    self.basepos = Vector3(x, y, z)
    self:UpdatePosition(10000)
end

function HudCompass_Wheeler:StartUpdateNeedle()
    self.needle_update = true
end

function HudCompass_Wheeler:StopUpdateNeedle()
    self.needle_update = false
end

function HudCompass_Wheeler:OnUpdate(dt)
    self:UpdatePosition(dt)

    if self.needle_update ~= true then
        return
    end

    if mastercompass ~= nil and mastercompass ~= self then
        self:CopyMasterNeedle()
        self.needle:SetRotation(self.displayheading)
        return
    end

    if self.wantstoclose then
        self.displayheading = EaseHeading(self.displayheading, 0, .5)
        self.needle:SetRotation(self.displayheading)
        self:CloseCompass()
        return
    end

    local delta = NormalizeHeading(self:GetCompassHeading() - self.currentheading)

    self.headingvel = self.headingvel + delta * self.forceperdegree
    self.headingvel = self.headingvel * self.damping
    self.currentheading = NormalizeHeading(self.currentheading + self.headingvel)

    --if self.currentcompass == nil then
        --return
    --end

    local t = GetTime()

    -- Offsets from haunting
    --local spooky_denominator = self.currentcompass.spookyoffsetfinish-self.currentcompass.spookyoffsetstart
    --local spooky_t = 1
    --if spooky_denominator > 0 then
        --spooky_t = math.clamp((t-self.currentcompass.spookyoffsetstart)/spooky_denominator, 0, 1)
    --end
    --local spooky_offset = math.sin(t*0.005) * Lerp(self.currentcompass.spookyoffsettarget,0,spooky_t)

    -- Offsets from sanity
    local sanity = self.owner.replica.sanity
    local sanity_t = math.clamp((sanity:IsInsanityMode() and sanity:GetPercent() or (1.0 - sanity:GetPercent())) * 3, 0, 1)
    local sanity_offset = math.sin(t*0.2) * Lerp(720, 0, sanity_t)

    -- Offset from full moon
    local fullmoon_t = TheWorld.state.isfullmoon and math.sin(TheWorld.state.timeinphase * math.pi) or 0
    local fullmoon_offset = math.sin(t*0.8) * Lerp(0, 720, fullmoon_t)

    if self.compass_item
        and self.compass_item:IsValid() then

        sanity_offset = 0
        fullmoon_offset = 0
    end

    -- Offset from wobble
    local wobble_offset = math.sin(t) * 5

    self.offsetheading = EaseHeading(self.offsetheading, wobble_offset + fullmoon_offset + sanity_offset, .5)

    self.easein = math.min(1, self.easein + dt)
    self.displayheading = EaseHeading(self.displayheading, self.currentheading + self.offsetheading, self.easein)
    self.needle:SetRotation(self.displayheading)
end

return HudCompass_Wheeler
