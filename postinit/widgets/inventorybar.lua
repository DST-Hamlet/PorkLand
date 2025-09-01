local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local InventoryBar = require("widgets/inventorybar")
local HudCompass_Wheeler = require ("widgets/hudcompass_wheeler")

local W = 68
local SEP = 12
local INTERSEP = 28

local RebuildLayout, scope_fn, i = ToolUtil.GetUpvalue(InventoryBar.Rebuild, "RebuildLayout")
debug.setupvalue(scope_fn, i, function(self, inventory, overflow, do_integrated_backpack, do_self_inspect, ...)
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
            self.hudcompass_wheeler:SetBasePosition(x, do_integrated_backpack and 80 or 40, 0)
        end

        x = x + W + SEP
    end

    RebuildLayout(self, inventory, overflow, do_integrated_backpack, do_self_inspect, ...)

    local bg_scale = (1.15 * total_w) / (1480) -- This is a bit ugly, the hardcoded 1480 is the standard width for a regular inventory total_w
    self.bg:SetScale(bg_scale, 1, 1)
    self.bgcover:SetScale(bg_scale, 1, 1)
end)

AddClassPostConstruct("widgets/inventorybar", function(self)
    self.hudcompass_wheeler = self.root:AddChild(HudCompass_Wheeler(self.owner, true))
    self.hudcompass_wheeler:SetScale(1.5, 1.5)
    self.hudcompass_wheeler:SetMaster()
    self.hudcompass_wheeler:MoveToBack()
end)
