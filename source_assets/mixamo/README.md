# Mixamo source files

Characters and animations from Adobe Mixamo (https://www.mixamo.com) for Mission 1's start
on foot and the collision (decision C27), and for Ethan's push behind bay 9's pallet jack in
Mission 2 (step 2e, #238-#240). The author downloaded them with their Adobe account, the
first seven on 2026-10-31, three more on 2026-11-12 and the two pistol clips on 2026-11-22, and saved them under Mixamo's own
names; Claude Code moved the last three here from the author's Downloads folder at their
word (#239). Claude Code converts them into the game and credits them in `SOURCES.md`.

## Files

Every file is FBX Binary, "With Skin", 30 fps, about 55 MB, because each one carries the
character's 4K textures. The walk, run and push clips keep their forward motion ("In Place"
was not ticked); the converter takes it out, and prints what the game moves Ethan instead.

| File | Character | Frames | Game clip |
| --- | --- | --- | --- |
| `Breathing Idle.fbx` | Ch33, Ethan (C28) | 299 | Ethan `Idle` (looping) |
| `Walking.fbx` | Ch33 | 32 | Ethan `Walk` (looping); also the pedestrian's `Walk` |
| `Walking Backwards.fbx` | Ch33 | 46 | Ethan `WalkBack` (looping) |
| `Running.fbx` | Ch33 | 22 | Ethan `Run` (looping) |
| `Entering Car.fbx` | Ch33 | 165 | Ethan `EnterVan` |
| `Exiting Car.fbx` | Ch33 | 175 | Ethan `ExitVan` |
| `Hit By Car.fbx` | Ch01, the pedestrian | 146 | pedestrian `HitByVan` |
| `Pushing.fbx` | Ch33 | 81 | Ethan `Push` (looping): 0.377 m/s, a 2.67 s stride |
| `Push Stop.fbx` | Ch33 | 79 | Ethan `PushStop`: three more steps, 0.756 m, then he stands |
| `Crouch Walk Forward.fbx` | Ch33 | 35 | not used (below) |
| `Pistol Idle.fbx` | Ch33 | 250 | Ethan `PistolIdle` (looping), upper body only (Assignment 7, #389) |
| `Reloading.fbx` | Ch33 | 100 | Ethan `PistolReload`, upper body only; its first frame is `PistolAim` (Assignment 7, #389) |

`Crouch Walk Forward.fbx` is kept but not converted: its arms are flung out, the left
forward and the right up by his head, so they would leave the jack's handle, and it walks at
1.69 m/s, more than four times the pace in the van's hold. Pushing's own lean already keeps
his head 1.41 m up at most, under the low-roof Daily's 1.45 m rear door (#239).

## Converting

From the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
    --python tools/art/convert_mixamo.py
# or, to rebuild Ethan alone and leave the pedestrian's file as it is:
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
    --python tools/art/convert_mixamo.py -- ethan
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
python3 -I tools/assets/configure_imports.py game/features/characters
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
```

This writes `game/features/characters/ethan/ethan.glb` and
`game/features/characters/pedestrian/pedestrian.glb`. Godot's import pulls each file's
textures out next to it as WebP. The converter's header lists what it changes. Push Stop's
travel, which it takes out at every sixth frame, is `STOP_TRAVEL` in
`game/features/characters/driver/push_gait.gd`; the two must match, or his planted feet
slide (`game/tests/test_loading.gd` reads his feet).

## Licence

Mixamo content is free to use in games, including games that are sold, under Adobe's
terms. Those terms do not allow sharing the files on their own.

- **Kept out of Git:** the downloads in this folder (`.gitignore`), which are too large
  for the repository at about 55 MB each.
- **Committed:** the converted `.glb` files and their textures, so that a clean clone of
  the game runs. The author accepted on 2026-10-31 that the public repository makes them
  downloadable, as an exception to C10 (decision C27).

Credit: Adobe Mixamo.
