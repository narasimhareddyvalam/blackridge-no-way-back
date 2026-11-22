# Step 7 logs (Assignment 7)

`enter_van_r0.log` is the per-frame log of the EnterVan strip r0 (`captures/enter_van/r0/`),
printed by `tools/captures/capture_enter_van_strip.gd` during a windowed Movie Maker run. The
movie's full PNG sequence went to Claude Code's scratch folder; only the frames read are in the
repository. Run from `game/`:

```sh
HOME=../.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --path . \
    --resolution 1280x800 --write-movie <scratch>/frame.png --fixed-fps 30 \
    -s ../tools/captures/capture_enter_van_strip.gd
```
