# Welcome to Pork Land contributing guide

Thank you for looking at contributing to this project and the time and effort you might be spending on it

Currently, bug fixes are always welcome, but if you're trying to add in a specific feature or change a behavior, please make sure to contact us through GitHub issues or other methods first to discuss about the design, since we don't want to turn down your Pull Requests

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
