# Roadside trees: attribution

The forest highway's Pacific Northwest roadside trees (#280, decision C63).

- `mountain_hemlock.glb`: "Realistic HD Mountain hemlock (21/43)" by PlantCatalog,
  https://sketchfab.com/models/225cd2dfbf7d4163bc3a062a0c0623aa, licensed CC BY 4.0
  (https://creativecommons.org/licenses/by/4.0/). Changed by
  `tools/art/convert_roadside_trees.py`: its foliage's alpha cut, its textures at most 2048
  pixels as WebP, and a far version added (`MountainHemlockFar`: a quarter of its foliage cards,
  grown 1.6 times, its wood decimated to 15%). Credited in the game's credits ("THE ROADSIDE
  TREES").
- `young_firs.glb`: "Realistic fir trees pack (LODS, gameready)" by lolipop_1707,
  https://sketchfab.com/models/f58e8b6d733e4b0586e5b7db847b89e7, licensed CC BY 4.0. Changed by
  the same script: four of its trees (Large tree 1-3, Medium tree 1, their most detailed meshes)
  kept, made matte, their alpha cut, textures as WebP, each given a far version. Credited there.
- `western_red_cedar.glb`: "Western Red Cedar *Inspired* Tree - WINTER Ver." by SirSonat,
  https://sketchfab.com/models/fdd3274350144d8abe119d8a73cdce34, licensed CC BY 4.0. Changed by
  the same script: its mushrooms left out, stood on the ground where they stood, 24 m tall above
  it and narrowed to 60% across (a second-growth cedar's girth), its alpha cut, textures as WebP,
  a far version added. Credited there.
- `red_alder.glb`: built for this game by `tools/art/build_red_alder.py` (three bare red alders
  and their far versions), barked with `red_alder_bark_diff.jpg`, made by
  `tools/art/make_alder_bark.py` from Poly Haven's "Chinese Hackberry Bark" by Charlotte
  Baglioni (CC0), turned grey; its normal map is that texture's own.
