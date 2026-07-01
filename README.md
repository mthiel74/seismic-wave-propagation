# Seismic Wave Propagation Across the Globe

**From First Principles — Earthquakes vs. Nuclear Explosions**

![Wolfram Language](https://img.shields.io/badge/Wolfram-Language-red)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

A from-scratch, reproducible account — in pure Wolfram Language — of how
seismic waves propagate through the Earth, and how the same physics lets a
seismic network tell an underground **nuclear explosion** apart from an
**earthquake**. Built as an educational [Wolfram Community](https://community.wolfram.com/)
post.

📄 **Read the post:** https://community.wolfram.com/groups/-/m/t/3742365

## What the project does

1. **Derives the two body waves** (P and S) from the elastic wave equation,
   with the consequences that fall straight out — `vP > vS` always, and
   `vS = 0` in the liquid outer core.
2. **Implements the PREM velocity model** (Dziewonski & Anderson 1981) layer
   by layer, with the inner-core boundary, core–mantle boundary and the
   410/660 km mantle discontinuities.
3. **Ray-traces the spherical Earth.** The ray parameter `p = r·sin(i)/v(r)`
   is conserved; the epicentral distance Δ(p) and travel time T(p) follow as
   integrals over the up-going path. The integrable turning-point singularity
   is removed with the substitution `r = r_tp + ξ²`.
4. **Validates against IASP91.** The computed direct-branch P times agree with
   the IASP91 standard to within ~4 s across 30–90°; the S/P ratio comes out
   at 1.84, the expected mantle value.
5. **Animates global wavefronts** — an IRIS-style **Ground Motion
   Visualization** of the Myanmar M7.7 sweeping across the European seismic
   network (`docs/images/SeismicGMV.mp4`), the same event as idealized P/S/
   Rayleigh fronts on a relief-map globe, and the **earthquake-vs-explosion**
   comparison that shows an explosion radiating *only* a P-front.
6. Covers **energy–magnitude scaling** (Kanamori), **supershear** Mach cones
   (Myanmar M7.7), the **mb–yield** calibration (Murphy 1996) and the classic
   **mb–Ms discrimination** used in nuclear test-ban verification.
7. Produces a self-contained **Wolfram Community notebook** as the end-product
   (`community/seismic_wave_propagation.nb`).

## Events studied

| Event | Magnitude | Type | Key feature |
|-------|-----------|------|-------------|
| Myanmar 2025 | M7.7 | Strike-slip | Supershear rupture, Mach cone |
| Venezuela 2026 | M7.5 | Strike-slip | Twin quakes 39 s apart |
| Crete 2025 | M6.0 | Normal | Felt across the Mediterranean |
| Tohoku 2011 | M9.1 | Megathrust | Devastating tsunami |
| Sumatra 2004 | M9.1 | Megathrust | Indian Ocean tsunami |
| Chile 1960 | M9.5 | Megathrust | Largest earthquake ever recorded |
| **DPRK 2017** | **mb 6.3** | **Nuclear test** | **250 kt, Punggye-ri** |

## Repository layout

The whole pipeline is pure Wolfram Language. Rendered figures and animations
are committed under `docs/images/` so the notebook can be rebuilt without
re-running the science.

| path | what lives there |
| --- | --- |
| `community/SeismicWavePropagation.wl` | function library: PREM model, ray tracing, travel-time integrals, event catalogue, energy/discrimination, GMV engine — imported by the notebook from the same folder |
| `community/seismic_wave_propagation.nb` / `.pdf` | the built notebook (committed output). It is **self-contained and runnable**: a Setup cell imports the `.wl`, and every figure/animation is produced by the call shown directly above it |
| `community/build_notebook.wls` | assembles the notebook from the prose + rendered figures |
| `wolfram/generate_figures.wls` | renders the computed figures + animations into `docs/images/` |
| `wolfram/fetch_real_data.wls` | fetches real seismograms (FDSN) → record section + single-station trace; writes `data/` CSVs |
| `wolfram/build_real_gmv.wls` | fetches real European station data → the real-data GMV |
| `data/` | committed tidy CSVs: fetched waveforms (`waveforms/`, `gmv_waveforms/`), station lists, manifests |
| `docs/images/` | rendered figures + animations referenced by the notebook and this README |
| `docs/images/SeismicGMV.mp4` | the full-resolution IRIS-style Ground Motion Visualization (pre-computed; `gmv_myanmar.gif` is the downsampled copy embedded in the notebook) |
| `tests/verify.wls` | scientific sanity checks (IASP91, energy ratios, mb–yield, supershear angle) |

## Reproducing

```sh
# 1. Render the computed figures + animations into docs/images/
#    (GeoGraphics figures need internet for the relief-map tiles)
wolframscript -file wolfram/generate_figures.wls  # loads community/SeismicWavePropagation.wl

# 2. Fetch real seismograms + build the record section and single-station
#    trace (needs internet; writes tidy CSVs to data/, figures to docs/images/)
wolframscript -file wolfram/fetch_real_data.wls

# 3. Fetch real European station data + build the real-data GMV
#    (needs internet; caches to data/gmv_waveforms/)
wolframscript -file wolfram/build_real_gmv.wls

# 4. Build the community notebook (writes community/seismic_wave_propagation.nb)
wolframscript -file community/build_notebook.wls

# 5. Run the scientific checks
wolframscript -file tests/verify.wls
```

The committed `data/` CSVs mean steps 2–3 only need to run once; the notebook's
`plotRecordSection[]`, `plotSingleStation[]` and `plotRealGMV[]` cells rebuild the
real-data figures from those CSVs with no network.

## Requirements

- **Wolfram Language** (Mathematica 14+ or Wolfram Engine)
- Internet connection for `GeoGraphics` relief-map tiles (the wavefront
  animations and the event map)

## References

1. Dziewonski, A. M. & Anderson, D. L. (1981). *Preliminary Reference Earth
   Model.* Phys. Earth Planet. Inter. 25, 297–356.
2. Shearer, P. M. (2009). *Introduction to Seismology.* Cambridge University Press.
3. Kennett, B. L. N. & Engdahl, E. R. (1991). Traveltimes for global earthquake
   location and phase identification (IASP91). Geophys. J. Int. 105, 429–465.
4. Kanamori, H. (1977). The energy release in great earthquakes. JGR 82, 2981–2987.
5. Murphy, J. R. (1996). Types of seismic events and their source descriptions.
   In *Monitoring a CTBT*, NATO ASI Series.

## Data and imagery credits

- **Seismograms** (record section, single-station trace, real-data GMV) — FDSN /
  IRIS-EarthScope `irisws-timeseries` service; networks GE (GEOFON), II (GSN/IDA),
  IU (GSN), MN (MedNet), CH, SL and others. Tidy CSVs are committed under `data/`.
- **Earthquake source parameters** — USGS and GCMT catalogues (event `us7000pn9s`).
- **Base maps** — rendered with Wolfram Language `GeoGraphics` (relief and
  country-border styling).
- **Reference model** — PREM (Dziewonski & Anderson 1981); reference travel times
  IASP91 (Kennett & Engdahl 1991).
- The **synthetic GMV** uses no real data — its station network and seismograms are
  generated from the PREM travel-time model.

The code is MIT-licensed; committed data are public-domain facts (USGS) or open
FDSN waveforms redistributed with attribution to the network operators above.

## License

MIT License — see [LICENSE](LICENSE).
