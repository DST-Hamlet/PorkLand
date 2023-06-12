require("stategraphs/commonstates")


local events=
{
    EventHandler("spring", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("extended") then   
            inst.sg:GoToState("extending")
        end       
    end),   

    EventHandler("reset", function(inst)
        --print("RESET EVENT")
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("retracted") and not inst.components.burnable:IsBurning() then   
            inst.sg:GoToState("retract")
        end       
    end),     

    EventHandler("hit", function(inst)
        if inst.sg:HasStateTag("extended") then   
            inst.sg:GoToState("hit")
        end       
    end),
    EventHandler("dead", function(inst)
        inst.sg:GoToState("destroyed")
    end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle","retracted","invisible"},
        onenter = function(inst)
            inst.setextendeddata(inst)
            inst.AnimState:PlayAnimation("idle_retract",true)
        end,       
    },
    
    State {
		name = "extending",
		tags = {"busy","damage"},
		
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/spear")       
            inst.AnimState:PlayAnimation("extending")                      

            inst.setextendeddata(inst, true) 
        end,

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst) inst.inflictdamage(inst) end),
        },

        events=
        {
            EventHandler("animover", function(inst)  inst.sg:GoToState("extended") end ),
        },
    },
    
    State{
        name = "extended",
        tags = {"extended"},
        
        onenter = function(inst)
            inst.setextendeddata(inst, true)             
            if inst.wantstoretract then
                inst.sg:GoToState("retract")
            else
                inst.AnimState:PlayAnimation("idle_extend")        
            end
        end,
    },

    State{
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")        
        end,

        events=
        {
            EventHandler("animover", function(inst) 
                if inst.components.health:IsDead() then
                    inst.sg:GoToState("destroyed") 
                else
                    inst.sg:GoToState("extended") 
                end
            end ),
        },        
    },    

    
    State{
        name = "breaking",
        tags = {"busy"},
        
        onenter = function(inst)
            inst:RemoveTag("hostile")
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("breaking")        
        end,
    },  
    
    State{
        name = "destroyed",
        tags = {"busy"},
        
        onenter = function(inst)
            inst:RemoveTag("hostile")
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("broken",true)        
        end,
    },  

    State {
        name = "retract",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.setextendeddata(inst)
            inst.AnimState:PlayAnimation("retracting")
        end,
        
        events=
        {
            EventHandler("animover", function(inst)                     
                inst.sg:GoToState("idle") 
            end ),
        },
    },  
}
    
return StateGraph("spear_trap", states, events, "idle")

