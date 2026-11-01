"""Download CC0 Poly Haven assets into a Godot feature folder.

Each file is checked against the MD5 published by the Poly Haven API. Existing
files with a matching checksum are skipped, so reruns never overwrite edits made
to other files. A Markdown provenance manifest is written beside the assets.

"maps" downloads single texture maps of an asset (for example a model's twig
atlas), named in "map_names", as JPEG files.

Usage, from the repository root:
    python3 -I tools/assets/fetch_polyhaven.py tools/assets/depot_yard_assets.json
"""

import hashlib
import json
import pathlib
import sys
import urllib.request
from collections.abc import Callable

API = "https://api.polyhaven.com"
HEADERS = {"User-Agent": "BlackridgeNoWayBack-asset-fetch/1.0"}
TEXTURE_MAPS = {"diff": "Diffuse", "nor_gl": "nor_gl", "arm": "arm"}


def fetch_json(url: str) -> dict:
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def md5_of(path: pathlib.Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def download(url: str, md5: str, target: pathlib.Path) -> int:
    if target.exists() and md5_of(target) == md5:
        return target.stat().st_size
    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_suffix(target.suffix + ".part")
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=300) as response:
        partial.write_bytes(response.read())
    if md5_of(partial) != md5:
        partial.unlink()
        raise RuntimeError(f"Checksum mismatch for {url}")
    partial.replace(target)
    return target.stat().st_size


def model_files(asset: str, files: dict, resolution: str) -> list:
    entry = files["gltf"][resolution]["gltf"]
    result = [(entry["url"], entry["md5"], f"{asset}.gltf")]
    for relative, data in entry.get("include", {}).items():
        result.append((data["url"], data["md5"], relative))
    return result


def texture_files(asset: str, files: dict, resolution: str) -> list:
    result = []
    for short, key in TEXTURE_MAPS.items():
        data = files[key][resolution]["jpg"]
        result.append((data["url"], data["md5"], f"{asset}_{short}_{resolution}.jpg"))
    return result


def map_files(names: list) -> Callable[[str, dict, str], list]:
    def build(asset: str, files: dict, resolution: str) -> list:
        result = []
        for name in names:
            data = files[name][resolution]["jpg"]
            result.append((data["url"], data["md5"], f"{asset}_{name}_{resolution}.jpg"))
        return result
    return build


def hdri_files(asset: str, files: dict, resolution: str) -> list:
    data = files["hdri"][resolution]["hdr"]
    return [(data["url"], data["md5"], f"{asset}_{resolution}.hdr")]


def main() -> None:
    config_path = pathlib.Path(sys.argv[1])
    config = json.loads(config_path.read_text())
    root = pathlib.Path(config["destination"])
    builders = {"models": model_files, "textures": texture_files, "hdris": hdri_files,
                "maps": map_files(config.get("map_names", []))}
    rows = []
    for kind, builder in builders.items():
        for asset, resolution in config.get(kind, {}).items():
            info = fetch_json(f"{API}/info/{asset}")
            files = fetch_json(f"{API}/files/{asset}")
            total = 0
            for url, md5, relative in builder(asset, files, resolution):
                total += download(url, md5, root / kind / asset / relative)
            authors = ", ".join(info.get("authors", {}).keys())
            rows.append((kind, asset, info.get("name", asset), resolution, authors, total))
            print(f"{kind:9} {asset:32} {resolution:3} {total / 1e6:7.2f} MB")
    lines = [
        "# Poly Haven assets",
        "",
        "Downloaded by `tools/assets/fetch_polyhaven.py` from the Poly Haven API.",
        "All Poly Haven assets are CC0 (public domain): https://polyhaven.com/license",
        "Attribution is not required; authors are recorded for credits.",
        "",
        "| Type | Asset | Name | Resolution | Authors | Bytes |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for kind, asset, name, resolution, authors, total in rows:
        link = f"[{asset}](https://polyhaven.com/a/{asset})"
        lines.append(f"| {kind} | {link} | {name} | {resolution} | {authors} | {total} |")
    (root / "POLYHAVEN.md").write_text("\n".join(lines) + "\n")
    print(f"Total {sum(row[5] for row in rows) / 1e6:.1f} MB in {root}")


if __name__ == "__main__":
    main()
