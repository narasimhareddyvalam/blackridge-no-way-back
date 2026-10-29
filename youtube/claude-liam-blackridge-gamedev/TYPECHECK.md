# TYPECHECK.md — GATE T

Reel: `claude-liam-blackridge-gamedev`  |  Checked: 2026-10-29T17:15  |  Overall: PASS  |  Beats checked: 29  |  FAILs: 0

Spec: `skills/make/kerning/reference/type-spec.md` §8.  Floor: 1.9% frame-height.  Contrast: 4.5:1 WCAG.  Kern threshold: 3.5× expected advance.  Wordy budget: 2 elements.

| beat | lane | polarity | worst finding | status | fix |
|------|------|----------|---------------|--------|-----|
| B00 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeComposerAsk) — §8.1 hachure/crossbar fragments ar… | PASS | — |
| B01 | ? | light | min-size §8.1: min text-run height 68px >= floor 41px | PASS | — |
| B02 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B03 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B04 | ? | light | no-wordy-card §8.5: pull-quote (11 words ≤ 12) | PASS | — |
| B05 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B06 | ? | light | no-wordy-card §8.5: pull-quote (4 words ≤ 12) | PASS | — |
| B07 | ? | light | no-wordy-card §8.5: pull-quote (9 words ≤ 12) | PASS | — |
| B08 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B09 | ? | light | no-wordy-card §8.5: pull-quote (6 words ≤ 12) | PASS | — |
| B10 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B11 | ? | light | no-wordy-card §8.5: pull-quote (8 words ≤ 12) | PASS | — |
| B12 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B13 | ? | light | no-wordy-card §8.5: pull-quote (7 words ≤ 12) | PASS | — |
| B14 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B15 | ? | light | no-wordy-card §8.5: pull-quote (8 words ≤ 12) | PASS | — |
| B16 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B17 | ? | light | no-wordy-card §8.5: pull-quote (7 words ≤ 12) | PASS | — |
| B18 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B19 | ? | light | no-wordy-card §8.5: pull-quote (11 words ≤ 12) | PASS | — |
| B20 | ? | light | no-wordy-card §8.5: pull-quote (11 words ≤ 12) | PASS | — |
| B21 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B22 | ? | light | no-wordy-card §8.5: pull-quote (9 words ≤ 12) | PASS | — |
| B23 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B24 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B25 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B26 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeVerdictArtifact) — §8.1 hachure/crossbar fragment… | PASS | — |
| B27 | ? | light | min-size §8.1: hand-drawn pattern (ClaudeComposerAsk) — §8.1 hachure/crossbar fragments ar… | PASS | — |
| B28 | ? | dark | min-size §8.1: min text-run height 44px >= floor 41px | PASS | — |

---

## Failures requiring action before cut

*None — GATE T PASS.*
---

## Check summary

| Check | Beats checked | FAILs |
|-------|---------------|-------|
| no-wordy-card §8.5 | 24 | 0 |
| min-size §8.1 | 29 | 0 |
| overflow §8.2 | 29 | 0 |
| contrast §8.3 | 29 | 0 |
| contrast-local §8.3b | 29 | 0 |
| bbox-overlap §8.6b | 29 | 0 |
| card-clip §8.13 | 29 | 0 |
| kerning §8.4 | 0 | 0 |
| redundancy §8.10 (advisory) | 1 | 0 (advisory — no exit effect) |

---

*GATE T: any FAIL blocks `./art run` and `./art final`. Fix the flagged beats and re-run `scripts/type_check.py` until green.*
