# Rocketbox source files

The gate guard at Mission 2's transfer shed (decision C55) comes from the Microsoft Rocketbox
avatar library, https://github.com/microsoft/Microsoft-Rocketbox, released by Microsoft under
the MIT licence (`LICENSE.md` beside this file). Claude Code downloaded these files from the
library's `master` branch on 2026-11-11, after the author chose the guard from a render (#197–#198),
and converts them into the game.

## Files

| File | From `Assets/` in the library | Size |
| --- | --- | ---: |
| `Security_Male_01/Export/Security_Male_01.fbx` | `Avatars/Professions/Security_Male_01/Export/` | 592,928 |
| `Security_Male_01/Textures/m171_{head,body,equipment}_{color,normal,specular}.tga` | `Avatars/Professions/Security_Male_01/Textures/` | 94 MB in all |
| `Animations/m_sit_chair_breathe_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 2,537,504 |

Each file is fetched from `https://raw.githubusercontent.com/microsoft/Microsoft-Rocketbox/master/Assets/`
followed by its path in the library. The character has 9,515 triangles and an 80-bone 3ds Max
Biped skeleton; the clip is 382 frames of a man breathing in a chair, its rest pose its own first
frame.

## Converting

From the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \
    --python tools/art/convert_rocketbox.py
HOME="$PWD/.scratch-home" /Applications/Godot.app/Contents/MacOS/Godot --headless --editor \
    --path game --import
python3 -I tools/assets/configure_imports.py game/features/characters/guard
HOME="$PWD/.scratch-home" /Applications/Godot.app/Contents/MacOS/Godot --headless --editor \
    --path game --import
```

This writes `game/features/characters/guard/guard.glb`; Godot's import pulls its textures out
next to it as WebP. The converter's header lists what it changes.

## Licence

MIT, copyright (c) 2020 Microsoft: free for any use, including a game that is sold, if the
copyright and licence notice go with the files. The in-game credits and `SOURCES.md` carry it.

- **Kept out of Git:** the downloads in this folder (`.gitignore`), 108 MB with the TGA textures.
- **Committed:** this README, `LICENSE.md`, and the converted `guard.glb` with its textures.
