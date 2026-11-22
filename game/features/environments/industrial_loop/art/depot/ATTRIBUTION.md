# The bigger depot's art: attribution

- `dock_door.glb`: "Industrial Overhead Door" by Maxwell autodoors (Sketchfab `maihupronoob`),
  https://sketchfab.com/3d-models/industrial-overhead-door-20ced63367824ec1a2ada0fbf118b413,
  licensed CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Changed: its red wall, its
  trim and its overhead tracks and springs removed, its panel scaled to the 2.74 x 3.05 m opening
  and reduced to 5,341 triangles by `tools/art/convert_depot_models.py`. Credited in the game's
  credits ("THE DEPOT").
- `dock_seal.glb`: "Foam Pad Dock Seal" and `dock_leveller.glb`: "DLHH Electrohydraulic Dock
  Leveler", both by Maxwell autodoors (Sketchfab `maihupronoob`), CC BY 4.0, changed by the same
  script: the seal's gap widened to 2.80 m and its pads 3.25 m tall; the leveller's deck sized
  2.13 x 2.44 m and its textures halved to at most 512 pixels.
- `forklift.glb`: "Warehouse Forklift Gameready" by Kamran Mughal (Sketchfab
  `absologixemployee`), https://sketchfab.com/3d-models/warehouse-forklift-gameready-94e21059f00c4e989c6403ada034516e;
  `pallet_jack.glb`: "Pallet Jack" by FFeller (Sketchfab `FFeller`),
  https://sketchfab.com/3d-models/pallet-jack-eccf1ee2e5d64743a7b4be69acfc734f; `pallet.glb`:
  "Euro pallet photoscanned" by widthRider (Sketchfab `widthRider`),
  https://sketchfab.com/3d-models/euro-pallet-photoscanned-84132ceb4323477292ccf22a349b9f9d.
  All three CC BY 4.0, changed by `tools/art/convert_depot_models.py`: the forklift's carriage
  (its forks, fork plate and load backrest) cut from its body so that it rides up the mast
  (part G of step 5 of #253, #302); the forklift's specular
  map left out; the pallet sized as the American 48 x 40 in pallet, reduced to 3,000 triangles
  and made matte; their textures halved to at most 1024 pixels. Credited in the game's credits
  ("THE DEPOT").
- `office_chair.glb`: "Office Chair" by Red Fox (Sketchfab `nokillnando`),
  https://sketchfab.com/3d-models/office-chair-b228a29fa84544c2be501c295653ffe7, licensed CC BY 4.0
  (https://creativecommons.org/licenses/by/4.0/). Changed: sized by its seat to 0.47 m, centred on
  its gas lift and its textures halved to 1024 pixels by `tools/art/convert_depot_models.py`.
  Credited in the game's credits ("THE DEPOT").
- `carton.glb`: Poly Haven's "Cardboard Box 01" by Rahul Chaudhary (CC0), reduced to 399
  triangles with its textures at 512 pixels by the same script.
- `cladding_grey_diff_2k.jpg`: made by `tools/art/make_depot_textures.py` from Poly Haven's "Box
  Profile Metal Sheet" by Amal Kumar (CC0), turned grey.
- `hazard_stripes.png`: drawn by `tools/art/make_depot_textures.py`, yellow and black stripes for
  bay 9's dock lift; made for this game.

## The yard at night (part H of step 5 of #253, #305)

- `tractor_1980.glb`: "Semi Truck 1980" by Brian Trepanier (Sketchfab `CMBC`),
  https://sketchfab.com/3d-models/semi-truck-1980-5f6db10ac12645b8938a4b76942d9133.
- `trailer_dryvan.glb`: "Truck Trailer FREE" by NLM (Sketchfab `NLM-Group`),
  https://sketchfab.com/3d-models/truck-trailer-free-575958a53e3d4e9f8bcfb1ee2cef67bf.
- `box_truck.glb`: "LCT 3000 '95 - Low poly model" by Daniel Zhabotinsky (Sketchfab
  `DanielZhabotinsky`), https://sketchfab.com/3d-models/lct-3000-95-low-poly-model-663a0953c038434a918cb85725c88ffa.
- `dumpsters.glb`: "dumpster" by YJ_ (Sketchfab `YJ_`),
  https://sketchfab.com/3d-models/dumpster-989ea7f01b924859b3484ee27103e8d9.

All four CC BY 4.0, fetched on 2026-11-11 (#221-#222, `source_assets/sketchfab/`), changed by
`tools/art/convert_depot_models.py` on 2026-11-17: the trailer slimmed from 637,301 faces to
20,000 triangles and its landing gear made a separate part (so a coupled trailer's is cranked
up), the tractor slimmed from 201,782 faces to 35,162 triangles, every texture halved to at most
1024 pixels, the specular maps left out. Credited in the game's credits ("THE YARD AT NIGHT").
The box truck's own made-up "LCT" badges and plates are kept.
