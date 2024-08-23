local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Grid = require("widgets/grid")

local DISABLE_CRAFTING_FILTERS = require("main/recipes_change").DISABLE_CRAFTING_FILTERS
local CraftingMenuWidget = require("widgets/redux/craftingmenu_widget")

local _MakeFilterPanel = CraftingMenuWidget.MakeFilterPanel
function CraftingMenuWidget:MakeFilterPanel(...)
    local _FillGrid = Grid.FillGrid
    Grid.FillGrid = function(grid, num_columns, coffset, roffset, items, ...)
        self.grid_buttons_wide = num_columns
        self.grid_items = items
        return _FillGrid(grid, num_columns, coffset, roffset, items, ...)
    end
    local result = {_MakeFilterPanel(self, ...)}
    Grid.FillGrid = _FillGrid

    return unpack(result)
end

local _UpdateFilterButtons = CraftingMenuWidget.UpdateFilterButtons
function CraftingMenuWidget:UpdateFilterButtons(...)
    local builder = self.owner ~= nil and self.owner.replica.builder or nil

    local widgets = {}
    for i, button in ipairs(self.grid_items) do
        if (builder and builder:IsFreeBuildMode()) or not DISABLE_CRAFTING_FILTERS[button.name]  then
            if not button.shown then
                button:Show()
            end

            table.insert(widgets, button)
        elseif button.shown then
            button:Hide()
        end
    end
    self.filter_panel.filter_grid:RebuildLayout(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, widgets)

    return _UpdateFilterButtons(self, ...)
end


PLENV.OnHotReload = function()
    CraftingMenuWidget.UpdateFilterButtons = _UpdateFilterButtons
end
