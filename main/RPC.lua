local AddModRPCHandler = AddModRPCHandler
local AddShardModRPCHandler = AddShardModRPCHandler
GLOBAL.setfenv(1, GLOBAL)

local function printinvalid(rpcname, player)
    print(string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))

    --This event is for MODs that want to handle players sending invalid rpcs
    TheWorld:PushEvent("invalidrpc", { player = player, rpcname = rpcname })

    if BRANCH == "dev" then
        --Internal testing
        assert(false, string.format("Invalid %s RPC from (%s) %s", rpcname, player.userid or "", player.name or ""))
    end
end

AddModRPCHandler("Porkland", "BoatEquipActiveItem", function(player, container)
    if container ~= nil then
        container.components.container:BoatEquipActiveItem()
    end
end)

AddModRPCHandler("Porkland", "SwapBoatEquipWithActiveItem", function(player, container)
    if container ~= nil then
        container.components.container:SwapBoatEquipWithActiveItem()
    end
end)

AddModRPCHandler("Porkland", "TakeActiveItemFromBoatEquipSlot", function(player, eslot, container)
    if not checknumber(eslot) then
        printinvalid("TakeActiveItemFromBoatEquipSlot", player)
        return
    end
    if container ~= nil then
        container.components.container:TakeActiveItemFromBoatEquipSlotID(eslot)
    end
end)

AddShardModRPCHandler("Porkland", "SetAporkalypseClockRewindMult", function(shardid, rewind_mult)
    if not TheWorld.ismastershard then
        return
    end

    TheWorld:PushEvent("ms_setrewindmult", rewind_mult)
end)

AddShardModRPCHandler("Porkland", "SwitchAporkalypse", function(shardid, active)
    if not TheWorld.ismastershard then
        return
    end

    if active then
        TheWorld:PushEvent("ms_startaporkalypse")
    else
        TheWorld:PushEvent("ms_stopaporkalypse")
    end
end)

AddModRPCHandler("Porkland", "teleport_to_home", function(inst)
    -- TODO: 以后可以做一个倒计时...
    local pos = inst:GetPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(pos.x, pos.z) then
        TheWorld.components.playerspawner:SpawnAtNextLocation(inst)
    end
end)

AddModRPCHandler("Porkland", "ReleaseControlSecondary", function(player, x, z)
    if not (checknumber(x) and checknumber(z)) then
        return
    end
    local playercontroller = player.components.playercontroller
    if playercontroller ~= nil then
        playercontroller:OnRemoteReleaseControlSecondary(x, z)
    end
end)

AddModRPCHandler("Porkland", "StrafeFacing_pl", function(player, dir)
    if not checknumber(dir) then
        printinvalid("StrafeFacing", player)
        return
    end
    local locomotor = player.components.locomotor
    if locomotor then
        locomotor:OnStrafeFacingChanged(dir)
    end
end)

AddClientModRPCHandler("Porkland", "interior_map", function(data)
    if type(data) == "string" then
        local unzipped = TheSim:DecodeAndUnzipString(data)
        local succeed, result = RunInSandboxSafe(unzipped)
        if succeed then
            local interiorvisitor = ThePlayer.replica.interiorvisitor
            if interiorvisitor then
                interiorvisitor:OnNewInteriorMapData(result)
            end
        else
            print("Failed to unserialize interior map data", unzipped)
        end
    end
end)

AddUserCommand("saveme", {
    aliases = nil,
    prettyname = nil,
    desc = nil,
    permission = COMMAND_PERMISSION.USER,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    localfn = function(params, caller)
        ThePlayer:DoTaskInTime(0, function()
            SendModRPCToServer(MOD_RPC["Porkland"]["teleport_to_home"])
        end)
    end,
})
