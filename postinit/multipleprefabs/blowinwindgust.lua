local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("grass", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)
end)

AddPrefabPostInit("depleted_grass", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.GRASS_WINDBLOWN_SPEED, TUNING.GRASS_WINDBLOWN_FALL_CHANCE)
end)

AddPrefabPostInit("sapling", function (inst)
    MakePickableBlowInWindGust(inst, TUNING.SAPLING_WINDBLOWN_SPEED, TUNING.SAPLING_WINDBLOWN_FALL_CHANCE)
end)

local stage_lookup_table = {
    "short",
    "normal",
    "tall",
    "old",
}

local function PushSway(inst)
    if math.random() > .5 then
        inst.AnimState:PushAnimation(inst.anims.sway1, true)
    else
        inst.AnimState:PushAnimation(inst.anims.sway2, true)
    end
end

local function OnGustAnimDone(inst)
    if inst:HasTag("stump") or inst:HasTag("burnt") then
        inst:RemoveEventCallback("animover", OnGustAnimDone)
        return
    end
    if inst.components.blowinwindgust and inst.components.blowinwindgust:IsGusting() then
        local anim = math.random(1, 2)
        inst.AnimState:PlayAnimation("blown_loop_" .. stage_lookup_table[inst.components.growable.stage] .. tostring(anim), false)
    else
        inst:DoTaskInTime(math.random() / 2, function(inst)
            if not inst:HasTag("stump") and not inst:HasTag("burnt") then
                inst.AnimState:PlayAnimation("blown_pst_".. stage_lookup_table[inst.components.growable.stage], false)
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
    inst:DoTaskInTime(math.random() / 2, function(inst)
        if inst:HasTag("stump") or inst:HasTag("burnt") then
			return
		end
        -- Whats the point of this?
        -- if inst.spotemitter == nil then
        --     AddToNearSpotEmitter(inst, "treeherd", "tree_creak_emitter", TUNING.TREE_CREAK_RANGE)
        -- end
        inst.AnimState:PlayAnimation("blown_pre_".. stage_lookup_table[inst.components.growable.stage], false)
        -- inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/wind_tree_creak")
        inst:ListenForEvent("animover", OnGustAnimDone)
    end)
end

local function OnGustFall(inst)
    inst.components.workable.onfinish(inst, TheWorld)
end

local function make_tree_blowinwindgust(tree, type)
    AddPrefabPostInit(tree, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        if not inst.components.blowinwindgust then
            inst:AddComponent("blowinwindgust")
        end

        inst.components.blowinwindgust:SetWindSpeedThreshold(TUNING[type .. "_WINDBLOWN_SPEED"])
        inst.components.blowinwindgust:SetDestroyChance(TUNING[type .. "_WINDBLOWN_FALL_CHANCE"])
        inst.components.blowinwindgust:SetGustStartFn(OnGustStart)
        inst.components.blowinwindgust:SetDestroyFn(OnGustFall)
        inst.components.blowinwindgust:Start()

        local onload = inst.OnLoad
        inst.OnLoad = function(inst, data)
            if onload then onload(inst, data) end
            if data and (data.stump or data.burnt) then
                inst:RemoveComponent("blowinwindgust")
            end
        end

        local onburnt = inst.components.burnable.onburnt
        inst.components.burnable:SetOnBurntFn(function(inst)
            if onburnt then onburnt(inst) end
            inst:RemoveComponent("blowinwindgust")
        end)

        local onfinish = inst.components.workable.onfinish
        inst.components.workable:SetOnFinishCallback(function(inst, chopper)
            if onfinish then onfinish(inst, chopper) end
            inst:RemoveComponent("blowinwindgust")
        end)
    end)
end

local evergreens = {
    "evergreen",
	"evergreen_normal",
    "evergreen_tall",
    "evergreen_short",
    "evergreen_sparse",
    "evergreen_sparse_normal",
    "evergreen_sparse_tall",
    "evergreen_sparse_short",
    "evergreen_burnt",
}
local deciduoustrees = {
    "deciduoustree",
    "deciduoustree_normal",
    "deciduoustree_tall",
    "deciduoustree_short",
    "deciduoustree_burnt",
}

for _, tree in pairs(evergreens) do
    make_tree_blowinwindgust(tree, "EVERGREEN")
end

for _, tree in pairs(deciduoustrees) do
    make_tree_blowinwindgust(tree, "DECIDUOUS")
end
