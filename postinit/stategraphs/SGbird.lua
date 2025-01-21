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
            _glide_onupdate(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 0.1 and not inst.sg.statemem.onlanding_spawned then
                if inst.components.periodicspawner.onlanding and math.random() <= TUNING.BIRD_LEAVINGS_CHANCE then
                    local canspawn, bait = inst.components.periodicspawner:TrySpawn()
                    inst.components.periodicspawner:SetSpawnTestFn(function() return false end)
                    inst.sg.statemem.onlanding_spawned = true
                    if bait then
                        inst.bufferedaction = BufferedAction(inst, bait, ACTIONS.EAT)
                    end
                end
            end

            local ents = TheSim:FindEntities(x, 0, z, 2)
            for k, v in pairs(ents) do
                if inst.components.eater:CanEat(v) and not v:IsInLimbo() and
                    v.components.bait and
                    not (v.components.inventoryitem and v.components.inventoryitem:IsHeld()) and
                    (inst.components.floater ~= nil or TheWorld.Map:IsPassableAtPoint(x, y, z)) then

                    inst.bufferedaction = BufferedAction(inst, v, ACTIONS.EAT)
                    break
                end
            end
        end
    end

    -- TODO bird takoff logic
end)
