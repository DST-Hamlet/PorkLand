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
