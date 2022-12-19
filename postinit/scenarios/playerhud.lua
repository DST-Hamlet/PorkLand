GLOBAL.setfenv(1, GLOBAL)

local PoisonOver = require("widgets/poisonover")
local PlayerHud = require("screens/playerhud")

local _CreateOverlays = PlayerHud.CreateOverlays
function PlayerHud:CreateOverlays(owner, ...)
    _CreateOverlays(self, owner, ...)

    self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
end

function PlayerHud:GoSane()
    self.vig:GetAnimState():PlayAnimation("basic", true)
end

function PlayerHud:GoInsane()
    self.vig:GetAnimState():PlayAnimation("insane", true)
end

local _SetMainCharacter = PlayerHud.SetMainCharacter
function PlayerHud:SetMainCharacter(maincharacter)
    _SetMainCharacter(self, maincharacter)

    self.inst:ListenForEvent("sanity_stun", function(inst, data)
        print("当前角色状态:神志不清")
        self:GoInsane()
    end, self.owner)

    self.inst:ListenForEvent("sanity_stun_over", function(inst, data)
        if ThePlayer.components.sanity:IsSane() then
            print("当前角色状态:神志不清_1")
            self:GoSane()
        end
    end, self.owner)

end
