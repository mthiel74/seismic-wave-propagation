# Repo notes for Claude

## Purpose

Produce a Wolfram Community post — `community/seismic_wave_propagation.nb` —
on seismic wave propagation from first principles: how the elastic wave
equation, the PREM velocity model and ray theory combine to explain
global travel times, and how the same physics distinguishes earthquakes
from underground nuclear explosions (the mb–Ms / P-vs-S test-ban
discrimination problem).

Pure Wolfram Language, no Python.

## Pipeline

```
community/SeismicWavePropagation.wl function library (next to the notebook, so
                                    the post imports it from the same folder):
                                    PREM model, ray tracing, travel-time
                                    integrals, event catalog, energy /
                                    discrimination, GMV engine. Computes the
                                    P/S travel-time curves on load (~30 s).
        │
wolfram/fetch_real_data.wls         Fetch real seismograms (FDSN/IRIS) for
                                    the Mandalay M7.7 -> record section +
                                    single-station trace. Writes data/ CSVs.
wolfram/build_real_gmv.wls          Fetch real European station LHZ -> the
                                    real-data GMV (via gmvFrame). Caches to
                                    data/gmv_waveforms/.
wolfram/generate_figures.wls        Get[] the library, render the computed
                                    figures + animations into docs/images/.
                                    GeoGraphics figures need
                                    internet (relief-map tiles).
        │
community/build_notebook.wls        Assemble the notebook from the prose +
                                    docs/images/*. Imports the rendered
                                    PNG/GIF — does NOT recompute the
                                    science. Writes the .nb and .pdf.

tests/verify.wls                    P/S travel times vs IASP91, energy
                                    ratios, mb–yield, supershear angle.
```

## Scientific core (do not regress)

The travel-time integrals Δ(p), T(p) use the substitution `r = rtp + ξ²`
to remove the integrable `1/√(η²−p²)` singularity at the turning point.
The earlier `eps`-offset scheme truncated that singularity and produced
travel times that were ~2× too large and non-monotonic. The ray models
`vpRay`/`vsRay` are dedicated monotonic order-1 interpolations (velocity
discontinuities split across a 1 m gap, e.g. 5701.0 / 5701.001) so that
η(r)=r/v(r) is single-valued and increasing — otherwise `√(η²−p²)` goes
complex just above each discontinuity. Validation: direct-branch P agrees
with IASP91 to within ~4 s over 30–90°; S/P ≈ 1.84.

`vpPREM`/`vsPREM` (exact piecewise, with jumps) are for **plotting only**.
`vpRay`/`vsRay` (monotonic) are for the **travel-time integration only**.

**Real data** (from FDSN/IRIS `irisws-timeseries`, LHZ 1 sps, band-passed
0.02–0.1 Hz): the record section, single-station trace and real GMV read
committed `data/` CSVs via `plotRecordSection[]`, `plotSingleStation[]`,
`plotRealGMV[]`. Two runtime gotchas learned here: (1) `Return` inside `Do`
does NOT exit the enclosing Module in this WL build — use `Catch`/`Throw` in
fetch loops; (2) `gmvFrame` needed `Map[#>0.05&, Abs[vals]]` (Greater is not
Listable) or every frame rendered blank.

## Conventions

* Plain-text `.wls`/`.wl` is the source of truth. The `.nb` and `.pdf` in
  `community/` are committed *outputs*.
* Figures live in `docs/images/` — referenced from both the README and the
  notebook.
* The notebook uses the RiverNetworkStatistics stylesheet (teal Roboto
  Condensed headings `RGBColor[0.153, 0.51, 0.64]`, Source Sans Pro code).
* Embedded animations: `AnimatedImage` with `ColorQuantize` per frame, and
  the notebook is saved via `UsingFrontEnd` + `CreateDocument` +
  `NotebookSave` (NOT `Export[file.nb, …]`) so the animations persist.
* No "how to cite" section. End matter is References + Reproducibility.
* The notebook is **runnable**: a "Setup" section imports the `.wl` via
  `SetDirectory[NotebookDirectory[]]; Get["SeismicWavePropagation.wl"]`, and
  `build_notebook.wls` places a `codeIn[...]` Input cell (the exact library
  call, comments preserved) directly above every figure/animation Output.
  The `.wl` therefore MUST live in `community/` next to the `.nb`. The hero
  banner at the top is the one exception (no code cell — its call is shown in
  §7).
* The hero §7 animation is the IRIS-style GMV (`docs/images/SeismicGMV.mp4`,
  computed separately by the library's GMV engine on the mac mini — NOT
  produced by `generate_figures.wls`). `gmv_myanmar.gif` is a downsampled
  copy (`ffmpeg fps=3 scale=600`) that `build_notebook.wls` embeds as an
  AnimatedImage. Keep both the .mp4 (full res) and the .gif (embed).
