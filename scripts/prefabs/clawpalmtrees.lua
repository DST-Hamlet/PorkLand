local assets =
{
	Asset("ANIM", "anim/claw_tree_build.zip"),
	Asset("ANIM", "anim/claw_tree_normal.zip"),
	Asset("ANIM", "anim/claw_tree_short.zip"),
	Asset("ANIM", "anim/claw_tree_tall.zip"),
	
	Asset("ANIM", "anim/dust_fx.zip"),
	Asset("SOUND", "sound/forest.fsb"),
	
	Asset("INV_IMAGE", "jungleTreeSeed"),
	
	Asset("MINIMAP_IMAGE", "claw_tree"),
	Asset("MINIMAP_IMAGE", "claw_tree_stump"),
	Asset("MINIMAP_IMAGE", "claw_tree_burnt"),
}

local prefabs =
{
	"cork",
	"charcoal",
	"treeguard",
	"chop_mangrove_blue",
	"fall_mangrove_blue",
	"snake_amphibious",
	"cave_banana",
	"bird_egg",
	"scorpion",
	"burr",
}

local builds =
{
	normal = {
		file="claw_tree_build",
        file_bank = "clawtree",
        prefab_name="clawpalmtree",
        regrowth_product="clawpalmtree_sapling",
        regrowth_tuning=TUNING.EVERGREEN_SPARSE_REGROWTH,
        grow_times=TUNING.EVERGREEN_GROW_TIME,
        normal_loot = {"cork", "cork"},
		short_loot = {"cork"},
		tall_loot = {"cork", "cork", "cork"},
        drop_pinecones=false,
        chop_camshake_delay=0.4,
	},
}

local function makeanims(stage)
	return {
		idle="idle_"..stage,
		sway1="sway1_loop_"..stage,
		sway2="sway2_loop_"..stage,
		chop="chop_"..stage,
		fallleft="fallleft_"..stage,
		fallright="fallright_"..stage,
		stump="stump_"..stage,
		burning="burning_loop_"..stage,
		burnt="burnt_"..stage,
		chop_burnt="chop_burnt_"..stage,
		idle_chop_burnt="idle_chop_burnt_"..stage,
		blown1="blown_loop_"..stage.."1",
		blown2="blown_loop_"..stage.."2",
		blown_pre="blown_pre_"..stage,
		blown_pst="blown_pst_"..stage
	}
end

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")
local old_anims =
{
	idle="idle_old",
	sway1="idle_old",
	sway2="idle_old",
	chop="chop_old",
	fallleft="chop_old",
	fallright="chop_old",
	stump="stump_old",
	burning="idle_olds",
	burnt="burnt_tall",
	chop_burnt="chop_burnt_tall",
	idle_chop_burnt="idle_chop_burnt_tall",
	blown="blown_loop",
	blown_pre="blown_pre",
	blown_pst="blown_pst"
}

local function dig_up_stump(inst, chopper)
	inst.components.lootdropper:SpawnLootPrefab("cork")
	inst:Remove()
end

local function chop_down_burnt_tree(inst, chopper)
	inst:RemoveComponent("workable")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	if not (chopper ~= nil and chopper:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/chop")
	end
	inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
	RemovePhysicsColliders(inst)
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)
	inst.components.lootdropper:SpawnLootPrefab("charcoal")
	inst.components.lootdropper:DropLoot()
	if inst.pineconetask then
		inst.pineconetask:Cancel()
		inst.pineconetask = nil
	end
end

local function GetBuild(inst)
	return builds[inst.build] or builds["normal"]
end

local burnt_highlight_override = {.5,.5,.5}
local function OnBurnt(inst, imm)
	local function changes()
		if inst.components.burnable ~= nil then
			inst.components.burnable:Extinguish()
		end
		inst:RemoveComponent("burnable")
		inst:RemoveComponent("propagator")
		inst:RemoveComponent("growable")
        inst:RemoveComponent("hauntable")
		--inst:RemoveComponent("blowinwindgust")
		inst:RemoveTag("shelter")
		--inst:RemoveTag("fire")		--?? IDK
		--inst:RemoveTag("gustable")	--?? IDK
        MakeHauntableWork(inst)

		--inst.components.lootdropper:SetLoot({})

		if inst.components.workable then
			inst.components.workable:SetWorkLeft(1)
			inst.components.workable:SetOnWorkCallback(nil)
			inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
		end
	end

	if imm then
		changes()
	else
		inst:DoTaskInTime( 0.5, changes)
	end
	inst.AnimState:PlayAnimation(inst.anims.burnt, true)
	inst.MiniMapEntity:SetIcon("claw_tree_burnt.tex")
	inst.AnimState:SetRayTestOnBB(true)
    inst:AddTag("burnt")

	inst.highlight_override = burnt_highlight_override
end

local function PushSway(inst)
    inst.AnimState:PushAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
end

local function Sway(inst)
    inst.AnimState:PlayAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
end

local function SetShort(inst)
	inst.anims = short_anims
	if inst.components.workable then
		inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_SMALL)
	end
	inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)
	Sway(inst)
end

local function GrowShort(inst)
	inst.AnimState:PlayAnimation("grow_tall_to_short")
	inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/wilt_to_grow")
	PushSway(inst)
end

local function SetNormal(inst)
	inst.anims = normal_anims
	if inst.components.workable then
		inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_NORMAL)
	end
	inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)
	Sway(inst)
end

local function GrowNormal(inst)
	inst.AnimState:PlayAnimation("grow_short_to_normal")
	inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/grow")
	PushSway(inst)
end

local function SetTall(inst)
	inst.anims = tall_anims
	if inst.components.workable then
		inst.components.workable:SetWorkLeft(TUNING.JUNGLETREE_CHOPS_TALL)
	end
	inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)
	Sway(inst)
end

local function GrowTall(inst)
	inst.AnimState:PlayAnimation("grow_normal_to_tall")
	inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/grow")
	PushSway(inst)
end

local function inspect_tree(inst)
	return (inst:HasTag("burnt") and "BURNT")
	or (inst:HasTag("stump") and "CHOPPED")
	or nil
end

local growth_stages =
{
	{name="short", time = function(inst) return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[1].base, TUNING.CLAWPALMTREE_GROW_TIME[1].random) end, fn = function(inst) SetShort(inst) end,  growfn = function(inst) GrowShort(inst) end , leifscale=.7 },
	{name="normal", time= function(inst) return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[2].base, TUNING.CLAWPALMTREE_GROW_TIME[2].random) end, fn = function(inst) SetNormal(inst) end, growfn = function(inst) GrowNormal(inst) end, leifscale=1 },
	{name="tall",  time = function(inst) return GetRandomWithVariance(TUNING.CLAWPALMTREE_GROW_TIME[3].base, TUNING.CLAWPALMTREE_GROW_TIME[3].random) end, fn = function(inst) SetTall(inst) end, growfn = function(inst) GrowTall(inst) end, leifscale=1.25 },	
}

local function GetGrowthStages(inst)
    return growth_stages or growth_stages["normal"]
end

local function chop_tree(inst, chopper, chopsleft, numchops)
	if not (chopper ~= nil and chopper:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/harvested/clawtree/chop")
		if chopper:HasTag("beaver") then
			inst.SoundEmitter:PlaySound("dontstarve/wilson/chop_tree_break",nil,0.3)
		end
	end

	inst.AnimState:PlayAnimation(inst.anims.chop)
	inst.AnimState:PushAnimation(inst.anims.sway1, true)
	
	local fx = SpawnPrefab("chop_mangrove_blue")				-- need add fx
	local x, y, z= inst.Transform:GetWorldPosition()
	fx.Transform:SetPosition(x,y + 2 + math.random()*2,z)

	--tell any nearby leifs to wake up
	-- local pt = Vector3(inst.Transform:GetWorldPosition())
	-- local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, TUNING.PALMTREEGUARD_REAWAKEN_RADIUS, {"treeguard"})
	-- for k,v in pairs(ents) do
	-- 	if v.components.sleeper and v.components.sleeper:IsAsleep() then
	-- 		v:DoTaskInTime(math.random(), function() v.components.sleeper:WakeUp() end)
	-- 	end
	-- 	v.components.combat:SuggestTarget(chopper)
	-- end
end

local function chop_down_tree_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .03,
        inst.components.growable ~= nil and
        inst.components.growable.stage > 2 and .5 or .25,
        inst, 6)
end


local function make_stump(inst)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("workable")
    inst:RemoveTag("shelter")
	--inst:RemoveComponent("blowinwindgust")
	inst:RemoveTag("gustable")
    inst:RemoveComponent("hauntable")
    MakeHauntableIgnite(inst)

    RemovePhysicsColliders(inst)

    inst:AddTag("stump")
    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    inst.MiniMapEntity:SetIcon("claw_tree_stump.tex")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.timer and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(GetBuild(inst).regrowth_tuning.DEAD_DECAY_TIME, GetBuild(inst).regrowth_tuning.DEAD_DECAY_TIME*0.5))
    end
end

local function chop_down_tree(inst, chopper)	
	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	local pt = inst:GetPosition()

    local he_right = true

    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

	local fx = SpawnPrefab("fall_mangrove_blue")					-- need add fx
	local x, y, z= inst.Transform:GetWorldPosition()
	fx.Transform:SetPosition(x,y + 2 + math.random()*2,z)
	
	if inst.components.growable == nil or inst.components.growable.stage > 1 then
        inst:DoTaskInTime(GetBuild(inst).chop_camshake_delay, chop_down_tree_shake)
    end

	-- make snakes attack
	local x,y,z = inst.Transform:GetWorldPosition()
	local snakes = TheSim:FindEntities(x,y,z, 2,nil,nil,{"snake_amphibious","scorpion"})
	for k, v in pairs(snakes) do
		if v.components.combat then
			v.components.combat:SetTarget(chopper)
		end
	end

	make_stump(inst)
	inst.AnimState:PushAnimation(inst.anims.stump)
end

local function onpineconetask(inst)
    local pt = inst:GetPosition()
    local angle = math.random() * 2 * PI
    pt.x = pt.x + math.cos(angle)
    pt.z = pt.z + math.sin(angle)
    inst.components.lootdropper:DropLoot(pt)
    inst.pineconetask = nil
    inst.burntcone = true
end

local function tree_burnt(inst)
	OnBurnt(inst)
	if not inst.burntcone then
        if inst.pineconetask ~= nil then
            inst.pineconetask:Cancel()
        end
        inst.pineconetask = inst:DoTaskInTime(10, onpineconetask)
    end
end

local function dropCritter(inst, prefab)
	local snake = SpawnPrefab(prefab)
	if snake == nil then return end
	local pt = Vector3(inst.Transform:GetWorldPosition())

	if math.random(0, 1) == 1 then
		pt = pt + (TheCamera:GetRightVec()*((math.random()*1)+1)) 
	else
		pt = pt - (TheCamera:GetRightVec()*((math.random()*1)+1))
	end

	snake.sg:GoToState("fall")
	pt.y = pt.y + (2*inst.components.growable.stage)
	
	snake.Transform:SetPosition(pt:Get())
end

local function tree_lit(inst)
	DefaultIgniteFn(inst)
	if not inst.flushed and math.random() < 0.4 then		
		inst.flushed = true		

		local prefab = "snake_amphibious"
		
		if math.random() < 0.5 then 
			prefab = "scorpion"
		end

		inst:DoTaskInTime(math.random()*0.5, function() dropCritter(inst, prefab) end)
		if math.random() < 0.3 then
			inst:DoTaskInTime(math.random()*0.5, function() dropCritter(inst, prefab) end)
		end	
		
	end
end

local function handler_growfromseed (inst)
    inst.components.growable:SetStage(1)
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function updateTreeType(inst)
	inst.AnimState:SetBuild(GetBuild(inst).file)	
end

local function doTransformBloom(inst)
	if not inst:HasTag("rotten") then
		inst.build = "blooming"
		
		updateTreeType(inst)	
	end
end

local function doTransformNormal(inst)
	if not inst:HasTag("rotten") then	
		inst.build = "normal"
		
		updateTreeType(inst)
	end
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
		data.burnt = true
	end

	if inst.flushed then
		data.flushed = inst.flushed
	end

	if inst:HasTag("stump") then
		data.stump = true
	end

	if inst.build ~= "normal" then
		data.build = inst.build
	end
	
	if inst._lastrebirth ~= nil then
        data.lastrebirth = inst._lastrebirth - GetTime()
    end

    data.burntcone = inst.burntcone
end

local function onload(inst, data)
	if data then
		inst.build = data.build ~= nil and builds[data.build] ~= nil and data.build or "normal"

		if data.stump then
            make_stump(inst)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            if data.burnt or inst:HasTag("burnt") then
                DefaultBurntFn(inst)
            end
        elseif data.burnt and not inst:HasTag("burnt") then
            OnBurnt(inst, true)
        end

		if not inst:IsValid() then
			return
		end
		
        if data.bloomtask then
            if inst.bloomtask then inst.bloomtask:Cancel() inst.bloomtask = nil end
            inst.bloomtaskinfo = nil
            inst.bloomtask, inst.bloomtaskinfo = inst:ResumeTask(data.bloomtask, function() doTransformBloom(inst) end)
        end   
        if data.unbloomtask then
            if inst.unbloomtask then inst.unbloomtask:Cancel() inst.unbloomtask = nil end
            inst.unbloomtaskinfo = nil
            inst.unbloomtask, inst.unbloomtaskinfo = inst:ResumeTask(data.unbloomtask, function() doTransformNormal(inst) end)
        end 

		if data.flushed then
			inst.flushed = data.flushed
		end

		if data.lastrebirth ~= nil then
            inst._lastrebirth = data.lastrebirth + GetTime()
        end

        inst.burntcone = data.burntcone
	end
end

local function OnEntitySleep(inst)
	local doBurnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning()
    if doBurnt and inst:HasTag("stump") then
        DefaultBurntFn(inst)
    else
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("inspectable")
        if doBurnt then
            inst:RemoveComponent("growable")
            inst:RemoveComponent("petrifiable")
            inst:AddTag("burnt")
        end
    end
end

local function OnEntityWake(inst)
	if inst:HasTag("burnt") then
        tree_burnt(inst)
    else
        local isstump = inst:HasTag("stump")

        if not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
            if inst.components.burnable == nil then
                if isstump then
                    MakeSmallBurnable(inst)
                else
                    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
                    inst.components.burnable:SetFXLevel(5)
                    inst.components.burnable:SetOnBurntFn(tree_burnt)
                end
            end

            if inst.components.propagator == nil then
                if isstump then
                    MakeSmallPropagator(inst)
                else
                    MakeMediumPropagator(inst)
                end
            end
        end

        if not isstump and GetBuild(inst).rebirth_loot ~= nil then
            -- This is a failsafe because trees don't actually grow offscreen (or
            -- rather, never more than one stage) So this will cause trees that
            -- have been offscreen for multiple stages to drop some loot even if
            -- their growth hasn't reached there yet.
            local growthcycletime = inst._lastrebirth
            for i,data in ipairs(GetBuild(inst).grow_times) do
                growthcycletime = growthcycletime + data.base
            end
            if growthcycletime < GetTime() then
                DoRebirthLoot(inst)
            end
        end
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end
end

local REMOVABLE =
{
    ["cork"] = true,
    ["charcoal"] = true,
}
local DECAYREMOVE_MUST_TAGS = { "_inventoryitem" }
local DECAYREMOVE_CANT_TAGS = { "INLIMBO", "fire" }
local function OnTimerDone(inst, data)
    if data.name == "decay" then
        local x, y, z = inst.Transform:GetWorldPosition()
        if inst:IsAsleep() then
            -- before we disappear, clean up any crap left on the ground
            -- too many objects is as bad for server health as too few!
            local leftone = false
            for i, v in ipairs(TheSim:FindEntities(x, y, z, 6, DECAYREMOVE_MUST_TAGS, DECAYREMOVE_CANT_TAGS)) do
                if REMOVABLE[v.prefab] then
                    if leftone then
                        v:Remove()
                    else
                        leftone = true
                    end
                end
            end
        else
            SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
        end
        inst:Remove()
    end
end



local function OnGustAnimDone(inst)
	if inst:HasTag("stump") or inst:HasTag("burnt") then
		inst:RemoveEventCallback("animover", OnGustAnimDone)
		return
	end
	if inst.components.blowinwindgust and inst.components.blowinwindgust:IsGusting() then
		local anim = math.random(1,2)
		inst.AnimState:PlayAnimation(inst.anims["blown"..tostring(anim)], false)
	else
		inst:DoTaskInTime(math.random()/2, function(inst)
            if not inst:HasTag("stump") and not inst:HasTag("burnt") then
                inst.AnimState:PlayAnimation(inst.anims.blown_pst, false)
                PushSway(inst)
            end
            inst:RemoveEventCallback("animover", OnGustAnimDone)
		end)
	end
end

local function OnGustStart(inst, windspeed)
	if inst:HasTag("stump") or inst:HasTag("burnt") then
		return
	end
	inst:DoTaskInTime(math.random()/2, function(inst)
		if inst:HasTag("stump") or inst:HasTag("burnt") then
			return
		end
		if inst.spotemitter == nil then
			AddToNearSpotEmitter(inst, "treeherd", "tree_creak_emitter", TUNING.TREE_CREAK_RANGE)
		end
		inst.AnimState:PlayAnimation(inst.anims.blown_pre, false)
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wind_tree_creak")
		inst:ListenForEvent("animover", OnGustAnimDone)
	end)
end

local function OnGustEnd(inst, windspeed)
end

local function OnGustFall(inst)
	if inst:HasTag("burnt") then
		chop_down_burnt_tree(inst, ThePlayer)
	else
		chop_down_tree(inst, ThePlayer)
	end
end

local function dropBurr(inst)
	local burr = SpawnPrefab("burr")
	local pt = Vector3(inst.Transform:GetWorldPosition())

	if math.random(0, 1) == 1 then
		pt = pt + (TheCamera:GetRightVec()*((math.random()*1)+1)) 
	else
		pt = pt - (TheCamera:GetRightVec()*((math.random()*1)+1))
	end

	burr.AnimState:PlayAnimation("drop")
	burr.AnimState:PushAnimation("idle")

	--pt.y = pt.y + (2*inst.components.growable.stage)
	
	burr.Transform:SetPosition(pt:Get())
end

local function canbloom(inst)
	 if not inst:HasTag("stump") and not inst:HasTag("rotten") then
	 	return true
	 else
	 	return false
	 end
end

local function startbloom(inst)
	doTransformBloom(inst)
end

local function stopbloom(inst)
	doTransformNormal(inst)
end

local function onhauntwork(inst, haunter)
    if inst.components.workable ~= nil and math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.workable:WorkedBy(haunter, 1)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function tree(name, build, stage, data)
	local function fn()
		local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

		inst.MiniMapEntity:SetIcon("claw_tree.tex")
		inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")
		inst:AddTag("workable")
		inst:AddTag("shelter")
		inst:AddTag("gustable")
		inst:AddTag("plainstree")

		if build == "rot" then
			inst:AddTag("rotten")
		end

		inst.build = build
        inst.AnimState:SetBuild(GetBuild(inst).file)

        inst.AnimState:SetBank(GetBuild(inst).file_bank)

        inst:SetPrefabName(GetBuild(inst).prefab_name)
        inst:AddTag(GetBuild(inst).prefab_name) -- used by regrowth
		
		MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)

		-------------------
		MakeLargeBurnable(inst)
		inst.components.burnable:SetFXLevel(3)
		inst.components.burnable:SetOnBurntFn(tree_burnt)
		
		MakeSmallPropagator(inst)
		inst.components.burnable:SetOnIgniteFn(tree_lit)

		-------------------
		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree
		
		-------------------
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetOnWorkCallback(chop_tree)
		inst.components.workable:SetOnFinishCallback(chop_down_tree)

		-------------------
		inst:AddComponent("lootdropper")
		
		---------------------
		inst:AddComponent("growable")
        inst.components.growable.stages = GetGrowthStages(inst)
        inst.components.growable:SetStage(stage == 0 and math.random(1, 3) or stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable.magicgrowable = true
        inst.components.growable:StartGrowing()

		inst:AddComponent("simplemagicgrower")
        inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages - 1)
		
		inst.growfromseed = handler_growfromseed

		--=need add component=--
		
		-- inst:AddComponent("blowinwindgust")
		-- inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING.JUNGLETREE_WINDBLOWN_SPEED)
		-- inst.components.blowinwindgust:SetDestroyChance(TUNING.JUNGLETREE_WINDBLOWN_FALL_CHANCE)
		-- inst.components.blowinwindgust:SetGustStartFn(OnGustStart)
		-- --inst.components.blowinwindgust:SetGustEndFn(OnGustEnd)
		-- inst.components.blowinwindgust:SetDestroyFn(OnGustFall)
		-- inst.components.blowinwindgust:Start()
		-- 
		-- inst:AddComponent("mystery")

		---------------------
        inst:AddComponent("plantregrowth")
        inst.components.plantregrowth:SetRegrowthRate(GetBuild(inst).regrowth_tuning.OFFSPRING_TIME)
        inst.components.plantregrowth:SetProduct(GetBuild(inst).regrowth_product)
        inst.components.plantregrowth:SetSearchTag(GetBuild(inst).prefab_name)

		---------------------
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)
		
		---------------------
        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(onhauntwork)
		
		---------------------
		inst.OnSave = onsave
		inst.OnLoad = onload

		MakeSnowCovered(inst, .01)
		---------------------

		if GetBuild(inst).rebirth_loot ~= nil then
            inst._lastrebirth = 0
            for i,time in ipairs(GetBuild(inst).grow_times) do
                if i == inst.components.growable.stage then
                    break
                end
                inst._lastrebirth = inst._lastrebirth - time.base
            end
        end
		print(inst.AnimState:GetCurrentAnimationNumFrames())
		if data =="stump"  then
			inst:RemoveComponent("burnable")
			MakeSmallBurnable(inst)
			inst:RemoveComponent("workable")
			inst:RemoveComponent("propagator")
			MakeSmallPropagator(inst)
			inst:RemoveComponent("growable")
			--inst:RemoveComponent("blowinwindgust")
			inst:RemoveTag("gustable")
			RemovePhysicsColliders(inst)
			inst.AnimState:PlayAnimation(inst.anims.stump)
			inst.MiniMapEntity:SetIcon("claw_tree_stump.tex")
			inst:AddTag("stump")
			inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.DIG)
			inst.components.workable:SetOnFinishCallback(dig_up_stump)
			inst.components.workable:SetWorkLeft(1)
		else
			inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
            if data == "burnt" then
                OnBurnt(inst)
            end
        end

		inst.OnEntitySleep = OnEntitySleep
		inst.OnEntityWake = OnEntityWake

		return inst
	end
	return Prefab(name, fn, assets, prefabs)
end

return tree("clawpalmtree", "normal", 0),
		tree("clawpalmtree_normal", "normal", 2),
		tree("clawpalmtree_tall", "normal", 3),
		tree("clawpalmtree_short", "normal", 1),
		tree("clawpalmtree_burnt", "normal", 0, "burnt"),
		tree("clawpalmtree_stump", "normal", 0, "stump")
