from lupa import LuaRuntime  # lupa(pip install lupa)
from pygtrans import Translate  # pygtrans(pip install pygtrans)
lua = LuaRuntime()
translator = Translate().translate

def lua_translator(text, source, target):  # for lua
    if len(text) > 1 and text[1] == "\"" and text[-1] == "\"":
        text = text[2: -1]  # delete the first and last "

    return translator(text, source=source, target=target, fmt="text").translatedText


lua_file = open("./merge.lua", "r", encoding="UTF-8")
lua.execute(lua_file.read())
