local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local InventoryBar = require("widgets/inventorybar")
local HudCompass_Wheeler = require ("widgets/hudcompass_wheeler")

local W = 68
local SEP = 12
local INTERSEP = 28

local _GetInventoryLists = InventoryBar.GetInventoryLists
function InventoryBar:GetInventoryLists(same_container_only, ...)
    same_container_only = false
    local lists = _GetInventoryLists(self, same_container_only, ...)
    if not same_container_only then
        local firstcontainer = self.owner.HUD:GetFirstOpenContainerWidget()
        if firstcontainer then
            if firstcontainer.boatEquip then
                table.insert(lists, firstcontainer.boatEquip)
            end
        end
        local containers = self.owner.HUD.controls.containers
        if containers then
            for k, v in pairs(containers) do
                if v and v ~= firstcontainer then
                    table.insert(lists, v.inv)
                    if v.boatEquip then
                        table.insert(lists, v.boatEquip)
                    end
                end
            end
        end
    end
    return lists
end

local _RebuildLayout = ToolUtil.GetUpvalue(InventoryBar.Rebuild, "RebuildLayout")
local function RebuildLayout(self, inventory, overflow, do_integrated_backpack, do_self_inspect, ...)
    local boatwidget = self.boatwidget
    if boatwidget then
        local x, _, z = boatwidget:GetPosition():Get()
        boatwidget:SetPosition(x, do_integrated_backpack and 115 or 75, z)
    end

    -- 复制自scripts/widgets/inventorybar，用于计算特定装备在物品栏中的位置

    local num_slots = inventory:GetNumSlots()
    local num_equip = #self.equipslotinfo
    local num_buttons = do_self_inspect and 1 or 0
    local num_slotintersep = math.ceil(num_slots / 5)
    local num_equipintersep = num_buttons > 0 and 1 or 0
    local total_w = (num_slots + num_equip + num_buttons) * W + (num_slots + num_equip + num_buttons - num_slotintersep - num_equipintersep - 1) * SEP + (num_slotintersep + num_equipintersep) * INTERSEP

	local x = (W - total_w) * .5 + num_slots * W + (num_slots - num_slotintersep) * SEP + num_slotintersep * INTERSEP
    for k, v in ipairs(self.equipslotinfo) do
        if v.slot == EQUIPSLOTS.HANDS then
            self.hudcompass_wheeler:SetPosition(x, do_integrated_backpack and 190 or 150, 0)
        end

        x = x + W + SEP
    end

    _RebuildLayout(self, inventory, overflow, do_integrated_backpack, do_self_inspect, ...)
end

ToolUtil.SetUpvalue(InventoryBar.Rebuild, RebuildLayout, "RebuildLayout")

AddClassPostConstruct("widgets/inventorybar", function(self)
    self.hudcompass_wheeler = self.root:AddChild(HudCompass_Wheeler(self.owner, true))
    self.hudcompass_wheeler:SetScale(1.5, 1.5)
    self.hudcompass_wheeler:SetMaster()
    self.hudcompass_wheeler:MoveToBack()
end)
