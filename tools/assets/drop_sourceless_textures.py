"""Remove the textures a glTF binary names without an image, and every material slot that uses
them (#359). Blender's exporter writes such textures when it cannot read a packed image's pixels
to merge it into a metallic-roughness map (the harbour crane's), and Godot then refuses the file.
The slot falls back to the material's own factors.

Usage, from the repository root:
    python3 -I tools/assets/drop_sourceless_textures.py <file.glb>
"""

import json
import pathlib
import struct
import sys


def _uses(node):
    if isinstance(node, dict):
        for key, value in node.items():
            yield node, key, value
            yield from _uses(value)
    elif isinstance(node, list):
        for item in node:
            yield from _uses(item)


def main(path):
    data = path.read_bytes()
    length = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + length])
    rest = data[20 + length:]
    textures = gltf.get("textures", [])
    bad = {index for index, texture in enumerate(textures) if "source" not in texture
           and "source" not in texture.get("extensions", {}).get("EXT_texture_webp", {})}
    if not bad:
        print(f"{path}: every texture has its image")
        return
    renumber = {}
    kept = []
    for index, texture in enumerate(textures):
        if index not in bad:
            renumber[index] = len(kept)
            kept.append(texture)
    gltf["textures"] = kept
    for material in gltf.get("materials", []):
        for holder, key, value in list(_uses(material)):
            if isinstance(value, dict) and "index" in value and key.endswith("Texture"):
                if value["index"] in bad:
                    del holder[key]
                else:
                    value["index"] = renumber[value["index"]]
    text = json.dumps(gltf, separators=(",", ":")).encode()
    text += b" " * ((4 - len(text) % 4) % 4)
    body = struct.pack("<I", len(text)) + b"JSON" + text + rest
    path.write_bytes(data[:8] + struct.pack("<I", 12 + len(body)) + body)
    print(f"{path}: dropped {len(bad)} sourceless textures")


main(pathlib.Path(sys.argv[1]))
