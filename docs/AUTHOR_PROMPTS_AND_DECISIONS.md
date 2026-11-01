# Author prompts and decisions

This file records what the author asked for, approved and declined during the
final-project realism work, in the author's own words. Prompts are quoted exactly, typos
included. Claude Code's proposals appear only through the answers the author gave them.

- **Prompt:** the author's request, verbatim.
- **Decision:** approved, declined, chose (from offered options) or deferred.
- **Result:** what happened and where it is recorded.

Earlier decisions, from repository setup and Assignment 5, are in
[`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md) (C01–C10) and the Assignment 5 documents at
tag `a5`. Pictures the author approved or rejected are filed in
[`source_assets/artwork/captures/`](../source_assets/artwork/captures/README.md).

## 2026-10-30

1. **Prompt:** "and the road doesnt look like road.. it should look realsictic and ghosted.
   and headlights dont make any difference when switched on and off. the user should see
   the road little better when turned on. and less when turned off. i want all small
   details like this. and i am not happy with car interior"
   - **Decision:** the realism work starts; the current look is declined.
   - **Result:** look-development experiments, then Phase 1 in `ROADMAP.md`. The still
     `rejected/2026-10-30_today_headlights_on_off.png` shows the look that was declined.
2. **Prompt:** "[Image #39] - i want it to be as realistic as this. this is a game.
   [Image #40] - terrible, cant see the road at all when light is on. road should be more
   visible"
   - **Decision:** declined volumetric mist in front of the headlights.
   - **Result:** `rejected/2026-10-30_headlights_lighting_mist.png`; volumetric fog stays
     off (`CLAUDE.md`).
3. **Answers to Claude Code's questions:** renderer "Yes, switch"; models "Free, credited";
   time of day "Rainy night"; deadline "More than a month".
   - **Decision:** chose Forward+ (C12), free credited models and a rainy night.
4. **Prompt:** "add like realistic shaders if we need to, add animations do how a top mnc do
   it, follow best practices and techniques. and make sure to write in frequency.md whats
   happening and all our decisions and also make sure to save the pictures in assets
   whatever we are rejecting and approving in accurate folders."
   - **Result:** the development log `fractional.md` and the captures folders
     `approved/`, `rejected/` and `pending/`.
5. **Prompt:** "no i gave it for you to know how realistic i want my game to be"
   - **Decision:** declined filing the author's reference screenshot as an approved image.
   - **Result:** the screenshot was removed from the repository (see the memory note on
     shared images).
6. **Answers:** "I'll paste the assignment"; "Near-photoreal, consistent"; "Approve the
   direction".
   - **Decision:** chose near-photoreal (C11) and approved the low-beam direction.
   - **Result:** `approved/2026-10-30_low_beam_headlights.png` and
     `approved/2026-10-30_low_beam_full_view.png`.
7. **Prompt:** (pasted the Assignment 10 brief) "but this will keep changing because my
   submission in december 20th. but i want a real game as my final portfolio piece"
   - **Result:** `ROADMAP.md`.
8. **Answers:** "macOS, Forward+"; "Yes, download"; "All three missions".
   - **Decision:** chose the macOS export (C13), downloading the export templates, and all
     three missions (C14).
9. **Prompt:** "make sure to follow best practices, make sure to update the documentation.
   make sure the file names are appropriate and accurate and meaninful and folder
   strucutre is clean and best practices. the goal is to put the game on some game store
   to sell it. make sure we are doing a realistic and professional game"
   - **Result:** C15.
10. **Prompt:** "we can skip selling also if its too much work. but i want realistic game.
    dont do anything that will go against our assignments for now. focus on thedevelopement
    of game, we will clean it up when i sat"
    - **Decision:** deferred selling. The repository clean-up waits for the author's word.
11. **Prompt:** "and at each step take my approval and then only do it"
    - **Result:** the working rule in `CLAUDE.md`.
12. **Prompt:** "perfect do it"
    - **Decision:** approved committing the plan (ROADMAP, decisions C11–C15, captures).
13. **Prompt:** "okay, first i think we revert change-brief.md. maybe give me suggestions. we
    should lose the work that we submitted for assignments. i mean how should we strucutre
    this? different branches and we merge into main at final project time?? or each folder
    for each assignment?"
    - **Answers:** "explain me how it will look for the one youre recommending"; "Yes,
      revert"; "assignment 5 deadline is extended so we can submit again. what should we
      do".
    - **Decision:** approved reverting `CHANGE-BRIEF.md`.
14. **Prompt** (instead of answering a question about folder structure): "i want something
    to be more like after assignments i want it to be professional i mean i dont want it
    to look like assignment 5 and assignment 6 after done with this course. i want to keep
    it as professional and i developed and portfolio piece"
    - **Decision:** declined per-assignment folders. Submissions are kept as git tags, and
      the repository ends as a professional game repository.
15. **Prompt:** "why to resubmit?", then "its fine. focus on creating making realistic game"
    - **Decision:** declined resubmitting Assignment 5.
16. **Prompt:** "yes do it. dont remove everything what we have in files till now. the ta will
    check our assignment"
    - **Decision:** approved, on condition that Assignment 5 files stay in place.
17. **Prompt:** "make changes and push to a new branch, for now we will make a pr later after
    assignment 5 is graded"
    - **Result:** work moved to the `develop` branch.
18. **Prompt:** "yes do it. never push to main without my approval"
    - **Result:** `main` changes only through a pull request the author approves.
19. **Prompt:** "show me after making the road,car more realstic add lot of trees on the
    entire road. dense trees, froest like road just a single lane road. they are literally
    the same bro. i told you to improve them. assignment 5 is done. move on."
    - **Decision:** declined the Run 1 look as too unchanged, and widened the scope to the
      road, forest and van.
    - **Result:** Run 2.
20. **Prompt:** "also when i switch on lights, i dont see more road, when lights are off road
    should be more darker. and also, the van interior isnt realistic. and rain should be
    super realistic for me. droplets on windshield etc. when wipper wipes them they should
    go and come back etc all that. make sure we are following best practices and realstic
    ones. use something better if this is not the best - 17 million polygons"
    - **Result:** Runs 2–3: the headlight fix, the wipe map, and drops that re-form after
      each wipe.
21. **Prompt:** "do all these properly then i will test all at once. i want the car interior
    to be different the ac vents, speedometer, sterrting wheel everything. more details,
    realistic"
    - **Result:** Run 3: a new cluster, vents, wheel and hood.
22. **Prompt:** "i dont like the trees. they look fake, i dont like the fog on the drivers side
    window. make it look more realistic like maybe add water droplets dripping on drivers
    side window as well. idk. also make change the van interiors completely. add more
    details. change everything inside the van.the sterring wheel sucks.[Image #44]. the
    vent is inside the drivers door. and also, the sterring wheel points downwards check
    for prebuilt if there are any maybe idk or create something better. or ask me how i
    want to be and what details you need to create like model plan etc?"
    - **Decision:** declined the Run 3 trees, the driver's-window fog and the Run 3 wheel.
    - **Answers:** "Free prebuilt, I pick"; "Modern van"; "Drops and drips, no fog";
      "Blender + Sketchfab token".
    - **Result:** Run 4 (C16, C17).
23. **Prompt:** "[Image #45] - its on."
    - **Result:** the Blender add-on was switched on.
24. **Prompt:** "the drivers window rain doesnt look as realistic as front windshield"
    - **Decision:** declined the Run 4 side-window rain.
    - **Result:** Run 5, with shared rain code. Before and after:
      `pending/2026-10-30_run5_side_window_rain.png`.
25. **Prompt:** "do these for me - 1. New interior. I'll search for free modern van cockpits
    and show you 2–3 options with pictures. You pick one. I remove the logos and wire up the
    wheel, gauges, mirrors and switches, replacing the whole interior, wheel included. 2.
    Realistic trees. I'll render real branches from Poly Haven's free pine scans into
    textured cards, so the trees stop looking fake. and also add more rain to the front
    windshiled and make it little unclear to see as if in real life when there is real
    rain and lot of droplets on windshield."
    - **Decision:** approved Claude Code's interior and tree plan, and asked for heavier
      rain.
    - **Result:** Run 6; `pending/2026-10-31_run6_rain_trees.png`.

## 2026-10-31

26. **Prompt:** "also when the car is moving quickly make sure the water is running up like
    in real life and is trying to fall off the car. for trees we thought we will use some
    other tool right? or am i worng? [Image #47] - I want A"
    - **Decision:** chose cockpit option A (Hyundai Staria, Sketchfab, CC-BY), and asked
      why Blender was not used for the trees.
    - **Result:** Run 7: water runs up the glass at speed. The Blender question was answered
      in the log.
27. **Command run by the author:** `uvx mcp-for-blender install-addon`
28. **Prompt:** "or maybe hes doing it with AI, its fine use it for now. make this for
    realstici understand the gravity, physics and do it. - [Pasted text #48 +3 lines]. add
    in the documents for my approvals, declines and my prompts what i want as well. i
    switched on blender as well. i want the A van. do it. i want as realsicitc as that one.
    show me interiors as well."
    - **Decision:** approved using cockpit A "for now" after the warning that its licence
      may not be valid (C18). Asked for physically based water (C19), this file, and to see
      the interiors.
    - **Note:** the pasted text did not reach Claude Code; it was taken to be the four
      lines describing water at speed.
29. **Prompt:** "pick B, or have me build a custom modern cockpit --> you arent coming upto
    my mark thats the problem. can you do it how they did? the free models? also, check
    this - [Image #49]."
    - **Decision:** declined option B and a cockpit custom-built by Claude Code, because
      earlier custom work did not meet the author's bar. Asked whether Claude Code can make
      models the way the free-model makers did. The screenshot shows Blender connected on
      port 9876, with every asset library and AI generator unticked.
    - **Result:** after the Blender restart the add-on reports protocol 15. Cockpit A waits
      only for the Sketchfab library to be ticked and the API key entered.
30. **Prompt:** "also the game looks not so smooth ?? why?? it feels like its kind of
    lagging."
    - **Result:** measured, parked driver's view at 1280×800 with vsync off:
      - all shadows on: 10–14 FPS, 5,319 draw calls and 15.2M triangles per frame;
      - trees, ground props and moon casting no shadows: 43–44 FPS, 481 draw calls and
        0.83M triangles.

      Shadows redraw the whole near forest into the moon's and both headlights' shadow
      maps every frame. The MacBook Air also slows down as it heats up. A performance pass
      was proposed and is waiting for approval.

31. **Prompt:** "My recommendation: use A now, as you decided; it meets your bar today.
    Before any public release or sale, I rebuild our own cockpit in Blender with A as the
    reference, which also removes the licence risk. --> lets rebuild it in blender just to be
    safe. how to keep all of them and switch to 60fps?"
    - **Decision:** chose to rebuild the cockpit in Blender now, using A only as a reference
      (C20). Asked to keep every visual effect and reach 60 FPS (C21).
    - **Result:** measured in paired runs with every effect still on: today 20.8 FPS; MetalFX
      upscaling at 67% gives 24.5; shadows limited to near distances (trees 50 m, props
      25 m, moon 40 m in two cascades) give 38.1; both together give 46–47 FPS. A plan to
      reach 60 was proposed and is waiting for approval.

32. **Prompt:** "yes do it, 60fps first then cockpit . also the blender is all sorted -
    [Image #50]."
    - **Decision:** approved the 60 FPS pass, including the MetalFX setting in
      `project.godot`, and then the Blender cockpit, in that order. The screenshot shows
      Poly Haven and Sketchfab ticked, with the API key entered.

33. **Prompt:** "didnt we have trees and bushes together?? did you remove the bushes?"
    - **Result:** nothing was removed. The capture logs show 11,330 ground props before and
      after the speed work, and renders with the old 48 m and new 24 m fern chunks show the
      same roadside ferns. Ferns are placed 3.5–22 m from the road and drawn to about 55 m;
      deeper in the forest there are only trees, as there have been since Run 3. Unlit
      bushes are nearly black at night. The author was asked for a screenshot of the spot,
      and offered undergrowth between the trees as well.

34. **Prompt:** "2. Add undergrowth between the trees, so trees and bushes mix deeper in the
    forest, not just along the road. This adds drawing work, so I'd add it sparsely and
    re-measure to keep 60 FPS. - alright do it"
    - **Decision:** approved sparse undergrowth between the trees, with the frame rate
      re-measured.

35. **Prompt:** "also the water droplets on front windshiled reduced. increase them. and make
    the water droplets running down and away random. dont make it uniform. thats not how
    the real life works right?? add in documentation also."
    - **Decision:** asked for more windshield droplets, and for running drops with random
      timing, speeds and paths instead of uniform columns, documented.
    - **Result:** Run 11 (`CHANGE-BRIEF.md`, development log).
      - More and larger resting droplets, lit by the night sky.
      - Runners are independent random events: random start, size, speed and length;
        stick-slip motion, wandering paths, swept lanes with beads.
      - Sheet: `pending/2026-10-31_run11_windshield_drops.png`.

36. **Prompt:** "i pasted the key and check now. how to turn off wipers?"
    - **Result:** the Sketchfab library reports "on". The wipers are on V and cycle slow →
      fast → off from the slow setting the game starts in, so two presses turn them off.
    - **Result:** van A was imported into Blender as a local reference.
      - Its interior is a low-detail placeholder: a smooth untextured dashboard, a faceted
        wheel, no gauges or controls.
      - The detail in its thumbnail is all exterior.
      - Its meshes are split by material across the whole van, typical of a converted
        game model.
      - The views were shown to the author. The cockpit needs a different realism
        reference.

37. **Prompt:** "check for free models for interior as well maybe?[Image #51], theres nothing to
    choose for me?"
    - **Decision:** asked for free interior and cockpit models to choose from, not only a
      cockpit built by Claude Code.
    - **Result:** searched Sketchfab for free CC-BY interiors and imported the two best into
      Blender to check from the driver's seat:
      - **Honda e (Alex Murias):** professionally modelled, separate wheel and screens,
        clean licence, a car;
      - **Opel Astra 2013:** a photo scan with real textures, ragged edges, baked daylight
        reflections and a fused wheel.

      Rejected from the search: a partial console, a futuristic student concept, a scan of
      a van's empty cargo area, a 1990s grey interior, and non-commercial licences. The
      driver's views were shown to the author.

38. **Prompt:** "[Image #52] - i like this more." (the Honda e driver's view)
    - **Decision:** chose option 1, the Honda e interior (Sketchfab, CC-BY, Alex Murias), to
      be adapted into the van (C22).

39. **Prompt:** "yes do it" (to step 1 of fitting the Honda e interior)
    - **Decision:** approved step 1, done in Blender only:
      - copy the interior;
      - delete the wheel badge and black out Honda's screen pictures;
      - put its driver's eye on ours;
      - bring in the van body as a guide;
      - extend the dash to the windshield and move the doors out to the side windows;
      - render it from the driving camera and from the side.

      No repository file changes in this step.
    - **Result:** done in Blender only. The fitted copy has 207 parts and 934,581 faces.
      - The dash grew from 1.19 m to 2.2 m, lengthened at three cuts.
      - The doors moved out 24 cm (driver) and 69 cm (passenger); the passenger seat moved
        45 cm to mirror the driver's.
      - The roof was raised 55 cm and widened to the van; the windshield pillars now stand
        upright along our glass.
      - Renders from the driving camera, both head turns, the cab, a side cut and a top
        view went to the author on one sheet. The sheet and the `.blend` copy are in the
        agent's scratch folder, not the repository.
      - Still open: the cab is open behind the seats, and the floor keeps the car's
        rear-footwell shape.

40. **Prompt:** "proceed but make sure its so accurate" (to step 2, closing the cab)
    - **Decision:** approved step 2, done in Blender only:
      - a plain dark wall behind the seats;
      - the floor and roof carried back to it;
      - the same six renders.

      The author asked for an exact fit.
    - **Result:** done in Blender only.
      - **New wall:** a dark wall at exactly the van body's cab end (Godot z 0.06), with
        side panels behind the B-pillars, a floor plate, the floor flattened behind the
        seats, and roof-edge strips down to the side-glass tops.
      - **Gaps closed:** the measuring test cast rays from the driver's eye over the whole
        mouse-look range and found more gaps: the open sunroof, door-handle recesses, belt
        slots, slits at the windshield pillars and one slit in the lengthened dash. These
        were closed with:
        - a shut sunshade panel;
        - backing panels behind the door cards;
        - black windshield edge bands (like real frit);
        - corner panels;
        - a dash slit cover.
      - **Rays that escape the cab:**
        - 3,209 of 33,750 before, 0 after at 1° spacing;
        - 0 of 536,463 at 0.25°;
        - 0 of 1,208,757 at 0.1° over the dash, pillars and roof edges.
      - **Driving view:** 3.6% of pixels changed, all in its left third (the pillar band, a
        door seal line, the closed slit). In the default view, glass is 50.4% of the
        picture against 52.1% before.
      - The sheet and the `.blend` copy are in the agent's scratch folder.

41. **Prompt:** "but we can move inside the car to look around right? so maybe we should keep it and keep it smooth? idk? what do you think?"
    - **Decision:** asked for Claude Code's view on slimming the cockpit (step 3).
    - **Claude Code's facts:**
      - The player turns their head from a fixed seat position; they cannot lean or walk.
      - The full-detail cockpit would be over 110 MB, with 110.6 MB of textures alone,
        against the 25 MB file rule and GitHub's 100 MB limit.
      - It would be drawn up to three times a frame: depth, colour and moon shadow.
    - **Claude Code's recommendation:** keep the look, not the face count. Remove only
      what the seat can never see or what is smaller than a pixel, and undo any cut that
      changes the driver's views.
    - **Outcome:** the author chose Claude Code's recommendation (#42).

42. **Prompt:** "yes do it, keep it looking the same. and make sure the game is smooth as butter"
    - **Decision:** approved step 3. Slim the cockpit under the rule "no visible change from
      the driver's seat", and make sure the game runs smoothly.

43. **Prompt:** "bro what are you doing?? the cockpit we added is not functional?? wtf?"
    - **Context:** this came during step 3. Claude Code was running a frame-rate test
      without warning first: a 20-second game window, in a throwaway copy of the game in
      its scratch folder. The cockpit sat in it as a static model.
    - **Response:**
      - Stopped the test.
      - Confirmed the real game is untouched: `cabin.glb` is byte-identical.
      - Explained that the wheel, gauges, map and mirror screens get hooked up in step 4.
      - Reported step 3 honestly:
        - the first slim, 406k faces, still changes the look;
        - the full cockpit costs about 1.8 ms a frame and about 380 draw calls (Mac hot).
    - **Outcome:** the author chose to finish slimming first (#44).

44. **Prompt:** "finish step 3 first, then hook it up"
    - **Decision:** finish step 3 (no visible change, smooth), then step 4 (hook the cockpit
      into the game). Step 4's files and commands are shown before it starts, per the
      working rule.
    - **Result (step 3, Blender only; the game is untouched):**
      - **Look:** compared pixel by pixel against the fitted original in nine views. From
        the driver's seat, at most 0.13% of pixels change at all, and none by more than
        48 of 255 levels. Outside views change at most 0.15%, mostly at edges.
      - **Size:**
        - 935,427 faces in 224 parts became 847,364 triangles in 93 material-and-area groups;
        - textures went from 110.6 MB to 30.6 MB;
        - a 31,533-triangle shadow stand-in replaces the shadow work of 573,638 faces;
        - only faces behind the wall were removed.
      - **Speed** (throwaway game copy, hot Mac, back to back): the cockpit costs about
        1.0 ms a frame parked and 1.1–1.6 ms driving. The unoptimised version cost 1.8 ms
        plus 380 draw calls. Today's whole game runs about 27 ms a frame on the hot Mac,
        against about 13 ms cool.
      - **Lessons:**
        - copying shading by projection broke thin parts and button labels;
        - sight-line sampling misses stacked surfaces and steep angles;
        - merging everything defeats Godot's per-object detail levels.

45. **Prompt:** "ok"
    - **Decision:** approved step 4, which hooks the cockpit into the game. Its scope:
      - the cockpit files and the shadow stand-in go into `art/`; `cabin.glb` and
        `steering.glb` stay in the repo, unused;
      - the Honda wheel turns with the steering;
      - our cluster and map show on the Honda screens, with the same night dimming;
      - the mirror views show on the dash-end screens;
      - the old trim pieces are removed;
      - all suites are rerun; the art check gets a written exception for the cockpit;
      - credits and the run documents are updated;
      - a frame-rate check runs, with a warning before any window opens.
    - **Result (Run 12):**
      - **In the game:** the cockpit is in, in four glTF files with shared textures (each
        under 25 MB).
      - **Wheel:** the whole Honda wheel turns on its hub. Claude Code found and fixed two
        problems:
        - the wheel had always turned the wrong way;
        - step 3 had left the hub ring and the spoke covers on the fixed column.
      - **Screens:** our cluster and map are on the Honda screens, through a new filtered
        screen shader, and the reverse camera takes the map's place. The mirror views show
        on the dash-end screens. Night dimming is unchanged.
      - **Mirror arms:** they now start at the side glass.
      - **Tests:**
        - all suites pass, and the new `test_cockpit.gd` passes 22/22;
        - with the old steering sign restored, it fails;
        - the art check has the written cockpit exception.
      - **Cost:** about 0.4 ms parked and 0.7 ms driving: 69 and 65 FPS, against 71 and 68
        for the old cabin.
      - **Evidence:** stills in `evidence/phase_1/cockpit/run12/`.
      - **Left open:** about half of the right mirror screen is hidden from the driver's
        seat.

46. **Prompt:** "can you place the steering wheel in front of driver little to the left. and also, make the road full of twists and turns like driving on ghats. not just a circle road."
    - **Status:** Claude Code describes both changes and waits for approval before changing
      anything.
    - **Claude Code's proposal:**
      - **Wheel:** move the driver's seat about 4 cm right instead, so that the wheel, column
        and gauges stay lined up. Stills from the game at 0, 4 and 7 cm were shown.
      - **Road:** real ghats (hills, hairpins, drops; several runs) or twists on flat ground
        (about one run).
      - **Deadline:** a reminder about the Nov 3 export.
    - **Outcome:** see #47.

47. **Prompt:** "move the steering wheel. assignment 10 extended dont worry. real ghats i want"
    - **Decision:**
      - move the steering wheel itself a little to the left, not the seat;
      - the Assignment 10 deadline is extended, so it is not a constraint now;
      - the road becomes real ghats: hills, hairpins and drops, not twists on flat ground.
    - **Result (Run 13, the wheel):**
      - The wheel, its column and its stalks moved 5 cm left.
      - The gauge display moved 3.5 cm, the farthest the Honda's black screen panel allows,
        so it stays in the wheel's upper opening.
      - All suites pass. Stills are in `evidence/phase_1/cockpit/run13/`.
    - **Ghat road:**
      - **Layout drafted by Claude Code:**
        - a 3.0 km loop from the depot: up a 76 m hillside through 5 hairpins, along the
          ridge, and down another 5 hairpins;
        - grades of 7.6–7.8% everywhere and hairpin radius 13 m;
        - about 530 × 430 m, inside the design's 1.2 × 0.9 km envelope.
      - **Canon note:** the story sets Blackridge in an American town, so the proposed look
        is an American mountain road: metal guardrails, yellow curve and switchback signs,
        rock cuts.
      - **Plan:** three runs, each approved separately. The layout and Run 14 wait for
        approval.

48. **Prompt:** "[Image #53] - i want a moon roof, let users see into the sky. also, for lights add low beam and high beam. also, make sure everything is realistic. with lights off the rain looks amazing on windshield realsitic af but with lights on its little less amazing. also i want this. and start with run 14. i am just letting you know about these as well. remember to implement all these"
    - **Context:** the image looks up at the cockpit roof. It shows the shut sunroof panel
      from step 2, the Honda overhead console with its own rear-view mirror, and the
      code-built inside mirror outside the windshield, with rain on it.
    - **Decision:**
      - approved Run 14 (the drivable ghat), with the proposed layout and the American
        mountain-road look;
      - the other requests are a backlog, to be implemented later and each approved
        separately:
        - a moon roof that shows the sky;
        - low and high beams;
        - windshield rain as convincing with the lights on as with them off;
        - everything realistic.
    - **Result (Run 14, C23):**
      - **The road:** a 3.2 km lap from the depot over Blackridge Hill. It climbs 79 m
        through 5 hairpins, runs along the summit ridge, comes down through 5 more, and
        returns along the valley.
      - **Grades and widths:** grades reach 9.1% and hairpins 6.2%. Hairpins are widened to
        6.5 m.
      - **Change from the approved map:** its way home ran through the depot building, so
        it now passes south of it.
      - **The hillside:** within 20 m of the road it follows the road's heights. The first
        version left embankments with drops on both sides; the stills caught it. Plain
        concrete barriers line every drop.
      - **The van:** it rolls back without the brake, the brake holds it on a hill, and it
        climbs from a stop. Its body and your view tilt with the road.
      - **The map screen:** it shows the real road.
      - **Tests:** all suites pass, including the new `test_ghat_road.gd` at 22/22.
      - **Frame rate (cool Mac):** 69–84 FPS on the hill, 78–79 FPS on the start straight.
      - **Evidence:** stills in `evidence/phase_1/ghat/run14/`.

49. **Prompt:** "yes start run 15. make sure we are documenting everything as well. also dont make it a pattern. make sure its uniqque. something like this, also make the wipers more realisitc and spawn the user away from the depot. [Image #54] - something like this maybe"
    - **Context:** the image is a "Ghat Road Map" of a mountain pass. Its road winds
      irregularly from a foothill village by a river up to a hilltop, through 9 hairpins of
      different shapes. Along the way it shows cliffs, a river, waterfalls, a tunnel, a
      viewpoint, a lay-by, a rest stop and a fuel station. It is a style reference ("something
      like this maybe").
    - **Decision:** approved Run 15 (the ghat details), with these additions:
      - the road layout must not be a repeating pattern: one unique, irregular mountain road,
        like the reference;
      - more realistic wipers;
      - the player starts away from the depot;
      - everything documented.
    - **Result (Run 15, C24):**
      - **The road:** one irregular 3.0 km mountain road from 38 hand-placed waypoints, four
        hairpins up and four down, no two legs alike. It climbs 64 m at up to 9.7%.
      - **The dressing:** galvanized guardrails and dry-stone walls at every drop, rock
        faces on the steep cuts, white delineator posts, American warning signs and chevrons
        at every hairpin, convex mirrors at the two tightest hairpins, and a viewpoint
        pull-off that looks over the valley to the town's lights.
      - **The start:** a lumber yard 589 m from the depot. A landslide closes the valley road
        east of the depot, so the way there is over the hill. Both are Claude Code's own
        calls, offered for the author's verdict.
      - **The wipers:** they park flat at the bottom of the glass, sweep 99° in tandem, slow
        at the ends and fast in the middle, and the blade rocks as it reverses.
      - **Tests:** all suites pass; `test_ghat_road.gd` is now 29/29.
      - **Frame rate (cool Mac):** 74.9 FPS parked and 76.0 driving at the start, 68–119 FPS
        on the hill.
      - **Not built from the reference:** the river, waterfalls, tunnel, rest stop, fuel
        station and numbered hairpins.
      - **Evidence:** stills in `evidence/phase_1/ghat/run15/`.

50. **Prompt:** "[Image #55] - i dont see the moon roof and lights for low beam and high beam and wipers arent realistic and on the pic if you see the floor of depot is coming onto road"
    - **Context:** the image is the author's screenshot from the driver's seat, at night on
      the valley road beside the depot ("DEPOT / 30 m" on the map). The wipers are
      mid-sweep. A rectangle of the depot yard's surface is drawn over the road ahead, with
      a lit edge across it.
    - **What Claude Code found:**
      - **The moon roof and the low and high beams were never built.** They were still in
        the #48 backlog, which waits for the author's approval of each step. Run 15 covered
        only the road, its dressing, the start and the wipers.
      - **The depot floor:** the 18 × 18 m driveway patch near the depot was placed for the
        old flat loop and was never moved. It covers 16 m of the new road, from the centre
        line to the edge, 3 cm above the asphalt; its side face is the lit line. The yard
        itself also covers 22 m of the road's edge where the road bends round the yard's
        north-west corner.
      - **The wipers:** from the driver's seat they read as thin black sticks, with no
        visible blade, rubber or arm shape, and the glass shows no clear sector behind them.
    - **Claude Code's proposal:** four steps, each approved on its own: (1) the depot
      floor, (2) the wipers, (3) the low and high beams, (4) the moon roof.
    - **The author's answers (2026-10-31):**
      - Step 1: "Yes, fix it now (Recommended)".
      - What is wrong with the wipers: "They look like sticks", "Water doesn't react".
      - The high-beam key: "Add it to the L. when L is pressed once low beam should turn on,
        when pressed twice high beam, when thrice lights off."
      - The moon roof: "Glass over front seats (Recommended)".
    - **Decision:** step 1 (the depot floor) approved. The L key will cycle low beam, high
      beam, off; this changes the protected L behaviour at the author's request, so its
      `CLAUDE.md` wording and the tests that press L change with step 3, and are shown first.
    - **Result (Run 16, step 1):** the depot yard and driveway are one flat surface built
      from the road's own edge. The driveway meets the asphalt level, and nothing of the
      yard lies on the road. A new test check fails if any of it does. All suites pass.
      Still: `evidence/phase_1/depot/run16/depot_road_after.png`.

51. **Prompt:** "yes start step 2"
    - **Decision:** approved Run 16 step 2, the wipers: real wiper parts (tapered arm,
      spring cover and hook; blade with spoiler, rubber lip and end caps; the driver's blade
      longer), and water that reacts (a clear arc that refills drop by drop, water pushed
      along the blade and dumped at each turn, thin streaks that fade), first capturing one
      stroke as it is now; new test checks; every suite; one game window for stills.
    - **Result (Run 16, step 2):**
      - **The wipers:** real parts. Each has a pivot cap, spring cover, tapered arm and hook,
        and a beam blade with spoiler, rubber lip, end caps and adapter. The driver's blade
        is 70 cm and the passenger's 55 cm.
      - **The water:** the wiped fan stays clear and refills over about 2 s, with new drops
        in new places each time. A ridge of water rides ahead of each blade and is dumped
        where the blades turn at the top. The rubber leaves thin streaks, and a moving blade
        leaves a short blur.
      - **Tests:** all suites pass, with the new `test_wipers.gd` at 12/12.
      - **Frame rate:** unchanged, 76.0 FPS parked and 74.3 FPS driving.
      - **Stills:** `source_assets/artwork/captures/pending/2026-10-31_run16_wipers.png`;
        the effects show best in motion.

52. **Prompt:** "yes start step 3"
    - **Decision:** approved Run 16 step 3, the low and high beams on L: L cycles low beam,
      high beam, off, and the game still starts on low beams; a high-beam pattern with no
      cutoff and a long reach on the same two headlights; a blue high-beam lamp on the
      cluster; the `CLAUDE.md` wording for the protected L key shown to the author first;
      the tests that press L changed with that reason, plus new checks; every suite; one
      game window for stills with low beams, high beams and lights off.
    - **Result (Run 16, step 3, C25):**
      - **L:** it cycles low beam, high beam, off; the game starts on low beams.
      - **High beams:** they keep the low beam's light, add a hot spot on the horizon and
        reach 220 m. A blue lamp shows on the cluster.
      - **Measured:** from the driver's seat, the far road (50–100 m) reads 40.3 on low
        beams, 61.6 on high beams and 28.7 with the lights off; nothing clips to white.
      - **Tests:** all suites pass. The tests that pressed L once for "off" now follow the
        cycle, as written in the brief.
      - **`CLAUDE.md`:** its wording for the protected L key waits for the author's OK.
      - **Stills:** `evidence/phase_1/beams/run16/beams_sheet.png`.

53. **Prompt:** "yes apply it and start step 4"
    - **Decision:**
      - the `CLAUDE.md` wording for the L key, as drafted in step 3, is approved and
        applied;
      - Run 16 step 4, the moon roof, is approved: a glass opening of about 70 × 45 cm in
        the cockpit roof above the front seats, cut in Blender (removing the shut panel
        from the cockpit fit); tinted glass with rain that sits and streaks backward at
        speed; the mouse look-up limit raised from 29° to about 60°; new test checks that
        the opening is clear to the sky; every suite; stills looking up from one game
        window.
    - **Result:**
      - **`CLAUDE.md`:** the L wording is applied.
      - **Moon roof (Run 16, step 4):** the Honda interior already had a sunroof frame over
        the front seats (139 × 43 cm); a plate added when the cockpit was fitted had closed
        it. That plate is cut away inside the frame, so the frame now opens onto tinted
        glass and the sky. The glass is wider than the 70 cm first estimated, and keeps the
        Honda's own trim.
      - **Rain on the roof glass:** drops sit when parked and are pushed backward at speed.
      - **Looking up:** the mouse now looks up far enough to see the whole roof.
      - **Tests:** all suites pass; the cockpit test is 26/26. With the old closed roof it
        fails.
      - **Stills:** `evidence/phase_1/moon_roof/run16/moon_roof_sheet.png`.

54. **Prompt:** "fix the mirror first, then commit"
    - **Decision:** approved the double rear-view mirror fix (the Honda's own mirror and the
      old code-built mirror beyond the windshield), then a commit of Runs 1–16 on
      `develop` (no push, no co-author line, labelled "(agent)").
    - **Result (Run 16, step 5):**
      - **The mirror:** the live rear view plays on the Honda's own centre mirror, as on the
        real Honda e. The old code-built mirror beyond the windshield, with its dark box, is
        gone. The cockpit test gained two checks (28/28), and they fail with the old mirror
        back. All suites pass.
      - **The commit:** Runs 1–16 are committed together on `develop`, without a push.

55. **Prompt:** "- Rain falling through the headlight beams waits for Assignment 6's particles. - A green road sign looks pale cyan under high beams. - The van's outside roof has no glass, which only shows from outside. - Your verdict on the lumber-yard start and the landslide. - Whether the CLAUDE.md line that says L "toggles" the lights should say "cycles". - do all these and i will test"
    - **Context:** the author pasted the open items from Claude Code's last report.
    - **Claude Code's question:** falling rain in the beams was kept for Assignment 6 (the
      particles assignment), so how should it be done: shader rain now, particles now, or
      wait?
    - **The author's answer:** "Shader rain now (Recommended)".
    - **Decision (C26):** rain streaks drawn by a shader inside the headlight beams, with no
      particle system, so Assignment 6's particles can replace them later. The other items
      are done as listed. The lumber-yard start and the landslide stay as they are for the
      author to judge while testing.
    - **Result (Run 17):**
      - **Rain in the beams:** streaks fall through the headlight beams, lit by the real
        low-beam and high-beam patterns, and none show with the lights off.
      - **Guide signs:** they are highway green.
      - **Outside roof:** the van's outside roof has dark glass over the moon roof.
      - **`CLAUDE.md`:** it says L cycles the lights.
      - **Tests:** all suites pass.
      - **Frame rate:** not measured fairly, because the Mac was on battery at 10%.
      - **Commit:** Run 17 is not committed; the author tests first.

56. **Prompt:** "when the low beam is turned on the falling rain should be less and when high beam is turned on it should be more like in real lkfe"
    - **Claude Code's proposal:** low-beam rain at about half its strength, mostly close to
      the road; high-beam rain at about 1.6× and a little denser; a test that high-beam rain
      is at least 3× as strong; every suite; one game window. It asked the author to plug
      in the Mac first (5% battery).

57. **Prompt:** "plugged in, go ahead"
    - **Decision:** approved Run 18, rain strength by beam, as proposed.
    - **Result (Run 18):**
      - **Low beams:** the rain is half as strong, so the view stays clear with a little
        rain close in.
      - **High beams:** the rain is 1.6× as strong and denser, a wall of streaks lit far up
        the road.
      - **Measured:** the rain adds +3.7 to the near road on low beams and +30.6 on high
        beams.
      - **Tests:** all suites pass; the new check fails if both beams show the same rain.

58. **Prompt:** "alright. everything is perfect. commit and push to remote"
    - **Decision:** the author accepts Runs 15–18 as tested ("everything is perfect"),
      including Run 15's lumber-yard start and landslide. Runs 17–18 are committed on
      `develop`, and `develop` is pushed to `origin`. `main` is not pushed; it changes only
      through a pull request the author approves.

## Waiting for the author

- A frame-rate check on power with a charged battery (Runs 17–18 were measured while the Mac
  was on battery or charging).
- Any pull request from `develop` to `main`, only with the author's approval.
