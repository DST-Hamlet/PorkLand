--做了点赛博搬砖，不知道有没有用。
--防花粉暂时被归类到治疗和衣服、放雾暂时被归类到了雨具和衣服。也许应该做一个“危险环境防护”之类的分类来放这些东西。
--如果你们打算和ia兼容的话，我不太清楚怎么处理猪镇继承自海难的那些配方，全放在最后面了。
--不包括室内装修。

local Ingredient = GLOBAL.Ingredient
local Tech = GLOBAL.TECH

--工具栏---------------------------------------------------------------------------------
AddRecipe2(
    "shears", 
    {
        Ingredient("twigs", 2),Ingredient("iron", 2),
    }, 
    TECH.SCIENCE_ONE,
    {
       --atlas = "", --图片，tex
       --image = "", --图片，xml
       --nounlock=, --无法解锁
       --numtogive= , --一次制作的数量
       --builder_tag="", --角色专属
       --placer="_placer",--放置预览
    },
    { "TOOLS" }--分类
)
--光源------------------------------------------------------------------------------
AddRecipe2(
    "candlehat", 
    {
        Ingredient("cork", 4),Ingredient("iron", 2),
    }, 
    TECH.SCIENCE_ONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    }
    { "LIGHT","RAIN" }--分类
)
AddRecipe2(
    "bathat", 
    {
        Ingredient("pigskin", 2),Ingredient("batwing", 1),Ingredient("compass", 1)
    }, 
    TECH.SCIENCE_TWO,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "LIGHT","RAIN","CLOTHING"  }
)
--生存-------------------------------------------------------------------------------------------------
AddRecipe2(
    "bugrepellent", 
    {
        Ingredient("tuber_crop", 6) ,Ingredient("venus_stalk", 1)
    }, 
    TECH.SCIENCE_ONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "WEAPONS","TOOLS" }
)
AddRecipe2(
    "antler", 
    {
        Ingredient("hippo_antler", 1),Ingredient("bill_quill", 3),Ingredient("flint", 1)
    }, 
    TECH.SCIENCE_ONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "TOOLS" }
)
--寻宝---------------------------------------------------------------------------------------
AddRecipe2(
    "disarming_kit", 
    {
        Ingredient("iron", 2), Ingredient("cutreeds", 2)
    }, 
    TECH.NONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "TOOLS" }
)
AddRecipe2(
    "ballpein_hammer", 
    {
        Ingredient("iron", 2), Ingredient("twigs", 1)
    }, 
    TECH.SCIENCE_ONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "TOOLS" }
)
AddRecipe2(
    "goldpan", 
    {
        Ingredient("iron", 2), Ingredient("hammer", 1)
    }, 
    TECH.SCIENCE_ONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "TOOLS" }
)
AddRecipe2(
    "magnifying_glass", 
    {
        Ingredient("iron", 1), Ingredient("twigs", 1), Ingredient("bluegem", 1)
    }, 
    TECH.SCIENCE_TWO,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "TOOLS" }
)
--食物---------------------------------------------------------------------------------------
AddRecipe2(
    "sprinkler", 
    {
        Ingredient("alloy", 2), Ingredient("bluegem", 1),Ingredient("ice", 6)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="sprinkler_placer",
    },
    { "STRUCTURES","GARDENING","SUMMER" }
)
--科学--------------------------------------------------------------------------------
AddRecipe2(
    "smelter", 
    {
        Ingredient("cutstone", 6), Ingredient("boards", 4), Ingredient("redgem", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="smelter_placer",
    },
    { "STRUCTURES","TOOLS" }--是热源吗？是的话把WINETER也加上
)
AddRecipe2(
    "basefan", 
    {
        Ingredient("alloy", 2), Ingredient("transistor", 2),Ingredient("gears", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="basefan_placer",
    },
    { "STRUCTURES","RESTORATION","RAIN" }--是冷源吗？是的话把SUMMER也加上
)
--战斗-----------------------------------------------------------------------------------------------
AddRecipe2(
    "halberd", 
    {
        Ingredient("alloy", 1), Ingredient("twigs", 2)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "WEAPONS","TOOLS" }
)
AddRecipe2(
    "cork_bat", 
    {
        Ingredient("cork", 3), Ingredient("boards", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "WEAPONS" }
)
AddRecipe2(
    "blunderbuss", 
    {
        Ingredient("boards", 2), Ingredient("oinc10", 1), Ingredient("gears", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "WEAPONS" }
)

AddRecipe2(
    "armor_weevole", 
    {
        Ingredient("weevole_carapace", 4), Ingredient("chitin", 2)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR","RAIN","CLOTHING"  }
)
AddRecipe2(
    "antmaskhat", 
    {
        Ingredient("chitin", 5),Ingredient("footballhat", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR","CLOTHING" }
)
AddRecipe2(
    "antsuit", 
    {
        Ingredient("chitin", 5),Ingredient("armorwood", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR","CLOTHING" }
)
AddRecipe2(
    "metalplatehat", 
    {
        Ingredient("alloy", 3),Ingredient("cork", 3)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR" }
)
AddRecipe2(
    "armor_metalplate", 
    {
        Ingredient("alloy", 3),Ingredient("hammer", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR" }
)
--建筑-----------------------------------------------------------------------------------
AddRecipe2(
    "corkchest", 
    {
        Ingredient("cork", 2), Ingredient("rope", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="corkchest_placer",
    },
    { "STRUCTURES","CONTAINERS" }
)
AddRecipe2(
    "turf_beard_hair", 
    {
        Ingredient("beardhair", 1), Ingredient("cutgrass", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "DECOR" }
)
AddRecipe2(
    "turf_lawn", 
    {
        Ingredient("cutgrass", 2), Ingredient("nitre", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "DECOR" }
)
AddRecipe2(
    "turf_fields", 
    {
        Ingredient("turf_rainforest", 1), Ingredient("ash", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "DECOR" }
)
AddRecipe2(
    "turf_deeprainforest_nocanopy", 
    {
        Ingredient("bramble_bulb", 1), Ingredient("cutgrass", 2), Ingredient("ash", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "DECOR","GARDENING" }
)
--精炼
AddRecipe2(
    "goldnugget", --"porkland_goldnugget"
    {
        Ingredient("gold_dust", 6)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "REFINE" }
)
AddRecipe2(
    "goldnugget", 
    {
        Ingredient("gold_dust", 6)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "REFINE" }
)
AddRecipe2(
    "venomgland", 
    {
        Ingredient("froglegs_poison", 3)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "REFINE","RESTORATION" }
)
AddRecipe2(
    "clawpalmtree_sapling", 
    {
        Ingredient("cork", 1), Ingredient("poop", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="clawpalmtree_sapling_placer",
    },
    { "REFINE","GARDENING" }--不确定放在耕作里合适不合适
)
--魔法！-------------------------------------------------------------------------------------------------------
AddRecipe2(
    "hogusporkusator", --石猪引擎
    {
        Ingredient("pigskin", 4), Ingredient("boards", 4), Ingredient("feather_robin_winter", 4)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="hogusporkusator_placer",
    },
    { "PROTOTYPERS","MAGIC","STRUCTURES" }
)
AddRecipe2(
    "bonestaff", --大蛇眼睛杖
    {
        Ingredient("pugalisk_skull", 1), Ingredient("boneshard", 1), Ingredient("nightmarefuel", 2)
    }, 
    TECH.MAGIC_THREE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
    },
    { "MAGIC","WEAPONS" }
)
AddRecipe2(
    "roottrunk_child", 
    {
        Ingredient("bramble_bulb", 1), Ingredient("venus_stalk", 2),Ingredient("boards", 3)
    }, 
    TECH.MAGIC_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="roottrunk_child_placer",
    },
    { "CONTAINERS","MAGIC","STRUCTURES" }
)
AddRecipe2(
    "armorvortexcloak", --漩涡斗篷
    {
        Ingredient("ancient_remnant", 5),Ingredient("armor_sanity", 1)
    }, 
    TECH.LOST,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR","MAGIC","CONTAINERS","CLOTHING"  }
)
AddRecipe2(
    "living_artifact", --机甲
    {
        Ingredient("infused_iron", 6),Ingredient("waterdrop", 1)
    }, 
    TECH.LOST,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "ARMOUR","MAGIC","WEAPONS","TOOLS"  }
)
AddRecipe2(
    "porkland_entrance", --天空之椅，不同于海难那个，只有一个prefab的制作配方，不知道是咋回事
    {
        Ingredient("nightmarefuel", 4), Ingredient("livinglog", 4), Ingredient("trinket_giftshop_4", 1)
    }, 
    TECH.MAGIC_THREE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="porkland_entrance_placer",
    },
    { "MAGIC","STRUCTURES" }
)
--衣服-----------------------------------------------------------------------------------------------------------------------
AddRecipe2(
    "snakeskinhat", --蛇皮帽
    {
        Ingredient("snakeskin", 1), Ingredient("strawhat", 1), Ingredient("boneshard", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "RAIN","CLOTHING"  }
)
AddRecipe2(
    "armor_snakeskin", --蛇皮衣
    {
        Ingredient("snakeskin", 2), Ingredient("vine", 2), Ingredient("boneshard", 2)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "RAIN","WINTER","CLOTHING"  }
)
AddRecipe2(
    "gasmaskhat", --防毒面具
    {
        Ingredient("peagawkfeather", 4), Ingredient("pigskin", 1), Ingredient("fabric", 1)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "RESTORATION","CLOTHING"  }
)
AddRecipe2(
    "pithhat", --软木帽
    {
        Ingredient("fabric", 1),Ingredient("vine", 3),Ingredient("cork", 6)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "RAIN","CLOTHING"  }--可以考虑加入隔热，那就要加summer分类
)
AddRecipe2(
    "thunderhat", --雷帽
    {
        Ingredient("feather_thunder", 1),Ingredient("goldnugget", 2),Ingredient("cork", 3)
    }, 
    TECH.SCIENCE_TWO,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        --placer="_placer",
    },
    { "CLOTHING"  }
)
--航海---------------------------------------------------------------------------------------------------
AddRecipe2(
    "corkboat" --软木舟
    {
        Ingredient("cork", 4), Ingredient("rope", 1)
    }, 
    TECH.SCIENCE_ONE,
    {   
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="", 
        placer="corkboat_placer",
    },
    { "SEAFARING"  }
)
--角色配方，是不是应该给薇勒尔的专属道具安排一下配方呢-----------------------------------------------------------------------------------------------------
--韦伯
Recipe2(
    "disguisehat", 
	{
        Ingredient("twigs", 2),  Ingredient("pigskin", 1), Ingredient("beardhair", 1)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="spiderwhisperer" ,
        --builder_tag={"spiderwhisperer","merm_builder"}--给沃特一个？
        --placer="_placer",
    },
    {"CLOTHING","CHARACTER"}
)
--沃姆伍德的药膏
Recipe2(
    "poisonbalm", 
	{
        Ingredient("livinglog", 1), Ingredient("venomgland", 1)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="plantkin" ,
        --placer="_placer,
    },
    {"RESTORATION","CHARACTER"}
)
--老瓦的眼镜
Recipe2(
    "gogglesnormalhat", --最简单的护目镜
	{
        Ingredient("goldnugget", 1),Ingredient("pigskin", 1)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected" ,
    },
    {"CLOTHING","CHARACTER"}
)
Recipe2(
    "gogglesheathat", --夜视
	{
        Ingredient("gogglesnormalhat", 1), Ingredient("transistor", 1), Ingredient("torch", 2)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected" ,
    },
    {"LIGHT","CHARACTER"}
)
Recipe2(
    "gogglesarmorhat", --面甲
	{
        Ingredient("gogglesnormalhat", 1), Ingredient("cutstone", 1)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected" ,
    },
    {"ARMOUR","CHARACTER"}
)
Recipe2(
    "gogglesshoothat", --电眼逼人
	{
        Ingredient("gogglesnormalhat", 1), Ingredient("redgem", 1)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected" ,
    },
    {"WEAPONS","CHARACTER"}
)
--传送底座和传送伞
Recipe2(
    "telebrella",
	{
        Ingredient("transistor", 1),Ingredient("grass_umbrella", 1)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected" ,
    },
    {"CHARACTER"}
)
Recipe2(
    "telipad",
	{
        Ingredient("gears", 1),Ingredient("transistor", 1),Ingredient("cutstone", 2)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected" ,
        placer="telipad_placer",
    },
    {"CHARACTER","STRUCTURES"}
)
--地震仪
Recipe2(
    "thumper",
	{
        Ingredient("gears", 1),Ingredient("transistor", 1),Ingredient("cutstone", 2)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        builder_tag="outofworldprojected",
        placer="thumper_placer",
    },
    {"STRUCTURES","TOOLS","CHARACTER"}
)
--继承自海难的配方-----------------------------------------------------------------------------------------------------------------
--两种砍刀
AddRecipe2(
    "machete", 
    {
        Ingredient("twigs", 1),Ingredient("flint", 3),
    }, 
    TECH.TECH.NONE,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        --placer="thumper_placer",
    },
    { "TOOLS" }
)
AddRecipe2(
    "goldenmachete", 
    {
        Ingredient("twigs", 4),Ingredient("goldnugget", 2),
    }, 
    TECH.SCIENCE_TWO,
    {    
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        --placer="thumper_placer",
    },
    { "TOOLS" }
)
--船和相关物品
Recipe2(
    "lograft",
	{
        Ingredient("log", 6), Ingredient("cutgrass", 4)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        placer="lograft_placer",
    },
    {"SEAFARING"}
)
Recipe2(
    "rowboat",
	{
        Ingredient("boards", 3), Ingredient("vine", 4)
    },
    TECH.SCIENCE_ONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        placer="rowboat_placer",
    },
    {"SEAFARING"}
)
Recipe2(
    "cargoboat",
	{
        Ingredient("boards", 6), Ingredient("rope", 3)
    },
    TECH.SCIENCE_TWO,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        placer="cargoboat_placer",
    },
    {"SEAFARING"}
)
Recipe2(
    "snakeskinsail",
	{
        Ingredient("log", 4), Ingredient("rope", 2), Ingredient("snakeskin", 2)
    },
    TECH.SCIENCE_TWO,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        --placer="thumper_placer",
    },
    {"SEAFARING"}
)
Recipe2(
    "boatrepairkit",
	{
        Ingredient("boards", 2), Ingredient("stinger", 2), Ingredient("rope", 2)
    },
    TECH.NONE,
    {
        --atlas = "",
        --image = "",
        --nounlock=,
        --numtogive= ,
        --builder_tag="" 
        --placer="thumper_placer",
    },
    {"SEAFARING"}
)