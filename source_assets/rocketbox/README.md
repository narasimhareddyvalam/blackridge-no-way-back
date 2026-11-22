# Rocketbox source files

The gate guard at Mission 2's transfer shed (decision C55) and bay 9's dock worker (C58) come
from the Microsoft Rocketbox avatar library, https://github.com/microsoft/Microsoft-Rocketbox,
released by Microsoft under the MIT licence (`LICENSE.md` beside this file). Claude Code
downloaded these files from the library's `master` branch on 2026-11-11, after the author chose
each from a render (the guard #197–#198, the dock worker #232–#235, the forklift driver
#303, fetched 2026-11-16; the warehouse compound's guard, fetched 2026-11-18 after the author
asked for another guard than the shed's, #315, without a render: she is the only other security
character the library has; the dock worker's walk start and stop, four turns and taking
documents, fetched 2026-11-19 at the author's word, #329; his crouching down and rising, to set
the seal log on the van's rear step, fetched 2026-11-19 after the author's "Yes, build it", #338),
and converts them into the game.

## Files

| File | From `Assets/` in the library | Size |
| --- | --- | ---: |
| `Security_Male_01/Export/Security_Male_01.fbx` | `Avatars/Professions/Security_Male_01/Export/` | 592,928 |
| `Security_Male_01/Textures/m171_{head,body,equipment}_{color,normal,specular}.tga` | `Avatars/Professions/Security_Male_01/Textures/` | 94 MB in all |
| `Animations/m_sit_chair_breathe_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 2,537,504 |
| `Construction_Male_08/Export/Construction_Male_08.fbx` | `Avatars/Professions/Construction_Male_08/Export/` | 584,816 |
| `Construction_Male_08/Textures/m108_{head,body,helmet}_{color,normal}.tga` | `Avatars/Professions/Construction_Male_08/Textures/` | 63 MB in all |
| `Construction_Male_07/Export/Construction_Male_07.fbx` | `Avatars/Professions/Construction_Male_07/Export/` | 566,144 |
| `Construction_Male_07/Textures/m107_{head,body,helmet}_{color,normal}.tga` | `Avatars/Professions/Construction_Male_07/Textures/` | 63 MB in all |
| `Animations/m_idle_neutral_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 2,418,544 |
| `Animations/m_walk_neutral_01.max.fbx` | `Animations/all_animations_max_motextr_xy/` | 994,336 |
| `Animations/m_try_door_outwards.max.fbx` | `Animations/all_animations_max_motextr_static/` | 1,972,496 |
| `Animations/m_sit_down_table_right.max.fbx` | `Animations/all_animations_max_motextr_xyz/` | 1,640,064 |
| `Animations/m_sit_stand_up_table_right.max.fbx` | `Animations/all_animations_max_motextr_xyz/` | 1,523,408 |
| `Animations/m_sit_table_idle_neutral_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 7,189,408 |
| `Animations/m_documents_check.max.fbx` | `Animations/all_animations_max_motextr_static/` | 3,057,824 |
| `Animations/m_documents_note.max.fbx` | `Animations/all_animations_max_motextr_static/` | 2,221,712 |
| `Security_Female_01/Export/Security_Female_01.fbx` | `Avatars/Professions/Security_Female_01/Export/` | 626,544 |
| `Security_Female_01/Textures/f170_{head,body,hat}_{color,normal}.tga` | `Avatars/Professions/Security_Female_01/Textures/` | 63 MB in all |
| `Animations/f_sit_chair_breathe_01.max.fbx` | `Animations/all_animations_max_motextr_static/` | 3,445,856 |
| `Animations/m_walk_start.max.fbx` | `Animations/all_animations_max_motextr_xy/` | 931,792 |
| `Animations/m_walk_stop.max.fbx` | `Animations/all_animations_max_motextr_xy/` | 1,209,760 |
| `Animations/m_turn_left_90.max.fbx` | `Animations/all_animations_max_motextr_xyz/` | 1,299,184 |
| `Animations/m_turn_left_180.max.fbx` | `Animations/all_animations_max_motextr_xyz/` | 1,325,984 |
| `Animations/m_turn_right_90.max.fbx` | `Animations/all_animations_max_motextr_xyz/` | 1,254,448 |
| `Animations/m_turn_right_180.max.fbx` | `Animations/all_animations_max_motextr_xyz/` | 1,308,256 |
| `Animations/m_documents_take.max.fbx` | `Animations/all_animations_max_motextr_static/` | 1,733,056 |
| `Animations/m_crouch_in.max.fbx` | `Animations/all_animations_max_motextr_xy/` | 1,634,800 |
| `Animations/m_crouch_out.max.fbx` | `Animations/all_animations_max_motextr_xy/` | 1,634,608 |

Each file is fetched from `https://raw.githubusercontent.com/microsoft/Microsoft-Rocketbox/master/Assets/`
followed by its path in the library. The character has 9,515 triangles and an 80-bone 3ds Max
Biped skeleton; the clip is 382 frames of a man breathing in a chair, its rest pose its own first
frame. The dock worker has 8,474 triangles on the same skeleton (81 joints in the converted file);
his clips are 351 frames of a standing idle, a 37-frame walk in place and 187 frames of a man
trying a door outwards, his reach to the van doors' hasp. On 2026-11-14 (step 3 of #253, part 2) his desk clips were added: sitting down to a table and
standing up from it (109 and 96 frames, their root motion on the armature object, Bip01), a
seated idle at a table (1,372 frames), checking a document (484) and noting in one (303). On
2026-11-19 (#338) his crouch and rise were added (136 frames each): a man stepping his left foot
ahead and crouching, his hips from 0.895 m to 0.41 m, and rising again; their motion is on the
armature object, so the converter keeps it (as for the desk clips) and starts the rise where the
crouch ends. His
specular maps are not downloaded:
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

## Maya and Lily (Mission 3's step 4, #359)

Downloaded 2026-11-21 by Claude Code at the author's word to finish Mission 3 (#359), from the
same library: `Female_Adult_07/` (Maya, in her late twenties to early thirties) and
`Female_Child_01/` (Lily, five), with the clips `f_idle_nervous_01`, `f_gestic_talk_sad_01`,
`f_gestic_talk_femalestressed_01`, `f_idle_breathe_01` and `f_walk_neutral_01` in `Animations/`.
`tools/art/convert_rocketbox.py`'s `maya` and `lily` jobs write
`game/features/characters/maya/maya.glb` and `game/features/characters/lily/lily.glb` (Lily
scaled to 1.12 m and her Bip02 bones renamed Bip01; `game/features/characters/ATTRIBUTION.md`).
- **Committed:** the two converted models and their textures; the downloads stay out of Git.

## Adrian (Mission 3's step 7, #359)

Downloaded 2026-11-22 by Claude Code, from the same library: `Business_Male_03/` (its
`Export/Business_Male_03.fbx` and its colour, normal and opacity textures, from
`Avatars/Professions/`), and the clips `m_idle_angry_01` and `m_gestic_talk_excited_01` (from
`Animations/all_animations_max_motextr_static/`) in `Animations/`. `tools/art/convert_rocketbox.py`'s
`adrian` job writes `game/features/characters/adrian/adrian.glb`.
- **Committed:** the converted model and its textures; the downloads stay out of Git.
