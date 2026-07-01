#!/usr/bin/env wolframscript
(* ::Package:: *)

(*  build_notebook.wls
    ------------------
    Assemble community/seismic_wave_propagation.nb — the long-form
    educational Wolfram Community post — from authored prose, equations
    and the pre-rendered figures in docs/images/. This script does NOT
    recompute the science: it imports the PNG/GIF produced by
    wolfram/generate_figures.wls and lays them out as fully-formed Cell
    expressions.

    Styling follows the "RiverNetworkStatistics" stylesheet: teal Roboto
    Condensed Title/Section headings (RGBColor[0.153, 0.51, 0.64]),
    Source Sans Pro code font, zero left margin.

    Embedded animations use AnimatedImage with per-frame ColorQuantize,
    and the notebook is persisted with UsingFrontEnd + CreateDocument +
    NotebookSave (NOT Export[file.nb, ...]) so the rasters and
    animations are actually written to disk.

    Run:  wolframscript -file community/build_notebook.wls
*)

scriptDir = DirectoryName[$InputFileName];
repoRoot  = ParentDirectory[scriptDir];
imgDir    = FileNameJoin[{repoRoot, "docs", "images"}];
outNb     = FileNameJoin[{scriptDir, "seismic_wave_propagation.nb"}];
outPdf    = FileNameJoin[{scriptDir, "seismic_wave_propagation.pdf"}];

(* ================================================================= *)
(*  Stylesheet (RiverNetworkStatistics)                              *)
(* ================================================================= *)
teal = RGBColor[0.153, 0.51, 0.64];
styleSheet = Notebook[{
   Cell[StyleData[StyleDefinitions -> "Default.nb"]],
   Cell[StyleData["Text"], CellMargins -> {{0, 10}, {7, 8}}, FontSize -> 14,
     FontFamily -> "Source Sans Pro"],
   Cell[StyleData["Title"], CellMargins -> {{0, 3}, {15, 0}},
     FontFamily -> "Roboto Condensed", FontColor -> teal],
   Cell[StyleData["Subtitle"], CellMargins -> {{0, 3}, {20, 0}},
     FontSize -> 18, FontFamily -> "Roboto Condensed",
     FontColor -> GrayLevel[0.35]],
   Cell[StyleData["Subsubtitle"], FontSize -> 14, FontSlant -> Italic,
     FontColor -> GrayLevel[0.4]],
   Cell[StyleData["Abstract"], CellMargins -> {{0, 10}, {0, 0}},
     FontColor -> GrayLevel[0.25]],
   Cell[StyleData["Section"], CellMargins -> {{0, 3}, {10, 22}},
     FontFamily -> "Roboto Condensed", FontSize -> 30, FontColor -> teal],
   Cell[StyleData["Subsection"], CellMargins -> {{0, 3}, {8, 16}},
     FontFamily -> "Roboto Condensed", FontColor -> GrayLevel[0.2]],
   Cell[StyleData["Subsubsection"], CellMargins -> {{0, 3}, {8, 12}},
     FontFamily -> "Roboto Condensed"],
   Cell[StyleData["Input"], CellMargins -> {{20, 3.}, {4., 4.}},
     StyleHints -> <|"CodeFont" -> "Source Code Pro"|>, FontSize -> 13],
   Cell[StyleData["Output"], CellMargins -> {{20, 3.}, {4., 4.}}, FontSize -> 13],
   Cell[StyleData["DisplayFormula"], CellMargins -> {{40, 10}, {10, 10}},
     FontSize -> 15],
   Cell[StyleData["Item"], CellMargins -> {{24, 10.}, {4., 6.}}, FontSize -> 14]
  }, Visible -> False];

(* ================================================================= *)
(*  Cell builders                                                    *)
(* ================================================================= *)
title[t_]    := Cell[t, "Title"];
subtitle[t_] := Cell[t, "Subtitle"];
authors[t_]  := Cell[t, "Subsubtitle"];
sec[t_]      := Cell[t, "Section"];
sub[t_]      := Cell[t, "Subsection"];

para[stuff__] := Cell[TextData[Flatten[{stuff}]], "Text"];
abstract[stuff__] := Cell[TextData[Flatten[{stuff}]], "Text", FontSize -> 14,
   CellMargins -> {{0, 40}, {8, 8}}, FontColor -> GrayLevel[0.25],
   Background -> RGBColor[0.96, 0.975, 0.98], CellFrame -> {{3, 0}, {0, 0}},
   CellFrameColor -> teal, CellFrameMargins -> 12];

b[s_]   := StyleBox[s, FontWeight -> Bold];
it[s_]  := StyleBox[s, FontSlant -> Italic];
m[s_]   := StyleBox[s, FontSlant -> Italic, FontFamily -> "Times"];
code[s_]:= StyleBox[s, FontFamily -> "Source Code Pro", FontColor -> RGBColor[0.25, 0.35, 0.55]];

item[stuff__] := Cell[TextData[Flatten[{stuff}]], "Item"];

(* inline math from boxes *)
im[boxes_] := Cell[BoxData @ FormBox[boxes, TraditionalForm], "InlineFormula"];
sb[base_, k_] := im @ SubscriptBox[base, k];

(* display equation from a TraditionalForm-able expression *)
eq[expr_] := Cell[BoxData @ FormBox[ToBoxes[expr, TraditionalForm], TraditionalForm],
   "DisplayFormula"];
(* display equation straight from a box expression *)
eqb[boxes_] := Cell[BoxData @ FormBox[boxes, TraditionalForm], "DisplayFormula"];

(* figure cell: import at high resolution, then DISPLAY at a fixed
   width (in points) via ImageSize so the figure fills the text column.
   We keep the raster at up to 2x the display width for crispness. *)
fig[file_, width_: 820, caption_: ""] := Module[{path, im0, raster, disp},
   path = FileNameJoin[{imgDir, file}];
   If[!FileExistsQ[path],
     Return @ Cell[TextData[b["[ missing figure: " <> file <> " ]"]], "Text",
       FontColor -> RGBColor[0.7, 0.1, 0.1], TextAlignment -> Center]];
   im0 = Import[path];
   raster = If[First[ImageDimensions[im0]] > 1.1 width, ImageResize[im0, Round[1.1 width]], im0];
   disp = Image[raster, ImageSize -> width];
   Cell[BoxData @ ToBoxes @ If[caption === "",
        disp,
        Labeled[disp, Style[caption, Italic, 12, FontFamily -> "Source Sans Pro",
           GrayLevel[0.4]], Bottom]],
     "Output", ShowCellLabel -> False, TextAlignment -> Center,
     CellMargins -> {{Automatic, Automatic}, {10, 16}}]
];

(* animation cell: import GIF, quantise frames, embed as AnimatedImage *)
anim[file_, width_: 640, caption_: "", rate_: 2.2] := Module[{path, frames, a},
   path = FileNameJoin[{imgDir, file}];
   If[!FileExistsQ[path],
     Return @ Cell[TextData[b["[ missing animation: " <> file <> " ]"]], "Text",
       FontColor -> RGBColor[0.7, 0.1, 0.1], TextAlignment -> Center]];
   frames = Import[path, {"GIF", "ImageList"}];
   frames = If[First[ImageDimensions[First[frames]]] > 720,
      ImageResize[#, 720] & /@ frames, frames];
   frames = ColorQuantize[#, 160, Dithering -> False] & /@ frames;
   a = AnimatedImage[frames, ImageSize -> width, FrameRate -> rate,
        AnimationRunning -> True, AnimationRepetitions -> Infinity];
   Cell[BoxData @ ToBoxes @ If[caption === "",
        a,
        Labeled[a, Style[caption, Italic, 11, FontFamily -> "Source Sans Pro",
           GrayLevel[0.4]], Bottom]],
     "Output", ShowCellLabel -> False, TextAlignment -> Center,
     CellMargins -> {{Automatic, Automatic}, {12, 16}}]
];

ref[n_, txt__] := Cell[TextData[Flatten[{b["[" <> ToString[n] <> "] "], txt}]],
   "Text", FontSize -> 12, CellMargins -> {{20, 10}, {3, 3}}];

(* Runnable Input cell holding the code (a call into the .wl library)
   that generates the figure/animation shown directly below it. The
   cell content is the literal code string, so the reader can evaluate
   it after running the Setup cell. *)
codeIn[s_String] := Cell[s, "Input", CellMargins -> {{20, 10}, {6, 2}}];

(* ================================================================= *)
(*  Content                                                          *)
(* ================================================================= *)
cells = {};
add[c__] := (cells = Join[cells, Flatten[{c}]]);

add[
 title["Seismic Wave Propagation Across the Globe"],
 subtitle["From First Principles \[Dash] Earthquakes vs. Nuclear Explosions"],
 authors["Marco Thiel \[Bullet] Wolfram Community"]
];

(* Hero animation — the IRIS-style GMV of the Myanmar M7.7 across Europe,
   the same animation developed in full in Section 7. *)
add @ anim["gmv_myanmar.gif", 740,
   "Watching an earthquake cross a continent: vertical ground motion at the European seismic network as the 2025 Myanmar M7.7 wavefronts arrive (red = up, blue = down). Built from scratch below \[LongDash] see \[Section]7.",
   6.];

add @ abstract[
  "When the ground breaks, it rings the whole planet like a bell. Within ",
  "20 minutes the wavefronts of a great earthquake have swept past every ",
  "seismometer on Earth, and the precise pattern of their arrival encodes ",
  "the interior structure of our planet \[Dash] and the nature of the source ",
  "that set them off. This notebook builds that physics ",
  b["from first principles"], " in pure Wolfram Language: the elastic wave ",
  "equation, the PREM velocity model, ray theory in a spherical Earth, and ",
  "the travel-time integrals that we validate against the IASP91 standard to ",
  "within a few seconds. We then turn the same machinery on a question of ",
  "real consequence \[Dash] how seismology tells an underground ",
  b["nuclear explosion"], " apart from an ", b["earthquake"], "."
];

(* ---- Setup ---- *)
add[
 sec["Setup"],
 para["This post is fully runnable. All of the computational machinery ",
   "\[Dash] the PREM model, the ray tracer, the travel-time integrals, the ",
   "event catalogue, the energy and discrimination tools and the Ground ",
   "Motion Visualization engine \[Dash] lives in the companion package ",
   code["SeismicWavePropagation.wl"], ", which sits in the same folder as ",
   "this notebook. Evaluate the cell below first to load it (it computes ",
   "the P and S travel-time curves on load, so it takes roughly half a ",
   "minute). Every figure that follows is produced by the call shown ",
   "directly above it."],
 codeIn["SetDirectory[NotebookDirectory[]];\nGet[\"SeismicWavePropagation.wl\"]"]
];

(* ---- 1 ---- *)
add[
 sec["1 | What is an earthquake?"],
 para["The outer shell of the Earth is broken into rigid plates that grind ",
   "past one another. Friction locks their boundaries, elastic strain ",
   "accumulates in the surrounding rock for decades or centuries, and when ",
   "the stress finally exceeds the strength of the fault the two sides ",
   "snap past each other in seconds. This is ", b["elastic rebound"], ": the ",
   "stored strain energy is released, and a fraction of it radiates away as ",
   "seismic waves."],
 para["Those waves come in two families. ", b["Body waves"], " travel through ",
   "the Earth's interior \[Dash] the compressional ", b["P-wave"],
   " (fastest, arrives first) and the shear ", b["S-wave"], ". ",
   b["Surface waves"], " (Rayleigh and Love) are trapped near the free ",
   "surface, travel more slowly, but carry the largest amplitudes and do ",
   "most of the damage. The rest of this notebook is, in essence, a careful ",
   "account of how fast each of these travels and why."]
];

(* ---- 2 ---- *)
add[
 sec["2 | The physics of seismic waves"],
 para["Small deformations of an isotropic elastic solid obey the elastic ",
   "wave equation. It separates into two independent solutions. The ",
   "compressional and shear wave speeds are set entirely by the elastic ",
   "moduli (Lam\[EAcute] parameter ", m["\[Lambda]"], ", shear modulus ",
   m["\[Mu]"], ") and the density ", m["\[Rho]"], ":"],
 eqb @ RowBox[{SubscriptBox["v", "P"], "=",
    SqrtBox[FractionBox[RowBox[{"\[Lambda]", "+", RowBox[{"2", "\[Mu]"}]}], "\[Rho]"]],
    "\[NonBreakingSpace]\[NonBreakingSpace]\[NonBreakingSpace]\[NonBreakingSpace]",
    SubscriptBox["v", "S"], "=", SqrtBox[FractionBox["\[Mu]", "\[Rho]"]]}],
 para["Two physical facts fall straight out of these formulas. First, ",
   "because ", m["\[Lambda]"], " and ", m["\[Mu]"], " are positive, ",
   sb["v", "P"], " > ", sb["v", "S"], " always \[Dash] the P-wave outruns the ",
   "S-wave, which is why ", it["P"], " stands for ", it["primary"], " and ",
   it["S"], " for ", it["secondary"], ". Second, a fluid cannot support ",
   "shear (", m["\[Mu]"], " = 0), so ", sb["v", "S"], " = 0 there: ",
   b["S-waves do not propagate through liquids"], ". That single fact is how ",
   "we know the outer core is molten. For a typical Poisson solid the ratio ",
   "is fixed:"],
 eqb @ RowBox[{FractionBox[SubscriptBox["v", "P"], SubscriptBox["v", "S"]], "=",
    SqrtBox["3"], "\[TildeTilde]", "1.73"}]
];

(* ---- 3 ---- *)
add[
 sec["3 | The PREM velocity model"],
 para["To trace waves through the Earth we need the seismic velocity at ",
   "every depth. We use the ", b["Preliminary Reference Earth Model"],
   " (PREM, Dziewonski & Anderson 1981), the standard spherically averaged ",
   "model. Tabulated node-by-node and interpolated layer by layer, it ",
   "captures the major internal boundaries: the inner-core boundary at ",
   "1221.5 km radius, the core\[Dash]mantle boundary (CMB) at 3480 km, and ",
   "the 660 km and 410 km mantle phase transitions."],
 codeIn["plotPREMProfiles[]"],
 fig["prem_profiles.png", 640,
   "PREM P-wave and S-wave velocity and density as a function of radius. Note vS = 0 throughout the liquid outer core."],
 para["Mapping the P-wave velocity onto a cross-section shows the same ",
   "structure as concentric shells \[Dash] velocity generally increasing ",
   "with depth, with sharp jumps at the boundaries:"],
 codeIn["plotPREMCrossSection[]"],
 fig["prem_cross.png", 560,
   "PREM P-wave velocity as a cross-section of the Earth (warmer = faster)."]
];

(* ---- 4 ---- *)
add[
 sec["4 | Ray theory and travel times"],
 para["In a spherically symmetric Earth, a seismic ray obeys Snell's law in ",
   "spherical coordinates. The combination"],
 eqb @ RowBox[{"p", "=", FractionBox[RowBox[{"r", " ", RowBox[{"sin", " ", "i"}]}],
      RowBox[{"v", "(", "r", ")"}]], "=", "const"}],
 para["is conserved along the entire path \[Dash] this is the ",
   b["ray parameter"], ". Introducing the radial slowness ",
   im @ RowBox[{"\[Eta]", "(", "r", ")", "=", "r", "/", RowBox[{"v", "(", "r", ")"}]}],
   ", a ray turns horizontal (", im @ RowBox[{"i", "=", "90", "\[Degree]"}],
   ") at the radius ", sb["r", "tp"], " where ",
   im @ RowBox[{"\[Eta]", "(", SubscriptBox["r", "tp"], ")", "=", "p"}],
   ". The epicentral distance and travel time follow as integrals over the ",
   "up-going path:"],
 eqb @ RowBox[{"\[CapitalDelta]", "(", "p", ")", "=", "2",
    UnderoverscriptBox["\[Integral]", SubscriptBox["r", "tp"], "R"],
    FractionBox["p", RowBox[{"r", " ",
       SqrtBox[RowBox[{SuperscriptBox["\[Eta]", "2"], "-", SuperscriptBox["p", "2"]}]]}]],
    RowBox[{"\[DifferentialD]", "r"}]}],
 eqb @ RowBox[{"T", "(", "p", ")", "=", "2",
    UnderoverscriptBox["\[Integral]", SubscriptBox["r", "tp"], "R"],
    FractionBox[SuperscriptBox["\[Eta]", "2"], RowBox[{"r", " ",
       SqrtBox[RowBox[{SuperscriptBox["\[Eta]", "2"], "-", SuperscriptBox["p", "2"]}]]}]],
    RowBox[{"\[DifferentialD]", "r"}]}],
 para["These integrals have an integrable singularity at the turning point, ",
   "where the square root vanishes. We tame it with the substitution ",
   im @ RowBox[{"r", "=", SubscriptBox["r", "tp"], "+", SuperscriptBox["\[Xi]", "2"]}],
   ", which makes the integrand regular and gives accurate, real-valued ",
   "results. Sweeping ", m["p"], " from the core\[Dash]mantle boundary up to ",
   "the surface traces every ray of the direct branch:"],
 codeIn["plotRayPaths[]"],
 fig["ray_paths.png", 680,
   "P-wave ray paths through PREM. Shallow rays (red) emerge close by; deeper-turning rays (blue\[Dash]purple) bottom near the core\[Dash]mantle boundary and emerge near 95\[Degree]."],
 para["Collecting (", im["\[CapitalDelta]"], ", ", im["T"],
   ") for the P and S branches, and adding the (linear) surface-wave moveout, ",
   "yields the universal travel-time curves \[Dash] the seismologist's master ",
   "chart, depending only on the Earth model, not on the earthquake:"],
 codeIn["plotTravelTimeCurves[]"],
 fig["travel_curves.png", 720,
   "Travel-time curves for P, S, Rayleigh and Love waves. The mild scatter near 25\[Dash]40\[Degree] is the real upper-mantle triplication from the 410/660 km discontinuities."],
 para["How good is this from-scratch calculation? Comparing the computed P ",
   "times against the IASP91 standard reference (Kennett & Engdahl 1991) ",
   "shows agreement to within a few seconds across teleseismic distances ",
   "\[Dash] the verification table is in \[Section]11."]
];

(* ---- 5 ---- *)
add[
 sec["5 | Seismic energy and magnitude"],
 para["The radiated seismic energy ", sb["E", "S"], " grows steeply with ",
   "moment magnitude via the Gutenberg\[Dash]Richter\[Dash]Kanamori relation:"],
 eqb @ RowBox[{SubscriptBox["log", "10"], RowBox[{"(", SubscriptBox["E", "S"], ")"}],
    "=", RowBox[{"1.5", " ", SubscriptBox["M", "w"]}], "+", "4.8"}],
 para["Each unit of magnitude is a factor ", im @ SuperscriptBox["10", "1.5"],
   " \[TildeTilde] 32 in energy. Plotted against the six earthquakes in our ",
   "catalogue and the 2017 DPRK nuclear test, the logarithmic gulf between a ",
   "great earthquake and even a large bomb is stark:"],
 codeIn["plotEnergyBarChart[]"],
 fig["energy_bars.png", 700,
   "Radiated energy of the six earthquakes vs. the 250 kt DPRK test (log scale)."],
 para["The numbers are sobering: the 1960 Chile M9.5 released on the order of ",
   b["10,000 times"], " the energy of the 250 kt DPRK test; even the Tohoku ",
   "M9.1 released roughly 2,700 times as much."]
];

(* ---- 6 ---- *)
add[
 sec["6 | A global tour of recent events"],
 para["We anchor the physics in seven real events \[Dash] six earthquakes ",
   "spanning four orders of magnitude in energy, plus one underground ",
   "nuclear test:"],
 codeIn["displayCatalog[]"],
 fig["catalog_table.png", 720, ""],
 codeIn["plotEventMap[]"],
 fig["event_map.png", 700,
   "The seven events on a Robinson projection (earthquakes in red, the DPRK nuclear test in black)."]
];

(* ---- 7 ---- *)
add[
 sec["7 | Watching the waves sweep the planet"],
 para["This is where the physics becomes visible. A ",
   b["Ground Motion Visualization"], " (GMV), pioneered by IRIS, animates ",
   "the vertical ground motion recorded at many seismometers: each station ",
   "is a dot that turns ", StyleBox["red", FontColor -> Red],
   " when the ground heaves up and ", StyleBox["blue", FontColor -> Blue],
   " when it drops. Here is the ", b["real"], " Mandalay M7.7 \[Dash] actual ",
   "LHZ waveforms from ", b["73 European stations"], " (FDSN / IRIS-EarthScope), ",
   "band-passed and normalised. Watch the wave sweep in from the east: the ",
   "stations nearest the source (the Caucasus) light up first and hardest, ",
   "then the disturbance rolls across the continent to Iberia:"],
 codeIn["gmvDir = FileNameJoin[{ParentDirectory[NotebookDirectory[]], \"data\"}];\n(* real European LHZ waveforms -> gmvFrame; reads committed data/gmv_waveforms *)\nplotRealGMV[gmvDir]"],
 anim["real_gmv.gif", 720,
   "Real-data Ground Motion Visualization of the Mandalay M7.7: 73 European stations coloured by their actual vertical ground motion (red = up, blue = down). The wave arrives from the east and sweeps west.", 8.],
 para["Now compare that with the ", b["synthetic"], " GMV at the top of this ",
   "post. That one uses ", b["no data at all"], " \[Dash] a 2000-station ",
   "synthetic network and seismograms generated purely from the PREM ",
   "travel-time model above \[Dash] yet it reproduces the same eastward sweep. ",
   "The physics alone predicts what the real network records. (Its ",
   "full-resolution 25-second video is ", code["docs/images/SeismicGMV.mp4"],
   "; the synthetic engine is ", code["exportGMVFrames[event]"], ".)"],
 sub["The same event as idealized wavefronts"],
 para["Stripped to its geometry, the event is just expanding circles on the ",
   "globe: the P, S and Rayleigh fronts have radius ", im["\[CapitalDelta](t)"],
   " centred on the epicentre. The fast blue P-front races ahead; the red ",
   "S-front and orange Rayleigh front follow:"],
 codeIn["myanmar = earthquakeCatalog[[1]];\nGraphicsRow[Table[\n   makeWavefrontFrame[myanmar[\"Position\"], t, False,\n     \"t = \" <> ToString[Round[t/60]] <> \" min\"],\n   {t, {300, 700, 1150}}]]"],
 fig["wavefront_snapshots.png", 840,
   "Idealized wavefronts for the Myanmar M7.7 at 5, 12 and 19 minutes \[Dash] the fast blue P-front races ahead of the red S-front and the orange (dashed) Rayleigh front."]
];

(* ---- 8 ---- *)
add[
 sec["8 | Supershear rupture"],
 para["The Myanmar earthquake was special: its rupture front outran its own ",
   "shear waves \[Dash] a ", b["supershear"], " event. When the rupture ",
   "velocity ", sb["v", "r"], " exceeds the shear-wave speed ", sb["v", "S"],
   ", the shear wavefronts pile up into a Mach cone, exactly as a ",
   "supersonic jet does in air. The half-angle is set by"],
 eqb @ RowBox[{"sin", " ", "\[Theta]", "=", FractionBox[SubscriptBox["v", "S"],
      SubscriptBox["v", "r"]]}],
 para["For ", sb["v", "S"], " \[TildeTilde] 3.5 km/s and ", sb["v", "r"],
   " \[TildeTilde] 5.5 km/s this gives ", im @ RowBox[{"\[Theta]", "\[TildeTilde]",
      "39.5", "\[Degree]"}], " \[Dash] a focusing of energy that makes ",
   "supershear quakes unusually destructive along the fault:"],
 codeIn["plotMachCone[]"],
 fig["mach_cone.png", 680,
   "Mach-cone geometry for the supershear Myanmar rupture."]
];

(* ---- 9 ---- *)
add[
 sec["9 | Nuclear explosions as seismic sources"],
 para["An underground nuclear explosion is also a seismic source \[Dash] but ",
   "a fundamentally different one. An earthquake is a ", b["double-couple"],
   ": slip on a fault, which radiates both P and S waves with a four-lobed ",
   "pattern. An explosion is, to first order, ", b["isotropic"],
   ": it pushes outward equally in all directions, radiating an efficient ",
   "P-wave and almost no shear or surface waves."],
 para["Body-wave magnitude scales with yield through an empirical ",
   "calibration (Murphy 1996):"],
 eqb @ RowBox[{SubscriptBox["m", "b"], "=", "4.45", "+",
    RowBox[{"0.75", " ", SubscriptBox["log", "10"], RowBox[{"(", "Y", ")"}]}]}],
 para["with ", m["Y"], " in kilotons. The 250 kt DPRK test sits at ",
   im @ RowBox[{SubscriptBox["m", "b"], "\[TildeTilde]", "6.25"}],
   " on this curve:"],
 codeIn["plotYieldMbRelation[]"],
 fig["yield_mb.png", 700,
   "Body-wave magnitude vs. yield (Murphy 1996), with the DPRK test."]
];

(* ---- 10 ---- *)
add[
 sec["10 | Telling bombs from earthquakes"],
 para["This is the heart of nuclear test-ban verification. Because an ",
   "explosion radiates efficient P but weak surface waves, while an ",
   "earthquake of the same body-wave magnitude radiates strong surface ",
   "waves, the two populations separate cleanly in the ",
   im @ RowBox[{SubscriptBox["m", "b"], "\[Dash]", SubscriptBox["M", "s"]}],
   " plane \[Dash] the classic discriminant:"],
 codeIn["plotMbMsDiscrimination[]"],
 fig["mb_ms.png", 680,
   "mb\[Dash]Ms discrimination: explosions (high mb for their Ms) separate from earthquakes."],
 para["The source physics is even clearer when watched directly. Place a ",
   "hypothetical double-couple earthquake and the real isotropic explosion ",
   "at the same spot and let the wavefronts run: the earthquake sprouts an ",
   "S-front and a Rayleigh front; the explosion shows ", b["only the P-front"],
   ". That missing shear energy is the signature of an explosion:"],
 codeIn["p = nuclearTest[\"Position\"];\nframes = Table[GraphicsRow[{\n     makeWavefrontFrame[p, t, False, \"Earthquake (double-couple)\"],\n     makeWavefrontFrame[p, t, True,  \"Explosion (isotropic)\"]}],\n   {t, 20, 900, 70}];\nAnimatedImage[frames, FrameRate -> 2.2]"],
 anim["quake_vs_explosion.gif", 720,
   "Earthquake (left: P + S + Rayleigh) vs. explosion (right: P only) from the same location."],
 para["The radiation patterns make the same point statically \[Dash] the ",
   "four-lobed double-couple beside the uniform explosion:"],
 codeIn["plotSourceMechanisms[]"],
 fig["source_mech.png", 720,
   "Double-couple (earthquake) vs. isotropic (explosion) P-wave radiation patterns."]
];

(* ---- 11 ---- *)
add[
 sec["11 | Verifying the model"],
 para["A model is only as good as its agreement with reality. First, against ",
   "the ", b["IASP91"], " empirical standard: our from-scratch PREM travel ",
   "times line up to within a few seconds across the teleseismic range, and ",
   "the S/P ratio comes out at 1.84, the expected mantle value:"],
 codeIn["displayVerificationTable[]"],
 fig["verification_table.png", 720, ""],
 sub["The real test: a real earthquake"],
 para["Tables are one thing; the actual Earth is another. So we fetch ",
   b["real broadband seismograms"], " of the Mandalay M7.7 from the global ",
   "seismic network (FDSN / IRIS-EarthScope), band-pass them to 0.02\[Dash]0.1 Hz, ",
   "and lay them out as a ", b["record section"], " \[Dash] amplitude vs. time, ",
   "each trace offset by its epicentral distance. Onto that we draw the P, S ",
   "and Rayleigh curves computed entirely from our PREM model above. If the ",
   "physics is right, the predicted curves should fall on the real arrivals:"],
 codeIn["dataDir = FileNameJoin[{ParentDirectory[NotebookDirectory[]], \"data\"}];\nplotRecordSection[dataDir]"],
 fig["record_section.png", 820,
   "Eleven real vertical seismograms (27\[Dash]96\[Degree]) of the Mandalay M7.7, with the PREM-predicted P, S and Rayleigh travel-time curves overlaid. The surface-wave energy tracks the Rayleigh line across the whole section."],
 para["The agreement is immediate: the large surface waves ride the orange ",
   "Rayleigh line at every distance, and the first energy arrives on the blue ",
   "P curve. Zooming in on a single station \[Dash] Obninsk, Russia, at 55\[Degree] ",
   "\[Dash] shows all three components, with the arrivals marked at our ",
   "predicted times. Note the S wave is stronger on the horizontals (N, E) ",
   "than on the vertical, exactly as shear-wave physics demands:"],
 codeIn["plotSingleStation[dataDir]"],
 fig["single_station.png", 820,
   "Real 3-component record at II.OBN (55\[Degree]); dashed lines are the PREM-predicted P, S and Rayleigh arrival times. The model, built from first principles, predicts the real Earth."]
];

(* ---- 12 ---- *)
add[
 sec["12 | Conclusions"],
 para["Starting from the elastic wave equation and one tabulated velocity ",
   "model, we reconstructed the seismologist's toolkit: P and S body waves, ",
   "the PREM Earth, ray-traced travel times validated against the ",
   "international standard, the energy\[Dash]magnitude scaling, global ",
   "wavefront animations, supershear Mach cones, and the source physics that ",
   "lets a seismic network distinguish a bomb from a quake. The same handful ",
   "of equations carries us from ", it["why the S-wave is slower"],
   " all the way to ", it["how we verify a nuclear test ban"], "."],
 para["Everything here is reproducible pure Wolfram Language \[Dash] see the ",
   "note below."]
];

(* ---- References ---- *)
add[
 sec["References"],
 ref[1, "Dziewonski, A. M. & Anderson, D. L. (1981). ",
   it["Preliminary Reference Earth Model."], " ",
   "Phys. Earth Planet. Inter. 25, 297\[Dash]356."],
 ref[2, "Shearer, P. M. (2009). ", it["Introduction to Seismology."],
   " Cambridge University Press."],
 ref[3, "Kennett, B. L. N. & Engdahl, E. R. (1991). ",
   "Traveltimes for global earthquake location and phase identification (IASP91). ",
   "Geophys. J. Int. 105, 429\[Dash]465."],
 ref[4, "Kanamori, H. (1977). The energy release in great earthquakes. ",
   "J. Geophys. Res. 82, 2981\[Dash]2987."],
 ref[5, "Murphy, J. R. (1996). Types of seismic events and their source ",
   "descriptions. In ", it["Monitoring a CTBT"], ", NATO ASI Series."],
 ref[6, "CTBTO \[Dash] Seismic monitoring: ",
   "https://www.ctbto.org/our-work/monitoring-technologies/seismic-monitoring"],
 ref[7, "IRIS DMC \[Dash] Ground Motion Visualization (GMV): ",
   "https://ds.iris.edu/ds/products/gmv/"],
 sub["Data and imagery credits"],
 para[b["Seismograms"], " (\[Section]11 record section and single-station ",
   "trace, and the real-data GMV) were obtained from the ", b["FDSN"],
   " / IRIS-EarthScope ", code["irisws-timeseries"], " service \[Dash] ",
   "networks GE (GEOFON), II (GSN/IDA), IU (GSN), MN (MedNet), CH, SL and ",
   "others. Earthquake source parameters are from the ", b["USGS"],
   " and ", b["GCMT"], " catalogues (event us7000pn9s). Base maps are ",
   "rendered with Wolfram Language ", code["GeoGraphics"],
   " (relief and country-border styling). The synthetic GMV uses no real ",
   "data \[Dash] its station network and seismograms are generated from the ",
   "PREM travel-time model above."]
];

(* ---- Reproducibility ---- *)
add[
 sec["Reproducibility"],
 para["The entire pipeline is pure Wolfram Language in the companion ",
   "repository:"],
 item[code["wolfram/SeismicWavePropagation.wl"],
   " \[Dash] the function library (PREM, ray tracing, travel-time integrals, ",
   "event catalogue, energy and discrimination, wavefront engine)."],
 item[code["wolfram/generate_figures.wls"],
   " \[Dash] renders every figure and the two animations into ",
   code["docs/images/"], " (the GeoGraphics figures need internet for the ",
   "relief-map tiles)."],
 item[code["community/build_notebook.wls"],
   " \[Dash] assembles this notebook from the prose and the rendered figures."],
 item[code["tests/verify.wls"],
   " \[Dash] checks the P/S travel times against IASP91, the energy ratios, ",
   "the mb\[Dash]yield calibration and the supershear angle."],
 para["Build it with:"],
 Cell["wolframscript -file wolfram/generate_figures.wls\nwolframscript -file community/build_notebook.wls",
   "Program", FontFamily -> "Source Code Pro", FontSize -> 12,
   CellMargins -> {{20, 10}, {6, 10}}, Background -> GrayLevel[0.96]]
];

(* ================================================================= *)
(*  Assemble + save                                                  *)
(* ================================================================= *)
Print["assembling ", Length[cells], " cells"];

TimeConstrained[
  UsingFrontEnd[
    nbObj = CreateDocument[cells, Visible -> False,
       WindowSize -> {1000, 820},
       StyleDefinitions -> styleSheet];
    NotebookSave[nbObj, outNb];
    Print["wrote ", outNb, "  (", Round[FileByteCount[outNb]/1024], " KB)"];
    Quiet @ Check[
      Export[outPdf, nbObj];
      Print["wrote ", outPdf, "  (", Round[FileByteCount[outPdf]/1024], " KB)"],
      Print["warn: PDF export failed"]];
    NotebookClose[nbObj];
  ],
  900,
  Print["warn: notebook save timed out"]
];
Print["done"];
