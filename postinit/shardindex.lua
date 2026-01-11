local modname = modname
local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

-- see shardindex.lua line 528
function ShardIndex:GeneratePorklandWorldGenOverride(slot, shard)
    local filename = "../worldgenoverride.lua"

    TheSim:GetPersistentString(filename, function(load_success, str)
        if load_success then
            -- this override config is rarely used, we still need to check if the Porkland preset is used
            print("Master Shard already exists " .. filename)
            local success, worldgenoverride = RunInSandbox(str)
            if success then
                if worldgenoverride.preset ~= "PORKLAND_DEFAULT" then
                    worldgenoverride.preset = "PORKLAND_DEFAULT"
                    local data = DataDumper(worldgenoverride, nil, false)
                    local onload = function(success, err)
                        if success then
                            print("Successfully overwrote " .. filename .. " to Master Shard")
                        else
                            print("Failed to overwrite " .. filename .. "to Master Shard \n Error: " .. tostring(err))
                        end
                    end

                    if shard ~= nil then
                        TheSim:SetPersistentStringInClusterSlot(slot, shard, filename, data, false, onload)
                    else
                        TheSim:SetPersistentString(filename, data, true, onload)
                    end
                end
            end
        else
            local data = "return {override_enabled = true, preset = \"PORKLAND_DEFAULT\",}"
            local onload = function(success, err)
                if success then
                    print("Successfully wrote " .. filename .. "to Master Shard")
                else
                    print("Failed to write " .. filename .. "to Master Shard \n Error: " .. tostring(err))
                end
            end

            if shard ~= nil then
                TheSim:SetPersistentStringInClusterSlot(slot, shard, filename, data, false, onload)
            else
                TheSim:SetPersistentString(filename, data, false, onload)
            end
        end
    end)
end

-- AddSimPostInit(function()
--     -- run only in the workshop version
--     local is_workshop_version = modname:find("workshop-")
--     -- run only on dedicated servers and master shard
--     if TheNet:IsDedicated() and not TheShard:IsSecondary() then -- and is_workshop_version Wait for test to be completed
--         ShardGameIndex:GeneratePorklandWorldGenOverride()
--     end
-- end)

local _SetServerShardData = ShardIndex.SetServerShardData
local GetLevelDataOverride, scope_fn, i = ToolUtil.GetUpvalue(_SetServerShardData, "GetLevelDataOverride")
local _GetLevelDataOverride = function(slot, shard, cb, ...)
    print("trying Generate Porkland WorldGen Override...")
    local is_workshop_version = modname:find("workshop-")
    -- This will only work on dedicated servers.
    if TheNet:IsDedicated() and not TheShard:IsSecondary() then -- and is_workshop_version
        ShardGameIndex:GeneratePorklandWorldGenOverride(slot, shard)

        print("Huh? Generate Porkland WorldGen Override done?")
    end
    return GetLevelDataOverride(slot, shard, cb, ...)
end

if i then
    debug.setupvalue(_SetServerShardData, i, _GetLevelDataOverride)
end
