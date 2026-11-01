# PERFORMANCE.md

Frame-rate measurements on the target machine. The target is 60 FPS with every visual
effect kept (C21; prediction P9 in `CHANGE-BRIEF.md`).

## Machine and method

- **Machine:** MacBook Air M4, 16 GB, no fan; macOS 26.6.2.
- **Engine:** Godot 4.7.2, Forward+ on Metal, in a 1280×800 window.
- **Tool:** `tools/captures/measure_performance.gd`. It loads the first drive and waits
  4 s. It then measures 5 s parked in the driver's view, and 5 s while accelerating along
  the east straight, after 1 s of acceleration.
- **What it reports:** average FPS, the median frame time, the slowest 5% of frames (the
  hitches you feel), and draw calls and triangles per frame.
- **Vsync:** off while measuring, so the true cost shows. In play, vsync is on and caps the
  game at 60.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path game --resolution 1280x800 \
  --script ../tools/captures/measure_performance.gd -- evidence/phase_1/performance/<label>
```

The Air slows itself down when hot. The same unchanged scene measured 21 FPS cool, and
10–14 FPS after many back-to-back runs. Compare only numbers taken in one sitting.

## 2026-10-31: performance pass (Run 9)

**Before:** 20.8 FPS parked (48 ms per frame), with 5,319 draw calls and 15.2M triangles
per frame. This was measured with an earlier scratch script that reported the average
only. The causes:

- Shadows redrew the near forest into the moon's shadow map and both headlights' shadow
  maps every frame.
- All three mirrors re-rendered the whole world in the same frame, 15 times a second. This
  was the hitch.
- The heaviest props (a 102,000-triangle fallen trunk, a 41,000-triangle stump) stayed at
  full detail, because detail was chosen per 96 m chunk.

Each step adds to the ones above it. Times are the median and the slowest 5% of frames:

| Step | Parked FPS | Parked times | Driving FPS | Driving times | Driving draws / triangles |
| --- | --- | --- | --- | --- | --- |
| Shadows only near: trees 50 m, props 30 m, moon 40 m | 36.1 | 15.8 / 45.2 ms | 23.4 | 46.2 / 81.7 ms | 3,038 / 8.19M |
| Trees cast shadows with their light version; props in 24 m chunks | 46.2 | 14.7 / 36.8 ms | 38.4 | 17.8 / 50.2 ms | 2,467 / 3.42M |
| Mirrors take turns; draw to 80 m; no headlight shadows; coarser detail | 59.4 | 18.2 / 19.6 ms | 51.3 | 18.8 / 27.1 ms | 1,237 / 1.87M |
| MetalFX temporal upscaling at 75% (macOS) | 69.3 | 12.3 / 18.1 ms | 57.0 | 16.9 / 26.8 ms | 1,348 / 1.82M |
| Moon shadow in one cascade | 67.4 | 12.5 / 18.3 ms | 64.6 | 13.1 / 20.1 ms | 1,269 / 1.73M |
| Full-detail trees to 60 m, light version beyond (was 90 m) | **73.4** | 11.7 / 17.0 ms | **70.8** | 12.2 / 18.8 ms | 1,254 / 1.57M |

**Every effect is kept:** moon, headlight, tree and prop shadows; rain on all glass;
screen-space reflections; all three mirrors. In the driver's view and the roadside view
the result looks the same as before. Headlight contrast is unchanged: the road reads 98.5
with the lights on and 12.1 with them off.

Evidence: `evidence/phase_1/performance/<step>/performance.txt`, with the steps named
`shadows_near`, `proxies`, `mirrors_fixed`, `metalfx`, `moon_single` and `near60`.

## 2026-10-31: undergrowth between the trees (Run 10)

Added 1,369 young firs and 3,100 deeper ferns and fallen branches:

| | Parked FPS | Parked times | Driving FPS | Driving times | Driving draws / triangles |
| --- | --- | --- | --- | --- | --- |
| Run 9 | 73.4 | 11.7 / 17.0 ms | 70.8 | 12.2 / 18.8 ms | 1,254 / 1.57M |
| Run 10, with undergrowth | 71.7 | 11.9 / 17.4 ms | 68.6 | 12.7 / 19.5 ms | 1,431 / 1.71M |

Evidence: `evidence/phase_1/performance/undergrowth/performance.txt`.

## 2026-10-31: the Honda e cockpit (Run 12)

The new cockpit (C22) is 847,364 triangles in 93 parts. It casts no shadows itself; a
31,533-triangle stand-in casts them. It was measured back to back against a throwaway copy
of Run 11 (the old 27,084-triangle cabin), twice, in A/B/A/B order, with the Mac cool:

| | Parked FPS | Parked times | Driving FPS | Driving times | Driving draws / triangles |
| --- | --- | --- | --- | --- | --- |
| Run 11 cabin, round A | 71.1 | 11.96 / 17.51 ms | 68.1 | 12.71 / 19.44 ms | 1,431 / 1.71M |
| Honda e cockpit, round A | 69.0 | 12.35 / 17.83 ms | 65.2 | 13.35 / 20.02 ms | 1,485 / 1.96M |
| Run 11 cabin, round B | 71.0 | 11.97 / 17.52 ms | 68.0 | 12.71 / 19.55 ms | 1,431 / 1.71M |
| Honda e cockpit, round B | 68.9 | 12.36 / 17.87 ms | 65.0 | 13.45 / 20.24 ms | 1,485 / 1.95M |

**The cockpit's cost:** about 0.4 ms of the median frame parked and 0.7 ms driving
(2 and 3 FPS), plus 54 draws while driving.

**Earlier, in step 3:** while the Mac was hot, the same comparison showed 1.0–1.6 ms, and
the whole game ran at about 27 ms a frame. The game stays above P9's 45 FPS, but the
slowest 5% of frames (about 20 ms driving) are above the 16.7 ms that 60 FPS needs.

Evidence: `evidence/phase_1/performance/run12_old_a`, `run12_new_a`, `run12_old_b` and
`run12_new_b`.

## 2026-10-31: the ghat road (Run 14)

The flat loop became a 3.2 km hill road, 79 m high, with a 690 × 540 m hill. To keep the
frame rate, the forest beyond 20 m from a road is thinned to a quarter, giving 9,315 trees.
The Mac was cool; 1280×800, vsync off.

| Where | FPS | Median | Slowest 5% | Draws / triangles |
| --- | --- | --- | --- | --- |
| Standard test, parked (start straight) | 79.4 | 11.45 ms | 15.60 ms | 1,726 / 1.70M |
| Standard test, driving (start straight) | 78.2 | 11.50 ms | 16.59 ms | 1,738 / 1.80M |
| Steepest climb, parked | 69.0 | 12.26 ms | 18.59 ms | 1,396 / 2.07M |
| Climbing at full throttle | 70.5 | 12.35 ms | 17.90 ms | 1,434 / 2.33M |
| Hairpin 2, parked | 83.5 | 10.30 ms | 16.01 ms | 1,255 / 2.00M |
| Summit, parked | 81.8 | 10.23 ms | 16.66 ms | 958 / 1.28M |

The first version of the hill had 21,601 trees, 9,830 young firs and 25,815 plants. It was
thinned before any frame-rate run.

**Comparing with Run 12:** Run 12 measured 69.0 and 65.2 FPS in its own sitting, so these
numbers are not a direct comparison. On a hot Mac, expect them to drop, as before.

Evidence: `evidence/phase_1/performance/run14_ghat/` and
`evidence/phase_1/ghat/run14/ghat_captures.txt`.

## 2026-10-31: the ghat road's dressing (Run 15)

The road became one irregular 3.0 km lap with four hairpins up and four down. Guardrails,
stone walls, delineators, 75 road signs, two mirrors, a landslide, a lumber yard and a lit town
were added; the hill grew to 820 × 650 m. The forest has 11,932 trees, 6,622 young firs and
19,218 plants. The Mac was cool; 1280×800, vsync off.

The standard test now starts at the lumber yard, the new start, so it is not the view
Run 14 measured on the depot straight.

| Where | FPS | Median | Slowest 5% | Draws / triangles |
| --- | --- | --- | --- | --- |
| Standard test, parked (lumber yard) | 74.9 | 11.18 ms | 17.57 ms | 1,370 / 1.94M |
| Standard test, driving (lumber yard) | 76.0 | 11.30 ms | 18.03 ms | 1,451 / 1.98M |
| Start, parked (capture run) | 74.2 | 11.10 ms | 17.98 ms | 1,287 / 1.82M |
| Steepest climb, parked | 76.8 | 11.54 ms | 16.73 ms | 1,639 / 1.63M |
| Climbing at full throttle | 68.2 | 12.69 ms | 19.91 ms | 1,486 / 1.71M |
| Viewpoint, looking at the town | 118.8 | 7.96 ms | 10.46 ms | 1,039 / 1.32M |
| Pass, parked | 85.5 | 10.09 ms | 15.65 ms | 1,037 / 1.45M |
| Steepest descent, parked | 76.2 | 10.98 ms | 18.29 ms | 1,338 / 1.86M |

The signs are batched, one MultiMesh per sign kind, and the guardrails, posts, walls and
delineators are one MultiMesh each. The town's glows are 24 quads in one MultiMesh, drawn
only beyond 150 m.

Evidence: `evidence/phase_1/performance/run15_ghat/` and
`evidence/phase_1/ghat/run15/ghat_captures.txt`.

## 2026-10-31: real wipers and reacting water (Run 16, step 2)

The windshield shader now also draws the blade water, the streaks, the blur trail and
reseeded drops; the wipers are 18 small code-built parts (nine each). The standard test at the start,
Mac cool, 1280×800, vsync off:

| | Parked FPS | Parked times | Driving FPS | Driving times | Driving draws / triangles |
| --- | --- | --- | --- | --- | --- |
| Run 15 | 74.9 | 11.18 / 17.57 ms | 76.0 | 11.30 / 18.03 ms | 1,451 / 1.98M |
| Run 16, step 2 | 76.0 | 11.06 / 17.60 ms | 74.3 | 11.52 / 18.16 ms | 1,448 / 1.99M |

The difference is within run-to-run noise. Evidence:
`evidence/phase_1/performance/run16_wipers/`.

## 2026-10-31: high beams (Run 16, step 3)

High beams switch the same two shadowed headlights to a wider pattern and a 220 m reach
(low beams 120 m), so no light or shadow is added. Measured parked at the start, in one
window, a 3 s sample per state:

| State | FPS |
| --- | --- |
| Low beams | 59.6 |
| High beams | 59.5 |
| Lights off | 60.0 |

That run held about 60 FPS in every state, so this shows no difference between them, not
the game's top speed (`measure_performance.gd` gave 76.0 FPS parked in step 2). Evidence:
`evidence/phase_1/beams/run16/beam_captures.txt`.

## Not yet verified

- A 10-minute windowed drive on a warm Mac (P9). The slowest 5% of frames (17–19 ms) sit
  just above the 16.7 ms budget for 60 FPS, so a hot machine may show occasional drops.
- Other hardware, and an exported build.
