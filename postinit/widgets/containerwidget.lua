local AddClassPostConstruct = AddClassPostConstruct
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local BoatBadge = require("widgets/boatbadge")
local ItemTile = require("widgets/itemtile")
local InvSlot = require("widgets/invslot")
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")
local ImageButton = require("widgets/imagebutton")
local ContainerWidget = require("widgets/containerwidget")

-- local DOUBLECLICKTIME = .33
local HUD_ATLAS = "images/hud/pl_hud.xml"

function ContainerWidget:BoatDelta(boat, data)
    if data.damage then
        self:Shake(0.25, 0.05, 5)
    end

    self.boatbadge:SetPercent(data.percent, data.maxhealth)

    if data.percent <= .25 then
        self.boatbadge:StartWarning()
    else
        self.boatbadge:StopWarning()
    end

    if self.prev_boat_pct and data.percent > self.prev_boat_pct then
        self.boatbadge:PulseGreen()
        --TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
    elseif self.prev_boat_pct and data.damage and data.percent < self.prev_boat_pct then
        self.boatbadge:PulseRed()
        --TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_down")
    end
    self.prev_boat_pct = data.percent
end

local _Open = ContainerWidget.Open
function ContainerWidget:Open(container, doer, boatwidget, ...)
    local _GetWidget = container.replica.container.GetWidget
    function container.replica.container:GetWidget(...)
        return _GetWidget(self, boatwidget, ...)
    end
    _Open(self, container, doer, ...)
    local widget = container.replica.container:GetWidget()
    container.replica.container.GetWidget = _GetWidget

    if self.inv_boatwidget and widget.pos then
        local integrated_backpack = TheInput:ControllerAttached() or Profile:GetIntegratedBackpack()
        local overflow = self.owner.replica.inventory:GetOverflowContainer()
        if integrated_backpack and overflow and overflow:IsOpenedBy(self.owner) then
            self:SetPosition(widget.pos.x, widget.pos.y + 40, widget.pos.z)
        end
    end

    if container.replica.container.type == "boat" then
        self.boatbadge:SetPosition(widget.badgepos.x, widget.badgepos.y)
        self.boatbadge:Show()
        if container and container.replica.boathealth then
            self.inst:ListenForEvent("boathealthchange", function(boat, data) self:BoatDelta(boat, data) end, container)
            self.boatbadge:SetPercent(container.replica.boathealth:GetPercent(), container.replica.boathealth:GetMaxHealth())
        end

        self.boatbadge:MoveToFront()

        self:Refresh()
    end

    if container.replica.container.hasboatequipslots then
        for eslot, index in pairs(container.replica.container.boatcontainerequips) do
            local invslot = self.inv[index]
            invslot.inst:ListenForEvent("newactiveitem", function(owner, data)
                if data.item ~= nil and
                    data.item.replica.equippable ~= nil and
                    data.item.replica.equippable:BoatEquipSlot() ~= "INVALID" and
                    data.item.replica.equippable:BoatEquipSlot() == eslot then
                        
                    invslot:ScaleTo(invslot.base_scale, invslot.highlight_scale, 0.125)
                    invslot.highlight = true
                elseif invslot.highlight then
                    invslot.highlight = false
                    invslot:ScaleTo(invslot.highlight_scale, invslot.base_scale, 0.125)
                end
            end, self.owner)
        end
    end
end

local _Close = ContainerWidget.Close
function ContainerWidget:Close(...)
    if self.isopen then
        if self.container ~= nil then
            if self.onitemequipfn ~= nil then
                self.inst:RemoveEventCallback("equip", self.onitemequipfn, self.container)
                self.onitemequipfn = nil
            end
            if self.onitemunequipfn ~= nil then
                self.inst:RemoveEventCallback("unequip", self.onitemunequipfn, self.container)
                self.onitemunequipfn = nil
            end
        end
        _Close(self, ...)
        self.boatbadge:Hide()
    else
        return _Close(self, ...)
    end
end

if not rawget(_G, "HotReloading") then
    AddClassPostConstruct("widgets/containerwidget", function(self)
        self.boatbadge = self:AddChild(BoatBadge(self.owner, self))
        self.boatbadge:Hide()
    end)
end

function PLENV.OnHotReload()
    ContainerWidget.Refresh = _Refresh
    ContainerWidget.Open = _Open
    ContainerWidget.Close = _Close
end
