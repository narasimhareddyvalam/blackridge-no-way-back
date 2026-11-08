# Mixamo source files

Characters and animations from Adobe Mixamo (https://www.mixamo.com) for Mission 1's start
on foot and the collision (decision C27). The author downloaded them with their Adobe
account on 2026-10-31 and saved them here under Mixamo's own names. Claude Code converts
them into the game and credits them in `SOURCES.md`.

## Files

Every file is FBX Binary, "With Skin", 30 fps, about 55 MB, because each one carries the
character's 4K textures. The walk and run clips keep their forward motion ("In Place" was
not ticked); the converter takes it out.

| File | Character | Frames | Game clip |
| --- | --- | --- | --- |
| `Breathing Idle.fbx` | Ch33, Ethan (C28) | 299 | Ethan `Idle` (looping) |
| `Walking.fbx` | Ch33 | 32 | Ethan `Walk` (looping); also the pedestrian's `Walk` |
| `Walking Backwards.fbx` | Ch33 | 46 | Ethan `WalkBack` (looping) |
| `Running.fbx` | Ch33 | 22 | Ethan `Run` (looping) |
| `Entering Car.fbx` | Ch33 | 165 | Ethan `EnterVan` |
| `Exiting Car.fbx` | Ch33 | 175 | Ethan `ExitVan` |
| `Hit By Car.fbx` | Ch01, the pedestrian | 146 | pedestrian `HitByVan` |

## Converting

From the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
    --python tools/art/convert_mixamo.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
python3 -I tools/assets/configure_imports.py game/features/characters
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
```

This writes `game/features/characters/ethan/ethan.glb` and
`game/features/characters/pedestrian/pedestrian.glb`. Godot's import pulls each file's
textures out next to it as WebP. The converter's header lists what it changes.

## Licence

Mixamo content is free to use in games, including games that are sold, under Adobe's
terms. Those terms do not allow sharing the files on their own.

- **Kept out of Git:** the downloads in this folder (`.gitignore`), which are too large
  for the repository at about 55 MB each.
- **Committed:** the converted `.glb` files and their textures, so that a clean clone of
  the game runs. The author accepted on 2026-10-31 that the public repository makes them
  downloadable, as an exception to C10 (decision C27).

Credit: Adobe Mixamo.
