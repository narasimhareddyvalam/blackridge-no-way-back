# scene-source — toolkit changes made for this film

This film was built with the Brutalist toolkit (`brutalist.art`, commit `6a8380a`). The build
needed these local changes, which are snapshotted here so the film can be rebuilt; they were
not pushed to the toolkit:

- `GodotEngineEvidence.tsx`: a new shared Remotion component for the visible-result half of a
  code/result pair. It shows engine footage and stills with provenance labels, a row-by-row
  capture grid, cue-revealed cards and a verbatim document view. It is registered in Root.tsx
  in 16:9 and 9:16.
- `toolkit-changes.patch` (`git diff` in the toolkit):
  - the Root.tsx registration;
  - GodotDevWorkbench's opt-in `dense` prop and `//` comment highlighting;
  - type_check.py image-content exemptions for GodotEngineEvidence's media slots, mirroring
    GodotDesignFigure.

The reasons for each change are in ../BUILD-LOG.md.
