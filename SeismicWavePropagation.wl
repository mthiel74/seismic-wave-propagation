(* ::Package:: *)

(* ====================================================================== *)
(*  SEISMIC WAVE PROPAGATION ACROSS THE GLOBE:                           *)
(*  From First Principles — Earthquakes vs. Nuclear Explosions           *)
(* ====================================================================== *)
(*  Author: Marco Thiel                                                   *)
(*  Date: June 2026                                                       *)
(*  For publication on the Wolfram Community                              *)
(* ====================================================================== *)
(*                                                                        *)
(*  When an earthquake strikes, seismometers worldwide record the         *)
(*  passage of seismic waves — and the resulting "ground motion           *)
(*  visualizations" (GMVs) have become viral: animated maps showing      *)
(*  the ground being lifted (red) and pushed down (blue) as waves        *)
(*  sweep across continents.                                              *)
(*                                                                        *)
(*  In this notebook we build such visualizations FROM FIRST             *)
(*  PRINCIPLES. Starting from the elastic wave equation and the PREM     *)
(*  velocity model, we derive seismic travel-time curves via ray         *)
(*  theory, then animate the resulting wavefronts on a 3D globe for      *)
(*  six different earthquakes — from a moderate M6.0 in the              *)
(*  Mediterranean to the largest earthquake ever recorded (Chile 1960,   *)
(*  M9.5).                                                                *)
(*                                                                        *)
(*  We then compare these natural events with underground nuclear        *)
(*  explosions, showing how seismology distinguishes bombs from          *)
(*  earthquakes — a question at the heart of nuclear test-ban            *)
(*  verification.                                                         *)
(*                                                                        *)
(*  The approach:                                                         *)
(*   1. Catalog six earthquakes spanning M6.0 to M9.5                    *)
(*   2. Implement the PREM velocity model from tabulated data            *)
(*   3. Derive travel times via ray-theoretic integrals                  *)
(*   4. Animate wavefronts for each event on GeoGraphics                 *)
(*   5. Compare seismic energy across 4 orders of magnitude              *)
(*   6. Model the 2025 Myanmar supershear rupture                        *)
(*   7. Compare earthquakes with the 2017 DPRK nuclear test              *)
(*   8. Derive the mb-Ms discrimination used for test-ban verification   *)
(* ====================================================================== *)


(* ====================================================================== *)
(*  SECTION 1: THE EARTHQUAKE CATALOG                                     *)
(* ====================================================================== *)

(*
   We study six earthquakes chosen to span a wide range of magnitudes,
   tectonic settings, and geographic locations, plus one underground
   nuclear test for comparison.

   Note: Wolfram's EarthquakeData is known to have gaps for major
   historical events (see Ammon 2017), so we hardcode all parameters
   from the USGS/GCMT catalogs for reliability.
*)

earthquakeCatalog = {
  <|"Name" -> "2025 Myanmar M7.7",
    "ShortName" -> "Myanmar 2025",
    "Magnitude" -> 7.7, "MagnitudeType" -> "Mw",
    "Position" -> GeoPosition[{21.88, 96.01}],
    "Depth" -> 10, (* km *)
    "Year" -> 2025,
    "Mechanism" -> "Strike-Slip",
    "Strike" -> 340, "Dip" -> 89, "Rake" -> 180,
    "FaultName" -> "Sagaing Fault",
    "Notes" -> "Supershear rupture, 530 km fault length, Mach cone"|>,

  <|"Name" -> "2026 Venezuela M7.5",
    "ShortName" -> "Venezuela 2026",
    "Magnitude" -> 7.5, "MagnitudeType" -> "Mw",
    "Position" -> GeoPosition[{10.56, -68.87}],
    "Depth" -> 10,
    "Year" -> 2026,
    "Mechanism" -> "Strike-Slip",
    "Strike" -> 90, "Dip" -> 85, "Rake" -> 175,
    "FaultName" -> "San Sebastian Fault",
    "Notes" -> "Twin quakes M7.2+M7.5 separated by 39 seconds"|>,

  <|"Name" -> "2025 Crete M6.0",
    "ShortName" -> "Crete 2025",
    "Magnitude" -> 6.0, "MagnitudeType" -> "Mw",
    "Position" -> GeoPosition[{34.87, 26.65}],
    "Depth" -> 65,
    "Year" -> 2025,
    "Mechanism" -> "Normal",
    "Strike" -> 260, "Dip" -> 40, "Rake" -> -90,
    "FaultName" -> "Hellenic Subduction Zone",
    "Notes" -> "Felt across the Mediterranean, as far as Egypt"|>,

  <|"Name" -> "2011 Tohoku M9.1",
    "ShortName" -> "Tohoku 2011",
    "Magnitude" -> 9.1, "MagnitudeType" -> "Mw",
    "Position" -> GeoPosition[{38.30, 142.37}],
    "Depth" -> 29,
    "Year" -> 2011,
    "Mechanism" -> "Megathrust",
    "Strike" -> 193, "Dip" -> 10, "Rake" -> 88,
    "FaultName" -> "Japan Trench",
    "Notes" -> "Devastating tsunami, Fukushima disaster"|>,

  <|"Name" -> "2004 Sumatra M9.1",
    "ShortName" -> "Sumatra 2004",
    "Magnitude" -> 9.1, "MagnitudeType" -> "Mw",
    "Position" -> GeoPosition[{3.30, 95.98}],
    "Depth" -> 30,
    "Year" -> 2004,
    "Mechanism" -> "Megathrust",
    "Strike" -> 329, "Dip" -> 8, "Rake" -> 110,
    "FaultName" -> "Sunda Trench",
    "Notes" -> "Indian Ocean tsunami, ~280,000 deaths"|>,

  <|"Name" -> "1960 Chile M9.5",
    "ShortName" -> "Chile 1960",
    "Magnitude" -> 9.5, "MagnitudeType" -> "Mw",
    "Position" -> GeoPosition[{-38.14, -73.41}],
    "Depth" -> 25,
    "Year" -> 1960,
    "Mechanism" -> "Megathrust",
    "Strike" -> 10, "Dip" -> 20, "Rake" -> 90,
    "FaultName" -> "Chile Trench",
    "Notes" -> "Largest earthquake ever recorded, 9.5 Mw"|>
};

(* North Korea underground nuclear test *)
nuclearTest = <|"Name" -> "2017 DPRK Nuclear Test",
  "ShortName" -> "DPRK 2017",
  "MagnitudeBody" -> 6.3,       (* mb, body wave magnitude *)
  "MagnitudeSurface" -> 4.2,    (* Ms, surface wave magnitude *)
  "Position" -> GeoPosition[{41.33, 129.03}],
  "Depth" -> 0.5,               (* km, very shallow *)
  "Year" -> 2017,
  "YieldKt" -> 250,             (* kilotons TNT *)
  "TestSite" -> "Punggye-ri",
  "Notes" -> "Largest DPRK test, hydrogen bomb, caused mountain collapse"|>;

(* Combined event list for comparative analysis *)
allEvents = Join[earthquakeCatalog, {nuclearTest}];


(* ---- Display the catalog ---- *)

Print[Style["EARTHQUAKE AND NUCLEAR TEST CATALOG", Bold, 16]];
Print[""];

Grid[
  Prepend[
    Table[{eq["ShortName"],
      If[KeyExistsQ[eq, "Magnitude"], eq["Magnitude"], eq["MagnitudeBody"]],
      If[KeyExistsQ[eq, "Mechanism"], eq["Mechanism"], "Explosion"],
      eq["Depth"],
      If[KeyExistsQ[eq, "FaultName"], eq["FaultName"], eq["TestSite"]]},
      {eq, allEvents}],
    {"Event", "Mag", "Type", "Depth (km)", "Source"}
  ],
  Frame -> All,
  Background -> {None, {LightBlue, None}},
  Alignment -> {Left, Center},
  Spacings -> {2, 1}
]


(* ---- Global map of all events ---- *)

eventMap = GeoGraphics[{
  (* Earthquake epicenters *)
  Table[
    With[{eq = earthquakeCatalog[[i]]},
      {Directive[Red, PointSize[0.005 + 0.003 (eq["Magnitude"] - 6)]],
       Point[eq["Position"]],
       Text[Style[eq["ShortName"], 8, Bold],
         eq["Position"], {-1.5, -1}]}
    ],
    {i, Length[earthquakeCatalog]}
  ],

  (* Nuclear test site *)
  {Directive[Black, PointSize[0.012]],
   Point[nuclearTest["Position"]],
   Text[Style[nuclearTest["ShortName"], 8, Bold, Darker[Red]],
     nuclearTest["Position"], {-1.5, -1}]}
},
GeoRange -> "World",
GeoProjection -> "Robinson",
GeoBackground -> GeoStyling["ReliefMap"],
PlotLabel -> Style["Events Studied: 6 Earthquakes + 1 Nuclear Test", Bold, 14],
ImageSize -> 800]


(* ====================================================================== *)
(*  SECTION 2: THE PHYSICS OF SEISMIC WAVES                              *)
(* ====================================================================== *)

(*
   The propagation of seismic waves is governed by the elastodynamic
   wave equation. In a homogeneous, isotropic elastic medium with
   density \[Rho], bulk modulus K, and shear modulus \[Mu]:

   \[Rho] \!\(\*OverscriptBox[\(u\), \(\[DoubleDot]\)]\) =
     (\[Lambda] + 2\[Mu]) \[Del](\[Del]\[CenterDot]u)
     - \[Mu] \[Del]\[Cross](\[Del]\[Cross]u)

   This equation admits two types of body-wave solutions:

   P-waves (Primary/Compressional):
     v_P = Sqrt[(\[Lambda] + 2\[Mu]) / \[Rho]]
     Particle motion: parallel to wave propagation
     Fastest wave; arrives first at any seismometer

   S-waves (Secondary/Shear):
     v_S = Sqrt[\[Mu] / \[Rho]]
     Particle motion: perpendicular to wave propagation
     Cannot propagate through fluids (\[Mu] = 0)

   The velocity ratio:
     v_P / v_S = Sqrt[(2 - 2\[Nu]) / (1 - 2\[Nu])]
   where \[Nu] is Poisson's ratio. For typical rock (\[Nu] \[TildeTilde] 0.25):
     v_P / v_S \[TildeTilde] Sqrt[3] \[TildeTilde] 1.73

   Surface waves (Rayleigh and Love) are guided along the Earth's
   surface, travel slower than body waves, but carry the largest
   amplitudes and cause the most damage.

   KEY DISTINCTION: Earthquakes are double-couple sources (quadrupolar
   radiation pattern), while explosions are isotropic (uniform
   compression in all directions). This fundamental difference in
   source mechanism is what allows seismologists to distinguish
   nuclear tests from earthquakes.
*)


(* ====================================================================== *)
(*  SECTION 3: THE PREM VELOCITY MODEL                                   *)
(* ====================================================================== *)

(*
   The Preliminary Reference Earth Model (PREM) of Dziewonski & Anderson
   (1981) is the standard 1-D reference model for Earth's interior.
   It specifies P-wave velocity, S-wave velocity, density, and
   attenuation as functions of radius.

   PREM was constructed to simultaneously fit:
   - Free oscillation eigenfrequencies
   - Surface wave dispersion curves
   - Body wave travel times
   - Earth's mass (5.974 x 10^24 kg) and moment of inertia

   We implement PREM using tabulated values from the original paper,
   with separate Interpolation functions for each continuous layer.
   This correctly handles the velocity discontinuities at:
   - ICB (1221.5 km): solid inner core -> liquid outer core
   - CMB (3480 km):   liquid outer core -> solid lower mantle
   - 670 km (5701 km): ringwoodite -> bridgmanite phase transition
   - 400 km (5971 km): olivine -> wadsleyite phase transition
   - 220 km (6151 km): lithosphere-asthenosphere boundary
*)

rEarth = 6371.0; (* Earth's radius in km *)

(* ---- PREM Tabulated Data ---- *)
(* Format: {radius (km), Vp (km/s), Vs (km/s), density (g/cm^3)} *)

(* Inner Core: solid iron-nickel alloy, r = 0 to 1221.5 km *)
premInnerCore = {
  {0.0,    11.2622, 3.6678, 13.0885},
  {200.0,  11.26,   3.66,   13.08},
  {400.0,  11.24,   3.65,   13.05},
  {600.0,  11.21,   3.63,   13.01},
  {800.0,  11.16,   3.60,   12.95},
  {1000.0, 11.11,   3.56,   12.87},
  {1200.0, 11.04,   3.51,   12.77},
  {1221.5, 11.03,   3.50,   12.76}
};

(* Outer Core: liquid iron alloy (Vs = 0), r = 1221.5 to 3480 km *)
premOuterCore = {
  {1221.5, 10.36, 0.0, 12.17},
  {1400.0, 10.25, 0.0, 12.07},
  {1600.0, 10.12, 0.0, 11.95},
  {1800.0,  9.99, 0.0, 11.81},
  {2000.0,  9.84, 0.0, 11.65},
  {2200.0,  9.67, 0.0, 11.48},
  {2400.0,  9.48, 0.0, 11.29},
  {2600.0,  9.28, 0.0, 11.08},
  {2800.0,  9.05, 0.0, 10.85},
  {3000.0,  8.80, 0.0, 10.60},
  {3200.0,  8.51, 0.0, 10.33},
  {3400.0,  8.20, 0.0, 10.03},
  {3480.0,  8.06, 0.0,  9.90}
};

(* Lower Mantle: r = 3480 to 5701 km *)
premLowerMantle = {
  {3480.0, 13.72, 7.26, 5.57},
  {3600.0, 13.69, 7.27, 5.51},
  {3630.0, 13.68, 7.27, 5.49},
  {3800.0, 13.48, 7.19, 5.41},
  {4000.0, 13.25, 7.10, 5.31},
  {4200.0, 13.02, 7.01, 5.21},
  {4400.0, 12.78, 6.92, 5.11},
  {4600.0, 12.54, 6.83, 5.00},
  {4800.0, 12.29, 6.73, 4.90},
  {5000.0, 12.02, 6.62, 4.79},
  {5200.0, 11.73, 6.50, 4.68},
  {5400.0, 11.42, 6.38, 4.56},
  {5600.0, 11.07, 6.24, 4.44},
  {5701.0, 10.75, 5.95, 4.38}
};

(* Transition Zone: 670-400 km depth, r = 5701 to 5971 km *)
premTransitionZone = {
  {5701.0, 10.27, 5.57, 3.99},
  {5771.0, 10.16, 5.52, 3.98},
  {5800.0, 10.01, 5.43, 3.94},
  {5900.0,  9.50, 5.14, 3.81},
  {5971.0,  9.13, 4.93, 3.72}
};

(* Upper Mantle: 400-220 km depth, r = 5971 to 6151 km *)
premUpperMantle = {
  {5971.0, 8.91, 4.77, 3.54},
  {6000.0, 8.85, 4.75, 3.53},
  {6100.0, 8.66, 4.68, 3.47},
  {6151.0, 8.56, 4.64, 3.44}
};

(* LVZ + Lithosphere: 220-24.4 km depth, r = 6151 to 6346.6 km *)
premLithosphere = {
  {6151.0, 7.99, 4.42, 3.36},
  {6200.0, 8.02, 4.44, 3.36},
  {6291.0, 8.08, 4.47, 3.37},
  {6300.0, 8.08, 4.47, 3.38},
  {6346.6, 8.11, 4.49, 3.38}
};

(* Crust: r = 6346.6 to 6368 km *)
premCrust = {
  {6346.6, 6.80, 3.90, 2.90},
  {6356.0, 6.80, 3.90, 2.90},
  {6356.0, 5.80, 3.20, 2.60},
  {6368.0, 5.80, 3.20, 2.60}
};

(* Ocean: r = 6368 to 6371 km *)
premOcean = {
  {6368.0, 1.45, 0.0, 1.02},
  {6371.0, 1.45, 0.0, 1.02}
};


(* ---- Build Interpolation Functions ---- *)

premCol[data_, col_] := data[[All, {1, col}]];
interpOrder[data_] := Min[3, Length[data] - 1];

vpInterpIC  = Interpolation[premCol[premInnerCore, 2],     InterpolationOrder -> interpOrder[premInnerCore]];
vpInterpOC  = Interpolation[premCol[premOuterCore, 2],     InterpolationOrder -> 3];
vpInterpLM  = Interpolation[premCol[premLowerMantle, 2],   InterpolationOrder -> 3];
vpInterpTZ  = Interpolation[premCol[premTransitionZone, 2],InterpolationOrder -> 3];
vpInterpUM  = Interpolation[premCol[premUpperMantle, 2],   InterpolationOrder -> 3];
vpInterpLith= Interpolation[premCol[premLithosphere, 2],   InterpolationOrder -> 3];

vsInterpIC  = Interpolation[premCol[premInnerCore, 3],     InterpolationOrder -> interpOrder[premInnerCore]];
vsInterpOC  = Interpolation[premCol[premOuterCore, 3],     InterpolationOrder -> 3];
vsInterpLM  = Interpolation[premCol[premLowerMantle, 3],   InterpolationOrder -> 3];
vsInterpTZ  = Interpolation[premCol[premTransitionZone, 3],InterpolationOrder -> 3];
vsInterpUM  = Interpolation[premCol[premUpperMantle, 3],   InterpolationOrder -> 3];
vsInterpLith= Interpolation[premCol[premLithosphere, 3],   InterpolationOrder -> 3];

rhoInterpIC  = Interpolation[premCol[premInnerCore, 4],     InterpolationOrder -> interpOrder[premInnerCore]];
rhoInterpOC  = Interpolation[premCol[premOuterCore, 4],     InterpolationOrder -> 3];
rhoInterpLM  = Interpolation[premCol[premLowerMantle, 4],   InterpolationOrder -> 3];
rhoInterpTZ  = Interpolation[premCol[premTransitionZone, 4],InterpolationOrder -> 3];
rhoInterpUM  = Interpolation[premCol[premUpperMantle, 4],   InterpolationOrder -> 3];
rhoInterpLith= Interpolation[premCol[premLithosphere, 4],   InterpolationOrder -> 3];


(* ---- Piecewise PREM Velocity Functions ---- *)

Clear[vpPREM, vsPREM, rhoPREM];

vpPREM[r_?NumericQ] := Piecewise[{
  {vpInterpIC[r],   0     <= r <  1221.5},
  {vpInterpOC[r],   1221.5 <= r < 3480.0},
  {vpInterpLM[r],   3480.0 <= r < 5701.0},
  {vpInterpTZ[r],   5701.0 <= r < 5971.0},
  {vpInterpUM[r],   5971.0 <= r < 6151.0},
  {vpInterpLith[r], 6151.0 <= r < 6346.6},
  {6.80,            6346.6 <= r < 6356.0},
  {5.80,            6356.0 <= r < 6368.0},
  {1.45,            6368.0 <= r <= 6371.0}
}];

vsPREM[r_?NumericQ] := Piecewise[{
  {vsInterpIC[r],   0     <= r <  1221.5},
  {0.0,             1221.5 <= r < 3480.0},
  {vsInterpLM[r],   3480.0 <= r < 5701.0},
  {vsInterpTZ[r],   5701.0 <= r < 5971.0},
  {vsInterpUM[r],   5971.0 <= r < 6151.0},
  {vsInterpLith[r], 6151.0 <= r < 6346.6},
  {3.90,            6346.6 <= r < 6356.0},
  {3.20,            6356.0 <= r < 6368.0},
  {0.0,             6368.0 <= r <= 6371.0}
}];

rhoPREM[r_?NumericQ] := Piecewise[{
  {rhoInterpIC[r],   0     <= r <  1221.5},
  {rhoInterpOC[r],   1221.5 <= r < 3480.0},
  {rhoInterpLM[r],   3480.0 <= r < 5701.0},
  {rhoInterpTZ[r],   5701.0 <= r < 5971.0},
  {rhoInterpUM[r],   5971.0 <= r < 6151.0},
  {rhoInterpLith[r], 6151.0 <= r < 6346.6},
  {2.90,             6346.6 <= r < 6356.0},
  {2.60,             6356.0 <= r < 6368.0},
  {1.02,             6368.0 <= r <= 6371.0}
}];


(* ---- Visualize the PREM Model ---- *)

premPlotP = Plot[vpPREM[r], {r, 0, rEarth},
  PlotStyle -> {Blue, Thick},
  PlotRange -> {0, 14.5},
  ExclusionsStyle -> Dashed,
  AxesLabel -> {"Radius (km)", "Velocity (km/s)"},
  PlotLabel -> Style["PREM P-wave Velocity", Bold],
  Filling -> Axis,
  FillingStyle -> Directive[Blue, Opacity[0.1]],
  GridLines -> {{1221.5, 3480, 5701, 5971, 6151, 6346.6}, Automatic},
  GridLinesStyle -> Directive[Gray, Dashed],
  Epilog -> {
    Text[Style["Inner\nCore", 8], {600, 12}],
    Text[Style["Outer Core", 8], {2400, 4}],
    Text[Style["Lower Mantle", 8], {4600, 8}],
    Text[Style["UM", 8], {5850, 6}],
    Text[Style["Crust", 8], {6360, 3}]
  },
  ImageSize -> 700];

premPlotS = Plot[vsPREM[r], {r, 0, rEarth},
  PlotStyle -> {Red, Thick},
  PlotRange -> {0, 8},
  ExclusionsStyle -> Dashed,
  AxesLabel -> {"Radius (km)", "Velocity (km/s)"},
  PlotLabel -> Style["PREM S-wave Velocity", Bold],
  Filling -> Axis,
  FillingStyle -> Directive[Red, Opacity[0.1]],
  GridLines -> {{1221.5, 3480, 5701, 5971, 6151, 6346.6}, Automatic},
  GridLinesStyle -> Directive[Gray, Dashed],
  Epilog -> {Text[Style["S = 0\n(liquid)", 8, Red], {2400, 2}]},
  ImageSize -> 700];

premPlotRho = Plot[rhoPREM[r], {r, 0, rEarth},
  PlotStyle -> {Darker[Green], Thick},
  PlotRange -> {0, 14},
  ExclusionsStyle -> Dashed,
  AxesLabel -> {"Radius (km)", "Density (g/cm\[Superscript]3)"},
  PlotLabel -> Style["PREM Density", Bold],
  Filling -> Axis,
  FillingStyle -> Directive[Green, Opacity[0.1]],
  GridLines -> {{1221.5, 3480, 5701, 5971, 6151, 6346.6}, Automatic},
  GridLinesStyle -> Directive[Gray, Dashed],
  ImageSize -> 700];

GraphicsColumn[{premPlotP, premPlotS, premPlotRho}, Spacings -> 0]


(* ---- Cross-section visualization ---- *)

premCrossSection = Show[
  ParametricPlot[
    {r Cos[\[Theta]], r Sin[\[Theta]]},
    {r, 0, rEarth}, {\[Theta], 0, 2 Pi},
    ColorFunction -> (ColorData["TemperatureMap"][
      Rescale[vpPREM[Sqrt[#1^2 + #2^2]], {0, 14}]] &),
    ColorFunctionScaling -> False,
    PlotPoints -> {100, 60},
    PlotRange -> All,
    Frame -> False, Axes -> False
  ],
  Graphics[{
    {White, Thick, Circle[{0, 0}, 1221.5]},
    {White, Thick, Circle[{0, 0}, 3480]},
    {White, Thin,  Circle[{0, 0}, 5701]},
    {White, Thin,  Circle[{0, 0}, 5971]},
    {White, Thin,  Circle[{0, 0}, 6346.6]}
  }],
  PlotLabel -> Style["PREM Cross-Section (P-wave velocity)", Bold, 14],
  ImageSize -> 500
]


(* ====================================================================== *)
(*  SECTION 4: RAY THEORY AND TRAVEL TIMES                               *)
(* ====================================================================== *)

(*
   In a spherically symmetric Earth, seismic rays obey Snell's law
   in spherical coordinates. The ray parameter p is conserved:

     p = r sin(i) / v(r)    [units: seconds]

   Define the "eta" function:
     \[Eta](r) = r / v(r)

   Then the ray turns (i = \[Pi]/2) at the radius r_tp where
   \[Eta](r_tp) = p.

   The epicentral distance and travel time are:

     \[CapitalDelta](p) = 2 \[Integral] from r_tp to R of
       p / (r Sqrt[\[Eta](r)^2 - p^2]) dr

     T(p) = 2 \[Integral] from r_tp to R of
       \[Eta](r)^2 / (r Sqrt[\[Eta](r)^2 - p^2]) dr

   IMPORTANT: These integrals depend ONLY on the velocity model, NOT
   on the specific earthquake. The travel-time curves T(\[CapitalDelta])
   are universal for a given Earth model. What varies between events
   is the epicenter location, radiation pattern, and amplitude.
*)


(* ---- Eta functions ---- *)

etaP[r_?NumericQ] := r / vpPREM[r];
etaS[r_?NumericQ] := r / vsPREM[r] /; vsPREM[r] > 0;

(* Layer boundaries in the mantle *)
mantleBoundaries = {3480.0, 5701.0, 5971.0, 6151.0, 6346.6};
rSource = 6346.6; (* Source at Moho *)

nLayers = Length[mantleBoundaries] - 1;
layerBottom[k_] := mantleBoundaries[[k]];
layerTop[k_]    := mantleBoundaries[[k + 1]];

(* Find which layer contains the turning point *)
turningLayer[p_, vFunc_] := Module[{k},
  For[k = 1, k <= nLayers, k++,
    If[layerTop[k] / vFunc[layerTop[k] - 0.01] < p,
      Return[k]
    ];
  ];
  nLayers
];

(* Find the turning point radius *)
findTurningPoint[p_, vFunc_] := Module[{rLow, rHigh, layerIdx, eta},
  layerIdx = turningLayer[p, vFunc];
  rLow  = layerBottom[layerIdx] + 0.1;
  rHigh = layerTop[layerIdx] - 0.1;
  eta[r_?NumericQ] := r / vFunc[r];
  r /. FindRoot[eta[r] - p, {r, (rLow + rHigh) / 2, rLow, rHigh},
    Method -> "Brent"]
];

(* Compute ray path: Delta(p) and T(p) *)
computeRayPath[p_?NumericQ, vFunc_] := Module[
  {rtp, layerIdx, delta = 0., ttime = 0.,
   rBot, rTop, eta, integrandDelta, integrandT, eps = 0.01},

  rtp = findTurningPoint[p, vFunc];
  layerIdx = turningLayer[p, vFunc];
  eta[r_?NumericQ] := r / vFunc[r];

  integrandDelta[r_?NumericQ] := p / (r Sqrt[eta[r]^2 - p^2]);
  integrandT[r_?NumericQ] := eta[r]^2 / (r Sqrt[eta[r]^2 - p^2]);

  (* Turning layer integral *)
  rBot = rtp + eps;
  rTop = layerTop[layerIdx] - eps;
  If[rBot < rTop,
    delta += 2 NIntegrate[integrandDelta[r], {r, rBot, rTop},
      MaxRecursion -> 20, PrecisionGoal -> 6];
    ttime += 2 NIntegrate[integrandT[r], {r, rBot, rTop},
      MaxRecursion -> 20, PrecisionGoal -> 6];
  ];

  (* Overlying layers *)
  Do[
    rBot = layerBottom[k] + eps;
    rTop = layerTop[k] - eps;
    If[rBot < rTop,
      delta += 2 NIntegrate[integrandDelta[r], {r, rBot, rTop},
        MaxRecursion -> 20, PrecisionGoal -> 6];
      ttime += 2 NIntegrate[integrandT[r], {r, rBot, rTop},
        MaxRecursion -> 20, PrecisionGoal -> 6];
    ],
    {k, layerIdx + 1, nLayers}
  ];

  (* Crustal correction *)
  Module[{vCrustAvg = 6.3, rCrust = 6346.6, dCrust = 21.4, iCrust, tCrust, dCrust2},
    iCrust = ArcSin[Min[p * vCrustAvg / rCrust, 0.99]];
    tCrust = 2 * dCrust / (vCrustAvg * Cos[iCrust]);
    dCrust2 = 2 * Tan[iCrust] * dCrust / rCrust;
    ttime += tCrust;
    delta += dCrust2;
  ];

  <|"Delta" -> delta, "T" -> ttime, "p" -> p, "rtp" -> rtp|>
];


(* ---- Compute P-wave travel times ---- *)

Print["Computing P-wave travel times... (1-2 minutes)"];

pMinP = 3480.0 / vpPREM[3480.01] + 2.0;
pMaxP = 6346.6 / vpPREM[6346.59] - 2.0;

pValuesP = Join[
  Table[p, {p, pMinP, pMinP + 50, 2}],
  Table[p, {p, pMinP + 50, pMaxP - 50, 5}],
  Table[p, {p, pMaxP - 50, pMaxP, 2}]
];

pRayDataP = Table[Quiet @ computeRayPath[p, vpPREM], {p, pValuesP}];

travelTimeDataP = SortBy[
  Select[
    Table[{pRayDataP[[i]]["Delta"] * 180 / Pi, pRayDataP[[i]]["T"]},
      {i, Length[pRayDataP]}],
    NumericQ[#[[1]]] && NumericQ[#[[2]]] && #[[1]] > 0 &
  ], First];

Print[StringForm["Computed `` P-wave travel times (``-`` degrees).",
  Length[travelTimeDataP],
  Round[Min[travelTimeDataP[[All, 1]]], 0.1],
  Round[Max[travelTimeDataP[[All, 1]]], 0.1]]];


(* ---- S-wave travel times ---- *)

Print["Computing S-wave travel times..."];

pMinS = 3480.0 / vsPREM[3480.01] + 2.0;
pMaxS = 6346.6 / vsPREM[6346.59] - 2.0;

pValuesS = Join[
  Table[p, {p, pMinS, pMinS + 100, 4}],
  Table[p, {p, pMinS + 100, pMaxS - 100, 10}],
  Table[p, {p, pMaxS - 100, pMaxS, 4}]
];

pRayDataS = Table[Quiet @ computeRayPath[p, vsPREM], {p, pValuesS}];

travelTimeDataS = SortBy[
  Select[
    Table[{pRayDataS[[i]]["Delta"] * 180 / Pi, pRayDataS[[i]]["T"]},
      {i, Length[pRayDataS]}],
    NumericQ[#[[1]]] && NumericQ[#[[2]]] && #[[1]] > 0 &
  ], First];

Print[StringForm["Computed `` S-wave travel times.", Length[travelTimeDataS]]];


(* ---- Surface wave travel times ---- *)

vRayleigh = 3.7; (* km/s *)
vLove = 4.3;     (* km/s *)

travelTimeSurf[deltaDeg_, v_] := (deltaDeg * Pi / 180) * rEarth / v;


(* ---- Travel-Time Curve Plot ---- *)

travelTimePlot = Show[
  ListPlot[travelTimeDataP,
    PlotStyle -> {Blue, PointSize[Small]},
    PlotMarkers -> {"\[FilledCircle]", 5}],
  ListPlot[travelTimeDataS,
    PlotStyle -> {Red, PointSize[Small]},
    PlotMarkers -> {"\[FilledSquare]", 5}],
  Plot[travelTimeSurf[d, vRayleigh], {d, 0, 180},
    PlotStyle -> {Orange, Thick, Dashed}],
  Plot[travelTimeSurf[d, vLove], {d, 0, 180},
    PlotStyle -> {Darker[Yellow], Thick, Dashed}],
  PlotRange -> {{0, 120}, {0, 2500}},
  AxesLabel -> {"Epicentral Distance (degrees)", "Travel Time (seconds)"},
  PlotLabel -> Style["Universal Seismic Travel-Time Curves (PREM)", Bold, 14],
  PlotLegends -> Placed[
    {"P-wave (ray theory)", "S-wave (ray theory)",
     "Rayleigh wave", "Love wave"}, {0.3, 0.8}],
  GridLines -> Automatic,
  GridLinesStyle -> Directive[LightGray],
  ImageSize -> 700, AspectRatio -> 0.5
]


(* ---- Interpolation for T(Delta) ---- *)

tOfDeltaP = Interpolation[travelTimeDataP, InterpolationOrder -> 3];
tOfDeltaS = Interpolation[travelTimeDataS, InterpolationOrder -> 3];
deltaOfTP = Interpolation[Reverse /@ travelTimeDataP, InterpolationOrder -> 3];
deltaOfTS = Interpolation[Reverse /@ travelTimeDataS, InterpolationOrder -> 3];
deltaOfTSurf[t_, v_] := t * v / rEarth * (180 / Pi);

tMinP = Min[travelTimeDataP[[All, 2]]];
tMaxP = Max[travelTimeDataP[[All, 2]]];
tMinS = Min[travelTimeDataS[[All, 2]]];
tMaxS = Max[travelTimeDataS[[All, 2]]];


(* ====================================================================== *)
(*  SECTION 5: VISUALIZING RAY PATHS                                      *)
(* ====================================================================== *)

computeRayXY[p_?NumericQ, vFunc_, nPoints_: 200] := Module[
  {rtp, rVals, points = {}, eta, dr, dAngle, r, angle = 0},

  rtp = Quiet @ findTurningPoint[p, vFunc];
  eta[rv_?NumericQ] := rv / vFunc[rv];

  rVals = Table[rv, {rv, rSource, rtp, -(rSource - rtp)/nPoints}];
  Do[
    r = rVals[[i]];
    dr = If[i < Length[rVals], rVals[[i + 1]] - r, 0];
    If[Abs[dr] > 0 && eta[r]^2 - p^2 > 0,
      dAngle = -p / (r Sqrt[eta[r]^2 - p^2]) * dr;
      angle += dAngle;
      AppendTo[points, {r Cos[angle], r Sin[angle]}];
    ],
    {i, Length[rVals]}
  ];

  points = Join[points,
    Reverse[{#[[1]] Cos[2 angle] + #[[2]] Sin[2 angle],
             #[[1]] Sin[2 angle] - #[[2]] Cos[2 angle]} & /@
      Reverse[Most[points]]]
  ];
  points
];

rayPathPlot = Show[
  Graphics[{
    {FaceForm[Lighter[Yellow, 0.8]], EdgeForm[Gray], Disk[{0, 0}, rEarth]},
    {FaceForm[Lighter[Orange, 0.5]], EdgeForm[Gray], Disk[{0, 0}, 5701]},
    {FaceForm[Lighter[Red, 0.5]], EdgeForm[Gray], Disk[{0, 0}, 3480]},
    {FaceForm[Yellow], EdgeForm[Gray], Disk[{0, 0}, 1221.5]}
  }],
  Table[
    With[{pts = Quiet @ computeRayXY[p, vpPREM, 300]},
      If[Length[pts] > 10,
        Graphics[{ColorData["Rainbow"][(p - pMinP)/(pMaxP - pMinP)],
          Thick, Line[pts]}],
        Graphics[{}]]
    ],
    {p, pMinP + 5, pMaxP - 5, (pMaxP - pMinP)/15}
  ],
  Graphics[{
    Text[Style["Inner\nCore", 10, White, Bold], {0, 0}],
    Text[Style["Outer Core", 10, White], {0, 2400}],
    Text[Style["Lower Mantle", 10], {0, 4600}],
    {Red, PointSize[0.015], Point[{0, rSource}]}
  }],
  PlotRange -> {{-7000, 7000}, {-7000, 7000}},
  PlotLabel -> Style["P-wave Ray Paths through PREM", Bold, 14],
  ImageSize -> 600, AspectRatio -> 1
]


(* ====================================================================== *)
(*  SECTION 6: ENERGY AND MAGNITUDE SCALING                              *)
(* ====================================================================== *)

(*
   The seismic energy radiated by an earthquake is related to its
   moment magnitude Mw by the Gutenberg-Richter-Kanamori relation:

     log10(E_s) = 1.5 Mw + 4.8      (E in Joules)

   This is a logarithmic scale: each unit increase in Mw corresponds
   to a factor of 10^1.5 ~ 31.6 in energy. A M9 earthquake releases
   about 31,600 times more energy than a M6.

   For nuclear explosions, the total energy is the weapon yield:
     E_nuc = Y (kilotons) x 4.184 x 10^12 J/kt

   The seismic coupling efficiency for underground nuclear tests is
   typically 1-7% — most energy goes into heating/melting rock and
   creating the cavity. But we compare total energies since that is
   the more meaningful physical quantity.
*)

(* Energy-magnitude relation (Kanamori 1977) *)
seismicEnergy[mw_] := 10^(1.5 mw + 4.8); (* Joules *)

(* 1 kiloton TNT equivalent *)
ktTNT = 4.184 * 10^12; (* Joules *)

(* Compute energies for all earthquakes *)
earthquakeEnergies = Table[
  <|"Name" -> eq["ShortName"],
    "Mw" -> eq["Magnitude"],
    "Energy" -> seismicEnergy[eq["Magnitude"]],
    "EnergyMt" -> seismicEnergy[eq["Magnitude"]] / (1000 * ktTNT)|>,
  {eq, earthquakeCatalog}
];

(* Nuclear test energy *)
nuclearEnergy = nuclearTest["YieldKt"] * ktTNT; (* 1.046 x 10^15 J *)
nuclearEnergyMt = nuclearTest["YieldKt"] / 1000; (* 0.25 Mt *)

(* Energy comparison table *)
Print[Style["\nENERGY COMPARISON: EARTHQUAKES vs. NUCLEAR TEST", Bold, 14]];
Print[""];

Grid[
  Prepend[
    Append[
      Table[{
        earthquakeEnergies[[i]]["Name"],
        earthquakeEnergies[[i]]["Mw"],
        ScientificForm[earthquakeEnergies[[i]]["Energy"], 3],
        NumberForm[earthquakeEnergies[[i]]["EnergyMt"], {5, 1}],
        NumberForm[earthquakeEnergies[[i]]["Energy"] / nuclearEnergy, {7, 0}]
        },
        {i, Length[earthquakeEnergies]}
      ],
      {nuclearTest["ShortName"],
       StringForm["mb ``", nuclearTest["MagnitudeBody"]],
       ScientificForm[nuclearEnergy, 3],
       NumberForm[nuclearEnergyMt, {4, 2}],
       1}
    ],
    {"Event", "Magnitude", "Energy (J)", "Energy (Mt TNT)", "Multiple of DPRK nuke"}
  ],
  Frame -> All,
  Background -> {None, {LightOrange, None, None, None, None, None, None, LightRed}},
  Alignment -> Center, Spacings -> {2, 1}
]

Print[""];
Print[Style[
  StringForm["The 1960 Chile M9.5 released `` times more energy than \
the largest North Korean nuclear test (250 kt).",
    Round[seismicEnergy[9.5] / nuclearEnergy]],
  Bold, 12]];

(*
   Let's visualize this on a logarithmic scale. The energy range spans
   4 orders of magnitude — from the DPRK nuke at 10^15 J to Chile at
   10^19 J. This is one of the most striking ways to appreciate how
   enormous great earthquakes truly are.
*)

energyBarChart = BarChart[
  Log10 /@ Append[
    seismicEnergy /@ earthquakeCatalog[[All, "Magnitude"]],
    nuclearEnergy
  ],
  ChartLabels -> Placed[
    Append[earthquakeCatalog[[All, "ShortName"]], nuclearTest["ShortName"]],
    Below],
  ChartStyle -> Append[Table[Blue, Length[earthquakeCatalog]], Red],
  AxesLabel -> {None, "log\[SubScript]10(Energy / Joules)"},
  PlotLabel -> Style["Seismic Energy Comparison (log scale)", Bold, 14],
  GridLines -> {None, Automatic},
  GridLinesStyle -> Directive[LightGray],
  ImageSize -> 700,
  PlotRange -> {14, 20},
  Epilog -> {
    Text[Style["Nuclear\ntest", 9, Red], {7, 15.3}],
    Text[Style["Each Mw unit = 31.6x energy", 10, Italic, Gray],
      Scaled[{0.5, 0.95}]]
  }
]


(* ====================================================================== *)
(*  SECTION 7: GLOBAL WAVEFRONT ANIMATION                                *)
(* ====================================================================== *)

(*
   Now we animate wavefronts for each event. The travel-time curves
   computed in Section 4 are UNIVERSAL — they depend only on the
   Earth's velocity structure, not on the specific earthquake.

   What varies between events:
   - Epicenter position (center of wavefront circles)
   - Magnitude (determines amplitude, but wavefront geometry is same)
   - Source mechanism (radiation pattern)
   - For nuclear tests: no S-wave or surface waves

   We create:
   1. An interactive Manipulate with event selector + time slider
   2. A comparative snapshot grid showing all events at t = 5 min
   3. A regional Mediterranean view for the Crete event
*)

(* ---- Radiation pattern for double-couple sources ---- *)
radiationPattern[azimuth_, strike_] := Cos[2 (azimuth - strike) Degree];


(* ---- Parameterized animation function ---- *)

makeWavefrontFrame[epicenter_, t_, isNuclear_: False,
  label_: "", projection_: "Orthographic"] :=
Module[{pDist, sDist, rDist, proj},

  pDist = If[tMinP <= t <= tMaxP, Quiet @ deltaOfTP[t],
    If[t < tMinP, 0, Max[travelTimeDataP[[All, 1]]]]];
  sDist = If[tMinS <= t <= tMaxS, Quiet @ deltaOfTS[t],
    If[t < tMinS, 0, Max[travelTimeDataS[[All, 1]]]]];
  rDist = deltaOfTSurf[t, vRayleigh];

  proj = If[projection == "Orthographic",
    {"Orthographic", "Centering" -> epicenter},
    projection];

  GeoGraphics[{
    (* P-wave front (blue) — present for both earthquakes and explosions *)
    If[pDist > 0 && pDist < 170,
      {Directive[Blue, Thick, Opacity[0.8]],
       GeoCircle[epicenter,
         Quantity[pDist * rEarth * Pi / 180, "Kilometers"]]},
      {}],

    (* P-wave swept region *)
    If[pDist > 5,
      {Directive[Blue, Opacity[0.05]],
       GeoDisk[epicenter,
         Quantity[pDist * rEarth * Pi / 180, "Kilometers"]]},
      {}],

    (* S-wave front (red) — ONLY for earthquakes *)
    If[!isNuclear && sDist > 0 && sDist < 170,
      {Directive[Red, Thick, Opacity[0.8]],
       GeoCircle[epicenter,
         Quantity[sDist * rEarth * Pi / 180, "Kilometers"]]},
      {}],

    (* Rayleigh surface wave (orange, dashed) — ONLY for earthquakes *)
    If[!isNuclear && rDist > 0 && rDist < 175,
      {Directive[Orange, Thick, Dashed, Opacity[0.8]],
       GeoCircle[epicenter,
         Quantity[Min[rDist, 179.9] * rEarth * Pi / 180, "Kilometers"]]},
      {}],

    (* Epicenter *)
    {If[isNuclear, Black, Red], PointSize[0.015], Point[epicenter]},
    {White, PointSize[0.010], Point[epicenter]}
  },
  GeoRange -> "World",
  GeoProjection -> proj,
  GeoBackground -> GeoStyling["ReliefMap"],
  PlotLabel -> Style[
    StringForm["`` | t = `` min `` s  |  P: ``\[Degree]``",
      label, Floor[t/60], Mod[Round[t], 60],
      Round[pDist, 0.1],
      If[isNuclear, " (explosion: no S/Rayleigh)",
        StringForm["  S: ``\[Degree]  R: ``\[Degree]",
          Round[sDist, 0.1], Round[rDist, 0.1]]]],
    Bold, 11],
  ImageSize -> 650]
];


(* ---- Interactive Multi-Event Animation ---- *)

(* Build event list for the Manipulate popup *)
eventPositions = Append[
  earthquakeCatalog[[All, "Position"]],
  nuclearTest["Position"]
];
eventLabels = Append[
  earthquakeCatalog[[All, "ShortName"]],
  nuclearTest["ShortName"] <> " (nuclear)"
];
eventIsNuclear = Append[
  Table[False, Length[earthquakeCatalog]],
  True
];

multiEventAnimation = Manipulate[
  makeWavefrontFrame[
    eventPositions[[eventIdx]], t,
    eventIsNuclear[[eventIdx]],
    eventLabels[[eventIdx]]
  ],
  {{eventIdx, 1, "Event"},
    Thread[Range[Length[eventLabels]] -> eventLabels],
    PopupMenu},
  {{t, 0, "Time (seconds)"}, 0, 1800, 1,
    Appearance -> "Labeled", AnimationRate -> 10},
  TrackedSymbols :> {t, eventIdx},
  SaveDefinitions -> True
]


(* ---- Comparative Snapshot Grid: all events at t = 300 s ---- *)

Print[Style["\nALL EVENTS AT t = 5 MINUTES", Bold, 14]];

snapshotGrid = GraphicsGrid[
  Partition[
    Table[
      With[{eq = allEvents[[i]]},
        makeWavefrontFrame[
          eq["Position"], 300,
          KeyExistsQ[eq, "YieldKt"],
          eq["ShortName"],
          "Orthographic"
        ] /. (ImageSize -> _) -> (ImageSize -> 280)
      ],
      {i, Length[allEvents]}
    ],
    UpTo[3]  (* 3 columns *)
  ],
  Spacings -> {5, 5},
  PlotLabel -> Style["Wavefront Comparison at t = 5 min: \
P (blue), S (red), Rayleigh (orange dashed)", Bold, 12]
]


(* ---- Regional Mediterranean View for Crete Event ---- *)

(*
   The 2025 Crete earthquake, while moderate (M6.0), produced
   striking visualizations across the Mediterranean seismic network.
   Here we zoom into the regional scale where the wavefronts sweep
   across Southern Europe and North Africa.
*)

creteEpicenter = earthquakeCatalog[[3]]["Position"]; (* Crete *)

creteRegionalAnimation = Manipulate[
  Module[{pDist, sDist, rDist},
    pDist = If[tMinP <= t <= tMaxP, Quiet@deltaOfTP[t], 0];
    sDist = If[tMinS <= t <= tMaxS, Quiet@deltaOfTS[t], 0];
    rDist = deltaOfTSurf[t, vRayleigh];

    GeoGraphics[{
      If[pDist > 0, {Blue, Thick,
        GeoCircle[creteEpicenter,
          Quantity[pDist * rEarth * Pi / 180, "Kilometers"]]}, {}],
      If[sDist > 0, {Red, Thick,
        GeoCircle[creteEpicenter,
          Quantity[sDist * rEarth * Pi / 180, "Kilometers"]]}, {}],
      If[rDist > 0, {Orange, Thick, Dashed,
        GeoCircle[creteEpicenter,
          Quantity[rDist * rEarth * Pi / 180, "Kilometers"]]}, {}],
      {Red, PointSize[0.015], Point[creteEpicenter]}
    },
    GeoRange -> {{20, 55}, {-10, 45}}, (* Mediterranean region *)
    GeoProjection -> "Mercator",
    GeoBackground -> GeoStyling["ReliefMap"],
    PlotLabel -> Style[
      StringForm["Crete M6.0 — Mediterranean View | t = `` s", Round[t]],
      Bold, 12],
    ImageSize -> 700, AspectRatio -> 0.5]
  ],
  {{t, 0, "Time (s)"}, 0, 600, 1,
    Appearance -> "Labeled", AnimationRate -> 5},
  TrackedSymbols :> {t},
  SaveDefinitions -> True
]


(* ---- Equirectangular Animation (flat world map) ---- *)

flatMapAnimation = Manipulate[
  Module[{center, isNuke},
    center = eventPositions[[eventIdx]];
    isNuke = eventIsNuclear[[eventIdx]];
    makeWavefrontFrame[center, t, isNuke,
      eventLabels[[eventIdx]], "Equirectangular"
    ] /. (ImageSize -> _) -> (ImageSize -> 800)
      /. (AspectRatio -> _) -> Sequence[]
  ],
  {{eventIdx, 1, "Event"},
    Thread[Range[Length[eventLabels]] -> eventLabels], PopupMenu},
  {{t, 0, "Time (seconds)"}, 0, 2400, 1,
    Appearance -> "Labeled", AnimationRate -> 10},
  TrackedSymbols :> {t, eventIdx},
  SaveDefinitions -> True
]


(* ====================================================================== *)
(*  SECTION 8: THE SUPERSHEAR EFFECT (Myanmar 2025)                      *)
(* ====================================================================== *)

(*
   The 2025 Myanmar earthquake was remarkable because it ruptured at
   SUPERSHEAR velocity: the fault rupture propagated faster than the
   local shear wave speed.

   Normally:    v_rupture < 0.92 v_S   (sub-Rayleigh)
   Myanmar:     v_rupture ~ 5.5 km/s > v_S ~ 3.5 km/s

   This creates a MACH CONE — the seismic analogue of a sonic boom:

     sin(\[Theta]_Mach) = v_S / v_rupture

   For Myanmar:
     sin(\[Theta]) = 3.5 / 5.5 = 0.636
     \[Theta] ~ 39.5 degrees

   The Mach cone concentrates energy into a narrow band, producing
   unusually intense shaking along its intersection with the surface.
*)

vRupture = 5.5;
vShearCrust = 3.5;
machAngle = ArcSin[vShearCrust / vRupture] * 180 / Pi;
machNumber = vRupture / vShearCrust;

Print[Style["\nSUPERSHEAR ANALYSIS", Bold, 14]];
Print[StringForm["Rupture velocity: `` km/s", vRupture]];
Print[StringForm["Shear wave speed: `` km/s", vShearCrust]];
Print[StringForm["Mach number: ``", Round[machNumber, 0.01]]];
Print[StringForm["Mach angle: ``\[Degree]", Round[machAngle, 0.1]]];

machConePlot = Graphics[{
  {Gray, Thick, Line[{{0, 0}, {10, 0}}]},
  {Gray, Thick, Arrowheads[0.03], Arrow[{{8, 0}, {10, 0}}]},
  Text[Style["Rupture direction\n(v = 5.5 km/s)", 10], {5, -0.5}],

  {Red, Thick, Opacity[0.8],
   Line[{{10, 0}, {10 - 8 Cos[machAngle Degree], 8 Sin[machAngle Degree]}}],
   Line[{{10, 0}, {10 - 8 Cos[machAngle Degree], -8 Sin[machAngle Degree]}}]},

  Table[
    {Blue, Thin, Opacity[0.3],
     Circle[{x, 0}, vShearCrust / vRupture * (10 - x)]},
    {x, 0, 9, 1}
  ],

  Text[Style[StringForm["\[Theta] = ``\[Degree]", Round[machAngle, 0.1]],
    12, Red, Bold], {9.5, 2}],
  {Red, PointSize[0.02], Point[{10, 0}]},
  {Darker[Green], Dashed, Thick, Circle[{10, 0}, 3]},
  Text[Style["S-wave from tip\n(v_S = 3.5 km/s)", 9, Darker[Green]], {10, -4}]
},
PlotRange -> {{-2, 14}, {-7, 7}},
PlotLabel -> Style["Supershear Mach Cone (Myanmar 2025)", Bold, 14],
Axes -> False, ImageSize -> 600, AspectRatio -> 0.6,
Epilog -> {
  Inset[Column[{
    Style["Supershear Rupture:", Bold],
    "v_rupture > v_S",
    StringForm["Mach number: ``", Round[machNumber, 0.01]],
    "Energy concentrated along Mach cone",
    "Analogous to a sonic boom"
  }, BaseStyle -> 10], Scaled[{0.15, 0.85}], {Left, Top}]
}]


(* ====================================================================== *)
(*  SECTION 9: NUCLEAR TESTS AS SEISMIC SOURCES                         *)
(* ====================================================================== *)

(*
   Underground nuclear explosions generate seismic waves that are
   recorded by the global seismograph network. This is the basis
   of the Comprehensive Nuclear-Test-Ban Treaty (CTBT) verification
   regime, operated by CTBTO with ~170 seismic stations worldwide.

   The key physics differences between an explosion and an earthquake:

   1. SOURCE MECHANISM:
      - Earthquake: double-couple (shear failure on a fault plane)
        -> quadrupolar radiation pattern (compression in 2 quadrants,
           rarefaction in the other 2)
      - Explosion: isotropic expansion (spherical cavity)
        -> uniform compression in all directions

   2. WAVE GENERATION:
      - Earthquake: strong P AND S waves, strong surface waves
      - Explosion: strong P waves, WEAK S waves (no shear in the
        source), weak surface waves (shallow, isotropic source
        couples poorly to Rayleigh waves)

   3. DEPTH:
      - Earthquakes: 0-700 km (most at 10-30 km)
      - Nuclear tests: < 1 km (must be contained underground)

   These differences create the two primary discrimination criteria:
   (a) P/S amplitude ratio: high for explosions, low for earthquakes
   (b) mb-Ms relation: explosions have high mb relative to Ms
*)


(* ---- mb-Yield Relationship ---- *)

(*
   The body-wave magnitude mb of a nuclear explosion is related to
   its yield by an empirical scaling law. For fully coupled explosions
   in hard rock (Murphy 1996; Ringdal 1986):

     mb = 4.45 + 0.75 log10(Y)     (Y in kilotons)

   This assumes full coupling — the cavity is small relative to the
   elastic radius. Decoupling (detonating in a pre-existing cavity)
   can reduce mb by 1-2 units, but this requires enormous cavities
   for large yields and is detectable by other means.
*)

mbFromYield[yieldKt_] := 4.45 + 0.75 Log10[yieldKt];
yieldFromMb[mb_] := 10^((mb - 4.45) / 0.75);

(* North Korea nuclear test series — a unique calibration dataset *)
nkTests = {
  <|"Year" -> 2006, "mb" -> 4.1, "Ms" -> 2.9, "Yield" -> 1,
    "Notes" -> "First test, likely fizzle"|>,
  <|"Year" -> 2009, "mb" -> 4.7, "Ms" -> 3.3, "Yield" -> 4,
    "Notes" -> "Improved design"|>,
  <|"Year" -> 2013, "mb" -> 5.1, "Ms" -> 3.4, "Yield" -> 10,
    "Notes" -> "Miniaturised warhead"|>,
  <|"Year" -> 2016, "mb" -> 5.1, "Ms" -> 3.5, "Yield" -> 10,
    "Notes" -> "January test"|>,
  <|"Year" -> 2016.7, "mb" -> 5.3, "Ms" -> 3.6, "Yield" -> 20,
    "Notes" -> "September test"|>,
  <|"Year" -> 2017, "mb" -> 6.3, "Ms" -> 4.2, "Yield" -> 250,
    "Notes" -> "Thermonuclear, mountain collapse"|>
};

(* Plot: mb vs yield with Murphy formula *)
yieldMbPlot = Show[
  (* NK data points *)
  ListPlot[
    {#["Yield"], #["mb"]} & /@ nkTests,
    PlotStyle -> {Red, PointSize[Large]},
    PlotMarkers -> {"\[FilledSquare]", 10}
  ],
  (* Murphy formula *)
  Plot[mbFromYield[y], {y, 0.5, 500},
    PlotStyle -> {Blue, Thick}],
  (* Reference yield levels *)
  Graphics[{
    {Gray, Dashed,
     Line[{{15, 3.5}, {15, 7}}]},
    Text[Style["Hiroshima\n(15 kt)", 8, Gray], {15, 3.3}],
    {Gray, Dashed,
     Line[{{250, 3.5}, {250, 7}}]},
    Text[Style["DPRK 2017\n(250 kt)", 8, Red], {250, 3.3}]
  }],
  PlotRange -> {{0.5, 500}, {3.5, 7}},
  ScalingFunctions -> {"Log10", None},
  AxesLabel -> {"Yield (kilotons TNT)", "Body-wave magnitude mb"},
  PlotLabel -> Style[
    "Nuclear Yield vs. Seismic Magnitude (Murphy 1996)", Bold, 14],
  PlotLegends -> Placed[
    {"DPRK nuclear tests", "mb = 4.45 + 0.75 log\[SubScript]10(Y)"},
    {0.3, 0.85}],
  GridLines -> Automatic,
  GridLinesStyle -> Directive[LightGray],
  ImageSize -> 700, AspectRatio -> 0.5
]

Print[""];
Print["Yield predictions from the mb formula:"];
Grid[
  Prepend[
    Table[{nk["Year"], nk["mb"], nk["Yield"],
      Round[yieldFromMb[nk["mb"]], 0.1]},
      {nk, nkTests}],
    {"Year", "Observed mb", "Estimated Yield (kt)", "Predicted from formula (kt)"}
  ],
  Frame -> All,
  Background -> {None, {LightBlue, None}},
  Alignment -> Center
]


(* ---- Nuclear Test Wavefront Animation ---- *)

(*
   A nuclear explosion produces wavefronts that look very different
   from an earthquake:
   - Only P-waves propagate efficiently (isotropic compression)
   - S-waves are much weaker (no shear in the source)
   - Surface waves are much weaker (shallow, isotropic source)
   - No radiation pattern variation with azimuth

   Let's compare Myanmar M7.7 (earthquake) side by side with the
   DPRK nuclear test at the same time stamps.
*)

comparisonSnapshots = Table[
  GraphicsRow[{
    (* Earthquake *)
    makeWavefrontFrame[
      earthquakeCatalog[[1]]["Position"], t, False,
      StringForm["Myanmar M7.7 (earthquake) t=``s", t],
      "Orthographic"
    ] /. (ImageSize -> _) -> (ImageSize -> 400),
    (* Nuclear test *)
    makeWavefrontFrame[
      nuclearTest["Position"], t, True,
      StringForm["DPRK mb6.3 (nuclear) t=``s", t],
      "Orthographic"
    ] /. (ImageSize -> _) -> (ImageSize -> 400)
  }, Spacings -> 1],
  {t, {120, 300, 600}}
];

GraphicsColumn[comparisonSnapshots, Spacings -> 5,
  PlotLabel -> Style[
    "Earthquake vs. Nuclear Test: The explosion produces \
ONLY P-waves (blue)\nNo S-wave (red) or surface wave (orange) fronts",
    Bold, 12]]


(* ====================================================================== *)
(*  SECTION 10: EARTHQUAKE vs. EXPLOSION DISCRIMINATION                  *)
(* ====================================================================== *)

(*
   The definitive seismological method for distinguishing nuclear
   explosions from earthquakes uses the relationship between body-wave
   magnitude (mb) and surface-wave magnitude (Ms).

   For earthquakes: mb and Ms are related by the tectonic source
   mechanism. Shallow earthquakes generate strong surface waves, so
   Ms is comparable to or larger than mb.

   For explosions: the isotropic source at very shallow depth couples
   poorly to surface waves. For a given mb, the explosion's Ms is
   much lower than an earthquake's Ms.

   Empirically:
     Earthquakes: Ms \[TildeTilde] 1.3 mb - 2.0  (approximate trend)
     Explosions:  Ms \[TildeTilde] mb - 1.7       (approximate trend)

   The gap between these two lines is the "discrimination space" that
   CTBT verification relies on. The CTBTO's International Data Centre
   uses this (and other criteria) to screen every detected event.
*)

(* Earthquake data: {mb, Ms} from our catalog *)
(* Note: for very large earthquakes, mb saturates around 6.5-7.0
   while Ms continues to increase. This creates the characteristic
   curved mb-Ms relationship for earthquakes. *)
eqMbMs = {
  {5.5, 5.8},    (* Crete 2025 *)
  {6.2, 7.3},    (* Venezuela 2026 *)
  {6.2, 7.5},    (* Myanmar 2025 *)
  {6.5, 8.3},    (* Sumatra 2004, mb saturated *)
  {6.5, 8.1},    (* Tohoku 2011, mb saturated *)
  {6.5, 8.5}     (* Chile 1960, mb saturated *)
};

(* Nuclear test data: {mb, Ms} from NK series *)
nukeMbMs = Table[{nk["mb"], nk["Ms"]}, {nk, nkTests}];

(* Additional reference data: historical nuclear tests *)
(* These are approximate but illustrate the systematic offset *)
refNukeMbMs = {
  {5.9, 3.7},    (* Semipalatinsk tests *)
  {5.5, 3.5},
  {5.0, 3.2},
  {4.5, 2.8},
  {6.1, 3.9}     (* Novaya Zemlya *)
};

mbMsPlot = Show[
  (* Earthquake population *)
  ListPlot[eqMbMs,
    PlotStyle -> {Blue, PointSize[Large]},
    PlotMarkers -> {"\[FilledCircle]", 12}],

  (* Nuclear test population: NK *)
  ListPlot[nukeMbMs,
    PlotStyle -> {Red, PointSize[Large]},
    PlotMarkers -> {"\[FilledSquare]", 10}],

  (* Reference nuclear tests *)
  ListPlot[refNukeMbMs,
    PlotStyle -> {Darker[Red], PointSize[Medium]},
    PlotMarkers -> {"\[FilledDiamond]", 8}],

  (* Earthquake trend *)
  Plot[1.3 mb - 2.0, {mb, 3.5, 7.5},
    PlotStyle -> {Blue, Dashed, Thick}],

  (* Explosion trend *)
  Plot[mb - 1.7, {mb, 3.5, 7.5},
    PlotStyle -> {Red, Dashed, Thick}],

  (* Discrimination line *)
  Plot[mb - 0.8, {mb, 3.5, 7.5},
    PlotStyle -> {Black, Dotted, Thick}],

  (* Labels *)
  Graphics[{
    Text[Style["Earthquake\npopulation", 10, Blue, Bold],
      {5.0, 6.5}],
    Text[Style["Explosion\npopulation", 10, Red, Bold],
      {5.0, 2.7}],
    Text[Style["Discrimination\nline", 9, Gray],
      {6.8, 5.7}]
  }],

  PlotRange -> {{3.5, 7.5}, {2, 9}},
  AxesLabel -> {"Body-wave magnitude (mb)",
    "Surface-wave magnitude (Ms)"},
  PlotLabel -> Style[
    "mb-Ms Discrimination: Earthquakes vs. Nuclear Explosions", Bold, 14],
  PlotLegends -> Placed[
    {"Earthquakes (this study)", "DPRK nuclear tests",
     "Other nuclear tests", "Earthquake trend", "Explosion trend",
     "Discrimination line"},
    {0.75, 0.35}],
  GridLines -> Automatic,
  GridLinesStyle -> Directive[LightGray],
  ImageSize -> 700, AspectRatio -> 0.7
]

(*
   The plot shows clear separation between the two populations.
   The DPRK tests (red squares) cluster well below the earthquake
   population — for a given mb, their Ms is 1.5-2.5 units lower.

   This is a direct consequence of the source physics:
   - Earthquakes are SHEAR failures on fault planes, efficiently
     exciting both body waves and surface waves.
   - Explosions are COMPRESSIVE point sources at very shallow depth,
     exciting strong P-waves but coupling poorly to surface waves.

   The discrimination holds even for the largest DPRK test (mb 6.3,
   Ms 4.2), which would be expected to have Ms > 6 if it were a
   natural earthquake.
*)


(* ---- Source Mechanism Diagram ---- *)

(*
   Let's visualize WHY the discrimination works by showing the
   fundamental difference in radiation patterns.
*)

sourceMechanismPlot = GraphicsRow[{
  (* Earthquake: double-couple radiation pattern *)
  Graphics[{
    (* P-wave radiation lobes *)
    Table[
      With[{amp = Cos[2 \[Theta]]},
        {If[amp > 0,
          Directive[Blue, Opacity[Abs[amp] * 0.6]],
          Directive[Red, Opacity[Abs[amp] * 0.6]]],
         Polygon[{
           {0, 0},
           {5 Abs[amp] Cos[\[Theta]], 5 Abs[amp] Sin[\[Theta]]},
           {5 Abs[amp] Cos[\[Theta] + Pi/36],
            5 Abs[amp] Sin[\[Theta] + Pi/36]}}]}
      ],
      {\[Theta], 0, 2 Pi - Pi/36, Pi/36}
    ],
    (* Labels *)
    Text[Style["C", Bold, Blue], {3, 3}],
    Text[Style["D", Bold, Red], {3, -3}],
    Text[Style["C", Bold, Blue], {-3, -3}],
    Text[Style["D", Bold, Red], {-3, 3}],
    {Black, PointSize[0.02], Point[{0, 0}]},
    Text[Style["EARTHQUAKE\n(double-couple)", Bold, 10], {0, -7}],
    Text[Style["C = compression\nD = dilatation", 8, Gray], {0, 7}]
  },
  PlotRange -> {{-8, 8}, {-8, 8}}, ImageSize -> 320],

  (* Explosion: isotropic radiation pattern *)
  Graphics[{
    Table[
      {Directive[Blue, Opacity[0.4]],
       Circle[{0, 0}, r]},
      {r, 0.5, 5, 0.5}
    ],
    (* All-compression arrows *)
    Table[
      {Blue, Thick, Arrowheads[0.04],
       Arrow[{{4 Cos[\[Theta]], 4 Sin[\[Theta]]},
              {5.5 Cos[\[Theta]], 5.5 Sin[\[Theta]]}}]},
      {\[Theta], 0, 2 Pi - Pi/4, Pi/4}
    ],
    {Black, PointSize[0.02], Point[{0, 0}]},
    Text[Style["EXPLOSION\n(isotropic)", Bold, 10], {0, -7}],
    Text[Style["All compression\n(no shear)", 8, Gray], {0, 7}]
  },
  PlotRange -> {{-8, 8}, {-8, 8}}, ImageSize -> 320]
},
Spacings -> 2,
PlotLabel -> Style[
  "Source Radiation Patterns: Why Explosions Look Different", Bold, 12]]


(* ====================================================================== *)
(*  SECTION 11: QUANTITATIVE VERIFICATION                                *)
(* ====================================================================== *)

(*
   We verify our PREM-based model against the IASP91 empirical
   travel-time tables, which are the standard reference for
   teleseismic P-wave arrivals.
*)

Print[Style["\nMODEL VERIFICATION: PREM vs. IASP91", Bold, 14]];
Print[""];

benchmarkDistances = {20, 30, 45, 60, 75, 90};
iasp91Times = {289, 370, 489, 608, 720, 781};

modelTimes = Table[
  If[Min[travelTimeDataP[[All,1]]] <= d <= Max[travelTimeDataP[[All,1]]],
    Round[tOfDeltaP[d], 0.1], "N/A"],
  {d, benchmarkDistances}
];

residuals = Table[
  If[NumberQ[modelTimes[[i]]],
    Round[modelTimes[[i]] - iasp91Times[[i]], 0.1],
    "N/A"],
  {i, Length[benchmarkDistances]}
];

Grid[
  Prepend[
    Table[{benchmarkDistances[[i]], iasp91Times[[i]],
      modelTimes[[i]], residuals[[i]]},
      {i, Length[benchmarkDistances]}],
    {"Delta (deg)", "IASP91 (s)", "Our Model (s)", "Residual (s)"}
  ],
  Frame -> All,
  Background -> {None, {LightBlue, None}},
  Alignment -> Center, Spacings -> {2, 1}
]


(* ---- Arrival times at major cities for each earthquake ---- *)

cities = {
  {"Bangkok",  GeoPosition[{13.75, 100.5}]},
  {"Delhi",    GeoPosition[{28.61, 77.21}]},
  {"Tokyo",    GeoPosition[{35.68, 139.69}]},
  {"London",   GeoPosition[{51.51, -0.13}]},
  {"New York", GeoPosition[{40.71, -74.01}]},
  {"Sydney",   GeoPosition[{-33.87, 151.21}]},
  {"Caracas",  GeoPosition[{10.49, -66.88}]},
  {"Athens",   GeoPosition[{37.98, 23.73}]}
};

(* Compute P-wave arrival times from each earthquake to each city *)
Print[""];
Print[Style["P-WAVE ARRIVAL TIMES AT MAJOR CITIES", Bold, 14]];

cityArrivalTable = Table[
  Module[{dist, tp},
    dist = QuantityMagnitude[
      GeoDistance[eq["Position"], city[[2]]], "Kilometers"];
    dist = dist / (rEarth * Pi / 180); (* degrees *)
    tp = If[Min[travelTimeDataP[[All,1]]] <= dist <= Max[travelTimeDataP[[All,1]]],
      tOfDeltaP[dist],
      dist * rEarth * Pi / (180 * 10)];
    StringForm["``m ``s", Floor[tp/60], Round[Mod[tp, 60]]]
  ],
  {eq, earthquakeCatalog}, {city, cities}
];

Grid[
  Prepend[
    Table[
      Prepend[cityArrivalTable[[i]], earthquakeCatalog[[i]]["ShortName"]],
      {i, Length[earthquakeCatalog]}
    ],
    Prepend[cities[[All, 1]], "Event / City"]
  ],
  Frame -> All,
  Background -> {None, {LightBlue, None}},
  Alignment -> Center, Spacings -> {1, 0.8},
  ItemSize -> {Automatic, 2}
]


(* ====================================================================== *)
(*  SECTION 12: DISCUSSION AND CONCLUSIONS                               *)
(* ====================================================================== *)

(*
   Summary of key findings:

   1. TRAVEL-TIME CURVES are universal properties of Earth's velocity
      structure. Our PREM-based ray-theory model agrees with the
      IASP91 empirical tables to within a few seconds across all
      teleseismic distances (20-90 degrees).

   2. ENERGY SCALING spans over 5 orders of magnitude across our
      event catalog. The 1960 Chile M9.5 released ~10,700 times more
      seismic energy than the 250 kt DPRK nuclear test. The moderate
      Crete M6.0 released about 15 kt equivalent — comparable to
      Hiroshima, but 1/17 of the DPRK hydrogen bomb.

   3. SUPERSHEAR RUPTURE in the Myanmar 2025 earthquake created a
      seismic Mach cone with a half-angle of ~39.5 degrees, focusing
      energy into a narrow beam along the fault.

   4. EARTHQUAKE vs. EXPLOSION DISCRIMINATION is robustly achieved
      through the mb-Ms relationship. Nuclear explosions produce
      anomalously weak surface waves relative to their body-wave
      magnitude, due to their isotropic, shallow source mechanism.
      The DPRK 2017 test had mb 6.3 but Ms only ~4.2 — a natural
      earthquake of the same mb would have Ms > 6.

   5. The WAVEFRONT ANIMATIONS show how seismic waves sweep across
      the globe at different speeds: P-waves arrive first (fastest),
      followed by S-waves, then surface waves. For nuclear explosions,
      only the P-wave front is visible — a striking visual
      confirmation of the source physics.

   References:
   [1] Dziewonski & Anderson (1981), Phys. Earth Planet. Inter.
   [2] Shearer (2009), Introduction to Seismology, Cambridge
   [3] Kennett & Engdahl (1991), Geophys. J. Int.
   [4] Murphy (1996), Bull. Seismol. Soc. Am.
   [5] Ringdal (1986), Bull. Seismol. Soc. Am.
   [6] CTBTO, Seismic Monitoring, ctbto.org
*)


(* ====================================================================== *)
(*  SECTION 13: EXPORT                                                    *)
(* ====================================================================== *)

(*
   Export animation frames for selected events.
   The following generates frames at 15-second intervals.
*)

Print["\nGenerating export frames for Myanmar M7.7..."];

animFrames = Table[
  makeWavefrontFrame[
    earthquakeCatalog[[1]]["Position"], t, False,
    "Myanmar M7.7",
    "Equirectangular"
  ] /. (ImageSize -> _) -> (ImageSize -> 800),
  {t, 0, 1800, 15}
];

Export["SeismicWavePropagation_Myanmar.gif", animFrames,
  "DisplayDurations" -> 0.1,
  AnimationRepetitions -> Infinity];

Print["Saved: SeismicWavePropagation_Myanmar.gif"];

(* Export nuclear comparison *)
Print["Generating nuclear comparison frames..."];

nukeCompFrames = Table[
  GraphicsRow[{
    makeWavefrontFrame[
      earthquakeCatalog[[1]]["Position"], t, False,
      "Myanmar M7.7 (earthquake)", "Equirectangular"
    ] /. (ImageSize -> _) -> (ImageSize -> 500),
    makeWavefrontFrame[
      nuclearTest["Position"], t, True,
      "DPRK 250kt (nuclear)", "Equirectangular"
    ] /. (ImageSize -> _) -> (ImageSize -> 500)
  }],
  {t, 0, 1200, 20}
];

Export["EarthquakeVsNuclear.gif", nukeCompFrames,
  "DisplayDurations" -> 0.15,
  AnimationRepetitions -> Infinity];

Print["Saved: EarthquakeVsNuclear.gif"];
Print[""];
Print[Style["Project complete. Open in Mathematica, evaluate all \
cells (Shift+Enter), and publish to community.wolfram.com.", Bold, 12]];
