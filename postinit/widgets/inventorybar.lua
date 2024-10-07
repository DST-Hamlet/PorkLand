GLOBAL.setfenv(1, GLOBAL)

local InventoryBar = require("widgets/inventorybar")

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
local function RebuildLayout(self, inventory, overflow, do_integrated_backpack, ...)
    local boatwidget = self.boatwidget
    if boatwidget then
        local x, _, z = boatwidget:GetPosition():Get()
        boatwidget:SetPosition(x, do_integrated_backpack and 115 or 75, z)
    end

    _RebuildLayout(self, inventory, overflow, do_integrated_backpack, ...)
end

ToolUtil.SetUpvalue(InventoryBar.Rebuild, RebuildLayout, "RebuildLayout")
