local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/player_idles_waxwell.zip"),
    Asset("SOUND", "sound/maxwell.fsb"),
}

local prefabs =
{
    "statue_transition_2",
    "waxwell_shadowstriker",
}

local start_inv =
{
    default =
    {
        "waxwelljournal",
        "nightmarefuel",
        "nightmarefuel",
        "nightmarefuel",
        "nightmarefuel",
        "nightmarefuel",
        "nightmarefuel",
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WAXWELL
end

prefabs = FlattenTree({prefabs, start_inv}, true)

local BOOK_MUST_TAGS = {"book", "shadowmagic"}
local BOOK_CANT_TAGS = {"INLIMBO", "fueldepleted"}
local function customidleanimfn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, y, z, 3, BOOK_MUST_TAGS, BOOK_CANT_TAGS)) do
		if v.isfloating then
			--secret idle anim near floating codex umbra
			--takes priority over inst.customidlestate
			return "idle3_waxwell"
		end
	end
end

local function DoEffects(pet)
    local x, y, z = pet.Transform:GetWorldPosition()
    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
end

local function KillPet(pet)
    pet.components.health:Kill()
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        --Delayed in case we need to relocate for migration spawning
        pet:DoTaskInTime(0, DoEffects)

        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
            inst.components.sanity:AddSanityPenalty(pet, TUNING.WAXWELL_MINION_SANITY_PENALTY)
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    elseif inst._OnSpawnPet ~= nil then
        inst:_OnSpawnPet(pet)
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        DoEffects(pet)
        pet:Remove()
    elseif inst._OnDespawnPet ~= nil then
        inst:_OnDespawnPet(pet)
    end
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") and v._killtask == nil then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
end

local function OnReroll(inst)
    local todespawn = {}
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") then
            table.insert(todespawn, v)
        end
    end
    for i, v in ipairs(todespawn) do
        inst.components.petleash:DespawnPet(v)
    end
end

local function common_postinit(inst)
    inst:AddTag("shadowmagic")
    inst:AddTag("dappereffects")
    --reader (from reader component) added to pristine state for optimization
    inst:AddTag("reader")
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidleanim = customidleanimfn --priority when not returning nil
	inst.customidlestate = "waxwell_funnyidle"

    inst:AddComponent("reader")

    if inst.components.petleash ~= nil then
        inst._OnSpawnPet = inst.components.petleash.onspawnfn
        inst._OnDespawnPet = inst.components.petleash.ondespawnfn
        inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + 4)
    else
        inst:AddComponent("petleash")
        inst.components.petleash:SetMaxPets(4)
    end
    inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
    inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

    inst.components.sanity.dapperness = 12*8/TUNING.TOTAL_DAY_TIME
    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * .5)
    inst.soundsname = "maxwell"

    inst._onpetlost = function(pet) inst.components.sanity:RemoveSanityPenalty(pet) end

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_becameghost", OnDeath)
    inst:ListenForEvent("ms_playerreroll", OnReroll)
    inst:ListenForEvent("summon_fail", function(inst)
        inst.components.talker:Say(STRINGS.SPELLCOMMAND.WAXWELL.NO_MAX_SANITY)
    end)
end

return MakePlayerCharacter("waxwell", prefabs, assets, common_postinit, master_postinit)
