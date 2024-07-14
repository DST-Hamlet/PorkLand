local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function GetWindSpeed(self)
    local wind_speed = 1

    -- get a wind speed adjustment
    if TheWorld.net ~= nil and TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy()
        and not self.inst:HasTag("windspeedimmune")
        and not self.inst:HasTag("playerghost") then

        local windangle = self.inst.Transform:GetRotation() - TheWorld.net.components.plateauwind:GetWindAngle()
        local windproofness = 1.0 -- ziwbi: There are no wind proof items in Hamelt... yet
        local windfactor = TUNING.WIND_PUSH_MULTIPLIER * windproofness * TheWorld.net.components.plateauwind:GetWindSpeed() * math.cos(windangle * DEGREES) + 1.0
        wind_speed = math.max(0.1, windfactor)
    end

    return wind_speed
end

local function endonexternalspeedmultiplier(self, externalspeedmultiplier)
    local rider = self.inst.components.rideable:GetRider()
    if rider ~= nil and rider.replica.rider ~= nil then
        rider.replica.rider:SetMountSpeedMultiplier(externalspeedmultiplier)
    end
end

local function ServerGetSpeedMultiplier(self)
    local mult = self:ExternalSpeedMultiplier()
    if self.inst.components.inventory ~= nil then
        if self.inst.components.rider ~= nil and self.inst.components.rider:IsRiding() then
            mult = self.inst.components.rider:GetMountSpeedMultiplier()
            local saddle = self.inst.components.rider:GetSaddle()
            if saddle ~= nil and saddle.components.saddler ~= nil then
                mult = mult + (saddle.components.saddler:GetBonusSpeedMult() - 1)
            end
        elseif self.inst.replica.sailor and self.inst.replica.sailor:GetBoat() then
            mult = self.inst.replica.sailor._currentspeed:value() / self:RunSpeed()
        elseif self.inst.components.inventory.isopen then
            -- NOTE: Check if inventory is open because client GetEquips returns
            --       nothing if inventory is closed.
            --       Don't check visibility though.
            local is_mighty = self.inst.components.mightiness ~= nil and self.inst.components.mightiness:GetState() == "mighty"
            for k, v in pairs(self.inst.components.inventory.equipslots) do
                if v.components.equippable ~= nil then
                    local item_speed_mult = v.components.equippable:GetWalkSpeedMult()
                    if is_mighty and item_speed_mult < 1 then
                        item_speed_mult = 1
                    end

                    mult = mult + (item_speed_mult - 1)
                end
            end
        end
    end

    mult = mult + ((self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) - 1)

    return mult * self.throttle * GetWindSpeed(self)
end

local function ClientGetSpeedMultiplier(self)
    local mult = self:ExternalSpeedMultiplier()
    local inventory = self.inst.replica.inventory
    if inventory ~= nil then
        local rider = self.inst.replica.rider
        if rider ~= nil and rider:IsRiding() then
            mult = rider:GetMountSpeedMultiplier()
            local saddle = rider:GetSaddle()
            local inventoryitem = saddle ~= nil and saddle.replica.inventoryitem or nil
            if inventoryitem ~= nil then
                mult = mult + (inventoryitem:GetWalkSpeedMult() - 1)
            end
        elseif self.inst.replica.sailor and self.inst.replica.sailor:GetBoat() then
            mult = self.inst.replica.sailor._currentspeed:value() / self:RunSpeed()
        else
            -- NOTE: GetEquips returns empty if inventory is closed! (Hidden still returns items.)
            local is_mighty = self.inst:HasTag("mightiness_mighty")
            for k, v in pairs(inventory:GetEquips()) do
                local inventoryitem = v.replica.inventoryitem
                if inventoryitem ~= nil then
                    local item_speed_mult = inventoryitem:GetWalkSpeedMult()
                    if is_mighty and item_speed_mult < 1 then
                        item_speed_mult = 1
                    end
                    mult = mult + (item_speed_mult - 1)
                end
            end
        end
    end

    mult = mult + ((self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) - 1)

    return mult * self.throttle * GetWindSpeed(self)
end

local function RecalculateExternalSpeedMultiplier(self, sources)
    local m = 1
    for source, src_params in pairs(sources) do
        for k, v in pairs(src_params.multipliers) do
            m = m + (v - 1)
        end
    end
    return m
end

AddComponentPostInit("locomotor", function(self, inst)
    if not TheWorld:HasTag("porkland") then
        return
    end

    if self.ismastersim then
        self.GetSpeedMultiplier = ServerGetSpeedMultiplier
    else
        self.GetSpeedMultiplier = ClientGetSpeedMultiplier
    end

    self.RecalculateExternalSpeedMultiplier = RecalculateExternalSpeedMultiplier

    if self.inst.components.rideable then
        ToolUtil.HookSetter(self, "externalspeedmultiplier", endonexternalspeedmultiplier)
    end
end)

local STATUS_CALCULATING = 0 -- 复制自components/locomotor.lua
local STATUS_FOUNDPATH = 1
local STATUS_NOPATH = 2

local LocoMotor = require("components/locomotor")

function LocoMotor:OnUpdate(dt, arrive_check_only)
    if self.hopping then
        --self:UpdateHopping(dt)
        return
    end

    if not self.inst:IsValid() then
        Print(VERBOSITY.DEBUG, "OnUpdate INVALID", self.inst.prefab)
        self:ResetPath()
        self:StopUpdatingInternal()
        self:StopMoveTimerInternal()
        return
    end

	if self.enablegroundspeedmultiplier and not arrive_check_only then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
        if tx ~= self.lastpos.x or ty ~= self.lastpos.y then
            self:UpdateGroundSpeedMultiplier()
            self.lastpos = { x = tx, y = ty }
        end
    end

	local facedir

    --Print(VERBOSITY.DEBUG, "OnUpdate", self.inst.prefab)
    if self.dest then
        --Print(VERBOSITY.DEBUG, "    w dest")
        if not self.dest:IsValid() or (self.bufferedaction and not self.bufferedaction:IsValid()) then
            self:Clear()
            return
        end

        if self.inst.components.health and self.inst.components.health:IsDead() then
            self:Clear()
            return
        end

        local destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
        local mypos_x, mypos_y, mypos_z = self.inst.Transform:GetWorldPosition()

        local reached_dest, invalid, in_cooldown = nil, nil, false
		if self.bufferedaction and self.bufferedaction.action.customarrivecheck then
			reached_dest, invalid = self.bufferedaction.action.customarrivecheck(self.inst, self.dest)
		else
			local dsq = distsq(destpos_x, destpos_z, mypos_x, mypos_z)
			local arrive_dsq = self.arrive_dist * self.arrive_dist
			if dt > 0 then
				local run_dist = self:GetRunSpeed() * dt * .5
				arrive_dsq = math.max(arrive_dsq, run_dist * run_dist)
			end
			reached_dest = dsq <= arrive_dsq

			--special case for attacks (in_cooldown can get set here)
			if self.bufferedaction and
				self.bufferedaction.action == ACTIONS.ATTACK and
				not (self.bufferedaction.forced and self.bufferedaction.target == nil)
			then
				local combat = self.inst.replica.combat
				if combat then
					reached_dest, invalid, in_cooldown = combat:LocomotorCanAttack(reached_dest, self.bufferedaction.target)
				end
			end
        end

        if invalid then
            self:Stop()
            self:Clear()
        elseif reached_dest then
        	--I think this is fine? we might need to make OnUpdateFinish() function that we can run to finish up the OnUpdate so we don't duplicate code
            if in_cooldown then return end
            --Print(VERBOSITY.DEBUG, "REACH DEST")
            self.inst:PushEvent("onreachdestination", { target = self.dest.inst, pos = Point(destpos_x, destpos_y, destpos_z) })
            if self.atdestfn ~= nil then
                self.atdestfn(self.inst)
            end

            if self.bufferedaction ~= nil and self.bufferedaction ~= self.inst.bufferedaction then
                if self.bufferedaction.target ~= nil and self.bufferedaction.target.Transform ~= nil and not self.bufferedaction.action.skip_locomotor_facing then
					self:FaceMovePoint(self.bufferedaction.target.Transform:GetWorldPosition())
                elseif self.bufferedaction.invobject ~= nil and not self.bufferedaction.action.skip_locomotor_facing then
                    local act_pos = self.bufferedaction:GetActionPoint()
                    if act_pos ~= nil then
						self:FaceMovePoint(act_pos:Get())
                    end
                end
                if self.ismastersim then
                    self.inst:PushBufferedAction(self.bufferedaction)
                else
                    self.inst:PreviewBufferedAction(self.bufferedaction)
                end
            end
            self:Stop()
            self:Clear()
		elseif not arrive_check_only then
            --Print(VERBOSITY.DEBUG, "LOCOMOTING")
            if self:WaitingForPathSearch() then
                local pathstatus = TheWorld.Pathfinder:GetSearchStatus(self.path.handle)
                --Print(VERBOSITY.DEBUG, "HAS PATH SEARCH", pathstatus)
                if pathstatus ~= STATUS_CALCULATING then
                    --Print(VERBOSITY.DEBUG, "PATH CALCULATION complete", pathstatus)
                    if pathstatus == STATUS_FOUNDPATH then
                        --Print(VERBOSITY.DEBUG, "PATH FOUND")
                        local foundpath = TheWorld.Pathfinder:GetSearchResult(self.path.handle)
                        print(foundpath)
                        if foundpath then
                            --Print(VERBOSITY.DEBUG, string.format("PATH %d steps ", #foundpath.steps))
                            print(#foundpath.steps)
                            if #foundpath.steps > 2 then
                                self.path.steps = foundpath.steps
                                self.path.currentstep = 2

                                -- for k,v in ipairs(foundpath.steps) do
                                --     Print(VERBOSITY.DEBUG, string.format("%d, %s", k, tostring(Point(v.x, v.y, v.z))))
                                -- end

                            else
                                --Print(VERBOSITY.DEBUG, "DISCARDING straight line path")
                                self.path.steps = nil
                                self.path.currentstep = nil
                            end
                        else
                            Print(VERBOSITY.DEBUG, "EMPTY PATH")
                        end
                    else
                        if pathstatus == nil then
                            Print(VERBOSITY.DEBUG, string.format("LOST PATH SEARCH %u. Maybe it timed out?", self.path.handle))
                        else
                            Print(VERBOSITY.DEBUG, "NO PATH")
                        end
                    end

                    TheWorld.Pathfinder:KillSearch(self.path.handle)
                    self.path.handle = nil
                end
            end

			local canrotate = self.inst.sg == nil or self.inst.sg:HasStateTag("canrotate")
			if canrotate or self.pusheventwithdirection then
                --Print(VERBOSITY.DEBUG, "CANROTATE")
                local facepos_x, facepos_y, facepos_z = destpos_x, destpos_y, destpos_z

                if self.path and self.path.steps and self.path.currentstep < #self.path.steps then
                    --Print(VERBOSITY.DEBUG, "FOLLOW PATH")
                    local step = self.path.steps[self.path.currentstep]
                    local steppos_x, steppos_y, steppos_z = step.x, step.y, step.z

                    --Print(VERBOSITY.DEBUG, string.format("CURRENT STEP %d/%d - %s", self.path.currentstep, #self.path.steps, tostring(steppos)))

                    local step_distsq = distsq(mypos_x, mypos_z, steppos_x, steppos_z)

                    local maxsteps = #self.path.steps
                    if self.path.currentstep < maxsteps then -- Add tolerance to step points that aren't the final destination.
                        local physdiameter = self.inst:GetPhysicsRadius(0)*2
                        step_distsq = step_distsq - physdiameter * physdiameter
                    end

                    if step_distsq <= (self.arrive_step_dist)*(self.arrive_step_dist) then
                        self.path.currentstep = self.path.currentstep + 1

                        if self.path.currentstep < maxsteps then
                            step = self.path.steps[self.path.currentstep]
                            steppos_x, steppos_y, steppos_z = step.x, step.y, step.z

                            --Print(VERBOSITY.DEBUG, string.format("NEXT STEP %d/%d - %s", self.path.currentstep, #self.path.steps, tostring(steppos)))
                        else
                            --Print(VERBOSITY.DEBUG, string.format("LAST STEP %s", tostring(destpos)))
                            steppos_x, steppos_y, steppos_z = destpos_x, destpos_y, destpos_z
                        end
                    end
                    facepos_x, facepos_y, facepos_z = steppos_x, steppos_y, steppos_z
                end

				facedir = self.inst:GetAngleToPoint(facepos_x, facepos_y, facepos_z)

                local x,y,z = self.inst.Physics:GetMotorVel()
				if x < 0 and self.strafedir == nil then
					facedir = facedir + 180
					if canrotate then
						--V2C: matching legacy behaviour, where this ignores busy state
						--Print(VERBOSITY.DEBUG, "SET ROT", facedir)
						self:SetMoveDir(facedir)
					end
				elseif canrotate and not (self.inst.sg and self.inst.sg:HasStateTag("busy")) then
					--V2C: while I'd like to remove the busy check,
					--     we'll keep it to match legacy behaviour:
					--     it used to call self.inst:FaceMovePoint(...)
					--Print(VERBOSITY.DEBUG, "FACE PT", Point(facepos_x, facepos_y, facepos_z))
					self:SetMoveDir(facedir)
                end
            end

            self.wantstomoveforward = self.wantstomoveforward or not self:WaitingForPathSearch()
        end
    end

	if arrive_check_only then
		return
	end

    local should_locomote = false
    if (self.ismastersim and not self.inst:IsInLimbo()) or not (self.ismastersim or self.inst:HasTag("INLIMBO")) then
        local is_moving = self.inst.sg ~= nil and self.inst.sg:HasStateTag("moving")
        local is_running = self.inst.sg ~= nil and self.inst.sg:HasStateTag("running")
        --'not' is being used below as a cast-to-boolean operator
        should_locomote =
            (not is_moving ~= not self.wantstomoveforward) or
            (is_moving and (not is_running ~= not self.wantstorun))

        if is_moving or is_running then
            self:StartMoveTimerInternal()
        end
    end

    if should_locomote then
		self.inst:PushEvent("locomote", self.pusheventwithdirection and facedir and { dir = facedir } or nil)
    elseif not self.wantstomoveforward and not self:WaitingForPathSearch() then
        self:ResetPath()
        self:StopUpdatingInternal()
        self:StopMoveTimerInternal()
    end

    local cur_speed = self.inst.Physics:GetMotorSpeed()
    if cur_speed > 0 then
        if self.allow_platform_hopping and (self.bufferedaction == nil or not self.bufferedaction.action.disable_platform_hopping) then
            local mypos_x, mypos_y, mypos_z = self.inst.Transform:GetWorldPosition()

            local rotation = self.inst.Transform:GetRotation() * DEGREES
            local forward_x, forward_z = math.cos(rotation), -math.sin(rotation)

			local hop_distance = self:GetHopDistance(self:GetSpeedMultiplier())

            local my_platform = self.inst:GetCurrentPlatform()
            local other_platform = nil
            local destpos_x, destpos_y, destpos_z
            if self.dest and self.dest:IsValid() then
				if my_platform == self.dest:GetPlatform() then
				    destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
					other_platform = my_platform
				end
			end
			if other_platform == nil then
                destpos_x, destpos_z = forward_x * hop_distance + mypos_x, forward_z * hop_distance + mypos_z
				other_platform = TheWorld.Map:GetPlatformAtPoint(destpos_x, destpos_z)
			end

            local can_hop = false
            local hop_x, hop_z, target_platform, blocked
            local too_early_top_hop = self.time_before_next_hop_is_allowed > 0
            if my_platform ~= other_platform and not too_early_top_hop then
                can_hop, hop_x, hop_z, target_platform, blocked = self:ScanForPlatform(my_platform, destpos_x, destpos_z, hop_distance)
            end
            if not blocked then
                if can_hop then
                    self.last_platform_visited = my_platform

                    self:StartHopping(hop_x, hop_z, target_platform)
                elseif self.inst.components.amphibiouscreature ~= nil and other_platform == nil and not self.inst.sg:HasStateTag("jumping") then
                    local dist = self.inst:GetPhysicsRadius(0) + 2.5
                    local _x, _z = forward_x * dist + mypos_x, forward_z * dist + mypos_z
                    if my_platform ~= nil then
                        local _
                        can_hop, _, _, _, blocked = self:ScanForPlatform(nil, _x, _z, hop_distance)
                    end

                    if not can_hop and self.inst.components.amphibiouscreature:ShouldTransition(_x, _z) then
                        -- If my_platform ~= nil, we already ran the "is blocked" test as part of ScanForPlatform.
                        -- Otherwise, run one now.
                        if (my_platform ~= nil and not blocked) or
                                not self:TestForBlocked(mypos_x, mypos_z, forward_x, forward_z, self.inst:GetPhysicsRadius(0), dist * 1.41421) then -- ~sqrt(2); _x,_z are a dist right triangle so sqrt(dist^2 + dist^2)
                            self.inst:PushEvent("onhop", {x = _x, z = _z})
                        end
                    end
                end
            end

            if (not can_hop and my_platform == nil and target_platform == nil and not self.inst.sg:HasStateTag("jumping")) and self.inst.components.drownable ~= nil and self.inst.components.drownable:ShouldDrown() then
                self.inst:PushEvent("onsink")
            end
        else
            local speed_mult = self:GetSpeedMultiplier()
            local desired_speed = self.isrunning and self:RunSpeed() or self.walkspeed
            if self.dest and self.dest:IsValid() then
                local destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
                local mypos_x, mypos_y, mypos_z = self.inst.Transform:GetWorldPosition()
                local dsq = distsq(destpos_x, destpos_z, mypos_x, mypos_z)
                if dsq <= .25 then
                    speed_mult = math.max(.33, math.sqrt(dsq))
                end
            end

			self:SetMotorSpeed(desired_speed * speed_mult)
        end
    end

    self.time_before_next_hop_is_allowed = math.max(self.time_before_next_hop_is_allowed - dt, 0)
end
