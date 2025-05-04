GLOBAL.setfenv(1, GLOBAL)
local InvSlot = require("widgets/invslot")

local SUPPORTED_ITEMS = {
    ["abigail_flower"] = true,
}

local use_item = InvSlot.UseItem
function InvSlot:UseItem(...)
    local item = self.tile and self.tile.item
    if item then
        local inventory = ThePlayer and ThePlayer.replica.inventory
        if inventory then
            if not TheInput:ControllerAttached() and SUPPORTED_ITEMS[item.prefab] and item.components.spellbook then
                local action = ThePlayer.components.playeractionpicker:GetInventoryActions(item)[1]
                -- print(action)
                if action then
                    if action.action == ACTIONS.USESPELLBOOK then
                        -- print("ThePlayer.HUD.controls.spellcontrols:Open()")
                        ThePlayer.HUD.controls.spellcontrols:Open(item.components.spellbook.items, item, self.tile:GetWorldPosition())
                        return
                    end
                    if action.action == ACTIONS.CLOSESPELLBOOK then
                        ThePlayer.HUD.controls.spellcontrols:Close()
                        return
                    end
                end
            end

            -- inventory:UseItemFromInvTile(item)
        end
    end
    return use_item(self, ...)
end
