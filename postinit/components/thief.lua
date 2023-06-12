local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local Thief = Class(function(self, inst)
    self.inst = inst
    self.stolenitems = {}
    self.onstolen--[[inst, victim, item]] = nil
    self.canopencontainers = true
    self.dropdistance = 1.0
end)

function Thief:SetOnStolenFn(fn)
    self.onstolen = fn
end

function Thief:SetDropDistance(dropdistance)
    self.dropdistance = dropdistance
end

function Thief:SetCanOpenContainers(canopen)
    self.canopencontainers = canopen
end

function Thief:StealItem(victim, itemtosteal, attack, food, setspeed)
    if victim.components.inventory and not victim.components.inventory.nosteal then
        local item = nil
        if itemtosteal then
            item = itemtosteal
        else
            if food then
                item = victim.components.inventory:FindItem(
                    function(item)
                        return
                            self.inst.components.eater:AbleToEat(item)
                            and (
                                    not item:HasTag("nosteal")
                                    or not (item.components.inventoryitem:IsHeld() and self.inst:HasTag("cannotstealequipped"))
                                )
                    end)
            else
                item = victim.components.inventory:FindItem(
                    function(item)
                        return not item:HasTag("nosteal")
                        or not (item.components.inventoryitem:IsHeld() and self.inst:HasTag("cannotstealequipped"))
                    end)
            end
        end

        if attack then
            self.inst.components.combat:DoAttack(victim)
        end

        if item then
            local direction = Vector3(self.inst.Transform:GetWorldPosition()) - Vector3(victim.Transform:GetWorldPosition() )
            victim.components.inventory:DropItem(item, false, direction:GetNormalized() * self.dropdistance, nil, nil, nil, setspeed)
            table.insert(self.stolenitems, item)
            if self.onstolen then
                self.onstolen(self.inst, victim, item)
            end
        end
    elseif victim.components.container and self.canopencontainers then
        local item = itemtosteal or victim.components.container:FindItem(function(item) return not item:HasTag("nosteal") end)

        if attack then
            if victim.components.equippable and victim.components.inventoryitem and victim.components.inventoryitem.owner then
                self.inst.components.combat:DoAttack(victim.components.inventoryitem.owner)
            end
        end

        victim.components.container:DropItem(item)
        table.insert(self.stolenitems, item)
        if self.onstolen then
            self.onstolen(self.inst, victim, item)
        end
    end
end
