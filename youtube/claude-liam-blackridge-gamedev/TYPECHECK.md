# TYPECHECK.md — GATE T

Reel: `claude-liam-blackridge-gamedev`  |  Checked: 2026-10-29T16:35  |  Overall: **FAIL**  |  Beats checked: 29  |  FAILs: 4

Spec: `skills/make/kerning/reference/type-spec.md` §8.  Floor: 1.9% frame-height.  Contrast: 4.5:1 WCAG.  Kern threshold: 3.5× expected advance.  Wordy budget: 2 elements.

| beat | lane | polarity | worst finding | status | fix |
|------|------|----------|---------------|--------|-----|
| B00 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeComposerAsk) — §8.1 hachure/crossbar fragments ar… | PASS | — |
| B01 | ? | light | min-size §8.1: min text-run height 68px >= floor 41px | PASS | — |
| B02 | ? | light | min-size §8.1: smallest text run 37px < floor 41px (1.9% of 2160px logical); likely a capt… | **FAIL** | Increase font_size in scenes.py or Remotion component |
| B03 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B04 | ? | light | no-wordy-card §8.5: pull-quote (11 words ≤ 12) | PASS | — |
| B05 | ? | light | contrast-local §8.3b: per-blob contrast 1.15:1 < 3.0:1 — text unreadable on actual local b… | **FAIL** | Use INK on cream; add backing plate under accent text |
| B06 | ? | light | no-wordy-card §8.5: prose element 'note': 13 words > 12 pull-quote limit. The screen shoul… | **FAIL** | De-wordify → Manim diagram or Remotion build-on |
| B07 | ? | light | no-wordy-card §8.5: pull-quote (9 words ≤ 12) | PASS | — |
| B08 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B09 | ? | light | no-wordy-card §8.5: pull-quote (6 words ≤ 12) | PASS | — |
| B10 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B11 | ? | light | no-wordy-card §8.5: prose element 'output[0]': 14 words > 12 pull-quote limit. The screen … | **FAIL** | De-wordify → Manim diagram or Remotion build-on |
| B12 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B13 | ? | light | no-wordy-card §8.5: pull-quote (7 words ≤ 12) | PASS | — |
| B14 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B15 | ? | light | no-wordy-card §8.5: pull-quote (8 words ≤ 12) | PASS | — |
| B16 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B17 | ? | light | no-wordy-card §8.5: pull-quote (7 words ≤ 12) | PASS | — |
| B18 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B19 | ? | light | no-wordy-card §8.5: pull-quote (11 words ≤ 12) | PASS | — |
| B20 | ? | light | no-wordy-card §8.5: pull-quote (11 words ≤ 12) | PASS | — |
| B21 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B22 | ? | light | no-wordy-card §8.5: pull-quote (9 words ≤ 12) | PASS | — |
| B23 | ? | — | no-wordy-card §8.5: no prose payload found | PASS | — |
| B24 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B25 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B26 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeVerdictArtifact) — §8.1 hachure/crossbar fragment… | PASS | — |
| B27 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeComposerAsk) — §8.1 hachure/crossbar fragments ar… | PASS | — |
| B28 | ? | dark | min-size §8.1: min text-run height 44px >= floor 41px | PASS | — |

---

## Failures requiring action before cut

### B02 (?)
- **min-size §8.1**: smallest text run 37px < floor 41px (1.9% of 2160px logical); likely a caption/label too small — increase font_size or check if this is a data label needing §7 treatment
- **contrast-local §8.3b**: per-blob contrast 1.04:1 < 3.0:1 — text unreadable on actual local background (blob@(1133,1762)–(1270,1823) fg≈(37, 43, 45) bg≈(34, 40, 45)); move label off its background or change text color
- **Fix:** Increase font_size in scenes.py or Remotion component

### B05 (?)
- **contrast-local §8.3b**: per-blob contrast 1.15:1 < 3.0:1 — text unreadable on actual local background (blob@(297,686)–(530,747) fg≈(26, 31, 43) bg≈(11, 17, 24)); move label off its background or change text color
- **Fix:** Use INK on cream; add backing plate under accent text

### B06 (?)
- **no-wordy-card §8.5**: prose element 'note': 13 words > 12 pull-quote limit. The screen should show structure, not sentences. De-wordify: shorten to a label or rebuild beat as a Manim/Remotion visual.
- **min-size §8.1**: smallest text run 37px < floor 41px (1.9% of 2160px logical); likely a caption/label too small — increase font_size or check if this is a data label needing §7 treatment
- **Fix:** De-wordify → Manim diagram or Remotion build-on

### B11 (?)
- **no-wordy-card §8.5**: prose element 'output[0]': 14 words > 12 pull-quote limit. The screen should show structure, not sentences. De-wordify: shorten to a label or rebuild beat as a Manim/Remotion visual.
- **Fix:** De-wordify → Manim diagram or Remotion build-on

---

## Check summary

| Check | Beats checked | FAILs |
|-------|---------------|-------|
| no-wordy-card §8.5 | 24 | 2 |
| min-size §8.1 | 21 | 2 |
| overflow §8.2 | 21 | 0 |
| contrast §8.3 | 21 | 0 |
| contrast-local §8.3b | 21 | 2 |
| bbox-overlap §8.6b | 21 | 0 |
| card-clip §8.13 | 21 | 0 |
| kerning §8.4 | 0 | 0 |
| redundancy §8.10 (advisory) | 1 | 0 (advisory — no exit effect) |

---

*GATE T: any FAIL blocks `./art run` and `./art final`. Fix the flagged beats and re-run `scripts/type_check.py` until green.*
