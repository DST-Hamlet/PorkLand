local DecoCreator = require("prefabs/deco_util")

return  DecoCreator:Create("deco_table_crate",    "interior_table", "interior_table", "table_crate",  {physics="post_physics", tags={"furniture", "rotatableobject"}, onbuilt = true }),
        DecoCreator:Create("deco_table_raw",      "interior_table", "interior_table", "table_raw",    {physics="post_physics", tags={"furniture", "rotatableobject"}, onbuilt = true }),
        DecoCreator:Create("deco_table_diy",      "interior_table", "interior_table", "table_diy",    {physics="post_physics", tags={"furniture", "rotatableobject"}, onbuilt = true }),
        DecoCreator:Create("deco_table_round",    "interior_table", "interior_table", "table_round",  {physics="post_physics", tags={"furniture", "rotatableobject"}, onbuilt = true }),
        DecoCreator:Create("deco_table_banker",   "interior_table", "interior_table", "table_banker", {physics="sofa_physics", tags={"furniture", "rotatableobject"}, onbuilt = true }),
        DecoCreator:Create("deco_table_chess",    "interior_table", "interior_table", "table_chess",  {physics="sofa_physics", tags={"furniture", "rotatableobject"}, onbuilt = true })
