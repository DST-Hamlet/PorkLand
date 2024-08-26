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

    sg.states["flyaway"].onupdate = function(inst)
        local position = inst:GetPosition()
        if TheWorld.components.interiorspawner:IsInInteriorRegion(position.x, position.z) then
            local room = TheWorld.components.interiorspawner:GetInteriorCenter(position)
            if room and room.height then
                if position.y >= room.height then
                    inst.components.combat:GetAttacked(nil, 5, nil)
                end
            end
        end
    end

    local _flyaway_ontimeout = sg.states["flyaway"].ontimeout
    if _flyaway_ontimeout then
        sg.states["flyaway"].ontimeout = function(inst)
            _flyaway_ontimeout(inst)
            local x, _, z = inst.Transform:GetWorldPosition()
            if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
                inst.Physics:SetMotorVel(0, math.random() * 5 + 15, 0)
            end
        end
    end

    local _glide_onupdate = sg.states["glide"].onupdate
    if _glide_onupdate then
        sg.states["glide"].onupdate = function(inst)
            local _, y, _ = inst.Transform:GetWorldPosition()
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
