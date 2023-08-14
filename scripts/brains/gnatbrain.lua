require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/findlight"
require "behaviours/follow"

local MAX_WANDER_DIST = 20
local AGRO_DIST = 5
local AGRO_STOP_DIST = 7

function IsOceanTile(tile)
	return TileGroupManager:IsOceanTile(tile)
end

function IsImpassableTile(tile)
    return TileGroupManager:IsImpassableTile(tile)
end

local function IsPointCloseToWaterOrImpassable(x, y, z,radius)
    local world = TheWorld.Map
	for i = -radius, radius, 1 do
		if IsOceanTile(world:GetTileAtPoint(x - radius, y + i, z)) or IsOceanTile(world:GetTileAtPoint(x + radius, y + i, z)) then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if IsOceanTile(world:GetTileAtPoint(x + i, y - radius, z)) or IsOceanTile(world:GetTileAtPoint(x + i, y + radius, z)) then
			return true
		end
	end
    for i = -radius, radius, 1 do
		if IsImpassableTile(world:GetTileAtPoint(x - radius, y + i, z)) or IsImpassableTile(world:GetTileAtPoint(x + radius, y + i, z)) then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if IsImpassableTile(world:GetTileAtPoint(x + i, y - radius, z)) or IsImpassableTile(world:GetTileAtPoint(x + i, y + radius, z)) then
			return true
		end
	end
	return false
end

local function findinfesttarget(inst,brain)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRangeSq( x, y, z, 10 * 10, true)
    if not inst.components.freezable:IsFrozen() and target and inst:GetDistanceSqToInst(target) < AGRO_DIST*AGRO_DIST and not inst.infesting then
        inst.chasingtargettask = inst:DoPeriodicTask(0.2,function()
                --print(inst:GetDistanceSqToInst(target) , AGRO_STOP_DIST*AGRO_STOP_DIST, inst.components.infester.infesting)
                if inst:GetDistanceSqToInst(target) > AGRO_STOP_DIST*AGRO_STOP_DIST then
                    inst:ClearBufferedAction()
                    inst.components.locomotor:Stop()
                    inst.sg:GoToState("idle")

                    if inst.chasingtargettask then
                        inst.chasingtargettask:Cancel()
                        inst.chasingtargettask = nil
                    end

                    -- THIS IS GROSS.. why does the "infest" DoAction not get it's OnFail event?!
                    brain:Stop()
                    brain:Start()
                end
            end)

        return BufferedAction(inst, target, ACTIONS.INFEST)
    end
    return false
end

local function findlighttarget(inst)
    local light = inst.findlight(inst)
    if light then
        return light
    end
end

local function makenest(inst)
    if not inst.components.homeseeker and not inst.makehome and not inst.makehometime then
        inst.makehometime = inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME * (0.5 + (math.random()*0.5) ), function()
                inst.makehome = true
            end)
    end

    if inst.makehome and not inst.components.homeseeker then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 4, nil, {"FX", "NOCLICK", "DECOR","INLIMBO"} )
        if #ents <= 1 and not IsPointCloseToWaterOrImpassable(x, y, z, 4) then--将离水体的最近距离从2修改为4，防止虫丘离水体过近
            inst.makehome = nil
            if inst.makehometime then
                inst.makehometime:Cancel()
                inst.makehometime = nil
            end
            return BufferedAction(inst, nil, ACTIONS.SPECIAL_ACTION)
        end
    end
end

local GnatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)



function GnatBrain:OnStart()

    --local clock = GetClock() --单机版的旧函数，在联机版已弃用

    local root =
        PriorityNode(
        {
            WhileNode( function() return not self.inst.components.infester.infesting end, "not infesting",
            PriorityNode{
                WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire",
                    Panic(self.inst) ),
                WhileNode( function() return  TheWorld.state.isdusk or TheWorld.state.isnight end, "chase light",
                    Follow(self.inst, function() return findlighttarget(self.inst) end, 0, 1, 1)),
                DoAction(self.inst, function() return findinfesttarget(self.inst,self) end, "infest", true),
                DoAction(self.inst, function() return makenest(self.inst) end, "make nest", true),
                Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
            },.5)
        },1)


    self.bt = BT(self.inst, root)


end

return GnatBrain
