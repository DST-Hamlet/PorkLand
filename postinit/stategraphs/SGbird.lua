local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

AddStategraphPostInit("bird", function(sg)
    local _flyaway_onenter = sg.states["flyaway"].onenter
    if _flyaway_onenter then
        sg.states["flyaway"].onenter = function(inst)
            _flyaway_onenter(inst)
            if inst.sounds.takeoff_2 then
                inst.SoundEmitter:PlaySound(inst.sounds.takeoff_2)
            end
        end
    end

    local _glide_onupdate = sg.states["glide"].onupdate
    if _glide_onupdate then
        sg.states["glide"].onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 0.1 and not inst.sg.statemem.onlanding_spawned then
                if inst.components.periodicspawner.onlanding then
                    inst.components.periodicspawner:TrySpawn()
                end
                inst.sg.statemem.onlanding_spawned = true
            end
            _glide_onupdate(inst)
        end
    end

    -- TODO bird takoff logic
end)
