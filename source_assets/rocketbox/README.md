# Rocketbox source files

The gate guard at Mission 2's transfer shed (decision C55) and bay 9's dock worker (C58) come
from the Microsoft Rocketbox avatar library, https://github.com/microsoft/Microsoft-Rocketbox,
released by Microsoft under the MIT licence (`LICENSE.md` beside this file). Claude Code
downloaded these files from the library's `master` branch on 2026-11-11, after the author chose
each from a render (the guard #197–#198, the dock worker #232–#235), and converts them into the
game.

## Files

| File | From `Assets/` in the library | Size |
| --- | --- | ---: |
| `Security_Male_01/Export/Security_Male_01.fbx` | `Avatars/Professions/Security_Male_01/Export/` | 592,928 |
| `Security_Male_01/Textures/m171_{head,body,equipment}_{color,normal,specular}.tga` | `Avatars/Professions/Security_Male_01/Textures/` | 94 MB in all |
| `Animations/m_sit_chair_breathe_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 2,537,504 |
| `Construction_Male_08/Export/Construction_Male_08.fbx` | `Avatars/Professions/Construction_Male_08/Export/` | 584,816 |
| `Construction_Male_08/Textures/m108_{head,body,helmet}_{color,normal}.tga` | `Avatars/Professions/Construction_Male_08/Textures/` | 63 MB in all |
| `Animations/m_idle_neutral_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 2,418,544 |
| `Animations/m_walk_neutral_01.max.fbx` | `Animations/all_animations_max_motextr_xy/` | 994,336 |
| `Animations/m_try_door_outwards.max.fbx` | `Animations/all_animations_max_motextr_static/` | 1,972,496 |

Each file is fetched from `https://raw.githubusercontent.com/microsoft/Microsoft-Rocketbox/master/Assets/`
followed by its path in the library. The character has 9,515 triangles and an 80-bone 3ds Max
Biped skeleton; the clip is 382 frames of a man breathing in a chair, its rest pose its own first
frame. The dock worker has 8,474 triangles on the same skeleton (81 joints in the converted file);
his clips are 351 frames of a standing idle, a 37-frame walk in place and 187 frames of a man
trying a door outwards, his reach to the van doors' hasp. His specular maps are not downloaded:
the converter does not use them.

## Converting

From the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \
    --python tools/art/convert_rocketbox.py
HOME="$PWD/.scratch-home" /Applications/Godot.app/Contents/MacOS/Godot --headless --editor \
    --path game --import
python3 -I tools/assets/configure_imports.py game/features/characters/guard
python3 -I tools/assets/configure_imports.py game/features/characters/dock_worker
HOME="$PWD/.scratch-home" /Applications/Godot.app/Contents/MacOS/Godot --headless --editor \
    --path game --import
```

This writes `game/features/characters/guard/guard.glb` and
`game/features/characters/dock_worker/dock_worker.glb` (`-- guard` or `-- dock_worker` after the
script converts one alone); Godot's import pulls their textures out next to them as WebP. The
converter's header lists what it changes. Restructured into these two jobs on 2026-11-11, it
writes `guard.glb` byte for byte as before (the same SHA-256).

## Licence

MIT, copyright (c) 2020 Microsoft: free for any use, including a game that is sold, if the
copyright and licence notice go with the files. The in-game credits and `SOURCES.md` carry it.

- **Kept out of Git:** the downloads in this folder (`.gitignore`), 159 MB with the TGA textures.
- **Committed:** this README, `LICENSE.md`, and the converted `guard.glb` and `dock_worker.glb`
  with their textures.
