local containers = require("containers")
local EquipSlot = require("equipslotutil")

local function onenableboatequipslots(self, enableboatequipslots)
    self.inst.replica.container._enableboatequipslots:set(enableboatequipslots)
end

local function oncanbeopened(self, canbeopened)
    self.inst.replica.container:SetCanBeOpened(canbeopened)
end

local function onopener(self, opener)
    self.inst.replica.container:SetOpener(opener)
end

local BoatContainer = Class(function(self, inst)
    self.inst = inst
    self.slots = {}
    self.boatequipslots = {}
    self.hasboatequipslots = false
    self.enableboatequipslots = true
    self.numslots = 0
    self.canbeopened = true
    self.acceptsstacks = true
    self.issidewidget = false
    self.type = nil
    self.widget = nil
    self.itemtestfn = nil
    self.opener = nil

    -- Hacky flags for altering behaviour when moving items between containers
    self.ignoresound = false

    inst:AddTag("boatcontainer")
end,
nil,
{
    canbeopened = oncanbeopened,
    opener = onopener,
    enableboatequipslots = onenableboatequipslots
})

local widgetprops =
{
    "numslots",
    "acceptsstacks",
    "issidewidget",
    "type",
    "widget",
    "itemtestfn",
}

function BoatContainer:WidgetSetup(prefab, data)
    for i, v in ipairs(widgetprops) do
        removesetter(self, v)
    end

    containers.widgetsetup(self, prefab, data)
    self.inst.replica.container:WidgetSetup(prefab, data)

    for i, v in ipairs(widgetprops) do
        makereadonly(self, v)
    end
end

function BoatContainer:GetWidget()
    -- UNUSED
    return self.widget
end

function BoatContainer:NumItems()
    local num = 0
    for k, v in pairs(self.slots) do
        num = num + 1
    end

    return num
end

function BoatContainer:IsFull()
    local items = 0
    for k, v in pairs(self.slots) do
        items = items + 1
    end

    return items >= self.numslots
end

function BoatContainer:IsEmpty()
    return next(self.slots) == nil
end

function BoatContainer:SetNumSlots(numslots)
    assert(numslots >= self.numslots)
    self.numslots = numslots
end

function BoatContainer:DropItemBySlot(slot)
    local item = self:RemoveItemBySlot(slot)
    if item ~= nil then
        item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:OnDropped(true)
        end
        item.prevcontainer = nil
        item.prevslot = nil
        self.inst:PushEvent("dropitem", { item = item })
    end
end

function BoatContainer:DropBoatEquipBySlot(slot)
    local item = self:Unequip(slot)
    if item ~= nil then
        item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:OnDropped(true)
        end
        item.prevcontainer = nil
        item.prevslot = nil
        self.inst:PushEvent("dropitem", { item = item })
    end
end

function BoatContainer:DropEverythingWithTag(tag)
    local containers = {}

    for i = 1, self.numslots do
        local item = self.slots[i]
        if item ~= nil then
            if item:HasTag(tag) then
                self:DropItemBySlot(i)
            elseif item.components.container ~= nil then
                table.insert(containers, item)
            end
        end
    end
    if self.hasboatequipslots then
         for k, v in pairs(self.boatequipslots) do
            local item = v
            if item:HasTag(tag) then
                self:DropBoatEquipBySlot(k)
            elseif item.components.container ~= nil then
                table.insert(containers, item)
            end
        end
    end

    for i, v in ipairs(containers) do
        v.components.container:DropEverythingWithTag(tag)
    end
end

function BoatContainer:DropEverything()
    for i = 1, self.numslots do
        self:DropItemBySlot(i)
    end
    if self.hasboatequipslots then
         for k, v in pairs(self.boatequipslots) do
            self:DropBoatEquipBySlot(k)
        end
    end
end

function BoatContainer:DropItem(itemtodrop)
    local item = self:RemoveItem(itemtodrop)
    if item then
        local pos = Vector3(self.inst.Transform:GetWorldPosition())
        item.Transform:SetPosition(pos:Get())
        if item.components.inventoryitem then
            item.components.inventoryitem:OnDropped(true)
        end
        item.prevcontainer = nil
        item.prevslot = nil
        self.inst:PushEvent("dropitem", {item = item})
    end
end

function BoatContainer:CanTakeItemInSlot(item, slot)
    return item ~= nil
        and item.components.inventoryitem ~= nil
        and item.components.inventoryitem.cangoincontainer
        and not item.components.inventoryitem.canonlygoinpocket
        and (slot == nil or (slot >= 1 and slot <= self.numslots))
        and not (GetGameModeProperty("non_item_equips") and item.components.equippable ~= nil)
        and (self.itemtestfn == nil or self:itemtestfn(item, slot))
end

function BoatContainer:AcceptsStacks()
    return self.acceptsstacks
end

function BoatContainer:IsSideWidget()
    return self.issidewidget
end

function BoatContainer:DestroyContents()
    for k = 1, self.numslots do
        local item = self:RemoveItemBySlot(k)
        if item ~= nil then
            item:Remove()
        end
    end
end

function BoatContainer:GiveItem(item, slot, src_pos, drop_on_fail)

    local eslot = self:IsItemBoatEquipped(item)

    if eslot then
       self:Unequip(eslot)
    end

    if item == nil then
        return false
    elseif item.components.inventoryitem ~= nil and self:CanTakeItemInSlot(item, slot) then
        -- try to burn off stacks if we're just dumping it in there
        if item.components.stackable ~= nil and self.acceptsstacks then
            -- Added this for when we want to dump a stack back into a
            -- specific spot (e.g. moving half a stack failed, so we
            -- need to dump the leftovers back into the original stack)
            if slot ~= nil and slot <= self.numslots then
                local other_item = self.slots[slot]
                if other_item ~= nil and (other_item.prefab == item.prefab and other_item.skinname == item.skinname) and not other_item.components.stackable:IsFull() then
                    if self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner ~= nil then
                        self.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = slot })
                    end

                    item = other_item.components.stackable:Put(item, src_pos)
                    if item == nil then
                        return true
                    end

                    slot = nil
                end
            end

            if slot == nil then
                for k = 1, self.numslots do
                    local other_item = self.slots[k]
                    if other_item and (other_item.prefab == item.prefab and other_item.skinname == item.skinname) and not other_item.components.stackable:IsFull() then
                        if self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner ~= nil then
                            self.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = k })
                        end

                        item = other_item.components.stackable:Put(item, src_pos)
                        if item == nil then
                            return true
                        end
                    end
                end
            end
        end

        local use_slot = slot and slot <= self.numslots and not self.slots[slot]
        local in_slot = nil
        if use_slot then
            in_slot = slot
        elseif self.numslots > 0 then
            for k = 1, self.numslots do
                if not self.slots[k] then
                    in_slot = k
                    break
                end
            end
        end

        if in_slot then
            -- weird case where we are trying to force a stack into a non-stacking container. this should probably have been handled earlier, but this is a failsafe
            if not self.acceptsstacks and item.components.stackable and item.components.stackable:StackSize() > 1 then
                item = item.components.stackable:Get()
                self.slots[in_slot] = item
                item.components.inventoryitem:OnPutInInventory(self.inst)
                self.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = src_pos })
                return false
            end

            self.slots[in_slot] = item
            item.components.inventoryitem:OnPutInInventory(self.inst)
            self.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = src_pos })

            if not self.ignoresound and self.inst.components.inventoryitem ~= nil and self.inst.components.inventoryitem.owner ~= nil then
                self.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = in_slot })
            end

            return true
        end
    end

    -- default to true if nil
    if drop_on_fail ~= false then
        item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:OnDropped(true)
        end
    end
    return false
end

function BoatContainer:RemoveItemBySlot(slot)
    if slot and self.slots[slot] then
        local item = self.slots[slot]
        if item then
            self.slots[slot] = nil
            if item.components.inventoryitem then
                item.components.inventoryitem:OnRemoved()
            end

            self.inst:PushEvent("itemlose", {slot = slot})
        end
        item.prevcontainer = self
        item.prevslot = slot
        return item
    end
end

function BoatContainer:GetNumSlots()
    return self.numslots
end

function BoatContainer:GetItemInSlot(slot)
    if slot and self.slots[slot] then
        return self.slots[slot]
    end
end

function BoatContainer:GetItemInBoatSlot(slot)
    if slot and self.boatequipslots[slot] then
        return self.boatequipslots[slot]
    end
end

function BoatContainer:GetItemSlot(item)
    for k, v in pairs(self.slots) do
        if item == v then
            return k
        end
    end
end

function BoatContainer:Open(doer)
    if self.opener == nil and doer ~= nil then
        self.inst:StartUpdatingComponent(self)

        local inventory = doer.components.inventory
        if inventory ~= nil then
            for k, v in pairs(inventory.opencontainers) do
                if k.prefab == self.inst.prefab or k.components.container.type == self.type then
                    k.components.container:Close()
                end
            end

            inventory.opencontainers[self.inst] = true
        end

        self.opener = doer

        if doer.HUD ~= nil then
            if self.type == "boat" then
                doer.HUD:OpenBoat(self.inst, self.inst.entity:GetParent() == doer)
            else
                doer.HUD:OpenContainer(self.inst, self:IsSideWidget())
            end
            if self:IsSideWidget() then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/backpack_open")
            end
        elseif self.widget ~= nil
            and self.widget.buttoninfo ~= nil
            and doer.components.playeractionpicker ~= nil then
            doer.components.playeractionpicker:RegisterContainer(self.inst)
        end

        self.inst:PushEvent("onopen", {doer = doer})

        if self.onopenfn ~= nil then
            self.onopenfn(self.inst, {doer = doer})
        end
    end
end

function BoatContainer:Close(forceclose)
    if self.opener ~= nil and not (self.inst.components.sailable and self.inst.components.sailable.sailor == self.opener and not forceclose) then
        self.inst:StopUpdatingComponent(self)

        local doer = self.opener
        self.opener = nil

        if doer.HUD ~= nil then
            doer.HUD:CloseContainer(self.inst, self:IsSideWidget())
            if self:IsSideWidget() then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/backpack_close")
            end
        elseif doer.components.playeractionpicker ~= nil then
            doer.components.playeractionpicker:UnregisterContainer(self.inst)
        end

        if doer.components.inventory ~= nil then
            doer.components.inventory.opencontainers[self.inst] = nil
        end

        if self.onclosefn ~= nil then
            self.onclosefn(self.inst, doer)
        end

        self.inst:PushEvent("onclose", { doer = doer })
    end
end

function BoatContainer:IsOpen()
    return self.opener ~= nil
end

function BoatContainer:IsOpenedBy(guy)
    return self.opener == guy
end

function BoatContainer:CanOpen()
    return not self:IsOpen()
end

local function CheckItem(item, target, checkcontainer)
    return target ~= nil
        and (item == target
            or (checkcontainer and
                target.replica.container ~= nil and
                target.replica.container:IsHolding(item, checkcontainer)))
end

function BoatContainer:IsHolding(item, checkcontainer)
    for k, v in pairs(self.slots) do
        if CheckItem(item, v, checkcontainer) then
            return true
        end
    end
end

function BoatContainer:FindItem(fn)
    for k, v in pairs(self.slots) do
        if fn(v) then
            return v
        end
    end
end

function BoatContainer:FindItems(fn)
    local items = {}

    for k, v in pairs(self.slots) do
        if fn(v) then
            table.insert(items, v)
        end
    end

    return items
end

BoatContainer.FindCraftingItems = BoatContainer.FindItems

function BoatContainer:Has(item, amount)
    local num_found = 0
    for k, v in pairs(self.slots) do
        if v and v.prefab == item then
            if v.components.stackable ~= nil then
                num_found = num_found + v.components.stackable:StackSize()
            else
                num_found = num_found + 1
            end
        end
    end

    return num_found >= amount, num_found
end

function BoatContainer:GetItemByName(item, amount)
    local total_num_found = 0
    local items = {}

    local function tryfind(v)
        local num_found = 0
        if v and v.prefab == item then
            local num_left_to_find = amount - total_num_found
            if v.components.stackable then
                if v.components.stackable.stacksize > num_left_to_find then
                    items[v] = num_left_to_find
                    num_found = amount
                else
                    items[v] = v.components.stackable.stacksize
                    num_found = num_found + v.components.stackable.stacksize
                end
            else
                items[v] = 1
                num_found = num_found + 1
            end
        end
        return num_found
    end

    for k, v in pairs(self.slots) do
        total_num_found = total_num_found + tryfind(v)

        if total_num_found >= amount then
            break
        end
    end

    return items
end

local function crafting_priority_fn(a, b)
    if a.stacksize == b.stacksize then
        return a.slot < b.slot
    end
    return a.stacksize < b.stacksize  -- smaller stacks first
end

function BoatContainer:GetCraftingIngredient(item, amount, reverse_search_order)
    local items = {}
    for i = 1, self.numslots do
        local v = self.slots[i]
        if v ~= nil and v.prefab == item and not v:HasTag("nocrafting") then
            table.insert(items, {
                item = v,
                stacksize = GetStackSize(v),
                slot = reverse_search_order and (self.numslots - (i - 1)) or i,
            })
        end
    end
    table.sort(items, crafting_priority_fn)

    local crafting_items = {}
    local total_num_found = 0
    for i, v in ipairs(items) do
        local stacksize = math.min(v.stacksize, amount - total_num_found)
        crafting_items[v.item] = stacksize
        total_num_found = total_num_found + stacksize
        if total_num_found >= amount then
            break
        end
    end

    return crafting_items
end

local function tryconsume(self, v, amount)
    if v.components.stackable == nil then
        self:RemoveItem(v):Remove()
        return 1
    elseif v.components.stackable.stacksize > amount then
        v.components.stackable:SetStackSize(v.components.stackable.stacksize - amount)
        return amount
    else
        amount = v.components.stackable.stacksize
        self:RemoveItem(v, true):Remove()
        return amount
    end
    -- shouldn't be possible?
    return 0
end

function BoatContainer:ConsumeByName(item, amount)
    if amount <= 0 then
        return
    end

    for k, v in pairs(self.slots) do
        if v.prefab == item then
            amount = amount - tryconsume(self, v, amount)
            if amount <= 0 then
                return
            end
        end
    end
end

function BoatContainer:OnSave()
    local data = {items= {}, boatequipitems = {}}
    local references = {}
    local refs = {}
    for k, v in pairs(self.slots) do
        if v:IsValid() and v.persists then  -- only save the valid items
            data.items[k], refs = v:GetSaveRecord()
            if refs then
                for k, v in pairs(refs) do
                    table.insert(references, v)
                end
            end
        end
    end
    for k, v in pairs(self.boatequipslots) do
        if v:IsValid() and v.persists then  -- only save the valid items
            data.boatequipitems[k], refs = v:GetSaveRecord()
            if refs then
                for k, v in pairs(refs) do
                    table.insert(references, v)
                end
            end
        end
    end
    return data, references
end

function BoatContainer:OnLoad(data, newents)
    if data.items then
        for k, v in pairs(data.items) do
            local inst = SpawnSaveRecord(v, newents)
            if inst then
                self:GiveItem(inst, k)
            end
        end
    end
    if data.boatequipitems then
        for k, v in pairs(data.boatequipitems) do
            local inst = SpawnSaveRecord(v, newents)
            if inst then
                self:Equip(inst, false)
            end
        end
    end
end

function BoatContainer:Equip(item, old_to_active)
    if not item or not item.components.equippable or not item:IsValid() then
        return
    end

    local inventory = self.opener ~= nil and self.opener.components.inventory or nil

    item.prevslot = inventory and inventory:GetItemSlot(item) or nil

    if item.prevslot == nil and
        item.components.inventoryitem.owner ~= nil and
        item.components.inventoryitem.owner.components.container ~= nil and
        item.components.inventoryitem.owner.components.inventoryitem ~= nil then
        item.prevcontainer = item.components.inventoryitem.owner.components.container
        item.prevslot = item.components.inventoryitem.owner.components.container:GetItemSlot(item)
    else
        item.prevcontainer = nil
    end

    local leftovers = nil
    if item.components.inventoryitem == nil then
        item = self:RemoveItem(item, item.components.equippable.equipstack) or item
    elseif item.components.inventoryitem:IsHeld() then
        item = item.components.inventoryitem:RemoveFromOwner(item.components.equippable.equipstack) or item
    elseif item.components.stackable ~= nil and item.components.stackable:IsStack() and not item.components.equippable.equipstack then
        leftovers = item
        item = item.components.stackable:Get()
    end

    if inventory and item == inventory.activeitem then
        leftovers = inventory.activeitem
        inventory:SetActiveItem(nil)
    end

    local eslot = item.components.equippable.boatequipslot
    if self.boatequipslots[eslot] ~= item then
        local olditem = self.boatequipslots[eslot]
        if leftovers ~= nil then
            if old_to_active then
                inventory:GiveActiveItem(leftovers)
            else
                inventory.silentfull = true
                inventory:GiveItem(leftovers)
                inventory.silentfull = false
            end
        end
        if olditem then
            self:Unequip(eslot)
            olditem.components.equippable:ToPocket()
            if olditem.components.inventoryitem and not olditem.components.inventoryitem.cangoincontainer and not inventory.ignorescangoincontainer then
                olditem.components.inventoryitem:OnRemoved()
                self:DropItem(olditem)
            elseif old_to_active then
                inventory:GiveActiveItem(olditem)
            else
                inventory.silentfull = true
                inventory:GiveItem(olditem)
                inventory.silentfull = false
            end
        end

        item.components.inventoryitem:OnPutInInventory(self.inst)
        item.components.equippable:Equip(self.inst)
        self.boatequipslots[eslot] = item
        self.inst:PushEvent("equip", {item=item, eslot=eslot})
        return true
    end
end

function BoatContainer:Unequip(equipslot)
    local item = self.boatequipslots[equipslot]
     if item and item.components.equippable then
        item.components.equippable:Unequip(self.inst)
    end
    self.boatequipslots[equipslot] = nil
    self.inst:PushEvent("unequip", {item=item, eslot=equipslot})
    return item
end


function BoatContainer:RemoveItem(item, wholestack)
    if item == nil then
        return
    end

    local prevslot = self:GetItemSlot(item)

    if not wholestack and item.components.stackable ~= nil and item.components.stackable:IsStack() then
        local dec = item.components.stackable:Get()
        dec.prevslot = prevslot
        dec.prevcontainer = self
        return dec
    end

    for k, v in pairs(self.slots) do
        if v == item then
            self.slots[k] = nil
            self.inst:PushEvent("itemlose", { slot = k })
            item.components.inventoryitem:OnRemoved()
            item.prevslot = prevslot
            item.prevcontainer = self
            return item
        end
    end

    local inventory = self.opener ~= nil and self.opener.components.inventory or nil

    if inventory and item == inventory.activeitem then
        inventory:SetActiveItem()
        inventory.inst:PushEvent("itemlose", { activeitem = true })
        item.components.inventoryitem:OnRemoved()
        item.prevslot = prevslot
        item.prevcontainer = self
        return item
    end

    for k, v in pairs(self.boatequipslots) do
        if v == item then
            self:Unequip(k)
            item.components.inventoryitem:OnRemoved()
            item.prevslot = prevslot
            item.prevcontainer = nil
            return item
        end
    end

    return item
end

--------------------------------------------------------------------------
--Check for auto-closing conditions
--------------------------------------------------------------------------

function BoatContainer:OnUpdate(dt)
    if self.opener == nil then
        self.inst:StopUpdatingComponent(self)
    elseif not (self.inst.components.inventoryitem ~= nil and
                self.inst.components.inventoryitem:IsHeldBy(self.opener))
        and ((self.opener.components.rider ~= nil and self.opener.components.rider:IsRiding())
            or not (self.opener:IsNear(self.inst, 3) and
                    CanEntitySeeTarget(self.opener, self.inst))) then
        self:Close()
    end
end

BoatContainer.OnRemoveEntity = BoatContainer.Close
BoatContainer.OnRemoveFromEntity = BoatContainer.Close


--------------------------------------------------------------------------
--InvSlot click action handlers
--------------------------------------------------------------------------

local function QueryActiveItem(self)
    local inventory = self.opener ~= nil and self.opener.components.inventory or nil
    return inventory, inventory ~= nil and inventory:GetActiveItem() or nil
end

function BoatContainer:PutOneOfActiveItemInSlot(slot)
    local _, active_item = QueryActiveItem(self)
    if active_item ~= nil and
        self:GetItemInSlot(slot) == nil and
        self:CanTakeItemInSlot(active_item, slot) and
        active_item.components.stackable ~= nil and
        active_item.components.stackable:IsStack() then

        self.ignoresound = true
        self:GiveItem(active_item.components.stackable:Get(1), slot)
        self.ignoresound = false
    end
end

function BoatContainer:PutAllOfActiveItemInSlot(slot)
    local inventory, active_item = QueryActiveItem(self)
    if active_item ~= nil and
        self:GetItemInSlot(slot) == nil and
        self:CanTakeItemInSlot(active_item, slot) and
        (self:AcceptsStacks() or
        active_item.components.stackable == nil or
        not active_item.components.stackable:IsStack()) then

        inventory:RemoveItem(active_item, true)
        self.ignoresound = true
        self:GiveItem(active_item, slot)
        self.ignoresound = false
    end
end

function BoatContainer:TakeActiveItemFromHalfOfSlot(slot)
    local inventory, active_item = QueryActiveItem(self)
    local item = self:GetItemInSlot(slot)
    if item ~= nil and
        active_item == nil and
        inventory ~= nil and
        item.components.stackable ~= nil and
        item.components.stackable:IsStack() then

        local halfstack = item.components.stackable:Get(math.floor(item.components.stackable:StackSize() / 2))
        halfstack.prevslot = slot
        halfstack.prevcontainer = self
        inventory:GiveActiveItem(halfstack)
    end
end

function BoatContainer:TakeActiveItemFromAllOfSlot(slot)
    local inventory, active_item = QueryActiveItem(self)
    local item = self:GetItemInSlot(slot)
    if item ~= nil and
        active_item == nil and
        inventory ~= nil then

        self:RemoveItemBySlot(slot)
        inventory:GiveActiveItem(item)
    end
end

function BoatContainer:AddOneOfActiveItemToSlot(slot)
    local _, active_item = QueryActiveItem(self)
    local item = self:GetItemInSlot(slot)
    if active_item ~= nil and
        item ~= nil and
        self:CanTakeItemInSlot(active_item, slot) and
        (item.prefab == active_item.prefab and item.skinname == active_item.skinname) and
        item.components.stackable ~= nil and
        self:AcceptsStacks() and
        active_item.components.stackable ~= nil and
        active_item.components.stackable:IsStack() and
        not item.components.stackable:IsFull() then

        item.components.stackable:Put(active_item.components.stackable:Get(1))
    end
end

function BoatContainer:AddAllOfActiveItemToSlot(slot)
    local inventory, active_item = QueryActiveItem(self)
    local item = self:GetItemInSlot(slot)
    if active_item ~= nil and
        item ~= nil and
        self:CanTakeItemInSlot(active_item, slot) and
        (item.prefab == active_item.prefab and item.skinname == active_item.skinname) and
        item.components.stackable ~= nil and
        self:AcceptsStacks() then

        local leftovers = item.components.stackable:Put(active_item)
        inventory:SetActiveItem(leftovers)
    end
end

function BoatContainer:SwapActiveItemWithSlot(slot)
    local inventory, active_item = QueryActiveItem(self)
    local item = self:GetItemInSlot(slot)
    if active_item ~= nil and
        item ~= nil and
        self:CanTakeItemInSlot(active_item, slot) and
        not ((item.prefab == active_item.prefab and item.skinname == active_item.skinname) and
            item.components.stackable ~= nil and
            self:AcceptsStacks()) and
        not (active_item.components.stackable ~= nil and
            active_item.components.stackable:IsStack() and
            not self:AcceptsStacks()) then

        inventory:RemoveItem(active_item, true)
        self:RemoveItemBySlot(slot)
        inventory:GiveActiveItem(item)
        self:GiveItem(active_item, slot)
    end
end

function BoatContainer:BoatEquipActiveItem()
    local _, active_item = QueryActiveItem(self)
    if active_item ~= nil and
        active_item.components.equippable ~= nil and
        self:GetItemInBoatSlot(active_item.components.equippable.boatequipslot) == nil then

        self:Equip(active_item, true)
    end
end

function BoatContainer:SwapBoatEquipWithActiveItem()
    local _, active_item = QueryActiveItem(self)
    if active_item ~= nil and
        active_item.components.equippable ~= nil and
        self:GetItemInBoatSlot(active_item.components.equippable.boatequipslot) ~= nil then

        self:Equip(active_item, true)
    end
end

function BoatContainer:IsItemBoatEquipped(item)
    for k, v in pairs(self.boatequipslots) do
        if v == item then
            return k
        end
    end
end

function BoatContainer:TakeActiveItemFromBoatEquipSlot(eslot)
    local item = self:GetItemInBoatSlot(eslot)
    local inventory, active_item = QueryActiveItem(self)
    if item ~= nil and active_item == nil then
        if inventory.maxslots > 0 then
            if self.boatequipslots[eslot] then
                local olditem = active_item
                local newitem = self:Unequip(eslot)
                inventory:SetActiveItem(newitem)

                if olditem and not self:IsItemBoatEquipped(olditem) then
                    inventory:GiveItem(olditem)
                end
            end
        else
            self:DropItem(self:Unequip(eslot), true, true)
        end
    end
end

function BoatContainer:TakeActiveItemFromBoatEquipSlotID(eslotid)
    self:TakeActiveItemFromBoatEquipSlot(EquipSlot.BoatFromID(eslotid))
end

function BoatContainer:MoveItemFromAllOfSlot(slot, container)
    local item = self:GetItemInSlot(slot)
    if item ~= nil and container ~= nil then
        container = container.components.container or container.components.inventory
        if container ~= nil and container:IsOpenedBy(self.opener) then
            local targetslot =
                self.opener.components.constructionbuilderuidata ~= nil and
                self.opener.components.constructionbuilderuidata:GetContainer() == container.inst and
                self.opener.components.constructionbuilderuidata:GetSlotForIngredient(item.prefab) or
                nil

            if container:CanTakeItemInSlot(item, targetslot) then
                item = self:RemoveItemBySlot(slot)
                item.prevcontainer = nil
                item.prevslot = nil

                -- Hacks for altering normal inventory:GiveItem() behaviour
                if container.ignoreoverflow ~= nil and container:GetOverflowContainer() == self then
                    container.ignoreoverflow = true
                end
                if container.ignorefull ~= nil then
                    container.ignorefull = true
                end

                if not container:GiveItem(item, targetslot) then
                    self:GiveItem(item, slot, nil, true)
                end

                -- Hacks for altering normal inventory:GiveItem() behaviour
                if container.ignoreoverflow then
                    container.ignoreoverflow = false
                end
                if container.ignorefull then
                    container.ignorefull = false
                end
            end
        end
    end
end

function BoatContainer:MoveItemFromHalfOfSlot(slot, container)
    local item = self:GetItemInSlot(slot)
    if item ~= nil and container ~= nil then
        container = container.components.container or container.components.inventory
        if container ~= nil and
            container:IsOpenedBy(self.opener) and
            item.components.stackable ~= nil and
            item.components.stackable:IsStack() then

            local targetslot =
                self.opener.components.constructionbuilderuidata ~= nil and
                self.opener.components.constructionbuilderuidata:GetContainer() == container.inst and
                self.opener.components.constructionbuilderuidata:GetSlotForIngredient(item.prefab) or
                nil

            if container:CanTakeItemInSlot(item, targetslot) then
                local halfstack = item.components.stackable:Get(math.floor(item.components.stackable:StackSize() / 2))
                halfstack.prevcontainer = nil
                halfstack.prevslot = nil

                -- Hacks for altering normal inventory:GiveItem() behaviour
                if container.ignoreoverflow ~= nil and container:GetOverflowContainer() == self then
                    container.ignoreoverflow = true
                end
                if container.ignorefull ~= nil then
                    container.ignorefull = true
                end

                if not container:GiveItem(halfstack, targetslot) then
                    self.ignoresound = true
                    self:GiveItem(halfstack, slot, nil, true)
                    self.ignoresound = false
                end

                -- Hacks for altering normal inventory:GiveItem() behaviour
                if container.ignoreoverflow then
                    container.ignoreoverflow = false
                end
                if container.ignorefull then
                    container.ignorefull = false
                end
            end
        end
    end
end

function BoatContainer:ReferenceAllItems()
    local items = {}
    for i = 1, self.numslots do
        if self.slots[i] ~= nil then
            table.insert(items, self.slots[i])
        end
    end
    return items
end

function BoatContainer:EnableInfiniteStackSize(enable)
	local _ = rawget(self, "_") --see class.lua for property setters implementation
	if enable then
		if not _.infinitestacksize[1] then
			_.infinitestacksize[1] = true
			for i = 1, self.numslots do
				local item = self.slots[i]
				if item and item.components.stackable then
					item.components.stackable:SetIgnoreMaxSize(true)
				end
			end
			self.inst.replica.container:EnableInfiniteStackSize(true)
		end
	elseif _.infinitestacksize[1] then
		_.infinitestacksize[1] = nil
		local x, y, z = self.inst.Transform:GetWorldPosition()
		for i = 1, self.numslots do
			local item = self.slots[i]
			if item and item.components.stackable then
				self:DropOverstackedExcess(item)
				item.components.stackable:SetIgnoreMaxSize(false)
			end
			self.inst.replica.container:EnableInfiniteStackSize(false)
		end
	end
end

function BoatContainer:IsRestricted(target)
    if not target:HasTag("player") then
        -- Restricted tags only apply to players.
        return false
    end

    return self.restrictedtag ~= nil
        and self.restrictedtag:len() > 0
        and not target:HasTag(self.restrictedtag)
end

return BoatContainer
