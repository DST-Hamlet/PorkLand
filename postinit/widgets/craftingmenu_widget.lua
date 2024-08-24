local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local Grid = require("widgets/grid")

local DISABLE_CRAFTING_FILTERS = require("main/recipes_change").DISABLE_CRAFTING_FILTERS
local CraftingMenuWidget = require("widgets/redux/craftingmenu_widget")

local function FindImageChild(texture, fn)
    return function(child)
        return child.texture == texture
    end
end

local _MakeFrame = CraftingMenuWidget.MakeFrame
function CraftingMenuWidget:MakeFrame(width, height)
    local w = _MakeFrame(self, width, height)

    self.frame_width = width
    self.frame_height = height
    self.frame_fill = w:FindChild(FindImageChild("backing.tex"))
    self.frame_left = w:FindChild(function(child)
        local pos = child:GetPosition()
        return child.texture == "side.tex" and pos.x < 0
    end)
    self.frame_right =  w:FindChild(function(child)
        local pos = child:GetPosition()
        return child.texture == "side.tex" and pos.x > 0
    end)
    self.frame_top = w:FindChild(FindImageChild("top.tex"))
    self.frame_bottom = w:FindChild(FindImageChild("bottom.tex"))

    return w
end

local _MakeFilterPanel = CraftingMenuWidget.MakeFilterPanel
function CraftingMenuWidget:MakeFilterPanel(...)
    local _FillGrid = Grid.FillGrid
    Grid.FillGrid = function(grid, num_columns, coffset, roffset, items, ...)
        self.grid_buttons_wide = num_columns
        self.grid_items = items
        local valid_items = self:GetValidFilter()
        return _FillGrid(grid, num_columns, coffset, roffset, valid_items, ...)
    end

    local result = {_MakeFilterPanel(self, ...)}
    Grid.FillGrid = _FillGrid

    return unpack(result)
end

local _UpdateFilterButtons = CraftingMenuWidget.UpdateFilterButtons
function CraftingMenuWidget:UpdateFilterButtons(...)
    self:UpdateFrame()
    return _UpdateFilterButtons(self, ...)
end

function CraftingMenuWidget:GetValidFilter()
    local builder = self.owner ~= nil and self.owner.replica.builder or nil

    local valid_filters = {}
    for i, button in ipairs(self.grid_items) do
        if (builder and builder:IsFreeBuildMode())
            or not TheWorld:HasTag("porkland")
            or not DISABLE_CRAFTING_FILTERS[button.name] then

            if not button.shown then
                button:Show()
            end

            table.insert(valid_filters, button)
        elseif button.shown then
            button:Hide()
        end
    end

    return valid_filters
end

function CraftingMenuWidget:UpdateFrame()
    local _num_rows = self.filter_panel.filter_grid.num_rows

    local valid_items = self:GetValidFilter()
    self.filter_panel.filter_grid:RebuildLayout(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, valid_items)

    local delta = _num_rows - self.filter_panel.filter_grid.num_rows
    if delta == 0 then
        return
    end

    self.filter_panel.panel_height = self.filter_panel.panel_height - self.grid_button_space * delta
    local filters_height = self.filter_panel.panel_height

    self.frame_width = 500
    local width = self.frame_width
    local height = self.frame_height + math.max(filters_height - 147, 0)

    self.frame_fill:ScaleToSize(width + 10, height + 18)
    self.frame_left:ScaleToSize(-26, -(height - 20))
    self.frame_right:ScaleToSize(26, height - 20)
    self.frame_top:SetPosition(0, height/2 + 10)
    self.frame_bottom:SetPosition(0, -height/2 - 8)

    self.filter_panel:SetPosition(0, height/2 - 20)

    local grid_w, grid_h = self.recipe_grid:GetScrollRegionSize() -- 231
	self.recipe_grid:SetPosition(-2, height/2 - filters_height - grid_h/2)

    self.no_recipes_msg:SetPosition(-2, height/2 - filters_height - grid_h/2)
    self.itemlist_split:SetPosition(0, height/2 - filters_height)
    self.itemlist_split2:SetPosition(0, height/2 - filters_height - grid_h - 2)

    self.details_root.panel_height = height - 20 * 2
	self.details_root:SetPosition(0, height/2 - filters_height - grid_h - 10)

    self.nav_hint:SetPosition(0, - height/2 - 30)
end


PLENV.OnHotReload = function()
    CraftingMenuWidget.MakeFrame = _MakeFrame
    CraftingMenuWidget.MakeFilterPanel = _MakeFilterPanel
    CraftingMenuWidget.UpdateFilterButtons = _UpdateFilterButtons
end
