local PLENV = env
GLOBAL.setfenv(1, GLOBAL)
local Grid = require("widgets/grid")
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

    self:UpdateFrame(true)

    return w
end

local _MakeFilterPanel = CraftingMenuWidget.MakeFilterPanel
function CraftingMenuWidget:MakeFilterPanel(...)
    local _FillGrid = Grid.FillGrid
    Grid.FillGrid = function(grid, num_columns, coffset, roffset, items, ...)
        self.grid_buttons_wide = num_columns
        self:SetFilter(items)
        local valid_filters = self:GetValidFilter()
        return _FillGrid(grid, num_columns, coffset, roffset, valid_filters, ...)
    end

    local filter_panel = _MakeFilterPanel(self, ...)
    Grid.FillGrid = _FillGrid

    -- add prototyper filter grid

    self.filter_line = filter_panel:FindChild(FindImageChild("line_horizontal_white.tex"))
    self.filter_line_pt = self.filter_line:GetPosition()
    self.filter_grid_pt = filter_panel.filter_grid:GetPosition()

    local prototyper_filter_grid = filter_panel:AddChild(Grid())
    prototyper_filter_grid:SetLooping(false, false)
    prototyper_filter_grid:FillGrid(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, self.prototyper_filters)
    prototyper_filter_grid:SetPosition(self.filter_grid_pt.x, - self.grid_button_space)
    filter_panel.prototyper_filter_grid = prototyper_filter_grid

    filter_panel.panel_height = filter_panel.panel_height + self.grid_button_space * prototyper_filter_grid.num_rows

    return filter_panel
end

local _UpdateFilterButtons = CraftingMenuWidget.UpdateFilterButtons
function CraftingMenuWidget:UpdateFilterButtons(...)
    self:UpdateFrame()
    return _UpdateFilterButtons(self, ...)
end

function CraftingMenuWidget:SetFilter(filters)
    self.filters = {}
    self.prototyper_filters = {}

    for i, filter in ipairs(filters) do
        if filter.filter_def.home_prototyper then
            table.insert(self.prototyper_filters, filter)
        else
            table.insert(self.filters, filter)
        end
    end
end

function CraftingMenuWidget:GetValidFilter()
    local builder = self.owner ~= nil and self.owner.replica.builder or nil

    local valid_filters = {}
    for i, filter in ipairs(self.filters) do
        if (builder and builder:IsFreeBuildMode())
            or not (filter.filter_def.disabled_worlds and TheWorld:HasTags(filter.filter_def.disabled_worlds))
            then
            filter:Show()
            table.insert(valid_filters, filter)
        else
            filter:Hide()
        end
    end

    return valid_filters
end

function CraftingMenuWidget:GetPrototyperFilter()
    if self.owner.replica.builder then
        local tech_bonus = self.owner.replica.builder:GetTechBonuses()
        if tech_bonus.HOME >= 2 then
            return self.prototyper_filters
        end
    end
    return {}
end

function CraftingMenuWidget:UpdateFrame(force)
    local _filter_grid_num_rows = self.filter_panel.filter_grid.num_rows
    local _prototyper_filter_grid_num_rows = self.filter_panel.prototyper_filter_grid.num_rows

    local valid_prototyper_filters = self:GetPrototyperFilter()
    self.filter_panel.prototyper_filter_grid:RebuildLayout(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, valid_prototyper_filters)
    if #valid_prototyper_filters > 0 then
        self.filter_panel.prototyper_filter_grid:Show()
    else
        self.filter_panel.prototyper_filter_grid:Hide()
    end

    local delta = _prototyper_filter_grid_num_rows - self.filter_panel.prototyper_filter_grid.num_rows
    if delta ~= 0 or force then
        local prototyper_filter_grid_height = self.filter_panel.prototyper_filter_grid.num_rows * self.grid_button_space
        self.filter_line:SetPosition(self.filter_line_pt.x, self.filter_line_pt.y - prototyper_filter_grid_height)
        self.filter_panel.filter_grid:SetPosition(self.grid_left, self.filter_grid_pt.y - prototyper_filter_grid_height)
    end

    local valid_filters = self:GetValidFilter()
    self.filter_panel.filter_grid:RebuildLayout(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, valid_filters)

    delta = delta + _filter_grid_num_rows - self.filter_panel.filter_grid.num_rows
    if delta == 0 and not force then
        return
    end

    local filters_height = self.filter_panel.panel_height - self.grid_button_space * delta
    self.filter_panel.panel_height = filters_height

    local width = self.frame_width
    local height = self.frame_height + math.max(filters_height - 147, 0)

    self.frame_fill:ScaleToSize(width + 10, height + 18)
    self.frame_left:ScaleToSize(-26, -(height - 20))
    self.frame_right:ScaleToSize(26, height - 20)
    self.frame_top:SetPosition(0, height / 2 + 10)
    self.frame_bottom:SetPosition(0, -height / 2 - 8)

    self.filter_panel:SetPosition(0, height / 2 - 20)

    local grid_w, grid_h = self.recipe_grid:GetScrollRegionSize() -- 231
    self.recipe_grid:SetPosition(-2, height / 2 - filters_height - grid_h / 2)

    self.no_recipes_msg:SetPosition(-2, height / 2 - filters_height - grid_h / 2)
    self.itemlist_split:SetPosition(0, height / 2 - filters_height)
    self.itemlist_split2:SetPosition(0, height / 2 - filters_height - grid_h - 2)

    self.details_root.panel_height = height - 20 * 2
    self.details_root:SetPosition(0, height / 2 - filters_height - grid_h - 10)

    self.nav_hint:SetPosition(0, -height / 2 - 30)
end


PLENV.OnHotReload = function()
    CraftingMenuWidget.MakeFrame = _MakeFrame
    CraftingMenuWidget.MakeFilterPanel = _MakeFilterPanel
    CraftingMenuWidget.UpdateFilterButtons = _UpdateFilterButtons
end
