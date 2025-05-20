import re
from collections import defaultdict

def find_duplicate_keys(lua_file_path):
    # 读取Lua文件内容
    with open(lua_file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # 使用正则表达式匹配所有key
    # 匹配类似 ANNOUNCE_GNATS_DIED= 或 BUILD = 这样的key
    pattern = r'^\s*([A-Z0-9_]+)\s*=|^\s*([A-Z0-9_]+)\s*=\s*\{'
    keys = []
    
    for line in content.split('\n'):
        match = re.search(pattern, line)
        if match:
            # 获取匹配的key（可能是第一个或第二个捕获组）
            key = match.group(1) if match.group(1) else match.group(2)
            keys.append(key)

    # 找出重复的key
    key_counts = defaultdict(int)
    for key in keys:
        key_counts[key] += 1

    duplicates = {key: count for key, count in key_counts.items() if count > 1}

    return duplicates

# 使用示例
if __name__ == "__main__":
    duplicates = find_duplicate_keys("wagstaff.lua")
    if duplicates:
        print("发现重复的key:")
        for key, count in duplicates.items():
            print(f"{key}: 出现 {count} 次")
    else:
        print("没有发现重复的key")