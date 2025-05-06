GLOBAL.setfenv(1, GLOBAL)
local PlayerActionPicker = require("components/playeractionpicker")

-- Imrpoved quantize function that works with rot ocean
local function QuantizeLandingPosition(px, pz)
    px, pz = math.floor(px), math.floor(pz)
    if px % 2 == 1 then px = px + 1 end
    if pz % 2 == 1 then pz = pz + 1 end
    return px, pz
end

local LAND_SCAN_STEP_SIZE = 2
local WALL_TAGS = { "wall" }
function PlayerActionPicker:ScanForLandInDir(my_x, my_z, dir_x, dir_z, steps, step_size)
    for i = 0, steps do -- Initial position can have a quantized pos on land so start at 0
        local pt_x, pt_z = QuantizeLandingPosition(my_x + dir_x * i * step_size, my_z + dir_z * i * step_size)

        local is_land = self.map:IsVisualGroundAtPoint(pt_x, 0, pt_z)
        if is_land then
            --search for nearby walls and fences with active physics.
            for _, v in ipairs(TheSim:FindEntities(math.floor(pt_x), 0, math.floor(pt_z), 1, WALL_TAGS)) do
                if v ~= self.inst and
                v.entity:IsVisible() and
                v.components.placer == nil and
                v.entity:GetParent() == nil and
                v.Physics:IsActive() then
                    return false, 0, 0
                end
            end
            return true, pt_x, pt_z
        end
    end
    return false, 0, 0
end

local PLATFORM_SCAN_STEP_SIZE = 0.25
local PLATFORM_SCAN_RANGE = 1
function PlayerActionPicker:ScanForPlatformInDir(my_x, my_z, dir_x, dir_z, steps, step_size)
    for i = 1, steps do
        local pt_x, pt_z = my_x + dir_x * i * step_size, my_z + dir_z * i * step_size

        local platform = self.map:GetNearbyPlatformAtPoint(pt_x, 0, pt_z, -PLATFORM_SCAN_RANGE)
        if platform ~= nil then
            return true, pt_x, pt_z, platform
        end
    end
    return false, 0, 0
end

function PlayerActionPicker:ScanForLandingPoint(target_x, target_z)
    local my_x, _, my_z = self.inst.Transform:GetWorldPosition()
    local dir_x, dir_z = target_x - my_x, target_z - my_z
    local dir_length = VecUtil_Length(dir_x, dir_z)
    dir_x, dir_z = dir_x / dir_length, dir_z / dir_length

    local land_step_count = dir_length / LAND_SCAN_STEP_SIZE

    local can_hop, hop_x, hop_z = self:ScanForLandInDir(my_x, my_z, dir_x, dir_z, land_step_count, LAND_SCAN_STEP_SIZE)

    if can_hop then
        return can_hop, hop_x, hop_z, nil
    end

    local platform_step_count = (dir_length + PLATFORM_SCAN_RANGE) / PLATFORM_SCAN_STEP_SIZE

    return self:ScanForPlatformInDir(my_x, my_z, dir_x, dir_z, platform_step_count, PLATFORM_SCAN_STEP_SIZE)
end

local _GetLeftClickActions = PlayerActionPicker.GetLeftClickActions
function PlayerActionPicker:GetLeftClickActions(position, target, ...)
    local actions = _GetLeftClickActions(self, position, target, ...)

    if TheInput:ControllerAttached() then
        return actions
    end

    if (not actions or #actions == 0) and self.inst:IsSailing() and self.map:IsPassableAtPoint(position.x, 0, position.z) then
        -- Find the landing position, where water meets the land
        local can_hop, hop_x, hop_z = self:ScanForLandingPoint(position.x, position.z)
        if can_hop then
            actions = { BufferedAction(self.inst, nil, ACTIONS.DISEMBARK, nil, Vector3(hop_x, 0, hop_z)) }
        end
    end

    return actions or {}
end

local get_right_click_actions = PlayerActionPicker.GetRightClickActions
function PlayerActionPicker:GetRightClickActions(position, target, ...)
    local actions = get_right_click_actions(self, position, target, ...)

    -- Allow performing Wheeler's DODGE on impassable points
    if IsTableEmpty(actions) and (target == nil or target:HasTag("walkableplatform") or target:HasTag("walkableperipheral")) and not self.map:IsPassableAtPoint(position:Get()) then
        local useitem = self.inst.replica.inventory:GetActiveItem()
        local point_special_actions = self:GetPointSpecialActions(position, useitem, true)
        if point_special_actions[1] and point_special_actions[1].action == ACTIONS.DODGE then
            actions = point_special_actions
        end
    end

    return actions or {}
end

-- Allow performing wheeler's DODGE in the dark
local do_get_mouse_actions = PlayerActionPicker.DoGetMouseActions
function PlayerActionPicker:DoGetMouseActions(position, target, spellbook, ...)
    local actions = { do_get_mouse_actions(self, position, target, spellbook, ...) }

    if position == nil then
        local lmb = actions[1]
        local rmb = actions[2]

        if not rmb and not TheInput:GetHUDEntityUnderMouse() and not self.inst.components.playercontroller:IsAOETargeting() then
            position = TheInput:GetWorldPosition()
			target = target or TheInput:GetWorldEntityUnderMouse()

            local cansee
            if target == nil then
                local x, y, z = position:Get()
                cansee = CanEntitySeePoint(self.inst, x, y, z)
            else
                cansee = target == self.inst or CanEntitySeeTarget(self.inst, target)
            end
            if not cansee then
                local rmbs = self:GetRightClickActions(position, nil, spellbook)
                for i, v in ipairs(rmbs) do
                    -- Mainly for this part
                    if v.action == ACTIONS.DODGE then
                        rmb = v
                    end
                end
            end

            return lmb, rmb
        end
    end

    return unpack(actions)
end
