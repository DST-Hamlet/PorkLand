local Badge = require("widgets/badge")
local UIAnim = require("widgets/uianim")

local BoatBadge = Class(Badge, function(self, owner, containerwidget)
    Badge._ctor(self, "boat_health", owner)

    self.containerwidget = containerwidget

    self.boatarrow = self.underNumber:AddChild(UIAnim())
    self.boatarrow:GetAnimState():SetBank("sanity_arrow")
    self.boatarrow:GetAnimState():SetBuild("sanity_arrow")
    self.boatarrow:GetAnimState():PlayAnimation("neutral")
    self.boatarrow:SetClickable(false)

    self.num:SetSize(40)

    self:SetScale(1.3)

    self:StartUpdating()

    local COMBINEDSTATUS = KnownModIndex:IsModEnabled("workshop-376333686")
    local RPGHUD = false
    for _, moddir in ipairs(TheSim:GetModDirectoryNames()) do
        if moddir ~= nil then
            local ModInfo = KnownModIndex:GetModInfo(moddir)
            if ModInfo and string.match(ModInfo.name or "", "RPG HUD") then
                RPGHUD = KnownModIndex:IsModEnabled(moddir)
                break
            end
        end
    end
    if COMBINEDSTATUS then
        local SHOWSTATNUMBERS = GetModConfigData("SHOWSTATNUMBERS", "workshop-376333686")
        if SHOWSTATNUMBERS then
            local nudge = RPGHUD and 75 or 12.5
            self.bg:SetPosition(-.5, nudge - 40)

            self.num:SetFont(NUMBERFONT)
            self.num:SetSize(28)
            self.num:SetPosition(3.5, nudge - 40.5)
            self.num:SetScale(1,.78,1)
            self.num:MoveToFront()
            self.num:Show()
        end
    end
end)

function BoatBadge:OnUpdate(dt)
    -- local down = self.owner.components.temperature:IsOverheating() or self.owner.components.temperature:IsFreezing() or self.owner.components.hunger:IsStarving() or self.owner.components.health.takingfiredamage
    -- local poison = self.owner.components.poisonable:IsPoisoned()

    -- local anim = poison and "arrow_loop_decrease_more" or "neutral"
    -- anim = down and "arrow_loop_decrease_most" or anim

    local anim = "neutral"
    if anim and self.arrowdir ~= anim then
        self.arrowdir = anim
        self.boatarrow:GetAnimState():PlayAnimation(anim, true)
    end
end

-- Status Announcements support

local stat = "PL_BOAT"
local categorynames = {"EMPTY", "LOW", "MID", "HIGH", "FULL"}
local thresholds    = {     .15,    .35,    .65,    .85 }

local function get_category(thresholds, percent)
    local i = 1
    while thresholds[i] ~= nil and percent >= thresholds[i] do
        i = i + 1
    end
    return i
end

local function get_stat_message(StatusAnnouncer, percent)
    local category_name = categorynames[get_category(thresholds, percent)]
    return StatusAnnouncer.char_messages[stat:upper()][category_name]
end

function BoatBadge:OnMouseButton(button, down)
    local StatusAnnouncer = self.owner and self.owner.HUD._StatusAnnouncer
    if StatusAnnouncer then
        if down and button == MOUSEBUTTON_LEFT and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) then
            local container = self.containerwidget and self.containerwidget.container
            if container then
                local boathealth = container.replica.boathealth
                if boathealth then
                    local cur = boathealth:GetCurrentHealth()
                    local max = boathealth:GetMaxHealth()

                    local final
                    local sailor = ThePlayer and ThePlayer.replica.sailor
                    if sailor and sailor._boat:value() == container then
                        local stat_name = StatusAnnouncer.stat_names[stat] or stat
                        final = string.format("(%s: %d/%d) %s", stat_name, cur, max, get_stat_message(StatusAnnouncer, cur / max))
                    else
                        local BOAT_STRINGS = STRINGS._STATUS_ANNOUNCEMENTS._.ANNOUNCE_IA_BOAT
                        final = subfmt(BOAT_STRINGS.FORMAT_STRING, {
                            THIS = BOAT_STRINGS.THIS,
                            BOAT = container:GetBasicDisplayName():lower(),
                            HAS = BOAT_STRINGS.HAS,
                            STAT = string.format("%d/%d", cur, max),
                            HEALTH = BOAT_STRINGS.HEALTH,
                        })
                    end
                    StatusAnnouncer:Announce(final, stat .. tostring(container.GUID))
                    return true
                end
            end
        end
    end
    return self._base.OnMouseButton(self, button, down)
end

return BoatBadge
