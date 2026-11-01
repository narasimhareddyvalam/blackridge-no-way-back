"""Apply Godot's 3D texture import settings to downloaded material textures.

Godot only switches a texture to 3D settings after the editor sees it used in a
3D material. Textures assigned from scripts stay lossless without mipmaps,
which shimmers at distance. This sets the same values as choosing
"VRAM Compressed", "Generate Mipmaps" and, for *_nor_gl_* files and the Mixamo
characters' *_Normal.webp files, "Normal Map: Enable" in the Import dock. Run Godot's
import afterwards.

Usage, from the repository root:
    python3 -I tools/assets/configure_imports.py game/features/environments/depot_yard
"""

import pathlib
import re
import sys

SETTINGS = {
    "compress/mode": "2",
    "mipmaps/generate": "true",
    "detect_3d/compress_to": "0",
}


def configure(path: pathlib.Path) -> bool:
    text = path.read_text()
    if 'importer="texture"' not in text:
        return False
    wanted = dict(SETTINGS)
    normal = "_nor_gl" in path.name or path.name.endswith("_Normal.webp.import")
    wanted["compress/normal_map"] = "1" if normal else "0"
    updated = text
    for key, value in wanted.items():
        updated = re.sub(rf"^{re.escape(key)}=.*$", f"{key}={value}", updated, flags=re.M)
    if updated == text:
        return False
    path.write_text(updated)
    return True


def main() -> None:
    root = pathlib.Path(sys.argv[1])
    imports = sorted(root.rglob("*.jpg.import")) + sorted(root.rglob("*.png.import"))
    imports += sorted(root.rglob("*.webp.import"))
    changed = [p for p in imports if configure(p)]
    print(f"Updated {len(changed)} texture import files under {root}")


if __name__ == "__main__":
    main()
