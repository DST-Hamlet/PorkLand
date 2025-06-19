local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local UIAnimButton = require("widgets/uianimbutton")
local UIAnim = require("widgets/uianim")
local Image = require "widgets/image"

local SpellControls = Class(Widget, function(self, owner)
    Widget._ctor(self, "SpellControls")

    self:SetScale(TheFrontEnd:GetHUDScale() * 0.8)
    self.inst:ListenForEvent("refreshhudsize", function(hud, scale) 
        self:SetScale(scale * 0.8) 
        self:UpdateAnchorPosition() 
    end, owner.HUD.inst)

    self.owner = owner

    self.source_item = nil
    -- self.anchor_position = Vector3()
    self.items = {}
    self.isopen = false

    self.background = self:AddChild(UIAnim())
    self.background:GetAnimState():AnimateWhilePaused(false)
    self.background:SetScale(0.9)
    self.background:MoveToBack()
    -- self.background:Hide()
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

function SpellControls:SetItems(items_data, background, source_item)
    if source_item then
        self.source_item = source_item
    end

    for _, item in ipairs(self.items) do
        item.button:Kill()
    end
    self.items = {}

    -- self.numspacers = 0

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
            button = self:AddChild(ImageButton(item_data.atlas, FunctionOrValue(item_data.normal, self.source_item), item_data.focus, item_data.disabled, item_data.down, item_data.selected, item_data.scale, item_data.offset))
            button:SetImageNormalColour(.8, .8, .8, 1)
            button:SetImageFocusColour(1, 1, 1, 1)
            button:SetImageDisabledColour(0.7, 0.7, 0.7, 0.7)
            local background_image = button.image:AddChild(Image("images/skilltree.xml", "selected.tex"))
            background_image:MoveToBack()
        end

        button:SetTooltip(FunctionOrValue(item_data.label, self.source_item))

        if item_data.widget_scale ~= nil then
            button:SetScale(item_data.widget_scale)
        end
        if item_data.hit_radius ~= nil then
            button.image:SetRadiusForRayTraces(item_data.hit_radius)
        end

        if item_data.on_execute_on_client then
            button.onclick = function()
                item_data.on_execute_on_client(self.source_item)
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

        table.insert(self.items, {
            button = button,
            data = item_data,
        })
    end

    local screen_width, _ = TheSim:GetScreenSize()
    local button_width = 75
    local total_width = button_width * (#self.items - 1)
    local half_total_width = total_width / 2
    local initial_position = Vector3(-half_total_width, 100)
    -- Limit the x so we can always display all the buttons inside the screen
    local max_x = screen_width - (total_width + button_width / 2)
    initial_position.x = math.min(initial_position.x, max_x)

    for i, item in ipairs(self.items) do
        item.button:SetPosition(initial_position + Vector3(button_width * (i - 1)))
    end

    if background then
        self.background:SetPosition(Vector3(-2, initial_position.y)) -- 最好有个为每个background进行自定义的表
        self.background:GetAnimState():SetBank(background.bank)
        self.background:GetAnimState():SetBuild(background.build)
        self.background:GetAnimState():PlayAnimation("open")
        -- self.background:Show()
    else
        self.background:GetAnimState():PlayAnimation("close")
        -- self.background:Hide()
    end
end

function SpellControls:RefreshItemStates()
    for _, item in ipairs(self.items) do
        if item.data.anims then
            -- TODO: Implement this when we have items with animations
        else
            item.button:SetTextures(item.data.atlas, FunctionOrValue(item.data.normal, self.source_item), item.data.focus, item.data.disabled, item.data.down, item.data.selected, item.data.scale, item.data.offset)
        end
        item.button:SetTooltip(FunctionOrValue(item.data.label, self.source_item))
    end

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

local function get_slot_position(inventory_bar, index)
    local slots = JoinArrays(unpack(inventory_bar:GetInventoryLists()))
    local i = 1
    for _, slot in pairs(slots) do
        if i == index then
            return slot:GetWorldPosition()
        end
        i = i + 1
    end
    return Vector3(0, 0, 0)
end

function SpellControls:UpdateAnchorPosition()
    -- TODO: we currently force the anchor position
    local anchor_position = self.owner.HUD.controls.inv.toprow:GetWorldPosition()
    anchor_position.x = get_slot_position(self.owner.HUD.controls.inv, 3).x

    -- self.anchor_position = anchor_position
    self:SetPosition(anchor_position)
end

function SpellControls:Open(items_data, background, source_item, anchor_position)
    self.isopen = true

    -- self:Show()
    -- self:Disable()
    -- self:SetClickable(false)
    self:SetClickable(true)
    self:Enable()

    self:UpdateAnchorPosition()

    self:SetItems(items_data, background, source_item)
    -- self:RefreshItemStates()
end

function SpellControls:Close()
    if not self.isopen then
        return
    end

    for _, item in ipairs(self.items) do
        item.button:Kill()
        -- if item.button.cooldown then
        --     item.button.cooldown:StopUpdating()
        -- end
        -- item.button:CancelMoveTo()
        -- item.button:Hide()
    end
    self.items = {}

    self:SetClickable(true)
    self:ClearFocus()
    self:Disable()
    self.background:GetAnimState():PlayAnimation("close")
    -- self:Hide()
    self.isopen = false
end

return SpellControls
