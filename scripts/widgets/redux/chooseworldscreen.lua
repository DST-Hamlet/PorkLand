local Widget = require("widgets/widget")
local Screen = require("widgets/screen")
local TEMPLATES = require("widgets/redux/templates")
local Text = require("widgets/text")
local Image = require("widgets/image")

local window_width = 400
local window_height = 550

local widget_width = 400
local widget_height = 80

local padded_width = widget_width + 10
local padded_height = widget_height + 10

local num_rows = math.floor(500 / padded_height)
local peek_height = math.abs(num_rows * padded_height - 500)

local dialog_width = window_width + 72
local dialog_height = window_height + 4
local r, g, b = unpack(UICOLOURS.BROWN_DARK)

local apply_str = STRINGS.UI.HELP.APPLY

STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC = {
    FOREST = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.SURVIVAL_TOGETHER,
    CAVE = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.DST_CAVE,
}

local ChooseWorldSreen = Class(Screen, function(self, parent_widget, currentworld, i, SetLevelLocations, WorldLocations)
    Screen._ctor(self, "ChooseWorldSreen")

    self.parent_widget = parent_widget
    self.onconfirmfn = SetLevelLocations
    self.locations = WorldLocations
    self.worlds = {}
    self.index = i

    self.root = self:AddChild(TEMPLATES.ScreenRoot())
    self.bg = self.root:AddChild(TEMPLATES.BackgroundTint(0.7))

    self.dialog_bg = self.root:AddChild(TEMPLATES.PlainBackground())
    self.dialog_bg:SetScissor(-dialog_width / 2, -dialog_height / 2, dialog_width, dialog_height)

    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(window_width, window_height))
    self.dialog:SetBackgroundTint(r,g,b, 0.6)

    if not TheInput:ControllerAttached() then
        self.cancel_button = self.root:AddChild(TEMPLATES.BackButton(function() self:OnCancel() end))
        self.select_button = self.root:AddChild(TEMPLATES.StandardButton(function() self:OnConfirmWorld() end, apply_str))
        self.select_button:SetScale(0.7)
        self.select_button:SetPosition(420, -310)
    end

    self.world_label = self.root:AddChild(Text(CHATFONT, 35))
    self.world_label:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
    self.world_label:SetHAlign(ANCHOR_MIDDLE)
    self.world_label:SetString(STRINGS.UI.SANDBOXMENU.CHOOSEWORLD)
    self.world_label:SetPosition(0, 250)

    self.horizontal_line = self.root:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
    self.horizontal_line:SetPosition(0, window_height / 2 - 48)
    self.horizontal_line:SetSize(dialog_width, 5)

    for k, v in pairs(self.locations[self.index]) do
        local world = {
            data = string.lower(k),
            text = STRINGS.UI.SANDBOXMENU.LOCATIONTABNAME[k],
            desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[k]
        }
        table.insert(self.worlds, world)
    end

    self:OnSelectWorld(currentworld or self.worlds[1].data)

    local normal_list_item_bg_tint = {1, 1, 1, 0.4}
    local focus_list_item_bg_tint  = {1, 1, 1, 0.6}
    local current_list_item_bg_tint = {1, 1, 1, 0.8}
    local focus_current_list_item_bg_tint  = {1, 1, 1, 1}

    local ScrollWidgetsCtor = function(context, i)
        local world = Widget("world-" .. i)
        world:SetOnGainFocus(function() self.scroll_list:OnWidgetFocus(world) end)

        world.backing = world:AddChild(TEMPLATES.ListItemBackground(padded_width, padded_height, function()
            self:OnWorldButton(world.data)
        end))
        world.backing.move_on_click = true

        world.name = world.backing:AddChild(Text(CHATFONT, 26))
        world.name:SetHAlign(ANCHOR_LEFT)
        world.name:SetRegionSize(padded_width - 40, 30)
        world.name:SetPosition(0, padded_height / 2 - 22.5)

        world.desc = world.backing:AddChild(Text(CHATFONT, 16))
        world.desc:SetVAlign(ANCHOR_MIDDLE)
        world.desc:SetHAlign(ANCHOR_LEFT)
        world.desc:SetPosition(0, padded_height / 2 - (20 + 26 + 10))

        world.focus_forward = world.backing

        return world
    end

    local ApplyDataToWidget = function(context, world, world_data, index)
        if not world_data then
            world.backing:Hide()
            world.data = nil
            return
        end

        if self.selectedworld == world_data.data then
            world.backing:Select()
            world.name:SetColour(UICOLOURS.GOLD_SELECTED)
        else
            world.backing:Unselect()
            world.name:SetColour(UICOLOURS.GOLD_CLICKABLE)
        end

        if world.data ~= world_data then
            world.data = world_data
            world.backing:Show()

            world.name:SetString(world_data.text)
            world.desc:SetMultilineTruncatedString(world_data.desc, 3, padded_width - 40, nil, "...")

            if world_data.data == currentworld then
                world.backing:SetImageNormalColour(unpack(current_list_item_bg_tint))
                world.backing:SetImageFocusColour(unpack(focus_current_list_item_bg_tint))
                world.backing:SetImageSelectedColour(unpack(current_list_item_bg_tint))
                world.backing:SetImageDisabledColour(unpack(current_list_item_bg_tint))
            else
                world.backing:SetImageNormalColour(unpack(normal_list_item_bg_tint))
                world.backing:SetImageFocusColour(unpack(focus_list_item_bg_tint))
                world.backing:SetImageSelectedColour(unpack(normal_list_item_bg_tint))
                world.backing:SetImageDisabledColour(unpack(normal_list_item_bg_tint))
            end
        end
    end

    self.scroll_list = self.root:AddChild(TEMPLATES.ScrollingGrid(
        self.worlds, {
            context = {},
            widget_width  = padded_width,
            widget_height = padded_height,
            num_visible_rows = num_rows,
            num_columns      = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn     = ApplyDataToWidget,
            scrollbar_offset = 10,
            scrollbar_height_offset = -50,
            peek_height = peek_height,
            force_peek = true,
            end_offset = 1 - peek_height/padded_height,
        }
    ))
    self.scroll_list:SetPosition(0 + (self.scroll_list:CanScroll() and -10 or 0), -25)

    self.default_focus = self.scroll_list
end)

function ChooseWorldSreen:OnWorldButton(world)
    self:OnSelectWorld(world.data)
    self:Refresh()
end

function ChooseWorldSreen:Refresh()
    self.scroll_list:RefreshView()
end

function ChooseWorldSreen:OnCancel()
    self:_Close()
end

function ChooseWorldSreen:OnConfirmWorld()
    self:_Close()
    self.onconfirmfn(self.parent_widget.servercreationscreen, self.selectedworld, self.index)
end

function ChooseWorldSreen:OnSelectWorld(world)
    self.selectedworld = world
end

function ChooseWorldSreen:OnControl(control, down)
    if ChooseWorldSreen._base.OnControl(self, control, down) then return true end

    if not down then
        if control == CONTROL_CANCEL then
            self:OnCancel()
            return true
        elseif control == CONTROL_PAUSE then
            self:OnConfirmWorld()
            return true
        end
    end
end

function ChooseWorldSreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.CANCEL)
    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. apply_str)

    return table.concat(t, "  ")
end

function ChooseWorldSreen:_Close()
    TheFrontEnd:PopScreen()
end

return ChooseWorldSreen
