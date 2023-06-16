local assets =
{
	Asset("ANIM", "anim/pig_house.zip"),
}

local prefabs = 
{

}

local REBUILD_REACTION_TIME = TUNING.TOTAL_DAY_TIME /50
local REBUILD_REACTION_VARIANCE = TUNING.SEG_TIME * 3 /50

local CALL_WORKER_TIME = TUNING.SEG_TIME * 3 /50

local OFF_SCREENDIST = 30 
local AUTO_REPAIRDIST = 100


local function fix(inst,fixer)
    if fixer and fixer.components.fixer then   -- covers the actual worker (possibly the player?)
        fixer.components.fixer:ClearTarget()
    end
    if inst.fixer and inst.fixer.components.fixer then  -- covers worker selected
        inst.fixer.components.fixer:ClearTarget()
    end      
    if inst.construction_prefab then
        local newprop = SpawnPrefab(inst.construction_prefab)
        newprop.Transform:SetPosition(inst.Transform:GetWorldPosition()) 

        if inst.reconstructedanims then
            newprop.AnimState:PlayAnimation(inst.reconstructedanims.play)
            newprop.AnimState:PushAnimation(inst.reconstructedanims.push)            
        else
            newprop.AnimState:PlayAnimation("place")
            newprop.AnimState:PushAnimation("idle")
        end        
        if inst.cityID then
            if not newprop.components.citypossession then
                newprop:AddComponent("citypossession")
            end
            newprop.components.citypossession:SetCity(inst.cityID)
            if newprop.citypossessionfn then
                newprop.citypossessionfn(newprop)
            end
        end
        if inst.interiorID then
            newprop.interiorID = inst.interiorID
        end
        if newprop.reconstructed then 
            newprop.reconstructed(newprop) 
        end
        newprop:AddTag("reconstructed")
        if inst.spawnerdata and newprop.components.spawner then

            newprop.components.spawner:Configure( inst.spawnerdata.childname, inst.spawnerdata.delay or 0, inst.spawnerdata.delay or 0)

            if inst.spawnerdata.child and inst.spawnerdata.child:IsValid() then
                newprop.components.spawner:TakeOwnership(inst.spawnerdata.child)
    end
        end
    end
    inst:Remove()
end

local function onhammered(inst, worker)

    if worker and worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("hammer") then

        inst.reconstruction_stage = inst.reconstruction_stage +1

        if inst.reconstruction_stages[inst.reconstruction_stage] then

            inst.AnimState:SetBank(inst.reconstruction_stages[inst.reconstruction_stage].bank)
            inst.AnimState:SetBuild(inst.reconstruction_stages[inst.reconstruction_stage].build)
            inst.AnimState:PlayAnimation(inst.reconstruction_stages[inst.reconstruction_stage].anim,true)       
            local scale = inst.reconstruction_stages[inst.reconstruction_stage].scale
            if scale then
                inst.AnimState:SetScale(scale[1],scale[2],scale[3])
            end

            inst.saveartdata = {
                bank = inst.reconstruction_stages[inst.reconstruction_stage].bank,
                build = inst.reconstruction_stages[inst.reconstruction_stage].build,
                anim = inst.reconstruction_stages[inst.reconstruction_stage].anim,
                scale  = inst.reconstruction_stages[inst.reconstruction_stage].scale,
            }

            inst.components.workable:SetWorkLeft(4)
        else
            fix(inst,worker)
        end
    else
        inst.components.workable:SetWorkLeft(4)
    end

end

local function onhit(inst, worker)

end

local function OnSave(inst, data)
    if inst.saveartdata then
        data.bank = inst.saveartdata.bank
        data.build = inst.saveartdata.build
        data.anim = inst.saveartdata.anim
        if inst.saveartdata.scale then
            data.scaleX = inst.saveartdata.scale[1]
            data.scaleY = inst.saveartdata.scale[2]
            data.scaleZ = inst.saveartdata.scale[3]
        end

    end
    data.reconstruction_stages = inst.reconstruction_stages
    data.reconstruction_stage = inst.reconstruction_stage
    data.construction_prefab = inst.construction_prefab 
    data.reconstructedanims = inst.reconstructedanims

    if inst.nameoverride then
        data.nameoverride = inst.nameoverride
    end

    if inst.cityID then
        data.cityID = inst.cityID
    end

    if inst.interiorID then
        data.interiorID = inst.interiorID
    end


    if inst.spawnerdata and inst.spawnerdata.child and inst.spawnerdata.child:IsValid() then
        data.childname = inst.spawnerdata.childname
        data.child = inst.spawnerdata.child and inst.spawnerdata.child.GUID or nil
        data.delay = inst.spawnerdata.delay
	end
    if data.child then
        return {data.child}
    end
end

local function OnLoad(inst, data)
    if data then
        inst.saveartdata = {
            bank = data.bank,
            build = data.build,
            anim = data.anim,
        }

        if inst.saveartdata.bank then
            inst.AnimState:SetBank(inst.saveartdata.bank)
            inst:Show()
        end

        if inst.saveartdata.build then
            inst.AnimState:SetBuild(inst.saveartdata.build)
            inst:Show()
        end
        
        if inst.saveartdata.anim then
            inst.AnimState:PlayAnimation(inst.saveartdata.anim, true)
            inst:Show()
        end

        if data.scaleX then
            inst.saveartdata.scale = {data.scaleX, data.scaleY, data.scaleZ}
            inst.AnimState:SetScale(data.scaleX, data.scaleY, data.scaleZ)
            inst:Show()
        end 

        if data.cityID then
            inst.cityID = data.cityID
        end

        if data.interiorID then
            inst.interiorID = data.interiorID
        end

        inst.reconstruction_stage = data.reconstruction_stage    
        inst.reconstruction_stages = data.reconstruction_stages  
        inst.construction_prefab = data.construction_prefab 
        inst.reconstructedanims = data.reconstructedanims

        if data.nameoverride then
            inst:SetPrefabNameOverride(data.nameoverride)
        end

        if data.childname then
            inst.spawnerdata = {
                childname = data.childname,
                delay = data.delay
            }
        end
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data.child then
        inst.spawnerdata.child = newents[data.child].entity
    end
end

local function getstatus(inst)  
    if inst.reconstruction_stage == 2 then
        return "SCAFFOLD"
    else
        return "RUBBLE"
    end
end

function GetSpawnPoint(inst, pt)
    -- if ThePlayer:HasTag("aquatic") then 
        -- return 
    -- end 

    local theta = math.random() * 2 * PI
    local radius = OFF_SCREENDIST

    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    if offset then
        local pos = pt+offset

        local ground = TheWorld
        local tile = GROUND.GRASS
        if ground and ground.Map then
            tile = inst:GetCurrentTileType(pos:Get())
        end

        -- local onWater = ground.Map:IsWater(tile)
        local onWater = IsOceanTile(tile)
        if not onWater then 
            return pos
        end 
    end
end


local function setfixer(inst,fixer)
    fixer.components.fixer:SetTarget(inst)
    inst.fixer = fixer
end

local function spawnFixer(inst)
    -- if away from player fix, else
    -- look for fixer pig
    -- spawn if none
    -- set pig's fixer target to this inst.
	local nearestPlayerInst = nil
	local nearestPlayerDist = 9999
	for i, v in ipairs(AllPlayers) do
		local distSq = v:GetDistanceSqToInst(inst)
		if nearestPlayerDist > distSq then
			nearestPlayerDist = distSq
			nearestPlayerInst = v
		end
	end
    -- if inst:GetDistanceSqToInst(ThePlayer) > AUTO_REPAIRDIST * AUTO_REPAIRDIST then
    if nearestPlayerDist > AUTO_REPAIRDIST * AUTO_REPAIRDIST then
        fix(inst)        
    else

        if not inst.fixer or inst.fixer.components.health:IsDead() then
            inst.fixer = nil
            -- if GetClock():IsDay() then   
            if TheWorld.state.isday then              
                local x,y,z = inst.Transform:GetWorldPosition()

                local ents = TheSim:FindEntities(x,y,z, 30, {"fixer"})
                if #ents > 0 then
                    for i,ent in ipairs(ents)do
                        if ent.components.fixer.target == nil then
                            setfixer(inst,ent)
                            break
                        end
                    end
                else
                    -- local pt = Vector3(ThePlayer.Transform:GetWorldPosition()) 
                    local pt = Vector3(nearestPlayerInst.Transform:GetWorldPosition()) 
                    local spawn_pt = GetSpawnPoint(inst, pt)
                    if spawn_pt then
                        local fixer = SpawnPrefab("pigman_mechanic")
						if fixer then
							fixer.Physics:Teleport(spawn_pt:Get())
							setfixer(inst,fixer)
						end
                    end
                end
            end
        end
        inst.task:Cancel()
        inst.task = nil
        inst.task = inst:DoTaskInTime(1,function() spawnFixer(inst) end)
    end
end

local function OnRemove(inst)
    inst.task:Cancel()
    inst.task = nil
end

local function DisplayNameFn(inst)
    if inst.nameoverride then return end

    return STRINGS.NAMES[string.upper(inst.construction_prefab)]
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState() 
	inst.entity:AddNetwork()

    --inst.entity:AddPhysics() 
    --MakeObstaclePhysics(inst, .25)         

    inst.entity:AddSoundEmitter()

    anim:SetBank("pig_house")
    anim:SetBuild("pig_house")

    anim:PlayAnimation("unbuilt",true)
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("lootdropper")

    MakeSnowCovered(inst, .01)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst.displaynamefn = DisplayNameFn
   
    inst.reconstruction_stage = 1
    inst.reconstruction_stages = {}

    inst:Hide()

    inst.fix = fix

    inst.OnRemoveEntity = OnRemove

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    inst.task = inst:DoTaskInTime(REBUILD_REACTION_TIME +(math.random() *REBUILD_REACTION_VARIANCE), function() spawnFixer(inst) end)
    return inst
end

return Prefab( "reconstruction_project", fn, assets, prefabs)
