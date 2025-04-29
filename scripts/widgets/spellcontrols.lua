local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local UIAnimButton = require("widgets/uianimbutton")
local UIAnim = require("widgets/uianim")

local SpellControls = Class(Widget, function(self, owner)
    Widget._ctor(self, "SpellControls")

    self.owner = owner

    self.source_item = nil
    self.anchor_position = Vector3()
    self.items = {}
    self.isopen = false
end)

function SpellControls:IsOpen()
    return self.isopen
end

local function UnpackAnimData(data_in, owner)
    local data_out = FunctionOrValue(data_in, owner)
    if data_out then
        return data_out.anim, data_out.loop
    end
end

function SpellControls:SetItems(items_data, source_item, anchor_position)
    if source_item then
        self.source_item = source_item
    end
    if anchor_position then
        self.anchor_position = anchor_position
    end

    for _, item in ipairs(self.items) do
        item.button:Kill()
    end
    self.items = {}

    -- self.numspacers = 0

    local visible_buttons = {}

    for i, item_data in ipairs(items_data) do
        local button
        if item_data.anims then
            button = self:AddChild(UIAnimButton(item_data.bank, item_data.build))
            button.animstate:Hide("mouseover")
            button.overrideclicksound = item_data.clicksound

            button:SetIdleAnim(UnpackAnimData(item_data.anims.idle, self.owner))
            button:SetDisabledAnim(UnpackAnimData(item_data.anims.focus, self.owner))
            button:SetSelectedAnim(UnpackAnimData(item_data.anims.disabled, self.owner))
            button:SetFocusAnim(UnpackAnimData(item_data.anims.down, self.owner))
            button:SetDownAnim(UnpackAnimData(item_data.anims.selected, self.owner))

            if item_data.checkcooldown then
                button.cooldown = button:AddChild(UIAnim())
                button.cooldown:SetClickable(false)
                button.cooldown:GetAnimState():SetBank(item_data.bank)
                button.cooldown:GetAnimState():SetBuild(item_data.build)
                if item_data.cooldowncolor then
                    button.cooldown:GetAnimState():SetMultColour(unpack(item_data.cooldowncolor))
                end
                button.cooldown:Hide()
            end
        else
            button = self:AddChild(ImageButton(item_data.atlas, item_data.normal, item_data.focus, item_data.disabled, item_data.down, item_data.selected, item_data.scale, item_data.offset))
            button:SetImageNormalColour(.8, .8, .8, 1)
            button:SetImageFocusColour(1, 1, 1, 1)
            button:SetImageDisabledColour(0.7, 0.7, 0.7, 0.7)
        end

        button:SetHoverText(item_data.label, { offset_y = 60 })

        if item_data.widget_scale ~= nil then
            button:SetScale(item_data.widget_scale)
        end
        if item_data.hit_radius ~= nil then
            button.image:SetRadiusForRayTraces(item_data.hit_radius)
        end

        if item_data.execute then
            button.onclick = function()
                item_data.onselect(self.source_item)
                item_data.execute(self.source_item)
            end
        end

        -- button.ongainfocus = function()
        --     if button:IsEnabled() and not (button:IsSelected() or button:IsDisabledState()) then
        --         if item_data.onfocus and item_data.onfocus() then
        --             return -- callback returned true: halt operation
        --         end
        --         -- button:MoveTo(item_data.pos, item_data.focus_pos, 0.1)
        --     end
        -- end

        -- button.onlosefocus = function()
        --     if button:IsEnabled() and not (button:IsSelected() or button:IsDisabledState()) then
        --         -- button:MoveTo(item_data.focus_pos, item_data.pos, 0.25)
        --     end
        -- end

        -- if item_data.helptext ~= nil then
        --     button:SetHelpTextMessage(item_data.helptext)
        -- end

        if item_data.postinit then
            item_data.postinit(button)
        end

        -- if item_data.spacer then
        --     self.numspacers = self.numspacers + 1
        -- end

        if not item_data.should_show or item_data.should_show(self.source_item) then
            table.insert(visible_buttons, button)
        else
            button:Hide()
        end

        table.insert(self.items, {
            button = button,
            data = item_data,
        })
    end

    local screen_width, _ = TheSim:GetScreenSize()
    local button_width = 70
    local total_width = button_width * (#visible_buttons - 1)
    local initial_position = self.anchor_position + Vector3(-total_width / 2, 100)
    initial_position.x = math.min(initial_position.x, screen_width - total_width)

    for i, button in ipairs(visible_buttons) do
        button:SetPosition(initial_position + Vector3(button_width * (i - 1)))
    end
end

function SpellControls:Open(items_data, source_item, anchor_position)
    self.isopen = true

    self:Show()
    -- self:Disable()
    -- self:SetClickable(false)
    self:SetClickable(true)
    self:Enable()

    self:SetItems(items_data, source_item, anchor_position)

    local selected
    for _, item in ipairs(self.items) do
        local disabled = item.data.checkenabled and not item.data.checkenabled(self.owner)
        if item.data.checkcooldown then
            item.button.cooldown.OnUpdate = function(cooldown, dt, force_init)
                local cd = item.data.checkcooldown(self.owner)
                if cd then
                    if force_init or item.button.enabled then
                        item.button:Disable()
                    end
                    cooldown:GetAnimState():SetPercent("cooldown", math.clamp(1 - cd, 0, 1))
                    cooldown:Show()
                else
                    if disabled then
                        if force_init or item.button.enabled then
                            item.button:Disable()
                        end
                    elseif force_init or not item.button.enabled then
                        item.button:Enable()
                    end
                    cooldown:Hide()
                end
            end
            item.button.cooldown:StartUpdating()
            item.button.cooldown:OnUpdate(0, true)
        elseif disabled then
            item.button:Disable()
        else
            item.button:Enable()
        end
        if (item.button.selected or selected == nil) and item.button.enabled then
            selected = item
        end
        -- item.button:MoveTo(Vector3(0, 0, 0), item.data.pos, 0.25)
    end

    if selected then
        -- selected.button:MoveTo(Vector3(0, 0, 0), selected.data.pos, 0.25, function()
        --     self:SetClickable(true)
        --     self:Enable()
        -- end)
    end
end

function SpellControls:Close()
    if not self.isopen then
        return
    end

    -- for _, item in ipairs(self.items) do
    --     if item.button.cooldown then
    --         item.button.cooldown:StopUpdating()
    --     end
    --     item.button:CancelMoveTo()
    --     item.button:Hide()
    -- end
    self:SetClickable(true)
    self:ClearFocus()
    self:Disable()
    self:Hide()
    self.isopen = false
end

return SpellControls
