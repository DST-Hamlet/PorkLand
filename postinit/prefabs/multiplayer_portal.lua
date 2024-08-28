local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("multiplayer_portal", function(inst)
    inst.AnimState:SetBank("portal_dst_classic")
    inst.AnimState:SetBuild("portal_dst_classic")

    if not TheWorld.ismastersim then
        return
    end

    inst.sounds = {
        idle_loop = nil,
        idle = "dontstarve/common/spawn/spawnportal_idle",
        scratch = "dontstarve/common/spawn/spawnportal_scratch",
        jacob = "dontstarve/common/spawn/spawnportal_jacob",
        blink = "dontstarve/common/spawn/spawnportal_blink",
        vines = nil,
        spawning_loop = "dontstarve/common/spawn/spawnportal_spawning",
        armswing = "dontstarve/common/spawn/spawnportal_armswing",
        shake = "dontstarve/common/spawn/spawnportal_shake",
        open = "dontstarve/common/spawn/spawnportal_open",
        glow_loop = "dontstarve/common/spawn/spawnportal_spawning",
        shatter = "dontstarve/common/spawn/spawnportal_open",
        place = nil,
        transmute_pre = nil,
        transmute =nil,
    }
end)
