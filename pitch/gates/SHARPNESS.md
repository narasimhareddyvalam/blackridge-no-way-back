# SHARPNESS GATE — blackridge-pitch

Compiled master: `blackridge-pitch.mp4`
Median Laplacian variance: **607.5**
Failure threshold: 303.8 (50% of median)

> Soft beats = rotation applied to `crispEdges` pixel-art.
> Fix: use translation/scale only — never rotate. See PIXEL-ART LAW in
> `ClaudeMascotScene.tsx`.

| Beat | LV | % of median | Status |
|------|----|-------------|--------|
| B00 | 602.8 | 99% | PASS — 99% |
| B01 | 189.1 | 31% | PASS — 31% |
| B02 | 241.9 | 40% | PASS — 40% |
| B03 | 526.4 | 87% | PASS — 87% |
| B04 | 712.1 | 117% | PASS — 117% |
| B05 | 618.1 | 102% | PASS — 102% |
| B06 | 725.9 | 119% | PASS — 119% |
| B07 | 855.9 | 141% | PASS — 141% |
| B08 | 687.0 | 113% | PASS — 113% |
| B09 | 425.2 | 70% | PASS — 70% |
| B10 | 739.4 | 122% | PASS — 122% |
| B11 | 767.9 | 126% | PASS — 126% |
| B12 | 612.3 | 101% | PASS — 101% |
| B13 | 431.6 | 71% | PASS — 71% |
| B14 | 469.2 | 77% | PASS — 77% |
| B15 | 246.6 | 41% | SKIP (exempt — no pixel-art rotation possible) |
