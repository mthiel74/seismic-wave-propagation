# Seismic Wave Propagation Across the Globe

**From First Principles — Earthquakes vs. Nuclear Explosions**

![Wolfram Language](https://img.shields.io/badge/Wolfram-Language-red)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

## Overview

This project builds a physics-based model of seismic wave propagation from first principles, applied to six major earthquakes spanning four orders of magnitude in energy — from a moderate M6.0 in the Mediterranean to the largest earthquake ever recorded (Chile 1960, M9.5). The model produces animated ground-motion visualizations showing P-waves, S-waves, and surface waves sweeping across the globe.

We then compare these natural events with underground nuclear explosions, showing how seismology distinguishes bombs from earthquakes — a question at the heart of nuclear test-ban verification.

## Events Studied

| Event | Magnitude | Type | Key Feature |
|-------|-----------|------|-------------|
| Myanmar 2025 | M7.7 | Strike-slip | Supershear rupture, Mach cone |
| Venezuela 2026 | M7.5 | Strike-slip | Twin quakes 39s apart |
| Crete 2025 | M6.0 | Normal | Felt across Mediterranean |
| Tohoku 2011 | M9.1 | Megathrust | Devastating tsunami |
| Sumatra 2004 | M9.1 | Megathrust | Indian Ocean tsunami |
| Chile 1960 | M9.5 | Megathrust | Largest earthquake ever |
| **DPRK 2017** | **mb 6.3** | **Nuclear test** | **250 kt, Punggye-ri** |

## The Model

The notebook develops the following chain of reasoning:

1. **Elastic Wave Equation** → Two body-wave solutions (P and S) plus surface waves (Rayleigh, Love)
2. **PREM Velocity Model** → Seismic velocity as a function of depth, with major discontinuities (ICB, CMB, 670 km, 400 km, 220 km)
3. **Ray Theory in Spherical Earth** → Snell's law gives the ray parameter *p = r sin(i) / v(r)*, conserved along each ray path
4. **Travel-Time Integrals** → Numerical computation of Δ(p) and T(p) via NIntegrate, split at layer boundaries
5. **Energy-Magnitude Scaling** → Kanamori relation log₁₀(E) = 1.5 Mw + 4.8, comparison with nuclear yield
6. **Multi-Event Animation** → Wavefronts for all six earthquakes + nuclear test on GeoGraphics
7. **Supershear Analysis** → Mach cone geometry for Myanmar (v_rupture ≈ 5.5 km/s > v_S)
8. **Nuclear Test Seismology** → mb-yield relation, isotropic source model, P/S discrimination
9. **mb-Ms Discrimination** → The classic test-ban verification technique separating explosions from earthquakes

## Key Equations

**Ray parameter (Snell's law in spherical coordinates):**
```
p = r sin(i) / v(r) = const.
```

**Epicentral distance:**
```
Δ(p) = 2 ∫[r_tp → R] p / (r √(η² − p²)) dr
```

**Travel time:**
```
T(p) = 2 ∫[r_tp → R] η² / (r √(η² − p²)) dr
```

**Seismic energy (Kanamori 1977):**
```
log₁₀(E) = 1.5 Mw + 4.8    (E in Joules)
```

**Nuclear yield-magnitude (Murphy 1996):**
```
mb = 4.45 + 0.75 log₁₀(Y)   (Y in kilotons)
```

**Supershear Mach angle:**
```
θ = arcsin(v_S / v_rupture) ≈ 39.5°
```

## Key Results

- **Travel times** agree with IASP91 empirical tables to within a few seconds
- **Chile M9.5** released ~10,700× more energy than the DPRK 250 kt nuclear test
- **Tohoku M9.1** released ~2,700× more energy than the nuclear test
- The **mb-Ms discrimination** clearly separates earthquakes from nuclear explosions
- Nuclear tests produce **only P-wave** fronts — no S-wave or surface wave fronts — a striking visual confirmation of the source physics

## Requirements

- **Wolfram Language** (Mathematica 13+ or Wolfram Cloud)
- Internet connection (for `GeoGraphics` map tiles)

## Usage

1. Open `SeismicWavePropagation.wl` in Mathematica
2. Evaluate all cells (Evaluation → Evaluate Notebook)
3. Ray-tracing computation takes approximately 5–10 minutes
4. Interactive animations are generated via `Manipulate`
5. Animated GIFs are exported automatically

## Output

| Output | Description |
|--------|-------------|
| PREM velocity profiles | P-wave, S-wave, and density vs. radius |
| Earth cross-section | Color-coded velocity structure |
| Ray path diagram | P-wave rays at different incidence angles |
| Travel-time curves | T(Δ) for P, S, Rayleigh, Love waves |
| Event map | All 7 events on Robinson projection |
| Energy comparison | Log-scale bar chart, earthquake vs. nuclear yield |
| Multi-event animation | Interactive globe/flat map with event selector |
| Mediterranean zoom | Regional view for Crete M6.0 |
| Supershear Mach cone | Myanmar rupture visualization |
| mb-yield plot | Nuclear test calibration curve |
| mb-Ms discrimination | Earthquake vs. explosion populations |
| Source mechanism diagrams | Double-couple vs. isotropic radiation |
| Verification table | PREM model vs. IASP91 empirical times |
| City arrival times | P-wave arrivals at 8 cities for all events |
| Exported GIFs | Myanmar animation + earthquake vs. nuclear comparison |

## References

1. Dziewonski, A.M. & Anderson, D.L. (1981). "Preliminary Reference Earth Model." *Physics of the Earth and Planetary Interiors*, 25, 297–356.
2. Shearer, P.M. (2009). *Introduction to Seismology*. Cambridge University Press.
3. Kennett, B.L.N. & Engdahl, E.R. (1991). "Traveltimes for global earthquake location and phase identification." *Geophysical Journal International*, 105, 429–465.
4. Murphy, J.R. (1996). "Types of seismic events and their source descriptions." *Monitoring a CTBT*, NATO ASI Series.
5. Ringdal, F. (1986). "Study of magnitudes, seismicity, and earthquake detectability using a global network." *Bull. Seismol. Soc. Am.*, 76, 1641–1659.
6. CTBTO. [Seismic Monitoring](https://www.ctbto.org/our-work/monitoring-technologies/seismic-monitoring).
7. IRIS DMC. [Ground Motion Visualization (GMV)](https://ds.iris.edu/ds/products/gmv/).

## License

MIT License — see [LICENSE](LICENSE) for details.

## Wolfram Community

This project was developed for publication on the [Wolfram Community](https://community.wolfram.com/).
