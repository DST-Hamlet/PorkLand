local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local UIAnimButton = require("widgets/uianimbutton")
local UIAnim = require("widgets/uianim")

-------------------------------------------------------------------------------
local SpellControls = Class(Widget, function(self, owner)
    Widget._ctor(self, "SpellControls")

    self.owner = owner

    self.items = {}
    self.isopen = false
end)

function SpellControls:IsOpen()
    return self.isopen
end

function SpellControls:SetItems(items_data)
    for _, item in ipairs(self.items) do
        item.button:Kill()
    end
    self.items = {}

    self.numspacers = 0

    for _, item_data in ipairs(items_data) do
        local button
        if item_data.anims then
            button = self:AddChild(UIAnimButton(item_data.bank, item_data.build))
            button.animstate:Hide("mouseover")
            button.overrideclicksound = item_data.clicksound

            local anim_data = FunctionOrValue(item_data.anims.idle, self.owner)
            if anim_data then
                button:SetIdleAnim(anim_data)
            end
            local anim_data = FunctionOrValue(item_data.anims.focus, self.owner)
            if anim_data then
                button:SetFocusAnim(anim_data)
            end
            local anim_data = FunctionOrValue(item_data.anims.disabled, self.owner)
            if anim_data then
                button:SetDisabledAnim(anim_data)
            end
            local anim_data = FunctionOrValue(item_data.anims.down, self.owner)
            if anim_data then
                button:SetDownAnim(anim_data)
            end
            local anim_data = FunctionOrValue(item_data.anims.selected, self.owner)
            if anim_data then
                button:SetSelectedAnim(anim_data)
            end

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
        button:Hide()

        if item_data.widget_scale ~= nil then
            button:SetScale(item_data.widget_scale)
        end
        if item_data.hit_radius ~= nil then
            button.image:SetRadiusForRayTraces(item_data.hit_radius)
        end

        if item_data.execute then
            button.onclick = function()
                item_data.execute()
            end
        end

        if item_data.ondown then
            button.ondown = function()
                item_data.ondown()
            end
        end

        button.ongainfocus = function()
            if button:IsEnabled() and not (button:IsSelected() or button:IsDisabledState()) then
                if item_data.onfocus and item_data.onfocus() then
                    return -- callback returned true: halt operation
                end
                button:MoveTo(item_data.pos, item_data.focus_pos, 0.1)
            end
        end

        button.onlosefocus = function()
            if button:IsEnabled() and not (button:IsSelected() or button:IsDisabledState()) then
                button:MoveTo(item_data.focus_pos, item_data.pos, 0.25)
            end
        end

        if item_data.helptext ~= nil then
            button:SetHelpTextMessage(item_data.helptext)
        end

        if item_data.postinit then
            item_data.postinit(button)
        end

        if item_data.spacer then
            self.numspacers = self.numspacers + 1
        end

        tablel.insert(self.items, {
            button = button,
            data = item_data,
        })
    end
end

function SpellControls:Open(items_data)
    self.isopen = true

    self:Show()
    self:Disable()
    self:SetClickable(false)

    self:SetItems(items_data)

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
            selected = item.button
        end
        item.button:MoveTo(Vector3(0, 0, 0), item.button.pos, 0.25)
        item.button:Show()
    end

    if selected then
        selected.widget:MoveTo(Vector3(0, 0, 0), selected.pos, 0.25, function()
            self:SetClickable(true)
            self:Enable()
        end)
    end
end

function SpellControls:Close()
    if not self.isopen then
        return
    end

    self:StopUpdating()

    for _, item in ipairs(self.items) do
        if item.button.cooldown then
            item.button.cooldown:StopUpdating()
        end
        item.button:CancelMoveTo()
        item.button:Hide()
    end
    self:SetClickable(true)
    self:ClearFocus()
    self:Disable()
    self:Hide()
    self.isopen = false
    TheFrontEnd:LockFocus(false)
end

return SpellControls
