local containers = require("containers")

local BoatContainer = Class(function(self, inst)
    self.inst = inst

    self._cannotbeopened = net_bool(inst.GUID, "boatcontainer._cannotbeopened")
    self._enableboatequipslots = net_bool(inst.GUID, "boatcontainer._enableboatequipslots")
    self._isopen = false
    self._numslots = 0
    self.hasboatequipslots = false
    self.acceptsstacks = true
    self.issidewidget = false
    self.type = nil
    self.widget = nil
    self.itemtestfn = nil
    self.opentask = nil

    if TheWorld.ismastersim then
        self.classified = SpawnPrefab("boatcontainer_classified")
        self.classified.entity:SetParent(inst.entity)

        -- Server intercepts messages and forwards to clients via classified net vars
        self._onitemget = function(inst, data)
            self.classified:SetSlotItem(data.slot, data.item, data.src_pos)
            if self.issidewidget and
                inst.components.inventoryitem.owner ~= nil and
                inst.components.inventoryitem.owner.HUD ~= nil then
                inst.components.inventoryitem.owner:PushEvent("refreshcrafting")
            end
        end
        self._onitemlose = function(inst, data)
            self.classified:SetSlotItem(data.slot)
            if self.issidewidget and
                inst.components.inventoryitem.owner ~= nil and
                inst.components.inventoryitem.owner.HUD ~= nil then
                inst.components.inventoryitem.owner:PushEvent("refreshcrafting")
            end
        end
        inst:ListenForEvent("itemget", self._onitemget)
        inst:ListenForEvent("itemlose", self._onitemlose)
        inst:ListenForEvent("equip", function(inst, data) self.classified:SetSlotBoatEquip(data.eslot, data.item) end)
        inst:ListenForEvent("unequip", function(inst, data) self.classified:SetSlotBoatEquip(data.eslot) end)
    else
        containers.widgetsetup(self)

        if self.classified == nil and inst.boatcontainer_classified ~= nil then
            self.classified = inst.boatcontainer_classified
            inst.boatcontainer_classified.OnRemoveEntity = nil
            inst.boatcontainer_classified = nil
            self:AttachClassified(self.classified)
        end
    end
end)

--------------------------------------------------------------------------

function BoatContainer:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified:Remove()
            self.classified = nil
            self.inst:RemoveEventCallback("itemget", self._onitemget)
            self.inst:RemoveEventCallback("itemlose", self._onitemlose)
            if self._onputininventory ~= nil then
                self.inst:RemoveEventCallback("onputininventory", self._onputininventory)
                self.inst:RemoveEventCallback("ondropped", self._ondropped)
                self._onputininventory = nil
                self._ondropped = nil
                self._owner = nil
            end
        else
            self.classified._parent = nil
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

BoatContainer.OnRemoveEntity = BoatContainer.OnRemoveFromEntity

--------------------------------------------------------------------------
--Client triggers open/close based on receiving access to classified data
--------------------------------------------------------------------------

local function OnRefreshCrafting(inst)
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
        ThePlayer:PushEvent("refreshcrafting")
    end
end

local function OpenContainer(inst, self, snap)
    self.opentask = nil

    --V2C: don't animate to and from the backpack position
    --     when re-opening inventory as Werebeaver->Woodie
    local inv = snap and ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer.HUD.controls.inv or nil
    snap = inv ~= nil and not inv.rebuild_pending

    self:Open(ThePlayer)
    OnRefreshCrafting(inst)

    if snap and inv.rebuild_pending then
        inv.rebuild_snapping = true
    end
end

function BoatContainer:AttachClassified(classified)
    self.classified = classified

    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)

    classified:InitializeSlots(self:GetNumSlots())

    local inv = self.issidewidget and ThePlayer ~= nil and ThePlayer.HUD ~= nil and ThePlayer.HUD.controls.inv or nil
    self.opentask = self.inst:DoTaskInTime(0, OpenContainer, self, inv ~= nil and (not inv.shown or inv.rebuild_snapping))

    if self.issidewidget then
        self.inst:ListenForEvent("itemget", OnRefreshCrafting)
        self.inst:ListenForEvent("itemlose", OnRefreshCrafting)
    end
end

function BoatContainer:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    if self.issidewidget then
        self.inst:RemoveEventCallback("itemget", OnRefreshCrafting)
        self.inst:RemoveEventCallback("itemlose", OnRefreshCrafting)
        OnRefreshCrafting(self.inst)
    end
    self:Close()
end

--------------------------------------------------------------------------
--Server initialization requires param since prefab property is not set yet
--------------------------------------------------------------------------

function BoatContainer:WidgetSetup(prefab, data)
    containers.widgetsetup(self, prefab, data)
    if self.classified ~= nil then
        self.classified:InitializeSlots(self:GetNumSlots())
    end
    if self.issidewidget then
        if self._onputininventory == nil then
            self._owner = nil
            self._ondropped = function(inst)
                if self._owner ~= nil then
                    local owner = self._owner
                    self._owner = nil
                    if owner.HUD ~= nil then
                        owner:PushEvent("refreshcrafting")
                    end
                end
            end
            self._onputininventory = function(inst, owner)
                self._ondropped(inst)
                self._owner = owner
                if owner ~= nil and owner.HUD ~= nil then
                    owner:PushEvent("refreshcrafting")
                end
            end
            self.inst:ListenForEvent("onputininventory", self._onputininventory)
            self.inst:ListenForEvent("ondropped", self._ondropped)
        end
    end
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

function BoatContainer:GetWidget(boatwidget)
    if not boatwidget then
        return self.widget
    else
        return self.inspectwidget
    end
end

function BoatContainer:SetNumSlots(numslots)
    self._numslots = numslots
end

function BoatContainer:GetNumSlots()
    return self._numslots
end

function BoatContainer:SetCanBeOpened(canbeopened)
    self._cannotbeopened:set(not canbeopened)
end

function BoatContainer:CanBeOpened()
    return not self._cannotbeopened:value()
end

function BoatContainer:CanTakeItemInSlot(item, slot)
    return item ~= nil
        and item.replica.inventoryitem ~= nil
        and item.replica.inventoryitem:CanGoInContainer()
        and not item.replica.inventoryitem:CanOnlyGoInPocket()
        and not (GetGameModeProperty("non_item_equips") and item.replica.equippable ~= nil)
        and (self.itemtestfn == nil or self:itemtestfn(item, slot))
end

function BoatContainer:AcceptsStacks()
    return self.acceptsstacks
end

function BoatContainer:IsSideWidget()
    return self.issidewidget
end

function BoatContainer:SetOpener(opener)
    self.classified.Network:SetClassifiedTarget(opener or self.inst)
    if self.inst.components.container ~= nil then
        for k, v in pairs(self.inst.components.container.slots) do
            v.replica.inventoryitem:SetOwner(self.inst)
        end
        for k, v in pairs(self.inst.components.container.boatequipslots) do
            v.replica.inventoryitem:SetOwner(self.inst)
        end
    else
        --Should only reach here during container construction
        assert(opener == nil)
    end
end

function BoatContainer:IsOpenedBy(guy)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsOpenedBy(guy)
    else
        return self._isopen and self.classified ~= nil and guy ~= nil and guy == ThePlayer
    end
end

function BoatContainer:IsHolding(item, checkcontainer)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsHolding(item, checkcontainer)
    else
        return self.classified ~= nil and self.classified:IsHolding(item, checkcontainer)
    end
end

function BoatContainer:GetItemInSlot(slot)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInSlot(slot)
    else
        return self.classified ~= nil and self.classified:GetItemInSlot(slot) or nil
    end
end

function BoatContainer:GetItemInBoatSlot(slot)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:GetItemInBoatSlot(slot)
    else
        return self.classified ~= nil and self.classified:GetItemInBoatSlot(slot) or nil
    end
end

function BoatContainer:GetItems()
    if self.inst.components.container ~= nil then
        return self.inst.components.container.slots
    else
        return self.classified ~= nil and self.classified:GetItems() or {}
    end
end

function BoatContainer:GetBoatEquips()
    if self.inst.components.container ~= nil then
        return self.inst.components.container.boatequipslots
    else
        return self.classified ~= nil and self.classified:GetBoatEquips() or {}
    end
end

function BoatContainer:IsEmpty()
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsEmpty()
    else
        return self.classified ~= nil and self.classified:IsEmpty()
    end
end

function BoatContainer:IsFull()
    if self.inst.components.container ~= nil then
        return self.inst.components.container:IsFull()
    else
        return self.classified ~= nil and self.classified:IsFull()
    end
end

function BoatContainer:Has(prefab, amount)
    if self.inst.components.container ~= nil then
        return self.inst.components.container:Has(prefab, amount)
    elseif self.classified ~= nil then
        return self.classified:Has(prefab, amount)
    else
        return amount <= 0, 0
    end
end

function BoatContainer:Open(doer)
    if self.inst.components.container ~= nil then
        if self.opentask ~= nil then
            self.opentask:Cancel()
            self.opentask = nil
        end
        self.inst.components.container:Open(doer)
    elseif self.classified ~= nil and
        self.opentask == nil and
        doer ~= nil and
        doer == ThePlayer then
        if doer.HUD == nil then
            self._isopen = false
        elseif not self._isopen then
            if self.type == "boat" then
                doer.HUD:OpenBoat(self.inst, self.inst.entity:GetParent() == doer)
            else
                doer.HUD:OpenContainer(self.inst, self:IsSideWidget())
            end
            if self:IsSideWidget() then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/backpack_open")
            end
            self._isopen = true
        end
    end
end

function BoatContainer:Close()
    if self.opentask ~= nil then
        self.opentask:Cancel()
        self.opentask = nil
    end
    if self.inst.components.container ~= nil then
        self.inst.components.container:Close()
    elseif self._isopen then
        if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
            ThePlayer.HUD:CloseContainer(self.inst, self:IsSideWidget())
            if self:IsSideWidget() then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/backpack_close")
            end
        end
        self._isopen = false
    end
end

function BoatContainer:IsBusy()
    return self.inst.components.container == nil and (self.classified == nil or self.classified:IsBusy())
end

--------------------------------------------------------------------------
--InvSlot click action handlers
--------------------------------------------------------------------------

function BoatContainer:PutOneOfActiveItemInSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:PutOneOfActiveItemInSlot(slot)
    elseif self.classified ~= nil then
        self.classified:PutOneOfActiveItemInSlot(slot)
    end
end

function BoatContainer:PutAllOfActiveItemInSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:PutAllOfActiveItemInSlot(slot)
    elseif self.classified ~= nil then
        self.classified:PutAllOfActiveItemInSlot(slot)
    end
end

function BoatContainer:TakeActiveItemFromHalfOfSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:TakeActiveItemFromHalfOfSlot(slot)
    elseif self.classified ~= nil then
        self.classified:TakeActiveItemFromHalfOfSlot(slot)
    end
end

function BoatContainer:TakeActiveItemFromAllOfSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:TakeActiveItemFromAllOfSlot(slot)
    elseif self.classified ~= nil then
        self.classified:TakeActiveItemFromAllOfSlot(slot)
    end
end

function BoatContainer:AddOneOfActiveItemToSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:AddOneOfActiveItemToSlot(slot)
    elseif self.classified ~= nil then
        self.classified:AddOneOfActiveItemToSlot(slot)
    end
end

function BoatContainer:AddAllOfActiveItemToSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:AddAllOfActiveItemToSlot(slot)
    elseif self.classified ~= nil then
        self.classified:AddAllOfActiveItemToSlot(slot)
    end
end

function BoatContainer:SwapActiveItemWithSlot(slot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:SwapActiveItemWithSlot(slot)
    elseif self.classified ~= nil then
        self.classified:SwapActiveItemWithSlot(slot)
    end
end

function BoatContainer:BoatEquipActiveItem()
    if self.inst.components.container ~= nil then
        self.inst.components.container:BoatEquipActiveItem()
    elseif self.classified ~= nil then
        self.classified:BoatEquipActiveItem()
    end
end

function BoatContainer:SwapBoatEquipWithActiveItem()
    if self.inst.components.container ~= nil then
        self.inst.components.container:SwapBoatEquipWithActiveItem()
    elseif self.classified ~= nil then
        self.classified:SwapBoatEquipWithActiveItem()
    end
end

function BoatContainer:TakeActiveItemFromBoatEquipSlot(eslot)
    if self.inst.components.container ~= nil then
        self.inst.components.container:TakeActiveItemFromBoatEquipSlot(eslot)
    elseif self.classified ~= nil then
        self.classified:TakeActiveItemFromBoatEquipSlot(eslot)
    end
end

function BoatContainer:MoveItemFromAllOfSlot(slot, container)
    if self.inst.components.container ~= nil then
        self.inst.components.container:MoveItemFromAllOfSlot(slot, container)
    elseif self.classified ~= nil then
        self.classified:MoveItemFromAllOfSlot(slot, container)
    end
end

function BoatContainer:MoveItemFromHalfOfSlot(slot, container)
    if self.inst.components.container ~= nil then
        self.inst.components.container:MoveItemFromHalfOfSlot(slot, container)
    elseif self.classified ~= nil then
        self.classified:MoveItemFromHalfOfSlot(slot, container)
    end
end

function BoatContainer:FindCraftingItems(fn)
    if self.inst.components.container then
        return self.inst.components.container:FindCraftingItems(fn)
    elseif self.classified then
        return self.classified:FindCraftingItems(fn)
    else
        return {}
    end
end

function BoatContainer:IsInfiniteStackSize()
    return false
end

--------------------------------------------------------------------------

return BoatContainer
