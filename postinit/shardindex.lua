GLOBAL.setfenv(1, GLOBAL)

function ShardIndex:GeneratePorklandWorldgenOverride(callback)
    local filename = "../worldgenoverride.lua"

    TheSim:GetPersistentString(filename, function(load_success, data)
        if load_success then
            -- local success, worldgenoverride = RunInSandbox(data)
            print("Master has " .. filename)
        else
            local data = "return {override_enabled = true, preset = \"PORKLAND_DEFAULT\",}"

            -- params：filename, data, overwrite, callback
            TheSim:SetPersistentString(filename, data, false, function(success, err)
                if success then
                    print("Successfully wrote " .. filename)
                else
                    print("Failed to write " .. filename .. ": " .. tostring(err))
                end
            end)
        end
    end)
end
