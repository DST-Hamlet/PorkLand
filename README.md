Copyright 2025 [亚丹]。此产品不授权在 Steam 上发布，除非在 Steam 帐户 oldhunter101 下

# Pork Land

Bring Hamlet DLC from Don't Starve to Don't Starve Together

## To Clone

We're running out of quota for GitHub's Git Large File Storage, so LFS won't work, you need to set `GIT_LFS_SKIP_SMUDGE` to 1 to skip it for clone to work

With PowerShell

```powershell
$env:GIT_LFS_SKIP_SMUDGE=1
```

With Command Prompt

```cmd
set GIT_LFS_SKIP_SMUDGE=1
```

With Bash

```bash
GIT_LFS_SKIP_SMUDGE=1
```

After `git clone`, you'll need to copy the missing sound files from Don't Starve's folder (for example `C:/Program Files (x86)/Steam/steamapps/common/dont_starve/data/DLC0003/sound/`) manually, currently you need

- `dont_starve/data/DLC0003/sound/DLC003_AMB_stream.fsb`
- `dont_starve/data/DLC0003/sound/DLC003_music_stream.fsb`
- `dont_starve/data/DLC0003/sound/DLC003_sfx.fsb`
