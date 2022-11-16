---@diagnostic disable: lowercase-global

local languages = {
    -- en = "strings.pot",
	de = "german",  -- german
	es = "spanish",  -- spanish
	fr = "french",  -- french
	it = "italian",  -- italian
	ko = "korean",  -- korean
	pt = "portuguese_br",  -- portuguese and brazilian portuguese
	pl = "polish",  -- polish
	ru = "russian",  -- russian
	["zh-CN"] = "chinese_s",  -- chinese
	["zh-TW"] = "chinese_t",  -- traditional chinese
}

ds_path = "F:/STEAM/steamapps/common/dont_starve"  -- don't dont_starve file path, need DLC003
string_key = {
    "asparagus_planted",
    "aloe","aloe_cooked","aloe_planted","aloe_seeds",
    "radish","radish_cooked","radish_planted","radish_seeds",
    "relic_1","relic_2","relic_3","relic_4","relic_5",
    "pig_ruins_head","pig_ruins_idol","pig_ruins_pig","pig_ruins_plaque",
    "basefan"
} -- need add string's prefab


new_strings = {
    language = "zh-CN",  -- look languages's key
    CHARACTERS = {
        WINONA = {
            DESCRIBE = {
                ASPARAGUS_PLANTED = "有益健康的绿色蔬菜。",

                ALOE = "吃下它会好吗？", --"Is it health benefits?"
                ALOE_COOKED = "应该不会有问题，尝试一下吧。",
                ALOE_PLANTED = "一株奇怪的植物。",--"A weird plant."
                ALOE_SEEDS = "一把种子。", --"A handful of seeds."

                RADISH = "非常火辣的萝卜。",
                RADISH_COOKED = "粗糙的加工适得其反。",
                RADISH_PLANTED = "欢迎来拔。", --"Perfectly pluckable."
                RADISH_SEEDS = "一把种子。", --"A handful of seeds."

                RELIC_1 = "会有有钱人想要这个的。",
                PIG_RUINS_IDOL = "一定有什么办法把上面那部分卸下来。",

                RELIC_2 = "我猜它会有一些文化价值。",
                PIG_RUINS_PLAQUE = "一定有什么办法把上面那部分卸下来。",

                RELIC_3 = "终究是文物，没准猪人会想要。",
                PIG_RUINS_HEAD = "一定有什么办法把中间那部分卸下来。",

                RELIC_4 = "这个看起来不太一样，也许她很特殊。",
                RELIC_5 = "镶嵌了许多宝石，一定很值钱。", 

                PIG_RUINS_PIG = "未免太过于张扬了。",

                BASEFAN = "老板一定会感兴趣的。", --"I'm sure bossman would be very interested in it."
            },
        },
        WORTOX = {
            DESCRIBE = {
                ASPARAGUS_PLANTED = "从土里长出的长矛。",

                ALOE = "可以内服也可以外敷，我选择外敷。",
                ALOE_COOKED = "对凡人们脆弱的身体有好处。",
                ALOE_PLANTED = "是芦荟，凡人的食物。",
                ALOE_SEEDS = "真是奇怪的小种子啊。", --"Strange little seeds, indeed, indeed."

                RADISH = "有点辣。",
                RADISH_COOKED = "辣死了辣死了。",
                RADISH_PLANTED = "",
                RADISH_SEEDS = "春种一粒粟，秋收万颗子！", --"Grow a seed and you shall feed!"

                RELIC_1 = "古代的小雕像，拿来装饰吧。",
                PIG_RUINS_IDOL = "上面的小雕像不错啊，我们把它拿走吧。",

                RELIC_2 = "我看看...“问号，流星，松树。”哈哈，开玩笑的。"--"Let me see...\"Question mark, shooting star, pine tree.\"Haha, just kidding"
                PIG_RUINS_PLAQUE = "嘿！小树，猜猜这上面写的是什么？",--"Hey little tree,guess what this says?"

                RELIC_3 = "大猪头的大鼻头。",
                PIG_RUINS_HEAD = "别人有伞，它有大头！", 

                RELIC_4 = "看上去就非常皇家。", --"It looks very royal."
                RELIC_5 = "很多宝石，但没有魔法。",

                PIG_RUINS_PIG = "笑口常开啊。",

                BASEFAN = "微风拂面，好不快活。",
            },
        },
        WURT = {
            DESCRIBE = {
                ASPARAGUS_PLANTED = "绿棒棒，闻起来不错。", --"Green sticks, can be a snack."

                ALOE = "又甜又黏。",
                ALOE_COOKED = "但这尝起来不像药啊，薇克巴顿女士。",--"But it don't taste like medicine. Ms. Wickerbottom"
                ALOE_PLANTED = "格，没见过的小吃", --"Grrr, snack never seen."
                ALOE_SEEDS = "能长出更多的小吃，浮浪噗！",--"Make more snacks, florp!"

                RADISH = "辛辣的根！",--"Hot spicy root!"
                RADISH_COOKED = "没有比原本更好。",--"Not better than it was."
                RADISH_PLANTED = "格，没见过的小吃", --"Grrr, snack never seen."
                RADISH_SEEDS = "能长出更多的小吃，浮浪噗！",--"Make more snacks, florp!"

                RELIC_1 = "猪人给我钱换它们自己的东西，好！",--"Pigfolk pay me for their own stuff. Good!"
                PIG_RUINS_IDOL = "一个猪人像，而不是鱼人。", --"A pigfolk idol, not mermfolk."

                RELIC_2 = "猪人给我钱换它们自己的东西，好！",--"Pigfolk pay me for their own stuff. Good!"
                PIG_RUINS_PLAQUE = "这也是猪人造的吗？", --"Created by pigfolk too?"

                RELIC_3 = "战利品！",
                PIG_RUINS_HEAD = "巨大的猪人脸。", --"Giant pifrolk face!"

                RELIC_4 = "一个不一样的猪人，为什么？", --"A different pigfolk, why?"
                RELIC_5 = "不能吃，但闪闪发光。", 

                PIG_RUINS_PIG = "看我把猪人的牙齿拿走！", --"I pull out the pigfolk's teeth!"

                BASEFAN = "水都跑掉了！浮浪噗的！", --"Water ran away! florpt!"
            },
        },
        WALTER = {
            DESCRIBE = {
                ASPARAGUS_PLANTED = "薇诺娜小姐可能会喜欢，摘一点吧。",

                ALOE = "芦荟的用途也包括食用。",
                ALOE_COOKED = "这样应该会更美味。",
                ALOE_PLANTED = "我认识这个！是芦荟！有很多好用途。",
                ALOE_SEEDS = "沃比，你看有什么好地方可以种这个吗？", --"Woby, do you see a good spot to plant these?"

                RADISH = "这种萝卜有可能会变成老鼠吗？",
                RADISH_COOKED = "对。这是做熟的水萝卜。",
                RADISH_PLANTED = "现在我们有更多的水萝卜了。耶。",
                RADISH_SEEDS = "沃比，你看有什么好地方可以种这个吗？", --"Woby, do you see a good spot to plant these?"

                RELIC_1 = "一尊小小的猪人像。",
                PIG_RUINS_IDOL = "看看我们发现了什么，沃比！", 

                RELIC_2 = "你觉得它们会写什么呢？沃比？",
                PIG_RUINS_PLAQUE = "是一个图腾！",

                RELIC_3 = "一个巨大的鼻子。",
                PIG_RUINS_HEAD = "沃比！它比你还要大！", 

                RELIC_4 = "非常有皇家风范。", 
                RELIC_5 = "看起来很宝贵。", 

                PIG_RUINS_PIG = "看它笑得多开心啊！",

                BASEFAN = "啊，真舒服，沃比你也来吹吹。",
            },
        },
        WANDA = {
            DESCRIBE = {
                ASPARAGUS_PLANTED = "我应该摘点回去吃。",

                ALOE = "这可是好东西。",
                ALOE_COOKED = "趁热吃吧。",
                ALOE_PLANTED = "我们摘走它吧，这可能是最后一个了。",
                ALOE_SEEDS = "既然现在就能吃，为什么还要浪费时间种呢？",--"Why waste time growing them when I can just eat them now?"

                RADISH = "这绝对是萝卜。", --"I Said. It must be a turnip."
                RADISH_COOKED = "搞定了，希望它值得。",
                RADISH_PLANTED = "这肯定是萝卜了，我不会认错。", --"It's a turnip. I can't be wrong,"
                RADISH_SEEDS = "既然现在就能吃，为什么还要浪费时间种呢？",--"Why waste time growing them when I can just eat them now?"

                RELIC_1 = "并不是谁都能跨越漫长的时间。",
                PIG_RUINS_IDOL = "我还以为会更深...噢，那是另一个。", 

                RELIC_2 = "想必是古代猪人的手笔。",
                PIG_RUINS_PLAQUE = "我很好奇它有什么含义，但还是算了吧。",

                RELIC_3 = "大石脸的鼻子。",
                PIG_RUINS_HEAD = "巨大的石头猪脸。",

                RELIC_4 = "我们快去领赏吧。",
                RELIC_5 = "就是它，我能用它换取丰厚的奖励。",

                PIG_RUINS_PIG = "它在笑什么？",

                BASEFAN = "非常有趣的结构，可惜还不够精细。",
            },
        },
    }
}

override = false
